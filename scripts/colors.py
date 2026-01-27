#!/usr/bin/env python3
import logging
import os
import re
import signal
import subprocess
import sys
import termios
import time
import tty

# Setup logging
logging.basicConfig(
    filename="/tmp/colors.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
log = logging.getLogger(__name__)

# Debug: kill script after 5 seconds
# signal.alarm(5)

# ANSI escape sequences
GREEN = "\033[32m"
BRIGHT_YELLOW = "\033[1;93m"
MATCH_BG = "\033[48;5;240m"  # Slightly bright gray background for matches
SELECTED_BG = "\033[48;5;250m"  # Brighter gray for selected match
RESET = "\033[0m"
CLEAR_SCREEN = "\033[2J"
HOME = "\033[H"
ENTER_ALTERNATE_SCREEN = "\033[?1049h"
RESTORE_NORMAL_SCREEN = "\033[?1049l"

# Label characters (home row priority)
LABELS = "asdfqwerzxcvjklmiuopghtybn"

# Patterns to match (ordered from most specific to least specific)
PATTERNS = [
    r'https?://[^\s<>"{}|\\^`\[\]]+',  # URLs (highest priority)
    r'(?:/|\.\.?/)[^\s:]+',  # File paths
    r'(?:(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?::[0-9a-fA-F]{1,4}){1,6}|:(?::[0-9a-fA-F]{1,4}){1,7}|::)',  # IPv6 addresses
    r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b',  # IPv4 addresses
    r'\bv\d+\.\d+\.\d+(?:-[\w.]+)?(?:\+[\w.]+)?\b',  # Semantic versions
    r'(?<![a-fA-F0-9])[0-9a-f]{7,40}(?![a-fA-F0-9])',  # Git hashes
    r'\b\d{3,}\b',  # Numbers with 3+ digits (lowest priority)
]


def tmux(*args):
    """Run tmux command and return output."""
    return subprocess.check_output(["tmux", *args]).decode().strip()


def generate_labels(count):
    """Generate labels for the given count of matches."""
    if count <= len(LABELS):
        return list(LABELS[:count])

    labels = []
    base = len(LABELS)
    digits_needed = 1
    while base ** digits_needed < count:
        digits_needed += 1

    for i in range(count):
        label = ""
        num = i
        for _ in range(digits_needed):
            label = LABELS[num % base] + label
            num //= base
        labels.append(label)

    return labels


def find_patterns(clean_content):
    """Find all patterns in clean content without overlapping matches."""
    all_matches = []

    # Collect all matches from all patterns
    for pattern in PATTERNS:
        for m in re.finditer(pattern, clean_content):
            all_matches.append((m.start(), m.end(), m.group()))

    # Sort by start position, then by length (longer matches first for same start)
    all_matches.sort(key=lambda x: (x[0], -(x[1] - x[0])))

    # Remove overlapping matches (keep the first one at each position)
    result = []
    last_end = -1
    for start, end, text in all_matches:
        if start >= last_end:
            result.append((start, end, text))
            last_end = end

    return result


def generate_labels_for_matches(matches):
    """Generate labels for matches, with duplicate texts sharing the same label."""
    # Map unique texts to labels
    text_to_label = {}
    for _, _, text in matches:
        if text not in text_to_label:
            text_to_label[text] = generate_labels(len(text_to_label) + 1)[-1]

    return [text_to_label[text] for _, _, text in matches]


def draw_screen(tty_path, content, matches, labels, selected_idx=None):
    """Draw the screen with original text colors, highlighted matches."""
    output = []
    cursor = 0

    for idx, ((start, end, match_text), label) in enumerate(zip(matches, labels)):
        if cursor < start:
            output.append(content[cursor:start])
        # Use brighter background for selected match
        bg = SELECTED_BG if idx == selected_idx else MATCH_BG
        # Yellow label on match background
        output.append(bg + BRIGHT_YELLOW + label + RESET)
        # Rest of match with green text on background
        if len(label) < len(match_text):
            output.append(bg + GREEN + match_text[len(label):] + RESET)
        cursor = end

    if cursor < len(content):
        output.append(content[cursor:])

    with open(tty_path, "w") as f:
        f.write(CLEAR_SCREEN + HOME)
        f.write("".join(output).replace("\n", "\n\r"))
        f.write(RESET + HOME)


def get_key(fd):
    """Read a single key from TTY file descriptor."""
    return os.read(fd, 1).decode()


def copy_to_clipboard(text, tty_path):
    """Copy text to system clipboard using OSC 52 escape sequence."""
    import base64
    encoded = base64.b64encode(text.encode()).decode()
    osc52 = f"\033]52;c;{encoded}\007"
    with open(tty_path, "w") as f:
        f.write(osc52)
    log.info(f"Copied to clipboard via OSC52: {text!r}")


def select_match(tty_path, content, matches, labels):
    """Interactive selection loop. Returns (selected_text, should_insert) or (None, False) if cancelled."""
    current_matches = matches[:]
    current_labels = labels[:]
    typed = ""

    # Open TTY and set raw mode for the entire selection process
    fd = os.open(tty_path, os.O_RDWR)
    old_settings = termios.tcgetattr(fd)
    try:
        # Flush any pending input and set raw mode (disables echo)
        termios.tcflush(fd, termios.TCIFLUSH)
        tty.setraw(fd)

        draw_screen(tty_path, content, current_matches, current_labels)

        while True:
            char = get_key(fd)
            log.debug(f"Key pressed: {char!r}, typed so far: {typed!r}")

            # ESC or Ctrl+C - cancel
            if char in ("\x1b", "\x03"):
                log.info("Selection cancelled")
                return None, False

            # Exit on non-label characters
            char_lower = char.lower()
            if char_lower not in LABELS:
                log.info(f"Invalid key pressed: {char!r}, exiting")
                return None, False

            # Check if uppercase (Shift held) - means insert after selection
            should_insert = char.isupper()

            typed += char_lower
            log.debug(f"Typed: {typed!r}, should_insert: {should_insert}")

            # Check if typed matches a complete label
            if typed in current_labels:
                idx = current_labels.index(typed)
                selected_text = current_matches[idx][2]
                copy_to_clipboard(selected_text, tty_path)
                return selected_text, should_insert

            # Filter matches whose labels start with typed prefix
            filtered = [
                (m, l) for m, l in zip(current_matches, current_labels)
                if l.startswith(typed)
            ]

            if filtered:
                # Update current matches and redraw
                current_matches, current_labels = map(list, zip(*filtered))
                # Update labels to show remaining suffix
                display_labels = [l[len(typed):] or l for l in current_labels]
                draw_screen(tty_path, content, current_matches, display_labels)
                log.debug(f"Filtered to {len(current_matches)} matches")
            else:
                # No matches for this prefix, reset
                log.debug("No matches for prefix, resetting")
                typed = ""
                current_matches = matches[:]
                current_labels = labels[:]
                draw_screen(tty_path, content, current_matches, current_labels)
    finally:
        # Restore terminal settings
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        os.close(fd)


def main():
    log.info("Starting colors.py")
    try:
        pane_tty = tmux("display-message", "-p", "#{pane_tty}")
        pane_id = tmux("display-message", "-p", "#{pane_id}")
        alternate_on = tmux("display-message", "-p", "#{alternate_on}")
        log.debug(f"pane_tty={pane_tty}, pane_id={pane_id}, alternate_on={alternate_on}")
        ansi_content = tmux("capture-pane", "-p", "-e", "-t", pane_id)
        content = tmux("capture-pane", "-p", "-t", pane_id)
        log.debug(f"Captured content length: {len(content)}")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        log.error(f"tmux error: {e}")
        print(f"tmux error: {e}", file=sys.stderr)
        return 1

    if alternate_on == "1":
        log.info("Already in alternate screen, exiting")
        print("Already in alternate screen", file=sys.stderr)
        return 0

    matches = find_patterns(content)
    labels = generate_labels_for_matches(matches)
    log.info(f"Found {len(matches)} matches")
    for i, ((start, end, text), label) in enumerate(zip(matches, labels)):
        log.debug(f"  Match {i} [{label}]: ({start}-{end}) {text!r}")

    if not matches:
        log.info("No matches found, exiting")
        return 0

    # Display with colors and labels
    log.debug("Entering alternate screen")
    with open(pane_tty, "w") as f:
        f.write(ENTER_ALTERNATE_SCREEN)

    selected = None
    should_insert = False
    try:
        selected, should_insert = select_match(pane_tty, content, matches, labels)
        if selected:
            log.info(f"Selected: {selected!r}, should_insert: {should_insert}")
        else:
            log.info("No selection made")
    except Exception as e:
        log.error(f"Error during display: {e}")
        raise
    finally:
        log.debug("Restoring normal screen")
        with open(pane_tty, "w") as f:
            f.write(RESTORE_NORMAL_SCREEN)

    # Insert text into pane if Shift was held
    if selected and should_insert:
        log.info(f"Inserting text into pane: {selected!r}")
        subprocess.run(["tmux", "send-keys", "-l", selected], check=False)

    log.info("Exiting normally")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)

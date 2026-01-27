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
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"

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


# Regex to match ANSI escape sequences
ANSI_ESCAPE = re.compile(r'\x1b\[[0-9;]*m')


def strip_ansi(content):
    """Strip ANSI escape sequences and return (clean_content, position_map).

    position_map[clean_pos] = raw_pos for translating positions.
    """
    clean = []
    pos_map = []
    i = 0

    while i < len(content):
        match = ANSI_ESCAPE.match(content, i)
        if match:
            i = match.end()
        else:
            clean.append(content[i])
            pos_map.append(i)
            i += 1

    # Add end position for slicing
    pos_map.append(i)

    return ''.join(clean), pos_map


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
        f.write(CLEAR_SCREEN + HOME + HIDE_CURSOR)
        f.write("".join(output).replace("\n", "\n\r"))
        f.write(RESET + HOME)


def get_key(tty_path):
    """Read a key from TTY. Returns (char, shift) tuple."""
    fd = os.open(tty_path, os.O_RDONLY)
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        char = os.read(fd, 1).decode()

        # Check for CSI u escape sequence (Shift+Enter = \x1b[13;2u)
        if char == "\x1b":
            seq = os.read(fd, 6).decode()  # Read potential CSI u sequence
            if seq.startswith("[13;2u"):
                return ("\r", True)  # Shift+Enter
            elif seq.startswith("["):
                return (None, False)  # Other escape sequence, ignore
            return ("\x1b", False)  # Plain ESC

        return (char, False)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        os.close(fd)


def select_match(tty_path, raw_content, clean_content, matches, labels):
    """Interactive selection loop. Returns (selected_text, selected_idx, paste) or (None, None, paste)."""
    draw_screen(tty_path, raw_content, matches, labels)
    selected = ""
    label_len = len(labels[0])
    pending_idx = None  # Store index when waiting for Enter

    while True:
        char, shift = get_key(tty_path)

        if char == "\x1b":  # ESC - go back to last pane
            return None, None, True
        if char == "\x03":  # Ctrl+C - just cancel
            return None, None, False

        if char is None:
            continue

        # Enter confirms pending match
        if char in ("\r", "\n") and pending_idx is not None:
            return matches[pending_idx][2], pending_idx, shift

        if char not in LABELS:
            continue

        selected += char

        if selected in labels:
            pending_idx = labels.index(selected)
            # Wait for Enter/Shift+Enter to confirm
            continue

        # Filter for multi-char labels
        if label_len > 1:
            filtered = [(m, l) for m, l in zip(matches, labels) if l.startswith(selected)]
            if filtered:
                matches, labels = map(list, zip(*filtered))
                draw_screen(tty_path, raw_content, matches, labels)
            else:
                selected = ""
                pending_idx = None
                matches = find_patterns(clean_content)
                labels = generate_labels_for_matches(matches)
                draw_screen(tty_path, raw_content, matches, labels)


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
    log.info(f"Found {len(matches)} matches")
    for i, (start, end, text) in enumerate(matches):
        log.debug(f"  Match {i}: ({start}-{end}) {text!r}")

    # Print found matches to TTY
    log.debug("Entering alternate screen")
    with open(pane_tty, "w") as f:
        f.write(ENTER_ALTERNATE_SCREEN)

    try:
        with open(pane_tty, "w") as f:
            f.write(CLEAR_SCREEN + HOME)
            f.write(f"Found {len(matches)} matches:\n\r")
            for i, (start, end, text) in enumerate(matches):
                f.write(f"  [{i}] ({start:4d}-{end:4d}): {text!r}\n\r")
            f.write(f"\n\rPress any key to exit...")

        log.debug("Waiting for input")
        # Wait for input
        input()
        log.debug("Input received")
    except Exception as e:
        log.error(f"Error during display: {e}")
        raise
    finally:
        log.debug("Restoring normal screen")
        with open(pane_tty, "w") as f:
            f.write(RESTORE_NORMAL_SCREEN)

    log.info("Exiting normally")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)

#!/usr/bin/env python3
import base64
import logging
import os
import re
import subprocess
import sys
import termios
import tty
from contextlib import contextmanager

# Setup logging
logging.basicConfig(
    filename="/tmp/colors.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
log = logging.getLogger(__name__)

# ANSI escape sequences
GREEN = "\033[32m"
BRIGHT_YELLOW = "\033[1;93m"
MATCH_BG = "\033[48;5;240m"
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
    r'https?://[^\s<>"{}|\\^`\[\]]+',  # URLs
    r'(?:/|\.\.?/)[^\s:]+',  # File paths
    r'(?:(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?::[0-9a-fA-F]{1,4}){1,6}|:(?::[0-9a-fA-F]{1,4}){1,7}|::)',  # IPv6
    r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b',  # IPv4
    r'\bv\d+\.\d+\.\d+(?:-[\w.]+)?(?:\+[\w.]+)?\b',  # Semantic versions
    r'(?<![a-fA-F0-9])[0-9a-f]{7,40}(?![a-fA-F0-9])',  # Git hashes
    r'\b\d{3,}\b',  # Numbers (3+ digits)
]


def tmux(*args):
    """Run tmux command and return output."""
    return subprocess.check_output(["tmux", *args]).decode().strip()


@contextmanager
def alternate_screen(tty_path):
    """Context manager for alternate screen with hidden cursor."""
    log.debug("Entering alternate screen")
    with open(tty_path, "w") as f:
        f.write(ENTER_ALTERNATE_SCREEN + HIDE_CURSOR)
    try:
        yield
    finally:
        log.debug("Restoring normal screen")
        with open(tty_path, "w") as f:
            f.write(SHOW_CURSOR + RESTORE_NORMAL_SCREEN)


@contextmanager
def raw_mode(tty_path):
    """Context manager for raw terminal mode."""
    fd = os.open(tty_path, os.O_RDWR)
    old_settings = termios.tcgetattr(fd)
    log.debug(f"Opened TTY {tty_path}, fd={fd}")
    try:
        termios.tcflush(fd, termios.TCIFLUSH)
        tty.setraw(fd)
        log.debug("Set raw mode")
        yield fd
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        os.close(fd)
        log.debug("Restored terminal settings")


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


def find_patterns(content):
    """Find all patterns in content without overlapping matches."""
    all_matches = []

    for pattern in PATTERNS:
        for m in re.finditer(pattern, content):
            all_matches.append((m.start(), m.end(), m.group()))

    # Sort by position, longer matches first for same start
    all_matches.sort(key=lambda x: (x[0], -(x[1] - x[0])))

    # Remove overlapping matches
    result = []
    last_end = -1
    for start, end, text in all_matches:
        if start >= last_end:
            result.append((start, end, text))
            last_end = end

    return result


def generate_labels_for_matches(matches):
    """Generate labels for matches, with duplicate texts sharing the same label."""
    text_to_label = {}
    for _, _, text in matches:
        if text not in text_to_label:
            text_to_label[text] = generate_labels(len(text_to_label) + 1)[-1]

    return [text_to_label[text] for _, _, text in matches]


def draw_screen(tty_path, content, matches, labels):
    """Draw the screen with highlighted matches and labels."""
    output = []
    cursor = 0

    for (start, end, match_text), label in zip(matches, labels):
        if cursor < start:
            output.append(content[cursor:start])
        output.append(MATCH_BG + BRIGHT_YELLOW + label + RESET)
        if len(label) < len(match_text):
            output.append(MATCH_BG + GREEN + match_text[len(label):] + RESET)
        cursor = end

    if cursor < len(content):
        output.append(content[cursor:])

    with open(tty_path, "w") as f:
        f.write(CLEAR_SCREEN + HOME)
        f.write("".join(output).replace("\n", "\n\r"))
        f.write(RESET + HOME)


def copy_to_clipboard(text, tty_path):
    """Copy text to system clipboard using OSC 52."""
    encoded = base64.b64encode(text.encode()).decode()
    with open(tty_path, "w") as f:
        f.write(f"\033]52;c;{encoded}\007")
    log.info(f"Copied to clipboard: {text!r}")


def select_match(tty_path, content, matches, labels):
    """Interactive selection loop. Returns (selected_text, should_insert) or (None, False)."""
    current_matches = matches[:]
    current_labels = labels[:]
    typed = ""

    with raw_mode(tty_path) as fd:
        draw_screen(tty_path, content, current_matches, current_labels)

        while True:
            char = os.read(fd, 1).decode()
            log.debug(f"Key pressed: {char!r}, typed: {typed!r}")

            # ESC or Ctrl+C - cancel
            if char in ("\x1b", "\x03"):
                log.info("Selection cancelled")
                return None, False

            # Exit on non-label characters
            char_lower = char.lower()
            if char_lower not in LABELS:
                log.info(f"Invalid key: {char!r}, exiting")
                return None, False

            # Shift held = insert after selection
            should_insert = char.isupper()
            typed += char_lower
            log.debug(f"Typed: {typed!r}, should_insert: {should_insert}")

            # Check for complete label match
            if typed in current_labels:
                idx = current_labels.index(typed)
                selected_text = current_matches[idx][2]
                copy_to_clipboard(selected_text, tty_path)
                return selected_text, should_insert

            # Filter matches by prefix
            filtered = [
                (m, l) for m, l in zip(current_matches, current_labels)
                if l.startswith(typed)
            ]

            if filtered:
                current_matches, current_labels = map(list, zip(*filtered))
                display_labels = [l[len(typed):] or l for l in current_labels]
                draw_screen(tty_path, content, current_matches, display_labels)
                log.debug(f"Filtered to {len(current_matches)} matches")
            else:
                log.debug("No matches, resetting")
                typed = ""
                current_matches = matches[:]
                current_labels = labels[:]
                draw_screen(tty_path, content, current_matches, current_labels)


def main():
    log.info("Starting colors.py")

    try:
        pane_tty = tmux("display-message", "-p", "#{pane_tty}")
        pane_id = tmux("display-message", "-p", "#{pane_id}")
        alternate_on = tmux("display-message", "-p", "#{alternate_on}")
        content = tmux("capture-pane", "-p", "-t", pane_id)
        log.debug(f"pane_tty={pane_tty}, pane_id={pane_id}, content_len={len(content)}")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        log.error(f"tmux error: {e}")
        print(f"tmux error: {e}", file=sys.stderr)
        return 1

    if alternate_on == "1":
        log.info("Already in alternate screen")
        return 0

    matches = find_patterns(content)
    labels = generate_labels_for_matches(matches)
    log.info(f"Found {len(matches)} matches")

    if not matches:
        return 0

    selected = None
    should_insert = False

    with alternate_screen(pane_tty):
        try:
            selected, should_insert = select_match(pane_tty, content, matches, labels)
            log.info(f"Selected: {selected!r}, should_insert: {should_insert}")
        except Exception as e:
            log.error(f"Error: {e}")
            raise

    # Insert text if Shift was held
    if selected and should_insert:
        log.info(f"Inserting into pane {pane_id}: {selected!r}")
        subprocess.run(["tmux", "send-keys", "-t", pane_id, "-l", selected], check=False)

    log.info("Done")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)

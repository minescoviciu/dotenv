#!/usr/bin/env python3
"""
Tmux pattern matcher - highlights URLs, paths, IPs, etc. and copies selection to clipboard.

Usage: bind-key s run-shell -b "~/.config/scripts/colors.py"
"""
import base64
import logging
import os
import re
import subprocess
import sys
import termios
import tty

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


class TTY:
    """Manages TTY read/write operations through a single file descriptor."""

    def __init__(self, tty_path: str):
        self.tty_path = tty_path
        self.fd: int = -1
        self.old_settings: list | None = None
        self.in_raw_mode = False
        self.in_alternate_screen = False

    def __enter__(self):
        self.fd = os.open(self.tty_path, os.O_RDWR | os.O_NOCTTY)
        self.old_settings = termios.tcgetattr(self.fd)
        log.debug(f"Opened TTY {self.tty_path}, fd={self.fd}, mode: {self._get_mode()}")
        return self

    def __exit__(self, *_):
        if self.in_alternate_screen:
            self.exit_alternate_screen()
        if self.in_raw_mode:
            self.exit_raw_mode()
        if self.fd >= 0:
            os.close(self.fd)
            log.debug("Closed TTY")
        return False

    def _get_mode(self):
        """Return a string describing the TTY mode."""
        settings = termios.tcgetattr(self.fd)
        lflag = settings[3]
        modes = []
        if lflag & termios.ECHO:
            modes.append("ECHO")
        if lflag & termios.ICANON:
            modes.append("ICANON")
        if lflag & termios.ISIG:
            modes.append("ISIG")
        return ",".join(modes) if modes else "RAW"

    def write(self, data: str | bytes):
        """Write data to TTY."""
        os.write(self.fd, data.encode() if isinstance(data, str) else data)

    def read_key(self) -> str:
        """Read a single key from TTY."""
        return os.read(self.fd, 1).decode()

    def flush_input(self):
        """Flush any pending input."""
        termios.tcflush(self.fd, termios.TCIFLUSH)
        log.debug("Flushed input")

    def enter_raw_mode(self):
        """Enter raw terminal mode."""
        if not self.in_raw_mode:
            self.flush_input()
            tty.setraw(self.fd)
            self.in_raw_mode = True
            log.debug(f"Entered raw mode, now: {self._get_mode()}")

    def exit_raw_mode(self):
        """Exit raw terminal mode."""
        if self.in_raw_mode and self.old_settings:
            termios.tcsetattr(self.fd, termios.TCSADRAIN, self.old_settings)
            self.in_raw_mode = False
            log.debug(f"Exited raw mode, now: {self._get_mode()}")

    def enter_alternate_screen(self):
        """Enter alternate screen with hidden cursor."""
        if not self.in_alternate_screen:
            self.write(ENTER_ALTERNATE_SCREEN + HIDE_CURSOR)
            self.in_alternate_screen = True
            log.debug("Entered alternate screen")

    def exit_alternate_screen(self):
        """Exit alternate screen and show cursor."""
        if self.in_alternate_screen:
            self.write(SHOW_CURSOR + RESTORE_NORMAL_SCREEN)
            self.in_alternate_screen = False
            log.debug("Exited alternate screen")

    def clear_and_home(self):
        """Clear screen and move cursor home."""
        self.write(CLEAR_SCREEN + HOME)

    def copy_to_clipboard(self, text):
        """Copy text to system clipboard using OSC 52."""
        encoded = base64.b64encode(text.encode()).decode()
        self.write(f"\033]52;c;{encoded}\007")
        log.info(f"Copied to clipboard: {text!r}")


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


def draw_screen(tty, content, matches, labels):
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

    tty.clear_and_home()
    tty.write("".join(output).replace("\n", "\n\r"))
    tty.write(RESET + HOME)


def select_match(tty, content, matches, labels):
    """Interactive selection loop. Returns (selected_text, should_insert) or (None, False)."""
    current_matches = matches[:]
    current_labels = labels[:]
    typed = ""

    draw_screen(tty, content, current_matches, current_labels)

    while True:
        char = tty.read_key()
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
            tty.copy_to_clipboard(selected_text)
            return selected_text, should_insert

        # Filter matches by prefix
        filtered = [
            (m, l) for m, l in zip(current_matches, current_labels)
            if l.startswith(typed)
        ]

        if filtered:
            current_matches, current_labels = map(list, zip(*filtered))
            display_labels = [l[len(typed):] or l for l in current_labels]
            draw_screen(tty, content, current_matches, display_labels)
            log.debug(f"Filtered to {len(current_matches)} matches")
        else:
            log.debug("No matches, resetting")
            typed = ""
            current_matches = matches[:]
            current_labels = labels[:]
            draw_screen(tty, content, current_matches, current_labels)


def main():
    log.info("Starting colors.py")

    # Debug: show script's own TTY info
    try:
        script_tty = os.ttyname(sys.stdin.fileno())
    except OSError:
        script_tty = "<no tty>"
    log.debug(f"Script stdin TTY: {script_tty}")
    log.debug(f"Script PID: {os.getpid()}, PPID: {os.getppid()}")

    try:
        pane_tty = tmux("display-message", "-p", "#{pane_tty}")
        pane_id = tmux("display-message", "-p", "#{pane_id}")
        alternate_on = tmux("display-message", "-p", "#{alternate_on}")
        content = tmux("capture-pane", "-p", "-t", pane_id)
        log.debug(f"pane_tty={pane_tty}, pane_id={pane_id}, content_len={len(content)}")
        log.debug(f"Script TTY vs Pane TTY: {'SAME' if script_tty == pane_tty else 'DIFFERENT'}")
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
    for (start, end, text), label in zip(matches, labels):
        log.debug(f"  [{label}] pos {start}-{end}: {text!r}")

    if not matches:
        return 0

    selected = None
    should_insert = False

    with TTY(pane_tty) as tty:
        tty.enter_alternate_screen()
        tty.enter_raw_mode()

        try:
            selected, should_insert = select_match(tty, content, matches, labels)
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

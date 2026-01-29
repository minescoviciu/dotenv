#!/usr/bin/env python3
"""
Tmux pattern matcher - highlights URLs, paths, IPs, etc. and copies selection to clipboard.

Uses a pane swap approach: creates a hidden window with the selection UI, then swaps it
with the original pane for a seamless transition (no visual flash from alternate screen).

Usage: bind-key s run-shell "python3 ~/.config/scripts/colors.py"
"""
import argparse
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
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"

# Label characters (home row priority)
LABELS = "asdfqwerzxcvjklmiuopghtybn"

# Pattern to match ANSI escape sequences
ANSI_ESCAPE = re.compile(r'\x1b\[[0-9;]*m')

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

    def __enter__(self):
        self.fd = os.open(self.tty_path, os.O_RDWR | os.O_NOCTTY)
        self.old_settings = termios.tcgetattr(self.fd)
        log.debug(f"Opened TTY {self.tty_path}, fd={self.fd}, mode: {self._get_mode()}")
        return self

    def __exit__(self, *_):
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

    def clear_and_home(self):
        """Clear screen and move cursor home."""
        self.write(CLEAR_SCREEN + HOME)

    def hide_cursor(self):
        """Hide the cursor."""
        self.write(HIDE_CURSOR)

    def show_cursor(self):
        """Show the cursor."""
        self.write(SHOW_CURSOR)

    def copy_to_clipboard(self, text):
        """Copy text to system clipboard using OSC 52."""
        encoded = base64.b64encode(text.encode()).decode()
        self.write(f"\033]52;c;{encoded}\007")
        log.info(f"Copied to clipboard: {text!r}")


def tmux(*args):
    """Run tmux command and return output."""
    return subprocess.check_output(["tmux", *args]).decode().strip()


def strip_ansi(text):
    """Remove ANSI escape sequences from text."""
    return ANSI_ESCAPE.sub('', text)


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


def draw_screen(tty, colored_content, matches, labels):
    """Draw the screen with highlighted matches and labels, preserving original colors."""
    output = []
    match_idx = 0
    visual_pos = 0  # Position in plain text (ignoring ANSI codes)
    i = 0  # Position in colored content

    while i < len(colored_content):
        # Check for ANSI escape sequence
        ansi_match = ANSI_ESCAPE.match(colored_content, i)
        if ansi_match:
            output.append(ansi_match.group())
            i = ansi_match.end()
            continue

        # Check if we're at a match start
        if match_idx < len(matches) and visual_pos == matches[match_idx][0]:
            _, end, match_text = matches[match_idx]
            label = labels[match_idx]

            # Output the label with highlight
            output.append(MATCH_BG + BRIGHT_YELLOW + label + RESET)

            # Output rest of match with green highlight (if label is shorter)
            if len(label) < len(match_text):
                output.append(MATCH_BG + GREEN + match_text[len(label):] + RESET)

            # Skip over the match in colored content (by visual chars)
            chars_to_skip = len(match_text)
            while chars_to_skip > 0 and i < len(colored_content):
                skip_ansi = ANSI_ESCAPE.match(colored_content, i)
                if skip_ansi:
                    i = skip_ansi.end()
                else:
                    i += 1
                    chars_to_skip -= 1

            visual_pos = end
            match_idx += 1
            continue

        # Regular character, copy it
        output.append(colored_content[i])
        i += 1
        visual_pos += 1

    tty.clear_and_home()
    tty.write("".join(output).replace("\n", "\n\r"))
    tty.write(RESET + HOME)


def select_match(tty, colored_content, matches, labels):
    """Interactive selection loop. Returns (selected_text, should_insert) or (None, False)."""
    current_matches = matches[:]
    current_labels = labels[:]
    typed = ""

    draw_screen(tty, colored_content, current_matches, current_labels)

    while True:
        char = tty.read_key()
        log.debug(f"Key pressed: {char!r}, typed: {typed!r}")

        # ESC or Ctrl+C - cancel
        if char in ("\x1b", "\x03"):
            log.info("Selection cancelled")
            return None, False

        # Enter - select exact match if one exists
        if char in ("\r", "\n"):
            if typed in current_labels:
                idx = current_labels.index(typed)
                selected_text = current_matches[idx][2]
                tty.copy_to_clipboard(selected_text)
                return selected_text, False  # Enter doesn't indicate shift
            continue

        # Exit on non-label characters
        char_lower = char.lower()
        if char_lower not in LABELS:
            log.info(f"Invalid key: {char!r}, exiting")
            return None, False

        # Shift held = insert after selection
        should_insert = char.isupper()
        typed += char_lower
        log.debug(f"Typed: {typed!r}, should_insert: {should_insert}")

        # Filter matches by prefix, deduplicate by label
        seen_labels = set()
        filtered = []
        for m, l in zip(current_matches, current_labels):
            if l.startswith(typed) and l not in seen_labels:
                filtered.append((m, l))
                seen_labels.add(l)

        if not filtered:
            # No matches, reset
            log.debug("No matches, resetting")
            typed = ""
            current_matches = matches[:]
            current_labels = labels[:]
            draw_screen(tty, colored_content, current_matches, current_labels)
        elif len(filtered) == 1 and filtered[0][1] == typed:
            # Unambiguous match - select it
            selected_text = filtered[0][0][2]
            tty.copy_to_clipboard(selected_text)
            return selected_text, should_insert
        else:
            # Multiple matches or incomplete label - filter and continue
            current_matches, current_labels = map(list, zip(*filtered))
            display_labels = [l[len(typed):] or l for l in current_labels]
            draw_screen(tty, colored_content, current_matches, display_labels)
            log.debug(f"Filtered to {len(current_matches)} matches")


def main_parent():
    """Parent mode: capture content and spawn child in swapped pane."""
    log.info("Starting colors.py (parent mode)")

    try:
        pane_id = tmux("display-message", "-p", "#{pane_id}")
        colored_content = tmux("capture-pane", "-p", "-e", "-t", pane_id)
        log.debug(f"pane_id={pane_id}, content_len={len(colored_content)}")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        log.error(f"tmux error: {e}")
        print(f"tmux error: {e}", file=sys.stderr)
        return 1

    # Early exit if no matches (match on plain text)
    plain_content = strip_ansi(colored_content)
    matches = find_patterns(plain_content)
    if not matches:
        log.info("No matches found, exiting")
        return 0

    log.info(f"Found {len(matches)} matches")

    # Write colored content to temp file (avoids escaping issues on command line)
    content_file = f"/tmp/colors_content_{os.getpid()}"
    with open(content_file, 'w') as f:
        f.write(colored_content)
    log.debug(f"Wrote content to {content_file}")

    # Ensure _tmp session exists
    try:
        tmux("has-session", "-t", "_tmp")
    except subprocess.CalledProcessError:
        tmux("new-session", "-d", "-s", "_tmp")
        log.debug("Created _tmp session")

    # Create window in _tmp session with child process, get new pane ID
    script_path = os.path.abspath(__file__)
    new_pane_id = tmux(
        "new-window", "-t", "_tmp", "-d", "-P", "-F", "#{pane_id}",
        f"python3 {script_path} --child {pane_id} {content_file}"
    )
    log.debug(f"Created new window in _tmp with pane {new_pane_id}")

    # Swap panes (instantaneous, no visual flash)
    tmux("swap-pane", "-s", new_pane_id, "-t", pane_id)
    log.debug(f"Swapped panes {new_pane_id} <-> {pane_id}")

    log.info("Parent done")
    return 0


def main_child(original_pane_id, content_file):
    """Child mode: display selection UI in swapped pane."""
    log.info(f"Starting colors.py (child mode), original_pane={original_pane_id}")

    own_pane_id = tmux("display-message", "-p", "#{pane_id}")
    own_tty = tmux("display-message", "-p", "#{pane_tty}")
    log.debug(f"own_pane_id={own_pane_id}, own_tty={own_tty}")

    # Read colored content from temp file
    try:
        with open(content_file) as f:
            colored_content = f.read()
        os.unlink(content_file)  # Clean up
        log.debug(f"Read and removed {content_file}")
    except FileNotFoundError:
        log.error(f"Content file not found: {content_file}")
        return 1

    # Match on plain text, display with colors
    plain_content = strip_ansi(colored_content)
    matches = find_patterns(plain_content)
    labels = generate_labels_for_matches(matches)

    log.info(f"Found {len(matches)} matches")
    for (start, end, text), label in zip(matches, labels):
        log.debug(f"  [{label}] pos {start}-{end}: {text!r}")

    selected = None
    should_insert = False

    with TTY(own_tty) as tty:
        tty.enter_raw_mode()
        tty.hide_cursor()
        tty.clear_and_home()

        try:
            selected, should_insert = select_match(tty, colored_content, matches, labels)
            log.info(f"Selected: {selected!r}, should_insert: {should_insert}")
        except Exception as e:
            log.error(f"Error: {e}")

        tty.show_cursor()

    # Swap back before exiting (returns user to original pane)
    tmux("swap-pane", "-s", own_pane_id, "-t", original_pane_id)
    log.debug(f"Swapped back: {own_pane_id} <-> {original_pane_id}")

    # Insert text if Shift was held
    if selected and should_insert:
        log.info(f"Inserting into pane {original_pane_id}: {selected!r}")
        subprocess.run(["tmux", "send-keys", "-t", original_pane_id, "-l", selected], check=False)

    log.info("Child done")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Tmux pattern matcher")
    parser.add_argument("--child", metavar="PANE_ID", help="Run in child mode with original pane ID")
    parser.add_argument("content_file", nargs="?", help="Path to content file (child mode only)")
    args = parser.parse_args()

    if args.child:
        if not args.content_file:
            print("Error: content_file required in child mode", file=sys.stderr)
            return 1
        return main_child(args.child, args.content_file)
    else:
        return main_parent()


if __name__ == "__main__":
    sys.exit(main() or 0)

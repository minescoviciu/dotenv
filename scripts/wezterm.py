#!/usr/bin/env python3

import os
import sys
import base64
import subprocess
import time
import json
from datetime import datetime

DEBUG = os.environ.get('DEBUG_WEZTERM') == '1'
LOG_PATH = '/tmp/wezterm-logs'

def log(msg):
    if not DEBUG:
        return
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')
    try:
        os.makedirs(LOG_PATH, exist_ok=True)
        with open(f"{LOG_PATH}/debug.log", "a") as f:
            f.write(f"{timestamp} {msg}\n")
    except Exception as e:
        print(f"Failed to write log: {e}", file=sys.stderr)

def write_clipboard(tty_file, text):
    """Write OSC-52 escape sequences to copy text into clipboard."""
    log(f"Writing to clipboard, text length: {len(text)}")
    in_tmux = "TMUX" in os.environ
    term = os.environ.get("TERM", "")
    in_screen_or_tmux = term.startswith("screen") or term.startswith("tmux")
    log(f"Terminal state: tmux={in_tmux}, term={term}")

    encoded = base64.b64encode(text.encode("utf-8")).decode("utf-8")
    if in_tmux or in_screen_or_tmux:
        sequence = f"\x1bPtmux;\x1b\x1b]52;c;{encoded}\a\x1b\\"
    else:
        sequence = f"\x1b]52;c;{encoded}\a"
    
    log(f"Writing sequence (length: {len(sequence)})")
    tty_file.write(sequence)
    tty_file.flush()

def send_notification(tty_file, message, title="Notification"):
    """Write WezTerm's notify escape sequence."""
    log(f"Sending notification: {message}")
    in_tmux = "TMUX" in os.environ

    if in_tmux:
        tty_file.write(f"\x1bPtmux;\x1b\x1b]777;notify;{title};{message}\x1b\\")
    else:
        tty_file.write(f"\x1b]777;notify;{title};{message}\x1b\\")

    tty_file.flush()

def codex_notification(tty_file, text):
    """
    data = {
      "type": "agent-turn-complete",
      "thread-id": "b5f6c1c2-1111-2222-3333-444455556666",
      "turn-id": "12345",
      "cwd": "/Users/alice/projects/example",
      "input-messages": ["Rename `foo` to `bar` and update the callsites."],
      "last-assistant-message": "Rename complete and verified `cargo build` succeeds."
    }
    """
    data = json.loads(text)
    send_notification(tty_file, data["last-assistant-message"], title="Codex")


def set_user_var(tty_file, value):
    """Write WezTerm's SetUserVar escape sequence."""
    log(f"Setting user var: {value}")
    var_name = "open-web"
    encoded_value = base64.b64encode(value.encode("utf-8")).decode("utf-8")
    in_tmux = "TMUX" in os.environ

    if in_tmux:
        tty_file.write(f"\x1bPtmux;\x1b\x1b]1337;SetUserVar={var_name}={encoded_value}\x07\x1b\\")
    else:
        tty_file.write(f"\x1b]1337;SetUserVar={var_name}={encoded_value}\x07")

    tty_file.flush()

def get_command_name(pid):
    """Return the command name of the process with the given PID."""
    log(f"Getting command name for PID: {pid}")
    try:
        cmd = ["ps", "-p", str(pid), "-o", "comm="]
        result = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
        log(f"Command for PID {pid}: {result}")
        return result
    except subprocess.SubprocessError as e:
        log(f"Failed to get command for PID {pid}: {e}")
        return None

def get_ppid(pid):
    """Return the parent PID of the given PID."""
    log(f"Getting parent PID for: {pid}")
    try:
        cmd = ["ps", "-p", str(pid), "-o", "ppid="]
        ppid = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
        result = int(ppid)
        log(f"Parent of PID {pid} is: {result}")
        return result
    except (subprocess.SubprocessError, ValueError) as e:
        log(f"Failed to get parent PID for {pid}: {e}")
        return None

def get_tty_from_pid(pid):
    """Get TTY path for a given PID."""
    log(f"Getting TTY for PID: {pid}")
    try:
        cmd = ["ps", "-p", str(pid), "-o", "tty="]
        tty = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
        if tty and "?" not in tty:
            result = f"/dev/{tty}"
            log(f"TTY for PID {pid}: {result}")
            return result
        log(f"No TTY found for PID {pid}")
    except subprocess.SubprocessError as e:
        log(f"Failed to get TTY for PID {pid}: {e}")
    return None

def find_parent_shell_tty():
    """Find TTY from parent shell process (bash/zsh/fish)."""
    log("Searching for parent shell TTY")
    shells = ("bash", "zsh", "fish", "sh")
    pid = os.getppid()
    while pid and pid > 1:
        log(f"Checking PID: {pid}")
        cmd_name = get_command_name(pid)
        if cmd_name and any(cmd_name.endswith(s) or cmd_name == s for s in shells):
            tty = get_tty_from_pid(pid)
            if tty and os.path.exists(tty):
                log(f"Found shell {cmd_name} TTY: {tty}")
                return tty
        pid = get_ppid(pid)
    log("No parent shell TTY found")
    return None

def get_target_tty():
    """Get target TTY path."""
    log("Getting target TTY")

    # First try /dev/tty if it's available
    try:
        with open("/dev/tty", "w") as f:
            log("Using /dev/tty")
            return "/dev/tty"
    except (OSError, IOError):
        log("/dev/tty not available")

    # Walk up parent chain to find a shell with TTY
    shell_tty = find_parent_shell_tty()
    if shell_tty:
        log(f"Using shell TTY: {shell_tty}")
        return shell_tty

    log("No TTY found")
    return None

def main():
    start_time = time.time()
    log("Script started")

    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <clipboard|notify|open> <text> [title]")
        sys.exit(1)

    operation = sys.argv[1]
    text = sys.argv[2]
    title = sys.argv[3] if len(sys.argv) > 3 else None
    log(f"Operation: {operation}, text length: {len(text)}")

    tty_path = get_target_tty()
    if not tty_path:
        log("No TTY available, skipping")
        sys.exit(0)

    log(f"Using TTY: {tty_path}")

    try:
        with open(tty_path, "w") as tty_file:
            if operation == "clipboard":
                write_clipboard(tty_file, text)
            elif operation == "notify":
                send_notification(tty_file, text, title=title or "Notification")
            elif operation == "open":
                set_user_var(tty_file, text)
            elif operation == "codex":
                codex_notification(tty_file, text)
            else:
                log(f"Unknown operation: {operation}")
                print(f"Unknown operation: {operation}")
                sys.exit(1)
    except Exception as e:
        log(f"Error writing to {tty_path}: {e}")
        print(f"Error writing to {tty_path}: {e}")
        sys.exit(1)

    end_time = time.time()
    log(f"Script completed in {end_time - start_time:.3f}s")

if __name__ == "__main__":
    main()

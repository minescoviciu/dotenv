#!/usr/bin/env python3

import os
import sys
import base64


def write_clipboard(tty_file, text):
    """
    Write OSC-52 escape sequences to copy text into clipboard.
    Detect if we're inside tmux/screen based on environment variables.
    """
    in_tmux = "TMUX" in os.environ
    term = os.environ.get("TERM", "")
    in_screen_or_tmux = term.startswith("screen") or term.startswith("tmux")

    # Encode the text as base64
    encoded = base64.b64encode(text.encode("utf-8")).decode("utf-8")

    if in_tmux or in_screen_or_tmux:
        # tmux/screen version
        tty_file.write(f"\x1bPtmux;\x1b\x1b]52;c;{encoded}\a\x1b\\")
    else:
        # Normal version
        tty_file.write(f"\x1b]52;c;{encoded}\a")

    tty_file.flush()


def send_notification(tty_file, message):
    """
    Write WezTerm's notify escape sequence.
    We'll treat the argument as the "body", with a fixed title "Notification".
    """
    title = "Notification"
    in_tmux = "TMUX" in os.environ

    if in_tmux:
        tty_file.write(f"\x1bPtmux;\x1b\x1b]777;notify;{title};{message}\x1b\\")
    else:
        tty_file.write(f"\x1b]777;notify;{title};{message}\x1b\\")

    tty_file.flush()


def set_user_var(tty_file, value):
    """
    Write WezTerm's SetUserVar escape sequence (1337).
    Using a default var name "MYVAR".
    """
    var_name = "open-web"
    encoded_value = base64.b64encode(value.encode("utf-8")).decode("utf-8")
    in_tmux = "TMUX" in os.environ

    if in_tmux:
        tty_file.write(f"\x1bPtmux;\x1b\x1b]1337;SetUserVar={var_name}={encoded_value}\x07\x1b\\")
    else:
        tty_file.write(f"\x1b]1337;SetUserVar={var_name}={encoded_value}\x07")

    tty_file.flush()


def get_command_name(pid):
    """
    Return the command name of the process with the given PID
    by reading /proc/<pid>/comm.
    """
    try:
        with open(f"/proc/{pid}/comm", "r") as f:
            return f.read().strip()
    except (FileNotFoundError, PermissionError):
        return None


def get_ppid(pid):
    """
    Return the PPid (parent PID) of the given PID by parsing /proc/<pid>/status.
    """
    path = f"/proc/{pid}/status"
    try:
        with open(path, "r") as f:
            for line in f:
                if line.startswith("PPid:"):
                    parts = line.split()
                    if len(parts) == 2:
                        return int(parts[1])
    except (FileNotFoundError, PermissionError):
        pass
    return None


def get_tty_from_pid(pid):
    """
    Scan /proc/<pid>/fd/ for a descriptor that points to /dev/pts/* or /dev/tty.
    Return the first matching path found, or None if not found.
    """
    fd_dir = f"/proc/{pid}/fd"
    try:
        for fd_name in os.listdir(fd_dir):
            fd_path = os.path.join(fd_dir, fd_name)
            try:
                link_target = os.readlink(fd_path)
                # Check if it looks like a TTY path
                if link_target.startswith("/dev/pts/") or link_target == "/dev/tty":
                    return link_target
            except OSError:
                # Could happen if there's no permission or the fd disappeared
                pass
    except (FileNotFoundError, PermissionError):
        return None
    return None


def find_parent_nvim_tty():
    """
    Walk up the process tree from this script's parent PID,
    looking for a process named 'nvim'.
    If found, return the TTY path that nvim is using, or None.
    """
    pid = os.getppid()  # Start with the immediate parent
    while pid and pid > 1:
        cmd_name = get_command_name(pid)
        if cmd_name and "nvim" in cmd_name:
            # Found an nvim process
            tty = get_tty_from_pid(pid)
            if tty:
                return tty
        # Move up one level
        pid = get_ppid(pid)
    return None


def get_target_tty():
    """
    If NVIM is set in the environment, try to find a parent 'nvim' process TTY.
    Otherwise, return "/dev/tty".
    """
    if "NVIM" in os.environ:
        nvim_tty = find_parent_nvim_tty()
        if nvim_tty:
            return nvim_tty
    return "/dev/tty"


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <clipboard|notify|open> <text>")
        sys.exit(1)

    operation = sys.argv[1]
    text = sys.argv[2]

    tty_path = get_target_tty()

    try:
        with open(tty_path, "w") as tty_file:
            if operation == "clipboard":
                write_clipboard(tty_file, text)
            elif operation == "notify":
                send_notification(tty_file, text)
            elif operation == "open":
                set_user_var(tty_file, text)
            else:
                print(f"Unknown operation: {operation}")
                sys.exit(1)
    except Exception as e:
        print(f"Error writing to {tty_path}: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

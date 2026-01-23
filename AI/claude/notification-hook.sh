#!/bin/bash

# Claude Code notification hook
# Uses wezterm.py for notifications

# Get tmux session name (if in tmux)
tmux_session=""
if [[ -n "$TMUX" ]]; then
    tmux_session=$(tmux display-message -p '#S' 2>/dev/null)
fi

# Build notification title with tmux session
if [[ -n "$tmux_session" ]]; then
    title="Claude [$tmux_session]"
else
    title="Claude"
fi

# Notification chime
printf '\a'; sleep 0.05
printf '\a'; sleep 0.05
printf '\a'; sleep 0.15
printf '\a'; sleep 0.05
printf '\a'

# Send notification using wezterm.py
~/.config/scripts/wezterm.py notify "Needs attention" "$title" 2>/dev/null || true

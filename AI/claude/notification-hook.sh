#!/bin/bash

# Claude Code notification hook
# Uses wezterm.py for notifications

# Read hook event data from stdin
input=$(cat)

# Get hook type from JSON
hook_type=$(echo "$input" | jq -r '.hook_type // empty')
stop_reason=$(echo "$input" | jq -r '.stop_reason // empty')

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

# Determine message based on hook type
message=""
case "$hook_type" in
    Stop)
        case "$stop_reason" in
            end_turn)
                message="Needs attention"
                ;;
            stop_sequence|max_tokens)
                message="Finished task"
                ;;
            *)
                message="Stopped: $stop_reason"
                ;;
        esac
        ;;
    Notification)
        message=$(echo "$input" | jq -r '.message // "Needs attention"')
        ;;
esac

# Send notification using wezterm.py
if [[ -n "$message" ]]; then
    ~/.config/scripts/wezterm.py notify "$message" "$title" 2>/dev/null || true
fi

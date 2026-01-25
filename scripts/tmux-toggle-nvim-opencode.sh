#!/bin/bash
# Get current window name
current_window=$(tmux display-message -p '#W')

# Get list of all windows with their names
nvim_window=$(tmux list-windows -F '#{window_index}:#{window_name}' | grep -i 'nvim' | head -1 | cut -d: -f1)
claude_window=$(tmux list-windows -F '#{window_index}:#{window_name}' | grep -i 'claude' | head -1 | cut -d: -f1)
opencode_window=$(tmux list-windows -F '#{window_index}:#{window_name}' | grep -i 'opencode' | head -1 | cut -d: -f1)

# Determine where to go based on current location
case "$current_window" in
    *[Nn][Vv][Ii][Mm]*)
        # Currently in nvim, try to go to Claude, fallback to OpenCode
        if [ -n "$claude_window" ]; then
            tmux select-window -t "$claude_window"
        elif [ -n "$opencode_window" ]; then
            tmux select-window -t "$opencode_window"
        fi
        ;;
    *[Cc]laude*)
        # Currently in Claude, try to go to nvim
        if [ -n "$nvim_window" ]; then
            tmux select-window -t "$nvim_window"
        fi
        ;;
    *[Oo]pen[Cc]ode*)
        # Currently in OpenCode, try to go to nvim
        if [ -n "$nvim_window" ]; then
            tmux select-window -t "$nvim_window"
        fi
        ;;
    *)
        # In some other window, prefer nvim, then claude, then opencode
        if [ -n "$nvim_window" ]; then
            tmux select-window -t "$nvim_window"
        elif [ -n "$claude_window" ]; then
            tmux select-window -t "$claude_window"
        elif [ -n "$opencode_window" ]; then
            tmux select-window -t "$opencode_window"
        fi
        ;;
esac

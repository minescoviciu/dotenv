#!/bin/bash
# Pick a tmux session in an fzf list and switch the client to it.
#
# Replaces tmux-fzf's `session.sh switch`. Meant to be run from a display-popup
# binding: the popup gives fzf a tty of its own and belongs to the attached
# client, so it is always drawn where you are looking.

set -u

current=$(tmux display-message -p '#S')

# grep -x -F: match the whole line literally, so a session named "dev" does not
# also filter out "dev2" and a name with regex characters is not interpreted.
others=$(tmux list-sessions -F '#{session_name}' | grep -vxF "$current")

if [ -z "$others" ]; then
    tmux display-message "No other session to switch to"
    exit 0
fi

# No --reverse: fzf's default layout puts the prompt at the bottom with the list
# growing upward, which is how tmux-fzf presented this.
target=$(printf '%s\n' "$others" | fzf \
    --no-multi \
    --prompt='session> ' \
    --preview='tmux capture-pane -ep -t {}:' \
    --preview-window='right,68%,border-left') || exit 0

[ -n "$target" ] && exec tmux switch-client -t "$target"

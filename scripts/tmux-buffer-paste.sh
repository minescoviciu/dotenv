#!/bin/bash
# Pick a tmux paste buffer in an fzf list and paste it into the current pane.
#
# Replaces tmux-fzf's clipboard.sh in buffer mode, which is the mode it used
# here anyway since copyq is not installed. Mainly this is how the named
# snippets set by snippets.sh (oob, inband, dc0, ...) get pasted.
#
# Meant to be run from a display-popup binding. Inside a popup tmux still
# resolves #{pane_id} to the pane underneath, so the paste target is captured up
# front and passed explicitly rather than relying on what "current" means by the
# time paste-buffer runs.

set -u

target=$(tmux display-message -p '#{pane_id}')

# name<TAB>sample: the sample is shown so the list can be searched by content,
# and cut takes the name back off the selected line. A tab is used because
# buffer contents routinely contain colons and spaces.
listing=$(tmux list-buffers -F '#{buffer_name}	#{buffer_sample}')

if [ -z "$listing" ]; then
    tmux display-message "No paste buffers"
    exit 0
fi

selected=$(printf '%s\n' "$listing" | fzf \
    --reverse \
    --no-multi \
    --prompt='buffer> ' \
    --delimiter='\t' \
    --preview='tmux show-buffer -b {1}' \
    --preview-window='right,60%,border-left') || exit 0

[ -z "$selected" ] && exit 0

buffer=$(printf '%s' "$selected" | cut -f1)
[ -n "$buffer" ] && exec tmux paste-buffer -b "$buffer" -t "$target"

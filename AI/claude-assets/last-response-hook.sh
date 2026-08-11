#!/bin/bash

# Claude Code Stop hook
# Records when the last response landed, for the statusline to display.
# The statusline input carries no timestamp, so it is stamped here instead.

session=$(jq -r '.session_id // empty' 2>/dev/null)
[[ -z "$session" ]] && session="unknown"

date +%H:%M > "/tmp/claude-last-response-${session}"

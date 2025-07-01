#!/bin/bash

_fzf_extract() {
    local line="$1" r=()
    r+=($(echo "$line" | grep -oE '\b[0-9]{1,5}\b' | awk '$1>=1&&$1<=99999{print "PID:"$1}'))
    r+=($(echo "$line" | grep -oE '\b[a-f0-9]{7,40}\b' | sed 's/^/Hash:/'))
    r+=($(echo "$line" | grep -oE '(/[^[:space:]]*|[^[:space:]]*\.[a-zA-Z0-9]+)' | sed 's/^/File:/'))
    r+=($(echo "$line" | grep -oE 'https?://[^[:space:]]+' | sed 's/^/URL:/'))
    r+=($(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sed 's/^/IPv4:/'))
    r+=($(echo "$line" | grep -oiE '\b([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}\b|\b([0-9a-f]{1,4}:){1,7}:|\b:([0-9a-f]{1,4}:){1,7}\b|\b([0-9a-f]{1,4}:){1,6}:[0-9a-f]{1,4}\b' | sed 's/^/IPv6:/'))
    r+=($(echo "$line" | grep -oiE '\b[0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}\b' | sed 's/^/MAC:/'))
    case ${#r[@]} in
    0) echo "$line" ;;
    1) echo "__input__${r[0]#*:}" ;;
    *) selected=$(printf '%s\n' "${r[@]}" | fzf --prompt="Select: "); [[ -n "$selected" ]] && echo "__input__${selected#*:}" ;;
    esac
}

_fzf_extract "$1"


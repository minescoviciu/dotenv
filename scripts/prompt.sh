#!/bin/bash

BASE="\033[38;2;30;30;46m"       # base
MANTLE="\033[38;2;24;24;37m"     # mantle
SURFACE0="\033[38;2;49;50;68m"   # surface0
SURFACE1="\033[38;2;69;71;90m"   # surface1
SURFACE2="\033[38;2;88;91;112m"  # surface2
TEXT="\033[38;2;205;214;244m"    # text
ROSEWATER="\033[38;2;245;224;220m" # rosewater
LAVENDER="\033[38;2;180;190;254m" # lavender
RED="\033[38;2;243;139;168m"     # red
PEACH="\033[38;2;250;179;135m"   # peach
YELLOW="\033[38;2;249;226;175m"  # yellow
GREEN="\033[38;2;166;227;161m"   # green
TEAL="\033[38;2;148;226;213m"    # teal
BLUE="\033[38;2;137;180;250m"    # blue
MAUVE="\033[38;2;203;166;247m"   # mauve
FLAMINGO="\033[38;2;242;205;205m" # flamingo
RESET="\033[0m"                  # Reset to default color
BLINK="\033[5m"
ARROW=$'\uf061'
START_PROMPT="\033]133;A\007"
STOP_PROMPT="\033]133;B\007"

find_git_branch() {
  # Based on: http://stackoverflow.com/a/13003854/170413
  local branch
  if branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null); then
    if [[ "$branch" == "HEAD" ]]; then
      branch='detached*'
    fi
    git_branch=$'\ue725'"($branch)"
  else
    git_branch=""
  fi
}

find_git_dirty() {
  local status=$(git status --porcelain 2> /dev/null)
  if [[ "$status" != "" ]]; then
    git_dirty=$'\uf192'
  else
    git_dirty=''
  fi
}

git_operation_status() {
    local git_dir="$(git rev-parse --git-dir 2>/dev/null)"
    git_state=""
    
    if [ -d "$git_dir" ]; then
        # Check for rebase
        if [ -d "$git_dir/rebase-merge" ]; then
            local step=$(cat "$git_dir/rebase-merge/msgnum" 2>/dev/null)
            local total=$(cat "$git_dir/rebase-merge/end" 2>/dev/null)
            if [ -n "$step" ] && [ -n "$total" ]; then
                git_state="[REBASE $step/$total]"
            else
                git_state="[REBASE]"
            fi
        elif [ -d "$git_dir/rebase-apply" ]; then
            local step=$(cat "$git_dir/rebase-apply/next" 2>/dev/null)
            local total=$(cat "$git_dir/rebase-apply/last" 2>/dev/null)
            if [ -n "$step" ] && [ -n "$total" ]; then
                git_state="[REBASE $step/$total]"
            else
                git_state="[REBASE]"
            fi
        # Check for cherry-pick
        elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
            git_state="[CHERRY-PICK]"
        elif [ -f "$git_dir/MERGE_HEAD" ]; then
            git_state="[MERGE]"
        elif [ -f "$git_dir/REVERT_HEAD" ]; then
            git_state="[REVERT]"
        elif [ -f "$git_dir/BISECT_LOG" ]; then
            local bisect_count=$(grep -c "^git bisect" "$git_dir/BISECT_LOG" 2>/dev/null)
            if [ -n "$bisect_count" ]; then
                git_state="[BISECT $bisect_count]"
            else
                git_state="[BISECT]"
            fi
        fi
    fi
}

check_disk_space() {
    # Get the filesystem information for current directory
    local df_output=$(df -Pk . | awk 'NR==2 {print}')
    # Extract usage percentage (Capacity column)
    local capacity=$(echo "$df_output" | awk '{print $5}')
    # Default threshold is 90% if DISK_THRESHOLD is not set
    local threshold=${DISK_THRESHOLD:-80}
    disk_full=''
    # Check if capacity is a number with % (valid filesystem)
    if [[ "$capacity" =~ ^[0-9]+%$ ]]; then
        # Remove the % sign and convert to number
        local current_usage=${capacity/\%/}
        if [ "$current_usage" -gt "$threshold" ]; then
            disk_full=" "$'\uf0c7'" "
        fi
    fi
}

format_pwd() {
    local dir="$PWD"
    
    # Check if we're in a git repository
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local git_base_dir=$(git rev-parse --show-toplevel)
        local repo_name=$(basename "$git_base_dir")
        
        # Replace git path with repo name
        if [[ "$dir" == "$git_base_dir"* ]]; then
            dir="${repo_name}${dir#$git_base_dir}"
        fi
    fi

    # Replace home directory with ~
    local home_dir="$HOME"
    if [[ "$dir" == "$home_dir"* ]]; then
        dir="~${dir#$home_dir}"
    fi
    
    # Add [^/]* to sef for extra directories
    if [[ $(echo "$dir" | grep -o '/' | wc -l) -gt 4 ]]; then
        dir=$(echo "$dir" | sed 's|.*/\([^/]*/[^/]*/[^/]*/[^/]*\)$|.../\1|')
    fi

    formated_pwd="$dir"
}

if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    # Do not use PROMPT_COMMAND as it conflicts with Cursor's run in terminal mode
    # It doesn't even like to define it here...
    PS1="\[${TEAL}\]\w\[${RESET}\]\[${GREEN}\]${ARROW}\[${RESET}\]"
else
    PROMPT_COMMAND="find_git_branch; find_git_dirty; check_disk_space; format_pwd; git_operation_status;"

    # PS1="\[${FLAMINGO}\]\${git_dirty}\[${RESET}\] \[${BLUE}\]\${formated_pwd}\[${RESET}\] \[${LAVENDER}\]\${git_branch}\[${RESET}\] \[${RED}\]\${disk_full}\[${RESET}\] > "
    PS1="\[$START_PROMPT\]\[${TEAL}\]\${formated_pwd}\[${RESET}\] \[${MAUVE}\]\${git_branch}\[${RESET}\]\[${YELLOW}\]\${git_state}\[${RESET}\]\[${PEACH}\]\${git_dirty}\[${RESET}\]\[${BLINK}${RED}\]\${disk_full}\[${RESET}\]\[${GREEN}\]${ARROW}\[${RESET}\]\[$STOP_PROMPT\]"
fi


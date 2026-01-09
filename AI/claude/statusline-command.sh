#!/bin/bash

# Color scheme (Catppuccin Mocha)
BASE="\033[38;2;30;30;46m"
MANTLE="\033[38;2;24;24;37m"
SURFACE0="\033[38;2;49;50;68m"
SURFACE1="\033[38;2;69;71;90m"
SURFACE2="\033[38;2;88;91;112m"
TEXT="\033[38;2;205;214;244m"
ROSEWATER="\033[38;2;245;224;220m"
LAVENDER="\033[38;2;180;190;254m"
RED="\033[38;2;243;139;168m"
PEACH="\033[38;2;250;179;135m"
YELLOW="\033[38;2;249;226;175m"
GREEN="\033[38;2;166;227;161m"
TEAL="\033[38;2;148;226;213m"
BLUE="\033[38;2;137;180;250m"
MAUVE="\033[38;2;203;166;247m"
FLAMINGO="\033[38;2;242;205;205m"
RESET="\033[0m"
BLINK="\033[5m"
ARROW=$'\uf061'

# Read stdin JSON input
input=$(cat)

# Get current directory from JSON input
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
cd "$current_dir" 2>/dev/null || true

# Find git branch
find_git_branch() {
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

# Check if git dirty
find_git_dirty() {
  local status=$(git status --porcelain 2> /dev/null)
  if [[ "$status" != "" ]]; then
    git_dirty=$'\uf192'
  else
    git_dirty=''
  fi
}

# Check git operation status
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

# Check disk space
check_disk_space() {
    local df_output=$(df -Pk . | awk 'NR==2 {print}')
    local capacity=$(echo "$df_output" | awk '{print $5}')
    local threshold=${DISK_THRESHOLD:-80}
    disk_full=''
    if [[ "$capacity" =~ ^[0-9]+%$ ]]; then
        local current_usage=${capacity/\%/}
        if [ "$current_usage" -gt "$threshold" ]; then
            disk_full=" "$'\uf0c7'" "
        fi
    fi
}

# Format pwd
format_pwd() {
    local dir="$current_dir"

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

    # Shorten if too many directory levels
    if [[ $(echo "$dir" | grep -o '/' | wc -l) -gt 4 ]]; then
        dir=$(echo "$dir" | sed 's|.*/\([^/]*/[^/]*/[^/]*/[^/]*\)$|.../\1|')
    fi

    formated_pwd="$dir"
}

# Execute all functions
find_git_branch
find_git_dirty
check_disk_space
format_pwd
git_operation_status

# Build and print the prompt (removed trailing arrow as it would act as a prompt character)
printf "${TEAL}${formated_pwd}${RESET} ${MAUVE}${git_branch}${RESET}${YELLOW}${git_state}${RESET}${PEACH}${git_dirty}${RESET}${BLINK}${RED}${disk_full}${RESET}"

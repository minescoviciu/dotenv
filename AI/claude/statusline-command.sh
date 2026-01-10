#!/bin/bash

# Color scheme (Catppuccin Mocha)
TEXT=$'\033[38;2;205;214;244m'
LAVENDER=$'\033[38;2;180;190;254m'
RED=$'\033[38;2;243;139;168m'
PEACH=$'\033[38;2;250;179;135m'
YELLOW=$'\033[38;2;249;226;175m'
GREEN=$'\033[38;2;166;227;161m'
TEAL=$'\033[38;2;148;226;213m'
BLUE=$'\033[38;2;137;180;250m'
MAUVE=$'\033[38;2;203;166;247m'
RESET=$'\033[0m'

# Read stdin JSON input
input=$(cat)

# Get current directory from JSON input
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
cd "$current_dir" 2>/dev/null || true

# Get Claude Code model info
get_model_info() {
    local model=$(echo "$input" | jq -r '.model // empty')
    model_icon=""

    if [[ -n "$model" ]]; then
        case "$model" in
            *opus*)
                model_icon="🔮opus"
                ;;
            *sonnet*)
                model_icon="🤖sonnet"
                ;;
            *haiku*)
                model_icon="⚡haiku"
                ;;
            *)
                model_icon="🤖${model}"
                ;;
        esac
    fi
}

# Get permission mode
get_permission_mode() {
    local mode=$(echo "$input" | jq -r '.permission_mode // empty')
    permission_mode=""

    if [[ -n "$mode" ]]; then
        case "$mode" in
            plan)
                permission_mode="⏸plan"
                ;;
            auto-accept)
                permission_mode="⏵⏵auto"
                ;;
            normal|*)
                permission_mode=""
                ;;
        esac
    fi
}

# Get background tasks count
get_background_tasks() {
    local tasks=$(echo "$input" | jq -r '.background_tasks // 0')
    background_tasks=""

    if [[ "$tasks" -gt 0 ]]; then
        background_tasks="⚙${tasks}"
    fi
}

# Get token usage indicator
get_token_usage() {
    # Read context window data
    local total=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
    local input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
    local output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

    token_indicator=""
    token_percent=0

    if [[ "$total" -gt 0 ]]; then
        # Messages = input + output tokens (conversation)
        local messages=$((input_tokens + output_tokens))
        # Estimate system overhead (prompt + tools + MCP) at ~25k
        local overhead=25000
        # Total used in context (approximate)
        local used=$((messages + overhead))

        token_percent=$((used * 100 / total))
        local remaining=$((total - used))
        local used_k=$((used / 1000))
        local total_k=$((total / 1000))

        # Format: used/total [percent%]
        token_indicator="📊${used_k}k/${total_k}k[${token_percent}%]"
    fi
}

# Find git branch
find_git_branch() {
    local branch
    if branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null); then
        if [[ "$branch" == "HEAD" ]]; then
            branch='detached*'
        fi
        git_branch=" ${branch}"
    else
        git_branch=""
    fi
}

# Check if git dirty
find_git_dirty() {
    local status=$(git status --porcelain 2> /dev/null)
    if [[ "$status" != "" ]]; then
        git_dirty="*"
    else
        git_dirty=''
    fi
}

# Check ahead/behind remote
check_git_remote_status() {
    git_remote=""

    if git rev-parse --git-dir &>/dev/null; then
        local upstream=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)

        if [[ -n "$upstream" ]]; then
            local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
            local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

            if [[ "$ahead" -gt 0 ]]; then
                git_remote="${git_remote}↑${ahead}"
            fi

            if [[ "$behind" -gt 0 ]]; then
                git_remote="${git_remote}↓${behind}"
            fi
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
get_model_info
get_permission_mode
get_background_tasks
get_token_usage
format_pwd
find_git_branch
find_git_dirty
check_git_remote_status

# Build statusline
# Format: [model] [permission_mode] [tasks] [token] [pwd] [git_branch][dirty][remote]
output=""

# Claude Code Status (Priority 1)
[[ -n "$model_icon" ]] && output="${output}${BLUE}${model_icon}${RESET} "
[[ -n "$permission_mode" ]] && output="${output}${YELLOW}${permission_mode}${RESET} "
[[ -n "$background_tasks" ]] && output="${output}${PEACH}${background_tasks}${RESET} "

# Token usage with color based on remaining context
if [[ -n "$token_indicator" ]]; then
    if [[ "$token_percent" -gt 80 ]]; then
        output="${output}${RED}${token_indicator}${RESET} "
    elif [[ "$token_percent" -gt 50 ]]; then
        output="${output}${YELLOW}${token_indicator}${RESET} "
    else
        output="${output}${GREEN}${token_indicator}${RESET} "
    fi

fi

# Current directory
output="${output}${TEAL}${formated_pwd}${RESET}"

# Git Info (Priority 2)
if [[ -n "$git_branch" ]]; then
    output="${output}${MAUVE}${git_branch}${RESET}"
    [[ -n "$git_dirty" ]] && output="${output}${PEACH}${git_dirty}${RESET}"
    [[ -n "$git_remote" ]] && output="${output}${LAVENDER}${git_remote}${RESET}"
fi

printf "%s" "$output"

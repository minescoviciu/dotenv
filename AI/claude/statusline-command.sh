#!/bin/bash

# Claude Code Statusline - 3-line display
# Line 1: model | permission | tokens used/total | %used | thinking
# Line 2: current: <bar> | weekly: <bar> | [extra: <bar>]
# Line 3: resets time | resets datetime | pwd git_branch

# ── Colors (Catppuccin Mocha) ──────────────────────────────────────
TEXT=$'\033[38;2;205;214;244m'
LAVENDER=$'\033[38;2;180;190;254m'
RED=$'\033[38;2;243;139;168m'
PEACH=$'\033[38;2;250;179;135m'
YELLOW=$'\033[38;2;249;226;175m'
GREEN=$'\033[38;2;166;227;161m'
TEAL=$'\033[38;2;148;226;213m'
BLUE=$'\033[38;2;137;180;250m'
MAUVE=$'\033[38;2;203;166;247m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# ── Paths & constants ──────────────────────────────────────────────
CACHE_FILE=/tmp/claude-statusline-usage-cache.json
CACHE_TTL=60
KEYCHAIN_SERVICE="Claude Code-credentials"
SETTINGS_FILE="$HOME/.claude/settings.json"
SEP=" ${DIM}|${RESET} "

# ── Read stdin JSON ────────────────────────────────────────────────
input=$(cat)
if [[ -z "$input" ]]; then
    printf "Claude"
    exit 0
fi

# Debug: dump raw JSON for inspection
echo "$input" > /tmp/claude-statusline-debug.json

# Parse fields individually (robust across bash versions)
model=$(echo "$input" | jq -r 'if .model | type == "object" then .model.id // .model.display_name // "" else .model // "" end')
permission_mode=$(echo "$input" | jq -r '.permission_mode // ""')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
remain_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // 0')

# ── Helpers ────────────────────────────────────────────────────────
format_number() {
    LC_NUMERIC=en_US.UTF-8 printf "%'d" "$1" 2>/dev/null || printf "%d" "$1"
}

format_tokens() {
    local n=$1
    if (( n >= 1000000 )); then
        local whole=$(( n / 1000000 ))
        local frac=$(( (n % 1000000) / 100000 ))
        printf "%d.%dm" "$whole" "$frac"
    elif (( n >= 1000 )); then
        printf "%dk" "$(( n / 1000 ))"
    else
        printf "%d" "$n"
    fi
}

token_color() {
    local pct=$1
    if (( pct > 80 )); then printf "%s" "$RED"
    elif (( pct > 50 )); then printf "%s" "$YELLOW"
    else printf "%s" "$GREEN"; fi
}

bar_color() {
    local pct=$1
    if (( pct >= 90 )); then printf "%s" "$RED"
    elif (( pct >= 70 )); then printf "%s" "$YELLOW"
    elif (( pct >= 50 )); then printf "%s" "$PEACH"
    else printf "%s" "$GREEN"; fi
}

progress_bar() {
    local pct=$1
    (( pct < 0 )) && pct=0
    (( pct > 100 )) && pct=100
    local filled=$(( pct * 10 / 100 ))
    local empty=$(( 10 - filled ))
    local color
    color=$(bar_color "$pct")

    local bar=""
    for (( i=0; i<filled; i++ )); do bar+="●"; done
    local empty_bar=""
    for (( i=0; i<empty; i++ )); do empty_bar+="○"; done

    printf "%s%s%s%s%s %s%d%%%s" "$color" "$bar" "$DIM" "$empty_bar" "$RESET" "$color" "$pct" "$RESET"
}

format_reset_time() {
    local iso="$1"
    local style="$2" # "time" or "datetime"
    [[ -z "$iso" || "$iso" == "null" ]] && return

    # Extract date and time parts (strip timezone)
    local date_part="${iso%%T*}"
    local time_full="${iso##*T}"
    local hour="${time_full%%:*}"
    local rest="${time_full#*:}"
    local minute="${rest%%:*}"

    # 24h -> 12h
    local h=$((10#$hour))
    local ampm="am"
    (( h >= 12 )) && ampm="pm"
    (( h > 12 )) && h=$(( h - 12 ))
    (( h == 0 )) && h=12

    if [[ "$style" == "time" ]]; then
        printf "%d:%s%s" "$h" "$minute" "$ampm"
    else
        local md="${date_part#*-}"
        local month="${md%%-*}"
        local day="${md##*-}"
        local d=$((10#$day))
        local months=(jan feb mar apr may jun jul aug sep oct nov dec)
        local m=$((10#$month - 1))
        printf "%s %d, %d:%s%s" "${months[$m]}" "$d" "$h" "$minute" "$ampm"
    fi
}

# ── API Usage (cached) ────────────────────────────────────────────
fetch_usage() {
    # Check cache freshness (stat -f %m is BSD/macOS for mtime epoch)
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_mtime
        cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
        local now
        now=$(date +%s)
        if (( now - cache_mtime < CACHE_TTL )); then
            cat "$CACHE_FILE"
            return 0
        fi
    fi

    # Need refresh - get token from macOS keychain
    local token
    token=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [[ -z "$token" ]]; then
        [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE"
        return 1
    fi

    # Call API (3s timeout)
    local response
    response=$(curl -s --max-time 3 \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "User-Agent: claude-code/2.1.34" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [[ $? -eq 0 ]] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
        echo "$response" > "$CACHE_FILE"
        echo "$response"
        return 0
    fi

    # Fallback to stale cache
    [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE"
    return 1
}

# ══════════════════════════════════════════════════════════════════
# BUILD LINE 1: model | permission | tokens | thinking
# ══════════════════════════════════════════════════════════════════
line1=""

# Model
case "$model" in
    *opus*)   line1+="${BLUE}🔮opus${RESET}" ;;
    *sonnet*) line1+="${BLUE}🤖sonnet${RESET}" ;;
    *haiku*)  line1+="${BLUE}⚡haiku${RESET}" ;;
    "")       line1+="${BLUE}Claude${RESET}" ;;
    *)        line1+="${BLUE}🤖${model}${RESET}" ;;
esac

# Permission mode
case "$permission_mode" in
    plan)        line1+=" ${YELLOW}⏸plan${RESET}" ;;
    auto-accept) line1+=" ${YELLOW}⏵⏵auto${RESET}" ;;
esac

# Token usage
if (( ctx_size > 0 )); then
    pct_used=$used_pct
    pct_remain=$remain_pct
    used=$(( ctx_size * pct_used / 100 ))
    remaining=$(( ctx_size - used ))

    tc=$(token_color "$pct_used")

    line1+="${SEP}${TEXT}$(format_tokens $used)/$(format_tokens $ctx_size)${RESET}"
    line1+="${SEP}${tc}${pct_used}%${RESET} ${DIM}($(format_number $used))${RESET} ${TEXT}used${RESET}"
fi

# Thinking status
thinking="off"
thinking_color="$DIM"
if [[ -f "$SETTINGS_FILE" ]]; then
    tv=$(jq -r '.alwaysThinkingEnabled // false' "$SETTINGS_FILE" 2>/dev/null)
    if [[ "$tv" == "true" ]]; then
        thinking="on"
        thinking_color="$GREEN"
    fi
fi
line1+="${SEP}${thinking_color}thinking: ${thinking}${RESET}"

# ══════════════════════════════════════════════════════════════════
# FETCH & PARSE API USAGE
# ══════════════════════════════════════════════════════════════════
usage_json=$(fetch_usage)

five_hour_pct=0; seven_day_pct=0; extra_enabled="false"
five_hour_reset_iso=""; seven_day_reset_iso=""
extra_pct=0; extra_used_cents=0; extra_limit_cents=0

if [[ -n "$usage_json" ]]; then
    IFS=$'\t' read -r five_hour_pct seven_day_pct extra_enabled extra_pct \
        extra_used_cents extra_limit_cents five_hour_reset_iso seven_day_reset_iso <<< \
        "$(echo "$usage_json" | jq -r '[
            (.five_hour.utilization // 0 | round | tostring),
            (.seven_day.utilization // 0 | round | tostring),
            (.extra_usage.is_enabled // false | tostring),
            (.extra_usage.utilization // 0 | round | tostring),
            (.extra_usage.used_credits // 0 | round | tostring),
            (.extra_usage.monthly_limit // 0 | round | tostring),
            (.five_hour.resets_at // ""),
            (.seven_day.resets_at // "")
        ] | @tsv')"
fi

# ══════════════════════════════════════════════════════════════════
# BUILD LINE 2: current bar | weekly bar | [extra bar]
# ══════════════════════════════════════════════════════════════════
line2=""
if [[ -n "$usage_json" ]]; then
    line2+="${TEXT}current:${RESET} $(progress_bar "$five_hour_pct")"
    line2+="${SEP}${TEXT}weekly:${RESET} $(progress_bar "$seven_day_pct")"

    if [[ "$extra_enabled" == "true" ]]; then
        ed=$(( extra_used_cents / 100 ))
        ec=$(( extra_used_cents % 100 ))
        ld=$(( extra_limit_cents / 100 ))
        lc=$(( extra_limit_cents % 100 ))
        line2+="${SEP}${TEXT}extra:${RESET} $(progress_bar "$extra_pct") ${DIM}\$${ed}.$(printf '%02d' $ec)/\$${ld}.$(printf '%02d' $lc)${RESET}"
    fi
else
    line2+="${DIM}usage: unavailable${RESET}"
fi

# ══════════════════════════════════════════════════════════════════
# BUILD LINE 3: resets | pwd | git branch
# ══════════════════════════════════════════════════════════════════
line3=""

if [[ -n "$usage_json" && -n "$five_hour_reset_iso" ]]; then
    fh_reset=$(format_reset_time "$five_hour_reset_iso" "time")
    sd_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
    line3+="${TEXT}resets${RESET} ${LAVENDER}${fh_reset}${RESET}"
    line3+="${SEP}${TEXT}resets${RESET} ${LAVENDER}${sd_reset}${RESET}"
    line3+="${SEP}"
fi

# PWD (replace $HOME with ~)
dir="${current_dir/#$HOME/\~}"
line3+="${TEAL}${dir}${RESET}"

# Git branch
if cd "$current_dir" 2>/dev/null; then
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        [[ "$branch" == "HEAD" ]] && branch="detached*"
        line3+="${MAUVE}  ${branch}${RESET}"
    fi
fi

# ── Output ─────────────────────────────────────────────────────────
printf "%s\n%s\n%s" "$line1" "$line2" "$line3"

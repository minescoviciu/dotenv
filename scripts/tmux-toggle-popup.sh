#!/bin/bash

log() {
    if DEBUG_TOGGLE=1; then
        local date_format="%Y-%m-%d %H:%M:%S"
        local timestamp=$(date +"${date_format}")
        local log_prefix="[${timestamp}]"
        local log_message="$1"
        echo "${log_prefix} ${log_message}" >> /tmp/tmux_toggle.log
    fi
}

toggle_popup() {
    if [[ $(tmux display -p '#S') == "_popup_"* ]]; then
        tmux detach-client
        exit
    fi
    tmux display-popup -E "$(declare -f attach_to_popup_session); $(declare -f log); attach_to_popup_session $@"
}

attach_to_popup_session() {

    session="_popup_$(tmux display -p '#S')"
    if ! tmux has -t "$session" 2> /dev/null; then
        log "No session found"
        session_id="$(tmux new-session -dP -s "$session" -F '#{session_id}' $@ )"
        tmux set-option -s -t "$session_id" key-table popup
        tmux set-option -s -t "$session_id" status off
        session="$session_id"
    fi

    log "Attaching to session: $session"
    exec tmux attach -t "$session" > /dev/null

}


log "Open log with script: $@"
# TODO Not working with more then one arg ?!
toggle_popup $@

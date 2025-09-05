#!/bin/bash

export PROMPT_TOOLKIT_COLOR_DEPTH=DEPTH_24_BIT
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# for macos suppress default shell message see https://support.apple.com/en-gb/102360
export BASH_SILENCE_DEPRECATION_WARNING=1

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=2000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# one tab complition 
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ls='ls --color=auto'
alias ll='ls -laF'

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

source ~/.config/scripts/prompt.sh
source ~/.config/scripts/create_pr.sh
SECRETS_FILE=~/.config/scripts/secrets.sh
echo $SECRETS_FILE
if [ -f $SECRETS_FILE ]; then
    source $SECRETS_FILE
fi
# eval "$(starship init bash)"

copy-clipboard() {
    # Read input from argument or stdin
    if [ -n "$1" ]; then
        input="$1"
    else
        input=$(cat)
    fi
    if [[ "$TERM" =~ ^(screen|tmux) ]]; then
      printf "\033Ptmux;\033\033]52;c;$(printf "$input" | base64 -w 0)\a\033\\" > /dev/tty
    else
      printf "\033]52;c;$(printf "$input" | base64 -w 0)\a" > /dev/tty
    fi
    # printf "\033]52;c;$(printf "%s" "$input" | base64)\a"
}

__wezterm_set_user_var() {
  if hash base64 2>/dev/null ; then
    if [[ -z "${TMUX}" ]] ; then
      printf "\033]1337;SetUserVar=%s=%s\007" "$1" `echo -n "$2" | base64` > /dev/tty
    else
      # <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it>
      # Note that you ALSO need to add "set -g allow-passthrough on" to your tmux.conf
      printf "\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\" "$1" `echo -n "$2" | base64` > /dev/tty
    fi
  fi
}

__wezterm_send_notification() {
    if [[ -z "${TMUX}" ]] ; then
      printf "\e]777;notify;%s;%s\e\\" $1 $2 > /dev/tty
    else
      printf "\033Ptmux;\033\e]777;notify;%s;%s\e\\" $1 $2 > /dev/tty
    fi

}

alias alert='__wezterm_send_notification Done'

__wezterm_open_web() {
    __wezterm_set_user_var "open-web" "$1"
}

#!/usr/bin/env bash

# Copy of https://github.com/Bash-it/bash-it/blob/master/completion/available/tmux.completion.bash
# and https://github.com/przepompownia/bash-it/blob/master/completion/available/tmux.completion.bash
# slightly refactored

# tmux completion
# See: http://www.debian-administration.org/articles/317 for how to write more.
# Usage: Put "source bash_completion_tmux.sh" into your .bashrc
# Based upon the example at http://paste-it.appspot.com/Pj4mLycDE

function _tmux_complete_client() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(tmux "$@" list-clients -F '#{client_tty}' 2> /dev/null)" -- "${cur}") )
    options=""
    return 0
}

function _tmux_complete_session() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(tmux "$@" list-sessions -F '#{session_name}' 2> /dev/null)" -- "${cur}") )
    options=""
    return 0
}

function _tmux_complete_window() {
    local IFS=$'\n'
    local cur="${1}" && shift
    local session_name="$(echo "${cur}" | sed 's/\\//g' | cut -d ':' -f 1)"
    local sessions

    sessions="$(tmux "$@" list-sessions 2> /dev/null | sed -re 's/([^:]+:).*$/\1/')"
    if [[ -n "${session_name}" ]]; then
        sessions="${sessions}
        $(tmux "$@" list-windows -t "${session_name}" 2> /dev/null | sed -re 's/^([^:]+):.*$/'"${session_name}"':\1/')"
    fi
    cur="$(echo "${cur}" | sed -e 's/:/\\\\:/')"
    sessions="$(echo "${sessions}" | sed -e 's/:/\\\\:/')"
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "${sessions}" -- "${cur}") )
    options=""
    return 0
}

function _tmux_complete_socket_name() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(find /tmp/tmux-$UID -type s -printf '%P\n')" -- "${cur}") )
    options=""
    return 0
}
function _tmux_complete_socket_path() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(find /tmp/tmux-$UID -type s -printf '%p\n')" -- "${cur}") )
    options=""
    return 0
}

####################################################################################################
#                                       TMUX COMPLETION                                            #
#     https://raw.githubusercontent.com/imomaliev/tmux-bash-completion/master/completions/tmux     #
####################################################################################################

# Copy of https://github.com/Bash-it/bash-it/blob/master/completion/available/tmux.completion.bash
# and https://github.com/przepompownia/bash-it/blob/master/completion/available/tmux.completion.bash
# slightly refactored

# tmux completion
# See: http://www.debian-administration.org/articles/317 for how to write more.
# Usage: Put "source bash_completion_tmux.sh" into your .bashrc
# Based upon the example at http://paste-it.appspot.com/Pj4mLycDE

function _tmux_complete_client() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(tmux "$@" list-clients -F '#{client_tty}' 2> /dev/null)" -- "${cur}") )
    options=""
    return 0
}

function _tmux_complete_session() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(tmux "$@" list-sessions -F '#{session_name}' 2> /dev/null)" -- "${cur}") )
    options=""
    return 0
}

function _tmux_complete_window() {
    local IFS=$'\n'
    local cur="${1}" && shift
    local session_name="$(echo "${cur}" | sed 's/\\//g' | cut -d ':' -f 1)"
    local sessions

    sessions="$(tmux "$@" list-sessions 2> /dev/null | sed -re 's/([^:]+:).*$/\1/')"
    if [[ -n "${session_name}" ]]; then
        sessions="${sessions}
        $(tmux "$@" list-windows -t "${session_name}" 2> /dev/null | sed -re 's/^([^:]+):.*$/'"${session_name}"':\1/')"
    fi
    cur="$(echo "${cur}" | sed -e 's/:/\\\\:/')"
    sessions="$(echo "${sessions}" | sed -e 's/:/\\\\:/')"
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "${sessions}" -- "${cur}") )
    options=""
    return 0
}

function _tmux_complete_socket_name() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(find /tmp/tmux-$UID -type s -printf '%P\n')" -- "${cur}") )
    options=""
    return 0
}
function _tmux_complete_socket_path() {
    local IFS=$'\n'
    local cur="${1}" && shift
    COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "$(find /tmp/tmux-$UID -type s -printf '%p\n')" -- "${cur}") )
    options=""
    return 0
}

__tmux_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref cur prev words cword
}

_tmux() {
    local cur prev words cword;
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion
    else
        __tmux_init_completion
    fi

    local index=1
    # Check tmux options that will change completion for:
    # - available sessions
    # - available windows
    # - ...
    local argv=( "${words[@]:1}" )
    local OPTIND OPTARG OPTERR=0 flag tmux_args=()
    while getopts "L:S:" flag "${argv[@]}"; do
        case "$flag" in
            L) tmux_args+=(-L "$OPTARG") ;;
            S) tmux_args+=(-S "$OPTARG") ;;
            *) ;;
        esac
    done
    # Completed -- have a space after
    if [[ ${#words[@]} -gt $OPTIND ]]; then
        local tmux_argc=${#tmux_args[@]}
        (( index+=tmux_argc ))
        (( cword-=tmux_argc ))
    fi

    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($( compgen -W "$(tmux start\; list-commands | cut -d' ' -f1)" -- "$cur" ));
        return 0
    else
        case ${words[index]} in
            -L) _tmux_complete_socket_name "${cur}" ;;
            -S) _tmux_complete_socket_path "${cur}" ;;

            attach-session|attach)
            case "$prev" in
                -t) _tmux_complete_session "${cur}" "${tmux_args[@]}" ;;
                *) options="-t -d" ;;
            esac ;;
            detach-client|detach)
            case "$prev" in
                -t) _tmux_complete_client "${cur}" "${tmux_args[@]}" ;;
                *) options="-t" ;;
            esac ;;
            lock-client|lockc)
            case "$prev" in
                -t) _tmux_complete_client "${cur}" "${tmux_args[@]}" ;;
                *) options="-t" ;;
            esac ;;
            lock-session|locks)
            case "$prev" in
                -t) _tmux_complete_session "${cur}" "${tmux_args[@]}" ;;
                *) options="-t -d" ;;
            esac ;;
            new-session|new)
            case "$prev" in
                -t) _tmux_complete_session "${cur}" "${tmux_args[@]}" ;;
                -[n|d|s]) options="-d -n -s -t --" ;;
                *)
                if [[ ${COMP_WORDS[option_index]} == -- ]]; then
                    _command_offset ${option_index}
                else
                    options="-d -n -s -t --"
                fi
                ;;
            esac
            ;;
            refresh-client|refresh)
            case "$prev" in
                -t) _tmux_complete_client "${cur}" "${tmux_args[@]}" ;;
                *) options="-t" ;;
            esac ;;
            rename-session|rename)
            case "$prev" in
                -t) _tmux_complete_session "${cur}" "${tmux_args[@]}" ;;
                *) options="-t" ;;
            esac ;;
            has-session|has|kill-session)
            case "$prev" in
                -t) _tmux_complete_session "${cur}" "${tmux_args[@]}" ;;
                *) options="-t" ;;
            esac ;;
            source-file|source)
                _filedir ;;
            suspend-client|suspendc)
            case "$prev" in
                -t) _tmux_complete_client "${cur}" "${tmux_args[@]}" ;;
                *) options="-t" ;;
            esac ;;
            switch-client|switchc)
            case "$prev" in
                -c) _tmux_complete_client "${cur}" "${tmux_args[@]}" ;;
                -t) _tmux_complete_session "${cur}" "${tmux_args[@]}" ;;
                *) options="-l -n -p -c -t" ;;
            esac ;;

            send-keys|send)
            case "$option" in
                -t) _tmux_complete_window "${cur}" "${tmux_args[@]}" ;;
                *) options="-t" ;;
            esac ;;
        esac # case ${cmd}
    fi # command specified

    if [[ -n "${options}" ]]; then
        COMPREPLY=( ${COMPREPLY[@]:-} $(compgen -W "${options}" -- "${cur}") )
    fi

    return 0
}
# http://linux.die.net/man/1/bash
complete -F _tmux tmux

# END tmux completion

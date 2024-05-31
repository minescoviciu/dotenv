#!/bin/bash

export PROMPT_TOOLKIT_COLOR_DEPTH=DEPTH_24_BIT
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

__wezterm_set_user_var() {
  if hash base64 2>/dev/null ; then
    if [[ -z "${TMUX}" ]] ; then
      printf "\033]1337;SetUserVar=%s=%s\007" "$1" `echo -n "$2" | base64`
    else
      # <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it>
      # Note that you ALSO need to add "set -g allow-passthrough on" to your tmux.conf
      printf "\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\" "$1" `echo -n "$2" | base64`
    fi
  fi
}

__wezterm_send_notification() {
    if [[ -z "${TMUX}" ]] ; then
      printf "\e]777;notify;%s;%s\e\\" $1 $2
    else
      printf "\033Ptmux;\033\e]777;notify;%s;%s\e\\" $1 $2
    fi

}

__wezterm_open_web() {
    __wezterm_set_user_var "open-web" "$1"
}

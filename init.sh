#!/bin/bash

if [ ! -f "~/.config/scripts" ]; then
    mkdir -p ~/.config/scripts
fi

CWD=$(pwd)
ln -s $CWD/nvim ~/.config
ln -s $CWD/tmux.conf ~/.tmux.conf
ln -s $CWD/gitconfig ~/.gitconfig
ln -s $CWD/wezterm ~/.config
ln -s $CWD/kitty ~/.config

chekc_if_install () {
    if [ -n "$(type $1)" ]; then
        echo "$1 is installed"
    else
        echo -e "\033[31m$1 is NOT installed\033[0m"
    fi
}

ZSH_FZF_SCRIPTS=(
    https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh
    https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh
)
SCRIPTS_PATH="~/.config/scripts"
for script in ${ZSH_FZF_SCRIPTS[@]}; do
    curl -o $SCRIPTS_PATH/$(basename $script) $script
done

# TODO: source in .zshrc or .bashrc

# BINARIES=("nvim", "git", "tmux")
# for binary in ${BINARIES[@]}; do
#     chekc_if_install $binary
# done


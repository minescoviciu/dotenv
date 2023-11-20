#!/bin/bash

if [ ! -f "~/.config" ]; then
    mkdir -p ~/.config
fi

CWD=$(pwd)
ln -s $CWD/nvim ~/.config/nvim
ln -s $CWD/tmux.conf ~/.tmux.conf
ln -s $CWD/gitconfig ~/.gitconfig

chekc_if_install () {
    if [ -n "$(type $1)" ]; then
        echo "$1 is installed"
    else
        echo -e "\033[31m$1 is NOT installed\033[0m"
    fi
}

# BINARIES=("nvim", "git", "tmux")
# for binary in ${BINARIES[@]}; do
#     chekc_if_install $binary
# done


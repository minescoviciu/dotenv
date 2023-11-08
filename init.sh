#!/bin/bash

if [ ! -f "~/.config/nvim" ]; then
    mkdir -p ~/.config/nvim
fi

CWD=$(pwd)
ln -s $CWD/nvim/init.lua ~/.config/nvim/init.lua
ln -s $CWD/nvim/git.lua ~/.config/nvim/git.lua
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


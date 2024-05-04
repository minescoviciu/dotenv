#!/bin/bash

set -x
exec > /tmp/test 2>&1
# $(ProjectPath) $(File) $(Line) $(Column)
PROJECT="$1"
FILE="$2"
CMD="<ESC>:call cursor($3,$4)<CR>"
NVIM="/opt/homebrew/bin/nvim"

function open_file(){
    SOCKET="/tmp/unity-nvim-server"
    if [ -e $SOCKET ]; then
        $NVIM --server $SOCKET --remote $FILE 
        $NVIM --server $SOCKET --remote-send "$CMD"
    else
        $NVIM --listen $SOCKET  $PROJECT
    fi
}

open_file

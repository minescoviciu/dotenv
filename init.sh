#!/bin/bash

# uncomment for debugging
# set -x

chekc_if_install () {
    type $1
    if [ $? -eq 0 ]; then
        echo "$1 is installed"
    else
        echo -e "\033[31m$1 is NOT installed\033[0m"
    fi
}

# assume bash shell
SCRIPTS_PATH=~/.config/scripts
# fzf shell bindings and autocomplete
FZF_SCRIPTS=(
    https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.bash
    https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.bash
)
SHELL_RC=~/.bashrc

current_shell=$(basename $SHELL)
if [ "$current_shell" = "zsh" ]; then
    FZF_SCRIPTS=(
        https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh
        https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh
    )
    SHELL_RC=~/.zshrc
fi

if [ ! -d ~/.config ]; then
    echo "Creating ~/.config dir"
    mkdir -p ~/.config
fi

echo "Linking config files"
CWD=$(pwd)
ln -s $CWD/nvim ~/.config && echo "Linked nvim config"
ln -s $CWD/tmux.conf ~/.tmux.conf && echo "Linked tmux config"
ln -s $CWD/gitconfig ~/.gitconfig && echo "Linked git config"
ln -s $CWD/yabai ~/.config && echo "Linked yabai config"
ln -s $CWD/wezterm ~/.config && echo "Linked wezterm config"
ln -s $CWD/kitty ~/.config && echo "Linked kitty config"
ln -s $CWD/scripts ~/.config && echo "Linked scripts"
if [ "$(uname)" == "Darwin" ]; then
    ln -s $CWD/skhd ~/.config && echo "Linked skhdrc"
fi

echo "Downloading fzf scripts"
for script in ${FZF_SCRIPTS[@]}; do
    script_path=$SCRIPTS_PATH/$(basename $script)
    curl $script -o $script_path
    echo "source $script_path" >> $SHELL_RC
done

echo "Checking apps"
BINARIES=("nvim" "git" "tmux" "fzf" "delta")
for binary in ${BINARIES[@]}; do
    chekc_if_install $binary
done

# TODO
# Check if git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# If not present install for tmux plugin manager
#
# Check fzf version >= 0.42
# Check tmux >= 3.2a
# Check nvim >= 9.4
# source /usr/share/bash-completion/completions/git


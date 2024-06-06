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
SHELL_RC=~/.bashrc
current_shell=$(basename $SHELL)
if [ "$current_shell" = "zsh" ]; then
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
ln -s $CWD/wezterm ~/.config && echo "Linked wezterm config"
ln -s $CWD/scripts ~/.config && echo "Linked scripts"
if [ "$(uname)" == "Darwin" ]; then
    ln -s $CWD/skhd ~/.config && echo "Linked skhdrc"
fi

for script_file in "$SCRIPTS_PATH"/*; do
  # Check if it is a regular file
  if [ -f "$script_file" ]; then
    case "${script_file##*.}" in
      "sh")
        echo "source $script_file" >> "$SHELL_RC"
        echo "Added source command for $script_file to $SHELL_RC"
        ;;
      "bash")
        if [ "$current_shell" = "bash" ]; then
          echo "source $script_file" >> "$SHELL_RC"
          echo "Added source command for $script_file to $SHELL_RC"
        fi
        ;;
      "zsh")
        if [ "$current_shell" = "zsh" ]; then
          echo "source $script_file" >> "$SHELL_RC"
          echo "Added source command for $script_file to $SHELL_RC"
        fi
        ;;
    esac
  fi
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


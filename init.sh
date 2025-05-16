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
ln -s $CWD/starship.toml ~/.config && echo "Linked starship.toml"
ln -s $CWD/aerospace.toml ~/.aerospace.toml &&  echo "Linked aerospace.toml"
ln -s $CWD/sketchybar ~/.config && echo "Linked sketchybar"

CURSOR_PATH="~/Library/Application\ Support/Cursor/User"
rm -f $CURSOR_PATH/settings.json
rm -f $CURSOR_PATH/keybindings.json
ln -s $CWD/vscode/settings.json $CURSOR_PATH/settings.json && echo "Linked vscode settings"
ln -s $CWD/vscode/keybindings.json $CURSOR_PATH/keybindings.json && echo "Linked vscode keybindings"

rm -f ~/.config/lazygit/config.yml
ln -s $CWD/lazygit.yaml ~/.config/config.yml && echo "Linked lazygit"

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


#install spaceship
curl -sS https://starship.rs/install.sh | sh


# TODO
# Check if git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# If not present install for tmux plugin manager
#
# Check fzf version >= 0.42
# Check tmux >= 3.2a
# Check nvim >= 9.4
# source /usr/share/bash-completion/completions/git


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
ln -s $(pwd)/nvim ~/.config && echo "Linked nvim config"
ln -s $(pwd)/tmux.conf ~/.tmux.conf && echo "Linked tmux config"
ln -s $(pwd)/gitconfig ~/.gitconfig && echo "Linked git config"
ln -s $(pwd)/wezterm ~/.config && echo "Linked wezterm config"
ln -s $(pwd)/scripts ~/.config && echo "Linked scripts"
ln -s $(pwd)/aerospace.toml ~/.aerospace.toml &&  echo "Linked aerospace.toml"
ln -s $(pwd)/sketchybar ~/.config && echo "Linked sketchybar"
mkdir -p ~/.config/opencode
ln -sfn $(pwd)/AI/opencode.jsonc ~/.config/opencode/opencode.jsonc && echo "Linked opencode.jsonc"
mkdir -p ~/.codex
ln -sfn $(pwd)/AI/codex.toml ~/.codex/config.toml && echo "Linked codex config"

# Claude Code. Everything lives under ~/.claude; the runtime dirs it manages
# itself (projects/, sessions/, plugins/, ...) stay untouched.
#
# settings.json points its hooks and statusline at ~/.claude/assets/, not at
# this repo's path, so the config does not care where the clone lives.
mkdir -p ~/.claude
ln -sfn $(pwd)/AI/claude-settings.json ~/.claude/settings.json && echo "Linked claude settings"
ln -sfn $(pwd)/AI/AGENTS.md ~/.claude/CLAUDE.md && echo "Linked claude AGENTS.md"
ln -sfn $(pwd)/AI/claude-assets ~/.claude/assets && echo "Linked claude assets"
ln -sfn $(pwd)/AI/claude-assets/agents ~/.claude/agents && echo "Linked claude agents"
ln -sfn $(pwd)/AI/commands ~/.claude/commands && echo "Linked claude commands"
ln -sfn $(pwd)/AI/skills ~/.claude/skills && echo "Linked claude skills"

CURSOR_PATH="~/Library/Application\ Support/Cursor/User"
rm -f $CURSOR_PATH/settings.json
rm -f $CURSOR_PATH/keybindings.json
ln -s $CWD/vscode/settings.json $CURSOR_PATH/settings.json && echo "Linked vscode settings"
ln -s $CWD/vscode/keybindings.json $CURSOR_PATH/keybindings.json && echo "Linked vscode keybindings"

rm -f ~/.config/lazygit/config.yml
ln -s $CWD/lazygit.yaml ~/.config/config.yml && echo "Linked lazygit"

# Only scripts that set up shell state -- functions, completions, the prompt --
# belong in the rc file. The rest of scripts/ is run on demand by a tmux or fzf
# binding, and those files do their work at the top level: sourcing
# tmux-toggle-popup.sh opens a popup and tmux-toggle-nvim-opencode.sh jumps to
# another window, on every single new shell. Hence an explicit list rather than
# globbing the directory.
SOURCED_SCRIPTS=(
  bashrc.sh
  prompt.sh
  just_completions.sh
  work.sh
  completion.bash
  key-bindings.bash
  completion.zsh
  key-bindings.zsh
)

for script_name in "${SOURCED_SCRIPTS[@]}"; do
  script_file="$SCRIPTS_PATH/$script_name"
  [ -f "$script_file" ] || continue
  case "${script_name##*.}" in
    "bash") [ "$current_shell" = "bash" ] || continue ;;
    "zsh")  [ "$current_shell" = "zsh" ]  || continue ;;
  esac
  # Re-running init.sh should not stack duplicate source lines.
  if grep -qxF "source $script_file" "$SHELL_RC" 2>/dev/null; then
    echo "Already sourced: $script_file"
    continue
  fi
  echo "source $script_file" >> "$SHELL_RC"
  echo "Added source command for $script_file to $SHELL_RC"
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

#!/bin/bash

# uncomment for debugging
# set -x
#
# This script is stateless: every step converges on the same result, so it is
# safe to re-run after any change. Re-running never duplicates a line in the rc
# file and never stacks a symlink inside a previous one.

chekc_if_install () {
    type $1
    if [ $? -eq 0 ]; then
        echo "$1 is installed"
    else
        echo -e "\033[31m$1 is NOT installed\033[0m"
    fi
}

# Point dest at src, creating the parent dir first. -f replaces an existing
# symlink and -n keeps us from descending into one that points at a directory,
# which is what would otherwise nest a link inside the previous run's link.
link () {
    local src="$1" dest="$2" label="$3"
    if [ ! -e "$src" ]; then
        echo -e "\033[31mMissing source, skipped: $src\033[0m"
        return 1
    fi
    # A real directory or file here is not ours to replace -- linking over it
    # would either nest inside it or throw away whatever it holds.
    if [ -d "$dest" ] && [ ! -L "$dest" ]; then
        echo -e "\033[31mReal directory in the way, left alone: $dest\033[0m"
        return 1
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest" && echo "Linked $label"
}

# assume bash shell
SCRIPTS_PATH=~/.config/scripts
SHELL_RC=~/.bashrc
current_shell=$(basename $SHELL)
if [ "$current_shell" = "zsh" ]; then
    SHELL_RC=~/.zshrc
fi

CWD=$(pwd)

echo "Linking config files"
link "$CWD/nvim"                    ~/.config/nvim                    "nvim config"
link "$CWD/tmux.conf"               ~/.tmux.conf                      "tmux config"
link "$CWD/gitconfig"               ~/.gitconfig                      "git config"
link "$CWD/wezterm"                 ~/.config/wezterm                 "wezterm config"
link "$CWD/scripts"                 ~/.config/scripts                 "scripts"
link "$CWD/lazygit.yaml"            ~/.config/lazygit/config.yml      "lazygit config"
link "$CWD/AI/opencode.jsonc"       ~/.config/opencode/opencode.jsonc "opencode config"
link "$CWD/AI/codex.toml"           ~/.codex/config.toml              "codex config"

# Claude Code. Everything lives under ~/.claude; the runtime dirs it manages
# itself (projects/, sessions/, plugins/, ...) stay untouched.
#
# settings.json points its hooks and statusline at ~/.claude/assets/, not at
# this repo's path, so the config does not care where the clone lives.
link "$CWD/AI/claude-settings.json" ~/.claude/settings.json           "claude settings"
link "$CWD/AI/AGENTS.md"            ~/.claude/CLAUDE.md               "claude AGENTS.md"
link "$CWD/AI/claude-assets"        ~/.claude/assets                  "claude assets"
link "$CWD/AI/claude-assets/agents" ~/.claude/agents                  "claude agents"
link "$CWD/AI/commands"             ~/.claude/commands                "claude commands"
link "$CWD/AI/skills"               ~/.claude/skills                  "claude skills"

# macOS-only targets. On Linux these paths do not exist and every one of them
# used to fail noisily on each run.
if [ "$(uname)" = "Darwin" ]; then
    CURSOR_PATH="$HOME/Library/Application Support/Cursor/User"
    link "$CWD/aerospace.toml"           ~/.aerospace.toml               "aerospace config"
    link "$CWD/sketchybar"               ~/.config/sketchybar            "sketchybar config"
    link "$CWD/vscode/settings.json"     "$CURSOR_PATH/settings.json"    "vscode settings"
    link "$CWD/vscode/keybindings.json"  "$CURSOR_PATH/keybindings.json" "vscode keybindings"
fi

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

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

# Shell rc integration.
#
# The rc file gets one managed block that globs the scripts directory at shell
# startup, rather than a source line per script. That keeps init.sh out of the
# loop entirely: add, rename or delete a script and the next shell reflects it,
# with no re-run needed and nothing to keep in sync by hand.
RC_BEGIN="# >>> dotenv scripts >>>"
RC_END="# <<< dotenv scripts <<<"

case "$current_shell" in
    zsh) rc_extra_glob='*.zsh' ;;
    *)   rc_extra_glob='*.bash' ;;
esac

# Strip the previous managed block plus any legacy per-script source lines,
# so the rewrite below is idempotent no matter which version wrote the rc file.
if [ -f "$SHELL_RC" ]; then
    rc_tmp=$(mktemp)
    awk -v b="$RC_BEGIN" -v e="$RC_END" -v p="$SCRIPTS_PATH" '
        index($0, b) { skip = 1; next }
        index($0, e) { skip = 0; next }
        skip         { next }
        index($0, "source " p "/") == 1 { next }
        { print }
    ' "$SHELL_RC" |
    # Drop trailing blank lines too, otherwise the blank line that separates the
    # block below is left behind on every run and the file grows a line at a time.
    awk 'NF { last = NR } { line[NR] = $0 } END { for (i = 1; i <= last; i++) print line[i] }' \
        > "$rc_tmp" && mv "$rc_tmp" "$SHELL_RC"
fi

cat >> "$SHELL_RC" <<EOF

$RC_BEGIN
# Managed by dotenv/init.sh -- do not edit between these markers.
#
# The executable bit decides what happens to a file in ~/.config/scripts:
#
#   not executable -> shell setup (functions, completions, prompt), sourced here
#   executable     -> a command run on demand by a tmux or fzf binding
#
# Executable ones must never be sourced: they do their work at the top level,
# so sourcing tmux-toggle-popup.sh opens a popup and
# tmux-toggle-nvim-opencode.sh jumps to another window, on every new shell.
#
# So: chmod +x a script you invoke, leave it non-executable to have it sourced.
for _dotenv_rc in "\$HOME/.config/scripts"/*.sh "\$HOME/.config/scripts"/$rc_extra_glob; do
    [ -f "\$_dotenv_rc" ] && [ ! -x "\$_dotenv_rc" ] && . "\$_dotenv_rc"
done
unset _dotenv_rc
$RC_END
EOF
echo "Refreshed the dotenv block in $SHELL_RC"

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

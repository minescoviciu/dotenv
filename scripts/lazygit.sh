# Layer a machine-local lazygit config over the tracked one.
#
# lazygit takes a comma-separated list of config files, merges them left to
# right, and -- importantly -- migrates each file in place when its schema
# changes, without ever writing one file's contents into another. So settings
# that should not be tracked can live in local.yml and survive the rewrites
# lazygit performs on config.yml.
#
# Sourced, not executed: this file is deliberately left non-executable so the
# rc block picks it up. See init.sh.

_lazygit_config="$HOME/.config/lazygit/config.yml"

if [ -f "$HOME/.config/lazygit/local.yml" ]; then
    _lazygit_config="$_lazygit_config,$HOME/.config/lazygit/local.yml"
fi

export LG_CONFIG_FILE="$_lazygit_config"
unset _lazygit_config

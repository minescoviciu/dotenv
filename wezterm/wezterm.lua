local wezterm = require 'wezterm'
local config = {}

config.hyperlink_rules = wezterm.default_hyperlink_rules()

table.insert(config.hyperlink_rules, {
  regex = [[(SW-\d+)]],
  format = 'https://example.com/$1',
})

-- config.font = wezterm.font("CaskaydiaCove Nerd Font")
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
-- config.font = wezterm.font("Iosevka Nerd Font Mono")
config.color_scheme = "Catppuccin Mocha"
--config.color_scheme = "Tokyo Night" -- Macchiato"

config.native_macos_fullscreen_mode = true
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.tab_bar_at_bottom = true
config.font_size = 15.0
config.audible_bell = "Disabled"
config.inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.5,
}
config.window_padding = {
  left = '1cell',
  right = '1cell',
  top = '0.3cell',
  bottom = '0cell',
}

-- Enable CSI u mode for better key handling
-- This makes WezTerm send proper escape sequences for modified keys like Shift+Enter
-- Can be toggled with Ctrl+Shift+U
config.enable_csi_u_key_encoding = true

-- Keybindings
config.keys = {
  -- Toggle CSI u mode on/off with Ctrl+Shift+U
  {
    key = 'U',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local overrides = window:get_config_overrides() or {}
      if overrides.enable_csi_u_key_encoding == false then
        overrides.enable_csi_u_key_encoding = true
        window:toast_notification('WezTerm', 'CSI u mode enabled', nil, 3000)
      else
        overrides.enable_csi_u_key_encoding = false
        window:toast_notification('WezTerm', 'CSI u mode disabled (legacy mode)', nil, 3000)
      end
      window:set_config_overrides(overrides)
    end),
  },
}

wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "open-web" then
        wezterm.open_with(value)
    end
end)

return config

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
config.font_size = 13.0
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
wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "open-web" then
        wezterm.open_with(value)
    end
end)

return config

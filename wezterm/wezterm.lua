local wezterm = require 'wezterm'
local config = {}

config.keys = {
    { key = 'L', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.ShowLauncherArgs({flags = 'DOMAINS|FUZZY'}) },
    { key = 'W', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.ShowLauncherArgs({flags = 'WORKSPACES|FUZZY'}) },
    { key = 'N', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.SwitchWorkspaceRelative(1) },
    { key = 'P', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.SwitchWorkspaceRelative(-1) },
    { key = 'X', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.CloseCurrentPane({confirm = true})},
    { key = 'C', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.CloseCurrentTab({confirm = true})},
    { key = 'T', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.ShowTabNavigator},
    { key = 'V', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.SplitHorizontal({domain = 'CurrentPaneDomain'})},
    { key = 'H', mods = 'CTRL|CMD|SHIFT', action = wezterm.action.SplitVertical({domain = 'CurrentPaneDomain'})},
     -- Prompt for a name to use for a new workspace and switch to it.
    {
         key = 'S',
         mods = 'CTRL|CMD|SHIFT',
         action = wezterm.action.PromptInputLine {
             description = wezterm.format {
                 { Attribute = { Intensity = 'Bold' } },
                 { Foreground = { AnsiColor = 'Fuchsia' } },
                 { Text = 'Enter name for new workspace' },
             },
             action = wezterm.action_callback(function(window, pane, line)
                 -- line will be `nil` if they hit escape without entering anything
                 -- An empty string if they just hit enter
                 -- Or the actual line of text they wrote
                 if line then
                     window:perform_action(
                     wezterm.action.SwitchToWorkspace {
                         name = line,
                     },
                     pane
                     )
                 end
             end),
         },
    },
    {
        key = 'R',
        mods = 'CTRL|CMD|SHIFT',
        action = wezterm.action.PromptInputLine {
             description = wezterm.format {
                 { Attribute = { Intensity = 'Bold' } },
                 { Foreground = { AnsiColor = 'Fuchsia' } },
                 { Text = 'Rename workspace ' .. wezterm.mux.get_active_workspace() },
             },
             action = wezterm.action_callback(function(window, pane, line)
                 -- add some sanitization to line 
                 if line then
                    local success, stdout, stderr = wezterm.run_child_process { '/Applications/WezTerm.app/Contents/MacOS/wezterm', 'cli', 'rename-workspace', line }
                end
             end),
        },
    },
}
-- config.font = wezterm.font("CaskaydiaCove Nerd Font")
config.font = wezterm.font("Iosevka Nerd Font Mono")

config.unix_domains = {
  {
    name = 'unix',
  },
}
-- config.default_gui_startup_args = { 'connect', 'unix' }

config.native_macos_fullscreen_mode = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.font_size = 13.0
config.audible_bell = "Disabled"
config.inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.5,
}


wezterm.on('format-tab-title', function(tab)
    local pane = tab.active_pane
    local title = pane.title
    if pane.domain_name then
        title = title .. ' - ' .. pane.domain_name .. ' [' .. wezterm.mux.get_active_workspace() .. ']'
    end
    return title
end)

return config

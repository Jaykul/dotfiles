-- https://wezfurlong.org/wezterm/config/lua/config/
local wezterm = require 'wezterm'
local launch = require 'launch'
local keys = require 'keys'

local act = wezterm.action
local config = wezterm.config_builder()
-- bind_keys passes through the config after adding the keybindings
config = keys.bind_keys(config)


local powerline = require 'powerlinetabs'
if powerline.is_dark() then
  config.color_scheme = 'MaterialDark'
else
  config.color_scheme = 'Material'
end

config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.5,
}

config.font = wezterm.font_with_fallback({'Cascadia Code', 'Symbols Nerd Font Mono'})
config.font_size = 12.0

powerline.segments_for_right_status = (function(window, _)
  return {
    window:mux_window():active_pane():get_current_working_dir(),
    basename(window:mux_window():active_pane():get_foreground_process_name()),
    window:active_workspace(),
    wezterm.hostname(),
    wezterm.strftime('%a %b %-d %H:%M'),
  }
end)


-- *** Removes the title bar, leaving only the tab bar.
-- use_fancy_tab_bar = false,
-- config.hide_tab_bar_if_only_one_tab = true
-- *** Keeps the ability to resize by dragging the window's edges.
-- *** Keep the window controls visible and integrate them into the tab bar.
config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
-- Sets the font for the window frame (tab bar)
config.window_frame = {
  font = wezterm.font({ family = 'Cascadia Code', weight = 'Bold', style = 'Italic' }),
  font_size = 11,
}

config.initial_cols = 120
config.initial_rows = 54
config.enable_scroll_bar = true
config.window_background_opacity = 1.0
config.default_cursor_style = "BlinkingUnderline"
config.cursor_blink_rate = 500
    -- window_decorations = "RESIZE",
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0, }
config.default_prog = {launch.getFirstShell('pwsh.exe', 'pwsh', 'powershell.exe', 'bash', 'bash.exe', 'cmd.exe')}
config.default_cwd = wezterm.home_dir
config.launch_menu = launch.getShells({})
config.quick_select_patterns = {
    -- match standalone words that look like sha1 hashes
    '\\b[0-9a-fA-F]{9}\\b',
    '\\b[0-9a-fA-F]{40}\\b',
    -- node names from kubectl (only when followed by the n/n READY count)
    '^[a-z][0-9a-z-]+(?=\\s+\\d+/\\d+)',
    -- file paths
    '\\b(?:[a-zA-Z]:|\\./|\\.\\\\)[\\/\\w\\d\\-\\_\\.]+\\b',
    -- urls
    '\\bhttps?://[^\\s]+\\b',
}

-- I don't use ssh very much (except for git and earthly) ...
-- but the nightly builds are breaking my KeeAgent setup
config.mux_enable_ssh_agent = false

return config


-- https://wezfurlong.org/wezterm/config/lua/config/
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local launch = require 'launch'

local act = wezterm.action
local keys = require 'keys'

config = keys.bind_keys(config)

local appearance = require 'appearance'
if appearance.is_dark() then
  config.color_scheme = 'MaterialDark'
else
  config.color_scheme = 'Material'
end

config.font = wezterm.font_with_fallback({'Cascadia Code', 'Symbols Nerd Font Mono'})
config.font_size = 12.0

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

local function segments_for_right_status(window)
  return {
    -- window:mux_window():active_pane():get_current_working_dir(),
    basename(window:mux_window():active_pane():get_foreground_process_name()),
    window:active_workspace(),
    wezterm.hostname(),
    wezterm.strftime('%a %b %-d %H:%M'),
  }
end


wezterm.on('update-status', function(window, _)
  local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
  local segments = segments_for_right_status(window)

  local color_scheme = window:effective_config().resolved_palette
  -- Note the use of wezterm.color.parse here, this returns
  -- a Color object, which comes with functionality for lightening
  -- or darkening the colour (amongst other things).
  local bg = wezterm.color.parse(color_scheme.background)
  local fg = color_scheme.foreground

  -- Each powerline segment is going to be coloured progressively
  -- darker/lighter depending on whether we're on a dark/light colour
  -- scheme. Let's establish the "from" and "to" bounds of our gradient.
  local gradient_to, gradient_from = bg, bg
  if appearance.is_dark() then
    gradient_from = gradient_to:lighten(0.2)
  else
    gradient_from = gradient_to:darken(0.2)
  end

  -- Yes, WezTerm supports creating gradients, because why not?! Although
  -- they'd usually be used for setting high fidelity gradients on your terminal's
  -- background, we'll use them here to give us a sample of the powerline segment
  -- colours we need.
  local gradient = wezterm.color.gradient(
    {
      orientation = 'Horizontal',
      colors = { gradient_from, gradient_to },
    },
    #segments -- only gives us as many colours as we have segments.
  )

  -- We'll build up the elements to send to wezterm.format in this table.
  local elements = {}

  for i, seg in ipairs(segments) do
    local is_first = i == 1

    if is_first then
      table.insert(elements, { Background = { Color = 'none' } })
    end
    table.insert(elements, { Foreground = { Color = gradient[i] } })
    table.insert(elements, { Text = SOLID_LEFT_ARROW })

    table.insert(elements, { Foreground = { Color = fg } })
    table.insert(elements, { Background = { Color = gradient[i] } })
    table.insert(elements, { Text = ' ' .. seg .. ' ' })
  end

--   table.insert(elements, { Foreground = { Color = 'none' } })
--   table.insert(elements, { Background = { Color = gradient[#segments] } })
--   table.insert(elements, { Text = SOLID_LEFT_ARROW })

  window:set_right_status(wezterm.format(elements))
end)


-- use_fancy_tab_bar = false,
-- config.hide_tab_bar_if_only_one_tab = true
-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- We coudl try 'RESIZE|INTEGRATED_BUTTONS' to keep the window controls visible
-- and integrate them into the tab bar.
config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
-- Sets the font for the window frame (tab bar)
config.window_frame = {
  font = wezterm.font({ family = 'Cascadia Code', weight = 'Bold', style = 'Italic' }),
  font_size = 11,
}


config.initial_cols = 120
config.initial_rows = 54
config.window_background_opacity = 1.0
config.default_cursor_style = "BlinkingUnderline"
config.cursor_blink_rate = 500
    -- window_decorations = "RESIZE",
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0, }
config.default_prog = {launch.getFirstShell('pwsh.exe', 'pwsh', 'powershell.exe', 'bash', 'bash.exe', 'cmd.exe')}
config.default_cwd = wezterm.home_dir
config.launch_menu = launch.menu
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

return config


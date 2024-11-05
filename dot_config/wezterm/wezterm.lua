-- https://wezfurlong.org/wezterm/config/lua/config/
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local projects = require 'projects'
local launch = require 'launch'

local act = wezterm.action
-- local keys = require 'keys'

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

local function move_pane(key, direction)
  return {
    key = key,
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection(direction),
  }
end

local function resize_pane(key, direction)
  return {
    key = key,
    action = wezterm.action.AdjustPaneSize { direction, 3 }
  }
end

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


    -- I had to disable the defaults in order to be able to use Ctrl+Shift for text selection in the prompt
    config.disable_default_key_bindings = true
    config.leader = { key = 'k', mods = 'CTRL', timeout_milliseconds = 1000 }

    config.mouse_bindings =  {
        {   event = { Down = { streak = 3, button = 'Left' } }, mods = 'NONE',
            action = act.SelectTextAtMouseCursor 'SemanticZone'
        },
    }
    config.keys = {
        { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
        { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
        { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },

        -- { key = 'P', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateCommandPalette },
        -- { key = 'F', mods = 'CTRL', action = wezterm.action.CharSelect },
        -- { key = ' ', mods = 'CTRL|SHIFT', action = wezterm.action.QuickSelect  },

        { key = 'p', mods = 'CTRL', action = wezterm.action.ShowLauncher },
        { key = 'p', mods = 'SHIFT|CTRL', action = act.ActivateCommandPalette },
        { key = 'r', mods = 'SHIFT|CTRL', action = act.ReloadConfiguration },
        { key = 'F5', mods = 'NONE', action = act.ReloadConfiguration },

        -- Present in to our project picker
        { key = 'p', mods = 'LEADER', action = projects.choose_project() },
        -- resize-pane mode
        { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false, }, },
        -- activate-pane mode
        { key = 'a', mods = 'LEADER', action = act.ActivateKeyTable { name = 'activate_pane', timeout_milliseconds = 1000, }, },
        { key = 'Z', mods = 'LEADER', action = act.TogglePaneZoomState },
        { key = 'D', mods = 'LEADER', action = act.ShowDebugOverlay },
        { key = '`', mods = 'CTRL', action = act.ShowDebugOverlay },


        { key = 'UpArrow', mods = 'SHIFT', action = wezterm.action.ScrollToPrompt(-1) },
        { key = 'DownArrow', mods = 'SHIFT', action = wezterm.action.ScrollToPrompt(1) },


        { key = "w", mods = "CTRL", action = wezterm.action { CloseCurrentPane = { confirm = false } } },
        { key = "t", mods = "CTRL", action = wezterm.action{ SpawnTab = "DefaultDomain" } },
        { key = "T", mods = "CTRL|SHIFT", action = wezterm.action{ SpawnTab = "DefaultDomain" } },
        { key = "N", mods = "CTRL", action = wezterm.action{ SpawnTab = "DefaultDomain" } },

        { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
        { key = '=', mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
        { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
        { key = '+', mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
        { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
        { key = '-', mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },
        { key = '_', mods = 'CTRL', action = act.DecreaseFontSize },
        { key = '_', mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },
        { key = '0', mods = 'CTRL', action = act.ResetFontSize },
        { key = '0', mods = 'SHIFT|CTRL', action = act.ResetFontSize },
        { key = '1', mods = 'CTRL', action = act.ActivateTab(0) },
        { key = '2', mods = 'CTRL', action = act.ActivateTab(1) },
        { key = '3', mods = 'CTRL', action = act.ActivateTab(2) },
        { key = '4', mods = 'CTRL', action = act.ActivateTab(3) },
        { key = '5', mods = 'CTRL', action = act.ActivateTab(4) },
        { key = '6', mods = 'CTRL', action = act.ActivateTab(5) },
        { key = '7', mods = 'CTRL', action = act.ActivateTab(6) },
        { key = '8', mods = 'CTRL', action = act.ActivateTab(7) },
        { key = '9', mods = 'CTRL', action = act.ActivateTab(-1) },

        { key = 'f', mods = 'CTRL', action = act.Search 'CurrentSelectionOrEmptyString' },
        { key = 'F', mods = 'CTRL|SHIFT', action = wezterm.action.QuickSelectArgs { patterns = config.quick_select_patterns } },
        { key = 'phys:Space', mods = 'SHIFT|CTRL', action = act.QuickSelect },

        { key = '`', mods = 'CTRL', action = act.ShowDebugOverlay },
        { key = '~', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },

        { key = 'x', mods = 'SHIFT|CTRL', action = act.ActivateCopyMode },
        -- This would let us use CTRL+C to copy selections (but we'd need to disable the default copy on select)
        -- E.g. https://gist.github.com/kvnxiao/c0f47da586fc997ef83c9fcbb9b61238
        { key = "c", mods = "CTRL", action = wezterm.action_callback(function(win, pane)
                local has_selection = win:get_selection_text_for_pane(pane) ~= ""
                if has_selection then
                    win:perform_action(wezterm.action {
                        CopyTo = "ClipboardAndPrimarySelection"
                    }, pane)
                else
                    win:perform_action(wezterm.action {
                        SendKey = {
                            key = "c",
                            mods = "CTRL"
                        }
                    }, pane)
                end
            end)
        },
        -- { key = 'c', mods = 'CTRL', action = act.CopyTo 'Clipboard' },
        { key = 'c', mods = 'SHIFT|CTRL', action = act.CopyTo 'Clipboard' },
        { key = 'c', mods = 'WIN', action = act.CopyTo 'Clipboard' },

        -- { key = 'K', mods = 'CTRL', action = act.ClearScrollback 'ScrollbackOnly' },
        { key = 'U', mods = 'CTRL', action = act.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
        -- { key = 'U', mods = 'SHIFT|CTRL', action = act.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
        { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
        { key = 'V', mods = 'SHIFT|CTRL', action = act.PasteFrom 'Clipboard' },
        { key = 'w', mods = 'CTRL', action = act.CloseCurrentTab{ confirm = true } },
        -- { key = 'W', mods = 'SHIFT|CTRL', action = act.CloseCurrentTab{ confirm = true } },
        { key = 'x', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },
        { key = 'z', mods = 'SHIFT|CTRL', action = act.TogglePaneZoomState },
        -- { key = 'Z', mods = 'SHIFT|CTRL', action = act.TogglePaneZoomState },
        { key = '[', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(-1) },
        { key = ']', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(1) },
        { key = '{', mods = 'WIN', action = act.ActivateTabRelative(-1) },
        { key = '{', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(-1) },
        { key = '}', mods = 'WIN', action = act.ActivateTabRelative(1) },
        { key = '}', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(1) },

        -- { key = 'c', mods = 'CTRL', action = act.EmitEvent 'user-defined-1' },
        { key = 'u', mods = 'SHIFT|CTRL', action = act.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },

        { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
        { key = 'Tab', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(-1) },

        -- { key = 'LeftArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Left' },
        -- { key = 'LeftArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Left', 1 } },
        -- { key = 'RightArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Right' },
        -- { key = 'RightArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Right', 1 } },
        { key = 'PageUp', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
        { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
        -- { key = 'UpArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Up' },
        -- { key = 'UpArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Up', 1 } },
        { key = 'PageDown', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
        { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
        -- { key = 'DownArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Down' },
        -- { key = 'DownArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Down', 1 } },
        { key = 'Insert', mods = 'SHIFT', action = act.PasteFrom 'PrimarySelection' },
        { key = 'Insert', mods = 'CTRL', action = act.CopyTo 'PrimarySelection' },
        { key = 'Copy', mods = 'NONE', action = act.CopyTo 'Clipboard' },
        { key = 'Paste', mods = 'NONE', action = act.PasteFrom 'Clipboard' },

    }


    config.key_tables = {
        search_mode = {
            -- Cancel the mode by pressing escape
            { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
            { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
            { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
            { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
            { key = 'Enter', mods = 'SHIFT', action = act.CopyMode 'NextMatch' },

            { key = 'r', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
            { key = 'm', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
            { key = 'Backspace', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
            { key = 'Delete', mods = 'NONE', action = act.CopyMode 'ClearPattern' },

            { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
            { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
            { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
            { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
        },
        copy_mode = {
            -- Cancel the mode by pressing escape
            { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
            { key = 'Space', mods = 'NONE', action = act.CopyMode { SetSelectionMode = 'Cell' } },
            { key = 'Space', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Line' } },

            -- { key = 'f', mods = 'NONE', action = act.CopyMode { JumpBackward = { prev_char = false } } },
            -- { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
            -- { key = 'L', mods = 'NONE', action = act.CopyMode 'MoveToViewportBottom' },
            -- { key = 'M', mods = 'NONE', action = act.CopyMode 'MoveToViewportMiddle' },
            -- { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
            -- { key = 't', mods = 'NONE', action = act.CopyMode { JumpBackward = { prev_char = true } } },
            -- { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
            -- { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
            -- { key = 'V', mods = 'SHIFT', action = act.CopyMode { SetSelectionMode = 'Line' } },

            { key = 'c', mods = 'CTRL', action = act.Multiple {{ CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' }} },
            { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
            { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
            { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
            { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
            { key = 'Enter', mods = 'NONE', action = act.Multiple {{ CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' }} },

            { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
            { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },
            { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
            { key = 'LeftArrow', mods = 'CTRL', action = act.CopyMode 'MoveBackwardWord' },
            { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'MoveRight' },
            { key = 'RightArrow', mods = 'CTRL', action = act.CopyMode 'MoveForwardWord' },
            { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'MoveUp' },
            { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'MoveDown' },
            { key = 'UpArrow', mods = 'CTRL', action = act.CopyMode 'MoveBackwardSemanticZone' },
            { key = 'DownArrow', mods = 'CTRL', action = act.CopyMode 'MoveForwardSemanticZone' },
            -- { key = 'UpArrow', mods = 'CTRL', action = act.CopyMode { MoveBackwardZoneOfType = 'Input' } },
            -- { key = 'DownArrow', mods = 'CTRL', action = act.CopyMode { MoveForwardZoneOfType = 'Input' } },
            { key = 'Home', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLineContent' },
            { key = 'Home', mods = 'CTRL', action = act.CopyMode 'MoveToScrollbackTop' },
            { key = 'End', mods = 'CTRL', action = act.CopyMode 'MoveToScrollbackBottom' },
            { key = 'End', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
        },
        -- Keys for resizing the pane that we're in. Active after Ctrl+K,r
        resize_pane = {
            { key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 1 } },
            { key = 'h', action = act.AdjustPaneSize { 'Left', 1 } },

            { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 1 } },
            { key = 'l', action = act.AdjustPaneSize { 'Right', 1 } },

            { key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 1 } },
            { key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },

            { key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 1 } },
            { key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },

            -- Cancel the mode by pressing escape
            { key = 'Escape', action = 'PopKeyTable' },
        },

        -- Keys for switching panes. Active after Ctrl+K,a
        activate_pane = {
            { key = 'LeftArrow', action = act.ActivatePaneDirection 'Left' },
            { key = 'h', action = act.ActivatePaneDirection 'Left' },

            { key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
            { key = 'l', action = act.ActivatePaneDirection 'Right' },

            { key = 'UpArrow', action = act.ActivatePaneDirection 'Up' },
            { key = 'k', action = act.ActivatePaneDirection 'Up' },

            { key = 'DownArrow', action = act.ActivatePaneDirection 'Down' },
            { key = 'j', action = act.ActivatePaneDirection 'Down' },

            -- Cancel the mode by pressing escape
            { key = 'Escape', action = 'PopKeyTable' },
        },
    }


return config


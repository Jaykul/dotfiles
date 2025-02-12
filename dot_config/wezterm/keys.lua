local wezterm = require 'wezterm'
local projects = require 'projects'
local act = wezterm.action


-- Define a lua table to hold _our_ module's functions
local module = {}

-- Returns a bool based on whether the host operating system's
-- appearance is light or dark.
function module.bind_keys(config)


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
        { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
        { key = 'm', mods = 'LEADER|CTRL', action = act.TogglePaneZoomState },
        { key = 'LeftArrow', mods = 'LEADER|CTRL', action = act.ActivatePaneDirection 'Left' },
        { key = 'RightArrow', mods = 'LEADER|CTRL', action = act.ActivatePaneDirection 'Right' },
        { key = 'UpArrow', mods = 'LEADER|CTRL', action = act.ActivatePaneDirection 'Up' },
        { key = 'DownArrow', mods = 'LEADER|CTRL', action = act.ActivatePaneDirection 'Down' },
        { key = 'Enter', mods = 'LEADER|CTRL', action = wezterm.action_callback( function(win, pane) local tab, window = pane:move_to_new_tab() end)},
        { key = 'd', mods = 'LEADER', action = act.ShowDebugOverlay },
        { key = '`', mods = 'CTRL', action = act.ShowDebugOverlay },


        { key = 'UpArrow', mods = 'SHIFT', action = wezterm.action.ScrollToPrompt(-1) },
        { key = 'DownArrow', mods = 'SHIFT', action = wezterm.action.ScrollToPrompt(1) },


        { key = "w", mods = "CTRL", action = wezterm.action { CloseCurrentPane = { confirm = false } } },
        { key = "t", mods = "CTRL", action = wezterm.action{ SpawnTab = "DefaultDomain" } },
        { key = "T", mods = "CTRL|SHIFT", action = wezterm.action{ SpawnTab = "DefaultDomain" } },
        { key = "n", mods = "CTRL", action = wezterm.action{ SpawnTab = "DefaultDomain" } },
        { key = "n", mods = "CTRL|SHIFT", action = wezterm.action{ SpawnTab = "DefaultDomain" } },

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
        { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.QuickSelectArgs { patterns = config.quick_select_patterns } },
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
        { key = 'c', mods = 'ALT', action = act.CopyTo 'Clipboard' },
        -- { key = 'c', mods = 'SHIFT|CTRL', action = act.CopyTo 'Clipboard' },
        -- { key = 'c', mods = 'WIN', action = act.CopyTo 'Clipboard' },

        -- { key = 'K', mods = 'CTRL', action = act.ClearScrollback 'ScrollbackOnly' },
        { key = 'u', mods = 'CTRL', action = act.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
        -- { key = 'u', mods = 'SHIFT|CTRL', action = act.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
        { key = 'v', mods = 'ALT', action = act.PasteFrom 'Clipboard' },
        -- { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
        { key = 'w', mods = 'CTRL', action = act.CloseCurrentTab{ confirm = true } },
        -- { key = 'W', mods = 'SHIFT|CTRL', action = act.CloseCurrentTab{ confirm = true } },
        { key = 'x', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },
        { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },
        -- { key = 'Z', mods = 'SHIFT|CTRL', action = act.TogglePaneZoomState },
        { key = '[', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(-1) },
        { key = ']', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(1) },
        { key = '{', mods = 'WIN', action = act.ActivateTabRelative(-1) },
        { key = '{', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(-1) },
        { key = '}', mods = 'WIN', action = act.ActivateTabRelative(1) },
        { key = '}', mods = 'SHIFT|WIN', action = act.ActivateTabRelative(1) },

        -- { key = 'c', mods = 'CTRL', action = act.EmitEvent 'user-defined-1' },

        { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
        { key = 'Tab', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(-1) },

        { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
        { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
        { key = 'UpArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
        { key = 'DownArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

        { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
        { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
        { key = 'PageUp', mods = 'NONE', action = act.ScrollByPage(-1) },
        { key = 'PageUp', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
        { key = 'PageUp', mods = 'CTRL', action = act.ScrollToTop },
        { key = 'PageDown', mods = 'NONE', action = act.ScrollByPage(1) },
        { key = 'PageDown', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
        { key = 'PageDown', mods = 'CTRL', action = act.ScrollToBottom },
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

            { key = "Enter", action = wezterm.action_callback(
                function(win, pane)
                    local tab, window = pane:move_to_new_tab()
                end
            ) },
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
end

return module
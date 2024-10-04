-- https://wezfurlong.org/wezterm/config/lua/config/
local wt = require 'wezterm'
local act = wt.action

local launch_menu = {
    {
        label = 'pwsh',
        args = {'pwsh', '-nologo'}
    }, {
        label = 'pwsh -noprofile',
        args = {'pwsh', '-noprofile', '-nologo'}
    }
}

local custom_keys = {
    -- { key = 'P', mods = 'CTRL|SHIFT', action = wt.action.ActivateCommandPalette },
    { key = 'p', mods = 'CTRL', action = wt.action.ShowLauncher },

    { key = 'UpArrow', mods = 'SHIFT', action = wt.action.ScrollToPrompt(-1) },
    { key = 'DownArrow', mods = 'SHIFT', action = wt.action.ScrollToPrompt(1) },

    { key = 'c', mods = 'CTRL', action = act.CopyTo 'Clipboard' },
    { key = 'C', mods = 'SHIFT|CTRL', action = act.CopyTo 'Clipboard' },

    { key = "w", mods = "CTRL", action = wt.action { CloseCurrentPane = { confirm = false } } },
    { key = "t", mods = "CTRL", action = wt.action{ SpawnTab = "DefaultDomain" } },
    { key = "T", mods = "CTRL|SHIFT", action = wt.action{ SpawnTab = "DefaultDomain" } },
    { key = "N", mods = "CTRL", action = wt.action{ SpawnTab = "DefaultDomain" } },

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
    { key = 'F', mods = 'SHIFT|CTRL', action = act.Search 'CurrentSelectionOrEmptyString' },

    { key = '`', mods = 'CTRL', action = act.ShowDebugOverlay },
    { key = '~', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },

    { key = 'x', mods = 'SHIFT|CTRL', action = act.ActivateCopyMode },
    -- This would let us use CTRL+C to copy selections (but we'd need to disable the default copy on select)
    -- E.g. https://gist.github.com/kvnxiao/c0f47da586fc997ef83c9fcbb9b61238
    { key = "c", mods = "CTRL", action = wt.action_callback(function(win, pane)
            local has_selection = win:get_selection_text_for_pane(pane) ~= ""
            if has_selection then
                win:perform_action(wt.action {
                    CopyTo = "ClipboardAndPrimarySelection"
                }, pane)
            else
                win:perform_action(wt.action {
                    SendKey = {
                        key = "c",
                        mods = "CTRL"
                    }
                }, pane)
            end
        end)
    }
}

local mouse_bindings = {
    {   event = { Down = { streak = 3, button = 'Left' } }, mods = 'NONE',
        action = act.SelectTextAtMouseCursor 'SemanticZone'
    },
}
-- OS detection":
-- wt.log_info('wezterm config loaded:' .. wt.target_triple)

function getFirstShell(...)
    -- find the first shell from an ordered list
    local folderSep = package.config:sub(1, 1)
    local pathSep = package.config:sub(3, 3)
    local pathMatch = string.format('([^%s]+)', pathSep)
    ospath = os.getenv("PATH")

    -- look for the shells in order of preference
    for _, shell in pairs({...}) do
        -- iterate through PATH entries
        for path in string.gmatch(ospath, pathMatch) do
            for _, file in ipairs(wt.glob(path .. folderSep .. shell)) do -- iterate through files in that entry
                wt.log_info('file: ' .. file)
                return file
            end
        end
    end
end

if wt.target_triple == "x86_64-pc-windows-msvc" then
    table.insert(launch_menu, {
        label = "PowerShell",
        args = {"powershell.exe", "-NoLogo"},
    })
    table.insert(launch_menu, {
        label = "PowerShell -NoProfile",
        args = {"powershell.exe", "-NoLogo", "-NoProfile"},
    })
    -- table.insert(launch_menu, {
    --     label = "PowerShell (Admin)",
    --     args = {"powershell.exe", "-NoLogo", "Start-Process", "-Verb", "runAs", "wt", "powershell.exe"},
    -- })
    table.insert(launch_menu, {
        label = "Command Prompt",
        args = {'cmd'}
    })
end

return {
    -- use_fancy_tab_bar = false,
    hide_tab_bar_if_only_one_tab = true,
    initial_cols = 120,
    initial_rows = 54,
    color_scheme = "MaterialOcean",
    window_background_opacity = 1.0,
    default_cursor_style = "BlinkingUnderline",
    cursor_blink_rate = 500,
    -- window_decorations = "RESIZE",
    window_padding = { left = 0, right = 0, top = 0, bottom = 0, },
    default_prog = {getFirstShell('pwsh.exe', 'pwsh', 'powershell.exe', 'bash', 'bash.exe', 'cmd.exe')},
    default_cwd = wt.home_dir,
    font_size = 12.0,
    font = wt.font_with_fallback({'Cascadia Code NF', 'Cascadia Mono NF', 'Cascadia Code', 'Consolas'}),
    launch_menu = launch_menu,
    mouse_bindings = mouse_bindings,

    keys = custom_keys,
    key_tables = {
        search_mode = {
            { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
            { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
            { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
            { key = 'Enter', mods = 'SHIFT', action = act.CopyMode 'NextMatch' },
            { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },

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

            { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
            { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
            { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
            { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
            { key = 'Enter', mods = 'NONE', action = act.Multiple {{ CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' }} },
            { key = 'C', mods = 'CTRL', action = act.Multiple {{ CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' }} },

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
    },
}

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
    {   key = 'UpArrow', mods = 'SHIFT',
        action = wt.action.ScrollToPrompt(-1)
    },
    {   key = 'DownArrow', mods = 'SHIFT',
        action = wt.action.ScrollToPrompt(1)
    },
    {   key = "w", mods = "CTRL",
        action = wt.action { CloseCurrentPane = { confirm = false } }
    },
    {   key = "t", mods = "CTRL",
        action = wt.action{ SpawnTab = "DefaultDomain" },
    },
    {   key = "n", mods = "CTRL",
        action = wt.action{ SpawnTab = "DefaultDomain" },
    },
    -- -- This would let us use CTRL+C to copy selections (but we'd need to disable the default copy on select)
    -- -- E.g. https://gist.github.com/kvnxiao/c0f47da586fc997ef83c9fcbb9b61238
    -- {   key = "C", mods = "CTRL",
    --     action = wt.action_callback(function(win, pane)
    --         local has_selection = win:get_selection_text_for_pane(pane) ~= ""
    --         if has_selection then
    --             win:perform_action(wt.action {
    --                 CopyTo = "ClipboardAndPrimarySelection"
    --             }, pane)
    --         else
    --             win:perform_action(wt.action {
    --                 SendKey = {
    --                     key = "c",
    --                     mods = "CTRL"
    --                 }
    --             }, pane)
    --         end
    --     end)
    -- }
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
    window_background_opacity = 0.9,
    default_cursor_style = "BlinkingUnderline",
    cursor_blink_rate = 500,
    -- window_decorations = "RESIZE",
    window_padding = { left = 0, right = 0, top = 0, bottom = 0, },
    default_prog = {getFirstShell('pwsh.exe', 'pwsh', 'powershell.exe', 'bash', 'bash.exe', 'cmd.exe')},
    default_cwd = wt.home_dir,
    font_size = 12.0,
    font = wt.font_with_fallback({'CaskaydiaCove NFM', 'FiraCode NFM', 'Cascadia Code', 'Consolas'}),
    launch_menu = launch_menu,
    mouse_bindings = mouse_bindings,

    keys = custom_keys,
    key_tables = {
        copy_mode = {
            { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
            { key = 'Tab', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
            { key = 'Tab', mods = 'SHIFT', action = act.CopyMode 'MoveBackwardWord' },
            { key = 'Enter', mods = 'NONE', action = act.CopyMode 'MoveToStartOfNextLine' },
            { key = 'Space', mods = 'NONE', action = act.CopyMode { SetSelectionMode = 'Cell' } },
            { key = '$', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
            { key = '$', mods = 'SHIFT', action = act.CopyMode 'MoveToEndOfLineContent' },
            { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
            { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
            { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
            { key = 'F', mods = 'NONE', action = act.CopyMode { JumpBackward = { prev_char = false } } },
            { key = 'F', mods = 'SHIFT', action = act.CopyMode { JumpBackward = { prev_char = false } } },
            { key = 'G', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackBottom' },
            { key = 'G', mods = 'SHIFT', action = act.CopyMode 'MoveToScrollbackBottom' },
            { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
            { key = 'H', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportTop' },
            { key = 'L', mods = 'NONE', action = act.CopyMode 'MoveToViewportBottom' },
            { key = 'L', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportBottom' },
            { key = 'M', mods = 'NONE', action = act.CopyMode 'MoveToViewportMiddle' },
            { key = 'M', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportMiddle' },
            { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
            { key = 'O', mods = 'SHIFT', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
            { key = 'T', mods = 'NONE', action = act.CopyMode { JumpBackward = { prev_char = true } } },
            { key = 'T', mods = 'SHIFT', action = act.CopyMode { JumpBackward = { prev_char = true } } },
            { key = 'V', mods = 'NONE', action = act.CopyMode { SetSelectionMode = 'Line' } },
            { key = 'V', mods = 'SHIFT', action = act.CopyMode { SetSelectionMode = 'Line' } },
            { key = '^', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLineContent' },
            { key = '^', mods = 'SHIFT', action = act.CopyMode 'MoveToStartOfLineContent' },
            { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
            { key = 'b', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
            { key = 'b', mods = 'CTRL', action = act.CopyMode 'PageUp' },
            { key = 'c', mods = 'CTRL', action = act.CopyMode 'Close' },
            { key = 'f', mods = 'NONE', action = act.CopyMode { JumpForward = { prev_char = false } } },
            { key = 'f', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
            { key = 'f', mods = 'CTRL', action = act.CopyMode 'PageDown' },
            { key = 'g', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackTop' },
            { key = 'g', mods = 'CTRL', action = act.CopyMode 'Close' },
            { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
            { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
            { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
            { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
            { key = 'm', mods = 'ALT', action = act.CopyMode 'MoveToStartOfLineContent' },
            { key = 'o', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEnd' },
            { key = 'q', mods = 'NONE', action = act.CopyMode 'Close' },
            { key = 't', mods = 'NONE', action = act.CopyMode { JumpForward = { prev_char = true } } },
            { key = 'v', mods = 'NONE', action = act.CopyMode { SetSelectionMode = 'Cell' } },
            { key = 'v', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Block' } },
            { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
            { key = 'y', mods = 'NONE', action = act.Multiple {{ CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' }} },
            { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
            { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },
            { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
            { key = 'LeftArrow', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
            { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'MoveRight' },
            { key = 'RightArrow', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
            { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'MoveUp' },
            { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'MoveDown' },
            -- there's got to be some way of making this work
            { key = 'UpArrow', mods = 'SHIFT', action = act.CopyMode { MoveBackwardZoneOfType = 'Output' } },
            { key = 'DownArrow', mods = 'SHIFT', action = act.CopyMode { MoveForwardZoneOfType = 'Output' } }
        }
    },
}

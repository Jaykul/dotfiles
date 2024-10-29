-- We almost always start by importing the wezterm module
local wezterm = require 'wezterm'
-- Define a lua table to hold _our_ module's functions
local module = {}


local menu = {
    {
        label = 'pwsh',
        args = {'pwsh', '-nologo'}
    }, {
        label = 'pwsh -noprofile',
        args = {'pwsh', '-noprofile', '-nologo'}
    }
}


function module.getFirstShell(...)
    -- find the first shell from an ordered list
    local folderSep = package.config:sub(1, 1)
    local pathSep = package.config:sub(3, 3)
    local pathMatch = string.format('([^%s]+)', pathSep)
    ospath = os.getenv("PATH")

    -- look for the shells in order of preference
    for _, shell in pairs({...}) do
        -- iterate through PATH entries
        for path in string.gmatch(ospath, pathMatch) do
            for _, file in ipairs(wezterm.glob(path .. folderSep .. shell)) do -- iterate through files in that entry
                wezterm.log_info('file: ' .. file)
                return file
            end
        end
    end
end

-- OS detection":
-- wezterm.log_info('wezterm config loaded:' .. wezterm.target_triple)
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    table.insert(menu, {
        label = "PowerShell",
        args = {"powershell.exe", "-NoLogo"},
    })
    table.insert(menu, {
        label = "PowerShell -NoProfile",
        args = {"powershell.exe", "-NoLogo", "-NoProfile"},
    })
    -- table.insert(menu, {
    --     label = "PowerShell (Admin)",
    --     args = {"powershell.exe", "-NoLogo", "Start-Process", "-Verb", "runAs", "wt", "powershell.exe"},
    -- })
    table.insert(menu, {
        label = "Command Prompt",
        args = {'cmd'}
    })
end

return module

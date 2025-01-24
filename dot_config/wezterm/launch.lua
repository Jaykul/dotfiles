-- We almost always start by importing the wezterm module
local wezterm = require 'wezterm'
-- Define a lua table to hold _our_ module's functions
local module = {}

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

function module.getShells(launch_menu)
    -- OS detection":
    wezterm.log_info('wezterm config loaded:' .. wezterm.target_triple)
    -- Only the first 9 get a number keybinding
    -- Less important things go in "extra" and get merged last
    local extra_launch_menu = {}

    if wezterm.target_triple == "x86_64-pc-windows-msvc" then
        -- Find installed PowerShell versions and add them to the menu (should just be 7 and maybe 7-preview)
        for _, psvers in ipairs(wezterm.glob('*/pwsh.exe', os.getenv('ProgramFiles') .. '/PowerShell/'))
        do
            local version = psvers:gsub('/pwsh.exe', '')
            table.insert(launch_menu, {
                label = 'pwsh ' .. version,
                args = {
                    os.getenv('ProgramFiles') .. '/PowerShell/' .. psvers,
                    '-nologo',
                },
                })
            table.insert(extra_launch_menu, {
                label = 'pwsh ' .. version .. ' -noprofile',
                args = {
                    os.getenv('ProgramFiles') .. '/PowerShell/' .. psvers,
                    '-nologo', '-noprofile'
                },
            })
        end
        -- Find installed visual studio version(s) and add their compilation
        -- environment command prompts to the menu
        for _, vsvers in ipairs( wezterm.glob('Microsoft Visual Studio/20*', os.getenv('ProgramFiles(x86)') .. '/'))
        do
            local year = vsvers:gsub('Microsoft Visual Studio/', '')
            table.insert(launch_menu, {
            label = 'x64 Native Tools VS ' .. year,
            args = {
                'cmd.exe',
                '/k',
                os.getenv('ProgramFiles(x86)') .. '/' ..vsvers .. '/BuildTools/VC/Auxiliary/Build/vcvars64.bat',
            },
            })
        end

        -- Add Windows PowerShell
        table.insert(launch_menu, {
            label = "PowerShell",
            args = {"powershell.exe", "-NoLogo"},
        })
        table.insert(extra_launch_menu, {
            label = "PowerShell -NoProfile",
            args = {"powershell.exe", "-NoLogo", "-NoProfile"},
        })
        -- table.insert(menu, {
        --     label = "PowerShell (Admin)",
        --     args = {"powershell.exe", "-NoLogo", "Start-Process", "-Verb", "runAs", "wt", "powershell.exe"},
        -- })
        -- and CMD, just to be completionist
        table.insert(extra_launch_menu, {
            label = "Command Prompt",
            args = {'cmd'}
        })
        -- and choco, we can run that inside pwsh
        table.insert(extra_launch_menu, {
            label = "choco upgrade all",
            args = {'choco','upgrade','all','-y'}
        })
    else
        -- I always want pwsh on the menu
        table.insert(launch_menu, {
            label = 'pwsh',
            args = {'pwsh', '-nologo'}
        })
        table.insert(extra_launch_menu, {
            label = 'pwsh -noprofile',
            args = {'pwsh', '-noprofile', '-nologo'}
        })

        table.insert(launch_menu, {
            args = {"top"},
        })
    end

    for _, extra in ipairs(extra_launch_menu) do
        table.insert(launch_menu, extra)
    end


    return launch_menu

end

return module

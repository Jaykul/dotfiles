
<#PSScriptInfo

.VERSION 4.1

.GUID 23eb26e7-5758-4b73-b9f9-c4ae0d611a53

.AUTHOR Joel 'Jaykul' Bennett

.COMPANYNAME PoshCode

.COPYRIGHT Copyright 2019, Joel Bennett.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

.TAGS Edit VSCode

.LICENSEURI

.PROJECTURI http://GitHub.com/PoshCode/ModuleBuilder

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    5.0 - Fix -Wait (which used to be -NoWait)
        - Add -NewWindow switch to force opening a new window, because I don't want to always -NewWindow with VSCode because it's so slow
    4.1 - Refactored back to a script function and publish to PowerShell Gallery
    4.0 - Added support for VS Code, fixed a bug in the internal SplitCommand
    3.0 - made it work for file paths, and any script command. Added "edit" alias, and "NoWait" option.
    2.1 - fixed the fix: always remove temp file, persist across-sessions in environment
    2.0 - fixed persistence of editor options, made detection more clever
    1.1 - refactored by June to (also) work on her machine (and have help)
    1.0 - first draft, worked on my machine

.PRIVATEDATA

#>

<#
    .SYNOPSIS
        Opens folders, files, or functions in your favorite code editor (configurable)

    .DESCRIPTION
        The edit command lets you open a folder, a file, or even a script function from your session in your favorite text editor.

        It opens the specified function in the editor that you specify, and when you finish editing the function and close the editor, the script updates the function in your session with the new function code.

        Functions are tricky to edit, because most code editors require a file, and determine syntax highlighting based on the extension of that file. edit creates a temporary file with the function code.

        If you have a favorite editor, you can use the Editor parameter to specify it once, and the script will save it as your preference. If you don't specify an editor, it tries to determine an editor using the PSEditor preference variable, the EDITOR environment variable, or your configuration for git.  As a fallback it searches for Sublime, and finally falls back to Notepad.

        REMEMBER: Because functions are specific to a session, your function edits are lost when you close the session unless you save them in a permanent file, such as your Windows PowerShell profile.

    .EXAMPLE
        edit Prompt

        Opens the prompt function in a default editor (gitpad, Sublime, Notepad, whatever)

    .EXAMPLE
        dir Function:\cd* | edit -Editor "C:\Program Files\Sublime Text 3\subl.exe" -Param "-n -w"

        Pipes all functions starting with cd to edit, which opens them one at a time in a new sublime window (opens each one after the other closes).

    .EXAMPLE
        Get-Command TabExpan* | edit -Editor 'C:\Program Files\SAPIEN Technologies, Inc\PowerShell Studio 2014\PowerShell Studio.exe

        Edits the TabExpansion and/or TabExpansion2 (whichever exists) in PowerShell Studio 2014 using the full path to the .exe file.
        Note that this also sets PowerShell Studio as your default editor for future calls.

    .NOTES
        The EditFunction is probably going into the ModuleBuilder module, but for now, here it is.
        By Joel Bennett (@Jaykul) and June Blender (@juneb_get_help)

        If you'd like anything changed, contact me on Discord (https://discord.gg/PowerShell), Twitter (@Jaykul), Mastodon (@Jaykul@fosstodon.org) or BlueSky (@Jaykul.PowerShell.Social)
        - Do you not like that I make every editor the default?
        - Think I should detect another editor?

        About ISE: it doesn't support waiting for the editor to close, so I can't really support it...
        If you're sure you don't care about that, and want to use PowerShell ISE, you can set it in $PSEditor or pass it as a parameter.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
[Alias("Edit-Code")]
[CmdletBinding(DefaultParameterSetName = "Command")]
param (
    # Specifies the name of a function or script to create or edit. Enter a function name or pipe a function to edit.
    # This parameter is required. If the function doesn't exist in the session, edit creates it.
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Command")]
    [Alias("PSPath")]
    [String]
    $Command,

    # Specifies the name of a function or script to create or edit. Enter a function name or pipe a function to edit.ps1.
    # This parameter is required. If the function doesn't exist in the session, edit creates it.
    [Parameter(Mandatory = $true, ParameterSetName = "File", ValueFromPipelineByPropertyName = $true)]
    [String[]]
    $Path,

    # Specifies a code editor.
    # If the editor is in the Path environment variable (Get-Command <editor>), you can enter just the editor name.
    # Otherwise, enter the path to the executable file for the editor.
    # Defaults to the value of $PSEditor.Command or $PSEditor or Env:Editor if any of them are set.
    [Parameter(Position = 1)]
    [String]
    $Editor = $(
        if ($global:PSEditor.Command) {
            $global:PSEditor.Command
        } else {
            $global:PSEditor
        }
    ),

    # Specifies commandline parameters for the editor that should _always_ be used.
    # edit.ps1 passes these editor-specific parameters to the editor you select.
    # For example, sublime uses -n -w to trigger a mode where closing the *tab* will return
    [Parameter(Position = 2)]
    [String]
    $Parameters = $global:PSEditor.Parameters,

    # Waits for the editor.
    # This switch is set automatically when editing a function, so we can update the function after you finish editing the file.
    # Otherwise, you need to set it manually, or the script will return immediately after opening your editor.
    [Switch]$Wait,

    # Force editing "Application" scripts.
    # Folders, and files with extensions .cmd, .bat, .vbs, .pl, .rb, .py, .wsf, and .js are known to editable, others will prompt unless Force is set, because most "Application"s aren't editable (they're .exe, .cpl, .com, .msc, etc.)
    [Switch]$Force,

    # Force opening a new window (*if* your PSEditor config supports it)
    [Switch]$NewWindow
)
begin {

    #requires -Version 3.0
    function SplitCommand {
        <#
            .SYNOPSIS
                SplitCommand divides the input command into the executable command and the parameters
            .DESCRIPTION
                Start-Process needs the command name separate from the parameters

                The normal (unix) "Editor" environment variable (or the one in `git config core.editor`)
                can include parameters so it can be executed by just appending the file name.
        #>
        param(
            # The Editor command from the environment, like 'code -n -w'
            [Parameter(Mandatory = $true)]
            [string]$Command
        )
        $Parts = @($Command -Split " ")

        for ($count = 0; $count -lt $Parts.Length; $count++) {
            $Editor = ($Parts[0..$count] -join " ").Trim("'", '"')
            if (Get-Command $Editor -ErrorAction Ignore) {
                $Editor
                $Parts[$($Count + 1)..$($Parts.Length)] -join " "
                break
            }
        }
    }

    function FindEditor {
        #.Synopsis
        #   Find a simple code editor
        #.Description
        #   Tries to find a text editor based on the PSEditor preference variable, the EDITOR environment variable, or your configuration for git.
        #   As a fallback it searches for Sublime, VSCode, Atom, or Notepad++, and finally falls back to Notepad.
        #
        #   I have deliberately excluded PowerShell_ISE because it is a single-instance app which doesn't support "wait" if it's already running.
        #   That is, if PowerShell_ISE is already running, issuing a command like this will return immediately:
        #
        #   Start-Process PowerShell_ISE $Profile -Wait
        [CmdletBinding()]
        param
        (
            # Specifies a code editor. If the editor is in the Path environment variable (Get-Command <editor>), you can enter just the editor name. Otherwise, enter the path to the executable file for the editor.
            # Defaults to the value of $PSEditor.Command or $PSEditor or Env:Editor if any of them are set.
            [Parameter(Position = 1)]
            [System.String]
            $Editor = $(
                if ($global:PSEditor.Command) {
                    $global:PSEditor.Command
                } else {
                    $global:PSEditor
                }
            ),

            # Specifies default commandline parameters for the editor.
            # edit.ps1 passes these editor-specific parameters to the editor you select.
            # For example, sublime uses -n -w to trigger a mode where closing the *tab* will return
            [Parameter(Position = 2)]
            [System.String]
            $Parameters = $global:PSEditor.Parameters,
            # The string for the switch that tells the editor we're waiting for this tab to close. E.g.: "--wait" or "-w"
            $WaitSwitch = $global:PSEditor.WaitSwitch,
            # The string for the switch that tells the editor to open a new window. E.g.: "--new-window" or "-n"
            $NewWindowSwitch = $global:PSEditor.NewWindowSwitch
        )

        end {
            do {
                # This is the GOTO hack: use break to skip to the end once we find it:
                # In this test, we let the Get-Command error leak out on purpose
                if ($Editor -and (Get-Command $Editor)) { break }

                if ($Editor -and !(Get-Command $Editor -ErrorAction Ignore)) {
                    Write-Verbose "Editor is not a valid command, split it:"
                    $Editor, $Parameters = SplitCommand $Editor
                    if ($Editor) { break }
                }

                if (Test-Path Env:Editor) {
                    Write-Verbose "Editor was not passed in, trying Env:Editor"
                    $Editor, $Parameters = SplitCommand $Env:Editor
                    if ($Editor) { break }
                }

                # If no editor is specified, try looking in git config
                if (Get-Command Git -ErrorAction Ignore) {
                    Write-Verbose "PSEditor and Env:Editor not found, searching git config"
                    if ($CoreEditor = git config core.editor) {
                        $Editor, $Parameters = SplitCommand $CoreEditor
                        if ($Editor) { break }
                    }
                }

                # Try a few common ones that might be in the path
                Write-Verbose "Editor not found, searching your path"
                if ($Editor = Get-Command "subl", "code", "code-insiders", "notepad++.exe" -ErrorAction Ignore | Select-Object -Expand Path -First 1) {
                    break
                }
                # Search the slow way for sublime
                Write-Verbose "Editor still not found, getting desperate:"
                if (($Editor = Get-Item "C:\Program Files\Sublime Text\subl.exe" -ErrorAction Ignore | Select-Object -First 1) -or
                ($Editor = Get-ChildItem C:\Program*\* -Recurse -Filter "subl.exe" -ErrorAction Ignore | Select-Object -First 1)) {
                    break
                }

                if (($Editor = Get-ChildItem "C:\Program Files\Notepad++\notepad++.exe" -Recurse -Filter "notepad++.exe" -ErrorAction Ignore | Select-Object -First 1) -or
                ($Editor = Get-ChildItem C:\Program*\* -Recurse -Filter "notepad++.exe" -ErrorAction Ignore | Select-Object -First 1)) {
                    break
                }

                # Settling for Notepad
                Write-Verbose "Editor not found, settling for notepad"
                $Editor = "notepad"

                if (!$Editor -or !(Get-Command $Editor -ErrorAction SilentlyContinue -ErrorVariable NotFound)) {
                    if ($NotFound) { $PSCmdlet.ThrowTerminatingError( $NotFound[0] ) }
                    else {
                        throw "Could not find an editor (not even notepad!)"
                    }
                }
            } while ($false)

            if (!$NewWindowSwitch -or !$Parameters) {
                switch -Regex ($Editor) {
                    "subl" {
                        $Parameters = "--new-window --wait"
                        $WaitSwitch = "--wait"
                        $NewWindowSwitch = "--new-window"
                    }
                    "code" {
                        $Parameters = ""
                        $WaitSwitch = "--wait"
                        $NewWindowSwitch = "--new-window"
                    }
                    "notepad\+\+" {
                        $Parameters = "-multiInst"
                        $NewWindowSwitch = "-multiInst"
                    }
                    default {
                        Write-Warning "Unknown editor '$Editor', you may need to specify parameters manually."
                    }
                }
            }

            $PSEditor = [PSCustomObject]@{
                PSTypeName      = "PSEditor"
                Command         = "$Editor"
                Parameters      = "$Parameters"
                WaitSwitch      = "$WaitSwitch"
                NewWindowSwitch = "$NewWindowSwitch"
            } | Add-Member ScriptMethod ToString -Value { "'" + $this.Command + "' " + $this.Parameters } -Force -PassThru

            # There are several reasons we might need to update the editor variable
            if ( $PSBoundParameters.ContainsKey("Editor") -or
                $PSBoundParameters.ContainsKey("Parameters") -or
                !(Test-Path variable:global:PSeditor) -or
                ($PSEditor.Command -ne $Editor)) {
                # Store it pre-parsed and everything in the current session:
                Write-Verbose "Setting global preference variable for Editor: PSEditor"
                $global:PSEditor = $PSEditor

                # Store it stickily in the environment variable
                if (![Environment]::GetEnvironmentVariable("Editor", "User")) {
                    Write-Verbose "Setting user environment variable: Editor"
                    [Environment]::SetEnvironmentVariable("Editor", "$PSEditor", "User")
                }
            }
            return $PSEditor
        }
    }

    # This is probably a terrible idea ...
    $TextApplications = ".cmd", ".bat", ".vbs", ".pl", ".rb", ".py", ".wsf", ".js", ".ps1"
    $NonFileCharacters = "[$(([IO.Path]::GetInvalidFileNameChars() | ForEach-Object{ [regex]::escape($_) }) -join '|')]"

    $RejectAll = $false;
    $ConfirmAll = $false;
}
process {
    [String[]]$Files = @()
    # Resolve-Alias-A-la-cheap:
    $MaxDepth = 10
    if ($PSCmdlet.ParameterSetName -eq "Command") {
        while ($Cmd = Get-Command $Command -Type Alias -ErrorAction Ignore) {
            $Command = $Cmd.definition
            if (($MaxDepth--) -lt 0) { break }
        }

        # We know how to edit Functions, ExternalScript, and even Applications, if you're sure...
        $Files = @(
            switch (Get-Command $Command -ErrorAction "Ignore" -Type "Function", "ExternalScript", "Application" | Select-Object -First 1) {
                { $_.CommandType -eq "Function" } {
                    Write-Verbose "Found a function matching $Command"
                    #Creates a temporary file in your temp directory with a .tmp.ps1 extension.
                    $File = [IO.Path]::GetTempFileName() |
                        Rename-Item -NewName { [IO.Path]::ChangeExtension($_, ".tmp.ps1") } -PassThru |
                        Select-Object -Expand FullName

                    #If you have a function with this name, it saves the function code in the temporary file.
                    if (Test-Path Function:\$Command) {
                        Set-Content -Path $File -Value $((Get-Content Function:\$Command) -Join "`n")
                    }
                    $File
                }

                { $_.CommandType -eq "ExternalScript" } {
                    Write-Verbose "Found an ExternalScript matching $Command"
                    $_.Path
                }

                { $_.CommandType -eq "Application" } {
                    Write-Verbose "Found an Application or Script matching $Command"
                    if (($TextApplications -contains $_.Extension) -or $Force -Or $PSCmdlet.ShouldContinue("Are you sure you want to edit '$($_.Path)' in a text editor?", "Opening '$($_.Name)'", [ref]$ConfirmAll, [ref]$RejectAll)) {
                        $_.Path
                    }
                }
            }
        )

        if ($Files.Length -eq 0) {
            Write-Verbose "No '$Command' command found, resolving file path"
            $Files = @(Resolve-Path $Command -ErrorAction Ignore | Select-Object -Expand Path)

            if ($Files.Length -eq 0) {
                Write-Verbose "Still no file found, they're probably trying to create a new function"
                # If the function name is basically ok, then lets make an random empty file for them to write it
                if ($Command -notmatch $NonFileCharacters) {
                    # Creates a temporary file in your temp directory with a .tmp.ps1 extension.
                    $File = [IO.Path]::GetTempFileName() |
                        Rename-Item -NewName { [IO.Path]::ChangeExtension($_, ".tmp.ps1") } -PassThru |
                        Select-Object -Expand FullName

                    #If you have a function with this name, it saves the function code in the temporary file.
                    if (Test-Path Function:\$Command) {
                        Set-Content -Path $file -Value $((Get-Content Function:\$Command) -Join "`n")
                    }
                    $Files = @($File)
                }
            } else {
                $Files
            }
        }
    } else {
        Write-Verbose "Resolving file path, because although we'll create files, we won't create directories"
        $Folder = Split-Path $Path
        $FileName = Split-Path $Path -Leaf
        # If the folder doesn't exist, die
        $Files = @(
            if ($Folder -and -not (Resolve-Path $Folder -ErrorAction Ignore)) {
                Write-Error "The path '$Folder' doesn't exist, so we cannot create '$FileName' there"
                return
            } elseif ($FileName -notmatch $NonFileCharacters) {
                foreach ($F in Resolve-Path $Folder -ErrorAction Ignore) {
                    Join-Path $F $FileName
                }
            } else {
                Resolve-Path $Path -ErrorAction Ignore | Select-Object -Expand Path
            }
        )
    }

    $PSEditor = FindEditor
    # Make sure we have a local copy of Parameters
    if (!$Parameters) {
        $Parameters = $PSEditor.Parameters
    }
    # Update the parameters for switches (including explicit opt-out)
    if ($Wait) {
        if ($PSEditor.WaitSwitch -and -not $Parameters.contains($PSEditor.WaitSwitch)) {
            Write-Verbose "Adding $($PSEditor.WaitSwitch) to parameters"
            $Parameters += " $($PSEditor.WaitSwitch)"
        }
    } elseif ($Parameters.contains("Wait") -and $PSEditor.WaitSwitch) {
        Write-Verbose "Removing $($PSEditor.WaitSwitch) from parameters"
        $Parameters = $Parameters -replace [regex]::escape($PSEditor.WaitSwitch)
    }
    if ($NewWindow) {
        if ($PSEditor.NewWindowSwitch -and -not $Parameters.contains($PSEditor.NewWindowSwitch)) {
            Write-Verbose "Adding $($PSEditor.NewWindowSwitch) to parameters"
            $Parameters += " $($PSEditor.NewWindowSwitch)"
        }
    } elseif ($Parameters.contains("NewWindow") -and $PSEditor.NewWindowSwitch) {
        Write-Verbose "Removing $($PSEditor.NewWindowSwitch) from parameters"
        $Parameters = $Parameters -replace [regex]::escape($PSEditor.NewWindowSwitch)
    }

    # Finally, edit the file!
    foreach ($File in @($Files)) {
        if ($File) {
            $LastWriteTime = (Get-Item $File).LastWriteTime

            # If it's a temp file, they're editing a function, so we have to wait!
            if ($File.EndsWith(".tmp.ps1") -and $File.StartsWith(([IO.Path]::GetTempPath()))) {
                $NoWait = $false
            }

            # Avoid errors if Parameter is null/empty.
            Write-Verbose "$($PSEditor.Command) $Parameters '$File'"
            if ($Parameters) {
                Start-Process -FilePath $PSEditor.Command -ArgumentList $Parameters, """$file""" -Wait:(!$NoWait) -NoNewWindow
            } else {
                Start-Process -FilePath $PSEditor.Command -ArgumentList """$file""" -Wait:(!$NoWait) -NoNewWindow
            }

            # Remove it if we created it
            if ($File.EndsWith(".tmp.ps1") -and $File.StartsWith(([IO.Path]::GetTempPath()))) {

                if ($LastWriteTime -ne (Get-Item $File).LastWriteTime) {
                    Write-Verbose "Changed $Command function"
                    # Recreates the function from the code in the temporary file and then deletes the file.
                    Set-Content -Path Function:\$Command -Value ([scriptblock]::create(((Get-Content $file) -Join "`n")))
                } else {
                    Write-Warning "No change to $Command function"
                }

                Write-Verbose "Deleting temp file $File"
                Remove-Item $File
            }
        }
    }
}
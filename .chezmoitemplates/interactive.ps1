# We need to force encoding to UTF8 for PSReadLine to do the right thing with extended characters
# But we need to make sure it's UTF8-NoBOM
[Console]::OutputEncoding = [Console]::InputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()

# Just a handful of additional TypeAccelerators
$xlr8r = [psobject].assembly.gettype("System.Management.Automation.TypeAccelerators")
$Accelerate = @{
    ReadLine   = [Microsoft.PowerShell.PSConsoleReadLine]
    List       = [System.Collections.Generic.List``1]
    Dictionary = [System.Collections.Generic.Dictionary``2]
}
if ($xlr8r::AddReplace) {
    $Accelerate.GetEnumerator().ForEach({
        $xlr8r::AddReplace($_.Key, $_.Value)
    })
} else {
    $Accelerate.GetEnumerator().ForEach({
        $null = $xlr8r::Remove($_.Key)
        $xlr8r::Add($_.Key, $_.Value)
    })
}

# Write-Information "Checking PSModulePath.env"
# Once a week I want to update the PSModulePath, just in case
$Before = (Get-Item ($PSModulePathPath = [IO.Path]::ChangeExtension($Profile, ".PSModulePath.env")) -ErrorAction Ignore).LastWriteTime
if (-not $Before -or (24 * 7) -lt ([DateTime]::Now - $Before).TotalHours) {
    Update-PSModulePath $PSModulePathFile -ProfileDir $ProfileDir
}

# Write-Information "Setting Location."
# For default elevated sessions, set the start location where it should be
if ($pwd.Path -eq "$Env:SystemRoot\System32") {
    {{ if eq .chezmoi.username "LD\\joelbennett" -}}
    Set-Location $ldx
    {{- else -}}
    Set-Location $ProfileDir
    {{- end }}
}

# Write-Information "Importing Default Modules."
# Note these are dependencies of the Profile module, but it's faster to load them explicitly up front
$DefaultModules = @(
    @{ ModuleName = "Microsoft.PowerShell.Management"; ModuleVersion = "3.1.0" }
    @{ ModuleName = "Microsoft.PowerShell.Security"; ModuleVersion = "3.0.0" }
    @{ ModuleName = "Microsoft.PowerShell.Utility"; ModuleVersion = "3.1.0" }
    @{ ModuleName = "Metadata"; ModuleVersion = "1.5.7" }
    @{ ModuleName = "Configuration"; ModuleVersion = "1.5.1" }
    @{ ModuleName = "Pansies"; ModuleVersion = "2.6.0" }
    @{ ModuleName = "TerminalBlocks"; ModuleVersion = "1.0.0" }
    @{ ModuleName = "PowerLine"; ModuleVersion = "4.0.0" }

    if ($Env:WT_SESSION) {
        @{ ModuleName = "EzTheme"; ModuleVersion = "0.1.0" }
        @{ ModuleName = "Theme.PowerShell"; ModuleVersion = "0.1.0" }
        @{ ModuleName = "Theme.PSReadline"; ModuleVersion = "0.1.0" }
        @{ ModuleName = "Theme.WindowsTerminal"; ModuleVersion = "0.1.0" }
    } else {
        @{ ModuleName = "EzTheme"; ModuleVersion = "0.1.1" }
        @{ ModuleName = "Theme.PowerShell"; ModuleVersion = "0.1.0" }
        @{ ModuleName = "Theme.PSReadline"; ModuleVersion = "0.1.0" }
    }

    @{ ModuleName = "Environment"; RequiredVersion = "1.1.0" }
    @{ ModuleName = "posh-git"; ModuleVersion = "1.1.0" }
    @{ ModuleName = "PowerLine"; ModuleVersion = "3.4.1" }
    @{ ModuleName = "PSReadLine"; ModuleVersion="2.4.0" }

    @{ ModuleName = "DefaultParameter"; RequiredVersion = "2.0.0" }
    # @{ ModuleName = "ErrorView"; RequiredVersion = "0.0.2" }
    @{ ModuleName = "zLocation"; ModuleVersion = "1.4.3" }
    # @{ ModuleName = "Profile"; ModuleVersion = "1.3.0" }
    {{ if eq .chezmoi.username "LD\\joelbennett" -}}
    @{ ModuleName = "LDOther"; ModuleVersion = "0.5.0" }
    @{ ModuleName = "LDUtility"; ModuleVersion = "5.7.1" }
    @{ ModuleName = "LDXGet"; ModuleVersion = "6.0.4" }
    {{- end }}
)

Import-Module -FullyQualifiedName $DefaultModules -Scope Global

# Write-Information "Importing Theme."
if (([PoshCode.TerminalBlock]::Elevated) -and (Get-Theme "${Env:UserName}-Elevated")) {
    Import-Theme "${Env:UserName}-Elevated" -IncludeModule Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, PowerLine
} elseif (($PSVersionTable.PSVersion.Major -le 7) -and (Get-Theme "${Env:UserName}-Legacy")) {
    Import-Theme "${Env:UserName}-Legacy"
} else {
    Import-Theme "${Env:UserName}" -IncludeModule Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, PowerLine
}

if ($PSStyle.OutputRendering) {
    # Make sure PSStyle doesn't mess with our color!
    $PSStyle.OutputRendering = 'ansi'
}
[PoshCode.Pansies.RgbColor]::ColorMode = 'Rgb24Bit'

$global:GitPromptSettings = New-GitPromptSettings
$global:GitPromptSettings.BeforeStatus = ''
$global:GitPromptSettings.AfterStatus = ''
$global:GitPromptSettings.PathStatusSeparator = ''
$global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
$global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"


# Write-Information "Write PowerLine Prompt"
# Now that we've imported PowerLine and configured Posh-Git we can call the NEW prompt function:
Write-PowerlinePrompt

# Write-Information "Configure PSReadLine KeyHandlers"
# This would be SO MUCH FASTER if PSReadLine had a config file instead of me calling this cmdlet 15 or 20 times
Set-PSReadLineKeyHandler Ctrl+Alt+c CaptureScreen
Set-PSReadLineKeyHandler Ctrl+Shift+r ForwardSearchHistory
Set-PSReadLineKeyHandler Ctrl+r ReverseSearchHistory

Set-PSReadLineKeyHandler Ctrl+DownArrow HistorySearchForward
Set-PSReadLineKeyHandler Ctrl+UpArrow HistorySearchBackward
Set-PSReadLineKeyHandler Ctrl+Home BeginningOfHistory

Set-PSReadLineKeyHandler Ctrl+m SetMark
Set-PSReadLineKeyHandler Ctrl+Shift+m ExchangePointAndMark

Set-PSReadLineKeyHandler Ctrl+K KillLine
Set-PSReadLineKeyHandler Ctrl+I Yank

Set-PSReadLineKeyHandler Ctrl+h BackwardDeleteWord
Set-PSReadLineKeyHandler Ctrl+Enter AddLine
Set-PSReadLineKeyHandler Ctrl+Shift+Enter AcceptAndGetNext

Set-PSReadLineKeyHandler -Key Alt+w {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [ReadLine]::AddToHistory($line)
    [ReadLine]::RevertLine()
} -Description "Save current line in history but do not execute"

Set-PSReadLineKeyHandler '(', '{', '[', '"', "'" {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar) {
        '(' { [char]')'; break }
        '{' { [char]'}'; break }
        '[' { [char]']'; break }
        '"' { [char]'"'; break }
        "'" { [char]"'"; break }
    }

    $start = $null
    $length = $null
    [ReadLine]::GetSelectionState([ref]$start, [ref]$length)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    if ($start -ne -1) {
        # Text is selected, wrap it in brackets
        [ReadLine]::Replace($start, $length, $key.KeyChar + $command.SubString($start, $length) + $closeChar)
        [ReadLine]::SetCursorPosition($start + $length + 2)
    } elseif ($cursor -eq 0 -and $command.length) {
        # Cursor's at the start of the command, wrap the whole command
        [ReadLine]::Replace(0, $command.length, $key.KeyChar + $command + $closeChar)
        [ReadLine]::SetCursorPosition($command.length + 2)
    } elseif ($cursor -eq $command.length) {
        # If we're at the end, do a matching pair
        [ReadLine]::Insert("$($key.KeyChar)$closeChar")
        [ReadLine]::SetCursorPosition($cursor + 1)
    } else {
        # Otherwise, just the character they typed
        [ReadLine]::Insert("$($key.KeyChar)")
        [ReadLine]::SetCursorPosition($cursor + 1)
    }
} -Description "Insert matching braces and quotes"

Set-PSReadLineKeyHandler ')', ']', '}', '"', "'" {
    param($key, $arg)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    # If the _next_ character matches this one, just move past it
    if ($command[$cursor] -eq $key.KeyChar) {
        [ReadLine]::SetCursorPosition($cursor + 1)
    } else {
        [ReadLine]::Insert("$($key.KeyChar)")
    }

    # For unmatched closing parenthesis, wrap the whole command
    if ($key.KeyChar -eq ')') {
        $tokens = $null
        $parseError = $null
        $ast = $null
        $cursor = $null
        [ReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseError, [ref]$cursor)
        # but only if it's at the VERY end
        if ($parseError.Extent.Text -eq $key.KeyChar -and $parseError.Extent.EndOffset -eq $cursor) {
            [ReadLine]::Replace(0, $ast.Extent.EndOffset, "($command)" )
            [ReadLine]::SetCursorPosition($command.length + 2)
        }
    }

} -Description "Insert or skip closing brace or wrap!"

Set-PSReadLineKeyHandler Backspace {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0) {
        $toMatch = $null
        if ($cursor -lt $line.Length) {
            switch ($line[$cursor]) {
                # '"' { $toMatch = '"'; break }
                # "'" { $toMatch = "'"; break }
                ')' { $toMatch = '('; break }
                ']' { $toMatch = '['; break }
                '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
            [ReadLine]::Delete($cursor - 1, 2)
        } else {
            [ReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
} -Description "Delete smart quotes/parens/braces"

Set-PSReadLineKeyHandler "Alt+]" {
    param($key, $arg)
    $start = $null
    $length = $null
    [ReadLine]::GetSelectionState([ref]$start, [ref]$length)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    # if there's no selection, these should be set to the cursor
    if ($start -lt 0) { $start = $cursor; $length = 0 }
    $end = $start + $length
    # Write-Host "`e[s`e[0;0H`e[32mStart:$start End:$end Length:$Length `e[u"

    # pretend that entire lines are selected
    if ($start -gt 0) {
        $start = $command.SubString(0, $start).LastIndexOf("`n") + 1
    }
    $end = $end + $command.SubString($end).IndexOf("`n")
    $length = $end - $start
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length `e[u"

    $lines = $command.SubString($start, $length)
    $count = ($lines -split "`n").Count
    # Write-Host "`e[s`e[3;0H`e[36m$lines`e[u"
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length Lines:$Count`e[u"
    [ReadLine]::Replace($start, $length, ($lines -replace "(?m)^", "    "))
    [ReadLine]::SetCursorPosition($start)
    [ReadLine]::SelectLine()

    if ($count -gt 1) {
        while (--$Count) {
            [ReadLine]::SelectForwardChar()
            [ReadLine]::SelectLine()
        }
    }
}

Set-PSReadLineKeyHandler "Alt+[" {
    param($key, $arg)
    $start = $null
    $length = $null
    [ReadLine]::GetSelectionState([ref]$start, [ref]$length)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    # if there's no selection, these should be set to the cursor
    if ($start -lt 0) { $start = $cursor; $length = 0 }
    $end = $start + $length
    # Write-Host "`e[s`e[0;0H`e[32mStart:$start End:$end Length:$Length `e[u"

    # pretend that entire lines are selected
    if ($start -gt 0) {
        $start = $command.SubString(0, $start).LastIndexOf("`n") + 1
    }
    $end = $end + $command.SubString($end).IndexOf("`n")
    $length = $end - $start
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length `e[u"

    $lines = $command.SubString($start, $length)
    $count = ($lines -split "`n").Count
    # Write-Host "`e[s`e[3;0H`e[36m$lines`e[u"
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length Lines:$Count`e[u"

    [ReadLine]::Replace($start, $length, ($lines -replace "(?m)^    ", ""))
    [ReadLine]::SetCursorPosition($start)
    [ReadLine]::SelectLine()

    if ($count -gt 1) {
        while (--$Count) {
            [ReadLine]::SelectForwardChar()
            [ReadLine]::SelectLine()
        }
    }
}

# Cycle through arguments on current line and select the text. This makes it easier to quickly change the argument if re-running a previously run command from the history
# or if using a psreadline predictor. You can also use a digit argument to specify which argument you want to select, i.e. Alt+1, Alt+a selects the first argument
# on the command line.
Set-PSReadLineKeyHandler -Key "Alt+k" {
    param($key, $arg)

    $tokens = $null
    $parseError = $null
    $ast = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseError, [ref]$cursor)

    $asts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
            $args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
        }, $true)

    if ($asts.Count -eq 0) {
        [ReadLine]::Ding()
        return
    }

    $nextAst = $null

    if ($null -ne $arg) {
        $nextAst = $asts[$arg - 1]
    } else {
        foreach ($ast in $asts) {
            if ($ast.Extent.StartOffset -ge $cursor) {
                $nextAst = $ast
                break
            }
        }

        if (!$nextAst) {
            $nextAst = $asts[0]
        }
    }

    $startOffsetAdjustment = 0
    $endOffsetAdjustment = 0

    if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
        $startOffsetAdjustment = 1
        $endOffsetAdjustment = 2
    }

    [ReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
    [ReadLine]::SetMark($null, $null)
    [ReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
} -Description "Select next argument in the command line (or use a digit to select by index)"

Set-PSReadLineKeyHandler -Key "Alt+j" {
    param($key)

    $tokens = $null
    $parseError = $null
    $ast = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseError, [ref]$cursor)

    $asts = @($ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
            $args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
        }, $true))
    [Array]::Reverse($asts)

    if ($asts.Count -eq 0) {
        [ReadLine]::Ding()
        return
    }

    $nextAst = $null
    foreach ($ast in $asts) {
        if ($ast.Extent.EndOffset -lt $cursor) {
            $nextAst = $ast
            break
        }
    }

    if (!$nextAst) {
        $nextAst = $asts[0]
    }

    $startOffsetAdjustment = 0
    $endOffsetAdjustment = 0

    if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
        $startOffsetAdjustment = 1
        $endOffsetAdjustment = 2
    }

    [ReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
    [ReadLine]::SetMark($null, $null)
    [ReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
} -Description "Select next argument in the command line (or use a digit to select by index)"

Set-PSReadLineOption -HistoryNoDuplicates:$false -MaximumHistoryCount 8kb


# this nonsense is temporary, just because I'm using a pre-release PSReadLine and I love it...
if ($PSVersionTable.PSVersion -ge "7.1") {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
} else {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
}
Set-PSReadLineOption -ContinuationPrompt "$(Text '&ColorSeparator; ')"

{{- if eq .chezmoi.username "LD\\joelbennett" -}}
# Write-Information "Detected LoanDepot"

# Gives you tab completion on -Component, -Environment, -Datacenter, -ComputerName, -Role parameters on all commands in the below modules.
# Beware the more modules you add to this list, the longer you powershell profile will take to set up.
Update-LDArgumentCompleter -ModuleName "LDXGet", "LDXSet", "LDNetworking", "LDF5", "LDServerManagement"

# You must regularly Update-LDModule...
# But not from inside VS Code, because when I open VS Code, I'm usually opening 3-6 at a time
if ($ENV:TERM_PROGRAM -ne "vscode") {
    # Write-Information "Detected not VS Code"

    $Now = Get-Date
    $LDUtilityManifest = Get-Module -List LDUtility | Get-Item | Select-Object -First 1
    $Age = ($Now - $LDUtilityManifest.LastWriteTime).TotalHours
    if ($Age -gt 12) {
        $LDUtilityManifest.LastWriteTime = $Now
        # Run this super frustrating update in a separate tab in windows terminal
        wt -w 0 --title "Update-LDModule" -p "Windows PowerShell" PowerShell -NonInteractive -Command Update-LDModule -Scope CurrentUser -Verbose
    }
    <#
    As a developer, I have full admin rights on my laptop...
    But our IT department still deploys GPO's that break things from time to time.
    So for breaking policies that can be removed in the registry, I just fix it.

    The Microsoft\FVE policy breaks Docker: https://github.com/docker/for-win/issues/1297

    The Microsoft\Edge and Google\Chrome policies force startup options
    #>
    $Roots = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        "HKLM:\SOFTWARE\Policies\Google\Chrome"
        "HKCU:\SOFTWARE\Policies\Microsoft\Edge"
        "HKCU:\SOFTWARE\Policies\Google\Chrome"
    )

    $Paths = $Roots | Where-Object { $_ | Test-Path }
    # If any of these policy folders exist, run PowerShell elevated to clean up
    if ($Paths) {
        Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile -NonInteractive -Command ""&{ Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE FDVDenyWriteAccess 0; Remove-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Edge','HKCU:\SOFTWARE\Policies\Microsoft\Edge','HKLM:\SOFTWARE\Policies\Google\Chrome','HKCU:\SOFTWARE\Policies\Google\Chrome' -Recurse -ErrorAction SilentlyContinue }"""
    }

    # Corporate keeps pinning things. They obviously don't understand the meaning of "User Pinned"
    Get-ChildItem "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\Taskbar" |
        Where-Object { $_.BaseName -notin "KeePass 2", "File Explorer", "Microsoft Teams", "Visual Studio Code - Insiders", "Outlook" } |
        ForEach-Object {
            Start-Process -FilePath $_.FullName -Verb "taskbarunpin" -ErrorAction SilentlyContinue
        }
}
# Make your life easier, set your deuterium path as a default
$PSDefaultParameterValues["*:DeuteriumPath"] = "$deut"
{{- end }}
# This allows you to just Import-LDAppSetting "PathToFile"  without having to explicitly add -DeuteriumPath $deut
# Note that wildcard means this globally affects ANY parameter to ANY script or cmdlet where the parameter is named "DeuteriumPath"

if ($host.Name -eq "Visual Studio Code Host") {
    # Write-Information "Detected VS Code"
    # This module and command are only useable in the "PowerShell Integrated Console" in VS Code
    Import-Module EditorServicesCommandSuite
    Import-EditorCommand -Module EditorServicesCommandSuite
}
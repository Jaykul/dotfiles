# For default elevated sessions, set the start location where it should be
if ($pwd.Path -eq "$Env:SystemRoot\System32") {
    {{ if eq .chezmoi.username "LD\\joelbennett" -}}
    Set-Location $ldx
    {{- else -}}
    Set-Location $ProfileDir
    {{- end }}
}

# Note these are dependencies of the Profile module, but it's faster to load them explicitly up front
$DefaultModules = @(
    @{ ModuleName = "Microsoft.PowerShell.Management"; ModuleVersion = "3.1.0" }
    @{ ModuleName = "Microsoft.PowerShell.Security"; ModuleVersion = "3.0.0" }
    @{ ModuleName = "Microsoft.PowerShell.Utility"; ModuleVersion = "3.1.0" }
    @{ ModuleName = "Configuration"; ModuleVersion = "1.4.0" }
    @{ ModuleName = "Pansies"; ModuleVersion = "2.1.0" }

    if ($Env:WT_SESSION) {
        @{ ModuleName = "EzTheme"; ModuleVersion = "0.0.1" }
        @{ ModuleName = "Theme.PowerShell"; ModuleVersion = "0.0.1" }
        @{ ModuleName = "Theme.PSReadline"; ModuleVersion = "0.0.1" }
        @{ ModuleName = "Theme.Terminal"; ModuleVersion = "0.0.1" }
    } else {
        @{ ModuleName = "EzTheme"; ModuleVersion = "0.0.1" }
        @{ ModuleName = "Theme.PowerShell"; ModuleVersion = "0.0.1" }
        @{ ModuleName = "Theme.PSReadline"; ModuleVersion = "0.0.1" }
    }

    @{ ModuleName = "Environment"; RequiredVersion = "1.1.0" }
    @{ ModuleName = "posh-git"; ModuleVersion = "1.0.0" }
    @{ ModuleName = "PowerLine"; ModuleVersion = "3.3.0" }
    # @{ ModuleName="PSReadLine";       ModuleVersion="2.1.0" }

    @{ ModuleName = "DefaultParameter"; RequiredVersion = "2.0.0" }
    @{ ModuleName = "ErrorView"; RequiredVersion = "0.0.2" }
    @{ ModuleName = "zLocation"; ModuleVersion = "1.4.3" }
    # @{ ModuleName = "Profile"; ModuleVersion = "1.3.0" }
    {{ if eq .chezmoi.username "LD\\joelbennett" -}}
    @{ ModuleName = "LDOther"; ModuleVersion = "0.5.0" }
    @{ ModuleName = "LDUtility"; ModuleVersion = "5.7.1" }
    @{ ModuleName = "LDXGet"; ModuleVersion = "6.0.4" }
    {{- end }}
)

Import-Module -FullyQualifiedName $DefaultModules -Scope Global

if (Test-Elevation) {
    Import-Theme Lightly -IncludeModule Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, PowerLine
} elseif ($PSVersionTable.PSVersion.Major -le 5) {
    Import-Theme PS5
} else {
    Import-Theme Darkly -IncludeModule Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, PowerLine
}

$global:GitPromptSettings = New-GitPromptSettings
$global:GitPromptSettings.BeforeStatus = ''
$global:GitPromptSettings.AfterStatus = ''
$global:GitPromptSettings.PathStatusSeparator = ''
$global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
$global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"

# Now that we've imported PowerLine, we can call the NEW prompt function:
Write-PowerlinePrompt

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

$ReadLine = [Microsoft.PowerShell.PSConsoleReadLine]

Set-PSReadLineKeyHandler -Key Alt+w {
    param($key, $arg)

    $line = $null
    $cursor = $null
    $ReadLine::GetBufferState([ref]$line, [ref]$cursor)
    $ReadLine::AddToHistory($line)
    $ReadLine::RevertLine()
} -Description "Save current line in history but do not execute"

Set-PSReadLineKeyHandler '(', '{', '[' {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar) {
        '(' { [char]')'; break }
        '{' { [char]'}'; break }
        '[' { [char]']'; break }
    }

    $start = $null
    $length = $null
    $ReadLine::GetSelectionState([ref]$start, [ref]$length)

    $command = $null
    $cursor = $null
    $ReadLine::GetBufferState([ref]$command, [ref]$cursor)

    if ($start -ne -1) {
        # Text is selected, wrap it in brackets
        $ReadLine::Replace($start, $length, $key.KeyChar + $command.SubString($start, $length) + $closeChar)
        $ReadLine::SetCursorPosition($start + $length + 2)
    } elseif ($cursor -eq 0 -and $command.length) {
        # Cursor's at the start of the command, wrap the whole command
        $ReadLine::Replace(0, $command.length, $key.KeyChar + $command + $closeChar)
        $ReadLine::SetCursorPosition($command.length + 2)
    } else {
        # Otherwise, do a matching pair
        $ReadLine::Insert("$($key.KeyChar)$closeChar")
        $ReadLine::SetCursorPosition($cursor + 1)
    }
} -Description "Insert matching braces"


Set-PSReadLineKeyHandler ')', ']', '}' {
    param($key, $arg)

    $line = $null
    $cursor = $null
    $ReadLine::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar) {
        $ReadLine::SetCursorPosition($cursor + 1)
    } else {
        $ReadLine::Insert("$($key.KeyChar)")
    }
} -Description "Insert closing brace or skip"

Set-PSReadLineKeyHandler Backspace {
    param($key, $arg)

    $line = $null
    $cursor = $null
    $ReadLine::GetBufferState([ref]$line, [ref]$cursor)

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
            $ReadLine::Delete($cursor - 1, 2)
        } else {
            $ReadLine::BackwardDeleteChar($key, $arg)
        }
    }
} -Description "Delete smart quotes/parens/braces"

# Cycle through arguments on current line and select the text. This makes it easier to quickly change the argument if re-running a previously run command from the history
# or if using a psreadline predictor. You can also use a digit argument to specify which argument you want to select, i.e. Alt+1, Alt+a selects the first argument
# on the command line.
Set-PSReadLineKeyHandler -Key Alt+a {
    param($key, $arg)

    $ast = $null
    $cursor = $null
    $ReadLine::GetBufferState([ref]$ast, [ref]$null, [ref]$null, [ref]$cursor)

    $asts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
            $args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
        }, $true)

    if ($asts.Count -eq 0) {
        $ReadLine::Ding()
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

    $ReadLine::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
    $ReadLine::SetMark($null, $null)
    $ReadLine::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
} -Description "Select next argument in the command line (or use a digit to select by index)"


Set-PSReadLineOption -HistoryNoDuplicates:$false -MaximumHistoryCount 8kb

# this nonsense is temporary, just because I'm using a pre-release PSReadLine and I love it...
if ((Get-Module PSReadLine).Version -ge "2.2") {
    if ($PSVersionTable.PSVersion -ge "7.1") {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
    } else {
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
    }
} else {
    Set-PSReadLineOption -PredictionSource History
}
Set-PSReadLineOption -ContinuationPrompt "$(Text '&ColorSeparator; ')"

{{- if eq .chezmoi.username "LD\\joelbennett" -}}
# Gives you tab completion on -Component, -Environment, -Datacenter, -ComputerName, -Role parameters on all commands in the below modules.
# Beware the more modules you add to this list, the longer you powershell profile will take to set up.
Update-LDArgumentCompleter -ModuleName "LDXGet", "LDXSet", "LDNetworking", "LDF5", "LDServerManagement"

# You must regularly Update-LDModule...
# But not from inside VS Code, because when I open VS Code, I'm usually opening 3-6 at a time
if ($ENV:TERM_PROGRAM -ne "vscode") {
    $Now = Get-Date
    $LDUtilityManifest = Get-Module -List LDUtility | Get-Item | Select-Object -First 1
    $Age = ($Now - $LDUtilityManifest.LastWriteTime).TotalHours
    if ($Age -gt 12) {
        Update-LDModule -Scope CurrentUser -Clean -Verbose
        $LDUtilityManifest.LastWriteTime = $Now
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
}
# Make your life easier, set your deuterium path as a default
$PSDefaultParameterValues["*:DeuteriumPath"] = "$deut"
{{- end }}
# This allows you to just Import-LDAppSetting "PathToFile"  without having to explicitly add -DeuteriumPath $deut
# Note that wildcard means this globally affects ANY parameter to ANY script or cmdlet where the parameter is named "DeuteriumPath"

if ($host.Name -eq "Visual Studio Code Host") {
    # This module and command are only useable in the "PowerShell Integrated Console" in VS Code
    Import-Module EditorServicesCommandSuite
    Import-EditorCommand -Module EditorServicesCommandSuite
}
# Note these are dependencies of the Profile module, but it's faster to load them explicitly up front
$DefaultModules = @(
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
$Now = Get-Date
$LDUtilityManifest = Get-Module -List LDUtility | Get-Item | Select-Object -First 1
$Age = ($Now - $LDUtilityManifest.LastWriteTime).TotalHours
if ($Age -gt 12) {
    Update-LDModule -Scope CurrentUser -Clean -Verbose
    $LDUtilityManifest.LastWriteTime = $Now
}

function Clear-Policy {
    <#
        .SYNOPSIS
            Run PowerShell elevated to delete policy nodes from the registry
        .DESCRIPTION
            As a developer, I have full admin rights on my laptop, but GPO's still break things from time to time.
            Since most of the policies can be removed in the registry, I'm adding my removal of those things here.

            The Microsoft\FVE policy breaks Docker: https://github.com/docker/for-win/issues/1297

            The Microsoft\Edge and Google\Chrome policies at loanDepot
            - Made my new tab require authentication
            - Removed my ability to reopen previous tabs when I restart my browser
    #>
    [Alias("clap")]
    [CmdletBinding()]
    param(
        [string[]]$Policies = @("Microsoft\Edge", "Google\Chrome", "Microsoft\FVE")
    )
    begin {
        $Roots = "HKLM:\SOFTWARE\Policies\", "HKCU:\SOFTWARE\Policies\", "HKLM:\SYSTEM\CurrentControlSet\Policies"
    }
    process {
        $Paths = foreach($Policy in $Policies) {
            $Roots | Join-Path -ChildPath $Policy | Where-Object { $_ | Test-Path}
        }
        # If any of these policy folders exist, run PowerShell elevated to remove them
        if ($Paths) {
            Start-Process pwsh -Verb RunAs -ArgumentList "-Command ""&{Remove-Item '$($Paths -join "','")' -Recurse -ErrorAction SilentlyContinue -Confirm}"""
        }
    }
}

# Make your life easier, set your deuterium path as a default
$PSDefaultParameterValues["*:DeuteriumPath"] = "$deut"
{{- end }}
# This allows you to just Import-LDAppSetting "PathToFile"  without having to explicitly add -DeuteriumPath $deut
# Note that wildcard means this globally affects ANY parameter to ANY script or cmdlet where the parameter is named "DeuteriumPath"

if ($host.Name -eq "Visual Studio Code Host") {
    # This module and command are only useable in VS Code
    Import-Module EditorServicesCommandSuite
    Import-EditorCommand -Module EditorServicesCommandSuite

    # # in VS Code, you probably want your terminal to start in the project directory
    # if ($psEditor.Workspace.Path) {
    #     Set-Location ([Uri]$psEditor.Workspace.Path).AbsolutePath
    # }
}

if ($pwd.Path -eq "$Env:SystemRoot\System32") {
    {{ if eq .chezmoi.username "LD\\joelbennett" -}}
    Set-Location $ldx
    {{- else -}}
    Set-Location $ProfileDir
    {{- end }}
}
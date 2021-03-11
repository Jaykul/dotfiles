trap { Write-Warning ($_.ScriptStackTrace | Out-String) }
$ProfileDir = Split-Path $Profile.CurrentUserAllHosts
{{ if eq .chezmoi.username "LD\\joelbennett" -}}
# Shortcuts for paths that you will use a lot.
$ldx = "C:\ldx"

# LD Teammates WILL use these variables in scripts they put in confluence:
$dscripts = "$ldx\DevOpsScripts"
$toolkit = "$dscripts\Toolkit"
$deut = "$ldx\Deuterium"
$chamber = "$deut\chamber"
{{- end -}}

# PART 1: Fix the PSModulePath
function Select-UniquePath {
    #
    #    .SYNOPSIS
    #        Select-UniquePath normalizes path variables and ensures only folders that actually currently exist are in them.
    #    .EXAMPLE
    #        $ENV:PATH = $ENV:PATH | Select-UniquePath
    #
    [CmdletBinding()]
    param(
        # Paths to folders
        [Parameter(Position = 1, Mandatory = $true, ValueFromRemainingArguments = $true, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path,

        # If set, output the path(s) as an array of paths
        # Otherwise output joined by -Delimiter
        [switch]$AsArray,

        # The Path value is split by the delimiter. Defaults to '[IO.Path]::PathSeparator' so you can use this on $Env:Path
        [Parameter(Mandatory = $False)]
        [AllowNull()]
        [string]$Delimiter = [IO.Path]::PathSeparator
    )
    begin {
        # Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Enter"
        [string[]]$Output = @()
        [string[]]$oldFolders = @()
        $CaseInsensitive = $false -notin (Test-Path $ProfileDir.ToLowerInvariant(), $ProfileDir.ToUpperInvariant())
    }
    process {
        $Output += $(
            # Split and trim trailing slashes to normalize, and drop empty strings
            $oldFolders += $folders = $Path -split $Delimiter -replace '[\\\/]$' -gt ""

            # Remove duplicates that are only different by case on FileSystems that are not case-sensitive
            if ($CaseInsensitive) {
                # Converting a path with wildcards forces Windows to calculate the ACTUAL case of the path
                $folders -replace '(?<!:|\\|/|\*)(\\|/|$)', '*$1'
            } else {
                $folders
            }
        )
    }
    end {
        # Use Get-Item -Force to ensure we don't loose hidden folders
        # This won't work: Convert-Path C:\programdata*
        # But make sure we didn't add anything that wasn't already there
        [string[]]$Output = (Get-Item $Output -Force).FullName | Where-Object { $_ -iin $oldFolders }

        if ((-not $AsArray) -and $Delimiter) {
            # This is just faster than Select-Object -Unique
            [System.Linq.Enumerable]::Distinct($Output) -join $Delimiter
        } else {
            [System.Linq.Enumerable]::Distinct($Output)
        }
        # Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Exit"
    }
}

# NOTES:
# 1. The main concern is to keep things in order:
#     a. User path ($Home) before machine path ($PSHome)
#     b. Existing PSModulePath before other versions
#     c. current version before other versions
# 2. I don't worry about duplicates because `Select-UniquePath` takes care of it
# 3. I don't worry about missing paths, because `Select-UniquePath` takes care of it
# 4. I don't worry about x86 because I never use it.
# 5. I don't worry about linux because I add paths based on `$PSScriptRoot`, `$Profile` and `$PSHome`
$Env:PSModulePath =
    # The normal first location in PSModulePath is the "Modules" folder next to the real profile:
    @(Join-Path $ProfileDir Modules) +
    # After that, whatever is in the environment variable
    @($Env:PSModulePath) +
    # PSHome is where powershell.exe or pwsh.exe lives ... it should already be in the Env:PSModulePath, but just in case:
    @(Join-Path $PSHome Modules) +
    # FINALLY, add the Module paths for other PowerShell versions, because I'm an optimist
    @(Join-Path (Split-Path (Split-Path $PSHome)) *PowerShell\ | Convert-Path | Get-ChildItem -Filter Modules -Directory -Recurse -Depth 2).FullName +
    @(Convert-Path @(
            Split-Path $ProfileDir | Join-Path -ChildPath *PowerShell\Modules
            # These may be duplicate or not exist, but it doesn't matter
            "$Env:ProgramFiles\*PowerShell\Modules"
            "$Env:ProgramFiles\*PowerShell\*\Modules"
            "$Env:SystemRoot\System32\*PowerShell\*\Modules"
        )) +
    # Guarantee my ~\Projects\Modules are there so I can load my dev projects
    @("$Home\Projects\Modules") +
    # To ensure canonical path case, wildcard every path separator and then convert-path
    @() | Select-UniquePath

    # I want to make sure that THIS version's Scripts (and then other versions) path is in the PATH
    $Env:Path = @($Env:Path) + @(Join-Path $ProfileDir Scripts) +
    @(Join-Path (Split-Path $ProfileDir) *PowerShell | Convert-Path | Get-ChildItem -Filter Scripts -Directory).FullName +
    @() | Select-UniquePath

# PART 2. Fix default values
# PSReadLine is usually pre-loaded if it can be
if (Get-Module PSReadline) {
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
}

# PART 3. Import other modules
#   For now, we're not going to import all these very useful modules, because it takes too long
#   Instead we list the modules that would be imported and define Import-DefaultModule to import them

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

function Import-DefaultModule {
    [Alias("def")]
    [CmdletBinding()]
    param(
        [switch]$Clear
    )
    Import-Module -FullyQualifiedName $DefaultModules -Scope Global

    if (Test-Elevation) {
        Import-Theme Lightly -IncludeModule Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, PowerLine
    } elseif ($PSVersionTable.PSVersion.Major -le 5) {
        Import-Theme PS5
    } else {
        Import-Theme Darkly -IncludeModule Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, PowerLine
    }
    function global:Reset-Prompt {
        Set-PowerLinePrompt -Prompt @(
            # This requires my PoshCode/PSGit module and the use of the SamplePSGitConfiguration
            { $MyInvocation.HistoryId }
            { "&Gear;" * $NestedPromptLevel }
            { if ($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } }
            { Write-VcsStatus }
            { Get-SegmentedPath }
            { "`t" } # Now split and right-justify
            { New-PromptText (Get-Elapsed) -ErrorBackgroundColor VioletRed4 -ErrorForegroundColor White }
            { Get-Date -f "T" }
            { "`n" }
            { New-PowerLineBlock "I ${fg:DodgerBlue3}&hearts;${fg:Black} PS" -Bg SkyBlue -Fg Black }
        ) -SetCurrentDirectory -PowerLineFont -Colors "Gray20", "Gray54" -Title {
            @(
                if (Test-Elevation) { [char]0xf132 }
                if ($GitStatus) {"$($GitStatus.RepoName) [$($GitStatus.Branch)]"} else {Get-ShortenedPath}
                "PS$($PSVersionTable.PSVersion.ToString(2)) (pid $PID)"
                if ([IntPtr]::Size -eq 4) {"32-bit"}
            ) -join " "
        }

        Set-PSReadLineOption -PromptText @(
            "$([char]27)[30m$([char]27)[48;2;135;206;235mI $([char]27)[38;2;24;116;205m♥$([char]27)[30m PS$([char]27)[49m$([char]27)[38;2;135;206;235m"
            "$([char]27)[30m$([char]27)[48;2;135;206;235mI $([char]27)[38;2;208;32;144m♥$([char]27)[30m PS$([char]27)[49m$([char]27)[38;2;135;206;235m"
        )

        $global:GitPromptSettings = New-GitPromptSettings
        $global:GitPromptSettings.BeforeStatus = ''
        $global:GitPromptSettings.AfterStatus = ''
    }

    $global:GitPromptSettings = New-GitPromptSettings
    $global:GitPromptSettings.BeforeStatus = ''
    $global:GitPromptSettings.AfterStatus = ''
    $global:GitPromptSettings.PathStatusSeparator = ''
    $global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
    $global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"

    Set-PSReadLineOption -ContinuationPrompt "$(Text '&ColorSeparator; ')"

    if ($Clear) { Clear-Host }

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
    {{- end }}
}

{{- if eq .chezmoi.username "LD\\joelbennett" -}}
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
    Set-Location $ProfileDir
    {{- if eq .chezmoi.username "LD\\joelbennett" -}}
    if ($ldx) {
        Set-Location $ldx
    }
    {{- end }}
}
trap { Write-Warning ($_.ScriptStackTrace | Out-String) }
# $InformationPreference = "Continue"
# I wish $Profile was in $Home, but since it's not:
$ProfileDir = $PSScriptRoot
$IsVSCode = $ENV:TERM_PROGRAM -eq "vscode"

# The XDG standard says use the variable and tells us how to calculate a fallback
# Dotnet Core uses the XDG standard for these so we can use that.
# ConfigHome $ENV:XDG_CONFIG_HOME  $HOME/.config       AppData/Roaming # profile and settings
# DataHome   $ENV:XDG_DATA_HOME    $HOME/.local/share  AppData/Local   # scripts and modules

$ConfigHome = [Environment]::GetFolderPath("ApplicationData")
$DataHome = [Environment]::GetFolderPath("LocalApplicationData")

# I can run `Update-PSModulePath` any time, but I don't by default
Set-Alias Update-PSModulePath $DataHome/powershell/Scripts/Update-PSModulePath.ps1
# I just read the cached values from the last run
if (Test-Path ($PSModulePathPath = [IO.Path]::ChangeExtension($Profile, "$Env:PSModulePath_Before"))) {
    $Env:PSModulePath_Before = $Env:PSModulePath
    $Env:PSModulePath = @(Get-Content $PSModulePathPath) -join [IO.Path]::PathSeparator
}
if (Test-Path ($PathPath = [IO.Path]::ChangeExtension($Profile, ".Path.env"))) {
    $Env:Path_Before = $Env:Path
    $Env:Path = @(Get-Content $PathPath) -join [IO.Path]::PathSeparator
} else {
    Update-PSModulePath
}

{{ if eq .chezmoi.username "LD\\joelbennett" -}}
# Shortcuts for paths that you will use a lot.
# LD Teammates WILL use these variables in scripts they put in confluence:
$LDDefaultJiraProject   = "DOH"
$LDSource   = $LDx      = "C:\ldx"
$LDScripts  = $dscripts = "$ldx\DevOpsScripts"
$LDToolkit  = $toolkit  = "$dscripts\Toolkit"
$LDDeut     = $deut     = "$ldx\Deuterium"
$LDChamber  = $chamber  = "$deut\chamber"
{{ end -}}

$Interactive = Convert-Path "$DataHome/powershell/Scripts/Initialize-Interactive.ps1"

if (!$Env:WARP_IS_LOCAL_SHELL_SESSION) {
    if ($IsVSCode -or $Host.UI.RawUI.KeyAvailable) {
        $Controlled = $false
        while ($Host.UI.RawUI.KeyAvailable -and ($key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp"))) {
            if (!$Controlled -and $key.ControlKeyState -match "LeftCtrlPressed") {
                $Controlled = $true
            }
        }
        if ($IsVSCode -or $Controlled) {
            Write-Host "Skipping Interactive Config. To complete, run:`n. `"$Interactive`"" -ForegroundColor Yellow
            if ($PSVersionTable.PSVersion.Major -gt 5) {
                function prompt { "`e[36m$($MyInvocation.HistoryId)`e[37m $pwd`e[0m`n❯" }
            } else {
                function prompt { "$([char]27)[36m$($MyInvocation.HistoryId)$([char]27)[37m $pwd$([char]27)[0m`n$([char]0x276f)" }
            }
            return
        }
    }

    # PART 3. Things we only need in interactive sessions
    #   For performance reasons, I don't want to do all of this work when I'm running automated scripts
    function prompt {
        Write-Host "Preparing interactive session for first use..." -ForegroundColor Cyan
        . $Interactive
        # $InformationPreference = "SilentlyContinue"
    }
} else {
    . $Interactive
}
trap { Write-Warning ($_.ScriptStackTrace | Out-String) }
# $InformationPreference = "Continue"
# I wish $Profile was in $Home, but since it's not:
$ProfileDir = $PSScriptRoot

# I can run `Update-PSModulePath` any time, but I don't by default
Set-Alias Update-PSModulePath $ProfileDir\Update-PSModulePath.ps1
# I just read the cached values from the last run
if (Test-Path ($PSModulePathPath = [IO.Path]::ChangeExtension($Profile, ".PSModulePath.env"))) {
    $Env:PSModulePath = @(Get-Content $PSModulePathPath) -join [IO.Path]::PathSeparator
}
if (Test-Path ($PathPath = [IO.Path]::ChangeExtension($Profile, ".Path.env"))) {
    $Env:Path = @(Get-Content $PathPath) -join [IO.Path]::PathSeparator
}

{{ if eq .chezmoi.username "LD\\joelbennett" -}}
# Shortcuts for paths that you will use a lot.
# LD Teammates WILL use these variables in scripts they put in confluence:
$ldx = "C:\ldx"
$dscripts = "$ldx\DevOpsScripts"
$toolkit = "$dscripts\Toolkit"
$deut = "$ldx\Deuterium"
$chamber = "$deut\chamber"
{{ end -}}


if ($Host.UI.RawUI.KeyAvailable) {
    $Controlled = $false
    while ($Host.UI.RawUI.KeyAvailable -and ($key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp"))) {
        if (!$Controlled -and $key.ControlKeyState -match "LeftCtrlPressed") {
            $Controlled = $true
        }
    }
    if ($Controlled) {
        Write-Warning "CTRL: Skipping Interactive Config. To complete, run:`n. `$ProfileDir\interactive.ps1"
        function prompt { "$([char]27)[36m$($MyInvocation.HistoryId)$([char]27)[37m $pwd$([char]27)[0m`n❯" }
        return
    }
}

# PART 3. Things we only need in interactive sessions
#   For performance reasons, I don't want to do all of this work when I'm running automated scripts
function prompt {
    & "$ProfileDir\interactive.ps1"
    # $InformationPreference = "SilentlyContinue"
}
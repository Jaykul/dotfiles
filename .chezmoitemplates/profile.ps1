trap { Write-Warning ($_.ScriptStackTrace | Out-String) }
$ProfileDir = [IO.Path]::GetDirectoryName($Profile.CurrentUserAllHosts)
{{ if eq .chezmoi.username "LD\\joelbennett" -}}
# Shortcuts for paths that you will use a lot.
# LD Teammates WILL use these variables in scripts they put in confluence:
$ldx = "C:\ldx"
$dscripts = "$ldx\DevOpsScripts"
$toolkit = "$dscripts\Toolkit"
$deut = "$ldx\Deuterium"
$chamber = "$deut\chamber"
{{ end -}}
$Now = [DateTime]::Now


# Sometimes ... set the PSModulePath correctly for _this_ shell.
# You can run `Update-PSModulePath` any time.
Set-Alias Update-PSModulePath $PSScriptRoot\Update-PSModulePath.ps1
$PSModulePathFile = [IO.Path]::ChangeExtension($Profile.CurrentUserCurrentHost, ".PSModulePath.env")
# But if it's been more than a day, we'll run it now, just to be sure
if (24 -lt ($Now - (Get-Item $PSModulePathFile).LastWriteTime).TotalHours) {
    Update-PSModulePath $PSModulePathFile
} else {
    $Env:PSModulePath = @(Get-Content $PSModulePathFile) -join ([IO.Path]::PathSeparator)
}

# PART 3. Things we only need in interactive sessions
#   For performance reasons, I don't want to do all of this work when I'm running automated scripts
function prompt { & "$ProfileDir\interactive.ps1" }
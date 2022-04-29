trap { Write-Warning ($_.ScriptStackTrace | Out-String) }
# Calculate a couple of
$ProfileDir = [IO.Path]::GetDirectoryName($Profile)
$PSModulePathFile = [IO.Path]::ChangeExtension($Profile, ".PSModulePath.env")

# You can run `Update-PSModulePath` any time.
Set-Alias Update-PSModulePath $PSScriptRoot\Update-PSModulePath.ps1

# But if it's been more than a week, we'll run it now, just to be sure
$Before = (Get-Item $PSModulePathFile -ErrorAction Ignore).LastWriteTime
if (-not $Before -or (24 * 7) -lt ([DateTime]::Now - $Before).TotalHours) {
    Update-PSModulePath $PSModulePathFile -ProfileDir $ProfileDir
} else {
    $Env:PSModulePath = @(Get-Content $PSModulePathFile) -join [IO.Path]::PathSeparator

    $Env:Path += @('') + [Linq.Enumerable]::Distinct([string[]]@(
        @([IO.Path]::Combine($ProfileDir, "Scripts")) +
        @(Get-ChildItem ([IO.Path]::Combine([IO.Path]::GetDirectoryName($ProfileDir), "*PowerShell\*")) -Filter Scripts -Directory).FullName
    )) -join [IO.Path]::PathSeparator
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

# PART 3. Things we only need in interactive sessions
#   For performance reasons, I don't want to do all of this work when I'm running automated scripts
function prompt { & "$ProfileDir\interactive.ps1" }
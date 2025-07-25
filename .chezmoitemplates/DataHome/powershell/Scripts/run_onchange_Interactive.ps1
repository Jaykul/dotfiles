#!/usr/bin/env pwsh
# This script needs to install modules whenever I change the Initialize-Interactive script
# profile hash: {{ include ".chezmoitemplates/DataHome/powershell/Scripts/Initialize-Interactive.ps1" | sha256sum }}
$ErrorView = 'DetailedView'

# It's time to switch to the DataHome AppData/Local location
$Destination = "$DataHome/powershell/Modules"

{{ template "DefaultModules.ps1" . }}

# Rewrite RequiredModules for ModuleFast instead
$RequiredModules = $DefaultModules | ForEach-Object {
    # A hack, these modules need to be imported, but are built-in, not on the gallery:
    if ($_.ModuleName -notin @(
        'Microsoft.PowerShell.Management'
        'Microsoft.PowerShell.Security'
        'Microsoft.PowerShell.Utility'
    )) {
        if ($_.ModuleVersion) {
            $_.ModuleName + ">=" + $_.ModuleVersion
        } else {
            $_.ModuleName + "=" + $_.RequiredVersion
        }
    }
}
Write-Warning "Pre-installing $($RequiredModules.Count) modules: $($RequiredModules -join ', ')"

# Bootstrap ModuleFast if it's not already installed
if (!(Get-Module ModuleFast -ListAvailable -ErrorAction SilentlyContinue)) {
    # $PSModulePaths = @("PSModulePaths:") + $env:PSModulePath.Split([IO.Path]::PathSeparator, [StringSplitOptions]::RemoveEmptyEntries)
    # Write-Verbose $($PSModulePaths -join "`n  $($PSStyle.Formatting.Verbose)") -Verbose

    Write-Verbose "ModuleFast not found. Installing to $($ModuleFastParam.Destination)" -Verbose
    # This is on github's head because they ALWAYS redirect releases/latest, but they throttle the releases/latest API
    $Response = Invoke-WebRequest https://github.com/JustinGrote/ModuleFast/releases/latest
    $Version = (Split-Path $Response.Headers.Location -Leaf).TrimStart("v")
    $File = "ModuleFast.$Version.zip"
    $Url = "https://github.com/JustinGrote/ModuleFast/releases/download/v$Version/$File"
    Write-Verbose "Installing $File from $Url" -Verbose
    Invoke-WebRequest $Url -OutFile $File
    Expand-Archive $File -DestinationPath $Destination
    Remove-Item $File
}

# Since these scripts _may_ not already be installed:
if (-not (Get-Command Install-GithubRelease -ErrorAction SilentlyContinue)) {
    $Script = Install-Script -Name Install-GithubRelease -Scope CurrentUser -Force -PassThru -WarningAction SilentlyContinue -ReInstall
    if ($Env:PATH -split [IO.Path]::PathSeparator -notcontains $Script.InstalledLocation) {
        $ENV:PATH += ([IO.Path]::PathSeparator) + (Convert-Path $Script.InstalledLocation)
    }
}
# https://github.com/PowerShell/PSResourceGet/issues/1448
Install-ModuleFast $RequiredModules -Destination $Destination -Update -Prerelease -NoProfileUpdate
# I probably have tools I should be auto-upgrading, but Install-GithubRelease should track versions so I don't reinstall them unnecessarily
Install-GithubRelease rsteube carapace-bin

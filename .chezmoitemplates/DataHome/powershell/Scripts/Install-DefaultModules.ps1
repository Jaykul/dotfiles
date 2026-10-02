#!/usr/bin/env pwsh
$ErrorView = 'DetailedView'

# It's time to switch to the DataHome AppData/Local location
$DataHome = [Environment]::GetFolderPath("LocalApplicationData")
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


# If ModuleFast is not already installed, install it to $Destination
if (!(Get-Module ModuleFast -ListAvailable -ErrorAction SilentlyContinue)) {
    Write-Verbose "ModuleFast not found. Installing to $($Destination)" -Verbose
    # When we get redirected beyond our limit, IWR throws
    [string]$Location = try {
        # Github redirects releases/latest, but throttles their API
        Invoke-WebRequest https://github.com/JustinGrote/ModuleFast/releases/latest -UseBasicParsing -MaximumRedirection 0
        "https://github.com/JustinGrote/ModuleFast/releases/tag/v0.6.0"
    } catch {
        $_.Exception.Response.Headers.location
    }
    $tag = Split-Path $Location -Leaf
    $version = $tag.Trim("v")
    $file = "ModuleFast.$version.zip"
    $url = "https://github.com/JustinGrote/ModuleFast/releases/download/$tag/$file"
    Write-Verbose "Installing $file from $url" -Verbose
    Invoke-WebRequest $url -OutFile $file
    Expand-Archive $file -DestinationPath $Destination
    Remove-Item $file
}

# Since these scripts _may_ not already be installed:
if (-not (Get-Command Install-GithubRelease -ErrorAction SilentlyContinue)) {
    $Script = Install-Script -Name Install-GithubRelease -Scope CurrentUser -Force -PassThru -WarningAction SilentlyContinue
    if ($Env:PATH -split [IO.Path]::PathSeparator -notcontains $Script.InstalledLocation) {
        $ENV:PATH += ([IO.Path]::PathSeparator) + (Convert-Path $Script.InstalledLocation)
    }
}
# https://github.com/PowerShell/PSResourceGet/issues/1448
Install-ModuleFast $RequiredModules -Destination $Destination -Update -Prerelease -NoProfileUpdate
# I probably have tools I should be auto-upgrading, but Install-GithubRelease should track versions so I don't reinstall them unnecessarily
Install-GithubRelease rsteube carapace-bin

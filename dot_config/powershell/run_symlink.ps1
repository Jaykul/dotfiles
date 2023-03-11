#!/usr/bin/env pwsh
Install-Module PowerShellGet -AllowPrerelease -Force
Set-PSResourceRepository -Name PSGallery -Trusted
Install-PSResource EzTheme, Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, Theme.PSStyle -Prerelease -WarningAction Ignore

# On Windows, I need an extra copy in the WindowsPowerShell folder
if ($Env:OneDriveCommercial) {
    Get-ChildItem profile.ps1 | ForEach-Object {
        # Put each file in both the WindowsPowerShell and PowerShell folders
        Copy-Item $_.FullName -Destination "$Env:OneDriveCommercial\Documents\PowerShell\$($_.Name)"
        Copy-Item $_.FullName -Destination "$Env:OneDriveCommercial\Documents\WindowsPowerShell\$($_.Name)"
    }
}

if ($Profile.CurrentUserAllHosts -ne (Convert-Path profile.ps1)) {
    Copy-Item profile.ps1 $Profile.CurrentUserAllHosts
}
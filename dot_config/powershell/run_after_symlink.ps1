#!/usr/bin/env pwsh
# profile hash: {{ include "profile.ps1" | sha256sum }}
$ErrorView = 'DetailedView'

# On Windows, I need an extra copy in the WindowsPowerShell folder
if ($Env:OneDriveCommercial) {
    # Put the profile in the WindowsPowerShell and PowerShell folders
    Copy-Item profile.ps1 -Destination "$Env:OneDriveCommercial\Documents\PowerShell\profile.ps1"
    Copy-Item profile.ps1 -Destination "$Env:OneDriveCommercial\Documents\WindowsPowerShell\profile.ps1"
    Copy-Item profile.ps1 -Destination "$Env:OneDriveCommercial\Documents\PowerShell\Microsoft.dotnet-interactive_profile.ps1"
}

# Make sure the profile and config are in the right place
if ($Profile.CurrentUserAllHosts -ne (Convert-Path profile.ps1)) {
    Copy-Item profile.ps1 $Profile.CurrentUserAllHosts
    Copy-Item powershell.config.json -Destination "$Env:OneDriveCommercial\Documents\PowerShell\powershell.config.json"
}

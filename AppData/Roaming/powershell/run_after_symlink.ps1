#!/usr/bin/env pwsh
# profile hash: {{ include "profile.ps1" | sha256sum }}
$ErrorView = 'DetailedView'

# On Windows, I need an extra copy in the WindowsPowerShell folder
if ($Env:OneDriveCommercial) {
    # Put the profile in the WindowsPowerShell and PowerShell folders
    Copy-Item profile.ps1 -Destination "$Env:OneDriveCommercial\Documents\PowerShell\profile.ps1"
    Copy-Item profile.ps1 -Destination "$Env:OneDriveCommercial\Documents\WindowsPowerShell\profile.ps1"
    if (Test-Path "$Env:OneDriveCommercial\Documents\PowerShell\Microsoft.dotnet-interactive_profile.ps1") {
        Remove-Item "$Env:OneDriveCommercial\Documents\PowerShell\Microsoft.dotnet-interactive_profile.ps1"
    }

    # Make sure the profile and config are in the right place
    if ($Profile.CurrentUserAllHosts -ne (Convert-Path profile.ps1)) {
        Copy-Item profile.ps1 $Profile.CurrentUserAllHosts
        Copy-Item powershell.config.json -Destination "$Env:OneDriveCommercial\Documents\PowerShell\powershell.config.json"
    }

} elseif ($Env:OneDrive) {
    # Put the profile in the WindowsPowerShell and PowerShell folders
    Copy-Item profile.ps1 -Destination "$Env:OneDrive\Documents\PowerShell\profile.ps1"
    Copy-Item profile.ps1 -Destination "$Env:OneDrive\Documents\WindowsPowerShell\profile.ps1"
    if (Test-Path "$Env:OneDrive\Documents\PowerShell\Microsoft.dotnet-interactive_profile.ps1") {
        Remove-Item "$Env:OneDrive\Documents\PowerShell\Microsoft.dotnet-interactive_profile.ps1"
    }

    # Make sure the profile and config are in the right place
    if ($Profile.CurrentUserAllHosts -ne (Convert-Path profile.ps1)) {
        Copy-Item profile.ps1 $Profile.CurrentUserAllHosts
        Copy-Item powershell.config.json -Destination "$Env:OneDrive\Documents\PowerShell\powershell.config.json"
    }
}

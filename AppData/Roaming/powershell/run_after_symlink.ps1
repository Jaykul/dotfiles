#!/usr/bin/env pwsh
# profile hash: {{ include "profile.ps1" | sha256sum }}
$ErrorView = 'DetailedView'

if ($IsWindows) { # On Windows, I need an extra copy in the WindowsPowerShell folder
    $ProfileDir = Split-Path -Parent $Profile.CurrentUserAllHosts

    Copy-Item powershell.config.json -Destination $ProfileDir -Verbose
    Copy-Item profile.ps1 -Destination $ProfileDir -Verbose
    Copy-Item profile.ps1 -Destination ($ProfileDir -replace 'PowerShell$','WindowsPowerShell')
}
#!/usr/bin/env pwsh
# This script just cleans up the cache files whenever I change the Update-PSModulePath script
# profile hash: {{ include ".chezmoitemplates/DataHome/powershell/Scripts/Update-PSModulePath.ps1" | sha256sum }}
Remove-Item "*.PSModulePath.env"
Remove-Item "*.Path.env"
#!/usr/bin/env pwsh
# profile hash: {{ include "profile.ps1" | sha256sum }}
$ErrorView = 'DetailedView'

# Use the same stuff for non-Preview Terminal
Get-ChildItem | Copy-Item -Destination $Env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState
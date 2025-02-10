#!/usr/bin/env pwsh
# profile hash: {{ include "profile.ps1" | sha256sum }}
$ErrorView = 'DetailedView'

$NonPreviewLocalState = $Env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState
if (Test-Path $NonPreviewLocalState) {
    # Use the same stuff for non-Preview Terminal
    Get-ChildItem *.png, *.ico, *.avif, settings.json
    | Copy-Item -Destination $NonPreviewLocalState
}
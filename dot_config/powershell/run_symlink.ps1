Install-PSResource EzTheme, Theme.PowerShell, Theme.PSReadLine, Theme.Terminal, Theme.PSStyle -Prerelease
if ($Env:OneDriveCommercial) {
    # The script will run in the current directory
    # It won't be copied there, so we have to use PWD not PSScriptRoot
    Get-ChildItem $PWD\*.ps1 | ForEach-Object {
        # Put each file in both the WindowsPowerShell and PowerShell folders
        Copy-Item $_.FullName -Destination "$Env:OneDriveCommercial\Documents\PowerShell\$($_.Name)"
        Copy-Item $_.FullName -Destination "$Env:OneDriveCommercial\Documents\WindowsPowerShell\$($_.Name)"
    }
}
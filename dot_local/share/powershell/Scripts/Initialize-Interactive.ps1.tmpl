# We need to force encoding to UTF8 for PSReadLine to do the right thing with extended characters
# But we need to make sure it's UTF8-NoBOM
[Console]::OutputEncoding = [Console]::InputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()
$global:IsVSCode = $ENV:TERM_PROGRAM -eq "vscode"

# Just a handful of additional TypeAccelerators
$xlr8r = [psobject].assembly.gettype("System.Management.Automation.TypeAccelerators")
$Accelerate = @{
    ReadLine   = [Microsoft.PowerShell.PSConsoleReadLine]
    List       = [System.Collections.Generic.List``1]
    Dictionary = [System.Collections.Generic.Dictionary``2]
}
if ($xlr8r::AddReplace) {
    $Accelerate.GetEnumerator().ForEach({
        $xlr8r::AddReplace($_.Key, $_.Value)
    })
} else {
    $Accelerate.GetEnumerator().ForEach({
        $null = $xlr8r::Remove($_.Key)
        $xlr8r::Add($_.Key, $_.Value)
    })
}

# Write-Host "Checking PSModulePath.env"
# Once a week I want to update the PSModulePath, just in case
$Before = (Get-Item ($PSModulePathPath = [IO.Path]::ChangeExtension($Profile, ".PSModulePath.env")) -ErrorAction Ignore).LastWriteTime
if (-not $Before -or (24 * 7) -lt ([DateTime]::Now - $Before).TotalHours) {
    Update-PSModulePath $PSModulePathFile -ProfileDir $ProfileDir
}

# Write-Host "Setting Location."
# For default elevated sessions, set the start location where it should be
if ($pwd.Path -eq "$Env:SystemRoot\System32") {
    {{ if eq .chezmoi.username "LD\\joelbennett" -}}
    Set-Location $ldx
    {{- else -}}
    Set-Location $ProfileDir
    {{- end }}
}

if ($Env:WARP_IS_LOCAL_SHELL_SESSION) {
    function prompt { "`n`e[36m$($MyInvocation.HistoryId)❯" }
}

{{ template "DefaultModules.ps1" . }}
try {
    Import-Module -FullyQualifiedName $DefaultModules -Scope Global -ErrorAction Stop
} catch {
    Write-Warning "Failed to import default modules. Trying again, one at a time."
    foreach ($Module in $DefaultModules) {
        try {
            Import-Module -FullyQualifiedName $Module -Scope Global -ErrorAction Stop
        } catch {
            Write-Warning "Failed to import $($Module.ModuleName) module version $($Module.ModuleVersion) or higher.`n$($_ | Get-Error)."
        }
    }
}

# Write-Host "Importing Theme."
if ((Test-Elevation) -and (Get-Theme "$([Environment]::UserName)-Elevated")) {
    Import-Theme "$([Environment]::UserName)-Elevated"
} elseif (($PSVersionTable.PSVersion.Major -le 7) -and (Get-Theme "$([Environment]::UserName)-Legacy")) {
    Import-Theme "$([Environment]::UserName)-Legacy"
} elseif (Get-Theme "$([Environment]::UserName)") {
    Import-Theme "$([Environment]::UserName)"
} else {
    Import-Theme Darkly
}

if ($PSStyle.OutputRendering) {
    # Make sure PSStyle doesn't mess with our color!
    $PSStyle.OutputRendering = 'ansi'
}
[PoshCode.Pansies.RgbColor]::ColorMode = 'Rgb24Bit'


# Warp doesn't use PSReadLine or the PowerShell prompt
if (!$Env:WARP_IS_LOCAL_SHELL_SESSION) {
    $global:GitPromptSettings = New-GitPromptSettings
    $global:GitPromptSettings.BeforeStatus = ''
    $global:GitPromptSettings.AfterStatus = ''
    $global:GitPromptSettings.PathStatusSeparator = ''
    $global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
    $global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"

    . (Join-Path $PSScriptRoot Initialize-PSReadLine.ps1)

    # Now that we've imported PowerLine and configured Posh-Git we can call the NEW prompt function:
    Write-PowerlinePrompt
}

{{if eq .chezmoi.username "LD\\joelbennett" -}}
# Write-Host "Detected LoanDepot"

# Warp doesn't use tab completion (booo!)
if (!$Env:WARP_IS_LOCAL_SHELL_SESSION) {
    # Gives you tab completion on -Component, -Environment, -Datacenter, -ComputerName, -Role parameters on all commands in the below modules.
    # Beware the more modules you add to this list, the longer you powershell profile will take to set up.
    Update-LDArgumentCompleter -ModuleName "LDXGet", "LDXSet", "LDNetworking", "LDF5", "LDServerManagement"
}

# You must regularly Update-LDModule...
# But not from inside VS Code, because when I open VS Code, I'm usually opening 3-6 at a time
if (!$IsVSCode) {
    # Write-Host "Detected not VS Code"

    $Now = Get-Date
    $LDUtilityManifest = Get-Module -List LDUtility | Get-Item | Select-Object -First 1
    $Age = ($Now - $LDUtilityManifest.LastWriteTime).TotalHours
    if ($Age -gt 12) {
        $LDUtilityManifest.LastWriteTime = $Now
        # Run this super frustrating update in a separate tab in windows terminal
        wt -w 0 --title "Update-LDModule" -p "Windows PowerShell" PowerShell -NonInteractive -Command Update-LDModule -Scope CurrentUser -Verbose
    }
}

# Make your life easier, set your deuterium path as a default
$PSDefaultParameterValues["*:DeuteriumPath"] = "$deut"
{{- end }}

# The PowerShell Extension host is slightly different:
if ($IsVSCode -and $Host.Name -eq "Visual Studio Code Host") {
    # This module and command are only useable in the "PowerShell Integrated Console" in VS Code
    Import-Module EditorServicesCommandSuite
    Import-EditorCommand -Module EditorServicesCommandSuite
}
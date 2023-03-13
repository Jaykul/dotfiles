# Write-Information "Importing Default Modules."
# Note these are dependencies of the Profile module, but it's faster to load them explicitly up front
$DefaultModules = @(
    @{ ModuleName = "Microsoft.PowerShell.Management"; ModuleVersion = "3.1.0" }
    @{ ModuleName = "Microsoft.PowerShell.Security"; ModuleVersion = "3.0.0" }
    @{ ModuleName = "Microsoft.PowerShell.Utility"; ModuleVersion = "3.1.0" }
    @{ ModuleName = "Metadata"; ModuleVersion = "1.5.7" }
    @{ ModuleName = "Configuration"; ModuleVersion = "1.5.1" }
    @{ ModuleName = "Pansies"; ModuleVersion = "2.6.0" }
    @{ ModuleName = "TerminalBlocks"; ModuleVersion = "1.0.0" }
    @{ ModuleName = "PowerLine"; ModuleVersion = "4.0.0" }

    @{ ModuleName = "EzTheme"; ModuleVersion = "0.1.0" }
    @{ ModuleName = "Theme.PowerShell"; ModuleVersion = "0.1.0" }
    @{ ModuleName = "Theme.PSReadline"; ModuleVersion = "0.1.0" }
    if ($Env:WT_SESSION) {
        @{ ModuleName = "Theme.WindowsTerminal"; ModuleVersion = "0.1.0" }
    } else {
        @{ ModuleName = "Theme.Terminal"; ModuleVersion = "0.1.0" }
    }
    if ($PSStyle) {
        @{ ModuleName = "Theme.PSStyle"; ModuleVersion = "0.1.0" }
    }

    @{ ModuleName = "Environment"; RequiredVersion = "1.1.0" }
    @{ ModuleName = "posh-git"; ModuleVersion = "1.1.0" }
    @{ ModuleName = "PSReadLine"; ModuleVersion = "2.2.4" }

    @{ ModuleName = "DefaultParameter"; RequiredVersion = "2.0.0" }
    # @{ ModuleName = "ErrorView"; RequiredVersion = "0.0.2" }
    @{ ModuleName = "zLocation"; ModuleVersion = "1.4.3" }
    # @{ ModuleName = "Profile"; ModuleVersion = "1.3.0" }
    {{ if eq .chezmoi.username "LD\\joelbennett" -}}
    @{ ModuleName = "LDOther"; ModuleVersion = "0.5.0" }
    @{ ModuleName = "LDUtility"; ModuleVersion = "5.7.1" }
    @{ ModuleName = "LDXGet"; ModuleVersion = "6.0.4" }
    {{- end }}
)
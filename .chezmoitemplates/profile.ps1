trap { Write-Warning ($_.ScriptStackTrace | Out-String) }
$ProfileDir = [IO.Path]::GetDirectoryName($Profile.CurrentUserAllHosts)
{{ if eq .chezmoi.username "LD\\joelbennett" -}}
# Shortcuts for paths that you will use a lot.
# LD Teammates WILL use these variables in scripts they put in confluence:
$ldx = "C:\ldx"
$dscripts = "$ldx\DevOpsScripts"
$toolkit = "$dscripts\Toolkit"
$deut = "$ldx\Deuterium"
$chamber = "$deut\chamber"
{{- end -}}

# PART 1: Fix the PSModulePath
function Select-UniquePath {
    #
    #    .SYNOPSIS
    #        Select-UniquePath normalizes path variables and ensures only folders that actually currently exist are in them.
    #    .EXAMPLE
    #        $ENV:PATH = $ENV:PATH | Select-UniquePath
    #
    [CmdletBinding()]
    param(
        # Paths to folders
        [Parameter(Position = 1, Mandatory = $true, ValueFromRemainingArguments = $true, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path,

        # If set, output the path(s) as an array of paths
        # Otherwise output joined by -Delimiter
        [switch]$AsArray,

        # The Path value is split by the delimiter. Defaults to '[IO.Path]::PathSeparator' so you can use this on $Env:Path
        [Parameter(Mandatory = $False)]
        [AllowNull()]
        [string]$Delimiter = [IO.Path]::PathSeparator,

        # Determine whether the provider is case insensitive
        [switch]$CaseInsensitive = $($false -notin (Test-Path $ProfileDir.ToLowerInvariant(), $ProfileDir.ToUpperInvariant()))
    )
    begin {
        # Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Enter"
        # [string[]]$oldFolders = @()
        [System.Collections.Generic.List[string]]$Output = @()
    }
    process {
        $Output.AddRange([string[]]($Path.Split($Delimiter).TrimEnd('\/')))
        <#
        += $(
            # Split and trim trailing slashes to normalize, and drop empty strings
            $oldFolders += $folders = $Path -split $Delimiter -replace '[\\\/]$' -gt ""

            # Remove duplicates that are only different by case on FileSystems that are not case-sensitive
            if ($CaseInsensitive) {
                # Using wildcards on every folder forces Windows to calculate the ACTUAL case of the path
                # Use Get-Item -Force to ensure we don't loose hidden folders (because Convert-Path and )
                #
                # This won't work: Convert-Path C:\programdata*
                # But make sure we didn't add anything that wasn't already there
                $folders -replace '(?<!:|\\|/|\*)(\\|/|$)', '*$1' |
                    Get-Item -Force |
                    Where-Object { $_.FullName -iin $oldFolders } |
                    ForEach-Object FullName
            } else {
                $folders
            }
        )
        #>
    }
    end {
        if ((-not $AsArray) -and $Delimiter) {
            # This is just faster than Select-Object -Unique
            [System.Linq.Enumerable]::Distinct($Output, [StringComparer]::OrdinalIgnoreCase) -join $Delimiter
        } else {
            [System.Linq.Enumerable]::Distinct($Output, [StringComparer]::OrdinalIgnoreCase)
        }
        # Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Exit"
    }
}

# NOTES:
# 1. The main concern is to keep things in order:
#     a. User path ($Home) before machine path ($PSHome)
#     b. Existing PSModulePath before other versions
#     c. current version before other versions
# 2. I don't worry about duplicates because `Select-UniquePath` takes care of it
# 3. I don't worry about missing paths, because `Select-UniquePath` takes care of it
# 4. I don't worry about x86 because I never use it.
# 5. I don't worry about linux because I add paths based on `$PSScriptRoot`, `$Profile` and `$PSHome`
$Env:PSModulePath =
    # The normal first location in PSModulePath is the "Modules" folder next to the real profile:
    @([IO.Path]::Combine($ProfileDir,"Modules")) +
    # After that, whatever is in the environment variable
    @($Env:PSModulePath) +
    # PSHome is where powershell.exe or pwsh.exe lives ... it should already be in the Env:PSModulePath, but just in case:
    @([IO.Path]::Combine($PSHome,"Modules")) +
    # FINALLY, add the Module paths for other PowerShell versions, because I'm an optimist
    @(Get-ChildItem ([IO.Path]::Combine([IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($PSHome)),"*PowerShell")) -Filter Modules -Recurse -Depth 2).FullName +
    @(Convert-Path @(
            [IO.Path]::Combine([IO.Path]::GetDirectoryName($ProfileDir), "*PowerShell\Modules")
            # These may be duplicate or not exist, but it doesn't matter
            "$Env:ProgramFiles\*PowerShell\Modules"
            "$Env:ProgramFiles\*PowerShell\*\Modules"
            "$Env:SystemRoot\System32\*PowerShell\*\Modules"
        )) +
    # Guarantee my ~\Projects\Modules are there so I can load my dev projects
    @("$Home\Projects\Modules") +
    # To ensure canonical path case, wildcard every path separator and then convert-path
    @() | Select-UniquePath

    # I want to make sure that THIS version's Scripts (and then other versions) path is in the PATH
$Env:Path = @($Env:Path) + @([IO.Path]::Combine($ProfileDir,"Scripts")) +
    @(Get-ChildItem ([IO.Path]::Combine([IO.Path]::GetDirectoryName($ProfileDir),"*PowerShell\*")) -Filter Scripts -Directory).FullName +
    @() | Select-UniquePath

# PART 2. Fix default values
# PART 3. Things we only need in interactive sessions
#   For performance reasons, I don't want to do all of this work when I'm running automated scripts
function prompt { & "$ProfileDir\interactive.ps1" }
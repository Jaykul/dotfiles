[CmdletBinding()]
param(
    # Cache file for the calculated PSModulePath (e.g. $Profile.PSModulePath.env)
    $PSModulePathFile = [IO.Path]::ChangeExtension($Profile, ".PSModulePath.env"),

    # Cache file for the calculated Path additions (e.g. $Profile.+Path.env)
    $PathAdditionFile = [IO.Path]::ChangeExtension($Profile, ".+Path.env"),

    # Root for "this" version of PowerShell
    $ProfileDir = [IO.Path]::GetDirectoryName($Profile.CurrentUserAllHosts)
)

function Select-UniquePath {
    #
    #    .SYNOPSIS
    #        Select-UniquePath normalizes path variables and ensures only folders that actually currently exist are in them.
    #    .EXAMPLE
    #        $ENV:PATH = $ENV:PATH | Select-UniquePath
    #
    #        Shows how to deduplicate
    #    .EXAMPLE
    #        $ENV:PSModulePath | Select-UniquePath -PathName ENV:PSModulePath -RemoveNonexistent
    [CmdletBinding()]
    param(
        # Paths to folders
        [Parameter(Position = 1, Mandatory = $true, ValueFromRemainingArguments = $true, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path,

        # PowerShell Paths which will will be Set-Content with the array
        [string[]]$OutPathNameAsArray,

        # PowerShell Paths which will will be Set-Content with the $Delimiter joined string
        [string[]]$OutPathName,

        # Force passing through output even when ArrayContentPaths or JoinContentPaths are specified
        [switch]$Passthru,

        # The Path value is split by the delimiter. Defaults to '[IO.Path]::PathSeparator' so you can use this on $Env:Path
        [Parameter(Mandatory = $False)]
        [AllowNull()]
        [string]$Delimiter = [IO.Path]::PathSeparator,

        # Root for "this" version of PowerShell (calculated automatically)
        $ProfileDir = [IO.Path]::GetDirectoryName($Profile),

        # Determine whether the provider is case insensitive (calculated automatically)
        [switch]$CaseInsensitive = $($false -notin (Test-Path $ProfileDir.ToLowerInvariant(), $ProfileDir.ToUpperInvariant())),

        [switch]$RemoveNonExistent
    )
    begin {
        #Write-Information"Select-UniquePath $fg:red$Delimiter$fg:clear $Path" -Tags "Trace", "Enter"
        # [string[]]$oldFolders = @()
        [System.Collections.Generic.List[string]]$Output = @()
    }
    process {
        #Write-Information"Select-UniquePath $fg:cyan$Path$fg:clear" -Tags "Trace", "Enter"
        # Split and trim trailing slashes to normalize, and drop empty strings
        $Output.AddRange([string[]]($Path.Split($Delimiter).TrimEnd('\/').Where{$_ -gt ""}))
    }
    end {
        # Correct the case of all paths in PATH, even on Windows.
        $Path =
        if ($CaseInsensitive -or $RemoveNonExistent) {
            @(
                if ($CaseInsensitive) {
                    # Using wildcards on every folder forces Windows to calculate the ACTUAL case of the path
                    $Output -replace '(?<!:|\\|/|\*)(\\|/|$)', '*$1'
                } else {
                    $Output
                }
            ) |
                # Because Convert-Path will not resolve hidden folders, like C:\ProgramData*\ ...
                # Use Get-Item -Force to ensure we don't loose hidden folders
                Get-Item -Force |
                # But make sure we didn't add anything that wasn't already there
                Where-Object { $_.FullName -iin $Output } |
                ForEach-Object FullName
        } else {
            $Output
        }

        [string[]]$Result = [System.Linq.Enumerable]::Distinct($Path, [StringComparer]::OrdinalIgnoreCase)

        if ($OutPathNameAsArray) {
            #Write-Information"Set-Content $fg:green$OutPathNameAsArray${fg:clear}:`n$($Result -join "`n")" -Tags "Trace"
            Set-Content -Path $OutPathNameAsArray -Value $Result
        }
        if ($OutPathName) {
            #Write-Information"Set-Content $fg:green$OutPathName${fg:clear}: $Result" -Tags "Trace"
            Set-Content -Path $OutPathName -Value ($Result -join $Delimiter)
        }
        if ($Passthru -or -not ($OutPathNameAsArray -or $OutPathName)) {
            #Write-Information"${fg:Green}Passthru:$fg:clear $Result" -Tags "Trace"
            $Result
        }
        #Write-Information"Select-UniquePath $fg:red$Delimiter$fg:clear $($Result -join "$fg:red$Delimiter$fg:clear")" -Tags "Trace", "Exit"
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
# The normal first location in PSModulePath is the "Modules" folder next to the real profile:
@([IO.Path]::Combine($ProfileDir, "Modules")) +
# After that, I guess we'll keep whatever is in the environment variable
@($Env:PSModulePath) +
# PSHome is where powershell.exe or pwsh.exe lives ... it should already be in the Env:PSModulePath, but just in case:
@([IO.Path]::Combine($PSHome, "Modules")) +
# FINALLY, add the Module paths for other PowerShell versions, because I'm an optimist
@(Get-ChildItem ([IO.Path]::Combine([IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($PSHome)), "*PowerShell")) -Filter Modules -Recurse -Depth 2).FullName +
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
@() | Select-UniquePath -OutPathName PSModulePath -OutPathNameAsArray $PSModulePathFile

# I want to make sure that THIS version's Scripts (and then other versions) path is in the PATH
$PathAdditions = [Linq.Enumerable]::Distinct([string[]]@(
    @([IO.Path]::Combine($ProfileDir, "Scripts")) +
    @(Get-ChildItem ([IO.Path]::Combine([IO.Path]::GetDirectoryName($ProfileDir), "*PowerShell\*")) -Filter Scripts -Directory).FullName
    )) | Tee-Object -FilePath $PathAdditionFile

@($Env:Path) + @($PathAdditions) | Select-UniquePath -RemoveNonExistent -OutPathName Env:Path

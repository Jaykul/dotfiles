[CmdletBinding()]
param(
    # Cache file for the calculated PSModulePath (e.g. $Profile.PSModulePath.env)
    $PSModulePathFile = [IO.Path]::ChangeExtension($Profile, ".PSModulePath.env"),

    # Cache file for the calculated Path (e.g. $Profile.Path.env)
    $PathFile = [IO.Path]::ChangeExtension($Profile, ".Path.env"),

    # Root for "this" version of PowerShell
    $ProfileDir = [IO.Path]::GetDirectoryName($Profile.CurrentUserAllHosts),

    # Determine whether the provider is case insensitive (calculated automatically)
    [switch]$CaseInsensitive = $($false -notin (Test-Path $ProfileDir.ToLowerInvariant(), $ProfileDir.ToUpperInvariant()))
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
        [Parameter(Position = 1, Mandatory, ValueFromRemainingArguments, ValueFromPipeline, ValueFromPipelineByPropertyName)]
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
        # Write-Information "Select-UniquePath ENTER BEGIN $fg:red$Delimiter$fg:clear $Path" -Tags "Trace", "Enter", "Begin"
        # [string[]]$oldFolders = @()
        [System.Collections.Generic.List[string]]$inputPaths = @()

        # Write-Information "Select-UniquePath EXIT BEGIN $fg:red$Delimiter$fg:clear $Path" -Tags "Trace", "Exit", "Begin"
    }
    process {
        # Write-Information "Select-UniquePath ENTER PROCESS $fg:cyan$Path$fg:clear" -Tags "Trace", "Enter", "Process"
        # Split and trim trailing slashes to normalize, and drop empty strings
        $inputPaths.AddRange([string[]]($Path.Split($Delimiter).TrimEnd('\/').Where{$_ -gt ""}))
        # Write-Information "Select-UniquePath EXIT PROCESS $fg:cyan$Path$fg:clear" -Tags "Trace", "Exit", "Process"
    }
    end {
        # Correct the case of all paths in PATH, even on Windows.
        [string[]]$outputPaths =
        if ($CaseInsensitive -or $RemoveNonExistent) {
            @(
                if ($CaseInsensitive) {
                    # Using wildcards on every folder forces Windows to calculate the ACTUAL case of the path
                    $inputPaths -replace '(?<!:|\\|/|\*)(\\|/|$)', '*$1'
                } else {
                    $inputPaths
                }
            ) |
                # Because Convert-Path will not resolve hidden folders, like C:\ProgramData*\ ...
                # Use Get-Item -Force to ensure we don't loose hidden folders
                Get-Item -Force |
                # But make sure we didn't add anything that wasn't already there
                Where-Object { $_.FullName -iin $inputPaths } |
                ForEach-Object FullName
        } else {
            $inputPaths
        }

        if (!$outputPaths) {
            throw "No valid paths after filter. InputPaths: $($InputPaths -join "`n")"
        }

        [string[]]$Result = [System.Linq.Enumerable]::Distinct($outputPaths, [StringComparer]::OrdinalIgnoreCase)

        if ($OutPathNameAsArray) {
            # Write-Information "Set-Content $fg:green$OutPathNameAsArray${fg:clear}:`n$($Result -join "`n")" -Tags "Trace"
            Set-Content -Path $OutPathNameAsArray -Value $Result
        }
        if ($OutPathName) {
            # Write-Information "Set-Content $fg:green$OutPathName${fg:clear}: $Result" -Tags "Trace"
            Set-Content -Path $OutPathName -Value ($Result -join $Delimiter)
        }
        if ($Passthru -or -not ($OutPathNameAsArray -or $OutPathName)) {
            # Write-Information "${fg:Green}Passthru:$fg:clear $Result" -Tags "Trace"
            $Result
        }
        # Write-Information "Select-UniquePath $fg:red$Delimiter$fg:clear $($Result -join "$fg:red$Delimiter$fg:clear")" -Tags "Trace", "Exit"
    }
}

# NOTES:
# 0. A hack for PowerShellGet 3.x
#     a. All versions of PowerShell use the same Env:PSModulePath
#     b. PowerShellGet 3 uses PSModulePath _before_ it's hard-coded locations.
#     c. If you put a shared location (outside your documents folder), PowerShellGet will use that first
# 1. The main concern is to keep things in order:
#     a. User path ($Home) before machine path ($PSHome)
#     b. Current version before other versions
#     c. Existing PSModulePath before other versions
# 2. I don't worry about duplicates because `Select-UniquePath` takes care of it
# 3. I don't worry about missing paths, because `Select-UniquePath` takes care of it
# 4. I don't worry about x86 because I never use it.
# 5. I don't worry about linux because I add paths based on `$PSScriptRoot`, `$Profile` and `$PSHome`

# Before paths that are next to my $profile, I want a path that's outside of my documents folder (and thus, outside OneDrive)
@([IO.Path]::Combine($Home, "PowerShell", "Modules")) +
# Then, the normal location next my $profile:
@([IO.Path]::Combine($ProfileDir, "Modules")) +
# Finally, this version's PSHome
@([IO.Path]::Combine($PSHome, "Modules")) +
# And then ... weirdly, I'm adding my Scripts path
# PowerShellGet 3 will see it in PSMODULEPATH and use it
@([IO.Path]::Combine($Home, "PowerShell", "Scripts")) +
# Then we can use whatever was in the PSModulePath environment variable
@(
    # But I don't just use $ENV:PSModulePath, because I overwrite it in my profile with cached output from this!
    if ($Env:PSModulePath_Before) {
        $Env:PSModulePath_Before
    } else {
        [System.Environment]::GetEnvironmentVariable("PSMODULEPATH", "Machine") + ';' +
        [System.Environment]::GetEnvironmentVariable("PSMODULEPATH", "User")
    }
) +
# If we're on Windows, just to make sure we don't miss anything
# Add the Module paths for other PowerShell versions down here
$(if (!$IsMacOS -and !$IsLinux) {
@(Convert-Path @(
        [IO.Path]::Combine([IO.Path]::GetDirectoryName($ProfileDir), "*PowerShell\Modules")
        # These may be duplicate or not exist, but it doesn't matter
        "$Env:ProgramFiles\*PowerShell\Modules"
        "$Env:ProgramFiles\*PowerShell\*\Modules"
        "$Env:SystemRoot\System32\*PowerShell\*\Modules"
    ))
}) +
    # This is likely to result in duplicates, but we'll remove those at the end
@(Get-ChildItem ([IO.Path]::Combine([IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($PSHome)), "*PowerShell")) -Filter Modules -Recurse -Depth 2).FullName +
# Put my ~\Projects\Modules on the end, so I can load my dev builds by version number when I want to
@("$Home\Projects\Modules") +
# Finally, to avoid duplicates and ensure canonical path case, pass it all through Select-UniquePath, set ENV and cache it on disc
@() | Select-UniquePath -OutPathName Env:PSModulePath -OutPathNameAsArray $PSModulePathFile -CaseInsensitive:$CaseInsensitive -RemoveNonExistent

# I want to make sure that THIS version's Scripts (and then other versions) path is in the PATH
# But don't use $ENV:PATH here because I wiped it's original contents with previously cached output from here
@($PSHOME) +
@(
    # Don't use $ENV:PATH, because I overwrite it in my profile with cached output from this
    if ($Env:PATH_Before) {
        $Env:PATH_Before
    } else {
        [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ';' +
        [System.Environment]::GetEnvironmentVariable("PATH", "User")
    }
) +
@([IO.Path]::Combine($ProfileDir, "Scripts")) +
@(Get-ChildItem ([IO.Path]::Combine([IO.Path]::GetDirectoryName($ProfileDir), "*PowerShell\*")) -Filter Scripts -Directory).FullName +
# Finally, to avoid duplicates and ensure canonical path case, pass it all through Select-UniquePath, set ENV and cache it on disc
@() | Select-UniquePath -OutPathName Env:Path -OutPathNameAsArray $PathFile -CaseInsensitive:$CaseInsensitive -RemoveNonExistent

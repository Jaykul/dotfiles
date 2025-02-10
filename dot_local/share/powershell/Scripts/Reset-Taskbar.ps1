<#
As a developer, I have full admin rights on my laptop...
But our IT department still deploys GPO's that break things from time to time.
So for breaking policies that can be removed in the registry, I just fix it.

The Microsoft\FVE policy breaks Docker: https://github.com/docker/for-win/issues/1297

The Microsoft\Edge and Google\Chrome policies force startup options
#>
$Roots = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    "HKLM:\SOFTWARE\Policies\Google\Chrome"
    "HKCU:\SOFTWARE\Policies\Microsoft\Edge"
    "HKCU:\SOFTWARE\Policies\Google\Chrome"
)

$Paths = $Roots | Where-Object { $_ | Test-Path }
# If any of these policy folders exist, run PowerShell elevated to clean up
if ($Paths) {
    Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile -NonInteractive -Command ""&{ Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE FDVDenyWriteAccess 0; Remove-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Edge','HKCU:\SOFTWARE\Policies\Microsoft\Edge','HKLM:\SOFTWARE\Policies\Google\Chrome','HKCU:\SOFTWARE\Policies\Google\Chrome' -Recurse -ErrorAction SilentlyContinue }"""
}

# Corporate keeps pinning things. They obviously don't understand the meaning of "User Pinned"


<# # Get all the Class IDs
$CLSID = Get-ItemProperty "HKLM:\SOFTWARE\Classes\CLSID\{*}\" "(default)" -ErrorAction Ignore
| Select-Object @{Name = "Guid"; Expr = { $_.PSChildName } }, @{Name = "DisplayName"; Expr = { $_."(default)"}}

[PSCustomObject]@{ Name = "All Tasks";             GUID = "{ED7BA470-8E54-465E-825C-99712043E01C}" },
[PSCustomObject]@{ Name = "User Pinned";           GUID = "{1f3427c8-5c10-4210-aa03-2ee45287d668}" },
[PSCustomObject]@{ Name = "Applications";          GUID = "{4234d49b-0245-4df3-b780-3893943456e1}" },
[PSCustomObject]@{ Name = "Programs and Features"; GUID = "{7b81be6a-ce2b-4676-a29e-eb907a5126c5}" }

Shell COM Object CLSID = {41904400-be18-11d3-a28b-00104bd35090}
Or is it "286E6F1B-7113-4355-9562-96B7E9D64C54"??
#>
function Get-ComFile {
    param($item)
    Write-Host $item.Name -for cyan
    foreach ($item in $item.Items()) {
        if ($item.IsFolder) {
            Get-ComFile $item.GetFolder()
        } else { $item }
    }
}

function Get-Application {
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name = "*",
        [switch]$StartPinned,
        # [switch]$PinnableToStart,
        [switch]$TaskbarPinned,
        # [switch]$PinnableToTaskbar,
        [guid[]]$Namespace = @(
            "{4234d49b-0245-4df3-b780-3893943456e1}" # Applications
            "{1f3427c8-5c10-4210-aa03-2ee45287d668}" # User Pinned
        )
    )
    begin {
        $App = New-Object -Com Shell.Application
    }
    process {
        foreach ($ns in $Namespace) {
            Get-ComFile ($App.NameSpace("shell:::{$ns}")) | Where-Object {
                ($_.Name -like $Name) -and
                (!$TaskbarPinned -or @($_.Verbs()).Name -replace "&" -eq "Unpin from taskbar") -and
                (!$StartPinned -or @($_.Verbs()).Name -replace "&" -eq "Unpin from start")
            }
        }
    }
}

function New-Shortcut {
    param (
        # Should be a .lnk file path
        [string]$Path,
        [string]$TargetPath
    )

    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($Path)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Save()
}

filter Unpin {
    param([ValidateSet("taskbar", "Start")]$From = "taskbar")
    @($_.Verbs()).Where{ $_.Name -replace "&" -eq "Unpin from $From" }.DoIt()
}

filter Pin {
    param([ValidateSet("taskbar", "Start")]$To = "taskbar")
    @($_.Verbs()).Where{ $_.Name -replace "&" -eq "Pin to $To" }.DoIt()
}

# $TaskBar = @(@($App.NameSpace("shell:::{1f3427c8-5c10-4210-aa03-2ee45287d668}").Items()).Where{ $_.Name -match "Taskbar" })[0].Path


function Copy-ToTaskbar {
    [CmdletBinding()]
    param(
        $Name
    )
    # TODO: Figure out how to do this starting with the "Applications" object
    Get-ChildItem -Filter "*$Name*" -File -Recurse @(
        [System.Environment]::GetFolderPath("Programs")
        [System.Environment]::GetFolderPath("CommonPrograms")
    ) | Sort-Object { $_.Name.Length } | Select-Object -First 1
    | Copy-Item -Destination $TaskBar

    Get-Application $Name -Namespace "{1f3427c8-5c10-4210-aa03-2ee45287d668}" | PinTaskbar
}

Get-Application -TaskbarPinned |
    Where-Object Name -NotIn "KeePass 2", "Firefox", "WezTerm", "File Explorer", "Microsoft Teams", "Visual Studio Code - Insiders", "Outlook", "Logseq" |
    Unpin
[CmdletBinding()]
param()

$Env:MAMBA_ROOT_PREFIX = Convert-Path "~/.local/share/mamba"
$Env:MAMBA_EXE = Convert-Path "~/miniforge3/Library/bin/mamba.exe"
if (!(Test-Path $Env:MAMBA_EXE)) {
    Write-Warning "Initialize-Mamba can't find mamba"
    return
}

# # & "C:\tools\miniforge3\Scripts\conda.exe" "shell.powershell" "hook"
# Write-Information "Initializing miniconda environment"
# $Env:CONDA_EXE = Convert-Path "~\miniforge3\Scripts\conda.exe"
# $Env:_CE_M = $null
# $Env:_CE_CONDA = $null
# $Env:_CONDA_ROOT = Convert-Path "~\miniforge3"
# $Env:_CONDA_EXE = Convert-Path "~\miniforge3\Scripts\conda.exe"
# $CondaModuleArgs = @{ChangePs1 = $Force }
# Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1" -ArgumentList $CondaModuleArgs -Scope Global

# Write-Information "Conda initialized."
# Write-Information "Calling 'conda activate' to activate the base environment."
# conda activate base
# Write-Information "Conda activated. Call Show-CondaContext in your prompt to see the current conda environment."

# & $Env:MAMBA_EXE 'shell' 'hook' -s 'powershell' -r $Env:MAMBA_ROOT_PREFIX
Import-Module "$Env:MAMBA_ROOT_PREFIX\condabin\Mamba.psm1" -ArgumentList @{ ChangePs1 = $False }
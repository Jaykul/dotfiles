[CmdletBinding()]
param()

if (!(Test-Path "C:\tools\miniconda3\Scripts\conda.exe")) {
    Write-Warning "Initialize-Conda can't find conda"
    return
}

Write-Information "Initializing miniconda environment"
$Env:CONDA_EXE = "C:/tools/miniconda3\Scripts\conda.exe"
$Env:_CE_M = ""
$Env:_CE_CONDA = ""
$Env:_CONDA_ROOT = "C:/tools/miniconda3"
$Env:_CONDA_EXE = "C:/tools/miniconda3\Scripts\conda.exe"

$CondaModuleArgs = @{ChangePs1 = $Force }
Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1" -ArgumentList $CondaModuleArgs -Scope Global

Write-Information "Conda initialized."
Write-Information "Calling 'conda activate' to activate the base environment."
conda activate
Write-Information "Conda activated. Call Show-CondaContext in your prompt to see the current conda environment."

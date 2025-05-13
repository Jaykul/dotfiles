[CmdletBinding()]
param()

if (!(Get-Module Conda)) {
    & "$PSScriptRoot/Initialize-Conda.ps1"
}
if (Get-Module Conda) {
    if (!(Test-Path("$HOME\Projects\Others\Codex-CLI\src\codex_query.py"))) {
        Write-Warning "Cannot find codex_query.py - ReadlineAI not registered"
        return
    }

    # this takes the input from the buffer and passes it to codex_query.py
    Set-PSReadLineKeyHandler -Key Ctrl+g `
        -BriefDescription ReadlineAI `
        -LongDescription "Calls ChatGPT with the current buffer" `
        -ScriptBlock {
        param($key, $arg)

        $buffer = $null
        $cursor = $null

        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$cursor)

        # get response from create_completion function
        Write-Progress -Id 1 -Activity "Codex query"
        $output = $buffer | python "$HOME\Projects\Others\Codex-CLI\src\codex_query.py"
        Write-Progress -Id 1 -Activity "Codex query" -Completed

        # check if output is not null
        if ($output -ne $null) {
            foreach ($str in $output) {
                if ($str -ne $null -and $str -ne "") {
                    [Microsoft.PowerShell.PSConsoleReadLine]::AddLine()
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($str)
                }
            }
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AddLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("# No response from GPT")
        }
    }
} else {
    Write-Warning "Conda not initialized. ReadlineAI not registered"
}
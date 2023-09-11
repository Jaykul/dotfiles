if (!(Get-Module Conda)) {
    & "$PSScriptRoot/Initialize-Conda.ps1"
}
if (Get-Module Conda) {
    if (!(Test-Path("~\Projects\Others\Codex-CLI\src\codex_query.py"))) {
        Write-Warning "Cannot find codex_query.py - ReadlineAI not registered"
        return
    }

    # this function takes the input from the buffer and passes it to codex_query.py
    function create_completion() {
        param (
            [Parameter (Mandatory = $true)] [string] $buffer
        )

        Write-Progress -Id 1 -Activity "Codex query"
        $output = $buffer | python "~\Projects\Others\Codex-CLI\src\codex_query.py"
        Write-Progress -Id 1 -Activity "Codex query" -Completed

        return $output
    }

    Set-PSReadLineKeyHandler -Key Ctrl+g `
        -BriefDescription ReadlineAI `
        -LongDescription "Calls ChatGPT with the current buffer" `
        -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null

        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        # get response from create_completion function
        $output = create_completion($line)

        # check if output is not null
        if ($output -ne $null) {
            foreach ($str in $output) {
                if ($str -ne $null -and $str -ne "") {
                    [Microsoft.PowerShell.PSConsoleReadLine]::AddLine()
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($str)
                }
            }
        }
    }
}
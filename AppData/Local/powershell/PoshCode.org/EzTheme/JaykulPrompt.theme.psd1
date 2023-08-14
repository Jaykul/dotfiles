
@{
  PowerLine = (PSObject @{
    DefaultCaps = '', ''
    DefaultSeparator = ''
    Prompt = @(
        New-TerminalBlock -Content '{ Update-ZLocation $pwd }'
        Show-HistoryId -Bg Magenta4 -Fg White
        New-TerminalBlock -Spacer
        Show-KubeContext -Bg DarkOrchid2 -Fg White
        Show-AzureContext -Bg Purple3 -Prefix "&nf-mdi-azure; " -Fg White
        Show-Path -HomeString "&House;" -Separator '' -Bg SlateBlue4 -Fg White -Depth 3
        New-TerminalBlock -Spacer
        Show-PoshGitStatus -Bg Gray30
        Show-Date -Format "h\:mm" -Prefix "🕒" -Bg DeepSkyBlue4 -Fg White
        Show-ElapsedTime -Autoformat -Prefix "&hourglassdone;" -Bg DeepSkyBlue -Fg Black
        New-TerminalBlock -NewLine
        New-TerminalBlock -Fg '#207A70' -Bg '#35C7B6' -Content '' -EFg '#CE178E'
    )
    PSReadLineContinuationPrompt = '█ '
    PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
    PSReadLinePromptText = '[48;2;99;184;255m[38;2;255;255;255m[49m[38;2;99;184;255m[0m','[48;2;139;34;82m[38;2;255;255;255m[49m[38;2;139;34;82m[0m'
    HideErrors = $false
    SetCurrentDirectory = $false
})
}

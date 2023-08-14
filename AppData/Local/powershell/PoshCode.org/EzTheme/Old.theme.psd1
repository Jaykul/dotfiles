
@{
  'Theme.PSReadline' = (PSObject @{
    CommandColor = '[93m'
CommentColor = '[32m'
ContinuationPromptColor = '[38;2;99;184;255m'
DefaultTokenColor = '[37m'
EmphasisColor = '[96m'
ErrorColor = '[91m'
InlinePredictionColor = '[38;5;238m'
KeywordColor = '[92m'
ListPredictionColor = '[33m'
ListPredictionSelectedColor = '[48;5;238m'
MemberColor = '[97m'
NumberColor = '[97m'
OperatorColor = '[90m'
ParameterColor = '[90m'
SelectionColor = '[30;47m'
StringColor = '[36m'
TypeColor = '[37m'
VariableColor = '[92m'
} -TypeName 'Selected.Microsoft.PowerShell.PSConsoleReadLineOptions','System.Management.Automation.PSCustomObject','System.Object')
  'Theme.PowerShell' = (PSObject @{
    Background = (ConsoleColor Black)
DebugBackgroundColor = (ConsoleColor Black)
DebugForegroundColor = (ConsoleColor Yellow)
ErrorAccentColor = (ConsoleColor Cyan)
ErrorBackgroundColor = (ConsoleColor Black)
ErrorForegroundColor = (ConsoleColor Red)
Foreground = (ConsoleColor Gray)
FormatAccentColor = (ConsoleColor Green)
ProgressBackgroundColor = (ConsoleColor Yellow)
ProgressForegroundColor = (ConsoleColor Black)
VerboseBackgroundColor = (ConsoleColor Black)
VerboseForegroundColor = (ConsoleColor Yellow)
WarningBackgroundColor = (ConsoleColor Black)
WarningForegroundColor = (ConsoleColor Yellow)
} -TypeName 'Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy','Selected.Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy','System.Management.Automation.PSCustomObject','System.Object')
  PowerLine = (PSObject @{
    DefaultCapsLeftAligned = '', ''
    DefaultCapsRightAligned = '', ''
    DefaultSeparator = '', ''
    Prompt = @(
        Show-HistoryId -DBg 'SteelBlue1' -EBg '#8B2252' -Fg 'White' -EFg 'White'
        Show-Path -HomeString "&House;" -Separator '' -Background 'Gray100' -Foreground 'Black'
        Show-Date -Format "h\:mm" -Prefix "🕒"  -Alignment 'Right' -Background 'Gray23'
        Show-ElapsedTime -Autoformat -Prefix "⏱️"  -Alignment 'Right' -Background 'Gray47'
        New-TerminalBlock -DFg 'White' -DBg '#63B8FF' -EFg 'White' -Cap '‍' -Content ''
    )
    PSReadLineContinuationPrompt = '▌ '
    PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
    PSReadLinePromptText = '[48;2;99;184;255m[38;2;255;255;255m[49m[38;2;99;184;255m[0m','[48;2;139;34;82m[38;2;255;255;255m[49m[38;2;139;34;82m[0m'
    SetCurrentDirectory = $false
})
}

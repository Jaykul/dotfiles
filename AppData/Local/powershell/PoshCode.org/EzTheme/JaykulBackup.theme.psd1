
@{
  'Theme.PSReadLine' = (PSObject @{
    CommandColor = '[38;2;255;230;109m'
CommentColor = '[38;2;95;97;103m'
ContinuationPromptColor = '[38;2;53;199;182m'
DefaultTokenColor = '[38;2;213;206;217m'
EmphasisColor = '[38;2;243;156;18m'
ErrorColor = '[4;38;2;255;93;97m'
InlinePredictionColor = '[38;2;95;97;103m'
KeywordColor = '[38;2;199;77;147m'
ListPredictionColor = '[33m'
ListPredictionSelectedColor = '[48;5;238m'
ListPredictionTooltipColor = '[97;2;3m'
MemberColor = '[38;2;43;168;256m'
NumberColor = '[38;2;243;43;23m'
OperatorColor = '[38;2;238;93;67m'
ParameterColor = '[38;2;143;228;256m'
SelectionColor = '[100;38;2;190;190;190m'
StringColor = '[38;2;150;224;114m'
TypeColor = '[38;2;238;93;67m'
VariableColor = '[38;2;0;242;178m'
} -TypeName 'Selected.Microsoft.PowerShell.PSConsoleReadLineOptions','System.Management.Automation.PSCustomObject','System.Object')
  PowerLine = (PSObject @{
    DefaultCaps = '', ''
    DefaultSeparator = ''
    Prompt = @(
        Show-ElapsedTime -Autoformat -Prefix "&hourglassdone;" -Bg DeepSkyBlue -Fg Black -Caps '', ''
        New-TerminalBlock -Cap '‍' -NewLine
        New-TerminalBlock -Cap '‍' -Content '{ Update-ZLocation $pwd }'
        Show-HistoryId -Bg Magenta4 -Fg White
        New-TerminalBlock -Cap '‍' -Spacer
        Show-KubeContext -Bg DarkOrchid2 -Fg White
        Show-AzureContext -Bg Purple3 -Prefix "&nf-mdi-azure; " -Fg White
        Show-Path -HomeString "&House;" -Separator '' -Bg SlateBlue4 -Fg White -Depth 3
        New-TerminalBlock -Cap '‍' -Spacer
        Show-PoshGitStatus -Bg Gray30
        Show-Date -Format "h\:mm" -Prefix "🕒" -Bg DeepSkyBlue4 -Fg White
        New-TerminalBlock -Cap '‍' -NewLine
        New-TerminalBlock -Cap '‍' -Fg '#207A70' -Bg '#35C7B6' -Content '' -EFg '#CE178E'
    )
    PSReadLineContinuationPrompt = '█ '
    PSReadLineContinuationPromptColor = '[38;2;53;199;182m'
    PSReadLinePromptText = '[48;2;53;199;182m[38;2;32;122;112m[49m[38;2;53;199;182m[0m','[48;2;53;199;182m[38;2;206;23;142m[49m[38;2;53;199;182m[0m'
    HideErrors = $false
    SimpleTransient = $true
    NoCache = $false
    SetCurrentDirectory = $false
})
  'Theme.PSStyle' = (PSObject @{
    Background_Black = '[40m'
Background_Blue = '[44m'
Background_BrightBlack = '[100m'
Background_BrightBlue = '[104m'
Background_BrightCyan = '[106m'
Background_BrightGreen = '[102m'
Background_BrightMagenta = '[105m'
Background_BrightRed = '[101m'
Background_BrightWhite = '[107m'
Background_BrightYellow = '[103m'
Background_Cyan = '[46m'
Background_Green = '[42m'
Background_Magenta = '[45m'
Background_Red = '[41m'
Background_White = '[47m'
Background_Yellow = '[43m'
Blink = '[5m'
BlinkOff = '[25m'
Bold = '[1m'
BoldOff = '[22m'
FileInfo_Directory = '[34;1m'
FileInfo_Executable = '[32;1m'
FileInfo_Extension = @{
      '.zip' = '[31;1m'
      '.cab' = '[31;1m'
      '.tgz' = '[31;1m'
      '.ps1' = '[33;1m'
      '.gz' = '[31;1m'
      '.ps1xml' = '[33;1m'
      '.nupkg' = '[31;1m'
      '.7z' = '[31;1m'
      '.psm1' = '[33;1m'
      '.tar' = '[31;1m'
      '.psd1' = '[33;1m'
    }
FileInfo_SymbolicLink = '[36;1m'
Foreground_Black = '[30m'
Foreground_Blue = '[34m'
Foreground_BrightBlack = '[90m'
Foreground_BrightBlue = '[94m'
Foreground_BrightCyan = '[96m'
Foreground_BrightGreen = '[92m'
Foreground_BrightMagenta = '[95m'
Foreground_BrightRed = '[91m'
Foreground_BrightWhite = '[97m'
Foreground_BrightYellow = '[93m'
Foreground_Cyan = '[36m'
Foreground_Green = '[32m'
Foreground_Magenta = '[35m'
Foreground_Red = '[31m'
Foreground_White = '[37m'
Foreground_Yellow = '[33m'
Formatting_Debug = '[38;2;0;255;0m'
Formatting_Error = '[38;2;255;99;71m'
Formatting_ErrorAccent = '[36;1m'
Formatting_FormatAccent = '[32;1m'
Formatting_TableHeader = '[32;1m'
Formatting_Verbose = '[38;2;0;255;255m'
Formatting_Warning = '[33;1m'
Hidden = '[8m'
HiddenOff = '[28m'
Italic = '[3m'
ItalicOff = '[23m'
OutputRendering = 'Host'
Progress_MaxWidth = 120
Progress_Style = '[33;1m'
Progress_UseOSCIndicator = $False
Progress_View = 'Minimal'
Reset = '[0m'
Reverse = '[7m'
ReverseOff = '[27m'
Strikethrough = '[9m'
StrikethroughOff = '[29m'
Underline = '[4m'
UnderlineOff = '[24m'
} -TypeName 'Theme.PSStyle','System.Management.Automation.PSCustomObject','System.Object')
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
}

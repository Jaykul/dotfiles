
@{
    PowerLine               = (PSObject @{
            DefaultCapsLeftAligned            = '', ''
            DefaultCapsRightAligned           = '', ''
            DefaultSeparator                  = '', ''
            Prompt                            = @(
                Show-HistoryId -Bg Magenta3 -Fg White
                Show-KubeContext -Bg Purple3 -Fg White
                Show-AzureContext -Bg RoyalBlue3 -Prefix "&nf-mdi-azure; " -Fg White
                Show-Path -HomeString "&House;" -Separator '' -Bg DeepSkyBlue3 -Fg White
                Show-PoshGitStatus -bg Gray90
                Show-Date -Format "h\:mm" -Prefix "🕒"  -Alignment 'Right' -Background Goldenrod2
                Show-ElapsedTime -Autoformat -Prefix "⏱️"  -Alignment 'Right' -Background Goldenrod3
                New-TerminalBlock -DFg 'White' -DBg '#00B2EE' -EFg '#CE178E' -Cap '‍' -Content ''
            )
            PSReadLineContinuationPrompt      = '█ '
            PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
            PSReadLinePromptText              = '[48;2;99;184;255m[38;2;255;255;255m[49m[38;2;99;184;255m[0m', '[48;2;139;34;82m[38;2;255;255;255m[49m[38;2;139;34;82m[0m'
            HideErrors                        = $false
            SetCurrentDirectory               = $false
        })
    'Theme.WindowsTerminal' = (PSObject @{
            background          = (ConvertFrom-Metadata @'
#FFFFFF
'@ -As PoshCode.Pansies.RgbColor)
            black               = (ConvertFrom-Metadata @'
#000000
'@ -As PoshCode.Pansies.RgbColor)
            blue                = (ConvertFrom-Metadata @'
#0073C3
'@ -As PoshCode.Pansies.RgbColor)
            brightBlack         = (ConvertFrom-Metadata @'
#454545
'@ -As PoshCode.Pansies.RgbColor)
            brightBlue          = (ConvertFrom-Metadata @'
#12A8CD
'@ -As PoshCode.Pansies.RgbColor)
            brightCyan          = (ConvertFrom-Metadata @'
#2BC2A7
'@ -As PoshCode.Pansies.RgbColor)
            brightGreen         = (ConvertFrom-Metadata @'
#81B600
'@ -As PoshCode.Pansies.RgbColor)
            brightPurple        = (ConvertFrom-Metadata @'
#C05478
'@ -As PoshCode.Pansies.RgbColor)
            brightRed           = (ConvertFrom-Metadata @'
#CA7073
'@ -As PoshCode.Pansies.RgbColor)
            brightWhite         = (ConvertFrom-Metadata @'
#FFFFFF
'@ -As PoshCode.Pansies.RgbColor)
            brightYellow        = (ConvertFrom-Metadata @'
#CC9800
'@ -As PoshCode.Pansies.RgbColor)
            cursorColor         = (ConvertFrom-Metadata @'
#000000
'@ -As PoshCode.Pansies.RgbColor)
            cyan                = (ConvertFrom-Metadata @'
#008E81
'@ -As PoshCode.Pansies.RgbColor)
            foreground          = (ConvertFrom-Metadata @'
#000000
'@ -As PoshCode.Pansies.RgbColor)
            green               = (ConvertFrom-Metadata @'
#4A8100
'@ -As PoshCode.Pansies.RgbColor)
            name                = 'EzTheme'
            purple              = (ConvertFrom-Metadata @'
#8F0057
'@ -As PoshCode.Pansies.RgbColor)
            red                 = (ConvertFrom-Metadata @'
#BE0000
'@ -As PoshCode.Pansies.RgbColor)
            selectionBackground = (ConvertFrom-Metadata @'
#FFFFFF
'@ -As PoshCode.Pansies.RgbColor)
            white               = (ConvertFrom-Metadata @'
#848388
'@ -As PoshCode.Pansies.RgbColor)
            yellow              = (ConvertFrom-Metadata @'
#BB6200
'@ -As PoshCode.Pansies.RgbColor)
        } -TypeName 'WindowsTerminal.ColorScheme', 'Terminal.ColorScheme', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.PSReadLine'      = (PSObject @{
            CommandColor                = '[38;2;121;94;38m'
            CommentColor                = '[38;2;0;128;0m'
            ContinuationPromptColor     = '[38;2;99;184;255m'
            DefaultTokenColor           = '[38;2;0;0;0m'
            EmphasisColor               = '[38;2;0;0;128m'
            ErrorColor                  = '[38;2;205;49;49m'
            InlinePredictionColor       = '[90m'
            KeywordColor                = '[38;2;175;0;219m'
            ListPredictionColor         = '[33m'
            ListPredictionSelectedColor = '[48;5;238m'
            MemberColor                 = '[38;2;121;94;38m'
            NumberColor                 = '[38;2;9;134;88m'
            OperatorColor               = '[38;2;0;0;0m'
            ParameterColor              = '[38;2;38;127;153m'
            SelectionColor              = '[48;2;214;255;128m'
            StringColor                 = '[38;2;163;21;21m'
            TypeColor                   = '[38;2;0;0;255m'
            VariableColor               = '[38;2;0;16;128m'
        } -TypeName 'Selected.Microsoft.PowerShell.PSConsoleReadLineOptions', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.PowerShell'      = (PSObject @{
            Background              = (ConsoleColor Black)
            DebugBackgroundColor    = (ConsoleColor Black)
            DebugForegroundColor    = (ConsoleColor Green)
            ErrorAccentColor        = (ConsoleColor Cyan)
            ErrorBackgroundColor    = (ConsoleColor Black)
            ErrorForegroundColor    = (ConsoleColor Red)
            Foreground              = (ConsoleColor Gray)
            FormatAccentColor       = (ConsoleColor Green)
            ProgressBackgroundColor = (ConsoleColor DarkMagenta)
            ProgressForegroundColor = (ConsoleColor Yellow)
            VerboseBackgroundColor  = (ConsoleColor Black)
            VerboseForegroundColor  = (ConsoleColor Cyan)
            WarningBackgroundColor  = (ConsoleColor Black)
            WarningForegroundColor  = (ConsoleColor Yellow)
        } -TypeName 'Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy', 'Selected.Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.PSStyle'         = (PSObject @{
            Background_Black         = '[40m'
            Background_Blue          = '[44m'
            Background_BrightBlack   = '[100m'
            Background_BrightBlue    = '[104m'
            Background_BrightCyan    = '[106m'
            Background_BrightGreen   = '[102m'
            Background_BrightMagenta = '[105m'
            Background_BrightRed     = '[101m'
            Background_BrightWhite   = '[107m'
            Background_BrightYellow  = '[103m'
            Background_Cyan          = '[46m'
            Background_Green         = '[42m'
            Background_Magenta       = '[45m'
            Background_Red           = '[41m'
            Background_White         = '[47m'
            Background_Yellow        = '[43m'
            Blink                    = '[5m'
            BlinkOff                 = '[25m'
            Bold                     = '[1m'
            BoldOff                  = '[22m'
            FileInfo_Directory       = '[44;1m'
            FileInfo_Executable      = '[32;1m'
            FileInfo_Extension       = @{
                '.nupkg'  = '[31;1m'
                '.gz'     = '[31;1m'
                '.7z'     = '[31;1m'
                '.tar'    = '[31;1m'
                '.ps1'    = '[33;1m'
                '.cab'    = '[31;1m'
                '.zip'    = '[31;1m'
                '.psd1'   = '[33;1m'
                '.psm1'   = '[33;1m'
                '.tgz'    = '[31;1m'
                '.ps1xml' = '[33;1m'
            }
            FileInfo_SymbolicLink    = '[36;1m'
            Foreground_Black         = '[30m'
            Foreground_Blue          = '[34m'
            Foreground_BrightBlack   = '[90m'
            Foreground_BrightBlue    = '[94m'
            Foreground_BrightCyan    = '[96m'
            Foreground_BrightGreen   = '[92m'
            Foreground_BrightMagenta = '[95m'
            Foreground_BrightRed     = '[91m'
            Foreground_BrightWhite   = '[97m'
            Foreground_BrightYellow  = '[93m'
            Foreground_Cyan          = '[36m'
            Foreground_Green         = '[32m'
            Foreground_Magenta       = '[35m'
            Foreground_Red           = '[31m'
            Foreground_White         = '[37m'
            Foreground_Yellow        = '[33m'
            Formatting_Debug         = '[33;1m'
            Formatting_Error         = '[31;1m'
            Formatting_ErrorAccent   = '[36;1m'
            Formatting_FormatAccent  = '[32;1m'
            Formatting_TableHeader   = '[32;1m'
            Formatting_Verbose       = '[33;1m'
            Formatting_Warning       = '[33;1m'
            Hidden                   = '[8m'
            HiddenOff                = '[28m'
            Italic                   = '[3m'
            ItalicOff                = '[23m'
            OutputRendering          = 'Host'
            Progress_MaxWidth        = 120
            Progress_Style           = '[33;1m'
            Progress_UseOSCIndicator = $False
            Progress_View            = 'Minimal'
            Reset                    = '[0m'
            Reverse                  = '[7m'
            ReverseOff               = '[27m'
            Strikethrough            = '[9m'
            StrikethroughOff         = '[29m'
            Underline                = '[4m'
            UnderlineOff             = '[24m'
        } -TypeName 'Theme.PSStyle', 'System.Management.Automation.PSCustomObject', 'System.Object')
}

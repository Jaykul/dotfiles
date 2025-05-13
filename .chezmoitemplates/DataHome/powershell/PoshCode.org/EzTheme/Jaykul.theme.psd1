
@{
    'Theme.Terminal'        = (PSObject @{
        foreground          = "#FFFCFF"
        background          = "#212021"
        selectionBackground = "#FFFFFF"
        cursorColor         = "#FFFFFF"
        black               = "#212021"
        blue                = "#01A0E4"
        cyan                = "#55C4CF"
        green               = "#01A252"
        purple              = "#A16A94"
        red                 = "#D92D20"
        white               = "#A5A2A2"
        yellow              = "#FBED02"
        brightBlack         = "#493F3F"
        brightBlue          = "#6ECEFF"
        brightCyan          = "#95F2FF"
        brightGreen         = "#6CD18E"
        brightPurple        = "#D29BC6"
        brightRed           = "#FF6E6D"
        brightWhite         = "#FFFCFF"
        brightYellow        = "#FFFF85"
    } -TypeName 'Terminal.ColorScheme', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.WindowsTerminal' = (PSObject @{
        name                = 'Darkly'
        foreground          = "#FFFCFF"
        background          = "#212021"
        selectionBackground = "#FFFFFF"
        cursorColor         = "#FFFFFF"
        black               = "#212021"
        blue                = "#01A0E4"
        cyan                = "#55C4CF"
        green               = "#01A252"
        purple              = "#A16A94"
        red                 = "#D92D20"
        white               = "#A5A2A2"
        yellow              = "#FBED02"
        brightBlack         = "#493F3F"
        brightBlue          = "#6ECEFF"
        brightCyan          = "#95F2FF"
        brightGreen         = "#6CD18E"
        brightPurple        = "#D29BC6"
        brightRed           = "#FF6E6D"
        brightWhite         = "#FFFCFF"
        brightYellow        = "#FFFF85"
    } -TypeName 'WindowsTerminal.ColorScheme', 'Terminal.ColorScheme', 'System.Management.Automation.PSCustomObject', 'System.Object')
    PowerLine               = (PSObject @{
        DefaultCaps                       = '', ''
        DefaultSeparator                  = ''
        Prompt                            = @(
            New-TerminalBlock -Separator ' ' -Content '{ Update-ZLocation $pwd }'
            Show-ElapsedTime -Autoformat -Prefix "&hourglass_done;" -Caps '', ''
            Show-Newline
            Show-NestedPromptLevel -RepeatCharacter "&gear;" -Postfix " "
            Show-HistoryId
            Show-Space
            Show-KubeContext
            Show-AzureContext
            Show-Path -HomeString "&House;" -Separator '' -Depth 3
            Show-Space
            Show-PoshGitStatus -Bg Gray30
            Show-Date -Format "h\:mm" -Prefix "🕒"
            Show-Newline
            New-TerminalBlock -Fg 'Black' -Content ''
        )
        PSReadLineContinuationPrompt      = '█ '
        PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
        PSReadLineErrorColor              = '#FF6347'
        HideErrors                        = $false
        RepeatPrompt                      = 'RecalculateLastLine'
        AutoRefresh                       = 'RecalculateLastLine'
        SetCurrentDirectory               = $false
        Title                             = ScriptBlock '-join @(
            if (Test-Elevation) { "Administrator: " }
            if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - " }
            Convert-Path $pwd
        )'
        DefaultAddIndex                   = 1
    })
    'Theme.PSReadLine'      = (PSObject @{
        CommandColor                = '[38;2;255;230;109m'
        CommentColor                = '[38;2;95;97;103m'
        ContinuationPromptColor     = '[38;2;99;184;255m'
        DefaultTokenColor           = '[38;2;213;206;217m'
        EmphasisColor               = '[38;2;243;156;18m'
        ErrorColor                  = '[4;38;2;255;93;97m'
        InlinePredictionColor       = '[38;2;95;97;103m'
        KeywordColor                = '[38;2;199;77;147m'
        ListPredictionColor         = '[33m'
        ListPredictionSelectedColor = '[48;5;238m'
        ListPredictionTooltipColor  = '[97;2;3m'
        MemberColor                 = '[38;2;43;168;256m'
        NumberColor                 = '[38;2;243;43;23m'
        OperatorColor               = '[38;2;238;93;67m'
        ParameterColor              = '[38;2;143;228;256m'
        SelectionColor              = '[100;38;2;190;190;190m'
        StringColor                 = '[38;2;150;224;114m'
        TypeColor                   = '[38;2;238;93;67m'
        VariableColor               = '[38;2;0;242;178m'
    } -TypeName 'Selected.Microsoft.PowerShell.PSConsoleReadLineOptions', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.PSStyle'         = (PSObject @{
        Background_Black                  = '[40m'
        Background_Blue                   = '[44m'
        Background_BrightBlack            = '[100m'
        Background_BrightBlue             = '[104m'
        Background_BrightCyan             = '[106m'
        Background_BrightGreen            = '[102m'
        Background_BrightMagenta          = '[105m'
        Background_BrightRed              = '[101m'
        Background_BrightWhite            = '[107m'
        Background_BrightYellow           = '[103m'
        Background_Cyan                   = '[46m'
        Background_Green                  = '[42m'
        Background_Magenta                = '[45m'
        Background_Red                    = '[41m'
        Background_White                  = '[47m'
        Background_Yellow                 = '[43m'
        Blink                             = '[5m'
        BlinkOff                          = '[25m'
        Bold                              = '[1m'
        BoldOff                           = '[22m'
        Dim                               = '[2m'
        DimOff                            = '[22m'
        FileInfo_Directory                = '[34m'
        FileInfo_Executable               = '[32m'
        FileInfo_Extension                = @{
            '.7z'     = '[31;1m'
            '.cab'    = '[31;1m'
            '.gz'     = '[31;1m'
            '.nupkg'  = '[31;1m'
            '.ps1'    = '[32m'
            '.ps1xml' = '[33;1m'
            '.psd1'   = '[33;1m'
            '.psm1'   = '[33;1m'
            '.tar'    = '[31;1m'
            '.tgz'    = '[31;1m'
            '.zip'    = '[31;1m'
        }
        FileInfo_SymbolicLink             = '[36;1m'
        Foreground_Black                  = '[30m'
        Foreground_Blue                   = '[34m'
        Foreground_BrightBlack            = '[90m'
        Foreground_BrightBlue             = '[94m'
        Foreground_BrightCyan             = '[96m'
        Foreground_BrightGreen            = '[92m'
        Foreground_BrightMagenta          = '[95m'
        Foreground_BrightRed              = '[91m'
        Foreground_BrightWhite            = '[97m'
        Foreground_BrightYellow           = '[93m'
        Foreground_Cyan                   = '[36m'
        Foreground_Green                  = '[32m'
        Foreground_Magenta                = '[35m'
        Foreground_Red                    = '[31m'
        Foreground_White                  = '[37m'
        Foreground_Yellow                 = '[33m'
        Formatting_CustomTableHeaderLabel = '[32;1;3m'
        Formatting_Debug                  = '[33;1m'
        Formatting_Error                  = '[31;1m'
        Formatting_ErrorAccent            = '[36;1m'
        Formatting_FeedbackAction         = '[97m'
        Formatting_FeedbackName           = '[33m'
        Formatting_FeedbackText           = '[96m'
        Formatting_FormatAccent           = '[32;1m'
        Formatting_TableHeader            = '[32;1m'
        Formatting_Verbose                = '[33;1m'
        Formatting_Warning                = '[33;1m'
        Hidden                            = '[8m'
        HiddenOff                         = '[28m'
        Italic                            = '[3m'
        ItalicOff                         = '[23m'
        OutputRendering                   = 'Host'
        Progress_MaxWidth                 = 120
        Progress_Style                    = '[33;1m'
        Progress_UseOSCIndicator          = $False
        Progress_View                     = 'Minimal'
        Reset                             = '[0m'
        Reverse                           = '[7m'
        ReverseOff                        = '[27m'
        Strikethrough                     = '[9m'
        StrikethroughOff                  = '[29m'
        Underline                         = '[4m'
        UnderlineOff                      = '[24m'
    } -TypeName 'Theme.PSStyle', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.PowerShell'      = (PSObject @{
        Background              = "Black"
        DebugBackgroundColor    = "Black"
        DebugForegroundColor    = "Yellow"
        ErrorAccentColor        = "Cyan"
        ErrorBackgroundColor    = "Black"
        ErrorForegroundColor    = "Red"
        Foreground              = "Gray"
        FormatAccentColor       = "Green"
        ProgressBackgroundColor = "Yellow"
        ProgressForegroundColor = "Black"
        VerboseBackgroundColor  = "Black"
        VerboseForegroundColor  = "Yellow"
        WarningBackgroundColor  = "Black"
        WarningForegroundColor  = "Yellow"
    } -TypeName 'Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy', 'Selected.Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy', 'System.Management.Automation.PSCustomObject', 'System.Object')
}

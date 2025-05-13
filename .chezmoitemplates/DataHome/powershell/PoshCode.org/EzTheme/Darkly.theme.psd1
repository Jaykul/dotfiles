
@{
    PowerLine          = (PSObject @{
            Colors               = @((RgbColor '#333333'), (RgbColor '#424242'), (RgbColor '#8A8A8A'), (RgbColor '#707070'))
            FullColor            = $True
            PowerLineCharacters  = @{
                Separator             = ''
                ColorSeparator        = ''
                ReverseSeparator      = ''
                ReverseColorSeparator = ''
            }
            PowerLineFont        = $True
            Prompt               = @((ScriptBlock 'New-PromptText -Fg Gray95 -Bg Gray40 -EBg VioletRed4 $MyInvocation.HistoryId'), (ScriptBlock ' if ($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } '), (ScriptBlock ' "&Gear;" * $NestedPromptLevel '), (ScriptBlock ' Write-VcsStatus '), (ScriptBlock 'Get-SegmentedPath'), (ScriptBlock '"`t"'), (ScriptBlock ' Get-Elapsed -Trim '), (ScriptBlock 'Get-Date -f "T"'), (ScriptBlock '"`n"'), (ScriptBlock 'New-PromptText -Fg Gray95 -Bg Gray40 "I ${Fg:Green}&hearts;${Fg:Gray95} PS"'))
            PSReadLinePromptText = @('[48;2;102;102;102m[92m♥[38;2;242;242;242m PS[38;2;102;102;102m[49m[0m', '[48;2;102;102;102m[38;2;255;99;71m♥[38;2;242;242;242m PS[38;2;102;102;102m[49m[0m')
            SetCurrentDirectory  = $True
            Title                = (ScriptBlock '')
        } -TypeName 'PowerLine.Theme', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.Terminal'   = (PSObject @{
            background   = (RgbColor '#212021')
            black        = (RgbColor '#212021')
            blue         = (RgbColor '#01A0E4')
            brightBlack  = (RgbColor '#493F3F')
            brightBlue   = (RgbColor '#6ECEFF')
            brightCyan   = (RgbColor '#95F2FF')
            brightGreen  = (RgbColor '#6CD18E')
            brightPurple = (RgbColor '#D29BC6')
            brightRed    = (RgbColor '#FF6E6D')
            brightWhite  = (RgbColor '#FFFCFF')
            brightYellow = (RgbColor '#FFFF85')
            cyan         = (RgbColor '#55C4CF')
            foreground   = (RgbColor '#FFFCFF')
            green        = (RgbColor '#01A252')
            name         = 'EzTheme'
            purple       = (RgbColor '#A16A94')
            red          = (RgbColor '#D92D20')
            white        = (RgbColor '#A5A2A2')
            yellow       = (RgbColor '#FBED02')
        } -TypeName 'Terminal.ColorScheme', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.PSReadLine' = (PSObject @{
            CommandColor                = '[38;2;255;230;109m'
            CommentColor                = '[38;2;95;97;103m'
            ContinuationPromptColor     = '[38;2;0;232;198m'
            DefaultTokenColor           = '[38;2;213;206;217m'
            EmphasisColor               = '[38;2;243;156;18m'
            ErrorColor                  = '[4;38;2;255;93;97m'
            InlinePredictionColor       = '[38;2;95;97;103m'
            KeywordColor                = '[38;2;199;77;147m'
            ListPredictionColor         = '[33m'
            ListPredictionSelectedColor = '[48;5;238m'
            MemberColor                 = '[38;2;43;168;256m'
            NumberColor                 = '[38;2;243;43;23m'
            OperatorColor               = '[38;2;238;93;67m'
            ParameterColor              = '[38;2;143;228;256m'
            SelectionColor              = '[100;38;2;190;190;190m'
            StringColor                 = '[38;2;150;224;114m'
            TypeColor                   = '[38;2;238;93;67m'
            VariableColor               = '[38;2;0;242;178m'
        } -TypeName 'Selected.Microsoft.PowerShell.PSConsoleReadLineOptions', 'System.Management.Automation.PSCustomObject', 'System.Object')
    'Theme.PowerShell' = (PSObject @{
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
}

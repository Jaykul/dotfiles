# In case TERM_PROGRAM supports shell integration, add some things to the prompt/readline before we output the prompt
# https://gitlab.freedesktop.org/Per_Bothner/specifications/blob/master/proposals/semantic-prompts.md
# https://code.visualstudio.com/docs/terminal/shell-integration#_manual-installation
# https://wezfurlong.org/wezterm/shell-integration.html
function global:PSConsoleHostReadLine {
    # End of prompt and start of user input
    # OSC 133 ; B ST
    [Console]::Write("$([char]0x1b)]133;B`a")
    $command = PSReadLine\PSConsoleHostReadLine
    # End of input, and start of output.
    # OSC 133 ; C ST
    [Console]::Write("$([char]0x1b)]133;C`a")
    $command
}

try {
    Add-PowerLineBlock -Index 0 ([PoshCode.TerminalBlocks.Block]@{
        MyInvocation = " " # this is a trick to make sure it doesn't export :)
        Caps         = ""
        Content      = {
            -join @(
                # This doesn't need to run if $MyInvocation.HistoryId hasn't changed...
                if ($MyInvocation.HistoryId -gt 1) {
                    if ($global:LastHistoryId -ne ($global:LastHistoryId = $MyInvocation.HistoryId)) {
                        # Command finished. Exit code only cares if it's zero or not.
                        # OSC 133 ; D [; <ExitCode>] ST
                        "$([char]0x1b)]133;D;$([int]![PoshCode.TerminalBlocks.Block]::LastSuccess)`a"
                    } else {
                        "$([char]0x1b)]133;D;0`a"
                    }
                }

                # Prompt started
                # OSC 633 ; A ST
                "$([char]0x1b)]133;A`a"

                # Update current working directory
                # OSC 7; file://<hostname>/<path> ST
                "$([char]0x1b)]7;file://${env:COMPUTERNAME}/$($ExecutionContext.SessionState.Path.CurrentFileSystemLocation)`a"
            )
        }
        DefaultBackgroundColor = [PoshCode.TerminalBlocks.Block]::DefaultColor
        DefaultForegroundColor = [PoshCode.TerminalBlocks.Block]::DefaultColor
    })

    if ($IsVSCode) {
        # Stop VSCode from screwing with my prompt
        $global:__VSCodeOriginalPrompt = { Write-PowerlinePrompt }
        Add-PowerLineBlock -Index 0 ([PoshCode.TerminalBlocks.Block]@{
            MyInvocation = " " # this is a trick to make sure it doesn't export :)
            Caps         = ""
            Content      = {
                if (($MyInvocation.HistoryId -gt 1) -and ($global:LastHistoryId -ne ($global:LastHistoryId = $MyInvocation.HistoryId))) {
                    # Add command-line to history
                    # OSC 633 ; E [; <CommandLine>] ST
                    "$([char]0x1b)]633;E;$((Get-History -Id ($MyInvocation.HistoryId -1) -ErrorAction Ignore).CommandLine.Replace("\", "\\").Replace("`n", "\x0a").Replace(";", "\x3b"))`a"
                }
            }
            DefaultBackgroundColor = [PoshCode.TerminalBlocks.Block]::DefaultColor
            DefaultForegroundColor = [PoshCode.TerminalBlocks.Block]::DefaultColor
        })
        # Set IsWindows property
        [Console]::Write("$([char]0x1b)]633;P;IsWindows=$($IsWindows)`a")

        # Remap key handlers to the VSCode compatible keybindings
        function Copy-PSReadlineKeyHandler {
            param ([string[]]$OldChord, [string[]]$NewChord)
            try {
                $Handler = Get-PSReadLineKeyHandler -Chord $OldChord | Select-Object -First 1
            } catch [System.Management.Automation.ParameterBindingException] {
                # PowerShell 5.1 ships with PSReadLine 2.0.0 which does not have -Chord,
                # so we check what's bound and filter it.
                $Handler = Get-PSReadLineKeyHandler -Bound | Where-Object -FilterScript { $_.Key -eq $OldChord } | Select-Object -First 1
            }
            if ($Handler) {
                Set-PSReadLineKeyHandler -Chord $NewChord -Function $Handler.Function
            }
        }
        Copy-PSReadlineKeyHandler 'Ctrl+Spacebar' 'F12,a'
        Copy-PSReadlineKeyHandler 'Alt+Spacebar' 'F12,b'
        Copy-PSReadlineKeyHandler 'Shift+Enter' 'F12,c'
        Copy-PSReadlineKeyHandler 'Shift+End' 'F12,d'
    }
} catch {
    Write-Warning "Failed to add terminal blocks to prompt."
}

# Write-Host "Setting PSReadLine Options."
Set-PSReadLineOption -HistoryNoDuplicates:$false -MaximumHistoryCount 8kb -EditMode Windows -PredictionViewStyle ListView

# this nonsense is temporary, just because I'm using a pre-release PSReadLine and I love it...
if ($PSVersionTable.PSVersion -ge "7.1") {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
} else {
    Set-PSReadLineOption -PredictionSource History
}

# Write-Host "Configure PSReadLine KeyHandlers"
# This would be SO MUCH FASTER if PSReadLine had a config file instead of me calling this cmdlet 15 or 20 times
Set-PSReadLineKeyHandler Ctrl+Alt+c CaptureScreen
Set-PSReadLineKeyHandler Ctrl+Shift+r ForwardSearchHistory
Set-PSReadLineKeyHandler Ctrl+r ReverseSearchHistory

Set-PSReadLineKeyHandler Ctrl+DownArrow HistorySearchForward
Set-PSReadLineKeyHandler Ctrl+UpArrow HistorySearchBackward
Set-PSReadLineKeyHandler Ctrl+Home BeginningOfHistory

Set-PSReadLineKeyHandler Ctrl+m SetMark
Set-PSReadLineKeyHandler Ctrl+m ExchangePointAndMark

Set-PSReadLineKeyHandler Ctrl+K KillLine
Set-PSReadLineKeyHandler Ctrl+I Yank

Set-PSReadLineKeyHandler Ctrl+h BackwardDeleteWord
Set-PSReadLineKeyHandler Ctrl+Enter AddLine
Set-PSReadLineKeyHandler Ctrl+Shift+Enter {
    if ([ReadLine]::GetHistoryItems().Count -gt 7.5kb) {
        Set-PSReadLineOption -MaximumHistoryCount 7kb
        Set-PSReadLineOption -MaximumHistoryCount 8kb
    }
    [ReadLine]::AcceptAndGetNext()
}

Set-PSReadLineKeyHandler -Key Alt+w {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [ReadLine]::AddToHistory($line)
    [ReadLine]::RevertLine()
} -Description "Save current line in history but do not execute"

Set-PSReadLineKeyHandler '(', '{', '"', "'" {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar) {
        '(' { [char]')'; break }
        # '{' { [char]'}'; break }
        '[' { [char]']'; break }
        '"' { [char]'"'; break }
        "'" { [char]"'"; break }
    }

    $start = $null
    $length = $null
    [ReadLine]::GetSelectionState([ref]$start, [ref]$length)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    if ($start -ne -1) {
        # Text is selected, wrap it in brackets
        [ReadLine]::Replace($start, $length, $key.KeyChar + $command.SubString($start, $length) + $closeChar)
        [ReadLine]::SetCursorPosition($start + $length + 2)
    } elseif ($cursor -eq 0 -and $command.length) {
        # Cursor's at the start of the command, wrap the whole command
        [ReadLine]::Replace(0, $command.length, $key.KeyChar + $command + $closeChar)
        [ReadLine]::SetCursorPosition($command.length + 2)
    } elseif ($cursor -eq $command.length) {
        # If we're at the end, do a matching pair
        [ReadLine]::Insert("$($key.KeyChar)$closeChar")
        [ReadLine]::SetCursorPosition($cursor + 1)
    } else {
        # Otherwise, just the character they typed
        [ReadLine]::Insert("$($key.KeyChar)")
        [ReadLine]::SetCursorPosition($cursor + 1)
    }
} -Description "Insert matching braces and quotes"

Set-PSReadLineKeyHandler ')', '}', '"', "'" {
    param($key, $arg)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    # If the _next_ character matches this one, just move past it
    if ($command[$cursor] -eq $key.KeyChar) {
        [ReadLine]::SetCursorPosition($cursor + 1)
    } else {
        [ReadLine]::Insert("$($key.KeyChar)")
    }

    # For unmatched closing parenthesis, wrap the whole command
    if ($key.KeyChar -eq ')') {
        $tokens = $null
        $parseError = $null
        $ast = $null
        $cursor = $null
        [ReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseError, [ref]$cursor)
        # but only if it's at the VERY end
        if ($parseError.Extent.Text -eq $key.KeyChar -and $parseError.Extent.EndOffset -eq $cursor) {
            [ReadLine]::Replace(0, $ast.Extent.EndOffset, "($command)" )
            [ReadLine]::SetCursorPosition($command.length + 2)
        }
    }
} -Description "Insert or skip closing brace or wrap!"

Set-PSReadLineKeyHandler Backspace {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0) {
        $toMatch = $null
        if ($cursor -lt $line.Length) {
            switch ($line[$cursor]) {
                # '"' { $toMatch = '"'; break }
                # "'" { $toMatch = "'"; break }
                ')' { $toMatch = '('; break }
                ']' { $toMatch = '['; break }
                '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
            [ReadLine]::Delete($cursor - 1, 2)
        } else {
            [ReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
} -Description "Delete smart quotes/parens/braces"

Set-PSReadLineKeyHandler "Alt+]" {
    param($key, $arg)
    $start = $null
    $length = $null
    [ReadLine]::GetSelectionState([ref]$start, [ref]$length)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    # if there's no selection, these should be set to the cursor
    if ($start -lt 0) { $start = $cursor; $length = 0 }
    $end = $start + $length
    # Write-Host "`e[s`e[0;0H`e[32mStart:$start End:$end Length:$Length `e[u"

    # pretend that entire lines are selected
    if ($start -gt 0) {
        $start = $command.SubString(0, $start).LastIndexOf("`n") + 1
    }
    $end = $end + $command.SubString($end).IndexOf("`n")
    $length = $end - $start
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length `e[u"

    $lines = $command.SubString($start, $length)
    $count = ($lines -split "`n").Count
    # Write-Host "`e[s`e[3;0H`e[36m$lines`e[u"
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length Lines:$Count`e[u"
    [ReadLine]::Replace($start, $length, ($lines -replace "(?m)^", "    "))
    [ReadLine]::SetCursorPosition($start)
    [ReadLine]::SelectLine()

    if ($count -gt 1) {
        while (--$Count) {
            [ReadLine]::SelectForwardChar()
            [ReadLine]::SelectLine()
        }
    }
} -Description "Indent selected lines"

Set-PSReadLineKeyHandler "Alt+[" {
    param($key, $arg)
    $start = $null
    $length = $null
    [ReadLine]::GetSelectionState([ref]$start, [ref]$length)

    $command = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$command, [ref]$cursor)

    # if there's no selection, these should be set to the cursor
    if ($start -lt 0) { $start = $cursor; $length = 0 }
    $end = $start + $length
    # Write-Host "`e[s`e[0;0H`e[32mStart:$start End:$end Length:$Length `e[u"

    # pretend that entire lines are selected
    if ($start -gt 0) {
        $start = $command.SubString(0, $start).LastIndexOf("`n") + 1
    }
    $end = $end + $command.SubString($end).IndexOf("`n")
    $length = $end - $start
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length `e[u"

    $lines = $command.SubString($start, $length)
    $count = ($lines -split "`n").Count
    # Write-Host "`e[s`e[3;0H`e[36m$lines`e[u"
    # Write-Host "`e[s`e[2;0H`e[34mStart:$start End:$end Length:$Length Lines:$Count`e[u"

    [ReadLine]::Replace($start, $length, ($lines -replace "(?m)^    ", ""))
    [ReadLine]::SetCursorPosition($start)
    [ReadLine]::SelectLine()

    if ($count -gt 1) {
        while (--$Count) {
            [ReadLine]::SelectForwardChar()
            [ReadLine]::SelectLine()
        }
    }
} -Description "Unindent selected lines"

# Cycle through arguments on current line and select the text. This makes it easier to quickly change the argument if re-running a previously run command from the history
# or if using a psreadline predictor. You can also use a digit argument to specify which argument you want to select, i.e. Alt+1, Alt+a selects the first argument
# on the command line.
Set-PSReadLineKeyHandler -Key "Alt+j" {
    param($key, $arg)

    $tokens = $null
    $parseError = $null
    $ast = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseError, [ref]$cursor)

    $asts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
            $args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset -and
            $args[0].Extent -notmatch "^--"
        }, $true)

    if ($asts.Count -eq 0) {
        [ReadLine]::Ding()
        return
    }

    $nextAst = $null

    if ($null -ne $arg) {
        $nextAst = $asts[$arg - 1]
    } else {
        foreach ($ast in $asts) {
            if ($ast.Extent.StartOffset -ge $cursor) {
                $nextAst = $ast
                break
            }
        }

        if (!$nextAst) {
            $nextAst = $asts[0]
        }
    }

    $startOffsetAdjustment = 0
    $endOffsetAdjustment = 0

    if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
        $startOffsetAdjustment = 1
        $endOffsetAdjustment = 2
    }

    [ReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
    [ReadLine]::SetMark($null, $null)
    [ReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
} -Description "Select next argument in the command line (or use a digit to select by index)"

Set-PSReadLineKeyHandler "alt+k" {
    $Suggestion = Get-History -Count 10 | Sort-Object Id -Descending | ForEach-Object {
        $tokens = $null
        $parseError = $null
        $Ast = [System.Management.Automation.Language.Parser]::ParseInput($_.CommandLine, [ref]$tokens, [ref]$parseError)

        if ($Kast = $Ast.Find({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].CommandElements[0].Value -eq "kubectl" -and
                    $args[0].CommandElements.Value -eq "--context" #-and
                    #$args[0].CommandElements.Value -eq "--namespace"
                }, $true)) {
            $Parameter = $null
            foreach ($param in $kast.CommandElements.Where{ $_.StringConstantType -eq "BareWord" }.Value) {
                if ($Parameter -eq "Context") { $Context = $param; $Parameter = $null; continue }
                if ($Parameter -eq "Namespace") { $Namespace = $param; $Parameter = $null; continue }
                if ($param -in "--context", "-c") { $Parameter = "Context"; continue }
                elseif ($param -in "--namespace", "-n") { $Parameter = "Namespace"; continue }
            }
            "kubectl --context $Context --namespace $Namespace"
        }
    } | Select-Object -First 1

    if (!$Suggestion) {
        $context, $namespace = (kubectl config view --minify --template '{{"{{range .contexts}}{{.name}}{{if .context.namespace}}/{{.context.namespace}}{{end}}{{end}}"}}').Split("/")
        $Suggestion = "kubectl --context $context --namespace $namespace "
    }

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # If the line is empty or just kubectl, insert the suggestion
    if (!$line -or $line -eq "kubectl ") {
        # Inject the start of a kubectl command with the explicit context
        [ReadLine]::Replace(0, $line.Length, $suggestion)
        if ($context -match "prd") {
            # audibly warn me
            Write-Host -NoNewline "`e[3;3;11;7;11;7,~"
        }
        if ($namespace) {
            # Select the namespace at the end, so you can replace it
            [ReadLine]::SetCursorPosition($suggestion.Length - $namespace.Length)
            [ReadLine]::SelectForwardChar($null, $namespace.Length)
        }
        # If I press it twice ... take off the parameters
    } elseif ($line -eq $suggestion) {
        [ReadLine]::Replace(0, $line.Length, "kubectl ")
        [ReadLine]::SetCursorPosition(8)
    }
} -Description "macro: kubectl --context <current-context> --namespace demos"

Set-PSReadLineKeyHandler "Alt+x" -Description "Expand aliases" {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
    [array]::Reverse($tokens)
    foreach ($token in $tokens) {
        if ($token.TokenFlags -band [System.Management.Automation.Language.TokenFlags]::CommandName) {
            $command = $token.Extent.Text
            $limit = 5 # recurse aliases of aliases, but don't get carried away
            while ($command -and ($alias = $ExecutionContext.InvokeCommand.GetCommand($command, 'Alias'))) {
                if ($alias.ResolvedCommandName) {
                    $command = $alias.ResolvedCommandName
                    if (($limit--) -gt 0) {
                        continue
                    }
                }
                break
            }

            $extent = $token.Extent
            $length = $extent.EndOffset - $extent.StartOffset
            [ReadLine]::Replace($extent.StartOffset, $length, $command)
        }
    }
    [ReadLine]::GetBufferState([ref]$ast, [ref]$cursor)
    [ReadLine]::SetCursorPosition($ast.Length)
}

Set-PSReadLineKeyHandler "Alt+x" -Description "Expand aliases" {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [ReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
    [array]::Reverse($tokens)
    foreach ($token in $tokens) {
        if ($token.TokenFlags -band [System.Management.Automation.Language.TokenFlags]::CommandName) {
            $command = $token.Extent.Text
            $limit = 5 # recurse aliases of aliases, but don't get carried away
            while ($command -and ($alias = $ExecutionContext.InvokeCommand.GetCommand($command, 'Alias'))) {
                if ($alias.ResolvedCommandName) {
                    $command = $alias.ResolvedCommandName
                    if (($limit--) -gt 0) {
                        continue
                    }
                }
                break
            }

            $extent = $token.Extent
            $length = $extent.EndOffset - $extent.StartOffset
            [ReadLine]::Replace($extent.StartOffset, $length, $command)
        }
    }
    [ReadLine]::GetBufferState([ref]$ast, [ref]$cursor)
    [ReadLine]::SetCursorPosition($ast.Length)
}
<#
Set-PSReadLineKeyHandler -Chord 'F12,b' {
    $commandLine = ""
    $cursorIndex = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$commandLine, [ref]$cursorIndex)
    $completionPrefix = $commandLine

    $result = "`e]633;Completions"
    if ($completionPrefix.Length -gt 0) {
        $completions = TabExpansion2 -inputScript $completionPrefix -cursorColumn $cursorIndex
        if ($null -ne $completions.CompletionMatches) {
            $result += ";$($completions.ReplacementIndex);$($completions.ReplacementLength);$($cursorIndex);"
            $result += $completions.CompletionMatches | ConvertTo-Json -Compress
        }
    }
    $result += "`a"

    Write-Host -NoNewLine $result
} -Description "Send completions to terminal"
#>
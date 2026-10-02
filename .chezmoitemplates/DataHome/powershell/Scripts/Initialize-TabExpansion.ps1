function global:TabExpansion2 {
    [CmdletBinding(DefaultParameterSetName = 'ScriptInputSet')]
    param (
        [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory, Position = 0)]
        [string]
        $inputScript,

        [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory, Position = 1)]
        [int]
        $cursorColumn,

        [Parameter(ParameterSetName = 'AstInputSet', Mandatory, Position = 0)]
        [System.Management.Automation.Language.Ast]
        $ast,

        [Parameter(ParameterSetName = 'AstInputSet', Mandatory, Position = 1)]
        [System.Management.Automation.Language.Token[]]
        $tokens,

        [Parameter(ParameterSetName = 'AstInputSet', Mandatory, Position = 2)]
        [System.Management.Automation.Language.IScriptPosition]
        $positionOfCursor,

        [Parameter(ParameterSetName = 'ScriptInputSet', Position = 2)]
        [Parameter(ParameterSetName = 'AstInputSet', Position = 3)]
        [Hashtable]
        $options = $null
    )

    if ($null -ne $options) {
        $options += $tabExpansionOptions
    } else {
        $options = $tabExpansionOptions
    }

    if ($psCmdlet.ParameterSetName -eq 'ScriptInputSet') {
        $results = [System.Management.Automation.CommandCompletion]::CompleteInput(
            <#inputScript#>				$inputScript,
            <#cursorColumn#>				$cursorColumn,
            <#options#>				$options)
    } else {
        $results = [System.Management.Automation.CommandCompletion]::CompleteInput(
            <#ast#>				$ast,
            <#tokens#>				$tokens,
            <#positionOfCursor#>				$positionOfCursor,
            <#options#>				$options)
    }

    if ($results.CompletionMatches.Count -eq 0) {
        # Built-in didn't succeed, try our own completions here.
        if ($psCmdlet.ParameterSetName -eq 'ScriptInputSet') {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($inputScript, [ref]$tokens, [ref]$null)
        } else {
            $cursorColumn = $positionOfCursor.Offset
        }

        # workaround PowerShell bug that case it to not invoking native completers for - or --
        # making it hard to complete options for many commands
        $nativeCommandResults = TryNativeCommandOptionCompletion -ast $ast -offset $cursorColumn
        if ($null -ne $nativeCommandResults) {
            $results.ReplacementIndex = $nativeCommandResults.ReplacementIndex
            $results.ReplacementLength = $nativeCommandResults.ReplacementLength
            if ($results.CompletionMatches.IsReadOnly) {
                # Workaround where PowerShell returns a readonly collection that we need to add to.
                $collection = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.CompletionResult]
                $results.GetType().GetProperty('CompletionMatches').SetValue($results, $collection)
            }
            $nativeCommandResults.Results | ForEach-Object {
                $results.CompletionMatches.Add($_)
            }
        }

        $attributeResults = TryAttributeArgumentCompletion $ast $cursorColumn
        if ($null -ne $attributeResults) {
            $results.ReplacementIndex = $attributeResults.ReplacementIndex
            $results.ReplacementLength = $attributeResults.ReplacementLength
            if ($results.CompletionMatches.IsReadOnly) {
                # Workaround where PowerShell returns a readonly collection that we need to add to.
                $collection = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.CompletionResult]
                $results.GetType().GetProperty('CompletionMatches').SetValue($results, $collection)
            }
            $attributeResults.Results | ForEach-Object {
                $results.CompletionMatches.Add($_)
            }
        }
    }

    if ($options.ExcludeHiddenFiles) {
        foreach ($result in @($results.CompletionMatches)) {
            if ($result.ResultType -eq [System.Management.Automation.CompletionResultType]::ProviderItem -or
                $result.ResultType -eq [System.Management.Automation.CompletionResultType]::ProviderContainer) {
                try {
                    $null = Get-Item -LiteralPath $result.CompletionText -ErrorAction Stop
                } catch {
                    # If Get-Item w/o -Force fails, it is probably hidden, so exclude the result
                    $null = $results.CompletionMatches.Remove($result)
                }
            }
        }
    }
    if ($options.AppendBackslash -and
        $results.CompletionMatches.ResultType -contains [System.Management.Automation.CompletionResultType]::ProviderContainer) {
        foreach ($result in @($results.CompletionMatches)) {
            if ($result.ResultType -eq [System.Management.Automation.CompletionResultType]::ProviderContainer) {
                $completionText = $result.CompletionText
                $lastChar = $completionText[-1]
                $lastIsQuote = ($lastChar -eq '"' -or $lastChar -eq "'")
                if ($lastIsQuote) {
                    $lastChar = $completionText[-2]
                }

                if ($lastChar -ne '\') {
                    $null = $results.CompletionMatches.Remove($result)

                    if ($lastIsQuote) {
                        $completionText =
                        $completionText.Substring(0, $completionText.Length - 1) +
                        '\' + $completionText[-1]
                    } else {
                        $completionText = $completionText + '\'
                    }

                    $updatedResult = New-Object System.Management.Automation.CompletionResult `
                    ($completionText, $result.ListItemText, $result.ResultType, $result.ToolTip)
                    $results.CompletionMatches.Add($updatedResult)
                }
            }
        }
    }

    if ($results.CompletionMatches.Count -eq 0) {
        # No results, if this module has overridden another TabExpansion2 function, call it
        # but only if it's not the built-in function (which we assume if function isn't
        # defined in a file.
        if ($null -ne $oldTabExpansion2 -and $null -ne $oldTabExpansion2.File) {
            return (& $oldTabExpansion2 @PSBoundParameters)
        }
    }

    return $results
}

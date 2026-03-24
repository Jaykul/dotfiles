# carapace helper functions
Function get-env([string]$name) { Get-Item "env:$name" }
Function set-env([string]$name, [string]$value) { Set-Item "env:$name" "$value" }
Function unset-env([string]$name) { Remove-Item "env:$name" }
$CarapaceCommands = 'age', 'az', 'az', 'bash', 'bash', 'bat', 'brotli', 'bun', 'bunx', 'carapace', 'code-insiders', 'code-insiders', 'curl', 'delta', 'docker', 'docker', 'docker-compose', 'docker-compose', 'expand', 'fd', 'find', 'ftp', 'fzf', 'gh', 'git', 'gitk', 'go', 'gofmt', 'gopls', 'gradle', 'helm', 'helm', 'hostname', 'http', 'https', 'install', 'jq', 'kubectl', 'kubectl', 'kubectl', 'lnav', 'more', 'ng', 'ng', 'node', 'npm', 'npm', 'pandoc', 'pandoc', 'ping', 'pip', 'pnpm', 'python', 'python', 'rg', 'scp', 'sftp', 'shutdown', 'sort', 'ssh', 'ssh-agent', 'ssh-keygen', 'staticcheck', 'tar', 'tig', 'tmux', 'tree', 'viu', 'wezterm', 'whoami', 'zoxide'
Register-ArgumentCompleter -Native -CommandName $CarapaceCommands -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $completer = $commandAst.CommandElements[0].Value
    carapace $completer powershell | Out-String | Invoke-Expression
    & (Get-Item "Function:_${completer}_completer") $wordToComplete $commandAst $cursorPosition
}

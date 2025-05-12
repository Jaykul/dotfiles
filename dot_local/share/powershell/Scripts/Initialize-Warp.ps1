Remove-Module -Name PSReadline;
$global:_warpOriginalPrompt = $function:global:prompt;
if ($PSEdition -eq 'Desktop' -or $IsWindows) {
    $global:_warp_PSProcessExecPolicy = $(Get-ExecutionPolicy -Scope Process)
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
}
function prompt {
    $username = [Environment]::UserName
    $epoch = [int](New-TimeSpan -Start (Get-Date '1970-01-01') -End (Get-Date)).TotalSeconds
    $random = Get-Random -Maximum 32768
    $global:_warpSessionId = [int64]"$epoch$random"
    $msg = ConvertTo-Json -Compress -InputObject @{
        hook  = 'InitShell'
        value = @{
            session_id = $_warpSessionId
            shell      = 'pwsh'
            user       = $username
            hostname   = [System.Net.Dns]::GetHostName()
        }
    }
    $encodedMsg = [BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($msg)).Replace('-', '')
    $oscStart = "$([char]0x1b)]9278;"
    $oscEnd = "`a"
    $oscJsonMarker = 'd'
    $oscParameterSeparator = ';'
    Write-Host "${oscStart}${oscJsonMarker}${oscParameterSeparator}$encodedMsg${oscEnd}"
    return $null
}
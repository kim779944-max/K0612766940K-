# usage: live.ps1 -cmd js|shot|nav|file -arg ... [-arg2 ...]
param([string]$cmd, [string]$arg = '', [string]$arg2 = '')
. "$PSScriptRoot\cdp.ps1"
Connect-Cdp 9333
Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null; Start-Sleep -Milliseconds 400
switch ($cmd) {
  'nav' { Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null; Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $arg) } | Out-Null }
  'js' { $v = Invoke-Js ([IO.File]::ReadAllText($arg, [Text.Encoding]::UTF8)) -await; Write-Output $v }
  'shot' { Save-Screenshot $arg }
  'file' { Set-FileInput $arg @($arg2) }
}
$global:cdpWs.Dispose()

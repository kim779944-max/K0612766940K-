param([string]$page, [string]$out, [string]$js = '')
. "$PSScriptRoot\cdp.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..\..").Path
Start-CdpChrome 9333 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl (Join-Path $root $page)) } | Out-Null
  Start-Sleep -Seconds 3
  if ($js) { $v = Invoke-Js $js -await; Write-Output $v; Start-Sleep -Milliseconds 1500 }
  Save-Screenshot $out
} finally { Stop-CdpChrome }

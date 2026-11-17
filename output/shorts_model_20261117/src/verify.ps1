# Opens a recorded short in Chrome, reports duration/size/audio, and screenshots frames at given times.
param([string]$file, [string]$times = '1,5,10', [string]$outPrefix)
. "$PSScriptRoot\cdp.ps1"
Start-CdpChrome 9336 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 540; height = 960; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Send-Cdp 'Page.navigate' @{ url = ((To-FileUrl "$PSScriptRoot\verify.html") + "?f=../" + $file) } | Out-Null
  Start-Sleep -Seconds 3
  Write-Output ("info " + (Invoke-Js "JSON.stringify(info())"))
  Write-Output ("audio " + (Invoke-Js "audioCheck().then(JSON.stringify)" -await))
  foreach ($t in $times.Split(',')) {
    $ct = Invoke-Js "seek($t)" -await
    Save-Screenshot ("{0}_{1}s.png" -f $outPrefix, $t)
    Write-Output ("frame t=$t actual=$ct")
  }
} finally { Stop-CdpChrome }

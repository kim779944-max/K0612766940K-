# Renders player.html?s=<short> at given timeline seconds and saves the 1080x1920 canvas as PNG (no recording)
param([string]$short, [string]$times, [string]$outPrefix)
. "$PSScriptRoot\cdp.ps1"
Start-CdpChrome 9338 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 600; height = 1100; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Send-Cdp 'Page.navigate' @{ url = ((To-FileUrl "$PSScriptRoot\player.html") + "?s=$short") } | Out-Null
  for ($i = 0; $i -lt 80; $i++) { Start-Sleep -Milliseconds 500; if (Invoke-Js "!!window.READY") { break } }
  Write-Output ("total=" + (Invoke-Js "window.TOTAL"))
  Write-Output (Invoke-Js "JSON.stringify(window.CUESHEET)")
  foreach ($t in $times.Split(',')) {
    Invoke-Js "renderAt($t)" -await | Out-Null
    $b64 = Invoke-Js "cv.toDataURL('image/png').split(',')[1]"
    [IO.File]::WriteAllBytes(("{0}_{1}s.png" -f $outPrefix, $t), [Convert]::FromBase64String($b64))
  }
} finally { Stop-CdpChrome }

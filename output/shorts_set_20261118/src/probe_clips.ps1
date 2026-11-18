param([string]$outDir)
. "$PSScriptRoot\cdp.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..\..").Path
Start-CdpChrome 9337 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 540; height = 960; deviceScaleFactor = 1; mobile = $false } | Out-Null
  foreach ($n in 'short1_converter_00','short2_theview_00','short3_saycap_00') {
    Send-Cdp 'Page.navigate' @{ url = ((To-FileUrl "$PSScriptRoot\verify.html") + "?f=" + (To-FileUrl "$root\assets\model_clips\$n.mp4")) } | Out-Null
    Start-Sleep -Seconds 3
    Write-Output ("$n info " + (Invoke-Js "JSON.stringify(info())"))
    Write-Output ("$n audio " + (Invoke-Js "audioCheck().then(JSON.stringify)" -await))
    foreach ($t in 0.5, 4) { Invoke-Js "seek($t)" -await | Out-Null; Save-Screenshot ("{0}\{1}_{2}s.png" -f $outDir, $n, $t) }
  }
} finally { Stop-CdpChrome }

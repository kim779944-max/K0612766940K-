# Plays player.html?s=<short> in real time inside headless Chrome, records canvas+narration with MediaRecorder, saves the file.
param([string]$short, [string]$outName, [string]$outDir = "$PSScriptRoot\..")
. "$PSScriptRoot\cdp.ps1"
Start-CdpChrome 9335 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 600; height = 1100; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Send-Cdp 'Page.navigate' @{ url = ((To-FileUrl "$PSScriptRoot\player.html") + "?s=$short") } | Out-Null
  for ($i = 0; $i -lt 120; $i++) { Start-Sleep -Milliseconds 500; if (Invoke-Js "!!window.READY") { break } }
  Write-Output ("ready, total=" + (Invoke-Js "window.TOTAL"))
  Invoke-Js "ctx.resume().then(()=>start(true)).then(()=>window.OUT_LEN)" -await | Out-Null
  $mime = Invoke-Js "window.REC_MIME"; $len = [int](Invoke-Js "window.OUT_LEN")
  Write-Output ("mime=$mime base64len=$len maxzoom=" + (Invoke-Js "window.MAXZ_USED"))
  $sb = New-Object Text.StringBuilder
  for ($o = 0; $o -lt $len; $o += 4000000) { [void]$sb.Append((Invoke-Js "window.OUT.substr($o, 4000000)")) }
  $ext = if ($mime -match 'mp4') { 'mp4' } else { 'webm' }
  $out = Join-Path $outDir ($outName + "." + $ext)
  [IO.File]::WriteAllBytes($out, [Convert]::FromBase64String($sb.ToString()))
  [IO.File]::WriteAllText((Join-Path $outDir ("cuesheet_" + $short + ".json")), (Invoke-Js "JSON.stringify({total:window.TOTAL, maxZoom:window.MAXZ_USED, mime:window.REC_MIME, cues:window.CUESHEET}, null, 1)"), (New-Object Text.UTF8Encoding($false)))
  Write-Output ("saved " + $out + " " + (Get-Item $out).Length)
} finally { Stop-CdpChrome }

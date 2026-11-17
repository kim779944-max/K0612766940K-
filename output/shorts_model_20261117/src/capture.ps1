# Drives the real app page through states and screenshots each (390x844 @2x).
# usage: capture.ps1 -steps steps_x.json -outDir ..\frames\x
param([string]$steps, [string]$outDir)
. "$PSScriptRoot\cdp.ps1"
$root = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$work = (Resolve-Path "$PSScriptRoot\..\work").Path
New-Item -ItemType Directory -Force $outDir | Out-Null
$cfg = [IO.File]::ReadAllText((Resolve-Path $steps), [Text.Encoding]::UTF8) | ConvertFrom-Json
Start-CdpChrome 9334 | Out-Null
$meta = @()
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'DOM.enable' | Out-Null
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl (Join-Path $root $cfg.page)) } | Out-Null
  Start-Sleep -Seconds 3
  Invoke-Js "window.__sl = ms => new Promise(r => setTimeout(r, ms)); 1" | Out-Null
  foreach ($s in $cfg.steps) {
    if ($s.file) { Set-FileInput $s.file.sel @((Join-Path $work $s.file.path)); Start-Sleep -Milliseconds 300 }
    if ($s.js) { Invoke-Js ("(async()=>{ const sleep=window.__sl; " + $s.js + " ; return 1 })()") -await | Out-Null }
    Start-Sleep -Milliseconds ([int]($s.wait + 0))
    $mj = "[]"; if ($s.marks -and @($s.marks).Count -gt 0) { $mj = ConvertTo-Json -InputObject @($s.marks) -Compress -Depth 5 }
    $rects = Invoke-Js ("JSON.stringify(" + $mj + ".map(m=>{const e=m.sel?document.querySelector(m.sel):null; if(!e) return null; const r=e.getBoundingClientRect(); return {kind:m.kind, x:r.x, y:r.y, w:r.width, h:r.height}}))")
    $png = Join-Path $outDir ($s.name + '.png')
    Save-Screenshot $png
    $meta += ('"' + $s.name + '":' + $rects)
    Write-Output ("captured " + $s.name + " " + $rects)
  }
} finally { Stop-CdpChrome }
[IO.File]::WriteAllText((Join-Path $outDir 'rects.json'), ('{' + ($meta -join ',') + '}'), (New-Object Text.UTF8Encoding($false)))

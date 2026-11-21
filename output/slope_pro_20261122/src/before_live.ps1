# 고치기 전 라이브 화면(390px) — 보고서 '전' 근거
. "$PSScriptRoot\..\..\slope3d_20261121\src\lib3d.ps1"
$Shots = (Resolve-Path "$PSScriptRoot\..\shots").Path
try {
  Open-Page 'https://autooneclick.com/slope/?v=before20261122' 9462
  $null = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 30000
  $null = Wait-Js "window.__KTS_ST().pcLoaded" 15000
  Start-Sleep -Milliseconds 2500
  Write-Output (Invoke-Js "JSON.stringify({st:window.__KTS_ST(),px:window.__KTS_PX&&window.__KTS_PX(),stat:typeof window.__KTS_PXSTAT})")
  Shot (Join-Path $Shots 'before_390.png')
  Shot-Clip (Join-Path $Shots 'before_390_map.png') '.mapwrap'
} finally { Stop-CdpChrome }

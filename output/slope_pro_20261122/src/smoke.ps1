param([string]$url = '')
. "$PSScriptRoot\..\..\slope3d_20261121\src\lib3d.ps1"
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
if (-not $url) { $url = To-FileUrl (Join-Path $OcRoot 'slope\index.html') }
$Shots = (Resolve-Path "$PSScriptRoot\..\shots").Path
try {
  Open-Page $url 9461
  $ok = Wait-Js "!!(window.__KTS_ST && document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 25000
  Write-Output ("terrain ready=" + $ok)
  $null = Wait-Js "window.__KTS_ST().pcLoaded" 12000
  Start-Sleep -Milliseconds 1500
  Write-Output (Invoke-Js "JSON.stringify(window.__KTS_PX())")
  Write-Output (Invoke-Js "JSON.stringify(window.__KTS_PXSTAT())")
  Write-Output (Invoke-Js "JSON.stringify(window.__KTS_ST())")
  Shot-Clip (Join-Path $Shots '_smoke_map.png') '.mapwrap'
  Write-Output (Invoke-Js "JSON.stringify(window.__KTS_ERR)")
  Evts-Summary | ConvertTo-Json -Compress
  $global:EVTS | Select-Object -First 12 | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(400, $_.text.Length)) }
} finally { Stop-CdpChrome }

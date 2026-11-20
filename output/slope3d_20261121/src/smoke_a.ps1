param([string]$extra = '')
. "$PSScriptRoot\lib3d.ps1"
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$url = To-FileUrl (Join-Path $OcRoot 'slope\index.html')
try {
  Open-Page $url 9361 $extra
  $ok = Wait-Js "!!(window.__KTS_ST && document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 25000
  Write-Output ("terrain ready=" + $ok)
  Write-Output ("webgl=" + (Invoke-Js "(()=>{try{return !!document.createElement('canvas').getContext('webgl')}catch(e){return 'ex'}})()"))
  TapSel '#vmode button[data-v="3d"]' | Out-Null
  Start-Sleep -Milliseconds 1500
  Write-Output (Invoke-Js "JSON.stringify(window.__KTS_3D())")
  Start-Sleep -Milliseconds 4000
  Write-Output (Invoke-Js "JSON.stringify(window.__KTS_3D())")
  Write-Output (Invoke-Js "JSON.stringify(window.__KTS_ERR)")
  Shot (Join-Path $PSScriptRoot '..\shots\_smoke.png')
  Evts-Summary | ConvertTo-Json -Compress
  $global:EVTS | Select-Object -First 12 | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(220, $_.text.Length)) }
} finally { Stop-CdpChrome }

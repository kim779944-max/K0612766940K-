. "$PSScriptRoot\lib.ps1"
Start-Serve
try {
  Open-Page ($global:Base + 'slope/') 9378
  $ok = Wait-Js "!!(window.__KTS_ST && document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 30000
  Write-Output ("ready=" + $ok)
  Start-Sleep -Milliseconds 1500
  ShotP '_slope_arrow.png'
  Write-Output (J "window.__KTS_PXSET('px',3); return 1")
  Start-Sleep -Milliseconds 800
  Write-Output (J "return JSON.stringify(window.__KTS_PX())")
  ShotP '_slope_px3.png'
  $r = Rect '#mapcv'
  Tap ($r.x + $r.w * 0.6) ($r.y + $r.h * 0.45)
  Start-Sleep -Milliseconds 400
  Write-Output (J "return document.getElementById('pxTip').textContent+' | '+JSON.stringify(window.__KTS_PX().last)+' | addr='+document.querySelector('#resTag').textContent")
  Write-Output ("SW " + (SW))
  Write-Output ((Evts-Summary) | ConvertTo-Json -Compress)
  $global:EVTS | Select-Object -First 6 | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(250, $_.text.Length)) }
} finally { Stop-CdpChrome }

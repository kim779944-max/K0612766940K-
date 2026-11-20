# 실서비스(autooneclick.com) 확인 — 세 페이지 오류·390px, 경사도 3D 실제 도메인에서 위성·필지
. "$PSScriptRoot\lib3d.ps1"
$OutDir = (Resolve-Path "$PSScriptRoot\..").Path; $Shots = Join-Path $OutDir 'shots'
$R = [ordered]@{}
Open-Page 'https://autooneclick.com/slope/' 9391
try {
  $null = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 30000
  $null = Wait-Js "window.__KTS_ST().pcLoaded" 15000
  Start-Sleep -Milliseconds 2000
  Invoke-Js "window.__clk=performance.now(); document.querySelector('#vmode button[data-v=""3d""]').click(); 1" | Out-Null
  $null = Wait-Js "window.__KTS_3D().st.draws>0" 5000
  $R.slope_firstFrameMs = Invoke-Js "Math.round(window.__KTS_3D().st.firstAt-window.__clk)"
  $null = Wait-Js "window.__KTS_3D().st.tilesOk+window.__KTS_3D().st.tilesFail>=window.__KTS_3D().st.tilesTotal" 15000
  Start-Sleep -Milliseconds 800
  Invoke-Js "window.__KTS_3D_SET({yaw:35,pitch:32})" | Out-Null
  $R.slope_3d = Invoke-Js "JSON.stringify(window.__KTS_3D())"
  $R.slope_inf = Invoke-Js "document.querySelector('#inf3d').textContent"
  Shot (Join-Path $Shots 'LIVE_slope_3d.png')
  Invoke-Js "window.__KTS_3D_SET({spinMs:3000})" | Out-Null; Start-Sleep -Milliseconds 3500
  $R.slope_frameMedianMs = Invoke-Js "window.__KTS_3D().frameMedianMs"
  TapSel '#vmode button[data-v="2d"]' | Out-Null; Start-Sleep -Milliseconds 800
  $R.slope_back2d = Invoke-Js "JSON.stringify(window.__KTS_ST())"
  $R.slope_sw = Invoke-Js "document.documentElement.scrollWidth"
  $R.slope_err = Invoke-Js "JSON.stringify(window.__KTS_ERR)"
  $R.slope_evts = (Evts-Summary); $R.slope_evtList = @($global:EVTS | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(200, $_.text.Length)) })
  Clear-Evts
  Go-Url 'https://autooneclick.com/sign/' 3500
  $R.sign = Invoke-Js "JSON.stringify({sw:document.documentElement.scrollWidth,slots:!!window.KTSSlots,box:!!document.querySelector('#stampBox .ksl-pan'),fix:!!document.querySelector('#sigFix')})"
  Shot (Join-Path $Shots 'LIVE_sign_top.png')
  $R.sign_evts = (Evts-Summary); $R.sign_evtList = @($global:EVTS | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(200, $_.text.Length)) })
  Clear-Evts
  Go-Url 'https://autooneclick.com/?ref=LIVE2345' 3500
  $id = Invoke-Js "document.querySelector('#plist [data-fav]').dataset.fav"
  Invoke-Js ("document.querySelector('#plist [data-fav=""" + $id + """]').click();1") | Out-Null; Start-Sleep -Milliseconds 300
  Invoke-Js "document.querySelector('.ksl-dim [data-a=""ok""]').click();1" | Out-Null; Start-Sleep -Milliseconds 300
  Invoke-Js ("document.querySelector('#plist [data-fav=""" + $id + """]').click();1") | Out-Null; Start-Sleep -Milliseconds 300
  $R.index = Invoke-Js "JSON.stringify({sw:document.documentElement.scrollWidth,ref:(document.querySelector('#refNote')||{}).innerText,items:FAVSL.items().length,cap:FAVSL.cap(),unpinToast:(document.querySelector('.ksl-toast')||{}).textContent})"
  Shot (Join-Path $Shots 'LIVE_index_ref.png')
  $R.index_evts = (Evts-Summary); $R.index_evtList = @($global:EVTS | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(200, $_.text.Length)) })
} finally { Stop-CdpChrome }
$out = Join-Path $OutDir 'verify_live_result.json'
$R | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $out
Get-Content $out -Raw -Encoding UTF8

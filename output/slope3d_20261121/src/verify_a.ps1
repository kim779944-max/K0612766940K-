# 과제 A(121번) 경사도 3D 검수 — A1~A10 (헤드리스 크롬 390x844 @2x)
. "$PSScriptRoot\lib3d.ps1"
. "$PSScriptRoot\px.ps1"
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$Shots = (Resolve-Path "$PSScriptRoot\..\shots").Path
$R = [ordered]@{}

# ---------- A1: 13개 함수 본문 바이트 비교 (149a7de vs 현재) ----------
function Get-FnBody([string]$src, [string]$name) {
  $m = [regex]::Match($src, '(?m)^function ' + [regex]::Escape($name) + '\(')
  if (-not $m.Success) { return $null }
  $i = $src.IndexOf('{', $m.Index); $d = 0
  for ($k = $i; $k -lt $src.Length; $k++) { $c = $src[$k]; if ($c -eq '{') { $d++ } elseif ($c -eq '}') { $d--; if ($d -eq 0) { return $src.Substring($m.Index, $k - $m.Index + 1) } } }
  return $null
}
Push-Location $OcRoot
$old = (git show 149a7de:slope/index.html) -join "`n"
Pop-Location
$new = ([IO.File]::ReadAllText((Join-Path $OcRoot 'slope\index.html'), [Text.Encoding]::UTF8)) -replace "`r`n", "`n"
$fns = 'render','scene','drawBase','drawSlopeImg','drawContours','drawGridLines','drawVWImg','drawParcelHL','drawMarker','drawProfile','analyze','paintResult','verdictOf'
$a1 = @(); foreach ($f in $fns) { $a = Get-FnBody $old $f; $b = Get-FnBody $new $f; $a1 += [pscustomobject]@{ fn = $f; len = $(if ($a) { $a.Length } else { -1 }); same = ($a -ne $null -and $a -eq $b) } }
$R.A1 = $a1
$consts = @('var ZMIN=13, ZMAX=20, TZMAX=19;', '<input type="range" id="op" min="0" max="100" value="38"', "g.strokeStyle='rgba(255,255,255,.95)'; g.lineWidth=7.5;", "g.strokeStyle='#FF6B00'; g.lineWidth=4.5;", "g.lineWidth=1.4; g.stroke(p);")
$R.A1consts = @($consts | ForEach-Object { [pscustomobject]@{ text = $_; inOld = $old.Contains($_); inNew = $new.Contains($_) } })
Write-Output ("A1 same=" + (@($a1 | Where-Object { $_.same }).Count) + "/" + $fns.Count)

# ---------- 기준판(149a7de) 임시 사본 ----------
$BaseDir = Join-Path $env:TEMP 'oc_base_149a7de'
if (Test-Path $BaseDir) { Remove-Item -Recurse -Force $BaseDir }
New-Item -ItemType Directory -Force (Join-Path $BaseDir 'slope') | Out-Null
Copy-Item (Join-Path $OcRoot 'master.js') $BaseDir
[IO.File]::WriteAllText((Join-Path $BaseDir 'slope\index.html'), $old, (New-Object Text.UTF8Encoding($false)))

# ---------- A2: 2D 무회귀(화면) — 기준판과 현재판 같은 5장 ----------
function Run-2D([string]$url, [string]$tag) {
  $o = [ordered]@{}
  Open-Page $url 9371
  try {
    $o.ready = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 25000
    $null = Wait-Js "window.__KTS_ST().pcLoaded" 12000
    Start-Sleep -Milliseconds 2500
    $o.op = Invoke-Js "document.querySelector('#op').value+'|'+document.querySelector('#opv').textContent"
    $o.layers = Invoke-Js "[...document.querySelectorAll('#togs button')].map(b=>b.dataset.l+':'+(b.classList.contains('on')?1:0)).join(',')"
    $o.free = Invoke-Js "document.querySelector('#freeTag').textContent+'|'+document.querySelector('#leftN').textContent+'|'+document.querySelector('#planTag').textContent"
    $o.st = Invoke-Js "JSON.stringify(window.__KTS_ST())"
    $o.sw = Invoke-Js "document.documentElement.scrollWidth"
    Shot-Clip (Join-Path $Shots ("A2_" + $tag + "_1_op38_parcel_contour.png")) '.mapwrap'
    Shot-Clip (Join-Path $Shots ("A2_" + $tag + "_2_quota_free3.png")) '#planFree'
    $null = Rect '.mapwrap'
    for ($i = 0; $i -lt 8; $i++) { TapSel '#zIn' | Out-Null; Start-Sleep -Milliseconds 150 }
    Start-Sleep -Milliseconds 3500
    $o.zoomAfter = Invoke-Js "window.__KTS_ST().zoom"
    Shot-Clip (Join-Path $Shots ("A2_" + $tag + "_3_z20.png")) '.mapwrap'
    TapSel '#togs button[data-l="cont"]' | Out-Null; Start-Sleep -Milliseconds 600
    Shot-Clip (Join-Path $Shots ("A2_" + $tag + "_4_z20_contour_off.png")) '.mapwrap'
    TapSel '#togs button[data-l="parcel"]' | Out-Null; Start-Sleep -Milliseconds 600
    Shot-Clip (Join-Path $Shots ("A2_" + $tag + "_5_z20_parcel_off.png")) '.mapwrap'
    $o.err = Invoke-Js "JSON.stringify(window.__KTS_ERR)"
    $o.evts = (Evts-Summary)
  } finally { Stop-CdpChrome }
  Clear-Evts
  return $o
}
$R.A2_base = Run-2D (To-FileUrl (Join-Path $BaseDir 'slope\index.html')) 'base'
$R.A2_new = Run-2D (To-FileUrl (Join-Path $OcRoot 'slope\index.html')) 'new'
$R.A2_diff = @()
foreach ($n in '1_op38_parcel_contour','2_quota_free3','3_z20','4_z20_contour_off','5_z20_parcel_off') {
  $d = [PxCmp]::Diff((Join-Path $Shots "A2_base_$n.png"), (Join-Path $Shots "A2_new_$n.png"), 24)
  $R.A2_diff += [pscustomobject]@{ shot = $n; diffRatio = [math]::Round($d, 4) }
}
Write-Output ("A2 diff: " + (($R.A2_diff | ForEach-Object { $_.shot + '=' + $_.diffRatio }) -join ', '))

# ---------- A3~A9: 3D ----------
$url = To-FileUrl (Join-Path $OcRoot 'slope\index.html')
Open-Page $url 9372
try {
  Send-Cdp 'Network.enable' | Out-Null
  Send-Cdp 'Emulation.setTouchEmulationEnabled' @{ enabled = $true; maxTouchPoints = 5 } | Out-Null
  $null = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 25000
  $null = Wait-Js "window.__KTS_ST().pcLoaded" 12000
  Start-Sleep -Milliseconds 1500
  $before = Invoke-Js "JSON.stringify(window.__KTS_ST())"
  Shot-Clip (Join-Path $Shots 'A9_1_2d_before.png') '.mapwrap'
  $R.A2D_jibun = Invoke-Js "window.__KTS_ST().jibun"
  # A3 진입
  Invoke-Js "window.__clk=performance.now(); document.querySelector('#vmode button[data-v=""3d""]').click(); 1" | Out-Null
  $null = Wait-Js "window.__KTS_3D().st.draws>0" 5000
  $R.A3 = [ordered]@{ clickToFirstFrameMs = (Invoke-Js "Math.round(window.__KTS_3D().st.firstAt-window.__clk)"); st = (Invoke-Js "JSON.stringify(window.__KTS_3D())") }
  $null = Wait-Js "window.__KTS_3D().st.tilesOk+window.__KTS_3D().st.tilesFail>=window.__KTS_3D().st.tilesTotal" 12000
  Start-Sleep -Milliseconds 600
  Shot (Join-Path $Shots 'A3_3d_enter_full.png')
  Shot-Clip (Join-Path $Shots 'A7_1_sat_ok.png') '.mapwrap'
  $R.A7_ok = Invoke-Js "JSON.stringify({st:window.__KTS_3D().st,inf:document.querySelector('#inf3d').textContent})"
  # A6 필지
  $R.A6 = Invoke-Js "JSON.stringify({parcel3d:window.__KTS_3D().st.parcel,lineSegs:window.__KTS_3D().st.lineSegs,center:window.__KTS_3D().st.center,label:document.querySelector('#lbl3d').textContent,labelShown:!document.querySelector('#lbl3d').classList.contains('hide'),jibun2d:window.__KTS_ST().jibun})"
  Shot-Clip (Join-Path $Shots 'A6_parcel_on_terrain.png') '.mapwrap'
  # A4 회전
  $R.A4 = @()
  foreach ($y in 0, 90, 180, 270) {
    Invoke-Js "window.__KTS_3D_SET({yaw:$y,pitch:38})" | Out-Null
    $p = Invoke-Js "JSON.stringify(window.__KTS_3D_PIX())"
    Shot-Clip (Join-Path $Shots ("A4_yaw" + $y + ".png")) '.mapwrap'
    $R.A4 += [pscustomobject]@{ yaw = $y; pix = $p; png = (Sha (Join-Path $Shots ("A4_yaw" + $y + ".png"))) }
  }
  # A5 기울기
  $R.A5 = @()
  foreach ($pt in 15, 45, 75) {
    Invoke-Js "window.__KTS_3D_SET({yaw:0,pitch:$pt})" | Out-Null
    $p = Invoke-Js "JSON.stringify(window.__KTS_3D_PIX())"
    Shot-Clip (Join-Path $Shots ("A5_pitch" + $pt + ".png")) '.mapwrap'
    $R.A5 += [pscustomobject]@{ pitch = $pt; pix = $p }
  }
  # 손가락 조작: 한 손가락 끌기 → yaw/pitch, 두 손가락 벌리기 → 거리, 두 번 톡 → 초기
  Invoke-Js "window.__KTS_3D_SET({yaw:0,pitch:38})" | Out-Null
  $c = Rect '#cv3d'
  $cx = $c.x + $c.w / 2; $cy = $c.y + $c.h / 2
  $g0 = Invoke-Js "JSON.stringify(window.__KTS_3D())" | ConvertFrom-Json
  Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchStart'; touchPoints = @(@{ x = $cx; y = $cy; id = 1 }) } | Out-Null
  for ($i = 1; $i -le 8; $i++) { Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchMove'; touchPoints = @(@{ x = ($cx - 10 * $i); y = ($cy + 4 * $i); id = 1 }) } | Out-Null }
  Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchEnd'; touchPoints = @() } | Out-Null
  Start-Sleep -Milliseconds 200
  $g1 = Invoke-Js "JSON.stringify(window.__KTS_3D())" | ConvertFrom-Json
  Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchStart'; touchPoints = @(@{ x = ($cx - 30); y = $cy; id = 1 }, @{ x = ($cx + 30); y = $cy; id = 2 }) } | Out-Null
  for ($i = 1; $i -le 8; $i++) { Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchMove'; touchPoints = @(@{ x = ($cx - 30 - 8 * $i); y = $cy; id = 1 }, @{ x = ($cx + 30 + 8 * $i); y = $cy; id = 2 }) } | Out-Null }
  Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchEnd'; touchPoints = @() } | Out-Null
  Start-Sleep -Milliseconds 200
  $g2 = Invoke-Js "JSON.stringify(window.__KTS_3D())" | ConvertFrom-Json
  Shot-Clip (Join-Path $Shots 'A4_touch_after_drag_pinch.png') '.mapwrap'
  foreach ($k in 1, 2) { Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchStart'; touchPoints = @(@{ x = $cx; y = $cy; id = 1 }) } | Out-Null; Send-Cdp 'Input.dispatchTouchEvent' @{ type = 'touchEnd'; touchPoints = @() } | Out-Null; Start-Sleep -Milliseconds 120 }
  Start-Sleep -Milliseconds 200
  $g3 = Invoke-Js "JSON.stringify(window.__KTS_3D())" | ConvertFrom-Json
  $R.Gest = [ordered]@{ start = "yaw=$($g0.yaw) pitch=$($g0.pitch) dist=$([math]::Round($g0.dist))"; oneFingerDrag = "yaw=$([math]::Round($g1.yaw,1)) pitch=$([math]::Round($g1.pitch,1))"; twoFingerSpread = "dist=$([math]::Round($g2.dist))"; doubleTap = "yaw=$($g3.yaw) pitch=$($g3.pitch) dist=$([math]::Round($g3.dist))" }
  # 고도 과장
  TapSel '#ex3d button[data-x="2"]' | Out-Null; Start-Sleep -Milliseconds 300
  Invoke-Js "window.__KTS_3D_SET({yaw:30,pitch:25})" | Out-Null
  Shot-Clip (Join-Path $Shots 'A_exag2x.png') '.mapwrap'
  $R.Exag = Invoke-Js "document.querySelector('#inf3d').textContent"
  TapSel '#ex3d button[data-x="1"]' | Out-Null
  # A8 성능
  Invoke-Js "window.__KTS_3D_SET({spinMs:3000})" | Out-Null
  Start-Sleep -Milliseconds 3600
  $R.A8 = Invoke-Js "JSON.stringify((()=>{const s=window.__KTS_3D();return {frameMedianMs:s.frameMedianMs,frames:s.frames,verts:s.st.verts,tris:s.st.tris,tex:s.st.texW+'x'+s.st.texH,tz:s.st.tz,drawMsLast:s.st.drawMs}})())"
  # A9 2D 복귀
  TapSel '#vmode button[data-v="2d"]' | Out-Null; Start-Sleep -Milliseconds 1500
  $after = Invoke-Js "JSON.stringify(window.__KTS_ST())"
  Shot-Clip (Join-Path $Shots 'A9_2_2d_after.png') '.mapwrap'
  $R.A9 = [ordered]@{ before = $before; after = $after; rafStopped = (Invoke-Js "!window.__KTS_3D().raf && !window.__KTS_3D().on"); pixDiff = [math]::Round([PxCmp]::Diff((Join-Path $Shots 'A9_1_2d_before.png'), (Join-Path $Shots 'A9_2_2d_after.png'), 24), 4) }
  # 중복 진입: 3D↔2D 6번 빠르게
  for ($i = 0; $i -lt 6; $i++) { Invoke-Js "document.querySelector('#vmode button[data-v=""3d""]').click();document.querySelector('#vmode button[data-v=""2d""]').click();document.querySelector('#vmode button[data-v=""3d""]').click();1" | Out-Null; Start-Sleep -Milliseconds 120 }
  Start-Sleep -Milliseconds 500
  $R.Dup = Invoke-Js "JSON.stringify({ctxCreated:window.__KTS_3D().st.ctx,live:window.__KTS_3D().st.live,canvases:document.querySelectorAll('#cv3d').length,on:window.__KTS_3D().on})"
  TapSel '#vmode button[data-v="2d"]' | Out-Null; Start-Sleep -Milliseconds 300
  # A7 실패: 위성 타일 차단 후 다시 3D
  Send-Cdp 'Network.setBlockedURLs' @{ urls = @('*Satellite*') } | Out-Null
  Invoke-Js "window.__KTS_3D_SET && 1" | Out-Null
  $R.A7_failToasts = @()
  Invoke-Js "window.__tl=[];new MutationObserver(()=>{const t=document.querySelector('#toast');if(t.classList.contains('on'))window.__tl.push(t.textContent)}).observe(document.querySelector('#toast'),{attributes:true,childList:true,characterData:true,subtree:true});1" | Out-Null
  # 다른 지점(캐시 안 된 타일)으로 2D에서 이동 후 3D
  Invoke-Js "document.querySelectorAll('#chips button')[2].click();1" | Out-Null
  $null = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0) && window.__KTS_ST().zoom>=16.6" 20000
  Start-Sleep -Milliseconds 4000
  TapSel '#vmode button[data-v="3d"]' | Out-Null
  $null = Wait-Js "window.__KTS_3D().st.tilesFail>=window.__KTS_3D().st.tilesTotal && window.__KTS_3D().st.tilesTotal>0" 15000
  Start-Sleep -Milliseconds 800
  Shot-Clip (Join-Path $Shots 'A7_2_sat_blocked_gray.png') '.mapwrap'
  Start-Sleep -Milliseconds 3000
  $R.A7_fail = Invoke-Js "JSON.stringify({st:window.__KTS_3D().st,inf:document.querySelector('#inf3d').textContent,toasts:[...new Set(window.__tl)]})"
  Send-Cdp 'Network.setBlockedURLs' @{ urls = @() } | Out-Null
  $R.sw = Invoke-Js "document.documentElement.scrollWidth"
  $R.err = Invoke-Js "JSON.stringify(window.__KTS_ERR)"
  $R.evts = (Evts-Summary)
  $R.evtList = @($global:EVTS | Select-Object -First 30 | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(160, $_.text.Length)) })
} finally { Stop-CdpChrome }
Clear-Evts

# ---------- A10: WebGL 끈 크롬 ----------
Open-Page $url 9373 '--disable-webgl --disable-3d-apis'
try {
  $null = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 25000
  Invoke-Js "window.__tl=[];new MutationObserver(()=>{const t=document.querySelector('#toast');if(t.classList.contains('on'))window.__tl.push(t.textContent)}).observe(document.querySelector('#toast'),{attributes:true,childList:true,characterData:true,subtree:true});1" | Out-Null
  $R.A10_webgl = Invoke-Js "(()=>{try{return !!document.createElement('canvas').getContext('webgl')}catch(e){return 'ex:'+e.message}})()"
  TapSel '#vmode button[data-v="3d"]' | Out-Null; Start-Sleep -Milliseconds 800
  $R.A10 = Invoke-Js "JSON.stringify({toasts:[...new Set(window.__tl)],mode2dOn:document.querySelector('#vmode button[data-v=""2d""]').classList.contains('on'),m3d:document.querySelector('.mapwrap').classList.contains('m3d'),mapVisible:getComputedStyle(document.querySelector('#mapcv')).visibility,cv3dHidden:document.querySelector('#cv3d').classList.contains('hide'),err:window.__KTS_ERR})"
  Shot-Clip (Join-Path $Shots 'A10_no_webgl_stays_2d.png') '.mapwrap'
  $R.A10_evts = (Evts-Summary)
} finally { Stop-CdpChrome }
Clear-Evts
Remove-Item -Recurse -Force $BaseDir
$out = Join-Path $PSScriptRoot '..\verify_a_result.json'
$R | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $out
Write-Output "saved $out"

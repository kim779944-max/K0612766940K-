. "$PSScriptRoot\lib.ps1"
Start-Serve
$READY = "!!(window.__KTS_ST && document.querySelector('#resTag').textContent.indexOf('평균')>=0)"
$O = [ordered]@{}
Add-Type -AssemblyName System.Drawing
function PixDiff($a, $b) {
  $A = [Drawing.Bitmap]::FromFile($a); $B = [Drawing.Bitmap]::FromFile($b)
  $n = 0; $d = 0
  for ($y = 0; $y -lt $A.Height; $y += 2) { for ($x = 0; $x -lt $A.Width; $x += 2) { $n++; $p = $A.GetPixel($x, $y); $q = $B.GetPixel($x, $y); if ([Math]::Abs($p.R - $q.R) + [Math]::Abs($p.G - $q.G) + [Math]::Abs($p.B - $q.B) -gt 24) { $d++ } } }
  $A.Dispose(); $B.Dispose(); return [Math]::Round(100.0 * $d / $n, 3)
}
function DragFrames() {
  J "window.__FR=[];window.__FRon=true;(function f(t){if(!window.__FRon)return;window.__FR.push(t);requestAnimationFrame(f)})(performance.now());return 1" | Out-Null
  $mr = Rect '#mapcv'
  Drag ($mr.x + 80) ($mr.y + 200) ($mr.x + 300) ($mr.y + 120) 40
  Drag ($mr.x + 300) ($mr.y + 120) ($mr.x + 90) ($mr.y + 260) 40
  return (J "window.__FRon=false;var a=window.__FR,d=[];for(var i=1;i<a.length;i++)d.push(a[i]-a[i-1]);d.sort(function(x,y){return x-y});return JSON.stringify({frames:a.length,median:+(d[Math.floor(d.length/2)]||0).toFixed(1),p90:+(d[Math.floor(d.length*0.9)]||0).toFixed(1)})")
}
foreach ($v in @(@{ n = 'base'; u = 'slope/_base_index.html'; port = 9391 }, @{ n = 'new'; u = 'slope/'; port = 9392 })) {
  try {
    Open-Page ($global:Base + $v.u) $v.port
    Wait-Js $READY 30000 | Out-Null
    Start-Sleep -Milliseconds 7000
    # 필지 경계(Vworld WMS 그림) 층은 응답 시점이 매번 달라 끄고 비교 — 나머지 층은 기본 그대로
    J "var b=document.querySelector('#togs button[data-l=parcel]');if(b.classList.contains('on'))b.click();return 1" | Out-Null
    Start-Sleep -Milliseconds 1200
    Shot-Clip (Join-Path $global:ShotDir ('E7_' + $v.n + '_default_noWMS.png')) '#mapcv'
    $O[$v.n + '_dragArrow_r100'] = DragFrames
    J "var e=document.getElementById('rad');e.value='300';e.dispatchEvent(new Event('input'));return 1" | Out-Null
    Start-Sleep -Milliseconds 1500
    $O[$v.n + '_dragArrow_r300'] = DragFrames
    if ($v.n -eq 'new') {
      $O.new_firstPaint_px3_r300 = Js "var t0=performance.now();window.__KTS_PXSET('px',3);await new Promise(function(r){requestAnimationFrame(function(){requestAnimationFrame(r)})});var P=window.__KTS_PX();return JSON.stringify({ms:+(performance.now()-t0).toFixed(1),buildMs:P.buildMs,cells:P.n*P.ny,inside:P.inside,zoom:window.__KTS_ST().zoom})"
      Start-Sleep -Milliseconds 500
      Shot-Clip (Join-Path $global:ShotDir 'E6_px3_r300_z16.png') '#mapcv'
      $O.new_dragPx3_r300 = DragFrames
      $O.new_firstPaint_px6_r300 = Js "var t0=performance.now();window.__KTS_PXSET('px',6);await new Promise(function(r){requestAnimationFrame(function(){requestAnimationFrame(r)})});var P=window.__KTS_PX();return JSON.stringify({ms:+(performance.now()-t0).toFixed(1),buildMs:P.buildMs,cells:P.n*P.ny,inside:P.inside})"
      $O.new_dragPx6_r300 = DragFrames
    }
    $O[$v.n + '_evts'] = Evts-Summary
  } finally { Stop-CdpChrome; $global:EVTS.Clear() }
}
$O.defaultPixDiffPct_noWMS = PixDiff (Join-Path $global:ShotDir 'E7_base_default_noWMS.png') (Join-Path $global:ShotDir 'E7_new_default_noWMS.png')
$O | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_e7perf_result.json')
$O | ConvertTo-Json -Depth 5

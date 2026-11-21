. "$PSScriptRoot\lib.ps1"
Start-Serve
$R = [ordered]@{}
$READY = "!!(window.__KTS_ST && document.querySelector('#resTag').textContent.indexOf('평균')>=0)"
function MapShot([string]$name) { Shot-Clip (Join-Path $global:ShotDir $name) '#mapcv' }

# ── E7(화면) 기준판(_base_index.html = 변경 전 사본) vs 새 판 — 기본 화면(화살표) 픽셀 비교 ──
$e7 = [ordered]@{}
foreach ($v in @(@{ n = 'base'; u = 'slope/_base_index.html'; port = 9381 }, @{ n = 'new'; u = 'slope/'; port = 9382 })) {
  try {
    Open-Page ($global:Base + $v.u) $v.port
    Wait-Js $READY 30000 | Out-Null
    Start-Sleep -Milliseconds 7000   # 안내 말풍선(6초) 사라진 뒤
    MapShot ('E7_' + $v.n + '_default.png')
    $e7[$v.n] = J "var t=document.body.innerText;return JSON.stringify({st:window.__KTS_ST(),lay:Object.keys({arrow:1,slope:1,cont:1,grid:1,parcel:1}).map(function(k){return k}),free:(t.match(/무료 3건|하루 3건 무료/g)||[]).length,price:(t.match(/10건권 9,000원|9,000원/g)||[]).length,op:document.getElementById('op').value,sw:document.documentElement.scrollWidth})"
    TapSel '#vmode button[data-v="3d"]' | Out-Null
    Start-Sleep -Milliseconds 2500
    $e7[$v.n + '_3d'] = J "var s=window.__KTS_3D&&window.__KTS_3D();return JSON.stringify(s?{on:s.on,frame:s.firstFrameMs||s.ms||null,verts:s.verts||null}:null)"
    MapShot ('E7_' + $v.n + '_after3d_dummy.png')
    $e7[$v.n + '_evts'] = Evts-Summary
  } finally { Stop-CdpChrome; $global:EVTS.Clear() }
}
Add-Type -AssemblyName System.Drawing
function PixDiff($a, $b) {
  $A = [Drawing.Bitmap]::FromFile($a); $B = [Drawing.Bitmap]::FromFile($b)
  $n = 0; $d = 0
  for ($y = 0; $y -lt $A.Height; $y += 2) { for ($x = 0; $x -lt $A.Width; $x += 2) { $n++; $p = $A.GetPixel($x, $y); $q = $B.GetPixel($x, $y); if ([Math]::Abs($p.R - $q.R) + [Math]::Abs($p.G - $q.G) + [Math]::Abs($p.B - $q.B) -gt 24) { $d++ } } }
  $A.Dispose(); $B.Dispose(); return [Math]::Round(100.0 * $d / $n, 3)
}
$e7.defaultPixDiffPct = PixDiff (Join-Path $global:ShotDir 'E7_base_default.png') (Join-Path $global:ShotDir 'E7_new_default.png')
$R.E7 = $e7

# ── 새 판 상세 ──
try {
  Open-Page ($global:Base + 'slope/') 9383 '--disable-web-security'
  Wait-Js $READY 30000 | Out-Null
  Start-Sleep -Milliseconds 1500
  # E1 밀도
  J "window.__KTS_PXSET('px',3);return 1" | Out-Null; Start-Sleep -Milliseconds 600
  $e1 = [ordered]@{}
  $e1.sub3 = J "return JSON.stringify(window.__KTS_PX())"
  MapShot 'E1_px_3x3_r100.png'
  J "window.__KTS_PXSET('px',6);return 1" | Out-Null; Start-Sleep -Milliseconds 600
  $e1.sub6 = J "return JSON.stringify(window.__KTS_PX())"
  MapShot 'E1_px_6x6_r100.png'
  $e1.ui = J "return JSON.stringify({view:[].map.call(document.querySelectorAll('#pxView button'),function(b){return b.textContent+(b.classList.contains('on')?'*':'')}),sub:[].map.call(document.querySelectorAll('#pxSub button'),function(b){return b.textContent+(b.classList.contains('on')?'*':'')}),note:document.getElementById('pxNote').textContent})"
  J "window.__KTS_PXSET('px',3);return 1" | Out-Null
  $R.E1 = $e1
  # E2 픽셀 제 색 — 확대(z20) 후 캔버스 getImageData 로 이웃 칸 비교 (등고선 끄고)
  J "document.querySelector('#togs button[data-l=cont]').click();return 1" | Out-Null
  for ($k = 0; $k -lt 8; $k++) { TapSel '#zIn' | Out-Null; Start-Sleep -Milliseconds 150 }
  Start-Sleep -Milliseconds 1500
  MapShot 'E2_after_px_z20.png'
  $R.E2 = J @"
var cv=document.getElementById('mapcv'),g=cv.getContext('2d'),dpr=cv.width/cv.clientWidth,P=window.__KTS_PX(),st=window.__KTS_ST();
var W=256*Math.pow(2,st.zoom),out={zoom:st.zoom,dpr:dpr,pairs:0,diffBand:0,diffBandSameColor:0,sameBand:0,sameBandColorFar:0,boundaries:0,mixedPx:0,maxTransition:0};
var img=g.getImageData(0,0,cv.width,cv.height).data;
function px(x,y){x=Math.round(x);y=Math.round(y);var i=(y*cv.width+x)*4;return [img[i],img[i+1],img[i+2]]}
function dist(a,b){return Math.abs(a[0]-b[0])+Math.abs(a[1]-b[1])+Math.abs(a[2]-b[2])}
var rows=[0.45,0.5,0.55,0.6];
rows.forEach(function(fy){
  var yC=cv.clientHeight*fy, prev=null;
  for(var xC=4;xC<cv.clientWidth-4;xC+=1){
    var c=window.__KTS_PXCELL(xC,yC); if(!c){prev=null;continue}
    if(prev&&(c.i!==prev.c.i)){
      /* 경계: prev 칸 중심과 c 칸 중심 색 비교 */
      var cs=(xC-prev.x0), a=px(prev.mid*dpr,yC*dpr), bxc=xC;
      prev.end=xC;
      var midA=(prev.x0+xC)/2, colA=px(midA*dpr,yC*dpr);
      /* 다음 칸 끝 찾기 */
      var xe=xC; while(xe<cv.clientWidth-4){var cc=window.__KTS_PXCELL(xe,yC); if(!cc||cc.i!==c.i)break; xe++}
      var midB=(xC+xe)/2, colB=px(midB*dpr,yC*dpr);
      out.pairs++;
      if(prev.c.band!==c.band){ out.diffBand++; if(dist(colA,colB)<=12) out.diffBandSameColor++;
        /* 경계 전이폭: 경계 ±3 device px 에서 두 색 어느 쪽과도 먼 픽셀 수 */
        out.boundaries++; var bx=xC*dpr, mixed=0;
        for(var dx=-3;dx<=3;dx++){ var q=px(bx+dx,yC*dpr); if(dist(q,colA)>30&&dist(q,colB)>30) mixed++ }
        out.mixedPx+=mixed; if(mixed>out.maxTransition) out.maxTransition=mixed;
      } else { out.sameBand++; if(dist(colA,colB)>60) out.sameBandColorFar++ }
      prev={c:c,x0:xC,mid:(xC+xe)/2};
    } else if(!prev){ prev={c:c,x0:xC,mid:xC} }
  }
});
out.diffBandSameColorPct=out.diffBand?+(100*out.diffBandSameColor/out.diffBand).toFixed(2):0;
out.transitionPx=out.maxTransition<=1?'<=1px':out.maxTransition+'px';
return JSON.stringify(out);
"@
  # E2 전: 기존 '경사도 색' 층(부드러운 보간) — 같은 확대에서 캡처
  J "window.__KTS_PXSET('arrow');document.querySelector('#togs button[data-l=slope]').click();return 1" | Out-Null; Start-Sleep -Milliseconds 800
  MapShot 'E2_before_smooth_slope_z20.png'
  J "document.querySelector('#togs button[data-l=slope]').click();document.querySelector('#togs button[data-l=cont]').click();window.__KTS_PXSET('px',3);return 1" | Out-Null; Start-Sleep -Milliseconds 600
  # E3 값 탭 3칸
  $e3 = @()
  $mr = Rect '#mapcv'
  foreach ($f in @(@(0.42, 0.40), @(0.58, 0.47), @(0.46, 0.62))) {
    $x = $mr.x + $mr.w * $f[0]; $y = $mr.y + $mr.h * $f[1]
    $cell = J "var r=document.getElementById('mapcv').getBoundingClientRect();return JSON.stringify(window.__KTS_PXCELL($x-r.left,$y-r.top))"
    Tap $x $y; Start-Sleep -Milliseconds 400
    $e3 += (J "var c=window.__KTS_PX().last,t=document.getElementById('pxTip').textContent;if(!c)return JSON.stringify({tip:t,last:null,pre:$cell});var s2=window.__KTS_PXSLOPE(c.u,c.v);return JSON.stringify({tip:t,shown:{slope:c.slope,elev:c.elev,asp:c.asp},recomputedSlope:+s2.toFixed(1),match:Math.abs(s2-c.slope)<0.06&&t.indexOf(c.slope+'°')>=0&&t.indexOf(c.elev+'m')>=0,stillCenter:window.__KTS_ST().zoom})")
  }
  $R.E3 = $e3
  MapShot 'E3_tap_value.png'
  ShotP 'E3_tap_value_page.png'
  # E4 각주 · '정밀' 표현
  $R.E4 = J "var n=document.getElementById('pxNote').textContent, t=document.body.innerText;return JSON.stringify({note:n,hasInterp:n.indexOf('기반 보간 · 참고용(측량값 아님)')>=0,precisionWordsInNewUI:(n.match(/정밀/g)||[]).length,precisionWordsPageTotal:(t.match(/정밀/g)||[]).length})"
  # E6 성능 — 반경 300m
  J "var e=document.getElementById('rad');e.value='300';e.dispatchEvent(new Event('input'));window.__KTS_PXSET('arrow');return 1" | Out-Null
  for ($k = 0; $k -lt 8; $k++) { TapSel '#zOut' | Out-Null; Start-Sleep -Milliseconds 120 }
  Start-Sleep -Milliseconds 2500
  $e6 = [ordered]@{}
  foreach ($s in 3, 6) {
    $e6["first_paint_sub$s"] = Js "var t0=performance.now();window.__KTS_PXSET('px',$s);await new Promise(function(r){requestAnimationFrame(function(){requestAnimationFrame(r)})});var P=window.__KTS_PX();return JSON.stringify({ms:+(performance.now()-t0).toFixed(1),buildMs:P.buildMs,n:P.n,ny:P.ny,cells:P.n*P.ny,insideR300:P.inside,sub:P.sub})"
  }
  MapShot 'E6_px_r300.png'
  # 끌기 중 프레임 간격
  J "window.__FR=[];window.__FRon=true;(function f(t){if(!window.__FRon)return;window.__FR.push(t);requestAnimationFrame(f)})(performance.now());return 1" | Out-Null
  $mr = Rect '#mapcv'
  Drag ($mr.x + 80) ($mr.y + 200) ($mr.x + 300) ($mr.y + 120) 40
  Drag ($mr.x + 300) ($mr.y + 120) ($mr.x + 90) ($mr.y + 260) 40
  $e6.drag = J "window.__FRon=false;var a=window.__FR,d=[];for(var i=1;i<a.length;i++)d.push(a[i]-a[i-1]);d.sort(function(x,y){return x-y});return JSON.stringify({frames:a.length,median:+(d[Math.floor(d.length/2)]||0).toFixed(1),p90:+(d[Math.floor(d.length*0.9)]||0).toFixed(1)})"
  $R.E6 = $e6
  $R.sw = SW
  $R.evts = Evts-Summary
  $R.evtList = @($global:EVTS | Select-Object -First 6 | ForEach-Object { $_.kind + ' :: ' + $_.text })
} finally { Stop-CdpChrome }

# E7(코드) 2D 함수 본문 동일
$old = [IO.File]::ReadAllText((Join-Path $global:OcRoot 'slope\_base_index.html'), [Text.Encoding]::UTF8)
$new = [IO.File]::ReadAllText((Join-Path $global:OcRoot 'slope\index.html'), [Text.Encoding]::UTF8)
function FnBody($t, $n) { $i = $t.IndexOf("function $n("); if ($i -lt 0) { return $null }; $d = 0; $s = $t.IndexOf('{', $i); for ($j = $s; $j -lt $t.Length; $j++) { if ($t[$j] -eq '{') { $d++ } elseif ($t[$j] -eq '}') { $d--; if ($d -eq 0) { return $t.Substring($i, $j - $i + 1) } } }; return $null }
$fns = 'render','scene','drawBase','drawSlopeImg','drawContours','drawGridLines','drawVWImg','drawParcelHL','drawMarker','drawProfile','analyze','paintResult','verdictOf','drawSlopeArrows','buildTerrain','endPtr','paintLegend'
$same = @(); $diff = @()
foreach ($f in $fns) { $a = FnBody $old $f; $b = FnBody $new $f; if ($a -ne $null -and $a -eq $b) { $same += $f } else { $diff += $f } }
$R.E7code = @{ same = $same.Count; total = $fns.Count; diff = $diff; strings = @{ zmax = ($new -match 'ZMIN=13, ZMAX=20, TZMAX=19'); op38 = ($new -match 'id="op" min="0" max="100" value="38"'); price = ([regex]::Matches($new, '9,000원')).Count; priceOld = ([regex]::Matches($old, '9,000원')).Count; free3 = ([regex]::Matches($new, '3건')).Count; free3Old = ([regex]::Matches($old, '3건')).Count } }
$R | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_e_result.json')
$R | ConvertTo-Json -Depth 6

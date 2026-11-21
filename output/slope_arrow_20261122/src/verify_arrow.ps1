# 경사 화살표 본색·방향 수리(2026-11-22) 검수 A1~A11·A13 — 헤드리스 크롬 390x844 @2x
param([string]$url = '', [string]$tag = 'local', [switch]$pxOnly, [switch]$steep)
. "$PSScriptRoot\..\..\slope3d_20261121\src\lib3d.ps1"
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
if (-not $url) { $url = To-FileUrl (Join-Path $OcRoot 'slope\index.html') }
$OutDir = (Resolve-Path "$PSScriptRoot\..").Path
$Shots = Join-Path $OutDir 'shots'; if (-not (Test-Path $Shots)) { New-Item -ItemType Directory $Shots | Out-Null }
# 그린 화살표 표본(페이지 내장 읽기 전용 훅 __KTS_ARROWS('drawn')) + 캔버스의 지도 카드 안 위치
$ProbeJs = "(()=>{const a=window.__KTS_ARROWS('drawn'); if(!a) return null; const cr=document.querySelector('#mapcv').getBoundingClientRect(), mr=document.querySelector('.mapwrap').getBoundingClientRect(); const cv=document.querySelector('#mapcv'), W2=cv.clientWidth/2, H2=cv.clientHeight/2, onCv=(x,y)=>document.elementFromPoint(cr.left+x,cr.top+y)===cv; return JSON.stringify({pts:a.filter(p=>{const tx=p.x+p.ax*(p.len/2+3), ty=p.y+p.ay*(p.len/2+3), ex=p.x-p.ax*(p.len/2+3), ey=p.y-p.ay*(p.len/2+3); return onCv(tx,ty)&&onCv(ex,ey)&&onCv(p.x-p.ay*6,p.y+p.ax*6)&&onCv(p.x+p.ay*6,p.y-p.ax*6)&&Math.hypot(p.x-W2,p.y-H2)>22}).map(p=>{const tx=p.x+p.ax*p.len/2, ty=p.y+p.ay*p.len/2, nx=tx-p.ax*p.hl, ny=ty-p.ay*p.hl; return {b:p.b,hex:['#FFFFFF','#FFF59D','#FFEB3B','#FFC107','#FF9800','#F57C00','#F44336','#D32F2F','#B71C1C','#7F0000'][p.b],s:p.s,len:p.len,hl:p.hl,dir:[p.ax,p.ay],tip:[+tx.toFixed(2),+ty.toFixed(2)],end:[+(p.x-p.ax*p.len/2).toFixed(2),+(p.y-p.ay*p.len/2).toFixed(2)],head:[nx+p.ax*p.hl/3,ny+p.ay*p.hl/3],base:[nx+p.ax*0.5,ny+p.ay*0.5],tail:[p.x-p.ax*p.len/2+p.ax*0.6,p.y-p.ay*p.len/2+p.ay*0.6]}}), cvOff:[cr.left-mr.left,cr.top-mr.top], gap:window.__KTS_PX().arrows.gap})})()"
# 정상 8방위: 지도 중심(=정상)에서 50m·100m 떨어진 8점의 화살표 방향이 바깥을 향하는지(dot>0)
function Summit([double]$lat) {
  $js = "(()=>{const z=window.__KTS_ST().zoom, mpp=156543.03392*Math.cos($lat*Math.PI/180)/Math.pow(2,z), c=document.querySelector('#mapcv'), w=c.clientWidth, h=c.clientHeight; const N=['N','NE','E','SE','S','SW','W','NW']; const q=[[0.5,0.5]], meta=[]; N.forEach((n,i)=>{const a=i*Math.PI/4, ox=Math.sin(a), oy=-Math.cos(a); [50,100].forEach(d=>{q.push([0.5+ox*d/mpp/w,0.5+oy*d/mpp/h]); meta.push({dir:n,d:d,ox:ox,oy:oy})})}); const r=window.__KTS_ARROWS(q); const c0=r[0]; const rows=N.map((n,i)=>{const o={dir:n}; [0,1].forEach(k=>{const p=r[1+i*2+k], m=meta[i*2+k]; o['dot'+m.d]=p?+(p.dir[0]*m.ox+p.dir[1]*m.oy).toFixed(3):null; o['elev'+m.d]=p?+p.elevCenter.toFixed(1):null; o['slope'+m.d]=p?+p.slope.toFixed(1):null; o['drop'+m.d]=p?p.drop:null}); o.outward=o.dot50>0&&o.dot100>0; o.lowerAt100=c0&&o.elev100<c0.elevCenter; return o}); return JSON.stringify({zoom:z, mpp:+mpp.toFixed(3), center:c0?+c0.elevCenter.toFixed(1):null, dirs:rows, outward:rows.filter(o=>o.outward).length, lower:rows.filter(o=>o.lowerAt100).length, arrows:window.__KTS_PX().arrows})})()"
  return (J $js)
}
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Drawing.Drawing2D;
public static class ArChk {
  static Bitmap bmp; static string cur;
  public static void Load(string p){ if(bmp!=null) bmp.Dispose(); bmp=new Bitmap(p); cur=p; }
  // 2x2 장치 px 평균(CSS 좌표 * 2)
  public static string Px(double cx,double cy){
    int x=(int)Math.Floor(cx*2-0.5), y=(int)Math.Floor(cy*2-0.5); int r=0,g=0,b=0,n=0;
    for(int j=y;j<y+2;j++) for(int i=x;i<x+2;i++){ if(i<0||j<0||i>=bmp.Width||j>=bmp.Height) continue; var c=bmp.GetPixel(i,j); r+=c.R; g+=c.G; b+=c.B; n++; }
    if(n==0) return "null"; return "["+(r/n)+","+(g/n)+","+(b/n)+"]";
  }
  // (cx,cy)에서 수직(px,py) 방향으로 본색(±tol) 연속 구간 폭(CSS px, 0.25 간격)
  public static double Run(double cx,double cy,double px,double py,int R,int G,int B,int tol){
    int n=1;
    for(int sgn=-1;sgn<=1;sgn+=2){ for(int k=1;k<60;k++){ double t=sgn*k*0.25; int i=(int)Math.Floor((cx+px*t)*2), j=(int)Math.Floor((cy+py*t)*2);
      if(i<0||j<0||i>=bmp.Width||j>=bmp.Height) break; var c=bmp.GetPixel(i,j);
      if(Math.Abs(c.R-R)<=tol&&Math.Abs(c.G-G)<=tol&&Math.Abs(c.B-B)<=tol) n++; else break; } }
    return n*0.25;
  }
  public static void Crop3(string src,string dst,int x,int y,int w,int h){
    using(var b=new Bitmap(src)) using(var o=new Bitmap(w*3,h*3)) using(var g=Graphics.FromImage(o)){
      g.InterpolationMode=InterpolationMode.NearestNeighbor; g.PixelOffsetMode=PixelOffsetMode.Half;
      g.DrawImage(b,new Rectangle(0,0,w*3,h*3),new Rectangle(x,y,w,h),GraphicsUnit.Pixel); o.Save(dst,ImageFormat.Png); }
  }
}
"@
$R = [ordered]@{ url = $url; tag = $tag; at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
function J([string]$e) { $t = Invoke-Js $e; if ($t) { return ($t | ConvertFrom-Json) } return $null }
function MapShot([string]$name) { $p = Join-Path $Shots ($tag + '_' + $name + '.png'); Shot-Clip $p '.mapwrap'; return $p }
function Pans([int]$n) { $m = Rect '.mapwrap'; for ($i = 0; $i -lt $n; $i++) { $dx = if ($i % 2) { 14 } else { -14 }; Drag ($m.x + $m.w / 2) ($m.y + $m.h / 2) ($m.x + $m.w / 2 + $dx) ($m.y + $m.h / 2) 6; Start-Sleep -Milliseconds 150 } ; Start-Sleep -Milliseconds 1500 }
function Wait-Ready { $null = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 30000; $null = Wait-Js "window.__KTS_ST().pcLoaded" 15000; Start-Sleep -Milliseconds 3500 }
function HexRgb([string]$h) { return @([Convert]::ToInt32($h.Substring(1, 2), 16), [Convert]::ToInt32($h.Substring(3, 2), 16), [Convert]::ToInt32($h.Substring(5, 2), 16)) }
# 지도 캡처에서 화살표 표본(색·폭) — 구간별 최대 $per 개
function Sample-Arrows([string]$shot, [int]$per = 5) {
  $pr = J $ProbeJs; if (-not $pr) { return $null }
  [ArChk]::Load($shot); $res = @(); $cnt = @{}
  foreach ($p in $pr.pts) {
    $b = [string]$p.b; if (-not $cnt.ContainsKey($b)) { $cnt[$b] = 0 }; if ($cnt[$b] -ge $per) { continue }
    $ox = $pr.cvOff[0]; $oy = $pr.cvOff[1]; $rgb = HexRgb $p.hex
    $got = ([ArChk]::Px($p.head[0] + $ox, $p.head[1] + $oy) | ConvertFrom-Json)
    if ($null -eq $got) { continue }
    $dmax = [math]::Max([math]::Max([math]::Abs($got[0] - $rgb[0]), [math]::Abs($got[1] - $rgb[1])), [math]::Abs($got[2] - $rgb[2]))
    $perpX = - $p.dir[1]; $perpY = $p.dir[0]
    $baseW = [ArChk]::Run($p.base[0] + $ox, $p.base[1] + $oy, $perpX, $perpY, $rgb[0], $rgb[1], $rgb[2], 40)
    $tailW = [ArChk]::Run($p.tail[0] + $ox, $p.tail[1] + $oy, $perpX, $perpY, $rgb[0], $rgb[1], $rgb[2], 40)
    $res += [pscustomobject]@{ band = $p.b; hex = $p.hex; slope = $p.s; rgb = ($got -join ','); dmax = $dmax; pass = ($dmax -le 6); hl = $p.hl; len = $p.len; dir = $p.dir; tip = $p.tip; end = $p.end; baseW_at0_5 = $baseW; baseW_theory = [math]::Round(7.2 * (1 - 0.5 / $p.hl), 2); tailW_at0_6 = $tailW; tailW_theory = 1.8 }
    $cnt[$b]++
  }
  return [pscustomobject]@{ total = $pr.pts.Count; gap = $pr.gap; cvOff = $pr.cvOff; samples = $res }
}

Open-Page $url 9471
try {
  Wait-Ready
  if ($steep) {
    # 급경사(35° 이상) 표본 — 백운대 정상 주변, z18 · 화살표 보기 + 3배 확대 크롭
    Invoke-Js "document.querySelector('#pxView button[data-v=""arrow""]').click();1" | Out-Null; Start-Sleep -Milliseconds 800
    Invoke-Js "(()=>{document.querySelector('#q').value='37.65840, 126.97796'; document.querySelector('#sf').requestSubmit(); return 1})()" | Out-Null
    Start-Sleep -Milliseconds 3000; $null = Wait-Js "(()=>{const r=window.__KTS_ARROWS([[0.5,0.5]]); return !!(r&&r[0])})()" 30000; Start-Sleep -Milliseconds 5000
    for ($i = 0; $i -lt 8; $i++) { if ([double](Invoke-Js "window.__KTS_ST().zoom") -ge 17.9) { break }; Invoke-Js "document.querySelector('#zIn').click();1" | Out-Null; Start-Sleep -Milliseconds 150 }
    Start-Sleep -Milliseconds 3500
    $p = MapShot 'arrow_steep_baegundae'
    $R.AR_steep = J "JSON.stringify({arrows:window.__KTS_PX().arrows, ms:window.__KTS_PX().arrowMsMedian, zoom:window.__KTS_ST().zoom})"
    $R.A1_steep = Sample-Arrows $p 6
    # 3배 확대 크롭: 지도 카드 가운데 아래쪽 120x120 CSS px(= 240 장치 px) → 720px
    [ArChk]::Crop3($p, (Join-Path $Shots ($tag + '_arrow_crop3x_steep.png')), 216, 420, 240, 240)
    $p2 = Join-Path $Shots ('live_arrow_gapyeong.png'); if (Test-Path $p2) { [ArChk]::Crop3($p2, (Join-Path $Shots ($tag + '_arrow_crop3x_gapyeong.png')), 210, 270, 260, 250) }
    $R.AR_DRAW_ms = Invoke-Js "window.__KTS_PX().arrowMsMedian"
    return
  }
  $R.pnu0 = Invoke-Js "window.__KTS_ST().pnu"
  # A7 픽셀 보기(기본) — 표·캡처
  $R.pxDefault = J "JSON.stringify({px:window.__KTS_PX().on, view:[...document.querySelectorAll('#pxView button')].map(b=>b.dataset.v+':'+(b.classList.contains('on')?1:0)).join(',')})"
  $R.PXSTAT = J "JSON.stringify(window.__KTS_PXSTAT())"
  MapShot 'px_view' | Out-Null
  # 화살표 보기
  Invoke-Js "document.querySelector('#pxView button[data-v=""arrow""]').click();1" | Out-Null; Start-Sleep -Milliseconds 1200
  Pans 4
  $R.arrowNote = Invoke-Js "document.querySelector('.arrow-note').textContent"
  $pa = MapShot 'arrow_gapyeong'
  Shot (Join-Path $Shots ($tag + '_arrow_390_full.png'))
  $R.AR_gapyeong = J "JSON.stringify({arrows:window.__KTS_PX().arrows, ms:window.__KTS_PX().arrowMsMedian, zoom:window.__KTS_ST().zoom})"
  if ($pxOnly) { return }
  $R.A1_gapyeong = Sample-Arrows $pa 5
  $R.A4_gapyeong = J "JSON.stringify(window.__KTS_ARROWDIR())"
  # 위성 바탕
  Invoke-Js "document.querySelector('#togs button[data-l=""sat""]').click();1" | Out-Null; Start-Sleep -Milliseconds 4000
  $ps = MapShot 'arrow_gapyeong_sat'
  $R.A1_gapyeong_sat = Sample-Arrows $ps 5
  Invoke-Js "document.querySelector('#togs button[data-l=""sat""]').click();1" | Out-Null; Start-Sleep -Milliseconds 800
  # 확대(z18) — 같은 필지
  for ($i = 0; $i -lt 8; $i++) { if ([double](Invoke-Js "window.__KTS_ST().zoom") -ge 17.9) { break }; Invoke-Js "document.querySelector('#zIn').click();1" | Out-Null; Start-Sleep -Milliseconds 150 }
  Start-Sleep -Milliseconds 3500
  $pz = MapShot 'arrow_gapyeong_z18'
  $R.AR_gapyeong_z18 = J "JSON.stringify({arrows:window.__KTS_PX().arrows, ms:window.__KTS_PX().arrowMsMedian, zoom:window.__KTS_ST().zoom})"
  $R.A1_gapyeong_z18 = Sample-Arrows $pz 5
  # 필지 2·3
  foreach ($ex in @(@(4, 'yangpyeong'), @(3, 'namyangju'))) {
    Invoke-Js ("document.querySelectorAll('#chips button')[" + $ex[0] + "].click();1") | Out-Null
    Start-Sleep -Milliseconds 1500; Wait-Ready
    if (Invoke-Js "!!window.__KTS_PX().on") { Invoke-Js "document.querySelector('#pxView button[data-v=""arrow""]').click();1" | Out-Null; Start-Sleep -Milliseconds 800 }
    Pans 2
    $p = MapShot ('arrow_' + $ex[1])
    $R[('AR_' + $ex[1])] = J "JSON.stringify({pnu:window.__KTS_ST().pnu, jibun:window.__KTS_ST().jibun, arrows:window.__KTS_PX().arrows, ms:window.__KTS_PX().arrowMsMedian, zoom:window.__KTS_ST().zoom, pxOn:window.__KTS_PX().on})"
    $R[('A1_' + $ex[1])] = Sample-Arrows $p 5
    $R[('A4_' + $ex[1])] = J "JSON.stringify(window.__KTS_ARROWDIR())"
  }
  # A5 정상 2곳
  $R.A5 = @()
  foreach ($sm in @(@(37.65840, 126.97796, 'baegundae'), @(37.55125, 126.98820, 'namsan'))) {
    Invoke-Js ("(()=>{document.querySelector('#q').value='" + ('{0:F5}, {1:F5}' -f $sm[0], $sm[1]) + "'; document.querySelector('#sf').requestSubmit(); return 1})()") | Out-Null
    Start-Sleep -Milliseconds 2500; $null = Wait-Js "(()=>{const r=window.__KTS_ARROWS([[0.5,0.5]]); return !!(r&&r[0])})()" 30000; Start-Sleep -Milliseconds 5000
    if (Invoke-Js "!!window.__KTS_PX().on") { Invoke-Js "document.querySelector('#pxView button[data-v=""arrow""]').click();1" | Out-Null; Start-Sleep -Milliseconds 800 }
    $o = Summit $sm[0]; $o | Add-Member -NotePropertyName name -NotePropertyValue $sm[2]; $R.A5 += $o
    MapShot ('arrow_summit_' + $sm[2]) | Out-Null
  }
  # 기본 필지로 복귀 → A8 무회귀
  Invoke-Js "document.querySelectorAll('#chips button')[0].click();1" | Out-Null; Start-Sleep -Milliseconds 1500; Wait-Ready
  Invoke-Js "document.querySelector('#pxView button[data-v=""px""]').click();1" | Out-Null; Start-Sleep -Milliseconds 800
  $R.PXSTAT_after = J "JSON.stringify(window.__KTS_PXSTAT())"
  $R.A10 = J "JSON.stringify({sw:document.documentElement.scrollWidth, cw:document.documentElement.clientWidth})"
  $R.A8 = [ordered]@{}
  $R.A8.quota = Invoke-Js "document.querySelector('#freeTag').textContent+'|'+document.querySelector('#leftN').textContent+'|'+document.querySelector('#planTag').textContent"
  Invoke-Js "document.querySelector('#chkGo').click();1" | Out-Null; Start-Sleep -Milliseconds 1500
  $R.A8.resOpen = Invoke-Js "document.querySelector('#res').classList.contains('on')"
  Shot (Join-Path $Shots ($tag + '_A8_result_top.png'))
  Invoke-Js "document.querySelector('#resClose').click();1" | Out-Null; Start-Sleep -Milliseconds 400
  Invoke-Js "document.querySelector('#vmode button[data-v=""3d""]').click();1" | Out-Null; Start-Sleep -Milliseconds 4000
  $R.A8.d3 = Invoke-Js "(()=>{try{return JSON.stringify(window.__KTS_3D().st)}catch(e){return 'ERR '+e.message}})()"
  Invoke-Js "document.querySelector('#vmode button[data-v=""arch""]').click();1" | Out-Null; Start-Sleep -Milliseconds 3000
  $R.A8.arch = Invoke-Js "document.querySelector('#aBody').innerText.slice(0,120)"
  Invoke-Js "document.querySelector('#vmode button[data-v=""2d""]').click();1" | Out-Null; Start-Sleep -Milliseconds 800
  Invoke-Js "document.querySelector('#togs button[data-l=""zone""]').click();1" | Out-Null; Start-Sleep -Milliseconds 2500
  MapShot 'A8_zone_on' | Out-Null
  Invoke-Js "document.querySelector('#togs button[data-l=""zone""]').click();1" | Out-Null
  $R.A8.profile = Invoke-Js "document.querySelector('#pfcv').width+'x'+document.querySelector('#pfcv').height"
  $R.err = Invoke-Js "JSON.stringify(window.__KTS_ERR)"
} finally {
  $R.evts = (Evts-Summary); $R.evtList = @($global:EVTS | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(300, $_.text.Length)) })
  Stop-CdpChrome
  $out = Join-Path $OutDir ('verify_' + $tag + '_result.json')
  $R | ConvertTo-Json -Depth 12 | Set-Content -Encoding UTF8 $out
  Write-Output ('saved ' + $out)
}

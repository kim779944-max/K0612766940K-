# 경사도 단독 완결(2026-11-22) 검수 V2~V15 — 헤드리스 크롬 390x844 @2x
param([string]$url = '', [string]$tag = 'local')
. "$PSScriptRoot\..\..\slope3d_20261121\src\lib3d.ps1"
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
if (-not $url) { $url = To-FileUrl (Join-Path $OcRoot 'slope\index.html') }
$Shots = (Resolve-Path "$PSScriptRoot\..\shots").Path
$OutDir = (Resolve-Path "$PSScriptRoot\..").Path
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class PalChk {
  static int[][] P = new int[][]{ new[]{255,255,255},new[]{255,245,157},new[]{255,235,59},new[]{255,193,7},new[]{255,152,0},new[]{245,124,0},new[]{244,67,54},new[]{211,47,47},new[]{183,28,28},new[]{127,0,0} };
  // 영역 안 픽셀 중 SLOPE10 본색(±tol)과 같은 비율, 본색 별 개수
  public static string Frac(string path,int x0,int y0,int w,int h,int tol){
    using(var b=new Bitmap(path)){
      var r=new Rectangle(0,0,b.Width,b.Height); var d=b.LockBits(r,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
      var a=new byte[d.Stride*b.Height]; Marshal.Copy(d.Scan0,a,0,a.Length); int st=d.Stride; b.UnlockBits(d);
      long tot=0, hit=0; var per=new long[10];
      for(int j=Math.Max(0,y0);j<Math.Min(b.Height,y0+h);j++) for(int i=Math.Max(0,x0);i<Math.Min(b.Width,x0+w);i++){
        int o=j*st+i*4; int B=a[o],G=a[o+1],R=a[o+2]; tot++;
        for(int k=0;k<10;k++){ if(Math.Abs(R-P[k][0])<=tol&&Math.Abs(G-P[k][1])<=tol&&Math.Abs(B-P[k][2])<=tol){ hit++; per[k]++; break; } }
      }
      return "{\"tot\":"+tot+",\"hit\":"+hit+",\"frac\":"+(tot>0?Math.Round((double)hit/tot,4):0)+",\"per\":["+string.Join(",",per)+"]}";
    }
  }
  // 초록·청록·남색·자주 계열 픽셀 수(지도 바탕 제외 영역에서) — 색상환 H 90~290°, 채도>0.35, 명도>0.25
  public static long Cool(string path,int x0,int y0,int w,int h){
    using(var b=new Bitmap(path)){ long n=0;
      for(int j=Math.Max(0,y0);j<Math.Min(b.Height,y0+h);j++) for(int i=Math.Max(0,x0);i<Math.Min(b.Width,x0+w);i++){
        var c=b.GetPixel(i,j); float H=c.GetHue(), S=c.GetSaturation(), L=c.GetBrightness(); if(H>=90&&H<=290&&S>0.35&&L>0.25&&L<0.9) n++; }
      return n; }
  }
}
"@
$R = [ordered]@{ url = $url; tag = $tag; at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
function J([string]$e) { $t = Invoke-Js $e; if ($t) { return ($t | ConvertFrom-Json) } return $null }
function Zoom-To([double]$z) { for ($i = 0; $i -lt 40; $i++) { $c = [double](Invoke-Js "window.__KTS_ST().zoom"); if ([math]::Abs($c - $z) -lt 0.26) { break }; if ($c -lt $z) { Invoke-Js "document.querySelector('#zIn').click();1" | Out-Null } else { Invoke-Js "document.querySelector('#zOut').click();1" | Out-Null }; Start-Sleep -Milliseconds 120 }; Start-Sleep -Milliseconds 3200; return [double](Invoke-Js "window.__KTS_ST().zoom") }
function MapShot([string]$name) { $p = Join-Path $Shots ($tag + '_' + $name + '.png'); Shot-Clip $p '.mapwrap'; return $p }
function Pans([int]$n) { $m = Rect '.mapwrap'; for ($i = 0; $i -lt $n; $i++) { $dx = if ($i % 2) { 14 } else { -14 }; Drag ($m.x + $m.w / 2) ($m.y + $m.h / 2) ($m.x + $m.w / 2 + $dx) ($m.y + $m.h / 2) 6; Start-Sleep -Milliseconds 120 } ; Start-Sleep -Milliseconds 1500 }

Open-Page $url 9463
try {
  $R.ready = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 30000
  $R.pc = Wait-Js "window.__KTS_ST().pcLoaded" 15000
  Start-Sleep -Milliseconds 2500
  # V2 픽셀 기본
  $R.V2 = J "JSON.stringify({px:window.__KTS_PX().on, viewOn:[...document.querySelectorAll('#pxView button')].map(b=>b.dataset.v+':'+(b.classList.contains('on')?1:0)).join(','), arrowTog:document.querySelector('#togs button[data-l=""arrow""]').classList.contains('on'), noteShown:!document.querySelector('#pxNote').classList.contains('hide'), opRow:getComputedStyle(document.querySelector('#opRow')).display, layers:[...document.querySelectorAll('#togs button')].map(b=>b.dataset.l+':'+(b.classList.contains('on')?1:0)).join(','), lsKeys:Object.keys(localStorage).filter(k=>/px|view/i.test(k))})"
  # V3 팔레트
  $R.V3 = J "JSON.stringify({hex:window.__KTS_PXSTAT().bands.map(b=>b.hex), legend:[...document.querySelectorAll('#cbar i')].map(i=>getComputedStyle(i).backgroundColor), aleg:!!document.querySelector('#aleg'), palette:window.__KTS_PX().palette})"
  $R.V3_srcForbidden = @('#1F9F6E', '#4FBF57', '#B7D34A', '#1E3E6C', '#10284C', '#A4143C', '31,159,110', '16,40,76', '30,62,108', '164,20,60') | Where-Object { (Invoke-Js ("document.documentElement.outerHTML.indexOf('" + $_ + "')>=0")) }
  $R.V3_srcForbidden = @($R.V3_srcForbidden)
  # V4 필지 전역
  $st = J "JSON.stringify(window.__KTS_PXSTAT())"
  $R.V4 = [ordered]@{ totalArea = $st.totalArea; parcelArea = $st.parcelArea; ratio = $(if ($st.parcelArea) { [math]::Round($st.totalArea / $st.parcelArea, 4) } else { $null }); bb = (J "JSON.stringify((b=>({x0:b.bx,y0:b.by,x1:b.bX,y1:b.bY}))(window.__KTS_ST().bb))"); radiusPx = (Invoke-Js "Math.round(100/(156543.03392*Math.cos(window.__KTS_ST().zoom*0+37.8319*Math.PI/180)/Math.pow(2,window.__KTS_ST().zoom)))") }
  $R.PXSTAT = $st
  $p = MapShot 'V4_z16_parcel_full'
  $R.V3_coolPixelsInParcel = [PalChk]::Cool($p, [int]($R.V4.bb.x0 * 2 + 20), [int]($R.V4.bb.y0 * 2 + 20), [int](($R.V4.bb.x1 - $R.V4.bb.x0) * 2 - 40), [int](($R.V4.bb.y1 - $R.V4.bb.y0) * 2 - 40))
  Shot-Clip (Join-Path $Shots ($tag + '_V3_legend.png')) '.legend'
  # V7 z16
  $nd = [ordered]@{}
  $px = J "JSON.stringify(window.__KTS_PX())"; $nd['z16.2'] = [ordered]@{ zoom = 16.2; numbersDrawn = $px.numbersDrawn; blockPx = $px.blockPx; cellPx = $px.cellPx; vec = $px.vecPath }
  Pans 4
  # z18
  $z = Zoom-To 18.1; $px = J "JSON.stringify(window.__KTS_PX())"; $nd['z18'] = [ordered]@{ zoom = $z; numbersDrawn = $px.numbersDrawn; blockPx = $px.blockPx; cellPx = $px.cellPx; vec = $px.vecPath }
  MapShot 'V7_z18' | Out-Null
  # z19
  $z = Zoom-To 19.1; $px = J "JSON.stringify(window.__KTS_PX())"; $nd['z19'] = [ordered]@{ zoom = $z; numbersDrawn = $px.numbersDrawn; blockPx = $px.blockPx; cellPx = $px.cellPx; vec = $px.vecPath }
  $p19 = MapShot 'V6_z19'
  Pans 4
  # V8 칸 탭 3개(구간이 다른 칸)
  $m = Rect '.mapwrap'; $taps = @(); $bands = @{}
  foreach ($f in @(@(0.5, 0.45), @(0.3, 0.3), @(0.7, 0.6), @(0.4, 0.7), @(0.6, 0.3), @(0.25, 0.55), @(0.75, 0.4), @(0.55, 0.8), @(0.35, 0.5), @(0.65, 0.5))) {
    if ($taps.Count -ge 3) { break }
    $x = $m.x + $m.w * $f[0]; $y = $m.y + $m.h * $f[1]
    $cell = J ("JSON.stringify(window.__KTS_PXCELL(" + ($m.w * $f[0]) + "," + ($m.h * $f[1]) + "))")
    if (-not $cell -or $bands.ContainsKey([string]$cell.band)) { continue }
    Tap $x $y; Start-Sleep -Milliseconds 500
    $tip = Invoke-Js "document.querySelector('#pxTip').textContent"
    $last = J "JSON.stringify(window.__KTS_PX().last)"
    $bands[[string]$cell.band] = 1
    $taps += [pscustomobject]@{ at = $f; tip = $tip; cell = $cell; lastSame = ($last.num -eq $cell.num -and $last.slope -eq $cell.slope -and $last.elev -eq $cell.elev); tipHasNum = ($tip -match ('^' + $cell.num + '번 칸')) }
    MapShot ('V8_tap' + $taps.Count) | Out-Null
  }
  $R.V8 = $taps
  # 번호와 목록 같은 번호(목록의 n번 평균 = PXNUM)
  $R.V8_num1 = J "JSON.stringify(window.__KTS_PXNUM(1))"
  # z20 / V6
  $z = Zoom-To 20.1; $px = J "JSON.stringify(window.__KTS_PX())"; $nd['z20'] = [ordered]@{ zoom = $z; numbersDrawn = $px.numbersDrawn; blockPx = $px.blockPx; cellPx = $px.cellPx; vec = $px.vecPath }
  $p20 = MapShot 'V6_z20'
  Invoke-Js "document.querySelector('#togs button[data-l=""cont""]').click();1" | Out-Null; Start-Sleep -Milliseconds 700
  $p20n = MapShot 'V6_z20_contour_off'
  $R.V6 = [ordered]@{ paletteFrac_z20_noContour = ([PalChk]::Frac($p20n, 80, 160, 500, 420, 2) | ConvertFrom-Json); paletteFrac_z19 = ([PalChk]::Frac($p19, 80, 160, 500, 420, 2) | ConvertFrom-Json); coolPx_z20 = [PalChk]::Cool($p20n, 80, 160, 500, 420); src_globalAlpha092 = [bool](Invoke-Js "document.documentElement.outerHTML.indexOf('globalAlpha=0.92')>=0") }
  Invoke-Js "document.querySelector('#togs button[data-l=""cont""]').click();1" | Out-Null; Start-Sleep -Milliseconds 400
  # z22
  $z = Zoom-To 22; $px = J "JSON.stringify(window.__KTS_PX())"; $nd['z22'] = [ordered]@{ zoom = $z; numbersDrawn = $px.numbersDrawn; blockPx = $px.blockPx; cellPx = $px.cellPx; vec = $px.vecPath }
  MapShot 'V10_z22' | Out-Null
  Pans 6
  $R.V7 = $nd
  $R.V10 = J "JSON.stringify((({bb,...o})=>o)(window.__KTS_ST()))"
  $R.perf_z22 = J "JSON.stringify(window.__KTS_PX().frameMsMedian)"
  # V9 화살표 보기 (z17.6 · z19)
  $z = Zoom-To 17.6
  Invoke-Js "document.querySelector('#pxView button[data-v=""arrow""]').click();1" | Out-Null; Start-Sleep -Milliseconds 900
  Pans 4
  $pa = MapShot 'V9_arrow_z17_6'
  $R.V9 = [ordered]@{ z17 = (J "JSON.stringify({px:window.__KTS_PX().on,arrows:window.__KTS_PX().arrows,ms:window.__KTS_PX().arrowMsMedian,numbersDrawn:window.__KTS_PX().numbersDrawn})"); paletteFracInParcel = $null }
  $z = Zoom-To 19.1; Pans 2
  MapShot 'V9_arrow_z19' | Out-Null
  $R.V9.z19 = J "JSON.stringify({arrows:window.__KTS_PX().arrows,ms:window.__KTS_PX().arrowMsMedian})"
  Invoke-Js "document.querySelector('#togs button[data-l=""sat""]').click();1" | Out-Null; Start-Sleep -Milliseconds 3500
  MapShot 'V9_arrow_z19_sat' | Out-Null
  $z = Zoom-To 17.6; Start-Sleep -Milliseconds 2000
  MapShot 'V9_arrow_z17_6_sat' | Out-Null
  Invoke-Js "document.querySelector('#togs button[data-l=""sat""]').click();1" | Out-Null
  $R.perf_arrow = J "JSON.stringify(window.__KTS_PX().frameMsMedian)"
  Invoke-Js "document.querySelector('#pxView button[data-v=""px""]').click();1" | Out-Null
  $z = Zoom-To 16.2; Start-Sleep -Milliseconds 1500
  # V11 / V12 표
  Shot-Clip (Join-Path $Shots ($tag + '_V11_table.png')) '#pxStat'
  $R.V11 = J "JSON.stringify({rows:document.querySelectorAll('#pxStat table')[0].querySelectorAll('tbody tr').length, sumRow:document.querySelector('#pxStat tr.sum').innerText, foot:document.querySelector('#pxStat .sn').innerText, swatch:[...document.querySelectorAll('#pxStat .sw')].map(s=>getComputedStyle(s).backgroundColor), areaCheck:window.__KTS_PXSTAT().bands.every(b=>Math.abs(b.area-+(b.cells*25/(window.__KTS_PXSTAT().sub**2)).toFixed(1))<0.06), sumPct:window.__KTS_PXSTAT().sumPct})"
  $R.V12 = [ordered]@{ closedDefault = (Invoke-Js "!document.querySelector('#pxStat details').open"); summary = (Invoke-Js "document.querySelector('#pxStat summary').innerText") }
  Invoke-Js "document.querySelector('#pxStat summary').click();1" | Out-Null; Start-Sleep -Milliseconds 300
  $R.V12.rowsPage1 = Invoke-Js "document.querySelectorAll('#pxStat details tbody tr').length"
  $R.V12.firstRow = Invoke-Js "document.querySelector('#pxStat details tbody tr').innerText"
  $R.V12.pxnum1 = J "JSON.stringify(window.__KTS_PXNUM(1))"
  Shot-Clip (Join-Path $Shots ($tag + '_V12_list_open.png')) '#pxStat'
  Invoke-Js "document.querySelector('#pxStat button[data-pg=""1""]').click();1" | Out-Null; Start-Sleep -Milliseconds 300
  $R.V12.page2 = Invoke-Js "document.querySelector('#pxStat .pg span').innerText+' | '+document.querySelector('#pxStat details tbody tr').innerText"
  $R.V12.nums = Invoke-Js "window.__KTS_PX().nums"
  $findN = [int](Invoke-Js "Math.min(window.__KTS_PX().nums, 77)")
  Invoke-Js ("(()=>{const i=document.querySelector('#pxStat .pg input'); i.value='" + $findN + "'; i.dispatchEvent(new Event('change',{bubbles:true})); return 1})()") | Out-Null; Start-Sleep -Milliseconds 500
  $R.V12.find = Invoke-Js "document.querySelector('#pxStat .pg span').innerText+' | hl='+(document.querySelector('#pxStat tr.hl')||{innerText:'none'}).innerText"
  Shot-Clip (Join-Path $Shots ($tag + '_V12_find.png')) '#pxStat'
  MapShot 'V12_find_on_map' | Out-Null
  # V13
  $R.V13 = J "JSON.stringify({sw:document.documentElement.scrollWidth, cw:document.documentElement.clientWidth, tableW:document.querySelector('#pxStat table').scrollWidth})"
  Shot (Join-Path $Shots ($tag + '_V13_390_full_top.png'))
  # V14 무회귀 — 결과 전체뷰·3D·건축·용도지역·무료 3건 문구
  $R.V14 = [ordered]@{}
  $R.V14.quota = Invoke-Js "document.querySelector('#freeTag').textContent+'|'+document.querySelector('#leftN').textContent+'|'+document.querySelector('#planTag').textContent"
  $R.V14.buy = Invoke-Js "decodeURIComponent(document.querySelector('#buy').href)"
  Invoke-Js "document.querySelector('#chkGo').click();1" | Out-Null; Start-Sleep -Milliseconds 1500
  $R.V14.resOpen = Invoke-Js "document.querySelector('#res').classList.contains('on')"
  $R.V14.resStat = Invoke-Js "!!document.querySelector('#resPxStat table') && document.querySelector('#resPxStat details').open===document.querySelector('#pxStat details').open && document.querySelector('#resPxStat tr.sum').innerText===document.querySelector('#pxStat tr.sum').innerText"
  Invoke-Js "document.querySelector('#resPxStat').scrollIntoView();1" | Out-Null
  Shot (Join-Path $Shots ($tag + '_V14_result_stat.png'))
  Invoke-Js "document.querySelector('.rvw').scrollTop=0;1" | Out-Null; Start-Sleep -Milliseconds 300
  Shot (Join-Path $Shots ($tag + '_V14_result_top.png'))
  Invoke-Js "document.querySelector('#resClose').click();1" | Out-Null; Start-Sleep -Milliseconds 400
  Invoke-Js "document.querySelector('#vmode button[data-v=""3d""]').click();1" | Out-Null; Start-Sleep -Milliseconds 4000
  $R.V14.d3 = Invoke-Js "(()=>{try{return JSON.stringify(window.__KTS_3D().st)}catch(e){return 'ERR '+e.message}})()"
  Invoke-Js "document.querySelector('#vmode button[data-v=""arch""]').click();1" | Out-Null; Start-Sleep -Milliseconds 3000
  $R.V14.arch = Invoke-Js "document.querySelector('#aBody').innerText.slice(0,160)"
  Invoke-Js "document.querySelector('#vmode button[data-v=""2d""]').click();1" | Out-Null; Start-Sleep -Milliseconds 800
  Invoke-Js "document.querySelector('#togs button[data-l=""zone""]').click();1" | Out-Null; Start-Sleep -Milliseconds 2500
  MapShot 'V14_zone_on' | Out-Null
  Invoke-Js "document.querySelector('#togs button[data-l=""zone""]').click();1" | Out-Null
  Invoke-Js "document.querySelector('#togs button[data-l=""slope""]').click();1" | Out-Null; Start-Sleep -Milliseconds 600
  $R.V14.opRowWithSlopeInPx = Invoke-Js "getComputedStyle(document.querySelector('#opRow')).display"
  Invoke-Js "document.querySelector('#pxView button[data-v=""arrow""]').click();1" | Out-Null; Start-Sleep -Milliseconds 600
  $R.V14.opRowWithSlopeInArrow = Invoke-Js "getComputedStyle(document.querySelector('#opRow')).display"
  MapShot 'V14_slope_layer_10color' | Out-Null
  Invoke-Js "document.querySelector('#togs button[data-l=""slope""]').click();1" | Out-Null
  Invoke-Js "document.querySelector('#pxView button[data-v=""px""]').click();1" | Out-Null
  # V15
  Pans 6
  $R.V15 = J "JSON.stringify(window.__KTS_PX())"
  $R.err = Invoke-Js "JSON.stringify(window.__KTS_ERR)"
  $R.evts = (Evts-Summary); $R.evtList = @($global:EVTS | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(300, $_.text.Length)) })
  Clear-Evts
  # V5 필지 없음 — 키를 비운 상태(PC 없음)로 다시 열기
  Invoke-Js "localStorage.setItem('kts_slope_vk','');1" | Out-Null
  Go-Url $url 3000
  $null = Wait-Js "!!(document.querySelector('#resTag').textContent.indexOf('평균')>=0)" 30000
  Start-Sleep -Milliseconds 2500
  $R.V5 = J "JSON.stringify({st:(({bb,...o})=>o)(window.__KTS_ST()), stat:window.__KTS_PXSTAT(), px:{n:window.__KTS_PX().n,ny:window.__KTS_PX().ny,parcel:window.__KTS_PX().parcel}, foot:document.querySelector('#pxStat .sn').innerText})"
  MapShot 'V5_noparcel_square' | Out-Null
  Invoke-Js "localStorage.removeItem('kts_slope_vk');1" | Out-Null
  $R.V5_evts = (Evts-Summary)
} finally { Stop-CdpChrome }
$out = Join-Path $OutDir ('verify_' + $tag + '_result.json')
$R | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $out
Get-Content $out -Raw -Encoding UTF8

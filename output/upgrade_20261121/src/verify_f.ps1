param([switch]$live)
. "$PSScriptRoot\lib.ps1"
Start-Serve
$R = [ordered]@{}
$new4 = 'gagebu', 'hogang', 'golf', 'petmind'
try {
  Open-Page ($global:Base + 'index.html') 9411
  Start-Sleep -Milliseconds 2500
  # F1 두 목록 동일 — products.js 내장 배열(window.PRODUCTS 초기값)은 파일을 직접 읽어 비교
  $R.F1 = Js @'
var c=await (await fetch('http://127.0.0.1:8765/catalog.json',{cache:'no-store'})).json();
var src=await (await fetch('http://127.0.0.1:8765/products.js',{cache:'no-store'})).text();
var m=src.match(/window\.PRODUCTS = (\[[\s\S]*?\n\]);/); var arr=JSON.parse(m[1]);
var ck=c.products.map(function(p){return p.k}), pk=arr.map(function(p){return p.k});
var onlyC=ck.filter(function(k){return pk.indexOf(k)<0}), onlyP=pk.filter(function(k){return ck.indexOf(k)<0});
var fieldDiff=c.products.filter(function(p,i){return JSON.stringify(p)!==JSON.stringify(arr.filter(function(q){return q.k===p.k})[0])}).map(function(p){return p.k});
return JSON.stringify({catalogCount:c.count,catalogLen:ck.length,productsLen:pk.length,onlyCatalog:onlyC,onlyProducts:onlyP,fieldDiff:fieldDiff,v:c.v,updated:c.updated,new4:['gagebu','hogang','golf','petmind'].map(function(k){var p=c.products.filter(function(x){return x.k===k})[0];return p?k+':'+p.cat+':'+p.icon+':'+p.shot:k+':MISSING'})});
'@
  # F4 문구
  $R.F4 = Js @'
var c=await (await fetch('http://127.0.0.1:8765/catalog.json',{cache:'no-store'})).json();
var n=c.products.filter(function(p){return p.k==='navi'})[0], r=c.products.filter(function(p){return p.k==='redev'})[0];
return JSON.stringify({navi:{nm:n.nm,sub:n.sub,price:n.price,badge:n.badge,line:n.line},redev:{sub:r.sub,blurbMoa:(r.blurb.match(/모아타운 64곳[^.]*/)||[''])[0]}});
'@
  # F5 ytsummary
  $R.F5 = Js @'
var a=await Promise.all(['catalog.json','products.js','index.html','sitemap.xml'].map(function(f){return fetch('http://127.0.0.1:8765/'+f,{cache:'no-store'}).then(function(r){return r.text()}).then(function(t){return f+':'+(t.match(/ytsummary/g)||[]).length})}));
return JSON.stringify(a);
'@
  # F6 허브 카드 노출
  $R.F6 = J @'
var out={};['gagebu','hogang','golf','petmind'].forEach(function(k){var a=document.querySelector('a.main[href="detail.html?k='+k+'"]'),b=document.querySelector('button[data-open="'+k+'"]');out[k]=a?{text:a.closest('.row').innerText.replace(/\s+/g,' ').slice(0,70),detail:a.getAttribute('href'),openBtn:!!b,icon:((a.closest('.row').querySelector('.ico img')||{}).src||'')}:null});
out.sw=document.documentElement.scrollWidth;return JSON.stringify(out);
'@
  J "var a=document.querySelector('a.main[href=\x22detail.html?k=gagebu\x22]');if(a){a.scrollIntoView({block:'center'})}return 1" | Out-Null
  Start-Sleep -Milliseconds 500
  ShotP 'F6_hub_life_group.png'
  # 클릭 이동(새 창 대신 같은 창으로) — hogang
  J "document.querySelector('button[data-open=hogang]').click();return 1" | Out-Null
  Start-Sleep -Milliseconds 2500
  $R.F6click = J "return location.pathname+location.search+' | '+document.title"
  # 상세 페이지 4종
  $d = @()
  foreach ($k in $new4) { Go-Url ($global:Base + 'detail.html?k=' + $k) 2200; $d += (J "return '$k | '+document.title+' | '+(document.body.innerText.indexOf('준비 중')>=0?'준비중표시':'ok')+' | sw='+document.documentElement.scrollWidth") }
  $R.detail = $d
  ShotP 'F6_detail_petmind.png'
  $R.evts = Evts-Summary
  $R.evtList = @($global:EVTS | Select-Object -First 5 | ForEach-Object { $_.kind + ' :: ' + $_.text })
} finally { Stop-CdpChrome }
# F2 링크 200 (로컬 · 실서비스)
$f2 = [ordered]@{}
foreach ($k in $new4) {
  try { $f2["local_$k"] = (Invoke-WebRequest -UseBasicParsing ($global:Base + $k + '/')).StatusCode } catch { $f2["local_$k"] = $_.Exception.Message }
  if ($live) { try { $f2["live_$k"] = (Invoke-WebRequest -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } ("https://autooneclick.com/" + $k + "/")).StatusCode } catch { $f2["live_$k"] = $_.Exception.Message } }
}
$R.F2 = $f2
# F3 아이콘·샷 크기
Add-Type -AssemblyName System.Drawing
$f3 = @()
foreach ($k in $new4) {
  foreach ($f in @("shots\ic_$k.png", "shots\${k}_home.png")) { $p = Join-Path $global:OcRoot $f; if (Test-Path $p) { $b = [Drawing.Image]::FromFile($p); $f3 += "$f $($b.Width)x$($b.Height)"; $b.Dispose() } else { $f3 += "$f MISSING" } }
}
$R.F3 = $f3
$R | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot ('..\verify_f_result' + $(if ($live) { '_live' } else { '' }) + '.json'))
$R | ConvertTo-Json -Depth 6

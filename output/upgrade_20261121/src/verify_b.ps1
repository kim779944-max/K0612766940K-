. "$PSScriptRoot\lib.ps1"
Start-Serve
$R = [ordered]@{}
$pages = @(@{ k = 'golf'; api = '__GOLF'; port = 9376 }, @{ k = 'petmind'; api = '__PET'; port = 9377 })
foreach ($p in $pages) {
  $o = [ordered]@{}
  try {
    Open-Page ($global:Base + $p.k + '/') $p.port
    Start-Sleep -Milliseconds 1500
    J "window.scrollTo(0,document.body.scrollHeight);return 1" | Out-Null; Start-Sleep -Milliseconds 900; J "window.scrollTo(0,0);return 1" | Out-Null
    $o.B1 = J "return JSON.stringify({svg:document.querySelectorAll('svg').length,canvas:document.querySelectorAll('canvas').length})"
    $o.imgs = J "var a=[].map.call(document.querySelectorAll('img'),function(i){return {src:i.getAttribute('src'),ok:i.complete&&i.naturalWidth>0,w:i.naturalWidth}});return JSON.stringify({n:a.length,broken:a.filter(function(x){return !x.ok}).map(function(x){return x.src})})"
    $o.title = J "return document.title+' | h1='+document.querySelector('h1').firstChild.textContent+' | og='+((document.querySelector('meta[property=\'og:title\']')||{}).content||'-')"
    $o.credit = J "var a=[].filter.call(document.querySelectorAll('a'),function(x){return x.textContent.trim()==='사진 출처'});return JSON.stringify({links:a.length,href:a.length?a[0].getAttribute('href'):''})"
    $o.B6 = J @"
var A=window.$($p.api),miss=[],noNum=[];
A.ORDER.forEach(function(k){var s=A.FIX[k].s; if(s.length!==6) miss.push(k+':'+s.length); s.forEach(function(t,i){ if(!t||t.length<20) miss.push(k+'#'+(i+1)); if(i>=1&&i<=3&&!/\d/.test(t)) noNum.push(k+'#'+(i+1)); });});
return JSON.stringify({items:A.ORDER.length,names:A.ORDER.map(function(k){return A.FIX[k].nm}),missingSteps:miss,stepsWithoutNumber:noNum,imgsPerItem:A.ORDER.map(function(k){return A.FIX[k].img.length})});
"@
    # 6단 DOM 렌더 확인(모든 항목 클릭)
    $o.render = J @"
var A=window.$($p.api),bad=[];
[].forEach.call(document.querySelectorAll('[data-k]'),function(b){b.click(); var n=document.querySelectorAll('#fixBox .steps6 li').length, im=document.querySelectorAll('#fixBox img').length; if(n!==6||im<1) bad.push(b.dataset.k+':'+n+'/'+im);});
return JSON.stringify({clicked:document.querySelectorAll('[data-k]').length,bad:bad});
"@
    # B5 390 · 잘림
    $o.B5 = J @"
var clip=[].filter.call(document.querySelectorAll('main *'),function(e){var cs=getComputedStyle(e);if(!e.textContent.trim()||e.children.length)return false;return (e.scrollWidth-e.clientWidth>1&&cs.overflowX!=='visible')||cs.textOverflow==='ellipsis';}).map(function(e){return e.tagName+':'+e.textContent.slice(0,20)});
return JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,clipped:clip});
"@
    # 캡처 6장(상·중·하)
    $first = J "return document.querySelector('[data-k]').dataset.k"
    J "document.querySelector('[data-k=\'$first\']').click();window.scrollTo(0,0);return 1" | Out-Null
    Start-Sleep -Milliseconds 400; ShotP ($p.k + '_1_top.png')
    $H = [int](J "return document.documentElement.scrollHeight")
    $i = 2
    foreach ($f in 0.18, 0.36, 0.54, 0.72, 1.0) {
      J "window.scrollTo(0,Math.round(($H-innerHeight)*$f));return 1" | Out-Null
      Start-Sleep -Milliseconds 500
      ShotP ($p.k + '_' + $i + '_' + [int]($f * 100) + '.png'); $i++
    }
    ShotFull ($p.k + '_full.png')
    $o.evts = Evts-Summary
    $o.evtList = @($global:EVTS | Select-Object -First 5 | ForEach-Object { $_.kind + ' :: ' + $_.text })
  } finally { Stop-CdpChrome; $global:EVTS.Clear() }
  # B2 파일 실재·용량
  $files = Get-ChildItem (Join-Path $global:OcRoot ($p.k + '\img')) -Filter *.webp
  $o.B2 = @{ count = $files.Count; maxKB = [math]::Round(($files | Measure-Object Length -Maximum).Maximum / 1KB, 1); over120 = @($files | Where-Object { $_.Length -gt 120KB } | ForEach-Object Name) }
  # B1 소스 검사
  $src = [IO.File]::ReadAllText((Join-Path $global:OcRoot ($p.k + '\index.html')), [Text.Encoding]::UTF8)
  $o.B1src = @{ svgTag = ([regex]::Matches($src, '<svg')).Count; createNS = ([regex]::Matches($src, 'createElementNS')).Count; canvas = ([regex]::Matches($src, '<canvas|getContext')).Count }
  # B3 라이선스
  $cr = [IO.File]::ReadAllText((Join-Path $global:OcRoot ($p.k + '\img\CREDITS.md')), [Text.Encoding]::UTF8)
  $lic = [regex]::Matches($cr, '\| (CC0|CC BY[^|]*|Public domain|PD[^|]*) \|') | ForEach-Object { $_.Groups[1].Value.Trim() }
  $o.B3 = @{ rows = ([regex]::Matches($cr, '(?m)^\| `')).Count; licenses = ($lic | Group-Object | ForEach-Object { $_.Name + ':' + $_.Count }); banned = ([regex]::Matches($cr, 'NC|ND|All rights')).Count }
  $R[$p.k] = $o
}
# B4 이름 (두 페이지 + 쇼룸 2파일 + 허브)
$old = @('강아지·고양이 마음 번역기', '펫마인드', '마음 번역기')
$hits = @()
foreach ($f in 'golf\index.html', 'petmind\index.html', 'products.js', 'catalog.json', 'index.html') {
  $t = [IO.File]::ReadAllText((Join-Path $global:OcRoot $f), [Text.Encoding]::UTF8)
  foreach ($w in $old) { $c = ([regex]::Matches($t, [regex]::Escape($w))).Count; if ($c) { $hits += "${f}:${w}=${c}" } }
}
$R.B4 = @{ oldNameHits = $hits }
$R | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_b_result.json')
$R | ConvertTo-Json -Depth 6

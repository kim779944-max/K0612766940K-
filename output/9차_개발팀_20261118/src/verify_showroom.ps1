# 쇼룸 첫 화면(index.html)·상세(detail.html) 등록 확인 — 타일 10개 · 목록 카드 · 상세 페이지 · 아이콘/캡처 로드
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$dir = Join-Path $OUT 'shots\showroom'; New-Item -ItemType Directory -Force $dir | Out-Null
$K = 'faqbot', 'csreply', 'leadscore', 'kakaotalk', 'weeksummary', 'booking', 'visitlog', 'funnel3', 'listing', 'docs'
$log = @()
Open-App 'oneclick\index.html' 9391
try {
  $log += 'index count: ' + (Invoke-Js "document.querySelector('#count').textContent") + ' / products total=' + (Invoke-Js 'String(window.PRODUCTS.length)')
  $tj = @'
JSON.stringify(KLIST.map(k=>k+":tile="+!!document.querySelector('.quick a[href="'+k+'.html"]')+",list="+!!document.querySelector('.pbtns a.go[href="'+k+'.html"]')))
'@
  $log += 'new tiles: ' + (Invoke-Js ($tj.Replace('KLIST', (ConvertTo-Json @($K) -Compress))))
  $log += 'broken images: ' + (Invoke-Js "JSON.stringify([...document.images].filter(i=>i.complete&&!i.naturalWidth).map(i=>i.getAttribute('src')))")
  $log += 'sw=' + (Invoke-Js 'document.documentElement.scrollWidth') + ' errs=' + (Invoke-Js 'JSON.stringify(window.__errs)')
  Save-Screenshot (Join-Path $dir 'index_top.png')
  Invoke-Js "(()=>{document.querySelector('.quick+.quick, .quick[style]').scrollIntoView({block:'start'}); return 1})()" | Out-Null; Start-Sleep -Milliseconds 300
  Save-Screenshot (Join-Path $dir 'index_tiles.png')
  # 타일 실제 탭 → 앱 열림
  $r = Rect '.quick a[href="booking.html"]'; Tap ($r.x + $r.w / 2) ($r.y + $r.h / 2); Start-Sleep -Milliseconds 1800
  $log += 'tap booking tile -> ' + (Invoke-Js 'location.pathname.split("/").pop()') + ' title=' + (Invoke-Js 'document.title')
  foreach ($k in $K) {
    Invoke-Js ("(()=>{location.href=location.href.replace(/[^/]*$/,'detail.html?k=" + $k + "'); return 1})()") | Out-Null; Start-Sleep -Milliseconds 1500
    Start-Sleep -Milliseconds 300
    $log += ('detail ' + $k + ': h1="' + (Invoke-Js "(document.querySelector('h1')||{}).textContent||''") + '" open=' + (Invoke-Js ('(()=>{const a=[...document.querySelectorAll("a")].find(a=>(a.getAttribute("href")||"")==="KK.html");return a?a.getAttribute("href"):"none"})()'.Replace('KK', $k))) + ' brokenImg=' + (Invoke-Js "JSON.stringify([...document.images].filter(i=>i.complete&&!i.naturalWidth).map(i=>i.getAttribute('src')))") + ' sw=' + (Invoke-Js 'document.documentElement.scrollWidth') + ' errs=' + (Invoke-Js 'JSON.stringify(window.__errs)'))
  }
  Save-Screenshot (Join-Path $dir 'detail_docs.png')
} finally { Stop-CdpChrome }
$log | Set-Content -Encoding UTF8 (Join-Path $dir 'run_log.txt')
$log

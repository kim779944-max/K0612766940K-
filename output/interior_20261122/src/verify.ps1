# 적립 128번 인테리어 견적기 검수 — 헤드리스 크롬 390x844 @2x (file://)
param([string]$url = '', [string]$tag = 'local')
. "$PSScriptRoot\..\..\slope3d_20261121\src\lib3d.ps1"
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$KRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$Cap = Join-Path $KRoot '_captures\interior_20261122'; if (-not (Test-Path $Cap)) { New-Item -ItemType Directory $Cap | Out-Null }
if (-not $url) { $url = To-FileUrl (Join-Path $OcRoot 'interior\index.html') }
$R = [ordered]@{ url = $url; at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
function J([string]$e) { $t = Invoke-Js $e; if ($t) { return ($t | ConvertFrom-Json) } return $null }
function St { return (J "JSON.stringify(window.__KTS_INTERIOR())") }
function Click([string]$sel) { Invoke-Js ("document.querySelector('" + $sel + "').click();1") | Out-Null; Start-Sleep -Milliseconds 250 }
function Key([string]$k, [int]$code) {
  Send-Cdp 'Input.dispatchKeyEvent' @{ type = 'rawKeyDown'; key = $k; code = $k; windowsVirtualKeyCode = $code } | Out-Null
  Send-Cdp 'Input.dispatchKeyEvent' @{ type = 'keyUp'; key = $k; code = $k; windowsVirtualKeyCode = $code } | Out-Null
}

Open-Page $url 9481
try {
  Start-Sleep -Milliseconds 1200
  # 첫 화면
  Shot (Join-Path $Cap '01_home_390.png')
  Copy-Item (Join-Path $Cap '01_home_390.png') (Join-Path $OcRoot 'shots\interior_home.png') -Force
  $R.layout = J "JSON.stringify({sw:document.documentElement.scrollWidth, cw:document.documentElement.clientWidth, minBtn:Math.min(...[...document.querySelectorAll('button,.btn,.pick,input[type=number],input[type=range]')].filter(e=>e.offsetParent).map(e=>e.getBoundingClientRect().height)), minFont:Math.min(...[...document.querySelectorAll('body *')].filter(e=>e.offsetParent&&e.childNodes.length&&[...e.childNodes].some(n=>n.nodeType===3&&n.textContent.trim())).map(e=>parseFloat(getComputedStyle(e).fontSize))), helper:!!window.KTS_HELPER, keys:!!window.KTS_KEYS, limit:window.KTS_KEYS&&KTS_KEYS.limitOf('interior'), free:window.KTS_KEYS&&KTS_KEYS.freeText('interior')})"
  # 계산 검산 1: 4.0x2.4 · 벽 하 · 배치 그대로
  $R.calc_default = (St).last | Select-Object c1, c2, c3, d32, d31, mat, labor, days, area
  $R.calc_default_line = Invoke-Js "document.querySelector('#calcOut .lines').innerText"
  Invoke-Js "document.querySelector('#secCalc').scrollIntoView({block:'start'});1" | Out-Null
  Shot (Join-Path $Cap '03_calc_3ways_390.png')
  # 계산 2: 벽 상
  Click '#rowWall button[data-g="h"]'
  $R.calc_wallH = (St).last | Select-Object c1, c2, c3, d32, d31
  $R.calc_wallH_line = Invoke-Js "document.querySelector('#calcOut .ln .v').innerText"
  Click '#rowWall button[data-g="l"]'
  # 배치 바꾸기 / 되돌리기
  Click '#layoutSeg button[data-l="move"]'
  $R.calc_move = (St).last | Select-Object c1, c2, c3, labor
  $R.calc_move_state = (St).state
  Click '#layoutSeg button[data-l="keep"]'
  $R.calc_keep_again = (St).last | Select-Object c1, c2, c3, labor
  # 면적 0 안내
  Invoke-Js "(()=>{const i=document.querySelector('#inW');i.value='0';i.dispatchEvent(new Event('input'));return 1})()" | Out-Null
  $R.calc_zero = Invoke-Js "document.querySelector('#calcOut').innerText"
  Invoke-Js "(()=>{const i=document.querySelector('#inW');i.value='4.0';i.dispatchEvent(new Event('input'));return 1})()" | Out-Null
  # 단가 수정 저장
  Invoke-Js "(()=>{document.querySelector('#ratesBox').open=true;const i=document.querySelector('[data-p=daily]');i.value='300000';i.dispatchEvent(new Event('input'));return 1})()" | Out-Null
  $R.rate_saved = J "JSON.stringify({ls:JSON.parse(localStorage.getItem('kts_interior_rates_v1')).daily, c2:window.__KTS_INTERIOR().last.c2, tag:document.querySelector('[data-tg=daily]').innerText})"
  Invoke-Js "document.querySelector('#rateReset').click();1" | Out-Null; Start-Sleep -Milliseconds 200
  $R.rate_reset_c2 = (St).last.c2
  $R.badges = J "JSON.stringify({ok:document.querySelectorAll('#ratesTbl .tg.ok').length, es:document.querySelectorAll('#ratesTbl .tg.es').length})"
  Invoke-Js "document.querySelector('#ratesBox').open=false;1" | Out-Null

  # 게이지: 샘플을 보기 좋게 — 조명 상 + 배치 바꾸기 + 가구 중
  Click '#rowLight button[data-g="h"]'; Click '#layoutSeg button[data-l="move"]'; Click '#rowFurn button[data-g="m"]'
  Start-Sleep -Milliseconds 400
  $m = Rect '#baSample'
  $y = $m.y + $m.h / 2
  Drag ($m.x + $m.w * 0.5) $y ($m.x + $m.w * 0.15) $y 8; Start-Sleep -Milliseconds 200
  $g1 = (St).gauge
  Drag ($m.x + $m.w * 0.15) $y ($m.x + $m.w * 0.85) $y 8; Start-Sleep -Milliseconds 200
  $g2 = (St).gauge
  Drag ($m.x + $m.w * 0.85) $y ($m.x - 40) $y 6; $g0 = (St).gauge
  Drag ($m.x) $y ($m.x + $m.w + 40) $y 6; $g100 = (St).gauge
  Invoke-Js "document.querySelector('#baSample').focus();1" | Out-Null
  Key 'ArrowLeft' 37; Key 'ArrowLeft' 37; $gk = (St).gauge
  Invoke-Js "(()=>{const r=document.querySelector('#rngSample');r.value='30';r.dispatchEvent(new Event('input'));return 1})()" | Out-Null
  $gr = J "JSON.stringify({g:window.__KTS_INTERIOR().gauge, dv:document.querySelector('#baSample .dv').getBoundingClientRect().left-document.querySelector('#baSample').getBoundingClientRect().left, w:document.querySelector('#baSample').getBoundingClientRect().width, clip:document.querySelector('#baSample canvas.af').style.clipPath, lbl:[...document.querySelectorAll('#baSample .lb')].map(e=>e.innerText).join('/')})"
  $R.gauge = [ordered]@{ drag_to_15 = $g1; drag_to_85 = $g2; drag_min = $g0; drag_max = $g100; key_left_x2_from100 = $gk; range30 = $gr }
  Invoke-Js "(()=>{const r=document.querySelector('#rngSample');r.value='50';r.dispatchEvent(new Event('input'));return 1})()" | Out-Null
  Invoke-Js "document.querySelector('#secSample').scrollIntoView({block:'start'});scrollBy(0,-56);1" | Out-Null
  Shot (Join-Path $Cap '02_gauge_before_after_390.png')
  foreach ($s in @('living', 'shop')) {
    Click ('#sceneTabs .tab[data-s="' + $s + '"]'); Start-Sleep -Milliseconds 400
    Shot (Join-Path $Cap ('02_gauge_' + $s + '_390.png'))
  }
  Click '#sceneTabs .tab[data-s="room"]'
  # 원본 해상도 전/후 캔버스 저장(샘플)
  $png = Invoke-Js "(()=>{const el=document.querySelector('#baSample'),b=el.querySelector('canvas.bf'),a=el.querySelector('canvas.af'),c=document.createElement('canvas');c.width=2400;c.height=900;const g=c.getContext('2d');g.drawImage(b,0,0);g.drawImage(a,1200,0);return c.toDataURL('image/png').split(',')[1]})()"
  [IO.File]::WriteAllBytes((Join-Path $Cap '05_sample_before_after_fullres.png'), [Convert]::FromBase64String($png))

  # 사진 1장째 (무료)
  Invoke-Js "localStorage.removeItem('kts_interior_trial_v1');localStorage.removeItem('kts_interior_pass_v1');localStorage.removeItem('kts_keys_v1');1" | Out-Null
  Set-FileInput '#photoIn' @((Join-Path $PSScriptRoot '..\test_room.jpg' | Resolve-Path).Path)
  $null = Wait-Js "window.__KTS_INTERIOR().photo" 8000; Start-Sleep -Milliseconds 400
  $R.photo1 = J "JSON.stringify(Object.assign(window.__KTS_INTERIOR(),{cw:document.querySelector('#baPhoto canvas.bf').width,ch:document.querySelector('#baPhoto canvas.bf').height,pass:!document.querySelector('#passBox').hidden,cnt:document.querySelector('#photoCnt').innerText,dayUsed:KTS_KEYS.usedToday('interior')}))"
  Invoke-Js "document.querySelector('#svAfter').click();1" | Out-Null; Start-Sleep -Milliseconds 700
  $R.photo1_save_toast = Invoke-Js "document.querySelector('#toast').innerText"
  Invoke-Js "document.querySelector('#secPhoto').scrollIntoView({block:'start'});scrollBy(0,-56);1" | Out-Null
  Shot (Join-Path $Cap '04_photo_1st_free_390.png')
  # 사진 2장째 (워터마크 + 이용권 안내)
  Set-FileInput '#photoIn' @((Join-Path $PSScriptRoot '..\test_room2.jpg' | Resolve-Path).Path)
  Start-Sleep -Milliseconds 1200
  $R.photo2 = J "JSON.stringify(Object.assign(window.__KTS_INTERIOR(),{cw:document.querySelector('#baPhoto canvas.bf').width,pass:!document.querySelector('#passBox').hidden,sms:document.querySelector('#smsPass').getAttribute('href'),cnt:document.querySelector('#photoCnt').innerText}))"
  Invoke-Js "document.querySelector('#passBox').scrollIntoView({block:'end'});1" | Out-Null
  Shot (Join-Path $Cap '04_photo_2nd_watermark_390.png')
  # 잘못된 코드 → 거절, 이번 달 코드 → 열림
  Invoke-Js "document.querySelector('#codeIn').value='KS0000-ABCD';document.querySelector('#codeBtn').click();1" | Out-Null
  $R.code_bad = J "JSON.stringify({wm:window.__KTS_INTERIOR().wm,toast:document.querySelector('#toast').innerText})"
  Invoke-Js "(()=>{const t=new Date(),ym=String(t.getFullYear()).slice(2)+('0'+(t.getMonth()+1)).slice(-2);let h=0x811c9dc5,s='kts-sign-'+ym;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,0x01000193)>>>0}document.querySelector('#codeIn').value='KS'+ym+'-'+h.toString(16).toUpperCase().padStart(8,'0').slice(0,4);document.querySelector('#codeBtn').click();return 1})()" | Out-Null
  $R.code_ok = J "JSON.stringify({wm:window.__KTS_INTERIOR().wm,unlocked:window.__KTS_INTERIOR().unlocked,pass:!document.querySelector('#passBox').hidden})"
  Invoke-Js "localStorage.removeItem('kts_interior_pass_v1');1" | Out-Null

  # 외부 요청·전체 레이아웃·이벤트
  $R.resources = Invoke-Js "performance.getEntriesByType('resource').map(e=>e.name.split('?')[0].replace(/^.*oneclick/,'')).join(' | ')"
  $R.external_count = Invoke-Js "performance.getEntriesByType('resource').map(e=>e.name).filter(n=>/^https?:/.test(n)).length"
  $R.layout_end = J "JSON.stringify({sw:document.documentElement.scrollWidth})"
  $R.events = Evts-Summary
  $R.eventList = @($global:EVTS)

  # 쇼룸 카드 · 상세
  Clear-Evts
  Go-Url (To-FileUrl (Join-Path $OcRoot 'index.html')) 2500
  $R.showroom = J "JSON.stringify((()=>{const a=[...document.querySelectorAll('a[href*=interior]')];const img=[...document.querySelectorAll('img')].filter(i=>/ic_interior/.test(i.src));return {links:a.length, text:a.map(x=>x.innerText.replace(/\s+/g,' ').slice(0,60)).slice(0,3), imgs:img.length, imgOk:img.filter(i=>i.complete&&i.naturalWidth>0).length}})())"
  $null = Invoke-Js "(()=>{const a=[...document.querySelectorAll('a[href*=interior]')].filter(x=>/interior\/|k=interior/.test(x.getAttribute('href'))&&!/bungee/.test(x.getAttribute('href'))); const t=a[0]||null; if(t) t.scrollIntoView({block:'center'}); return 1})()"
  Start-Sleep -Milliseconds 1500
  $R.showroom_img = J "JSON.stringify([...document.querySelectorAll('img')].filter(i=>/ic_interior/.test(i.src)).map(i=>({ok:i.complete&&i.naturalWidth>0,w:i.naturalWidth,loading:i.loading})))"
  $R.showroom_hrefs = Invoke-Js "[...document.querySelectorAll('a[href*=interior]')].map(a=>a.getAttribute('href')).join(' | ')"
  Shot (Join-Path $Cap '06_showroom_card_390.png')
  $R.showroom_events = Evts-Summary
  Clear-Evts
  Go-Url ((To-FileUrl (Join-Path $OcRoot 'detail.html')) + '?k=interior') 2500
  $R.detail = J "JSON.stringify({title:document.title, h:(document.querySelector('h1,h2')||{}).innerText, hasHow:document.body.innerText.indexOf('게이지 바를 좌우로 밀어')>=0, how4:['샘플에서 게이지','배치와 벽','가로·세로를 넣으면','내 방 사진을 올리면'].every(s=>document.body.innerText.indexOf(s)>=0)})"
  Shot (Join-Path $Cap '07_detail_390.png')
  $R.detail_events = Evts-Summary
}
finally { Stop-CdpChrome }
$out = Join-Path $PSScriptRoot ('..\verify_' + $tag + '.json')
($R | ConvertTo-Json -Depth 8) | Out-File -Encoding utf8 $out
Get-Content $out -Encoding UTF8

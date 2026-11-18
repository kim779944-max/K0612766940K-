# 계약서 1초 생성기 실화면 검수·캡처 (390x844 @2x)
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$out = (Resolve-Path "$PSScriptRoot\..").Path
$files = Join-Path $out 'files'
New-Item -ItemType Directory -Force $files | Out-Null
Open-App 'oneclick\contract.html' 9342
$log = @()
$BR = '"br":{"office":"KTS공인중개사사무소","reg":"11710-2026-00001","rep":"최중개","tel":"02-123-4567","addr":"서울특별시 송파구 올림픽로 290"}'
$SAMPLES = [ordered]@{
  sale  = '{"type":"sale","rent":"wolse","step":1,"a":{"name":"김매도","rrn":"750312","addr":"서울특별시 강남구 테헤란로 100","tel":"010-1111-2222"},"b":{"name":"이매수","rrn":"820415","addr":"경기도 성남시 분당구 판교로 200","tel":"010-3333-4444"},"prop":{"addr":"서울특별시 송파구 올림픽로 300","lot":"잠실동 40-1","bldg":"KTS아파트 101동","floor":"12","ho":"1203","area":"84.97","regNo":"2026-012345"},"money":{"contractDate":"2026-11-18","total":"850000000","deposit":"85000000","mid":"300000000","midDays":"30","balDays":"60","months":"24"},"sp":[0,1,2,6],"free":"잔금일에 관리비 선수금은 매수인이 매도인에게 지급한다.",' + $BR + ',"cp":{"a":1,"b":1,"c":1}}'
  house = '{"type":"house","rent":"wolse","step":1,"a":{"name":"박임대","rrn":"680901","addr":"서울특별시 마포구 월드컵로 10","tel":"010-5555-6666"},"b":{"name":"정임차","rrn":"960220","addr":"서울특별시 관악구 관악로 1","tel":"010-7777-8888"},"prop":{"addr":"서울특별시 마포구 독막로 50","lot":"서교동 300-2","bldg":"KTS빌라","floor":"3","ho":"301","area":"45.2","regNo":""},"money":{"contractDate":"2026-11-18","total":"50000000","rent":"1200000","deposit":"5000000","balDays":"21","months":"24"},"sp":[0,1,3,9],"free":"",' + $BR + ',"cp":{"a":1,"b":1,"c":1}}'
  shop  = '{"type":"shop","rent":"wolse","step":1,"a":{"name":"(주)KTS빌딩","rrn":"110111","addr":"부산광역시 해운대구 센텀로 10","tel":"051-111-2222"},"b":{"name":"한카페","rrn":"900505","addr":"부산광역시 수영구 광안로 5","tel":"010-9999-0000"},"prop":{"addr":"부산광역시 해운대구 센텀중앙로 20","lot":"우동 1500","bldg":"KTS타워","floor":"1","ho":"102","area":"66.0","regNo":"2026-054321"},"money":{"contractDate":"2026-11-18","total":"30000000","rent":"2500000","mgmt":"300000","deposit":"3000000","balDays":"14","months":"24"},"sp":[0,1,3,9],"free":"업종: 카페(일반음식점)",' + $BR + ',"cp":{"a":1,"b":1,"c":1}}'
}
$NM = @{ sale = '매매'; house = '주택임대차'; shop = '상가임대차' }
try {
  # 빈 화면 + 종류 선택
  Shot $out '01_start' @((Mk 'tap' (Rect '#typeSeg') '계약서 종류'), (Mk 'circle' (RectNoScroll '#legalTop') '고지 고정 표시'))
  # 미입력 빨간 표시: 아무것도 안 넣고 3단계에서 인쇄 누르기
  TapSel '#nextBtn' | Out-Null; TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 300
  TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 300
  Invoke-Js "document.querySelector('#missBox').scrollIntoView({block:'center'})" | Out-Null
  Shot $out '02_missing_box' @((Mk 'circle' (RectNoScroll '#missBox') '미입력 목록'), (Mk 'circle' (RectNoScroll '#plbls') '단계별 미입력 수'))
  TapSel '#plbls button[data-s="1"]' | Out-Null; Start-Sleep -Milliseconds 300
  Invoke-Js "document.querySelector('#aBox').scrollIntoView({block:'start'}); window.scrollBy(0,-210)" | Out-Null
  Shot $out '02b_missing_red' @((Mk 'circle' (RectNoScroll '#aBox input[data-k="name"]') '빨간 칸 = 미입력'))
  $log += 'missing on empty: ' + (Js 'return String(KC.missing().length)')

  # 실제 타이핑 시험(매도인 성명·매매대금 한글 금액)
  TapSel '#aBox input[data-k="name"]' | Out-Null; TypeText '김매도'
  $log += 'typed name saved: ' + (Js 'return KC.S.a.name')
  Js 'KC.go(2); return 1' | Out-Null
  TapSel '#moneyBox input[data-k="total"]' | Out-Null; TypeText '120000000'
  $log += 'kor 120000000: ' + (Invoke-Js "document.querySelector('[data-kor=""total""]').textContent") + ' / input=' + (Invoke-Js "document.querySelector('#moneyBox input[data-k=""total""]').value")
  TapSel '#moneyBox [data-chips="balDays"] button[data-d="60"]' | Out-Null
  $log += 'D+60: ' + (Invoke-Js "document.querySelector('[data-when=""balDays""]').textContent")
  # 자동 저장: 새로고침 후에도 남아 있는지
  Nav 'oneclick\contract.html'
  $log += 'after reload: ' + (Js 'return JSON.stringify({name:KC.S.a.name, total:KC.S.money.total, step:KC.S.step})')

  foreach ($t in $SAMPLES.Keys) {
    $n = $NM[$t]
    Js ('localStorage.setItem("kc_contract_v1", JSON.stringify(' + $SAMPLES[$t] + ')); return 1') | Out-Null
    Nav 'oneclick\contract.html'
    Shot $out ($t + '_1_party') @((Mk 'circle' (RectNoScroll ('#typeSeg button[data-v="' + $t + '"]')) $n), (Mk 'circle' (RectNoScroll '#aBox') '갑'))
    TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 300
    Invoke-Js "document.querySelector('#moneyBox').scrollIntoView({block:'start'}); window.scrollBy(0,-230)" | Out-Null
    Shot $out ($t + '_2_money') @((Mk 'circle' (RectNoScroll '[data-kor="total"]') '한글 금액 자동'), (Mk 'circle' (RectNoScroll '#moneyBox input[data-k="deposit"]') '계약금'))
    Invoke-Js "document.querySelector('[data-chips=""balDays""]').scrollIntoView({block:'center'})" | Out-Null
    Shot $out ($t + '_2b_dates') @((Mk 'tap' (RectNoScroll '[data-chips="balDays"] button[data-d="30"]') 'D+n 날짜 자동'), (Mk 'circle' (RectNoScroll '[data-when="balDays"]') '실제 날짜'))
    TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
    Shot $out ($t + '_3_specials') @((Mk 'tap' (RectNoScroll '#spList label:first-child input') '특약 체크'))
    Invoke-Js "document.querySelector('#printBtn').scrollIntoView({block:'center'})" | Out-Null
    Shot $out ($t + '_3b_output') @((Mk 'tap' (RectNoScroll '#printBtn') '인쇄·PDF'), (Mk 'tap' (RectNoScroll '#hwpxBtn') '한글 저장'), (Mk 'circle' (RectNoScroll '.cp') '3부 선택'))
    Invoke-Js "document.querySelector('#pvWrap').scrollIntoView({block:'start'}); window.scrollBy(0,-170)" | Out-Null
    Shot $out ($t + '_4_preview') @((Mk 'circle' (RectNoScroll '#pvWrap') '계약서 미리보기'))
    $log += $t + ' missing: ' + (Js 'return JSON.stringify(KC.missing().map(m=>m.t))')
    $log += $t + ' copies: ' + (Js 'return JSON.stringify(KC.copies())')
    Save-B64 (Js ($B64JS + 'return await b2(await KC.hwpxBlob())')) (Join-Path $files ($n + '계약서_샘플.hwpx'))
    TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 700
    $log += $t + ' printArea pages: ' + (Js 'return String(document.querySelectorAll("#printArea .paper").length)')
    Print-Pdf (Join-Path $files ($n + '계약서_3부_인쇄.pdf'))
  }
  # 부수 선택: 중개사용 끄면 2부
  TapSel '.cp input[data-cp="c"]' | Out-Null
  $log += 'copies after uncheck: ' + (Js 'return JSON.stringify(KC.copies())')
  TapSel '.cp input[data-cp="c"]' | Out-Null
  # 전세 전환 시 차임 줄이 빠지는지
  $log += 'jeonse doc: ' + (Js 'KC.S.type="house"; KC.S.rent="jeonse"; const d=KC.buildDoc(); const tbl=d.blocks.find(b=>b.main); return JSON.stringify({title:d.blocks[0].runs[0][0], rows:tbl.cells.filter(c=>c[1]===0).map(c=>c[4])})')
  Js 'localStorage.setItem("kc_contract_v1", JSON.stringify(KC.S)); return 1' | Out-Null
  Nav 'oneclick\contract.html'
  # 60초 문의
  TapSel '#qName' | Out-Null; TypeText '최중개'; TapSel '#qTel' | Out-Null; TypeText '02-123-4567'; TapSel '#qMsg' | Out-Null; TypeText '토지 매매계약서도 있으면 좋겠습니다'
  TapSel '#qMake' | Out-Null
  Invoke-Js "document.querySelector('.qa').scrollIntoView({block:'start'})" | Out-Null
  Shot $out '90_inquiry' @((Mk 'tap' (RectNoScroll '#qMake') '답장 초안'), (Mk 'circle' (RectNoScroll '#qDraft') '자동 발송 없음'))
  $log += 'errors: ' + (Js 'return JSON.stringify(window.__errs)') + ' / before-nav: [' + ($global:ERRS -join ',') + ']'
  $log += 'print calls: ' + (Js 'return String(window.__printed||0)')
} finally { Stop-CdpChrome }
Save-Marks (Join-Path $out 'marks.json')
$log | Set-Content -Encoding UTF8 (Join-Path $out 'run_log.txt')
$log

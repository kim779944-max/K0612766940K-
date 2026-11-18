# 민원·내용증명 초안 실화면 검수·캡처 (서식 4종 각각 초안 1장 생성·인쇄 A4 1쪽)
. "$PSScriptRoot\pmlib.ps1"
$out = AppDir 'letter'; $files = Join-Path $out 'files'
$NM = @{ notice = '내용증명'; civil = '민원신청서'; objection = '이의신청서'; fact = '사실확인서' }
$log = @()
function TypeIn([string]$sel, [string]$v) { TapSel $sel | Out-Null; TypeText $v }
function SetVal([string]$sel, [string]$v) { Js ("const e=document.querySelector('" + $sel + "'); e.value='" + $v + "'; e.dispatchEvent(new Event('input',{bubbles:true})); return 1") | Out-Null }
Open-App 'oneclick\letter.html' 9357
try {
  Js 'localStorage.clear(); return 1' | Out-Null
  Nav 'oneclick\letter.html'
  Shot $out '01_kinds' @((Mk 'tap' (RectNoScroll '#kinds button[data-v="notice"]') '서식 고르기'), (Mk 'circle' (RectNoScroll '#legalTop') '고지 고정 표시'))
  # ① 내용증명: 모든 칸을 손으로 입력
  TapSel '#kinds button[data-v="notice"]' | Out-Null; Start-Sleep -Milliseconds 300
  Shot $out '02_notice_empty' @((Mk 'tap' (RectNoScroll '#sampleBtn') '예시 넣기'), (Mk 'circle' (RectNoScroll '#evBox') '사건 개요'))
  SetVal '#evBox [data-e="when"]' '2024-11-09'
  TypeIn '#evBox [data-e="who"]' '본인과 귀하는'
  TypeIn '#evBox [data-e="what"]' '서울특별시 마포구 독막로 50 KTS빌라 301호에 대한 임대차계약을 맺었습니다'
  TypeIn '#evBox [data-e="how"]' '계약이 2026-10-31에 끝나 같은 날 집을 비워 드렸으나, 보증금 50000000원 중 1200000원을 아직 돌려받지 못했습니다'
  TypeIn '#evBox [data-e="demand"]' "남은 보증금 1200000원을 본인 명의 계좌(KTS은행 123-456-789012)로 돌려주십시오`n공제할 금액이 있다면 그 내역을 글로 알려 주십시오"
  TypeIn '#evBox [data-e="amount"]' '1200000'
  TapSel '#dueChips button[data-d="14"]' | Out-Null
  TypeIn '#evBox [data-e="attach"]' "임대차계약서 사본 1부`n보증금 입금 확인증 사본 1부"
  SetVal '#evBox [data-e="date"]' '2026-11-18'
  TypeIn '#pBox [data-g="from"][data-k="name"]' '정임차'; TypeIn '#pBox [data-g="from"][data-k="addr"]' '서울특별시 관악구 관악로 1'; TypeIn '#pBox [data-g="from"][data-k="tel"]' '010-7777-8888'
  TypeIn '#pBox [data-g="to"][data-k="name"]' '박임대'; TypeIn '#pBox [data-g="to"][data-k="addr"]' '서울특별시 마포구 월드컵로 10'
  ScrollTo '#evBox [data-e="amount"]' 'start' -250
  Shot $out '03_notice_typed' @((Mk 'circle' (RectNoScroll '#evBox [data-e="amount"]') '금액 → 한글 병기'), (Mk 'tap' (RectNoScroll '#dueChips button[data-d="14"]') '기한 D+14'), (Mk 'circle' (RectNoScroll '[data-w="due"]') '실제 날짜'))
  $log += 'notice missing: [' + (Js 'return LT.missing().join(",")') + ']'
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
  Shot $out '04_notice_draft' @((Mk 'circle' (RectNoScroll '#bodyText') '본문(바로 고치기)'), (Mk 'tap' (RectNoScroll '#printBtn') '인쇄·PDF'), (Mk 'tap' (RectNoScroll '#copyBtn') '텍스트 복사'))
  ScrollTo '#pvWrap' 'start' -170
  Shot $out '05_notice_preview' @((Mk 'circle' (RectNoScroll '#pvWrap') '수신·제목·본문·붙임·작성일'))
  TapSel '#copyBtn' | Out-Null; Start-Sleep -Milliseconds 300
  $log += 'copy: ' + (Invoke-Js "document.querySelector('#outInfo').textContent")
  # 본문 직접 고치기 → 인쇄에 반영 → 되돌리기
  TapSel '#bodyText' | Out-Null; Js 'const e=document.querySelector("#bodyText"); e.setSelectionRange(e.value.length,e.value.length); return 1' | Out-Null; TypeText "`n`n7. 연락은 문자로 주셔도 됩니다."
  $log += 'edited body in paper: ' + (Js 'return String(LT.paperHtml().includes("연락은 문자로 주셔도"))')
  TapSel '#resetBody' | Out-Null; Start-Sleep -Milliseconds 200
  $log += 'after reset: ' + (Js 'return String(LT.paperHtml().includes("연락은 문자로 주셔도"))')
  [IO.File]::WriteAllText((Join-Path $files '내용증명_초안.txt'), (Js 'return LT.fullText()'), (New-Object Text.UTF8Encoding($false)))
  TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
  $pdf = Join-Path $files '내용증명_초안.pdf'; Print-Pdf $pdf; $log += 'notice pdf pages=' + (Pages $pdf)
  # 인쇄 레이아웃 캡처(내용증명)
  Js 'document.querySelector("#printArea").innerHTML = LT.paperHtml(); return 1' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 643; height = 1000; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null; Start-Sleep -Milliseconds 400
  $h = [int](Invoke-Js "Math.ceil(document.querySelector('#printArea .paper').getBoundingClientRect().height)")
  $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 643; height = $h; scale = 1 } }
  [IO.File]::WriteAllBytes((Join-Path $out 'print_layout_notice.png'), [Convert]::FromBase64String($r['data']))
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  # ②③④: [예시 넣기] + 한 칸은 손으로 고쳐 쓰기
  $edit = @{ civil = @('#pBox [data-g="from"][data-k="tel"]', '010-2222-3399'); objection = @('#evBox [data-e="how"]', '. 당시 정차 위치는 횡단보도에서 10m 넘게 떨어져 있었습니다'); fact = @('#evBox [data-e="purpose"]', '') }
  $i = 6
  foreach ($k in 'civil', 'objection', 'fact') {
    TapSel '#plbls button[data-s="1"]' | Out-Null; Start-Sleep -Milliseconds 250
    TapSel ('#kinds button[data-v="' + $k + '"]') | Out-Null; Start-Sleep -Milliseconds 300
    TapSel '#sampleBtn' | Out-Null; Start-Sleep -Milliseconds 300
    SetVal '#evBox [data-e="date"]' '2026-11-18'
    if ($k -eq 'civil') { SetVal $edit[$k][0] ''; TypeIn $edit[$k][0] $edit[$k][1] }
    elseif ($k -eq 'objection') { $e = Rect $edit[$k][0]; Js ('const e=document.querySelector(''' + $edit[$k][0] + '''); e.focus(); e.setSelectionRange(e.value.length,e.value.length); return 1') | Out-Null; TypeText $edit[$k][1] }
    ScrollTo '#evBox' 'start' -200
    Shot $out (('{0:D2}' -f $i) + '_' + $k + '_input') @((Mk 'tap' (RectNoScroll '#sampleBtn') '예시 넣기'), (Mk 'circle' (RectNoScroll '#evBox label.lb') ($NM[$k] + ' 전용 칸')))
    $log += "$k missing: [" + (Js 'return LT.missing().join(",")') + ']'
    TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
    ScrollTo '#pvWrap' 'start' -170
    Shot $out (('{0:D2}' -f ($i + 1)) + '_' + $k + '_preview') @((Mk 'circle' (RectNoScroll '#pvWrap') ($NM[$k] + ' 초안')))
    [IO.File]::WriteAllText((Join-Path $files ($NM[$k] + '_초안.txt')), (Js 'return LT.fullText()'), (New-Object Text.UTF8Encoding($false)))
    TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
    $pdf = Join-Path $files ($NM[$k] + '_초안.pdf'); Print-Pdf $pdf; $log += "$k pdf pages=" + (Pages $pdf)
    $i += 2
  }
  $log += 'civil tel typed in draft: ' + ([IO.File]::ReadAllText((Join-Path $files '민원신청서_초안.txt'), [Text.Encoding]::UTF8).Contains('010-2222-3399'))
  # 빈 칸으로 3단계 → 밑줄 안내 + 빨간 칸
  TapSel '#newBtn' | Out-Null; Start-Sleep -Milliseconds 250
  TapSel '#kinds button[data-v="notice"]' | Out-Null; Start-Sleep -Milliseconds 250
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 300
  $log += 'empty -> step3 toast: ' + (Toast) + ' / step=' + (Js 'return String(LT.S.step)')
  TapSel '#plbls button[data-s="2"]' | Out-Null; Start-Sleep -Milliseconds 250
  ScrollTo '#evBox' 'start' -200
  Shot $out '12_missing' @((Mk 'circle' (RectNoScroll '#evBox [data-e="when"]') '빨간 칸 = 빈 칸'))
  # 외부 발송 0: 코드에 메일·문자 발송 경로가 없는지
  $src = [IO.File]::ReadAllText((Join-Path $global:ROOT 'oneclick\letter.html'), [Text.Encoding]::UTF8)
  $log += 'send paths in letter.html (mailto/sms/fetch/sendBeacon/XMLHttpRequest): ' + ([regex]::Matches($src, 'mailto:|sms:|sendBeacon|XMLHttpRequest|fetch\(')).Count + ' (fetch는 common.js의 AI 함수 1곳 — letter는 AI 미사용)'
  Js 'LT.go(1); return 1' | Out-Null
  TypeIn '#qName' '정임차'; TypeIn '#qTel' '010-7777-8888'; TypeIn '#qMsg' '합의서·차용증 서식도 있으면 좋겠습니다'
  TapSel '#qMake' | Out-Null; Start-Sleep -Milliseconds 200
  ScrollTo '.qa' 'start' -150
  Shot $out '90_inquiry' @((Mk 'tap' (RectNoScroll '#qMake') '답장 초안'), (Mk 'circle' (RectNoScroll '#qDraft') '자동 발송 없음'))
  $log = Finish $out $log
} finally { Stop-CdpChrome }
$log

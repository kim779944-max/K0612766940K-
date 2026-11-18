# 지출결의서 1초 정리 실화면 검수·캡처 (영수증 3장 → 결의서 xlsx·PDF, 합계·부가세 손 검산)
. "$PSScriptRoot\pmlib.ps1"
$out = AppDir 'expense'; $files = Join-Path $out 'files'; $work = Join-Path $out 'work'
New-Item -ItemType Directory -Force $work | Out-Null
$log = @()
function SetSel([string]$card, [string]$f, [string]$v) {
  Js ("const e=document.querySelector('" + $card + " [data-f=" + $f + "]'); e.value='" + $v + "'; e.dispatchEvent(new Event('input',{bubbles:true})); e.dispatchEvent(new Event('change',{bubbles:true})); return 1") | Out-Null
}
Open-App 'oneclick\expense.html' 9353
try {
  # 시험용 영수증 사진 3장(캔버스로 그린 가짜 영수증)
  $mk = "const mk=(L)=>{const w=420,h=600,c=document.createElement('canvas');c.width=w;c.height=h;const g=c.getContext('2d');g.fillStyle='#FBFAF4';g.fillRect(0,0,w,h);g.fillStyle='#222';g.font='bold 28px Malgun Gothic';g.textAlign='center';g.fillText(L[0],w/2,56);g.font='19px Malgun Gothic';g.textAlign='left';let y=104;for(const l of L.slice(1)){if(l==='-'){g.fillRect(20,y-14,w-40,2);y+=18;continue}g.fillText(l,26,y);y+=32}return c.toDataURL('image/jpeg',.9).split(',')[1]};"
  $R = @(
    @('receipt_1_한빛식당.jpg', "['카드 영수증','상호: 한빛식당','일시: 2026-11-03 12:41','-','김치찌개 x4   36,000','계란말이 x1   12,000','-','공급가액      43,636','부가세         4,364','합계          48,000','-','신한카드 승인 12345678']"),
    @('receipt_2_KTS문구.jpg', "['전자세금계산서','공급자: KTS문구','작성일자: 2026-11-07','-','A4 복사용지 20박스','공급가액     120,000','세액          12,000','합계금액     132,000','-','영수 / 청구: 청구']"),
    @('receipt_3_서울택시.jpg', "['간이 영수증','서울택시 (개인)','2026-11-12 22:15','-','송파구 → 마포구','요금          15,800','-','위 금액을 영수함']")
  )
  $paths = @()
  foreach ($x in $R) { $p = Join-Path $work $x[0]; Save-B64 (Invoke-Js ("(()=>{" + $mk + "return mk(" + $x[1] + ")})()")) $p; $paths += $p }
  Shot $out '01_start' @((Mk 'tap' (RectNoScroll '#photoBtn') '영수증 사진 넣기'), (Mk 'circle' (RectNoScroll '#ocrInfo') '글자 읽기는 열쇠 있을 때'))
  Set-FileInput '#photoIn' $paths
  if (-not (Wait-Idle "EX.S.rows.length===3 && EX.S.rows.every(r=>r.thumb)")) { throw 'photos not loaded' }
  $log += 'photos -> rows: ' + (Js 'return JSON.stringify(EX.S.rows.map(r=>r.photo))')
  ScrollTo '#list1' 'start' -150
  Shot $out '02_cards_empty' @((Mk 'circle' (RectNoScroll '#list1 .rc .ph') '사진 1장 = 1줄'), (Mk 'circle' (RectNoScroll '#list1 .rc .flds') '일자·거래처·금액'))
  # 줄마다 실제 타이핑(거래처·합계) + 날짜/선택 칸은 값 넣고 change
  $V = @(@('2026-11-03', '한빛식당', '48000', '식대', '카드영수증'), @('2026-11-07', 'KTS문구', '132000', '소모품', '세금계산서'), @('2026-11-12', '서울택시', '15800', '교통비', '간이영수증'))
  for ($i = 0; $i -lt 3; $i++) {
    $c = '#list1 .rc:nth-child(' + ($i + 1) + ')'
    SetSel $c 'date' $V[$i][0]; SetSel $c 'proof' $V[$i][4]; SetSel $c 'use' $V[$i][3]
    TapSel ($c + ' [data-f="vendor"]') | Out-Null; TypeText $V[$i][1]
    TapSel ($c + ' [data-f="total"]') | Out-Null; TypeText $V[$i][2]
    Start-Sleep -Milliseconds 150
  }
  $log += 'after typing: ' + (Js 'return JSON.stringify(EX.S.rows.map(r=>({d:r.date,v:r.vendor,total:r.total,vat:r.vat,use:r.use,proof:r.proof})))')
  ScrollTo '#list1 .rc:nth-child(2)' 'start' -150
  Shot $out '03_cards_filled' @((Mk 'circle' (RectNoScroll '#list1 .rc:nth-child(2) [data-f="total"]') '합계 입력'), (Mk 'circle' (RectNoScroll '#list1 .rc:nth-child(2) .vatrow') '부가세 자동'), (Mk 'circle' (RectNoScroll '#list1 .rc:nth-child(2) .chk') '줄 검산'))
  # 중복 의심: 1번과 같은 줄 추가
  TapSel '#addBtn' | Out-Null; Start-Sleep -Milliseconds 200
  $c = '#list1 .rc:nth-child(4)'
  SetSel $c 'date' '2026-11-03'; SetSel $c 'use' '식대'
  TapSel ($c + ' [data-f="vendor"]') | Out-Null; TypeText '한빛식당'
  TapSel ($c + ' [data-f="total"]') | Out-Null; TypeText '48000'
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
  $log += 'dup check: ' + (Js 'const f=EX.flags(); return JSON.stringify({dup:[...f.dup], miss:f.nMiss})')
  Shot $out '04_fix_total' @((Mk 'circle' (RectNoScroll '#totBox') '합계·부가세 자동 검산'))
  ScrollTo '#list2 .rc:nth-child(4)' 'start' -150
  Shot $out '05_dup' @((Mk 'circle' (RectNoScroll '#list2 .rc:nth-child(4) .hdr') '중복 의심'), (Mk 'tap' (RectNoScroll '#list2 .rc:nth-child(4) .del') '삭제'))
  TapSel '#list2 .rc:nth-child(4) .del' | Out-Null; Start-Sleep -Milliseconds 250
  # 빠진 값 빨간 표시: 빈 줄 하나 추가 → 표시 확인 → 삭제
  Js 'EX.S.rows.push(EX.newRow()); EX.save(); EX.renderList(); return 1' | Out-Null
  ScrollTo '#list2 .rc:nth-child(4)' 'start' -150
  $log += 'missing on empty row: ' + (Js 'return String(EX.flags().nMiss)')
  Shot $out '06_missing' @((Mk 'circle' (RectNoScroll '#list2 .rc:nth-child(4) .flds') '빨간 칸 = 빠진 값'))
  TapSel '#list2 .rc:nth-child(4) .del' | Out-Null; Start-Sleep -Milliseconds 250
  # 부가세 1/11 단추
  Js "const r=EX.S.rows[0]; r.vat='4000'; r.vatAuto=0; EX.save(); EX.renderList(); return 1" | Out-Null
  $log += 'vat off flag (4000 instead of 4364): ' + (Js 'return JSON.stringify([...EX.flags().vatOff])')
  ScrollTo '#list2 .rc:nth-child(1)' 'start' -150
  Shot $out '07_vat_check' @((Mk 'circle' (RectNoScroll '#list2 .rc:nth-child(1) .hdr') '부가세 확인'), (Mk 'tap' (RectNoScroll '#list2 .rc:nth-child(1) [data-vat]') '1/11 다시 계산'))
  TapSel '#list2 .rc:nth-child(1) [data-vat]' | Out-Null; Start-Sleep -Milliseconds 250
  $log += 'after 1/11: row1 vat=' + (Js 'return EX.S.rows[0].vat')
  $t = Js 'return JSON.stringify(EX.totals())'
  $log += 'app totals: ' + $t
  # 손 검산(이 스크립트에서 따로 계산)
  $hand = @(@(48000, 'tax'), @(132000, 'tax'), @(15800, 'simple')) | ForEach-Object { $tot = $_[0]; $vat = if ($_[1] -eq 'tax') { $tot - [math]::Round($tot / 1.1, [MidpointRounding]::AwayFromZero) } else { 0 }; [pscustomobject]@{ total = $tot; vat = $vat; supply = $tot - $vat } }
  $hs = ($hand | Measure-Object supply -Sum).Sum; $hv = ($hand | Measure-Object vat -Sum).Sum; $ht = ($hand | Measure-Object total -Sum).Sum
  $tj = $t | ConvertFrom-Json
  $log += "hand check: rows=" + (($hand | ForEach-Object { "$($_.supply)+$($_.vat)=$($_.total)" }) -join ', ') + " / sum supply=$hs vat=$hv total=$ht / match=" + (($tj.supply -eq $hs) -and ($tj.vat -eq $hv) -and ($tj.total -eq $ht) -and ($hs + $hv -eq $ht))
  ScrollTo '#totBox' 'center'
  Shot $out '08_check_ok' @((Mk 'circle' (RectNoScroll '#totOk') '검산 일치'))
  # 3단계: 서식 3종
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
  TapSel '#headBox input[data-h="title"]' | Out-Null; TypeText '11월 영업팀 경비'
  TapSel '#headBox input[data-h="writer"]' | Out-Null; TypeText '김민수'
  TapSel '#headBox input[data-h="dept"]' | Out-Null; TypeText '영업팀'
  Js "const e=document.querySelector('#headBox input[data-h=date]'); e.value='2026-11-18'; e.dispatchEvent(new Event('input',{bubbles:true})); return 1" | Out-Null
  ScrollTo '#formSeg' 'start' -170
  Shot $out '09_form_general' @((Mk 'tap' (RectNoScroll '#formSeg button[data-v="general"]') '서식 3종'), (Mk 'circle' (RectNoScroll '#headBox') '머리 정보'))
  ScrollTo '#xlsxBtn' 'center'
  Shot $out '10_export' @((Mk 'tap' (RectNoScroll '#xlsxBtn') '엑셀 저장'), (Mk 'tap' (RectNoScroll '#printBtn') '인쇄·PDF'), (Mk 'circle' (RectNoScroll '.cp') '사진 목록 붙임'))
  ScrollTo '#pvWrap' 'start' -170
  Shot $out '11_preview_general' @((Mk 'circle' (RectNoScroll '#pvWrap') '결의서 미리보기'))
  Save-B64 (Js ($B64JS + 'return await b2(await EX.xlsxBlob())')) (Join-Path $files '지출결의서_11월영업팀경비_20261118.xlsx')
  TapSel '#xlsxBtn' | Out-Null; Start-Sleep -Milliseconds 400
  $log += 'xlsx btn: ' + (Invoke-Js "document.querySelector('#outInfo').textContent")
  TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
  $log += 'print called: ' + (Js 'return String(window.__printed||0)')
  $pdf = Join-Path $files '지출결의서_일반_인쇄.pdf'; Print-Pdf $pdf; $log += 'general pdf pages=' + (Pages $pdf)
  # 사진 목록 붙임 포함
  TapSel '#phPrint' | Out-Null; TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
  $pdf = Join-Path $files '지출결의서_일반_사진붙임_인쇄.pdf'; Print-Pdf $pdf; $log += 'general + photo list pdf pages=' + (Pages $pdf) + ' (결의서 1 + 사진 목록 1)'
  TapSel '#phPrint' | Out-Null
  foreach ($f in 'trip', 'ent') {
    TapSel ('#formSeg button[data-v="' + $f + '"]') | Out-Null; Start-Sleep -Milliseconds 250
    if ($f -eq 'trip') { TapSel '#headBox input[data-h="place"]' | Out-Null; TypeText '부산 해운대'; TapSel '#headBox input[data-h="period"]' | Out-Null; TypeText '2026-11-10 ~ 2026-11-11'; TapSel '#headBox input[data-h="purpose"]' | Out-Null; TypeText '거래처 설비 점검' }
    else { TapSel '#headBox input[data-h="guest"]' | Out-Null; TypeText '(주)한빛상사 김부장 외 1명'; TapSel '#headBox input[data-h="people"]' | Out-Null; TypeText '3명'; TapSel '#headBox input[data-h="purpose"]' | Out-Null; TypeText '연간 납품 계약 협의' }
    ScrollTo '#formSeg' 'start' -170
    Shot $out ('12_form_' + $f) @((Mk 'tap' (RectNoScroll ('#formSeg button[data-v="' + $f + '"]')) ''), (Mk 'circle' (RectNoScroll '#headBox') '서식 전용 칸'))
    TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
    $fk = @{ trip = '출장'; ent = '접대' }[$f]; $pdf = Join-Path $files ('지출결의서_' + $fk + '_인쇄.pdf'); Print-Pdf $pdf; $log += "$f pdf pages=" + (Pages $pdf)
    Save-B64 (Js ($B64JS + 'return await b2(await EX.xlsxBlob())')) (Join-Path $files ('지출결의서_' + $fk + '.xlsx'))
  }
  # 인쇄 레이아웃 캡처(일반)
  TapSel '#formSeg button[data-v="general"]' | Out-Null
  Js 'document.querySelector("#printArea").innerHTML = EX.paperHtml(); return 1' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 706; height = 1000; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null; Start-Sleep -Milliseconds 400
  $h = [int](Invoke-Js "Math.ceil(document.querySelector('#printArea .paper').getBoundingClientRect().height)")
  $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 706; height = $h; scale = 1 } }
  [IO.File]::WriteAllBytes((Join-Path $out 'print_layout_general.png'), [Convert]::FromBase64String($r['data']))
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  # 자동 저장: 새로고침 후 남아 있는지
  Nav 'oneclick\expense.html'
  $log += 'after reload: ' + (Js 'return JSON.stringify({rows:EX.S.rows.length, title:EX.S.head.title, total:EX.totals().total, thumbs:EX.S.rows.filter(r=>r.thumb).length})')
  Js 'EX.go(1); return 1' | Out-Null
  TapSel '#qName' | Out-Null; TypeText '김사장'; TapSel '#qTel' | Out-Null; TypeText '010-2468-1357'; TapSel '#qMsg' | Out-Null; TypeText '법인카드 사용 내역서 서식도 있으면 좋겠습니다'
  TapSel '#qMake' | Out-Null; Start-Sleep -Milliseconds 200
  ScrollTo '.qa' 'start' -150
  Shot $out '90_inquiry' @((Mk 'tap' (RectNoScroll '#qMake') '답장 초안'), (Mk 'circle' (RectNoScroll '#qDraft') '자동 발송 없음'))
  $log = Finish $out $log
} finally { Stop-CdpChrome }
$log

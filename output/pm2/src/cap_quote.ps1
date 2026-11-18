# 견적서 1초 발행 실화면 검수·캡처 (3건 연속 발행 → 연번 0001·0002·0003, 각 PDF A4 1쪽)
. "$PSScriptRoot\pmlib.ps1"
$out = AppDir 'quote'; $files = Join-Path $out 'files'
$log = @()
function TypeIn([string]$sel, [string]$v) { TapSel $sel | Out-Null; TypeText $v }
function SetVal([string]$sel, [string]$v) { Js ("const e=document.querySelector('" + $sel + "'); e.value='" + $v + "'; e.dispatchEvent(new Event('input',{bubbles:true})); return 1") | Out-Null }
function AddItems($items) {
  for ($i = 0; $i -lt $items.Count; $i++) {
    if ($i -gt 0) { TapSel '#addItem' | Out-Null; Start-Sleep -Milliseconds 150 }
    $c = '#items .it:nth-child(' + ($i + 1) + ')'
    TypeIn ($c + ' [data-it="name"]') $items[$i][0]
    if ($items[$i][1]) { TypeIn ($c + ' [data-it="spec"]') $items[$i][1] }
    SetVal ($c + ' [data-it="qty"]') ''; TypeIn ($c + ' [data-it="qty"]') $items[$i][2]
    TypeIn ($c + ' [data-it="price"]') $items[$i][3]
  }
}
Open-App 'oneclick\quote.html' 9355
try {
  Js 'localStorage.clear(); return 1' | Out-Null
  Nav 'oneclick\quote.html'
  Shot $out '01_me_empty' @((Mk 'circle' (RectNoScroll '#meBox') '내 정보(1회)'))
  $ME = @(@('name', 'KTS인테리어'), @('rep', '김대표'), @('bizno', '123-45-67890'), @('addr', '서울특별시 송파구 올림픽로 300 KTS타워 5층'), @('tel', '02-123-4567'), @('email', 'kts@example.com'), @('bank', 'KTS은행 100-200-300400 (KTS인테리어)'))
  foreach ($m in $ME) { TypeIn ('#meBox input[data-me="' + $m[0] + '"]') $m[1] }
  ScrollTo '#meSave' 'center'
  Shot $out '02_me_filled' @((Mk 'tap' (RectNoScroll '#meSave') '내 정보 저장'))
  TapSel '#meSave' | Out-Null; Start-Sleep -Milliseconds 200
  $log += 'me saved: ' + (Js 'return localStorage.getItem("kq_me_v1")')
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 300
  # 견적 1: 부가세 별도
  TypeIn '#cust' '(주)한빛상사'; SetVal '#qdate' '2026-11-18'
  TapSel '#validChips button[data-d="30"]' | Out-Null
  TypeIn '#pay' '착수 50%, 완료 후 50% 계좌이체'; TypeIn '#note' '자재는 동급 이상으로 바꿀 수 있습니다'
  ScrollTo '#cust' 'start' -200
  Shot $out '03_cond' @((Mk 'circle' (RectNoScroll '#cust') '고객명'), (Mk 'tap' (RectNoScroll '#validChips button[data-d="30"]') '유효기간 D+30'), (Mk 'circle' (RectNoScroll '#vatSeg') '부가세 별도/포함'))
  AddItems @(@('강화마루 시공', '㎡', '33', '45000'), @('걸레받이 교체', 'm', '40', '8000'), @('폐자재 처리', '식', '1', '150000'))
  ScrollTo '#items .it:nth-child(2)' 'start' -160
  Shot $out '04_items' @((Mk 'tap' (RectNoScroll '#addItem') '+ 품목'), (Mk 'circle' (RectNoScroll '#items .it:nth-child(3) .amt') '금액 자동'), (Mk 'circle' (RectNoScroll '#sumBox') '합계·부가세'))
  $c1 = Js 'return JSON.stringify(QT.calc())'
  $hand1 = (33 * 45000) + (40 * 8000) + 150000; $hv1 = [math]::Floor($hand1 * 0.1)
  $log += "quote1 calc=$c1 / hand: supply=$hand1 vat=$hv1 total=" + ($hand1 + $hv1)
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
  Shot $out '05_before_issue' @((Mk 'circle' (RectNoScroll '#issueBox') '다음 번호'), (Mk 'tap' (RectNoScroll '#issueBtn') '발행'))
  TapSel '#issueBtn' | Out-Null; Start-Sleep -Milliseconds 300
  Shot $out '06_issued' @((Mk 'circle' (RectNoScroll '#issueBox') '발행 번호'), (Mk 'tap' (RectNoScroll '#printBtn') '인쇄·PDF'), (Mk 'tap' (RectNoScroll '#hwpxBtn') '한글'))
  ScrollTo '#pvWrap' 'start' -170
  Shot $out '07_preview' @((Mk 'circle' (RectNoScroll '#pvWrap') '견적서 A4 1장'))
  $no = Js 'return QT.S.issued'
  TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
  $pdf = Join-Path $files ("견적서_${no}_인쇄.pdf"); Print-Pdf $pdf; $log += "quote1 no=$no pdf pages=" + (Pages $pdf)
  Save-B64 (Js ($B64JS + 'return await b2(await QT.hwpxBlob(QT.S.issued))')) (Join-Path $files ("견적서_${no}.hwpx"))
  TapSel '#hwpxBtn' | Out-Null; Start-Sleep -Milliseconds 400
  $log += 'hwpx btn: ' + (Invoke-Js "document.querySelector('#outInfo').textContent")
  # 인쇄 레이아웃 캡처
  Js 'document.querySelector("#printArea").innerHTML = QT.paperHtml(QT.S.issued); return 1' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 680; height = 1000; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null; Start-Sleep -Milliseconds 400
  $h = [int](Invoke-Js "Math.ceil(document.querySelector('#printArea .paper').getBoundingClientRect().height)")
  $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 680; height = $h; scale = 1 } }
  [IO.File]::WriteAllBytes((Join-Path $out 'print_layout_quote1.png'), [Convert]::FromBase64String($r['data']))
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  # 견적 2: 부가세 포함 · [인쇄]만 눌러도 번호 자동 발행
  TapSel '#newBtn' | Out-Null; Start-Sleep -Milliseconds 300
  $log += 'new quote starts at step: ' + (Js 'return String(QT.S.step)')
  TypeIn '#cust' 'KTS카페'; SetVal '#qdate' '2026-11-18'
  TapSel '#vatSeg button[data-v="in"]' | Out-Null
  AddItems @(,@('커피머신 정기 점검', '1회', '1', '110000'))
  $c2 = Js 'return JSON.stringify(QT.calc())'; $log += "quote2 (vat incl.) calc=$c2 / hand: total=110000 supply=" + [math]::Round(110000 / 1.1) + ' vat=' + (110000 - [math]::Round(110000 / 1.1))
  ScrollTo '#sumBox' 'center'
  Shot $out '08_vat_included' @((Mk 'circle' (RectNoScroll '#sumBox') '부가세 포함 계산'))
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 300
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 500
  $no = Js 'return QT.S.issued'
  $pdf = Join-Path $files ("견적서_${no}_인쇄.pdf"); Print-Pdf $pdf; $log += "quote2 no=$no (auto-issued by print) pdf pages=" + (Pages $pdf)
  # 견적 3
  TapSel '#newBtn' | Out-Null; Start-Sleep -Milliseconds 300
  TypeIn '#cust' '박서준'; SetVal '#qdate' '2026-11-18'
  AddItems @(@('욕실 타일 보수', '㎡', '2', '250000'), @('실리콘 재시공', '식', '1', '60000'))
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 300
  TapSel '#issueBtn' | Out-Null; Start-Sleep -Milliseconds 300
  $no = Js 'return QT.S.issued'
  TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
  $pdf = Join-Path $files ("견적서_${no}_인쇄.pdf"); Print-Pdf $pdf; $log += "quote3 no=$no pdf pages=" + (Pages $pdf)
  Save-B64 (Js ($B64JS + 'return await b2(await QT.hwpxBlob(QT.S.issued))')) (Join-Path $files ("견적서_${no}.hwpx"))
  # 같은 견적에 발행을 다시 눌러도 번호가 늘지 않음
  TapSel '#issueBtn' | Out-Null; Start-Sleep -Milliseconds 200
  $log += 're-issue same quote: toast=' + (Toast) + ' / ledger=' + (Js 'return JSON.stringify(QT.ledger().map(e=>e.no))')
  ScrollTo '#ledger' 'start' -200
  Shot $out '09_ledger' @((Mk 'circle' (RectNoScroll '#ledger') '발행 대장'))
  # 발행 뒤 내용을 고치면 → 새 번호로 발행 안내(이미 쓴 번호 재사용 0)
  Js 'QT.S.note = "타일 색상 변경"; QT.save(); QT.go(3); return 1' | Out-Null
  $log += 'edited after issue: isIssued=' + (Js 'return String(QT.isIssued())') + ' next=' + (Js 'return QT.nextNo("2026")')
  Shot $out '10_edited_after_issue' @((Mk 'circle' (RectNoScroll '#issueBox') '고치면 새 번호'))
  $led = Js 'return JSON.stringify(QT.ledger())'
  $nos = ($led | ConvertFrom-Json) | ForEach-Object { $_.no }
  $log += 'ledger nos=' + ($nos -join ',') + ' unique=' + (@($nos | Select-Object -Unique).Count -eq @($nos).Count)
  [IO.File]::WriteAllText((Join-Path $out 'ledger.json'), $led, (New-Object Text.UTF8Encoding($false)))
  # 새로고침: 내 정보·대장 유지, 2단계부터
  Nav 'oneclick\quote.html'
  $log += 'after reload: ' + (Js 'return JSON.stringify({step:QT.S.step, me:QT.ME.name, ledger:QT.ledger().length})')
  Js 'QT.go(1); return 1' | Out-Null
  TypeIn '#qName' '김대표'; TypeIn '#qTel' '02-123-4567'; TypeIn '#qMsg' '견적서에 회사 도장 그림도 넣고 싶습니다'
  TapSel '#qMake' | Out-Null; Start-Sleep -Milliseconds 200
  ScrollTo '.qa' 'start' -150
  Shot $out '90_inquiry' @((Mk 'tap' (RectNoScroll '#qMake') '답장 초안'), (Mk 'circle' (RectNoScroll '#qDraft') '자동 발송 없음'))
  $log = Finish $out $log
} finally { Stop-CdpChrome }
$log

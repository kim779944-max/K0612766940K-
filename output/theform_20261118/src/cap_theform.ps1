# 더양식 실화면 검수·캡처 (390x844 @2x) — 실제 탭·끌기·타이핑으로 진행
. "$PSScriptRoot\lib.ps1"
$out = (Resolve-Path "$PSScriptRoot\..").Path
$files = Join-Path $out 'files'; $work = Join-Path $out 'work'
New-Item -ItemType Directory -Force $files, $work | Out-Null
Open-App 'oneclick\theform.html'
$log = @()
function SigDraw($sg) {
  Drag ($sg.x + 40) ($sg.y + 70) ($sg.x + 110) ($sg.y + 28) 6
  Drag ($sg.x + 110) ($sg.y + 28) ($sg.x + 175) ($sg.y + 80) 6
  Drag ($sg.x + 150) ($sg.y + 55) ($sg.x + 270) ($sg.y + 42) 6
}
try {
  Shot $out '01_home' @((Mk 'tap' (Rect '#pickBtn') '양식 사진 찍기'))

  # 시험용 '찍은 사진': 어두운 바닥 위에 기울어진 종이 양식
  $b64 = Js ($B64JS + @'
const P=document.createElement("canvas");P.width=800;P.height=1100;const g=P.getContext("2d");
g.fillStyle="#fbfaf6";g.fillRect(0,0,800,1100);g.fillStyle="#111";g.font="700 46px Malgun Gothic";g.textAlign="center";g.fillText("방 문 신 청 서",400,110);
g.font="400 20px Malgun Gothic";g.fillText("아래 칸을 채워 안내 데스크에 내 주세요",400,155);
const L=["성명","연락처","방문일","방문 인원","방문 목적","서명"];g.textAlign="left";g.font="700 26px Malgun Gothic";g.lineWidth=2;g.strokeStyle="#222";
L.forEach((t,i)=>{const y=200+i*110;g.fillStyle="#111";g.fillText(t,80,y+40);g.strokeRect(260,y,460,60);});
g.font="400 18px Malgun Gothic";g.fillText("KTS 빌딩 관리사무소",540,1040);
const B=document.createElement("canvas");B.width=1200;B.height=1500;const h=B.getContext("2d");
const gr=h.createLinearGradient(0,0,1200,1500);gr.addColorStop(0,"#3b2d22");gr.addColorStop(1,"#1f1812");h.fillStyle=gr;h.fillRect(0,0,1200,1500);
h.translate(600,760);h.rotate(-0.11);h.shadowColor="rgba(0,0,0,.6)";h.shadowBlur=30;h.drawImage(P,-440,-605,880,1210);
const bl=await new Promise(r=>B.toBlob(r,"image/jpeg",0.9));return await b2(bl);
'@)
  $photo = Join-Path $work 'test_form_photo.jpg'; Save-B64 $b64 $photo
  Set-FileInput '#photoIn' @($photo)
  Start-Sleep -Milliseconds 300
  Wait-Idle "!document.querySelector('#busy').classList.contains('on') && !!(window.TF.CUR)" | Out-Null
  $log += 'regInfo: ' + (Invoke-Js "document.querySelector('#regInfo').textContent")
  $log += 'fixed size: ' + (Invoke-Js "document.querySelector('#regCv').width + 'x' + document.querySelector('#regCv').height")
  Invoke-Js "document.querySelector('#regStage').scrollIntoView({block:'start'}); window.scrollBy(0,-150)" | Out-Null
  Shot $out '02_auto_fix_after' @((Mk 'circle' (RectNoScroll '#regStage') '자동 보정 결과'), (Mk 'tap' (RectNoScroll '#regSeg button[data-v="raw"]') '보정 전 비교'))
  TapSel '#regSeg button[data-v="raw"]' | Out-Null
  Invoke-Js "document.querySelector('#regStage').scrollIntoView({block:'start'}); window.scrollBy(0,-150)" | Out-Null
  Shot $out '02b_auto_fix_before' @((Mk 'tap' (RectNoScroll '#regSeg button[data-v="raw"]') '보정 전'))
  TapSel '#regSeg button[data-v="fix"]' | Out-Null
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400

  # ② 빈칸 지정: 실제 탭으로 칸을 만들고, 이름표를 치고, 파란 점을 끌어 칸 크기를 맞춘다
  $defs = @(@('성명', 'text'), @('연락처', 'text'), @('방문일', 'date'), @('방문 인원', 'number'), @('방문 목적', 'text'), @('서명', 'sign'))
  $lastTap = $null
  for ($i = 0; $i -lt $defs.Count; $i++) {
    $st = Rect '#edStage' 'start'
    $bx = 260 / 800; $bw = 460 / 800; $by = (200 + $i * 110) / 1100; $bh = 60 / 1100
    $ty = $st.y + ($by + 0.018) * $st.h
    if ($ty -gt 780) { Invoke-Js ("window.scrollBy(0," + [int]($ty - 400) + ")") | Out-Null; $st = RectNoScroll '#edStage'; $ty = $st.y + ($by + 0.018) * $st.h }
    $tx = $st.x + ($bx + 0.13) * $st.w
    Tap $tx $ty; Start-Sleep -Milliseconds 150
    $lastTap = [pscustomobject]@{ x = $tx - 20; y = $ty - 20; w = 40; h = 40 }
    Invoke-Js "(()=>{const i=document.querySelector('#fLabel'); i.focus(); i.select(); return 1})()" | Out-Null
    TypeText $defs[$i][0]
    if ($defs[$i][1] -ne 'text') { Js ('document.querySelector(''#fType button[data-v="' + $defs[$i][1] + '"]'').click(); return 1') | Out-Null }
    $st = RectNoScroll '#edStage'
    $hd = RectNoScroll '#edStage .fld.sel .hd2'
    Drag ($hd.x + $hd.w / 2) ($hd.y + $hd.h / 2) ($st.x + ($bx + $bw) * $st.w - 3) ($st.y + ($by + $bh) * $st.h - 3)
    Start-Sleep -Milliseconds 120
  }
  $log += 'fields after taps: ' + (Js 'return JSON.stringify(TF.CUR.fields.map(f=>f.label+"/"+f.type+"@"+[f.x,f.y,f.w,f.h].map(v=>v.toFixed(1)).join(",")))')
  Invoke-Js "document.querySelector('#edStage').scrollIntoView({block:'start'}); window.scrollBy(0,-150)" | Out-Null
  $lt = Js 'const f=TF.CUR.fields[0], r=document.querySelector("#edStage").getBoundingClientRect(); return JSON.stringify({x:r.x+(f.x+13)/100*r.width-20, y:r.y+(f.y+1.8)/100*r.height-20, w:40, h:40})'
  Shot $out '03_fields_tap' @((Mk 'tap' ($lt | ConvertFrom-Json) '빈 곳을 누르면 칸 추가'), (Mk 'circle' (RectNoScroll '#edStage .fld.sel .hd2') '파란 점 끌어 크기'), (Mk 'circle' (RectNoScroll '#addF') '+ 칸 추가'), (Mk 'circle' (RectNoScroll '#undoF') '되돌리기'))
  Invoke-Js "document.querySelector('#fEdit').scrollIntoView({block:'center'})" | Out-Null
  Shot $out '03b_field_label_type' @((Mk 'circle' (RectNoScroll '#fLabel') '이름표'), (Mk 'circle' (RectNoScroll '#fType') '성격'))
  # 되돌리기 10단계 이상 시험 (칸 12개 추가 → 12번 되돌리기 → 원래대로)
  $log += 'undo test: ' + (Js 'const n=TF.CUR.fields.length; for(let i=0;i<12;i++) TF.addField(10+i*5,95); const depth=TF.UNDO.length; for(let i=0;i<12;i++) TF.undo(); TF.SEL=-1; TF.drawEditor(); return JSON.stringify({before:n, afterAdd:n+12, undoDepth:depth, afterUndo:TF.CUR.fields.length, ok:TF.CUR.fields.length===n && depth>=12})')
  $log += 'delete+undo: ' + (Js 'const n=TF.CUR.fields.length; TF.SEL=0; document.querySelector("#delF").click(); const a=TF.CUR.fields.length; document.querySelector("#undoF").click(); TF.SEL=-1; TF.drawEditor(); return JSON.stringify({n, afterDel:a, afterUndo:TF.CUR.fields.length})')
  TapSel '#formName' | Out-Null; TypeText '방문 신청서'
  Shot $out '03c_form_name' @((Mk 'circle' (RectNoScroll '#formName') '양식 이름'), (Mk 'tap' (RectNoScroll '#nextBtn') '내 양식으로 저장'))
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 600
  $log += 'saved forms: ' + (Js 'return JSON.stringify(TF.myForms().map(f=>f.name+":"+f.fields.length))')

  # ③ 값 입력(실제 타이핑 + 손가락 서명)
  $vals = @('박서준', '010-2345-6789', '', '3', '설비 점검 협의')
  for ($i = 0; $i -lt $vals.Count; $i++) {
    if ($i -eq 2) { Js 'const e=document.querySelector("#valList input[data-f=\"2\"]"); e.value="2026-11-20"; e.dispatchEvent(new Event("input",{bubbles:true})); return 1' | Out-Null; continue }
    TapSel ('#valList input[data-f="' + $i + '"]') | Out-Null; TypeText $vals[$i]
  }
  SigDraw (Rect '#valList canvas[data-sig]')
  Invoke-Js "document.querySelector('#valList').scrollIntoView({block:'start'}); window.scrollBy(0,-200)" | Out-Null
  Shot $out '04_custom_values' @((Mk 'circle' (RectNoScroll '#valList input[data-f="0"]') '값 타이핑'), (Mk 'circle' (RectNoScroll '#voiceBtn') '음성 메모'))
  Invoke-Js "document.querySelector('#valList canvas[data-sig]').scrollIntoView({block:'center'})" | Out-Null
  Shot $out '04b_custom_sign' @((Mk 'tap' (RectNoScroll '#valList canvas[data-sig]') '손가락 서명'))
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 800
  Shot $out '05_custom_preview' @((Mk 'circle' (RectNoScroll '#pvCv') '종이 위에 값이 얹힘'))
  TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 300
  Shot $out '05b_custom_export' @((Mk 'tap' (RectNoScroll '#exHwpx') '한글'), (Mk 'tap' (RectNoScroll '#exXlsx') '엑셀'), (Mk 'tap' (RectNoScroll '#exPrint') '인쇄·PDF'))
  foreach ($k in 'hwpx', 'xlsx') { Save-B64 (Js ($B64JS + "return await b2(await TF.exportBlob('$k'))")) (Join-Path $files ("방문신청서_내양식.$k")) }
  TapSel '#exPrint' | Out-Null; Start-Sleep -Milliseconds 900
  Print-Pdf (Join-Path $files '방문신청서_내양식_인쇄.pdf')

  # ① 목록: 내 양식 + 기본 5종, 복제·삭제 시험
  Js 'TF.go(1); return 1' | Out-Null
  $log += 'dup/delete: ' + (Js 'const n=TF.myForms().length; const id=await TF.dupForm(TF.myForms()[0].id); const a=TF.myForms().length; await TF.delForm(id); return JSON.stringify({n, afterDup:a, afterDel:TF.myForms().length})')
  Invoke-Js "document.querySelector('#formList').scrollIntoView({block:'start'}); window.scrollBy(0,-170)" | Out-Null
  Shot $out '06_my_list' @((Mk 'tap' (RectNoScroll '#formList .fi:first-child [data-open]') '열기'), (Mk 'circle' (RectNoScroll '#formList .fi:first-child [data-dup]') '복제'), (Mk 'circle' (RectNoScroll '#formList .fi:first-child [data-del]') '삭제'))

  # 기본 양식 1: 거래명세서
  TapSel '#formList [data-open="b_trade"]' | Out-Null; Start-Sleep -Milliseconds 600
  Js 'document.querySelector("#sampleVals").click(); return 1' | Out-Null
  Invoke-Js "window.scrollTo(0,0)" | Out-Null
  Shot $out '07_trade_values' @((Mk 'circle' (RectNoScroll '#valList input[data-f="4"]') '합계 자동 계산'), (Mk 'circle' (RectNoScroll '#handBtn') '손글씨 사진(열쇠 필요)'))
  Js 'TF.go(2); return 1' | Out-Null
  Shot $out '07b_trade_fields' @((Mk 'circle' (RectNoScroll '#edStage') '기본 양식 빈칸 23개'))
  Js 'TF.go(4); return 1' | Out-Null; Start-Sleep -Milliseconds 700
  Shot $out '08_trade_preview' @((Mk 'circle' (RectNoScroll '#pvCv') '미리보기'))
  Js 'TF.go(5); return 1' | Out-Null
  Shot $out '09_trade_export' @((Mk 'tap' (RectNoScroll '#exHwpx') '한글'), (Mk 'tap' (RectNoScroll '#exXlsx') '엑셀'), (Mk 'tap' (RectNoScroll '#exPrint') '인쇄·PDF'))
  foreach ($k in 'hwpx', 'xlsx') { Save-B64 (Js ($B64JS + "return await b2(await TF.exportBlob('$k'))")) (Join-Path $files ("거래명세서_기본.$k")) }
  TapSel '#exPrint' | Out-Null; Start-Sleep -Milliseconds 900
  Print-Pdf (Join-Path $files '거래명세서_기본_인쇄.pdf')

  # 기본 양식 2: 근로계약서 (서명 2곳 손가락)
  Js 'await TF.openForm("b_labor",3); document.querySelector("#sampleVals").click(); return 1' | Out-Null; Start-Sleep -Milliseconds 400
  $sigs = [int](Invoke-Js "document.querySelectorAll('#valList canvas[data-sig]').length")
  for ($s = 0; $s -lt $sigs; $s++) {
    $sg = (Invoke-Js ("(()=>{const e=document.querySelectorAll('#valList canvas[data-sig]')[" + $s + "]; e.scrollIntoView({block:'center'}); const r=e.getBoundingClientRect(); return JSON.stringify({x:r.x,y:r.y,w:r.width,h:r.height})})()")) | ConvertFrom-Json
    SigDraw $sg
  }
  Js 'TF.go(4); return 1' | Out-Null; Start-Sleep -Milliseconds 800
  Shot $out '10_labor_preview' @((Mk 'circle' (RectNoScroll '#pvCv') '근로계약서 미리보기'))
  foreach ($k in 'hwpx', 'xlsx') { Save-B64 (Js ($B64JS + "return await b2(await TF.exportBlob('$k'))")) (Join-Path $files ("근로계약서_기본.$k")) }
  Js 'TF.go(5); return 1' | Out-Null; TapSel '#exPrint' | Out-Null; Start-Sleep -Milliseconds 900
  Print-Pdf (Join-Path $files '근로계약서_기본_인쇄.pdf')

  # 60초 문의
  Js 'TF.go(1); return 1' | Out-Null
  TapSel '#qName' | Out-Null; TypeText '김사장'; TapSel '#qTel' | Out-Null; TypeText '010-9876-5432'; TapSel '#qMsg' | Out-Null; TypeText '우리 업종 납품확인서 양식도 넣어 주세요'
  TapSel '#qMake' | Out-Null
  Invoke-Js "document.querySelector('#qa').scrollIntoView({block:'start'})" | Out-Null
  Shot $out '11_inquiry' @((Mk 'tap' (RectNoScroll '#qMake') '답장 초안'), (Mk 'circle' (RectNoScroll '#qDraft') '자동 발송 없음'))
  Invoke-Js "window.scrollTo(0,0)" | Out-Null
  TapSel '#keyBtn' | Out-Null; Start-Sleep -Milliseconds 300
  Shot $out '12_key_sheet' @((Mk 'circle' (RectNoScroll '#keyIn') '내 무료 열쇠(선택)'))
  $log += 'errors: ' + (Js 'return JSON.stringify(window.__errs)')
  $log += 'print calls: ' + (Js 'return String(window.__printed||0)')
} finally { Stop-CdpChrome }
Save-Marks (Join-Path $out 'marks.json')
$log | Set-Content -Encoding UTF8 (Join-Path $out 'run_log.txt')
$log

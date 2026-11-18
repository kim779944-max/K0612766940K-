# 9차 개발팀 10종: 390x844 @2x 실화면 검수 + 캡처 3장(① 누르는 곳 ② 입력 ③ 결과) + 기능 검증 로그
# 직전 회차 도구(theform_20261118/src/lib.ps1: CDP 크롬 · 탭/타이핑/캡처/좌표 기록) 재사용
param([string]$app = 'faqbot')
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$dir = Join-Path $OUT ("shots\" + $app); New-Item -ItemType Directory -Force $dir | Out-Null
$files = Join-Path $OUT 'files'; New-Item -ItemType Directory -Force $files | Out-Null
$global:MARKS = @(); $global:ERRS = @()
$log = @()
function L([string]$s) { $script:log += $s; Write-Output $s }
function SetVal([string]$sel, [string]$v) { Js ("const e=document.querySelector('" + $sel + "'); e.value=" + (ConvertTo-Json $v) + "; e.dispatchEvent(new Event('input',{bubbles:true})); return 1") | Out-Null }
function TypeIn([string]$sel, [string]$v) { TapSel $sel | Out-Null; TypeText $v }
function ScrollTo([string]$sel, [string]$block = 'start', [int]$dy = 0) { Invoke-Js ("(()=>{const t=document.querySelector('#toast'); t&&t.classList.remove('on'); const e=document.querySelector('" + $sel + "'); e.scrollIntoView({block:'" + $block + "'}); window.scrollBy(0," + $dy + "); return 1})()") | Out-Null; Start-Sleep -Milliseconds 300 }
$LAYOUT = @'
(()=>{const W=innerWidth,bad=[];document.querySelectorAll('#app *').forEach(e=>{const cs=getComputedStyle(e);if(cs.display==='none'||cs.visibility==='hidden'||e.closest('.hide'))return;const r=e.getBoundingClientRect();if(!r.width||!r.height)return;
if(r.right>W+0.5||r.left<-0.5)bad.push('OUT '+e.tagName+'.'+e.className+' '+Math.round(r.left)+'~'+Math.round(r.right));
if(!/INPUT|TEXTAREA|SELECT/.test(e.tagName)&&(cs.overflowX==='hidden'||cs.textOverflow==='ellipsis')&&e.scrollWidth>e.clientWidth+1&&!e.closest('.pv'))bad.push('CLIP '+e.tagName+'.'+e.className+' "'+e.textContent.slice(0,24)+'"')});
return JSON.stringify({sw:document.documentElement.scrollWidth,n:bad.length,bad:bad.slice(0,12)})})()
'@
function Layout([string]$when) { $r = Invoke-Js $LAYOUT; L ("layout[" + $when + "]: " + $r); return ($r | ConvertFrom-Json) }
function PrintPdf([string]$name) {
  TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 500
  $pdf = Join-Path $files ($app + '_' + $name + '.pdf'); Print-Pdf $pdf
  $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pdf)); $pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count
  L ("print " + $name + ": pages=" + $pages + " bytes=" + (Get-Item $pdf).Length + " file=files\" + (Split-Path $pdf -Leaf)); return $pages
}
function Std([string]$inputSel, [string]$resultSel, [string]$copySel = '#copyBtn', [scriptblock]$afterSample = $null) {
  Shot $dir '01_press' @((Mk 'tap' (RectNoScroll '#sampleBtn') '① 여기를 누르세요'))
  TapSel '#sampleBtn' | Out-Null; Start-Sleep -Milliseconds 500
  if ($afterSample) { & $afterSample }
  ScrollTo '#runBtn' 'end' 40
  Shot $dir '02_input' @((Mk 'circle' (RectNoScroll $inputSel) '② 입력 확인'), (Mk 'tap' (RectNoScroll '#runBtn') '만들기'))
  TapSel '#runBtn' | Out-Null; Start-Sleep -Milliseconds 700
  ScrollTo $resultSel 'start' -64
  Shot $dir '03_result' @((Mk 'tap' (RectNoScroll $copySel) '③ 결과 복사·저장'))
}
Open-App ("oneclick\" + $app + ".html") 9371
try {
  Js 'localStorage.clear(); return 1' | Out-Null
  Nav ("oneclick\" + $app + ".html")
  $l0 = Layout 'start'
  switch ($app) {
  'faqbot' {
    Std '#fields' '#result'
    L ('items=' + (Js 'return String(document.querySelectorAll("#list .item").length)') + ' answered=' + (Js 'return $("#sOk").textContent') + ' fallback=' + (Js 'return $("#sFb").textContent'))
    TapSel '#copyBtn' | Out-Null; Start-Sleep -Milliseconds 300
    L ('json copy: ' + (Js 'const o=JSON.parse(window.__lastCopy); return "faq="+o.faq.length+" store="+o.store.name+" fallback="+o.rule.fallback'))
    TapSel '#csvBtn' | Out-Null; L ('csv: ' + (Js 'return JSON.stringify(window.__lastDownload)'))
    TypeIn '#testQ' '주차 돼요?'; TapSel '#testBtn' | Out-Null; L ('test1: ' + (Js 'return $("#testA").textContent'))
    SetVal '#testQ' '강아지 데려가도 돼요?'; TapSel '#testBtn' | Out-Null; L ('test2: ' + (Js 'return $("#testA").textContent'))
    L ('price answers use input only: ' + (Js 'return CUR.faq.filter(x=>x.field==="price").map(x=>x.a).join(" | ")'))
    PrintPdf 'faq40' | Out-Null
  }
  'csreply' {
    Std '#inq' '#result'
    TapSel '#copyBtn' | Out-Null; Start-Sleep -Milliseconds 200
    for ($i = 0; $i -lt 5; $i++) {
      TapSel ('#samples button[data-i="' + $i + '"]') | Out-Null
      foreach ($t in 'polite', 'brief', 'warm') {
        TapSel ('#tone button[data-t="' + $t + '"]') | Out-Null; TapSel '#runBtn' | Out-Null; Start-Sleep -Milliseconds 200
        $r = Js 'return [...document.querySelectorAll("#tags .tag")].map(x=>x.textContent).join(" / ")+" || "+$("#ans").value.replace(/\n/g," ⏎ ")'
        L ("sample" + ($i + 1) + " " + $t + ": " + $r)
      }
      TapSel '#saveBtn' | Out-Null
    }
    L ('promise check (숫자+원 금액 약속 없음): ' + (Js 'return String(!/\d[\d,]*\s*원/.test(LS.get("kts_csreply_hist_v1",[]).map(x=>x.ans).join(" ")))'))
    L ('history: ' + (Js 'return String(LS.get("kts_csreply_hist_v1",[]).length)'))
    TapSel '#tone button[data-t="polite"]' | Out-Null; TapSel '#samples button[data-i="0"]' | Out-Null; TapSel '#runBtn' | Out-Null
    ScrollTo '#result' 'start' -64
    Shot $dir '03_result' @((Mk 'tap' (RectNoScroll '#copyBtn') '③ 결과 복사·저장'))
    ScrollTo '#hist' 'center'
    Shot $dir '04_history' @((Mk 'circle' (RectNoScroll '#hist') '이력 20건 보관'))
  }
  'leadscore' {
    Std '#csv' '#result' '#csvBtn'
    L ('leads=' + (Js 'return String(CUR.length)') + ' grades A/B/C/D=' + (Js 'return ["A","B","C","D"].map(g=>CUR.filter(o=>o.grade===g).length).join("/")'))
    L ('order: ' + (Js 'return CUR.map(o=>o.이름+":"+o.score+o.grade).join(", ")'))
    L ('top1 why: ' + (Js 'return CUR[0].why.join(" | ")'))
    L ('calls=' + (Js 'return String(document.querySelectorAll("#calls .item").length)'))
    TapSel '#csvBtn' | Out-Null; L ('csv: ' + (Js 'return JSON.stringify(window.__lastDownload)'))
    TapSel '#copyBtn' | Out-Null; L ('copy head: ' + (Js 'return window.__lastCopy.slice(0,160)'))
    PrintPdf 'order' | Out-Null
  }
  'kakaotalk' {
    Std '#name' '#result'
    foreach ($k in 'food', 'hair', 'academy', 'clinic', 'shop') {
      TapSel ('#preset button[data-k="' + $k + '"]') | Out-Null; TapSel '#runBtn' | Out-Null; Start-Sleep -Milliseconds 200
      L ($k + ': secs=' + (Js 'return String(CUR.S.length)') + ' faq=' + (Js 'return String(CUR.S[1].qa.length)') + ' 확정문구=' + (Js 'return String(/확정되었|예약이 확정되었|자동으로 발송/.test($("#secs").textContent))'))
    }
    TapSel '#preset button[data-k="food"]' | Out-Null
    SetVal '#kakao' 'https://evil.example.com/x'; TapSel '#runBtn' | Out-Null; L ('bad kakao link -> ' + (Js 'return $("#toast").textContent'))
    SetVal '#kakao' 'https://pf.kakao.com/_kts000'; SetVal '#home' 'https://kim779944-max.github.io/K0612766940K-/oneclick/'; TapSel '#runBtn' | Out-Null
    L ('links in greeting: ' + (Js 'return CUR.S[0].msgs[0].split("\n").filter(x=>/http/.test(x)).join(" | ")'))
    TapSel '#copyBtn' | Out-Null; L ('copy len=' + (Js 'return String(window.__lastCopy.length)'))
    ScrollTo '#result' 'start' -64
    Shot $dir '03_result' @((Mk 'tap' (RectNoScroll '#copyBtn') '③ 결과 복사·저장'))
    PrintPdf 'food' | Out-Null
  }
  'weeksummary' {
    Std '#txt' '#result'
    L ('lines=' + (Js 'return $("#sN").textContent') + ' negLines=' + (Js 'return $("#sNeg").textContent') + ' masked=' + (Js 'return $("#sMask").textContent'))
    L ('neg top5: ' + (Js 'return CUR.neg.slice(0,5).map(([k,L])=>k+" "+L.length).join(", ")'))
    L ('pos top3: ' + (Js 'return CUR.pos.slice(0,3).map(([k,L])=>k+" "+L.length).join(", ")'))
    L ('raw phone/email left on page: ' + (Js 'return String(/010-0000-5566|kim\.review@/.test(document.querySelector("#result").textContent))'))
    L ('quote is verbatim: ' + (Js 'const q=[...document.querySelectorAll("#neg blockquote")][0]; const t=q.textContent.replace(/^\d+번 줄/,""); return String($("#txt").value.split("\n").map(maskPII).indexOf(t)>=0)+" -> "+t'))
    TapSel '#copyBtn' | Out-Null; TapSel '#csvBtn' | Out-Null; L ('csv: ' + (Js 'return JSON.stringify(window.__lastDownload)'))
    PrintPdf 'report' | Out-Null
  }
  'booking' {
    Std '#memo' '#result' '#printBtn'
    L ('parse: ' + (Js 'return JSON.stringify(window.__parse)') + ' fail="' + (Js 'return $("#fail").textContent') + '"')
    L ('sorted: ' + (Js 'const k=CUR.map(o=>o.date+o.time); return String(k.every((x,i)=>!i||k[i-1]<=x))') + ' today=' + (Js 'return $("#sToday").textContent') + ' risk=' + (Js 'return $("#sRisk").textContent'))
    L ('rows: ' + (Js 'return CUR.map(o=>o.date.slice(5)+" "+o.time+" "+o.name+" "+o.people+"명 "+o.tel+" "+o.risk).join(" | ")'))
    ScrollTo '#msgs' 'start' -64
    TapSel '#copyBtn' | Out-Null; L ('msg1: ' + (Js 'return window.__lastCopy.replace(/\n/g," ⏎ ")'))
    foreach ($i in 1, 2) { TapSel ('#msgs button[data-i="' + $i + '"]') | Out-Null; L ('msg' + ($i + 1) + ': ' + (Js 'return window.__lastCopy.replace(/\n/g," ⏎ ")')) }
    Shot $dir '04_messages' @((Mk 'circle' (RectNoScroll '#msgs') '문구 3종'), (Mk 'tap' (RectNoScroll '#copyBtn') '복사'))
    TapSel '#csvBtn' | Out-Null; L ('csv: ' + (Js 'return JSON.stringify(window.__lastDownload)'))
    PrintPdf 'today' | Out-Null
  }
  'visitlog' {
    Shot $dir '01_press' @((Mk 'tap' (RectNoScroll '#sampleBtn') '① 여기를 누르세요'))
    TapSel '#sampleBtn' | Out-Null; Start-Sleep -Milliseconds 400
    L ('after sample: customers=' + (Js 'return $("#sCu").textContent') + ' month=' + (Js 'return $("#sMon").textContent') + ' overdue=' + (Js 'return $("#sOver").textContent'))
    L ('today5: ' + (Js 'return window.__today5.join(", ")'))
    TypeIn '#v_name' '김영희'; TypeIn '#v_memo' '실외기 점검 완료, 다음 여름 전에 필터 교체 안내'; TapSel '#nextChips button[data-d="90"]' | Out-Null
    ScrollTo '#runBtn' 'end' 40
    Shot $dir '02_input' @((Mk 'circle' (RectNoScroll '#v_memo') '② 입력'), (Mk 'tap' (RectNoScroll '#runBtn') '저장'))
    TapSel '#runBtn' | Out-Null; Start-Sleep -Milliseconds 400
    L ('after add: today5: ' + (Js 'return window.__today5.join(", ")') + ' overdue=' + (Js 'return $("#sOver").textContent') + ' tel autofill=' + (Js 'return DB.rec[DB.rec.length-1].tel'))
    ScrollTo '#result' 'start' -64
    Shot $dir '03_result' @((Mk 'tap' (RectNoScroll '#copyBtn') '③ 결과 복사·저장'))
    ScrollTo '#card' 'start' -64
    Shot $dir '04_card' @((Mk 'circle' (RectNoScroll '#ccard') '고객 카드'))
    TapSel '#copyBtn' | Out-Null
    TapSel '#expBtn' | Out-Null; L ('export: ' + (Js 'return JSON.stringify(window.__lastDownload)'))
    $bk = Js 'return VL.exportJSON()'; [IO.File]::WriteAllText((Join-Path $files 'visitlog_backup.json'), $bk, (New-Object Text.UTF8Encoding($false)))
    $n0 = Js 'return String(DB.rec.length)'
    Js 'DB={v:1,rec:[]}; save(); render(); return 1' | Out-Null
    $n1 = Js 'return String(DB.rec.length)'
    $imp = Js ('return String(VL.importJSON(' + (ConvertTo-Json $bk) + '))')
    L ('backup/restore: before=' + $n0 + ' wiped=' + $n1 + ' imported=' + $imp + ' after=' + (Js 'return String(DB.rec.length)') + ' re-import dup=' + (Js ('return String(VL.importJSON(' + (ConvertTo-Json $bk) + '))')))
    Nav 'oneclick\visitlog.html'; L ('persist after reload: ' + (Js 'return String(DB.rec.length)'))
    PrintPdf 'today5' | Out-Null
  }
  'funnel3' {
    Std '#benefit' '#result'
    L ('stages: ' + (Js 'return CUR.map(x=>x.t+" "+x.when+" "+x.b+"B "+x.kind+" ok="+x.ok).join(" | ")') + ' total=' + (Js 'return $("#tBytes").textContent+"B / "+$("#tCost").textContent+"원 / "+$("#tOk").textContent'))
    L ('msg1: ' + (Js 'return CUR[0].body.replace(/\n/g," ⏎ ")'))
    TapSel '#copyBtn' | Out-Null; L ('copy all len=' + (Js 'return String(window.__lastCopy.length)'))
    Js 'const t=document.querySelector("#stages textarea[data-i=\"1\"]"); t.value=t.value.replace("(광고)",""); t.dispatchEvent(new Event("input",{bubbles:true})); return 1' | Out-Null
    L ('after removing (광고) in 2차: ' + (Js 'return $("#c1").textContent') + ' / ' + (Js 'return $("#tOk").textContent'))
    TapSel '#stages button[data-c="1"]' | Out-Null; L ('copy blocked toast: ' + (Js 'return $("#toast").textContent'))
    TapSel '#runBtn' | Out-Null
    L ('send code present: ' + (Js 'return String(/sms:|sendBeacon|XMLHttpRequest|fetch\(/.test(document.documentElement.outerHTML))'))
    PrintPdf 'approve' | Out-Null
  }
  'listing' {
    Std '#ph' '#result' '#printBtn'
    L ('guard: ' + (Js 'return $("#guard").textContent'))
    $p = PrintPdf 'A4'
    L ('print imgs=' + (Js 'return String(document.querySelectorAll("#printArea .grid img").length)') + ' 등기부 문구=' + (Js 'return String(/등기부등본/.test($("#printArea").textContent))'))
    # 개인정보 가드: 담당에 실명, 교환 포인트에 전화번호
    SetVal '#agent' '김철수'; SetVal '#pt3' '자세한 상담은 010-0000-9999 로'; TapSel '#runBtn' | Out-Null
    L ('guard test: ' + (Js 'return $("#guard").textContent') + ' / sheet has phone=' + (Js 'return String(/010-0000-9999/.test($("#pv").textContent))') + ' agent=' + (Js 'return CUR.agent'))
    SetVal '#agent' 'K.T.S'; SetVal '#pt3' '교환 시 차액은 현금·대출 승계로 맞출 수 있음'; TapSel '#runBtn' | Out-Null
    ScrollTo '#result' 'start' -64
    Shot $dir '03_result' @((Mk 'tap' (RectNoScroll '#printBtn') '③ 인쇄 · PDF 저장'))
    # A4 인쇄 레이아웃 그림
    Js '$("#printArea").innerHTML=sheet(CUR); return 1' | Out-Null
    Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 794; height = 1123; deviceScaleFactor = 1; mobile = $false } | Out-Null
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null; Start-Sleep -Milliseconds 500
    $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 794; height = 1123; scale = 1 } }
    [IO.File]::WriteAllBytes((Join-Path $dir 'print_A4.png'), [Convert]::FromBase64String($r['data']))
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
    Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  }
  'docs' {
    Shot $dir '01_press' @((Mk 'tap' (RectNoScroll '#sampleBtn') '① 상황을 누르세요'), (Mk 'circle' (RectNoScroll '.fixnote') '일반 안내 고지'))
    foreach ($k in 'biz', 'corp', 'lease', 'loan', 'close') {
      TapSel ('#sit button[data-k="' + $k + '"]') | Out-Null; Start-Sleep -Milliseconds 200
      L ($k + ': docs=' + (Js 'return String(document.querySelectorAll("#docs .doc").length)') + ' miss=' + (Js 'return String(document.querySelectorAll("#miss .item").length)') + ' order=' + (Js 'return String(document.querySelectorAll("#order tr").length)') + ' links=' + (Js 'return [...document.querySelectorAll("#links a")].map(a=>a.href).join(" ")'))
    }
    TapSel '#sit button[data-k="biz"]' | Out-Null; Start-Sleep -Milliseconds 300
    TapSel '#docs input[data-i="1"]' | Out-Null; TapSel '#docs input[data-i="2"]' | Out-Null
    ScrollTo '#docs' 'start' -120
    Shot $dir '02_input' @((Mk 'tap' (RectNoScroll '#docs input[data-i="2"]') '② 준비한 서류 체크'), (Mk 'circle' (RectNoScroll '#progTxt') '남은 개수'))
    Nav 'oneclick\docs.html'
    TapSel '#sit button[data-k="biz"]' | Out-Null; Start-Sleep -Milliseconds 300
    L ('persist after reload: ' + (Js 'return $("#progTxt").textContent'))
    ScrollTo '#result' 'start' -64
    Shot $dir '03_result' @((Mk 'tap' (RectNoScroll '#printBtn') '③ 오늘 준비물 인쇄'))
    TapSel '#copyBtn' | Out-Null; L ('copy head: ' + (Js 'return window.__lastCopy.split("\n").slice(0,4).join(" | ")'))
    PrintPdf 'biz' | Out-Null
  }
  }
  $l1 = Layout 'end'
  # 결과 화면 전체 길이 검사(스크롤하며 넘침 확인)
  L ('full page height=' + (Invoke-Js 'document.documentElement.scrollHeight') + ' inquiry link=' + (Js 'const a=document.querySelector("#inqLink"); return a? a.getAttribute("href"):"없음"') + ' privacy line=' + (Js 'return String(!!document.querySelector(".privacy") && /이 기기 안에서만 처리/.test(document.querySelector(".privacy").textContent))'))
  L ('external refs: ' + (Js 'return JSON.stringify([...document.querySelectorAll("script[src],link[href],img[src]")].map(e=>e.getAttribute("src")||e.getAttribute("href")).filter(u=>u&&!/^data:|^blob:/.test(u)))'))
  ScrollTo '#inq' 'center'
  Shot $dir '90_inquiry' @((Mk 'tap' (RectNoScroll '#inqLink') '60초 문의'))
  $log += 'errors(now): ' + (Js 'return JSON.stringify(window.__errs)') + ' / before-nav: [' + ($global:ERRS -join ',') + ']'
  $log += 'print calls: ' + (Js 'return String(window.__printed||0)')
  Save-Marks (Join-Path $dir 'marks.json')
  $bad = @($global:MARKS | Where-Object { $_.scrollWidth -ne 390 })
  $log += ("shots=" + $global:MARKS.Count + " overflow(scrollWidth!=390)=" + $bad.Count + " layoutIssues(start/end)=" + $l0.n + "/" + $l1.n)
  $log | Set-Content -Encoding UTF8 (Join-Path $dir 'run_log.txt')
  Copy-Item (Join-Path $dir '03_result.png') (Join-Path $OUT ('390_' + $app + '.png')) -Force
  Write-Output ($log[-3..-1] -join "`n")
} finally { Stop-CdpChrome }

# 독소조항 1초 검토기 실화면 검수·캡처 (390x844 @2x · 실제 탭·타이핑 · 누른 자리 기록)
. "$PSScriptRoot\pmlib.ps1"
$out = AppDir 'riskcheck'; $files = Join-Path $out 'files'
$NM = @{ sale = '매매'; house = '주택임대차'; shop = '상가임대차' }
$log = @()
Open-App 'oneclick\riskcheck.html' 9352
try {
  Shot $out '01_start' @((Mk 'tap' (RectNoScroll '#sampleSeg') '예시 계약서'), (Mk 'circle' (RectNoScroll '#legalTop') '고지 고정 표시'))
  # 직접 타이핑 시험: 조항 2개를 손으로 넣고 자르기·판정 확인
  TapSel '#docText' | Out-Null
  TypeText "제1조(기간) 기간이 끝나기 1개월 전까지 이의를 제기하지 않으면 같은 조건으로 연장된다.`n제2조(해지) 임차인은 중도 해지를 할 수 없다."
  Start-Sleep -Milliseconds 300
  $log += 'typed: info=' + (Invoke-Js "document.querySelector('#clauseInfo').textContent") + ' / review=' + (Js 'const r=RC.review(); return JSON.stringify(r.out.map(o=>o.c.id+":"+["낮음","보통","높음"][o.lv]+":"+o.ids.join("+")))')
  Shot $out '02_typed' @((Mk 'circle' (RectNoScroll '#docText') '조항 붙여넣기'), (Mk 'circle' (RectNoScroll '#clauseInfo') '조항 수'))
  foreach ($t in 'sale', 'house', 'shop') {
    TapSel '#plbls button[data-s="1"]' | Out-Null; Start-Sleep -Milliseconds 300
    $r = TapSel ('#sampleSeg button[data-v="' + $t + '"]'); Start-Sleep -Milliseconds 300
    if ($t -eq 'sale') { ScrollTo '#sampleSeg' 'start' -170; Shot $out ('03_sample_' + $t) @((Mk 'tap' (RectNoScroll ('#sampleSeg button[data-v="' + $t + '"]')) '예시 넣기'), (Mk 'circle' (RectNoScroll '#sideSeg') '내 입장'), (Mk 'circle' (RectNoScroll '#docText') '')) }
    TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
    Shot $out ('04_review_' + $t) @((Mk 'circle' (RectNoScroll '.sumrow') '등급별 개수'), (Mk 'circle' (RectNoScroll '#riskList .rk') '검토표'))
    ScrollTo '#riskList .rk' 'start' -150
    Shot $out ('05_table_' + $t) @((Mk 'circle' (RectNoScroll '#riskList .rk table') '조항·발췌·등급·이유·문구'), (Mk 'tap' (RectNoScroll '#riskList .rk .ck') '수정 요청에 넣기'))
    $log += $t + ' review: ' + (Js 'const r=RC.review(); return JSON.stringify({clauses:r.cls.length, risks:r.out.map(o=>o.c.id+":"+["낮음","보통","높음"][o.lv]+":"+o.ids.join("+")), clean:r.ok})')
    if ($t -eq 'sale') {
      # AI 단추: 열쇠 없음 → 안내만
      TapSel '#aiBtn' | Out-Null; Start-Sleep -Milliseconds 300
      $log += 'ai (no key) toast: ' + (Toast)
      Shot $out '06_ai_nokey' @((Mk 'tap' (RectNoScroll '#aiBtn') 'AI(열쇠 있을 때만)'), (Mk 'circle' (RectNoScroll '#toast') '열쇠 안내'))
      # 체크 해제 시험: 마지막(보통) 조항 빼기
      $before = Js 'return String(RC.reqText().split("\n").filter(l=>/^\d+\)/.test(l)).length)'
      $ck = Rect '#riskList .rk:last-child .ck input'; Tap ($ck.x + $ck.w / 2) ($ck.y + $ck.h / 2); Start-Sleep -Milliseconds 200
      $after = Js 'return String(RC.reqText().split("\n").filter(l=>/^\d+\)/.test(l)).length)'
      $log += "request items: checked all=$before -> after uncheck 1=$after"
      Tap ($ck.x + $ck.w / 2) ($ck.y + $ck.h / 2)
    }
    TapSel '#nextBtn' | Out-Null; Start-Sleep -Milliseconds 400
    if ($t -eq 'sale') {
      Shot $out '07_request' @((Mk 'circle' (RectNoScroll '#reqText') '수정 요청 문구'), (Mk 'tap' (RectNoScroll '#copyBtn') '복사'), (Mk 'tap' (RectNoScroll '#printBtn') '요약 인쇄'))
      TapSel '#copyBtn' | Out-Null; Start-Sleep -Milliseconds 400
      $log += 'copy: ' + (Invoke-Js "document.querySelector('#outInfo').textContent")
      $log += 'request text: ' + ((Invoke-Js "document.querySelector('#reqText').value") -replace "`n", ' / ')
      ScrollTo '#pvWrap' 'start' -170
      Shot $out '08_summary_preview' @((Mk 'circle' (RectNoScroll '#pvWrap') '요약 1장(A4)'))
    }
    TapSel '#printBtn' | Out-Null; Start-Sleep -Milliseconds 600
    $pdf = Join-Path $files ('검토요약_' + $NM[$t] + '.pdf'); Print-Pdf $pdf
    $log += $t + ' summary pdf: ' + (Split-Path $pdf -Leaf) + ' pages=' + (Pages $pdf) + ' / print() called=' + (Js 'return String(window.__printed||0)')
    if ($t -eq 'sale') {
      # 인쇄 레이아웃 캡처(A4 인쇄 폭 210mm − 좌우 여백 24mm ≈ 703px)
      Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 703; height = 1000; deviceScaleFactor = 1; mobile = $false } | Out-Null
      Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null; Start-Sleep -Milliseconds 400
      $h = [int](Invoke-Js "Math.ceil(document.querySelector('#printArea .paper').getBoundingClientRect().height)")
      $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 703; height = $h; scale = 1 } }
      [IO.File]::WriteAllBytes((Join-Path $out 'print_layout_sale.png'), [Convert]::FromBase64String($r['data']))
      Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
      Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
    }
  }
  # contract.html 이 실제로 만든 계약서 본문(샘플 3종)을 그대로 붙여 넣어 검토
  $cap = [IO.File]::ReadAllText((Join-Path $global:PM2 '..\contract_20261118\src\cap_contract.ps1'), [Text.Encoding]::UTF8)
  $br = [regex]::Match($cap, '\$BR = ''(.*?)''').Groups[1].Value
  foreach ($t in 'sale', 'house', 'shop') {
    $m = [regex]::Match($cap, '(?m)^\s*' + $t + '\s*=\s*''(\{.*?)''\s*\+\s*\$BR')
    $json = $m.Groups[1].Value + $br + ',"cp":{"a":1,"b":1,"c":1}}'
    Nav 'oneclick\contract.html'
    Js ('localStorage.setItem("kc_contract_v1", JSON.stringify(' + $json + ')); return 1') | Out-Null
    Nav 'oneclick\contract.html'
    $txt = Js 'const d=document.createElement("div"); d.innerHTML=KC.rawToHtml(KC.buildDoc()); document.body.appendChild(d); const t=[...d.querySelectorAll("p,tr")].map(e=>e.innerText.replace(/\t/g," ").trim()).filter(Boolean).join("\n"); d.remove(); return t'
    [IO.File]::WriteAllText((Join-Path $files ('contract_html_' + $t + '.txt')), $txt, (New-Object Text.UTF8Encoding($false)))
    Nav 'oneclick\riskcheck.html'
    Js ('RC.S.text = ' + (ConvertTo-Json $txt) + '; RC.S.title = "contract.html 샘플(' + $NM[$t] + ')"; RC.S.off = {}; RC.go(2); return 1') | Out-Null
    $log += 'contract.html ' + $t + ': ' + (Js 'const r=RC.review(); return JSON.stringify({clauses:r.cls.length, risks:r.out.map(o=>o.c.id+":"+["낮음","보통","높음"][o.lv]+":"+o.ids.join("+"))})')
    if ($t -eq 'house') { Shot $out '09_contract_html_house' @((Mk 'circle' (RectNoScroll '.sumrow') 'contract.html 계약서 검토')) }
  }
  # 60초 문의
  Js 'RC.go(1); return 1' | Out-Null
  TapSel '#qName' | Out-Null; TypeText '최중개'; TapSel '#qTel' | Out-Null; TypeText '010-1234-5678'; TapSel '#qMsg' | Out-Null; TypeText '프랜차이즈 가맹계약서도 검토되면 좋겠습니다'
  TapSel '#qMake' | Out-Null; Start-Sleep -Milliseconds 200
  ScrollTo '.qa' 'start' -150
  Shot $out '90_inquiry' @((Mk 'tap' (RectNoScroll '#qMake') '답장 초안'), (Mk 'circle' (RectNoScroll '#qDraft') '자동 발송 없음'))
  $log = Finish $out $log
} finally { Stop-CdpChrome }
$log

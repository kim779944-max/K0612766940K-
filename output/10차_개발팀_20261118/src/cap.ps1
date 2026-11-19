# 10차_개발팀_20261118: 390x844 @2x 실화면 검수 + 캡처 3장(① 누르는 곳 ② 입력 ③ 결과) + 기능 검증 로그
# 9차 cap.ps1 구조 재사용 · 앱별 검증식은 checks.ps1
param([string]$app = 'mealplan', [int]$port = 9411)
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
. "$PSScriptRoot\checks.ps1"
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$dir = Join-Path $OUT ("shots\" + $app); New-Item -ItemType Directory -Force $dir | Out-Null
$files = Join-Path $OUT 'files'; New-Item -ItemType Directory -Force $files | Out-Null
$global:MARKS = @(); $global:ERRS = @()
$log = @()
function L([string]$s) { $script:log += $s; Write-Output $s }
function SetVal([string]$sel, [string]$v) { Js ("const e=document.querySelector('" + $sel + "'); e.value=" + (ConvertTo-Json $v) + "; e.dispatchEvent(new Event('input',{bubbles:true})); e.dispatchEvent(new Event('change',{bubbles:true})); return 1") | Out-Null }
function ScrollTo([string]$sel, [string]$block = 'start', [int]$dy = 0) { Invoke-Js ("(()=>{const t=document.querySelector('#toast'); t&&t.classList.remove('on'); const e=document.querySelector('" + $sel + "'); e.scrollIntoView({block:'" + $block + "'}); window.scrollBy(0," + $dy + "); return 1})()") | Out-Null; Start-Sleep -Milliseconds 300 }
$LAYOUT = @'
(()=>{const W=innerWidth,bad=[];document.querySelectorAll('#app *').forEach(e=>{const cs=getComputedStyle(e);if(cs.display==='none'||cs.visibility==='hidden'||e.closest('.hide'))return;if(e.closest('.hscroll'))return;const r=e.getBoundingClientRect();if(!r.width||!r.height)return;
if(r.right>W+0.5||r.left<-0.5)bad.push('OUT '+e.tagName+'.'+e.className+' '+Math.round(r.left)+'~'+Math.round(r.right));
if(!/INPUT|TEXTAREA|SELECT/.test(e.tagName)&&(cs.overflowX==='hidden'||cs.textOverflow==='ellipsis')&&e.scrollWidth>e.clientWidth+1&&!e.closest('.pv'))bad.push('CLIP '+e.tagName+'.'+e.className+' "'+e.textContent.slice(0,24)+'"')});
return JSON.stringify({sw:document.documentElement.scrollWidth,n:bad.length,bad:bad.slice(0,12)})})()
'@
function Layout([string]$when) { $r = Invoke-Js $LAYOUT; L ("layout[" + $when + "]: " + $r); return ($r | ConvertFrom-Json) }
function PrintPdf([string]$name, [string]$btn = '#printBtn') {
  TapSel $btn | Out-Null; Start-Sleep -Milliseconds 500
  $pdf = Join-Path $files ($app + '_' + $name + '.pdf'); Print-Pdf $pdf
  $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pdf)); $pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count
  L ("print " + $name + ": pages=" + $pages + " bytes=" + (Get-Item $pdf).Length + " file=files\" + (Split-Path $pdf -Leaf)); return $pages
}
function Chk([string]$label, [string]$code) { $v = Js $code; L ($label + ': ' + $v) }
$C = $CHECKS[$app]; if (-not $C) { throw "no checks for $app" }
$rel = "oneclick\" + $app + ".html"
Open-App $rel $port
try {
  Js 'localStorage.clear(); return 1' | Out-Null
  Nav $rel
  $l0 = Layout 'start'
  $sample = if ($C.sample) { $C.sample } else { '#sampleBtn' }
  $run = if ($C.run) { $C.run } else { '#runBtn' }
  $res = if ($C.result) { $C.result } else { '#result' }
  $copy = if ($C.copy) { $C.copy } else { '#copyBtn' }
  Shot $dir '01_press' @((Mk 'tap' (RectNoScroll $sample) '① 여기를 누르세요'))
  TapSel $sample | Out-Null; Start-Sleep -Milliseconds 500
  if ($C.afterSample) { & $C.afterSample }
  ScrollTo $run 'end' 40
  Shot $dir '02_input' @((Mk 'circle' (RectNoScroll $C.input) '② 입력 확인'), (Mk 'tap' (RectNoScroll $run) '만들기'))
  TapSel $run | Out-Null; Start-Sleep -Milliseconds 800
  ScrollTo $res 'start' -64
  Shot $dir '03_result' @((Mk 'tap' (RectNoScroll $copy) '③ 결과 복사·저장'))
  L ('taps to result: sample(1) + run(1) = 2')
  foreach ($ck in $C.checks) { Chk $ck[0] $ck[1] }
  if ($C.extra) { & $C.extra }
  if ($C.print -ne $false) { PrintPdf 'print' | Out-Null }
  $l1 = Layout 'end'
  L ('full page height=' + (Invoke-Js 'document.documentElement.scrollHeight') + ' inquiry link=' + (Js 'const a=document.querySelector("#inqLink"); return a? a.getAttribute("href"):"없음"') + ' privacy line=' + (Js 'return String(!!document.querySelector(".privacy") && /이 기기 안에서만 처리/.test(document.querySelector(".privacy").textContent))'))
  L ('external refs: ' + (Js 'return JSON.stringify([...document.querySelectorAll("script[src],link[href],img[src]")].map(e=>e.getAttribute("src")||e.getAttribute("href")).filter(u=>u&&!/^data:|^blob:/.test(u)))'))
  L ('send code present: ' + (Js 'return String(/sms:|mailto:|sendBeacon|XMLHttpRequest|fetch\(/.test(document.documentElement.outerHTML))'))
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

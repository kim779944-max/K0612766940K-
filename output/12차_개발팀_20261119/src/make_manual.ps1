# 상품별 사용설명서 1장(9차 make_manual.ps1 재사용): 390px 실제 캡처 3장 + 실제로 누른 자리(marks.json) 표시
# 출력: output/12차_개발팀_20261119/{앱}_설명서.html + .md (+ 1쪽 확인용 files/{앱}_설명서.pdf)
param([string]$apps = "")
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
. "$PSScriptRoot\manual_data.ps1"
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$C = [ordered]@{}; foreach ($k in $MANUAL.Keys) { if (-not $apps -or ($apps -split ",") -contains $k) { $C[$k] = $MANUAL[$k] } }
Start-CdpChrome 9485 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  foreach ($app in $C.Keys) {
    $d = $C[$app]; $sd = Join-Path $OUT ("shots\" + $app)
    $marks = [IO.File]::ReadAllText((Join-Path $sd 'marks.json'), [Text.Encoding]::UTF8)
    $steps = @(@('01_press', '① 누르는 곳', $d[3]), @('02_input', '② 입력', $d[4]), @('03_result', '③ 결과', $d[5]))
    $stepsJson = ConvertTo-Json -InputObject @($steps | ForEach-Object { , @($_) }) -Depth 4 -Compress
    $html = @"
<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>$($d[0]) 사용설명서</title>
<style>
@page{size:A4;margin:10mm}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"Malgun Gothic","Apple SD Gothic Neo",sans-serif;color:#111;font-size:10pt;line-height:1.5;max-width:760px;margin:0 auto;padding:8px;word-break:keep-all}
.cover{background:#0A1128;color:#fff;border-radius:10px;padding:14px 16px;margin-bottom:10px}
.cover h1{font-size:17pt;letter-spacing:-.8px}.cover h1 small{font-size:9.5pt;color:#FFA24D;margin-left:6px}
.cover p{color:#C9D3E3;margin-top:6px;font-size:9.5pt}
.legend{display:flex;gap:16px;font-size:9pt;color:#444;margin:0 0 8px}
.steps{display:flex;gap:10px}
.st{flex:1;min-width:0}
.st h2{font-size:12pt;color:#0A1128;border-left:4px solid #FF6B00;padding-left:7px;margin-bottom:5px}
.shot{position:relative;width:100%;border-radius:12px;overflow:hidden;border:2px solid #0A1128}
.shot img{display:block;width:100%}
.st p{font-size:9.4pt;color:#333;margin-top:6px}
.ring{position:absolute;border:3px solid #FF6B00;border-radius:10px;box-shadow:0 0 0 2px rgba(255,255,255,.85);margin:-3px 0 0 -3px;padding:3px;box-sizing:content-box}
.tap{position:absolute;width:28px;height:28px;margin:-14px 0 0 -14px;border-radius:50%;background:rgba(255,107,0,.35);border:3px solid #FF6B00}
.fing{position:absolute;width:26px;height:32px;margin:2px 0 0 -4px}
.lbl{position:absolute;font-size:7.5pt;font-weight:700;color:#fff;background:#FF6B00;border-radius:4px;padding:0 4px;white-space:nowrap}
.foot{font-size:8.5pt;color:#666;margin-top:8px;border-top:1px solid #ddd;padding-top:6px}
</style></head><body>
<div class="cover"><h1>$($d[0]) 사용설명서<small>oneclick/$($d[1])</small></h1><p>$($d[2])</p></div>
<div class="legend"><span>● 주황 원 + 손가락 = 여기를 누르세요</span><span>□ 주황 테두리 = 여기를 보세요</span><span>화면은 390px 휴대폰 실제 캡처</span></div>
<div class="steps" id="list"></div>
<p class="foot">KTS 원클릭 · 입력하신 내용은 이 기기 안에서만 처리됩니다 · 서버 0 · 외부 발송 0 · 화면 맨 아래 [60초 문의 폼 열기]로 이름·연락처·문의를 남길 수 있습니다.</p>
<script>
const MARKS = $marks;
const STEPS = $stepsJson;
const fing = '<svg class="fing" viewBox="0 0 30 36"><path d="M9 3c1.7 0 3 1.3 3 3v10l1-.2V12c0-1.6 1.3-2.8 2.8-2.8S18.6 10.4 18.6 12v4l.8-.1c1.5 0 2.7 1.2 2.7 2.7v1l.6-.1c1.5 0 2.8 1.2 2.8 2.8V26c0 4.4-3.6 8-8 8h-3.3c-2.6 0-5-1.3-6.4-3.4L3.3 24c-.9-1.3-.6-3 .7-3.9 1.2-.8 2.8-.6 3.7.5L6 21V6c0-1.7 1.3-3 3-3z" fill="#fff" stroke="#0A1128" stroke-width="1.6"/></svg>';
const byShot = {}; (Array.isArray(MARKS) ? MARKS : [MARKS]).forEach(m => byShot[m.shot] = m.marks || []);
document.getElementById('list').innerHTML = STEPS.map(([shot, h, p]) => '<div class="st"><h2>' + h + '</h2><div class="shot" data-s="' + shot + '"><img src="shots/$app/' + shot + '.png"></div><p>' + p + '</p></div>').join('');
function draw(){ document.querySelectorAll('.shot').forEach(el => {
  const X = v => (v / 390 * 100).toFixed(2) + '%', Y = v => (v / 844 * 100).toFixed(2) + '%'; let ov = '';
  (byShot[el.dataset.s] || []).forEach(m => {
    if (!m || m.y > 844 || m.y + m.h < 0) return;
    if (m.kind === 'tap'){ const cx = X(m.x + m.w / 2), cy = Y(m.y + m.h / 2); ov += '<div class="tap" style="left:' + cx + ';top:' + cy + '"></div><div style="position:absolute;left:' + cx + ';top:' + cy + '">' + fing + '</div>'; }
    else { const y0 = Math.max(0, m.y), y1 = Math.min(844, m.y + m.h); ov += '<div class="ring" style="left:' + X(m.x) + ';top:' + Y(y0) + ';width:' + X(m.w) + ';height:' + Y(y1 - y0) + '"></div>'; }
    if (m.note) ov += '<div class="lbl" style="left:' + X(Math.max(2, Math.min(300, m.x))) + ';top:calc(' + Y(Math.max(0, m.y)) + ' - 15px)">' + m.note + '</div>';
  });
  el.querySelectorAll('.ov').forEach(x => x.remove()); const d = document.createElement('div'); d.className = 'ov'; d.innerHTML = ov; el.appendChild(d); }); }
window.addEventListener('load', draw);
</script></body></html>
"@
    $hp = Join-Path $OUT ($app + '_설명서.html')
    [IO.File]::WriteAllText($hp, $html, (New-Object Text.UTF8Encoding($false)))
    $md = @"
# $($d[0]) 사용설명서

- 앱: ``oneclick/$($d[1])`` (단일 HTML · 설치 없음 · 서버 0)
- $($d[2])
- 입력하신 내용은 이 기기 안에서만 처리됩니다.

## ① 누르는 곳
![① 누르는 곳](shots/$app/01_press.png)

$($d[3])

## ② 입력
![② 입력](shots/$app/02_input.png)

$($d[4])

## ③ 결과
![③ 결과](shots/$app/03_result.png)

$($d[5])

## 60초 문의
화면 맨 아래 **[60초 문의 폼 열기]** 를 누르면 KTS 60초 접수 폼(``misa-1116/form.html``)이 열립니다. 이름·연락처·문의만 남기면 됩니다.

> 390px 실물 캡처: ``390_$app.png`` · 실제로 누른 자리 기록: ``shots/$app/marks.json`` · 검증 로그: ``shots/$app/run_log.txt``
"@
    [IO.File]::WriteAllText((Join-Path $OUT ($app + '_설명서.md')), $md, (New-Object Text.UTF8Encoding($false)))
    Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $hp) } | Out-Null; Start-Sleep -Milliseconds 1800
    $broken = Invoke-Js "JSON.stringify([...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.getAttribute('src')))"
    $nm = Invoke-Js "String(document.querySelectorAll('.tap,.ring').length)"
    $r = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true }
    $pdf = Join-Path $OUT ("files\" + $app + "_설명서.pdf"); [IO.File]::WriteAllBytes($pdf, [Convert]::FromBase64String($r['data']))
    $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pdf)); $pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count
    Write-Output ($app + " manual: pages=" + $pages + " marks=" + $nm + " brokenImages=" + $broken)
  }
} finally { Stop-CdpChrome }

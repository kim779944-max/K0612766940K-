# consult.html → PNG 배경 8장(+기본 2장) · PDF 4개 · 390px 미리보기 4장 · 실측 JSON
# 다시 돌리면 같은 결과: powershell -NoProfile -ExecutionPolicy Bypass -File src\cap.ps1
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$RAW = Join-Path $OUT '측정_원자료'; New-Item -ItemType Directory -Force $RAW | Out-Null
$HTML = Join-Path $OUT 'consult.html'
$MJS = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'measure.js'))
$THEMES = 'mono', 'sky', 'green', 'gray'
$GUARD = "window.__errs=[];addEventListener('error',function(e){var t=e.target;__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);addEventListener('unhandledrejection',function(e){__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});(function(){var ce=console.error;console.error=function(){__errs.push('CONSOLE '+[].join.call(arguments,' '));return ce.apply(console,arguments)}})();window.print=function(){};"
function Go([string]$q) {
  Send-Cdp 'Page.navigate' @{ url = ((To-FileUrl $HTML) + $q) } | Out-Null
  Start-Sleep -Milliseconds 1200
  Invoke-Js "document.fonts.ready.then(()=>1)" -await | Out-Null
}
function Res() { return (Invoke-Js "JSON.stringify(performance.getEntriesByType('resource').map(e=>e.name))") }
$log = @()
Start-CdpChrome 9583 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = $GUARD } | Out-Null
  # ---------- 1) 데스크톱 캡처 모드: PNG·PDF·실측 ----------
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 1000; height = 2400; deviceScaleFactor = 1; mobile = $false } | Out-Null
  foreach ($t in $THEMES) {
    Go "?cap=1&theme=$t"
    $j = Invoke-Js $MJS; [IO.File]::WriteAllText((Join-Path $RAW "screen_$t.json"), $j, [Text.Encoding]::UTF8)
    $o = $j | ConvertFrom-Json
    $i = 0
    foreach ($p in $o.pages) {
      $i++
      $clip = @{ x = [double]$p.left; y = [double]$p.top; width = [double]$p.w; height = [double](2105 / $o.S); scale = [double]$o.S }
      $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; clip = $clip; captureBeyondViewport = $true }
      [IO.File]::WriteAllBytes((Join-Path $OUT "tpl_consult_p${i}_$t.png"), [Convert]::FromBase64String($r['data']))
    }
    # 인쇄 매체로 바꿔 같은 실측(화면=인쇄 위치 대조) 후 PDF
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null
    $jp = Invoke-Js $MJS; [IO.File]::WriteAllText((Join-Path $RAW "print_$t.json"), $jp, [Text.Encoding]::UTF8)
    $pdf = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true; marginTop = 0; marginBottom = 0; marginLeft = 0; marginRight = 0 }
    [IO.File]::WriteAllBytes((Join-Path $OUT "컨설팅_약정서_$t.pdf"), [Convert]::FromBase64String($pdf['data']))
    # 위치 대조용: 색을 모두 검정·흰색으로 중화해 다시 찍음(테마가 색만 바꾸는지 픽셀로 확인)
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
    Invoke-Js "(()=>{const s=document.createElement('style');s.id='neutral';s.textContent='#sheets *{color:#000!important;background:#fff!important;border-color:#000!important}';document.head.appendChild(s);return 1})()" | Out-Null
    $i = 0
    foreach ($p in $o.pages) { $i++; $clip = @{ x = [double]$p.left; y = [double]$p.top; width = [double]$p.w; height = [double](2105 / $o.S); scale = [double]$o.S }
      $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; clip = $clip; captureBeyondViewport = $true }
      [IO.File]::WriteAllBytes((Join-Path $RAW "neutral_p${i}_$t.png"), [Convert]::FromBase64String($r['data'])) }
    Invoke-Js "(()=>{document.getElementById('neutral').remove();return 1})()" | Out-Null
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
    $log += "screen $t errs=" + (Invoke-Js "JSON.stringify(window.__errs)") + " res=" + (Res)
  }
  # 기본(테마 없는 이름) = 하늘색 사본
  Copy-Item (Join-Path $OUT 'tpl_consult_p1_sky.png') (Join-Path $OUT 'tpl_consult_p1.png') -Force
  Copy-Item (Join-Path $OUT 'tpl_consult_p2_sky.png') (Join-Path $OUT 'tpl_consult_p2.png') -Force
  # ---------- 2) 폰 390px: 도구줄 + 칩으로 테마 전환 ----------
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Go ""
  foreach ($t in $THEMES) {
    Invoke-Js "(()=>{document.querySelector('.chip[data-t=$t]').click();window.scrollTo(0,0);return 1})()" | Out-Null
    Start-Sleep -Milliseconds 400
    $j = Invoke-Js $MJS; [IO.File]::WriteAllText((Join-Path $RAW "m390_$t.json"), $j, [Text.Encoding]::UTF8)
    $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }
    [IO.File]::WriteAllBytes((Join-Path $OUT "390_$t.png"), [Convert]::FromBase64String($r['data']))
    $log += "m390 $t theme=" + (Invoke-Js "document.body.dataset.theme") + " zoom=" + (Invoke-Js "document.getElementById('sheets').style.zoom") + " scrollW=" + (Invoke-Js "document.documentElement.scrollWidth") + " clientW=" + (Invoke-Js "document.documentElement.clientWidth") + " errs=" + (Invoke-Js "JSON.stringify(window.__errs)") + " res=" + (Res)
  }
} finally { Stop-CdpChrome }
$log | Set-Content -Encoding UTF8 (Join-Path $RAW 'cap_log.txt')
$log

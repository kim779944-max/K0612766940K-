# 더뷰 v1.4 앱 자산 검수 — 헤드리스 크롬 390x844 (CDP). 앱 자산 폴더가 없으므로 임시 폴더에 viewer.html 만 두고 연다.
. "$PSScriptRoot\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$OUT = $PSScriptRoot
$K = (Resolve-Path "$PSScriptRoot\..\..").Path
$T = Join-Path $env:TEMP 'viewer_v14_check'; if (Test-Path $T) { Remove-Item -Recurse -Force $T }; New-Item -ItemType Directory $T | Out-Null
Copy-Item "$OUT\assets\viewer.html" $T
[IO.File]::WriteAllBytes((Join-Path $T 'dummy.hwp'), [byte[]](0xD0,0xCF,0x11,0xE0,0xA1,0xB1,0x1A,0xE1) + (New-Object byte[] 504))
$log = @(); function L($s) { $script:log += $s; Write-Output $s }
function Js([string]$code) { return Invoke-Js ("(async()=>{ " + $code + " })()") -await }
Start-CdpChrome 9531 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null; Send-Cdp 'DOM.enable' | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href).split('/').pop()):('JS '+e.message))},true);window.addEventListener('unhandledrejection',function(e){window.__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});" } | Out-Null
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl (Join-Path $T 'viewer.html')) } | Out-Null; Start-Sleep -Milliseconds 3000
  L ("title: " + (Js 'return document.title'))
  L ("load errors: " + (Js 'return JSON.stringify(window.__errs)'))
  L ("requests (resource timing, non-file): " + (Js 'return JSON.stringify(performance.getEntriesByType("resource").map(e=>e.name).filter(u=>!/^file:|^data:|^blob:/.test(u)))'))
  L ("cdnjs in <script src>/<link>: " + (Js 'return JSON.stringify([...document.querySelectorAll("script[src],link[href]")].map(e=>e.getAttribute("src")||e.getAttribute("href")).filter(u=>/^https?:/.test(u)))'))
  L ("390 sw(home): " + (Js 'return String(document.documentElement.scrollWidth)'))
  $files = @(
    @('xlsx', "$K\output\pm2\expense\files\지출결의서_출장.xlsx"),
    @('hwpx', "$K\output\contract_20261118\files\매매계약서_샘플.hwpx"),
    @('img',  "$K\output\교환계약서_20261120\after_tpl_exchange.png"),
    @('pdf',  "$K\output\교환계약서_20261120\after_print_12줄.pdf"),
    @('hwp(더미)', (Join-Path $T 'dummy.hwp')))
  foreach ($f in $files) {
    Js 'window.__errs=[]; return 1' | Out-Null
    $doc = Send-Cdp 'DOM.getDocument' @{ depth = 0 }
    $n = Send-Cdp 'DOM.querySelector' @{ nodeId = $doc['root']['nodeId']; selector = '#f' }
    Send-Cdp 'DOM.setFileInputFiles' @{ nodeId = $n['nodeId']; files = @($f[1]) } | Out-Null
    Start-Sleep -Milliseconds 4000
    $r = Js 'const o=document.getElementById("out"); return JSON.stringify({kind:(typeof PP!=="undefined"?PP.kind:"?"), pages:(typeof PP!=="undefined"&&PP.pages?PP.pages.length:0), meta:(document.getElementById("fmeta")||{}).textContent, outText:o?o.innerText.replace(/\s+/g," ").slice(0,90):"", sw:document.documentElement.scrollWidth, errs:window.__errs})'
    L ("open " + $f[0] + ": " + $r)
    $s = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }; [IO.File]::WriteAllBytes((Join-Path $OUT ('check_' + ($f[0] -replace '[^a-z]','') + '.png')), [Convert]::FromBase64String($s['data']))
  }
} finally { Stop-CdpChrome }
$log | Set-Content -Encoding UTF8 (Join-Path $OUT 'verify_asset_log.txt')

# /ops/ 상황판 390px 캡처 — 로컬 HTTP(HttpListener, 별도 프로세스)로 oneclick 폴더를 열어 status.json fetch·렌더 확인
# (로컬 렌더 확인용: 시험 브라우저에서 PIN 게이트 덮개(#gate)만 숨기고 페이지의 [새로고침] 버튼으로 load() 실행 — 비밀번호를 쓰거나 기록하지 않음)
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$OC = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$port = 8733
$srv = Join-Path $env:TEMP 'ops_srv.ps1'
@'
param($root, $port)
$l = New-Object Net.HttpListener; $l.Prefixes.Add("http://127.0.0.1:$port/"); $l.Start()
$types = @{ '.html'='text/html; charset=utf-8'; '.json'='application/json; charset=utf-8'; '.js'='application/javascript; charset=utf-8'; '.png'='image/png'; '.css'='text/css'; '.svg'='image/svg+xml'; '.jpg'='image/jpeg' }
while ($true) {
  $c = $l.GetContext(); $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath.TrimStart('/'))
  if ($p -eq '' -or $p.EndsWith('/')) { $p += 'index.html' }
  $f = Join-Path $root ($p -replace '/', '\')
  if (Test-Path $f -PathType Leaf) { $b = [IO.File]::ReadAllBytes($f); $ext = [IO.Path]::GetExtension($f); $c.Response.ContentType = $(if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }); $c.Response.OutputStream.Write($b, 0, $b.Length) }
  else { $c.Response.StatusCode = 404 }
  $c.Response.Close()
}
'@ | Set-Content -Encoding UTF8 $srv
$proc = Start-Process powershell -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $srv, "`"$OC`"", $port) -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 2000
Start-CdpChrome 9573 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];addEventListener('error',function(e){var t=e.target;__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);addEventListener('unhandledrejection',function(e){__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});" } | Out-Null
  Send-Cdp 'Page.navigate' @{ url = "http://127.0.0.1:$port/ops/" } | Out-Null; Start-Sleep -Milliseconds 3000
  Invoke-Js "(()=>{document.querySelector('#gate').classList.add('off'); document.querySelector('#btnReload').click(); return 1})()" | Out-Null
  Start-Sleep -Milliseconds 2500
  $r = Invoke-Js @'
(()=>{const all=[...document.querySelectorAll('*')];const pcEl=all.filter(e=>e.children.length<=3&&/PC 클로드 코드팀/.test(e.textContent)).pop();
const card=pcEl?pcEl.closest('[class*=dep],[class*=card],button,article,li,section')||pcEl:null; if(card) card.scrollIntoView({block:'center'});
return JSON.stringify({sw:document.documentElement.scrollWidth, pcCard:!!card, pcText:card?card.innerText.replace(/\s+/g,' ').slice(0,200):'', blkDots:document.querySelectorAll('.blk').length, oldBlockedText:/절전/.test(document.body.innerText), stamp:(document.querySelector('#stamp')||{}).textContent, errs:window.__errs})})()
'@
  Start-Sleep -Milliseconds 500
  $png = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }; [IO.File]::WriteAllBytes((Join-Path $OUT 'ops_390.png'), [Convert]::FromBase64String($png['data']))
  "ops: " + $r
  $r | Set-Content -Encoding UTF8 (Join-Path $OUT 'ops_390_log.txt')
} finally { Stop-CdpChrome; try { Stop-Process -Id $proc.Id -Force } catch {} }

# apply.ps1 시험 — %TEMP% 에 라이브 oneclick HEAD 를 clone 해서만 실행(실서비스 저장소는 읽기만)
#  A) -WhatIf → 아무것도 안 바뀜   B) 실제 적용 → 30개 복사 · products.js +N/−1 · count == products · 쇼룸 타일 10 · 깨진 그림 0 · 상세 정상
#  C) 미커밋 상태에서 재실행 → 멈춤   D) 커밋 후 재실행 → 추가 0건(멱등)
#  E) 기존 5종 패키지를 먼저 적용한 저장소 → 나머지 5종만   F) -Exclude themenu → 9종
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$PKG = (Resolve-Path "$PSScriptRoot\..").Path
$LIVE = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$APPLY = Join-Path $PKG 'apply.ps1'
$T = Join-Path $env:TEMP 'mig10_dry'; if (Test-Path $T) { Remove-Item -Recurse -Force $T }; New-Item -ItemType Directory $T | Out-Null
$out = @(); function L($s) { $script:out += $s; Write-Output $s }
function Clone([string]$name) { $d = Join-Path $T $name; git clone -q $LIVE $d 2>&1 | Out-Null; git -C $d config user.name test; git -C $d config user.email test@example.invalid; return $d }
function Apply([string]$oc, [string[]]$more = @()) { $r = & powershell -NoProfile -ExecutionPolicy Bypass -File $APPLY -OC $oc @more 2>&1 | Out-String; return @{ text = $r; code = $LASTEXITCODE } }
$SL = @('swapcheck', 'rights1p', 'yieldcalc', 'pricegap', 'notice', 'bidcompare', 'balju', 'ledger', 'tagmaker', 'themenu')

L ("라이브 oneclick: " + $LIVE + " HEAD " + (git -C $LIVE rev-parse --short HEAD) + " · status --short: [" + ((git -C $LIVE status --short) -join ';') + "]")
$A = Clone 'a'
L '== A) -WhatIf'
$r = Apply $A @('-WhatIf'); L $r.text.TrimEnd()
L ("A 결과: 종료코드 " + $r.code + " · 시험 사본 status --short 줄 수 " + @(git -C $A status --short).Count + " (0 이어야 함)")

L '== B) 실제 적용'
$r = Apply $A; L $r.text.TrimEnd()
$st = @(git -C $A status --short -uall)
$news = @($st | Where-Object { $_ -like '`?`?*' }); $mods = @($st | Where-Object { $_ -like ' M*' })
L ("B status: 새 파일 " + $news.Count + " · 수정 " + $mods.Count + " (" + (($mods | ForEach-Object { $_.Trim() }) -join ', ') + ")")
L ("B diff --numstat: " + ((git -C $A diff --numstat) -join ' | '))
$pd = git -C $A diff -U0 products.js | Out-String
$minus = @($pd -split "`n" | Where-Object { $_ -match '^-[^-]' })
L ("B products.js 지운 줄: " + $minus.Count + " → " + ($minus -join ' / ').Trim())
$man = @((Get-Content -Raw -Encoding UTF8 (Join-Path $PKG 'copy_manifest.json') | ConvertFrom-Json) | ForEach-Object { $_ })
$ok = @($man | Where-Object { Test-Path (Join-Path $A $_.to) }).Count
L ("B copy_manifest 30줄 Test-Path: " + $ok + "/" + @($man).Count)
$cat = Get-Content -Raw -Encoding UTF8 (Join-Path $A 'catalog.json') | ConvertFrom-Json
L ("B catalog.json: count " + $cat.count + " · products " + @($cat.products).Count + " · 같음 " + ($cat.count -eq @($cat.products).Count))
$links = 0; $left = 0; foreach ($s in $SL) { $h = [IO.File]::ReadAllText((Join-Path $A "$s.html"), [Text.Encoding]::UTF8); $links += ([regex]::Matches($h, [regex]::Escape('https://autooneclick.com/#reserve'))).Count; $left += ([regex]::Matches($h, [regex]::Escape('../misa-1116/form.html'))).Count }
L ("B 문의 링크: 새 주소 " + $links + "곳 · 옛 주소 남음 " + $left + "곳")

# 쇼룸·상세 — 로컬 http 서버(catalog.json fetch 가 실제처럼 동작)
$srv = Start-Process powershell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + (Join-Path $PSScriptRoot 'serve.ps1') + '"'), '-Root', ('"' + $A + '"'), '-Port', '8765' -PassThru -WindowStyle Hidden
Start-Sleep 2
Start-CdpChrome 9581 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);" } | Out-Null
  Send-Cdp 'Page.navigate' @{ url = 'http://localhost:8765/index.html' } | Out-Null; Start-Sleep 4
  $js = "(async()=>{const SL=" + (ConvertTo-Json $SL -Compress) + ";const norm=u=>String(u||'').split('?')[0];" + @'
document.querySelectorAll('img').forEach(i=>i.loading='eager'); window.scrollTo(0,document.body.scrollHeight); await new Promise(r=>setTimeout(r,2500));
const tiles=[...document.querySelectorAll('#tiles a.tile')]; const mine=tiles.filter(a=>SL.includes(norm(a.getAttribute('href')).replace('.html','')));
const imgs=[...document.querySelectorAll('img')]; await Promise.all(imgs.map(i=>i.complete?1:new Promise(r=>{i.onload=i.onerror=r})));
const broken=imgs.filter(i=>!i.naturalWidth).map(i=>i.getAttribute('src'));
return JSON.stringify({source:window.KTS_CATALOG&&window.KTS_CATALOG.source, products:window.PRODUCTS.length, tilesAll:tiles.length, tilesNew:mine.length, newHrefs:mine.map(a=>a.getAttribute('href')), plistRows:document.querySelectorAll('#plist .prow').length, imgs:imgs.length, broken, errs:window.__errs})})()
'@
  L ("B 쇼룸(index.html, http): " + (Invoke-Js $js -await))
  Save-Screenshot (Join-Path $T 'index_after.png')
  foreach ($s in $SL) {
    Send-Cdp 'Page.navigate' @{ url = "http://localhost:8765/detail.html?k=$s" } | Out-Null; Start-Sleep -Milliseconds 1800
    $d = Invoke-Js "(async()=>{const im=[...document.querySelectorAll('img')]; im.forEach(i=>i.loading='eager'); await Promise.all(im.map(i=>i.complete?1:new Promise(r=>{i.onload=i.onerror=r}))); const z=document.querySelector('.zimg'); return JSON.stringify({title:document.title, missing:!!document.querySelector('.missing'), shot:z?z.getAttribute('src')+' '+z.naturalWidth+'x'+z.naturalHeight:'없음', broken:im.filter(i=>!i.naturalWidth).map(i=>i.getAttribute('src')), errs:window.__errs})})()" -await
    L ("B 상세 detail.html?k=" + $s + ": " + $d)
  }
} finally { Stop-CdpChrome; try { Invoke-WebRequest 'http://localhost:8765/__stop' -UseBasicParsing -TimeoutSec 3 | Out-Null } catch {}; Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue }

L '== C) 커밋 안 한 채로 다시 실행 → 멈춰야 함'
$r = Apply $A; L $r.text.TrimEnd(); L ("C 종료코드 " + $r.code)
L '== D) 커밋 후 다시 실행 → 추가 0건'
git -C $A add -A; git -C $A commit -q -m 'apply 1회차'
$r = Apply $A; L $r.text.TrimEnd()
L ("D 2회차 뒤 status --short 줄 수: " + @(git -C $A status --short).Count)

L '== E) 기존 5종 패키지(output/100선_이관_20261120/apply.ps1)를 먼저 적용한 저장소'
$E = Clone 'e'
$r0 = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PKG '..\100선_이관_20261120\apply.ps1') -OC $E 2>&1 | Out-String
L ("기존 5종 apply 마지막 줄: " + (($r0.Trim() -split "`n") | Select-String 'products.js|catalog.json' | ForEach-Object { $_.Line.Trim() }) -join ' / ')
git -C $E add -A; git -C $E commit -q -m 'old 5'
$r = Apply $E; L $r.text.TrimEnd()
$ce = Get-Content -Raw -Encoding UTF8 (Join-Path $E 'catalog.json') | ConvertFrom-Json
L ("E catalog.json count " + $ce.count + " · products " + @($ce.products).Count + " · k 중복 " + @($ce.products | Group-Object k | Where-Object Count -gt 1).Count)

L '== F) -Exclude themenu (9종 패키지)'
$F = Clone 'f'
$r = Apply $F @('-Exclude', 'themenu'); L $r.text.TrimEnd()
L ("F themenu.html 생김: " + (Test-Path (Join-Path $F 'themenu.html')))

L '== 실서비스 저장소 변경 확인'
L ("git -C oneclick status --short: [" + ((git -C $LIVE status --short) -join ';') + "] · HEAD " + (git -C $LIVE rev-parse --short HEAD))
$out | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'dryrun_log.txt')

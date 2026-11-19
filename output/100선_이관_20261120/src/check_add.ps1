# products_추가분.js 문법 검사(<script src>로 읽기 — eval 없음) + 기존 키 중복 + catalog_추가분.json 생성
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$PKG = (Resolve-Path "$PSScriptRoot\..").Path
$OC = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$T = Join-Path $env:TEMP 'mig5_check'; if (Test-Path $T) { Remove-Item -Recurse -Force $T }; New-Item -ItemType Directory $T | Out-Null
Copy-Item (Join-Path $PKG 'products_추가분.js') (Join-Path $T 'add.js')
Copy-Item (Join-Path $OC 'products.js') (Join-Path $T 'products.js')
$html = '<!doctype html><meta charset="utf-8"><script>window.__errs=[];addEventListener("error",e=>__errs.push(e.message||("LOAD "+(e.target&&e.target.src))),true)</script><script src="products.js"></script><script src="add.js"></script>'
[IO.File]::WriteAllText((Join-Path $T 'c.html'), $html, (New-Object Text.UTF8Encoding $false))
Start-CdpChrome 9551 | Out-Null
try {
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl (Join-Path $T 'c.html')) } | Out-Null; Start-Sleep -Milliseconds 1500
  "syntax errors: " + (Invoke-Js 'JSON.stringify(window.__errs)')
  "add count: " + (Invoke-Js 'String((window.KTS_PRODUCTS_ADD_20261120||[]).length)')
  "existing keys: " + (Invoke-Js 'window.PRODUCTS.map(p=>p.k).join(",")')
  "dup keys: " + (Invoke-Js 'JSON.stringify(window.KTS_PRODUCTS_ADD_20261120.map(p=>p.k).filter(k=>window.PRODUCTS.some(p=>p.k===k)))')
  "key sets equal to existing format: " + (Invoke-Js 'const need=Object.keys(window.PRODUCTS.find(p=>p.k==="photo2doc")).sort().join(","); JSON.stringify(window.KTS_PRODUCTS_ADD_20261120.map(p=>p.k+":"+(Object.keys(p).sort().join(",")===need)))')
  $json = Invoke-Js 'JSON.stringify({note:"실서비스 catalog.json 의 products 배열 맨 끝에 아래 5개를 붙이고, count 를 19 → 24 로 올립니다(apply.ps1 이 자동으로 함). 형식은 기존 catalog.json 항목과 같습니다.", count_change:{from:19,to:24,how:"catalog.json 의 \"count\": 19 를 \"count\": 24 로 바꾼다 (= products 배열 길이)"}, products:window.KTS_PRODUCTS_ADD_20261120}, null, 1)'
  [IO.File]::WriteAllText((Join-Path $PKG 'catalog_추가분.json'), $json + "`n", (New-Object Text.UTF8Encoding $false))
  "catalog_추가분.json written: " + $json.Length + " chars"
} finally { Stop-CdpChrome }

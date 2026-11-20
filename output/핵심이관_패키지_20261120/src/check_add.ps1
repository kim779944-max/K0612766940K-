# products_추가분.js 문법 검사(<script src>로 읽기 — eval 없음) + 라이브 키 중복 + 키 구성 비교 + catalog_추가분.json 생성·형식 비교
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$PKG = (Resolve-Path "$PSScriptRoot\..").Path
$OC = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$T = Join-Path $env:TEMP 'mig10_check'; if (Test-Path $T) { Remove-Item -Recurse -Force $T }; New-Item -ItemType Directory $T | Out-Null
Copy-Item (Join-Path $PKG 'products_추가분.js') (Join-Path $T 'add.js')
Copy-Item (Join-Path $OC 'products.js') (Join-Path $T 'products.js')
$live = [IO.File]::ReadAllText((Join-Path $OC 'catalog.json'), [Text.Encoding]::UTF8)
[IO.File]::WriteAllText((Join-Path $T 'catalog.js'), 'window.LIVE_CATALOG = ' + $live + ';', (New-Object Text.UTF8Encoding $false))
$html = '<!doctype html><meta charset="utf-8"><script>window.__errs=[];addEventListener("error",e=>__errs.push(e.message||("LOAD "+(e.target&&e.target.src))),true)</script><script src="products.js"></script><script src="catalog.js"></script><script src="add.js"></script>'
[IO.File]::WriteAllText((Join-Path $T 'c.html'), $html, (New-Object Text.UTF8Encoding $false))
$out = @(); function L($s) { $script:out += $s; Write-Output $s }
Start-CdpChrome 9563 | Out-Null
try {
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl (Join-Path $T 'c.html')) } | Out-Null; Start-Sleep -Milliseconds 1500
  $A = 'window.KTS_PRODUCTS_ADD_20261120_TOP10'
  L ("live oneclick HEAD: " + (git -C $OC rev-parse --short HEAD) + " · status --short: [" + ((git -C $OC status --short) -join ';') + "]")
  L ("syntax errors: " + (Invoke-Js 'JSON.stringify(window.__errs)'))
  L ("add count: " + (Invoke-Js "String(($A||[]).length)"))
  L ("add keys: " + (Invoke-Js "$A.map(p=>p.k).join(',')"))
  L ("live products.js keys (" + (Invoke-Js 'String(window.PRODUCTS.length)') + "): " + (Invoke-Js 'window.PRODUCTS.map(p=>p.k).join(",")'))
  L ("live catalog.json keys (count " + (Invoke-Js 'String(LIVE_CATALOG.count)') + " · products " + (Invoke-Js 'String(LIVE_CATALOG.products.length)') + "): " + (Invoke-Js 'LIVE_CATALOG.products.map(p=>p.k).join(",")'))
  L ("dup keys vs products.js: " + (Invoke-Js "JSON.stringify($A.map(p=>p.k).filter(k=>window.PRODUCTS.some(p=>p.k===k)))"))
  L ("dup keys vs catalog.json: " + (Invoke-Js "JSON.stringify($A.map(p=>p.k).filter(k=>LIVE_CATALOG.products.some(p=>p.k===k)))"))
  L ("dup links vs live: " + (Invoke-Js "JSON.stringify($A.map(p=>p.link).filter(l=>LIVE_CATALOG.products.some(p=>p.link===l)))"))
  L ("key sets equal to existing products.js item (photo2doc): " + (Invoke-Js "const need=Object.keys(window.PRODUCTS.find(p=>p.k==='photo2doc')).sort().join(','); const r=$A.map(p=>Object.keys(p).sort().join(',')===need); r.filter(Boolean).length+'/'+r.length+' '+JSON.stringify($A.map((p,i)=>p.k+':'+r[i]))"))
  L ("prices: " + (Invoke-Js "$A.map(p=>p.k+'='+p.price).join(', ')"))
  $json = Invoke-Js ("JSON.stringify({note:'실서비스 catalog.json 의 products 배열 맨 끝에 아래 항목 중 아직 없는 k 만 붙입니다(apply.ps1 이 자동으로 함). 형식은 기존 catalog.json 항목과 같습니다.', count_rule:{how:'count 는 고정 값을 쓰지 않습니다. 붙인 뒤 catalog.json 의 products 배열 길이를 세어 count = products.Count 로 다시 씁니다.', why:'기존 5종 패키지를 먼저 적용했든 아니든, 9종·8종으로 줄였든 count 가 항상 실제 개수와 같게 하려고', example:'라이브 19개 + 이번 10종 = 29 · 기존 5종이 이미 들어가 있으면 24 + 나머지 5종 = 29'}, products:$A}, null, 1)")
  [IO.File]::WriteAllText((Join-Path $PKG 'catalog_추가분.json'), $json + "`n", (New-Object Text.UTF8Encoding $false))
  L ("catalog_추가분.json written: " + $json.Length + " chars")
  $ca = $json | ConvertFrom-Json
  $need = @(($live | ConvertFrom-Json).products[1].PSObject.Properties.Name | Sort-Object)
  $miss = @(); foreach ($p in $ca.products) { $have = @($p.PSObject.Properties.Name | Sort-Object); $d = Compare-Object $need $have; if ($d) { $miss += ($p.k + ':' + (($d | ForEach-Object { $_.SideIndicator + $_.InputObject }) -join ',')) } }
  L ("catalog_추가분.json 항목 키 = 라이브 catalog.json 항목 키(" + ($need -join ',') + "): 차이 " + $miss.Count + " " + ($miss -join ' | '))
} finally { Stop-CdpChrome }
$out | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'check_add_log.txt')

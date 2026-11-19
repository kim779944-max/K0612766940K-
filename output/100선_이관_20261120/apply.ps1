# ============================================================================
#  100선 실매출 5종 → 실서비스 oneclick 이관 (2026-11-20 패키지)
#  ※ 대표님 시연·승인(관문 6) 전에는 실행하지 않습니다. 이 파일은 만들기만 했습니다.
#
#  하는 일 (3단계)
#   1) copy_manifest.json 대로 10개 파일 복사(html 5 + 아이콘 5)
#      + 상세 페이지 캡처 5장(shots/{slug}_home.png — products 의 shot 칸이 가리킴, 없으면 상세 페이지 그림 404)
#      + ★ 문의 카드 링크 1줄 교체: '../misa-1116/form.html' → 'https://autooneclick.com/#reserve'
#        (misa-1116 폴더는 실서비스 저장소에 없음 → 그대로 두면 404. 5종 모두 각 1곳, 합계 5곳)
#   2) products.js 의 window.PRODUCTS 끝(`];` 앞)에 products_추가분.js 의 객체 5개를 붙임
#   3) catalog.json 의 products 끝에 catalog_추가분.json 의 5개를 붙이고 "count": 19 → 24
#
#  되돌리기:  cd <oneclick>
#            git checkout -- products.js catalog.json
#            git clean -n -- swapcheck.html rights1p.html balju.html ledger.html tagmaker.html shots/   (확인 후 -n 을 -f 로)
#
#  사용:  powershell -ExecutionPolicy Bypass -File apply.ps1 [-OC <oneclick 저장소 경로>]
# ============================================================================
param([string]$OC = (Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot))) 'oneclick'))
$ErrorActionPreference = 'Stop'
$PKG = $PSScriptRoot
$K = (Resolve-Path (Join-Path $PKG '..\..')).Path
$OC = (Resolve-Path $OC).Path
$OLD = '../misa-1116/form.html'
$NEW = 'https://autooneclick.com/#reserve'
$UTF8 = New-Object Text.UTF8Encoding $false
if (-not (Test-Path (Join-Path $OC 'products.js')) -or -not (Test-Path (Join-Path $OC 'catalog.json'))) { throw "oneclick 저장소가 아닙니다: $OC" }
Write-Output "oneclick = $OC  (HEAD $(git -C $OC rev-parse --short HEAD))"

# ---- 1) 복사 + 문의 링크 교체 ----
$man = Get-Content -Raw -Encoding UTF8 (Join-Path $PKG 'copy_manifest.json') | ConvertFrom-Json
$slugs = @()
foreach ($m in $man) {
  $src = Join-Path $K $m.from; $dst = Join-Path $OC $m.to
  if (-not (Test-Path $src)) { throw "원본 없음: $src" }
  New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
  if ($m.to -like '*.html') {
    $t = [IO.File]::ReadAllText($src, [Text.Encoding]::UTF8)
    $n = ([regex]::Matches($t, [regex]::Escape($OLD))).Count
    [IO.File]::WriteAllText($dst, $t.Replace($OLD, $NEW), $UTF8)
    Write-Output ("복사 {0} → {1} · 문의 링크 교체 {2}곳" -f $m.from, $m.to, $n)
    $slugs += [IO.Path]::GetFileNameWithoutExtension($m.to)
  } else { Copy-Item $src $dst -Force; Write-Output ("복사 {0} → {1}" -f $m.from, $m.to) }
}
foreach ($s in $slugs) {   # 상세 페이지 캡처 (products 의 shot 칸)
  $src = Join-Path $K "oneclick\shots\${s}_home.png"
  if (Test-Path $src) { Copy-Item $src (Join-Path $OC "shots\${s}_home.png") -Force; Write-Output "복사 oneclick/shots/${s}_home.png → shots/${s}_home.png (상세 캡처)" }
  else { Write-Warning "상세 캡처 없음: $src" }
}

# ---- 2) products.js ----
$pj = Join-Path $OC 'products.js'
$p = [IO.File]::ReadAllText($pj, [Text.Encoding]::UTF8)
$add = [IO.File]::ReadAllText((Join-Path $PKG 'products_추가분.js'), [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
$m1 = [regex]::Match($add, '(?s)window\.KTS_PRODUCTS_ADD_20261120 = \[\r?\n(.*)\r?\n\];')
if (-not $m1.Success) { throw 'products_추가분.js 형식 오류' }
$objs = ($m1.Groups[1].Value -replace "`r`n", "`n") -replace "`n", "`r`n"
$dup = @($slugs | Where-Object { $p -match ("k:'" + $_ + "'") })
if ($dup.Count) { Write-Warning ("products.js 에 이미 있음 — 건너뜀: " + ($dup -join ',')) }
else {
  $re = [regex]'(\]\})(\r?\n\];)'
  if (-not $re.IsMatch($p)) { throw 'products.js 에서 PRODUCTS 배열 끝(]} + ];)을 찾지 못함' }
  $p = $re.Replace($p, ('$1,' + "`r`n`r`n" + $objs.Replace('$', '$$') + '$2'), 1)
  [IO.File]::WriteAllText($pj, $p, $UTF8)
  Write-Output 'products.js: 5개 추가'
}

# ---- 3) catalog.json ----
$cj = Join-Path $OC 'catalog.json'
$c = [IO.File]::ReadAllText($cj, [Text.Encoding]::UTF8)
$ca = [IO.File]::ReadAllText((Join-Path $PKG 'catalog_추가분.json'), [Text.Encoding]::UTF8)
$m2 = [regex]::Match($ca, '(?s)"products": \[\n(.*)\n \]\n\}')
if (-not $m2.Success) { throw 'catalog_추가분.json 형식 오류' }
$items = $m2.Groups[1].Value -replace "`n", "`r`n"
if ($c -match '"k": "swapcheck"') { Write-Warning 'catalog.json 에 이미 있음 — 건너뜀' }
else {
  $re2 = [regex]'(\r?\n  \})(\r?\n \]\r?\n\}\s*)$'
  if (-not $re2.IsMatch($c)) { throw 'catalog.json 에서 products 배열 끝을 찾지 못함' }
  $c = $re2.Replace($c, ('$1,' + "`r`n" + $items.Replace('$', '$$') + '$2'), 1)
  $c = [regex]::Replace($c, '"count": 19,', '"count": 24,')
  [IO.File]::WriteAllText($cj, $c, $UTF8)
  $chk = $c | ConvertFrom-Json
  Write-Output ("catalog.json: count={0} · products={1}" -f $chk.count, $chk.products.Count)
  if ($chk.count -ne $chk.products.Count) { Write-Warning 'count 와 products 수가 다릅니다' }
}
Write-Output ''
Write-Output '끝. 확인: git -C <oneclick> status --short  /  쇼룸(index.html)에서 5개 타일 · 상세 페이지 · 문의 링크(https://autooneclick.com/#reserve)'

# ============================================================================
#  100선 핵심 10종 → 실서비스 oneclick 이관 (2026-11-20 상위 패키지 · 기존 5종 패키지를 포함)
#  ※ 대표님 시연·승인(관문 6) 전에는 실서비스 저장소에 실행하지 않습니다. 시험은 %TEMP% 사본에서만.
#
#  하는 일 (멱등 — 몇 번 돌려도 이미 들어간 것은 다시 넣지 않음)
#   0) 대상 저장소에 커밋 안 된 변경이 있으면 멈춤(다른 작업과 섞이지 않게)
#   1) copy_manifest.json 30줄 복사(html 10 + 아이콘 10 + 상세 캡처 10). 대상과 내용이 같으면 건너뜀
#      + 문의 카드 링크 교체: '../misa-1116/form.html' → 'https://autooneclick.com/#reserve' (10종 각 1곳, 합계 10곳)
#   2) products.js : 아직 없는 k 만 window.PRODUCTS 끝(`];` 앞)에 붙임 (기존 5종이 이미 있으면 나머지 5종만)
#   3) catalog.json: 아직 없는 k 만 products 끝에 붙이고, count = products 배열 길이로 다시 계산(고정 값 안 씀)
#
#  사용:  powershell -ExecutionPolicy Bypass -File apply.ps1 [-OC <oneclick 저장소>] [-WhatIf] [-Exclude themenu,bidcompare]
#         -WhatIf  : 바뀔 것만 출력하고 아무 파일도 쓰지 않음
#         -Exclude : 뺄 slug(9종·8종 패키지로 줄일 때)
#  되돌리기: README.md '되돌리기' 3줄
# ============================================================================
param(
  [string]$OC = (Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot))) 'oneclick'),
  [switch]$WhatIf,
  [string[]]$Exclude = @()
)
$ErrorActionPreference = 'Stop'
$PKG = $PSScriptRoot
$SrcRoot = (Resolve-Path (Join-Path $PKG '..\..')).Path   # K0612766940K- (원본 파일 위치)
$OC = (Resolve-Path $OC).Path
$OLD = '../misa-1116/form.html'
$NEW = 'https://autooneclick.com/#reserve'
$UTF8 = New-Object Text.UTF8Encoding $false
$tag = if ($WhatIf) { '[WhatIf] ' } else { '' }
if (-not (Test-Path (Join-Path $OC 'products.js')) -or -not (Test-Path (Join-Path $OC 'catalog.json'))) { throw "oneclick 저장소가 아닙니다: $OC" }
Write-Output "${tag}oneclick = $OC  (HEAD $(git -C $OC rev-parse --short HEAD))"

# ---- 0) 대상 저장소가 깨끗한지 ----
$dirty = @(git -C $OC status --short)
if ($dirty.Count) {
  Write-Output "멈춤: 대상 저장소에 커밋 안 된 변경이 $($dirty.Count)건 있습니다. 먼저 커밋하거나 되돌린 뒤 다시 실행하세요."
  $dirty | Select-Object -First 10 | ForEach-Object { "   $_" }
  exit 2
}

# ---- 준비: 패키지 읽기 ----
$man = @((Get-Content -Raw -Encoding UTF8 (Join-Path $PKG 'copy_manifest.json') | ConvertFrom-Json) | ForEach-Object { $_ })   # PS 5.1: 배열을 한 덩어리로 내보내므로 풀어 줌
$slugs = @($man | ForEach-Object { $_.slug } | Select-Object -Unique | Where-Object { $Exclude -notcontains $_ })
if ($Exclude.Count) { Write-Output ("${tag}제외: " + ($Exclude -join ',') + " → 대상 " + $slugs.Count + "종") }
$addJs = [IO.File]::ReadAllText((Join-Path $PKG 'products_추가분.js'), [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
$addCa = [IO.File]::ReadAllText((Join-Path $PKG 'catalog_추가분.json'), [Text.Encoding]::UTF8)
$pBlk = @{}; foreach ($m in [regex]::Matches($addJs, "(?ms)^  \{k:'([\w-]+)',.*?\]\}(?=,?\r?\n)")) { $pBlk[$m.Groups[1].Value] = ($m.Value -replace "`r`n", "`n") }
$ci = $addCa.IndexOf('"products": [')
if ($ci -lt 0) { throw 'catalog_추가분.json 형식 오류("products": [ 없음)' }
$cBlk = @{}; foreach ($m in [regex]::Matches($addCa.Substring($ci), '(?ms)^  \{\r?\n.*?^  \}')) { $ck = [regex]::Match($m.Value, '"k": "([\w-]+)"').Groups[1].Value; $cBlk[$ck] = ($m.Value -replace "`r`n", "`n") }
foreach ($s in $slugs) { if (-not $pBlk[$s]) { throw "products_추가분.js 에 $s 없음" }; if (-not $cBlk[$s]) { throw "catalog_추가분.json 에 $s 없음" } }

$pj = Join-Path $OC 'products.js'; $p = [IO.File]::ReadAllText($pj, [Text.Encoding]::UTF8)
$cj = Join-Path $OC 'catalog.json'; $c = [IO.File]::ReadAllText($cj, [Text.Encoding]::UTF8)
$bomP = $p.Length -gt 0 -and $p[0] -eq [char]0xFEFF; $bomC = $c.Length -gt 0 -and $c[0] -eq [char]0xFEFF
$p = $p.TrimStart([char]0xFEFF); $c = $c.TrimStart([char]0xFEFF)
$nlP = if ($p -match "`r`n") { "`r`n" } else { "`n" }
$nlC = if ($c -match "`r`n") { "`r`n" } else { "`n" }
$liveC = $c | ConvertFrom-Json
$needP = @($slugs | Where-Object { $p -notmatch ("\{k:'" + [regex]::Escape($_) + "'") })
$needC = @($slugs | Where-Object { $sk = $_; -not ($liveC.products | Where-Object { $_.k -eq $sk }) })
$skipP = @($slugs | Where-Object { $needP -notcontains $_ }); $skipC = @($slugs | Where-Object { $needC -notcontains $_ })
if ($skipP.Count) { Write-Output ("${tag}products.js 에 이미 있음 — 건너뜀: " + ($skipP -join ',')) }
if ($skipC.Count) { Write-Output ("${tag}catalog.json 에 이미 있음 — 건너뜀: " + ($skipC -join ',')) }

# ---- 1) 복사 + 문의 링크 교체 ----
$nCopy = 0; $nSame = 0; $nLink = 0
foreach ($m in ($man | Where-Object { $slugs -contains $_.slug })) {
  $src = Join-Path $SrcRoot $m.from; $dst = Join-Path $OC $m.to
  if (-not (Test-Path $src)) { throw "원본 없음: $src" }
  if ($m.to -like '*.html') {
    $t = [IO.File]::ReadAllText($src, [Text.Encoding]::UTF8)
    $n = ([regex]::Matches($t, [regex]::Escape($OLD))).Count
    $newBytes = $UTF8.GetBytes($t.Replace($OLD, $NEW))
  } else { $n = 0; $newBytes = [IO.File]::ReadAllBytes($src) }
  if ((Test-Path $dst) -and ([Convert]::ToBase64String([IO.File]::ReadAllBytes($dst)) -eq [Convert]::ToBase64String($newBytes))) { $nSame++; continue }
  $nCopy++; $nLink += $n
  if (-not $WhatIf) { New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null; [IO.File]::WriteAllBytes($dst, $newBytes) }
  $note = if ($m.to -like '*.html') { " · 문의 링크 교체 ${n}곳" } else { '' }
  Write-Output ("${tag}복사 {0} → {1}{2}" -f $m.from, $m.to, $note)
}
Write-Output ("${tag}복사 {0}개 · 이미 같은 파일 {1}개 · 문의 링크 교체 합계 {2}곳" -f $nCopy, $nSame, $nLink)

# ---- 2) products.js ----
if ($needP.Count) {
  $re = [regex]'(\]\})(\r?\n\];)'
  if (-not $re.IsMatch($p)) { throw 'products.js 에서 PRODUCTS 배열 끝(]} + ];)을 찾지 못함' }
  $objs = (($needP | ForEach-Object { $pBlk[$_] }) -join (",`n`n")) -replace "`n", $nlP
  $p2 = $re.Replace($p, ('$1,' + $nlP + $nlP + $objs.Replace('$', '$$') + '$2'), 1)
  if (-not $WhatIf) { [IO.File]::WriteAllText($pj, $(if ($bomP) { [char]0xFEFF + $p2 } else { $p2 }), $UTF8) }
}
Write-Output ("${tag}products.js: +{0}개 ({1})" -f $needP.Count, ($needP -join ','))

# ---- 3) catalog.json (count = products 배열 길이로 다시 계산) ----
$before = $liveC.count
if ($needC.Count) {
  $re2 = [regex]'(\r?\n  \})(\r?\n \]\r?\n\}\s*)$'
  if (-not $re2.IsMatch($c)) { throw 'catalog.json 에서 products 배열 끝을 찾지 못함' }
  $items = (($needC | ForEach-Object { $cBlk[$_] }) -join (",`n")) -replace "`n", $nlC
  $c = $re2.Replace($c, ('$1,' + $nlC + $items.Replace('$', '$$') + '$2'), 1)
}
$cnt = @(($c | ConvertFrom-Json).products).Count
$c = [regex]::Replace($c, '"count":\s*\d+', ('"count": ' + $cnt), 1)
$chk = $c | ConvertFrom-Json
if ($chk.count -ne @($chk.products).Count) { throw 'count 와 products 수가 다릅니다' }
if (($needC.Count -or $before -ne $cnt) -and -not $WhatIf) { [IO.File]::WriteAllText($cj, $(if ($bomC) { [char]0xFEFF + $c } else { $c }), $UTF8) }
Write-Output ("${tag}catalog.json: +{0}개 ({1}) · count {2} → {3} (= products {4}개)" -f $needC.Count, ($needC -join ','), $before, $chk.count, @($chk.products).Count)

Write-Output ''
if ($WhatIf) { Write-Output '[WhatIf] 아무 파일도 쓰지 않았습니다.' }
else { Write-Output '끝. 확인: git -C <oneclick> status --short  /  쇼룸(index.html) 타일 · 상세(detail.html?k=slug) · 문의 링크(https://autooneclick.com/#reserve)' }

# 핵심 10종 이관 패키지 — products_추가분.js · copy_manifest.json 만들기 (다시 돌리면 같은 결과)
#  원본: K0612766940K-/oneclick/products.js (NIGHT 쇼룸 등록분, 문구 그대로) · 기존 5종 패키지(output/100선_이관_20261120)와 대조
#  catalog_추가분.json 은 check_add.ps1 이 크롬에서 products_추가분.js 를 읽어 JSON.stringify 로 만든다(형식 동일 보장)
$ErrorActionPreference = 'Stop'
$PKG = (Resolve-Path "$PSScriptRoot\..").Path
$K = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$UTF8 = New-Object Text.UTF8Encoding $false
$SEL = @(
  @('swapcheck', '#71', '기존 5종'), @('rights1p', '#65', '기존 5종'), @('yieldcalc', '#69', '추가 5종'), @('pricegap', '#67', '추가 5종'),
  @('notice', '#74', '추가 5종'), @('bidcompare', '#70', '추가 5종'), @('balju', '#57', '기존 5종'), @('ledger', '#76', '기존 5종'),
  @('tagmaker', '#88', '기존 5종'), @('themenu', '#61', '추가 5종')
)
$src = [IO.File]::ReadAllText((Join-Path $K 'oneclick\products.js'), [Text.Encoding]::UTF8)
$old = [IO.File]::ReadAllText((Join-Path $K 'output\100선_이관_20261120\products_추가분.js'), [Text.Encoding]::UTF8)
function Get-Obj([string]$text, [string]$slug) {
  $m = [regex]::Match($text, "(?ms)^  \{k:'" + [regex]::Escape($slug) + "',.*?\]\}(?=,?\r?\n)")
  if (-not $m.Success) { throw "객체를 찾지 못함: $slug" }
  return ($m.Value -replace "`r`n", "`n")
}
$blocks = @(); $man = @(); $i = 0
foreach ($s in $SEL) {
  $i++; $slug = $s[0]
  $o = Get-Obj $src $slug
  if ($s[2] -eq '기존 5종') {
    $o2 = Get-Obj $old $slug
    Write-Output ("{0,-10} 기존 5종 패키지 객체와 동일: {1}" -f $slug, ($o -eq $o2))
  }
  $price = [regex]::Match($o, "price:'([^']*)'").Groups[1].Value
  $want = if ($slug -eq 'themenu') { '무료' } else { '무료 체험' }
  if ($price -ne $want) { $o = $o.Replace("price:'$price'", "price:'$want'"); Write-Output "  $slug price '$price' → '$want' (지시서 2-1 규칙)" }
  $shot = [regex]::Match($o, "shot:'([^']*)'").Groups[1].Value
  $icon = [regex]::Match($o, "icon:'([^']*)'").Groups[1].Value
  if ($shot -ne "shots/${slug}_home.png" -or $icon -ne "shots/ic_$slug.png") { throw "$slug icon/shot 경로가 규칙과 다름: $icon / $shot" }
  $blocks += ("  /* " + $i + "/10 " + $s[1] + " " + $slug + " · " + $s[2] + " — 이 주석부터 객체 끝까지 빼면 이 종만 빠집니다 */`n" + $o)
  $man += [ordered]@{ slug = $slug; from = "oneclick/$slug.html"; to = "$slug.html" }
  $man += [ordered]@{ slug = $slug; from = "oneclick/shots/ic_$slug.png"; to = "shots/ic_$slug.png" }
  $man += [ordered]@{ slug = $slug; from = "oneclick/shots/${slug}_home.png"; to = "shots/${slug}_home.png" }
}
$head = @'
/* ============================================================
   KTS 원클릭 100선 → 실서비스 이관 추가분 — 핵심 10종 (2026-11-20, 상위 패키지)
   · apply.ps1 이 아래 배열의 객체 중 실서비스 products.js 에 아직 없는 k 만 window.PRODUCTS 맨 끝(`];` 바로 앞)에 붙입니다.
   · 형식은 기존 products.js 그대로(k, nm, sub, cat, badge, status, icon, price, price2, line, blurb, link, shot, bullets, how, notes).
   · 출처: K0612766940K-/oneclick/products.js (NIGHT 쇼룸 등록분, 문구 그대로 · price 만 지시서 규칙: themenu '무료', 나머지 '무료 체험')
   · 9종·8종으로 줄일 때: 해당 slug 의 'n/10 slug' 주석 줄부터 객체 끝까지를 지우거나, apply.ps1 -Exclude slug 로 실행합니다.
   ============================================================ */
window.KTS_PRODUCTS_ADD_20261120_TOP10 = [

'@
$body = ($blocks -join ",`n`n") + "`n];`n"
[IO.File]::WriteAllText((Join-Path $PKG 'products_추가분.js'), (($head -replace "`r`n", "`n") + $body), (New-Object Text.UTF8Encoding $true))
$mj = "[`n" + (($man | ForEach-Object { ' { "slug": "' + $_.slug + '", "from": "' + $_.from + '", "to": "' + $_.to + '" }' }) -join ",`n") + "`n]`n"
[IO.File]::WriteAllText((Join-Path $PKG 'copy_manifest.json'), $mj, $UTF8)
$ok = 0; foreach ($m in $man) { if (Test-Path (Join-Path $K $m.from)) { $ok++ } else { Write-Output "없음: $($m.from)" } }
Write-Output ("copy_manifest.json: {0}줄 · Test-Path {1}/{0}" -f $man.Count, $ok)
Write-Output ("products_추가분.js: 객체 {0}개" -f $blocks.Count)

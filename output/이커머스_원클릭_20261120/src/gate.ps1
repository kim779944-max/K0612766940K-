# G1 하드 린터 9항목 (kts_gate.py 와 같은 9개 검사를 Python 없이 PowerShell 로 이식)
# 대상: output/이커머스_원클릭_20261120/*.html (+ assets/*.js 는 G1-5 열쇠 검사에 포함)
# 사용: powershell -ExecutionPolicy Bypass -File src\gate.ps1     → shots\_gate.txt 작성 + 측정.txt 재조립, FAIL 수만큼 exit code
# 실명 목록은 저장소에 쓰지 않습니다. 필요하면 실행 창에서만: $env:KTS_REALNAMES = '이름1,이름2'
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$base = (Resolve-Path "$PSScriptRoot\..").Path
$rows = New-Object System.Collections.ArrayList
function Add-Row($f, $item, $verdict, $why) { [void]$rows.Add([pscustomobject]@{ f = $f; item = $item; v = $verdict; why = $why }) }
function Read-Utf8($p) { return [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) }

$htmls = @('index.html', 'coupang.html', 'naver.html', 'global.html', 'blog.html', 'insta.html')
$need = $htmls + @('assets/app.css', 'assets/app.js', 'assets/xlsx.js', 'assets/ai.js', 'assets/freekey.js', 'assets/data/bundle.js',
  'assets/data/fees.json', 'assets/data/duties.json', 'assets/data/tags_ko.json', 'assets/data/copy_ko.json', 'assets/data/copy_en.json', 'assets/data/copy_ja.json',
  'assets/data/blog_bones.json', 'assets/data/insta_copy.json', 'assets/data/sample_products.json')

# G1-1 파일 존재
$miss = @($need | Where-Object { -not (Test-Path (Join-Path $base $_)) })
Add-Row '(폴더)' 'G1-1 파일 존재' $(if ($miss.Count) { 'FAIL' } else { 'PASS' }) ("필수 " + $need.Count + "개 중 없음 " + $miss.Count + $(if ($miss.Count) { ' : ' + ($miss -join ',') } else { '' }))

$realNames = @()
if ($env:KTS_REALNAMES) { $realNames = $env:KTS_REALNAMES.Split(',') | Where-Object { $_.Trim() } }

foreach ($h in $htmls) {
  $p = Join-Path $base $h
  if (-not (Test-Path $p)) { continue }
  $src = Read-Utf8 $p
  # 스크립트·스타일 본문을 뺀 마크업(태그 짝 검사용)
  $markup = [regex]::Replace($src, '(?is)(<script\b[^>]*>).*?(</script>)', '$1$2')
  $markup = [regex]::Replace($markup, '(?is)(<style\b[^>]*>).*?(</style>)', '$1$2')

  # G1-2 태그 짝
  $bad = @()
  foreach ($t in @('div', 'section', 'main', 'header', 'nav', 'table', 'script', 'style', 'label', 'select', 'button', 'a', 'ol', 'ul', 'p', 'h1', 'h2', 'textarea')) {
    $o = [regex]::Matches($markup, "(?i)<$t(\s[^>]*)?>").Count
    $c = [regex]::Matches($markup, "(?i)</$t>").Count
    if ($o -ne $c) { $bad += "$t $o/$c" }
  }
  Add-Row $h 'G1-2 태그 짝' $(if ($bad.Count) { 'FAIL' } else { 'PASS' }) $(if ($bad.Count) { '열림/닫힘 불일치: ' + ($bad -join ', ') } else { '18종 태그 열림=닫힘' })

  # G1-3 Base64 용량(1장 150KB · 합계 500KB)
  $b64 = [regex]::Matches($src, 'data:[a-z/+.-]+;base64,([A-Za-z0-9+/=]+)')
  $sizes = @($b64 | ForEach-Object { [math]::Floor($_.Groups[1].Value.Length * 3 / 4) })
  $max = if ($sizes.Count) { ($sizes | Measure-Object -Maximum).Maximum } else { 0 }
  $sum = if ($sizes.Count) { ($sizes | Measure-Object -Sum).Sum } else { 0 }
  Add-Row $h 'G1-3 Base64 용량' $(if ($max -gt 153600 -or $sum -gt 512000) { 'FAIL' } else { 'PASS' }) ("내장 " + $sizes.Count + "개 · 최대 " + $max + "B · 합계 " + $sum + "B")

  # G1-4 모달 닫기 수단
  $modal = ([regex]::Matches($markup, '(?i)role="dialog"|class="sheet')).Count
  if ($modal) {
    $close = ([regex]::Matches($markup, 'data-close')).Count
    $esc = (Read-Utf8 (Join-Path $base 'assets/app.js')) -match "Escape"
    Add-Row $h 'G1-4 모달 닫기' $(if ($close -ge 1 -and $esc) { 'PASS' } else { 'FAIL' }) ("모달 " + $modal + "개 · [닫기] " + $close + "개 · 바깥 누름·Esc 닫기(app.js) " + $esc)
  } else { Add-Row $h 'G1-4 모달 닫기' 'PASS' '모달 0개' }

  # G1-5 API 키 하드코딩
  $keyHits = ([regex]::Matches($src, 'sk-[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_\-]{20,}|apiKey\s*=\s*["''][^"'']{8,}')).Count
  Add-Row $h 'G1-5 API키 하드코딩' $(if ($keyHits) { 'FAIL' } else { 'PASS' }) ("sk-/AIza/apiKey= 일치 " + $keyHits + "건")

  # G1-6 실명(연락처·이메일·주민번호 패턴 + 실행 창 지정 실명 목록)
  $txt = [regex]::Replace($src, 'data:[^"'')\s]+', '')
  $ph = ([regex]::Matches($txt, '01[016789][-. ]?\d{3,4}[-. ]?\d{4}')).Count
  $em = ([regex]::Matches($txt, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')).Count
  $rr = ([regex]::Matches($txt, '\d{6}-[1-4]\d{6}')).Count
  $nm = 0; foreach ($n in $realNames) { $nm += ([regex]::Matches($txt, [regex]::Escape($n.Trim()))).Count }
  Add-Row $h 'G1-6 실명' $(if ($ph + $em + $rr + $nm) { 'FAIL' } else { 'PASS' }) ("휴대폰 " + $ph + " · 이메일 " + $em + " · 주민번호 " + $rr + " · 실명목록(" + $realNames.Count + "개) " + $nm)

  # G1-7 원가·내부문구 (사장님 구역은 WARN)
  $words = @('원가', '도매가', '매입가', '마진', '수수료')
  $cnt = 0; $hit = @(); foreach ($w in $words) { $k = ([regex]::Matches($src, $w)).Count; if ($k) { $cnt += $k; $hit += "$w $k" } }
  $owner = $src -match 'id="ownerApp"'
  if ($cnt -eq 0) { Add-Row $h 'G1-7 원가·내부문구' 'PASS' '0건' }
  elseif ($owner) { Add-Row $h 'G1-7 원가·내부문구' 'WARN' ("사장님 구역(#ownerApp) 격리 확인 · " + ($hit -join ', ') + " · 손님 산출물은 verify.ps1 G2 에서 0건 확인") }
  else { Add-Row $h 'G1-7 원가·내부문구' 'FAIL' ("손님 화면에 " + ($hit -join ', ')) }

  # G1-8 내부 링크 대상 존재
  $refs = [regex]::Matches($markup, '(?i)(?:href|src)="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
  $broken = @()
  foreach ($r in $refs) {
    if ($r -match '^(https?:|data:|instagram:|mailto:|tel:|javascript:|#)') { continue }
    $rel = ($r -replace '[?#].*$', '')
    if (-not $rel) { continue }
    if (-not (Test-Path (Join-Path $base $rel))) { $broken += $r }
  }
  Add-Row $h 'G1-8 내부 링크' $(if ($broken.Count) { 'FAIL' } else { 'PASS' }) ("내부 링크 " + @($refs | Where-Object { $_ -notmatch '^(https?:|data:|instagram:|#)' }).Count + "개 · 없는 대상 " + $broken.Count + $(if ($broken.Count) { ' : ' + ($broken -join ',') } else { '' }))

  # G1-9 viewport
  $vp = $src -match '<meta name="viewport" content="width=device-width'
  Add-Row $h 'G1-9 viewport' $(if ($vp) { 'PASS' } else { 'FAIL' }) $(if ($vp) { 'width=device-width 있음' } else { 'viewport 없음' })
}

# G1-5 보조: assets/*.js · data 에 열쇠 문자열이 없는지
$jsHits = 0
Get-ChildItem (Join-Path $base 'assets') -Recurse -File -Include *.js, *.json | ForEach-Object { $jsHits += ([regex]::Matches((Read-Utf8 $_.FullName), 'sk-[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_\-]{20,}')).Count }
Add-Row 'assets/**' 'G1-5 API키 하드코딩' $(if ($jsHits) { 'FAIL' } else { 'PASS' }) ("js·json 일치 " + $jsHits + "건 · freekey.js p=[] 비움")

$fail = @($rows | Where-Object { $_.v -eq 'FAIL' }).Count
$warn = @($rows | Where-Object { $_.v -eq 'WARN' }).Count
$pass = @($rows | Where-Object { $_.v -eq 'PASS' }).Count
$out = New-Object System.Text.StringBuilder
[void]$out.AppendLine('## G1 하드 린터 (src/gate.ps1) — ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
[void]$out.AppendLine('')
[void]$out.AppendLine('| 파일 | 항목 | 판정 | 근거 |')
[void]$out.AppendLine('|---|---|---|---|')
foreach ($r in $rows) { [void]$out.AppendLine('| ' + $r.f + ' | ' + $r.item + ' | ' + $r.v + ' | ' + ($r.why -replace '\|', '/') + ' |') }
[void]$out.AppendLine('')
[void]$out.AppendLine("합계: PASS $pass · WARN $warn · FAIL $fail (행 " + $rows.Count + ")")
[void]$out.AppendLine('WARN 사유: 5종은 사장님 도구라 원가·마진이 화면에 나옵니다. 전체를 #ownerApp(사장님 구역)으로 감싸 격리했고, 손님에게 나가는 산출물(상세·블로그·인스타)은 verify.ps1 의 G2 항목에서 0건을 확인합니다.')
$shots = Join-Path $base 'shots'; if (-not (Test-Path $shots)) { New-Item -ItemType Directory -Force $shots | Out-Null }
[IO.File]::WriteAllText((Join-Path $shots '_gate.txt'), $out.ToString(), (New-Object System.Text.UTF8Encoding($true)))
. "$PSScriptRoot\measure.ps1"
Build-Measure $base
Write-Output ("G1 gate: PASS $pass · WARN $warn · FAIL $fail")
exit $fail

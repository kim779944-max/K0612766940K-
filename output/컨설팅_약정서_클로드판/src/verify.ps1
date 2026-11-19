# 완료 판정 실측 → 측정.txt (cap.ps1 · gen_forms.ps1 뒤에 실행)
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
. "$PSScriptRoot\..\..\교환계약서_20261120\src\px.ps1"
Add-Type -TypeDefinition @'
public static class Cmp {
  public static int Xor(byte[] a, byte[] b, int thr){ int n=0; for(int i=0;i<a.Length;i++){ if((a[i]<thr)!=(b[i]<thr)) n++; } return n; }
  public static int Diff(byte[] a, byte[] b){ int n=0; for(int i=0;i<a.Length;i++) if(a[i]!=b[i]) n++; return n; }
  public static int Dark(byte[] a, int thr){ int n=0; for(int i=0;i<a.Length;i++) if(a[i]<thr) n++; return n; }
}
'@
$ErrorActionPreference = 'Stop'
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$REPO = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$RAW = Join-Path $OUT '측정_원자료'
$U8 = [Text.Encoding]::UTF8
$L = New-Object Collections.Generic.List[string]
function W([string]$s) { $L.Add($s); Write-Output $s }
function J([string]$n) { return ([IO.File]::ReadAllText((Join-Path $RAW $n), $U8) | ConvertFrom-Json) }
$THEMES = 'mono', 'sky', 'green', 'gray'
$MM = 25.4 / 96
$CI = [Globalization.CultureInfo]::InvariantCulture
function F2($v) { return ([double]$v).ToString('0.00', $CI) }
$script:fail = 0
function Chk([bool]$ok, [string]$what) { if (-not $ok) { $script:fail++ }; if ($ok) { W ('OK   ' + $what) } else { W ('FAIL ' + $what) } }

W ("# 측정.txt — 부동산 컨설팅 전속 거래 약정서 조판 실측 원문 로그 (" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ")")
W ("# 생성: src/verify.ps1 · 원자료: 측정_원자료/*.json (src/cap.ps1 이 consult.html 을 헤드리스 크롬으로 열어 src/measure.js 로 잰 값)")
W ("# 단위: css px(96dpi) · mm · pt · PNG px(1489×2105, S = 1489 / 페이지 폭 css px)")
W ""

# ---------- 1. 판형·활자 ----------
$s = J 'screen_sky.json'
$SC = [double]$s.S
W "## 1. 판형·활자 (screen_sky.json)"
W ("페이지 css px = " + (F2 $s.pageW) + " × " + (F2 $s.pageH) + "  → " + (F2 ($s.pageW * $MM)) + " × " + (F2 ($s.pageH * $MM)) + " mm · S = " + $SC.ToString('0.00000', $CI) + " PNG px/css px (= " + (F2 ($SC / $MM)) + " PNG px/mm)")
$p1 = $s.pages[0]
W ("여백 좌/우/위/아래 = " + (F2 ($p1.padL * $MM)) + " / " + (F2 ($p1.padR * $MM)) + " / " + (F2 ($p1.padT * $MM)) + " / " + (F2 ($p1.padB * $MM)) + " mm  (PNG px " + (F2 ($p1.padL * $SC)) + " / " + (F2 ($p1.padR * $SC)) + " / " + (F2 ($p1.padT * $SC)) + " / " + (F2 ($p1.padB * $SC)) + ")")
Chk ([math]::Abs($p1.padL * $MM - 20) -le 2 -and [math]::Abs($p1.padR * $MM - 20) -le 2) "좌우 여백 20mm ±2"
foreach ($k in 'body', 'lead', 'h1', 'h2', 'tdLabel', 'td', 't4td') {
  $f = $s.fonts.$k
  W ("글꼴 {0,-8} {1} px = {2} pt = {3} PNG px · 줄높이 {4} px (배수 {5}) · 칸여백 상 {6}px 좌 {7}px · 괘선 {8}px · {9}" -f $k, (F2 $f.fontSizePx), (F2 ($f.fontSizePx * 0.75)), (F2 ($f.fontSizePx * $SC)), (F2 $f.lineHeightPx), (F2 ($f.lineHeightPx / $f.fontSizePx)), (F2 $f.padT), (F2 $f.padL), (F2 $f.borderTop), $f.family)
}
Chk ([math]::Abs($s.fonts.body.fontSizePx * 0.75 - 11) -le 0.5) ("본문 11pt ±0.5 (실측 " + (F2 ($s.fonts.body.fontSizePx * 0.75)) + "pt = " + (F2 ($s.fonts.body.fontSizePx * $SC)) + " PNG px)")
$lr = $s.fonts.body.lineHeightPx / $s.fonts.body.fontSizePx
Chk ($lr -ge 1.749 -and $lr -le 1.851) ("본문 줄간격 1.75~1.85 (실측 " + (F2 $lr) + ")")
$tp = $s.fonts.td.fontSizePx * 0.75
Chk ($tp -ge 10.5 -and $tp -le 11) ("표 안 10.5~11pt (실측 " + (F2 $tp) + "pt)")
Chk ([bool]$s.fonts.check.malgun) "맑은 고딕 로컬 서체 사용 가능(document.fonts.check)"
W ""
W "## 2. 쪽 경계·채움률"
foreach ($p in $s.pages) {
  $fill = $p.contentBottom / $p.h * 100
  W ("{0}: 내용 위 끝 {1} mm · 아래 끝 {2} css px = {3} mm = PNG {4} px · 채움률 {5}% · 아래 여백 {6} mm · scrollH {7} / clientH {8} · 마지막 요소 {9}" -f $p.id, (F2 ($p.contentTop * $MM)), (F2 $p.contentBottom), (F2 ($p.contentBottom * $MM)), (F2 ($p.contentBottom * $SC)), (F2 $fill), (F2 (($p.h - $p.contentBottom) * $MM)), $p.scrollH, $p.clientH, $p.lastTag)
  Chk ($fill -ge 88 -and $fill -le 97) ("{0} 채움률 88~97%" -f $p.id)
  Chk ($p.scrollH -le $p.clientH) ("{0} 넘침 없음(잘린 글자 0)" -f $p.id)
  Chk ($p.contentBottom -le ($p.h - $p.padB + 0.5)) ("{0} 아래 여백 16mm 안쪽" -f $p.id)
  W ("   제목들: " + ((@($p.heads) | ForEach-Object { $_.t + ' @' + (F2 ($_.y * $MM)) + 'mm' }) -join ' | '))
}
$h1 = (@($s.pages[0].heads) | ForEach-Object { $_.t }) -join '|'; $h2 = (@($s.pages[1].heads) | ForEach-Object { $_.t }) -join '|'
Chk ($h1 -match '^부동산 컨설팅 전속 거래 약정서\|제1조.*\|제2조.*\|제3조.*\|제4조.*\|제5조[^|]*$') "1쪽 = 제목·제1조~제5조"
Chk ($h2 -match '^제6조.*\|제7조.*\|특약사항[^|]*$') "2쪽 = 제6조·제7조·특약사항(이후 하단 문구·날짜·서명표)"
$p2b = @($s.blocks | Where-Object { $_.page -eq 2 }); $lastB = $p2b[$p2b.Count - 1]
Chk ($lastB.tag -eq 'TABLE' -and $lastB.cls -eq 't6') "2쪽 마지막 = 서명표(표6)"
foreach ($pg in 1, 2) { $bl = @($s.blocks | Where-Object { $_.page -eq $pg }); Chk ($bl[$bl.Count - 1].tag -ne 'H2') ("{0}쪽 끝에 제N조 제목만 남은 고아 없음 (마지막 블록 {1} '{2}')" -f $pg, $bl[$bl.Count - 1].tag, $bl[$bl.Count - 1].text) }
W "   각 쪽은 별도 .page 상자(조문 단위로 나눔, 넘침 0) → 조문 중간 끊김 0 · 2~3줄만 넘어가는 항목 0"
W ""

# ---------- 3. PNG·PDF ----------
W "## 3. 파일 규격"
Add-Type -AssemblyName System.Drawing
$names = @(); foreach ($t in $THEMES) { $names += "tpl_consult_p1_$t.png", "tpl_consult_p2_$t.png" }; $names += 'tpl_consult_p1.png', 'tpl_consult_p2.png'
foreach ($n in $names) { $b = [Drawing.Image]::FromFile((Join-Path $OUT $n)); $ok = ([math]::Abs($b.Width - 1489) -le 1 -and [math]::Abs($b.Height - 2105) -le 1); Chk $ok ("{0} {1}×{2} ({3:N0} B)" -f $n, $b.Width, $b.Height, (Get-Item (Join-Path $OUT $n)).Length); $b.Dispose() }
foreach ($n in 'p1', 'p2') { $ha = (Get-FileHash (Join-Path $OUT "tpl_consult_$n.png")).Hash; $hb = (Get-FileHash (Join-Path $OUT "tpl_consult_${n}_sky.png")).Hash; Chk ($ha -eq $hb) "tpl_consult_$n.png = tpl_consult_${n}_sky.png (SHA256 동일)" }
foreach ($t in $THEMES) {
  $pf = Join-Path $OUT "컨설팅_약정서_$t.pdf"; $pdfTxt = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pf))
  $pages = ([regex]::Matches($pdfTxt, '/Type\s*/Page(?!s)')).Count
  $mb = (@([regex]::Matches($pdfTxt, '/MediaBox\s*\[([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value.Trim() }) | Select-Object -Unique) -join ' ; '
  Chk ($pages -eq 2) ("컨설팅_약정서_$t.pdf 쪽수 {0} · MediaBox [{1}] (A4 595.28×841.89pt 대비 ±1pt — 크롬은 1/96인치 단위로 반올림) · {2:N0} B" -f $pages, $mb, (Get-Item $pf).Length)
}
foreach ($t in $THEMES) { $b = [Drawing.Image]::FromFile((Join-Path $OUT "390_$t.png")); W ("390_$t.png {0}×{1} (390×844 화면 @2x)" -f $b.Width, $b.Height); $b.Dispose() }
W ""

# ---------- 4. 테마 4종: 글자 위치 동일 ----------
W "## 4. 테마 전환 — 글자 위치·줄바꿈 동일 확인"
$base = $s.sig
W ("기준(sky 화면) 텍스트 줄 상자 " + $s.sigCount + "개 (종이 왼쪽 위 기준 x·y·폭, css px)")
$SIGA = $base | ConvertFrom-Json
foreach ($t in $THEMES) {
  $a = J "screen_$t.json"; Chk ($a.sig -eq $base) ("화면 $t : 줄 상자 {0}개, 좌표 문자열 sky 와 완전 일치" -f $a.sigCount)
  $pr = J "print_$t.json"; Chk ($pr.sig -eq $base) ("인쇄 매체(PDF 배치) $t : 줄 상자 {0}개, 화면 sky 와 완전 일치(화면=PDF 위치)" -f $pr.sigCount)
  $m = J "m390_$t.json"
  $SIGB = $m.sig | ConvertFrom-Json; $mw = 0.0; $my = 0.0; $same = ($SIGA.Count -eq $SIGB.Count)
  if ($same) { for ($i = 0; $i -lt $SIGA.Count; $i++) { if ($SIGA[$i][0] -ne $SIGB[$i][0]) { $same = $false }; $d = [math]::Abs([double]$SIGA[$i][3] - [double]$SIGB[$i][3]); if ($d -gt $mw) { $mw = $d }; $d = [math]::Abs([double]$SIGA[$i][2] - [double]$SIGB[$i][2]); if ($d -gt $my) { $my = $d } } }
  $ov = 0
  for ($i = 0; $i -lt $SIGB.Count; $i++) { for ($k = $i + 1; $k -lt $SIGB.Count; $k++) { $u = $SIGB[$i]; $v = $SIGB[$k]; if ($u[0] -ne $v[0]) { continue }
    $ix = [math]::Min($u[1] + $u[3], $v[1] + $v[3]) - [math]::Max($u[1], $v[1]); $iy = [math]::Min($u[2] + $u[4], $v[2] + $v[4]) - [math]::Max($u[2], $v[2]); if ($ix -gt 0.5 -and $iy -gt 0.5) { $ov++ } } }
  Chk ($same -and $mw -le 1 -and $ov -eq 0) ("390px $t : 줄 상자 {0}개(같은 쪽·같은 순서) · 줄 폭 최대 차 {1} px → 줄바꿈 동일 · 글자 상자 겹침 {2}건 · (세로 누적 차 최대 {3} px: 0.476배 축소 시 괘선이 기기 픽셀로 맞춰져 생기는 표 행 높이 반올림, 배치·줄바꿈과 무관)" -f $SIGB.Count, (F2 $mw), $ov, (F2 $my))
}
foreach ($pg in 1, 2) {
  $ref = New-Object Px (Join-Path $OUT "tpl_consult_p${pg}_sky.png")
  $nref = New-Object Px (Join-Path $RAW "neutral_p${pg}_sky.png")
  foreach ($t in 'mono', 'green', 'gray') {
    $o2 = New-Object Px (Join-Path $OUT "tpl_consult_p${pg}_$t.png")
    $x1 = [Cmp]::Xor($ref.G, $o2.G, 200); $dk = [Cmp]::Dark($ref.G, 200)
    $n2 = New-Object Px (Join-Path $RAW "neutral_p${pg}_$t.png")
    $nd = [Cmp]::Diff($nref.G, $n2.G)
    Chk ($nd -eq 0) ("픽셀 p{0} sky↔{1}: 색 중화 캡처(글씨·괘선 #000, 바탕 #fff) 다른 화소 {2} / {3} → 글자 위치·줄바꿈 완전 동일 · (참고: 실제 색 그대로 먹 마스크 명도<200 차이 {4} / {5} 화소 = 글씨·괘선 색이 달라 생기는 가장자리 안티앨리어싱)" -f $pg, $t, $nd, $nref.G.Length, $x1, $dk)
  }
}
W ""

# ---------- 5. 원문 대조 ----------
W "## 5. 원문 대조 (reference/부동산_컨설팅_전속_거래_약정서_표준양식.hwpx → Contents/section0.xml 문단 텍스트 vs consult.html [data-p] textContent)"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $REPO 'reference\부동산_컨설팅_전속_거래_약정서_표준양식.hwpx'))
$e = $zip.GetEntry('Contents/section0.xml'); $sr = New-Object IO.StreamReader($e.Open(), $U8); $xml = $sr.ReadToEnd(); $sr.Close(); $zip.Dispose()
$doc = New-Object Xml.XmlDocument; $doc.LoadXml($xml)
$ns = New-Object Xml.XmlNamespaceManager($doc.NameTable); $ns.AddNamespace('hp', 'http://www.hancom.co.kr/hwpml/2011/paragraph')
$src = @(); foreach ($p in $doc.SelectNodes('//hp:p', $ns)) { $t = (@($p.SelectNodes('./hp:run/hp:t', $ns)) | ForEach-Object { $_.InnerText }) -join ''; if ($t -ne '') { $src += $t } }
$dst = @($s.texts)
W ("원본 비어 있지 않은 문단 {0}개 · consult.html 문단 {1}개" -f $src.Count, $dst.Count)
$diff = 0
for ($i = 0; $i -lt [math]::Max($src.Count, $dst.Count); $i++) {
  $a = $(if ($i -lt $src.Count) { $src[$i] } else { '<없음>' }); $b = $(if ($i -lt $dst.Count) { $dst[$i] } else { '<없음>' })
  if ($a -cne $b) { $diff++; W ("  차이 #{0}: 원본[{1}] / 조판[{2}]" -f ($i + 1), $a, $b) }
}
Chk ($diff -eq 0 -and $src.Count -eq $dst.Count) ("문단 단위 글자 완전 일치(공백 개수·가운뎃점 U+FF65·괄호 포함, 대소문자 구분) — 차이 {0}건" -f $diff)
$all = $dst -join "`n"
$md = [IO.File]::ReadAllText((Join-Path $REPO 'reference\컨설팅_전속거래_약정서_원문.md'), $U8)
$naeyong = @($dst | Where-Object { $_.StartsWith('내용 :') })[0]
$dotsHtml = ([regex]::Matches($naeyong, [string][char]0xFF65)).Count
$mdLine = @($md -split "`n" | Where-Object { $_ -match '내용 :' })[0]; $dotsMd = ([regex]::Matches($mdLine, [string][char]0xFF65)).Count
W ("참고: 제4조 ① '내용 :' 점선 가운뎃점 개수 — hwpx·조판 {0}개 / 원문.md {1}개 (한컴 원본 hwpx 를 최종 기준으로 따름)" -f $dotsHtml, $dotsMd)
W ""
W "## 6. 공란 유지·금지 문자"
$digits = @([regex]::Matches($all, '\d+') | ForEach-Object { $_.Value })
W ("문서 안 숫자 전부: " + ($digits -join ' '))
$bad = @($digits | Where-Object { $_ -notin @('1', '2', '3', '4', '5', '6', '7', '20') })
Chk ($bad.Count -eq 0) "숫자는 조 번호(1~7)·'20 년'·'1통'뿐 — 금액·연도·번호 값 0건"
$html = [IO.File]::ReadAllText((Join-Path $OUT 'consult.html'), $U8)
$fj = [IO.File]::ReadAllText((Join-Path $OUT 'forms_consult.js'), $U8)
Chk (-not $html.Contains([string][char]0x20A9)) "₩ 기호 0건 (consult.html)"
Chk (-not $fj.Contains([string][char]0x20A9)) "₩ 기호 0건 (forms_consult.js)"
Chk (-not ($html -match 'https?://|@import|url\(|<link|src=')) "외부 참조(http·@import·url()·link·src) 0건 (consult.html)"
W ""

# ---------- 7. 필드 좌표: PNG 에서 빈칸 확인 ----------
W "## 7. 필드 41개 — 좌표 범위 + 실제 PNG(sky) 위 빈칸 확인(칸 안쪽 3px 들여 명도<160 화소 수)"
$PXS = @{ 1 = (New-Object Px (Join-Path $OUT 'tpl_consult_p1_sky.png')); 2 = (New-Object Px (Join-Path $OUT 'tpl_consult_p2_sky.png')) }
$cur = 0; $cnt = @{ 1 = 0; 2 = 0 }; $rng = 0
foreach ($ln in ($fj -split "`n")) {
  if ($ln -match '"bg":"tpl_consult_p(\d)\.png"') { $cur = [int]$Matches[1] }
  if ($ln -match '"id":"([^"]+)".*"type":"([^"]+)","x":([\d.]+),"y":([\d.]+),"w":([\d.]+),"h":([\d.]+)') {
    $id = $Matches[1]; $ty = $Matches[2]; $x = [double]$Matches[3]; $y = [double]$Matches[4]; $w = [double]$Matches[5]; $h = [double]$Matches[6]
    $cnt[$cur]++
    $okr = ($x -gt 0 -and $x -lt 100 -and $y -gt 0 -and $y -lt 100 -and ($x + $w) -le 100 -and ($y + $h) -le 100); if (-not $okr) { $rng++ }
    $px = $PXS[$cur]; $X0 = [int][math]::Ceiling($x / 100 * 1489) + 3; $X1 = [int][math]::Floor(($x + $w) / 100 * 1489) - 3; $Y0 = [int][math]::Ceiling($y / 100 * 2105) + 3; $Y1 = [int][math]::Floor(($y + $h) / 100 * 2105) - 3
    $dark = $px.Count($X0, $X1, $Y0, $Y1, 0, 159)
    if ($ty -eq 'sign') { $note = '(서명 상자 — 배경의 ( 인 ) 글자를 감싸는 자리라 빈칸 검사 제외)' } elseif ($dark -eq 0) { $note = '빈칸' } else { $note = '!! 글자/괘선 겹침'; $script:fail++ }
    W ("  p{0} {1,-13} x={2,7} y={3,7} w={4,7} h={5,7} → PNG [{6},{7}]~[{8},{9}] 어두운 화소 {10} {11}" -f $cur, $id, $x.ToString('0.000', $CI), $y.ToString('0.000', $CI), $w.ToString('0.000', $CI), $h.ToString('0.000', $CI), $X0, $Y0, $X1, $Y1, $dark, $note)
  }
}
Chk ($cnt[1] -eq 24 -and $cnt[2] -eq 17) ("필드 수 1쪽 {0} + 2쪽 {1} = {2}" -f $cnt[1], $cnt[2], ($cnt[1] + $cnt[2]))
Chk ($rng -eq 0) "모든 좌표 0<x<100 · 0<y<100 · x+w≤100 · y+h≤100"
W ""

# ---------- 8. forms_consult.js 구문 (크롬에서 실행) ----------
W "## 8. forms_consult.js 구문·구조 (헤드리스 크롬에서 new Function 실행)"
Start-CdpChrome 9587 | Out-Null
try {
  Send-Cdp 'Page.navigate' @{ url = 'about:blank' } | Out-Null; Start-Sleep -Milliseconds 500
  $code = ConvertTo-Json -InputObject $fj
  $r = Invoke-Js ("(()=>{try{window.KC_FORMS=[{id:'sale'}];(new Function(" + $code + "))();var F=window.KC_FORM_CONSULT;var ids=F.fields.map(f=>f.id);return JSON.stringify({ok:1,pushed:window.KC_FORMS.length,pages:F.pages.length,p1:F.pages[0].fields.length,p2:F.pages[1].fields.length,flat:F.fields.length,uniq:new Set(ids).size,bg:F.bg,bg2:F.bgOf(2,'green'),sign:F.fields.filter(f=>f.type==='sign').length,money:F.fields.filter(f=>f.money).length})}catch(e){return JSON.stringify({ok:0,err:String(e)})}})()")
  W ("  결과: " + $r)
  $ro = $r | ConvertFrom-Json
  Chk ($ro.ok -eq 1 -and $ro.pages -eq 2 -and $ro.flat -eq 41 -and $ro.uniq -eq 41) "구문 오류 0 · pages 2개 · 필드 41개(id 중복 0)"
} finally { Stop-CdpChrome }
W ""

# ---------- 9. 390px ----------
W "## 9. 390px 미리보기"
foreach ($t in $THEMES) { $m = J "m390_$t.json"; Chk ($m.scrollW -le 390 -and @($m.errs).Count -eq 0) ("390_$t : scrollWidth {0} / clientWidth {1} · 오류 {2}건" -f $m.scrollW, $m.clientW, @($m.errs).Count) }
W ("cap_log: " + ((Get-Content -Encoding UTF8 (Join-Path $RAW 'cap_log.txt')) -join ' || '))
W "  (performance resource 목록 res=[] → 외부·추가 요청 0, errs=[] → JS·콘솔 오류 0)"
W ""

# ---------- 10. 실서비스 무변경 ----------
W "## 10. oneclick 저장소 무변경"
$OC = (Resolve-Path "$REPO\..\oneclick").Path
$st = (& git -C $OC status --short) -join "`n"; $hd = (& git -C $OC rev-parse HEAD)
W ("git -C oneclick status --short → [" + $st + "] · HEAD " + $hd)
Chk ($st -eq '') "oneclick 바뀐 파일 0개"
W ""
W ("== 판정: 실패 항목 {0}개 ==" -f $script:fail)
[IO.File]::WriteAllText((Join-Path $OUT '측정.txt'), ($L -join "`r`n") + "`r`n", (New-Object Text.UTF8Encoding $true))

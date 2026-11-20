# 상품별 완료 판정 자동화 (사람 손 0) — 새 헤드리스 크롬 컨텍스트에서 ?sample=1&auto=1 로 열고 CDP 로 판정
# 사용: powershell -ExecutionPolicy Bypass -File src\verify.ps1   → shots\_verify.txt + 측정.txt 재조립, FAIL 수만큼 exit code
. "$PSScriptRoot\lib.ps1"
$ErrorActionPreference = 'Stop'
$ALL = New-Object System.Collections.ArrayList
$script:no = 0
function Chk([string]$tool, [string]$item, [bool]$ok, [string]$ev) {
  $script:no++
  [void]$ALL.Add([pscustomobject]@{ n = $script:no; t = $tool; i = $item; v = $(if ($ok) { 'PASS' } else { 'FAIL' }); e = $ev })
  Write-Output ("{0,3} {1} {2,-8} {3} :: {4}" -f $script:no, $(if ($ok) { 'PASS' } else { 'FAIL' }), $tool, $item, $ev)
}
function J([string]$expr) { $s = Invoke-Js ("JSON.stringify(" + $expr + ")"); if ($null -eq $s) { return $null }; return ($s | ConvertFrom-Json) }
function Click([string]$sel) { Invoke-Js ("(function(){var b=document.querySelector('" + $sel + "'); if(!b) return 'NOEL'; b.click(); return 'OK';})()") }
function JR([double]$x) { return [math]::Floor($x + 0.5) }
function Open-Sample([string]$rel) {
  Go-Tool $rel
  $d = Wait-For "window.__done===true" 25000
  Start-Sleep -Milliseconds 300
  return $d
}
function Common([string]$tool) {
  $errs = J "window.__errs||[]"; $net = J "window.__net||[]"
  $sw = Invoke-Js "document.documentElement.scrollWidth"
  return @{ errs = @($errs).Count; errTxt = (($errs | ForEach-Object { $_ }) -join ' / '); net = @($net).Count; sw = $sw }
}
function Dl([string]$sel, [string]$pat) { Clear-Dl; $c = Click $sel; if ($c -ne 'OK') { return $null }; return (Wait-Dl $pat 10000) }
function Bom([string]$p) { $b = [IO.File]::ReadAllBytes($p); return ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) }
function Xlsx([string]$p) {
  $tmp = Join-Path $env:TEMP ('kts_xlsx_' + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Force $tmp | Out-Null
  $zip = Join-Path $tmp 'f.zip'; Copy-Item $p $zip
  $keep = Join-Path $global:BASE (Join-Path 'shots' 'files'); if (-not (Test-Path $keep)) { New-Item -ItemType Directory -Force $keep | Out-Null }; Copy-Item $p $keep -Force
  $o = @{ ok = $false; rows = 0; c1 = 0; c2 = 0; ko = $false; err = '' }
  try {
    Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp 'x') -Force
    $x = [IO.File]::ReadAllText((Join-Path $tmp 'x\xl\worksheets\sheet1.xml'), [Text.Encoding]::UTF8)
    $rows = [regex]::Matches($x, '(?s)<row r="(\d+)">(.*?)</row>')
    $o.rows = $rows.Count
    if ($rows.Count -ge 1) { $o.c1 = [regex]::Matches($rows[0].Groups[2].Value, '<c r=').Count }
    if ($rows.Count -ge 2) { $o.c2 = [regex]::Matches($rows[1].Groups[2].Value, '<c r=').Count }
    $o.ko = [regex]::IsMatch($x, '[가-힣]')
    $o.ok = $true
  } catch { $o.err = $_.Exception.Message }
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  return $o
}
$CUST = @('원가', '도매가', '매입가', '마진', '수수료')
function CustHits([string]$t) { $n = 0; foreach ($w in $CUST) { $n += ([regex]::Matches($t, $w)).Count }; $n += ([regex]::Matches($t, '01[016789][-. ]?\d{3,4}[-. ]?\d{4}')).Count; return $n }

Open-Tool 9381
try {
  # ================= 공통·허브 =================
  $d = Open-Sample 'index.html'
  $c = Common 'index'
  $cards = Invoke-Js "document.querySelectorAll('#cards a').length"
  Chk '허브' '5개 카드·390 넘침 0·오류 0' ($cards -eq 5 -and $c.sw -eq 390 -and $c.errs -eq 0) ("카드 $cards · scrollWidth $($c.sw) · 오류 $($c.errs)")

  # ================= 과업 1 쿠팡 =================
  $marginRows = @()
  foreach ($s in 0, 1, 2) {
    $d = Open-Sample ("coupang.html?sample=1&auto=1&s=$s")
    $r = J "window.__res"
    if ($s -eq 0) {
      $c = Common 'coupang'
      Chk '쿠팡' '?sample=1&auto=1 자동 완주' $d ("__done=$d")
      Chk '쿠팡' '콘솔·pageerror 0' ($c.errs -eq 0) ("오류 $($c.errs) $($c.errTxt)")
      Chk '쿠팡' '390 가로 넘침 0' ($c.sw -eq 390) ("scrollWidth $($c.sw)")
      Chk '쿠팡' '외부 요청 0(열쇠 없음)' ($c.net -eq 0) ("fetch $($c.net)건")
      $empty = Invoke-Js "document.querySelectorAll('#out .panel .empty').length"
      Chk '쿠팡' '5탭 모두 채워짐' ($empty -eq 0) ("빈 탭 $empty")
      $t = @($r.titles)
      $okT = @($t | Where-Object { $_.len -le 100 -and $_.dup -eq 0 -and $_.ban -eq 0 -and $_.sp -eq 0 }).Count
      $distinct = @($t | ForEach-Object { $_.t } | Select-Object -Unique).Count
      Chk '쿠팡' '상품명 3안 ≤100자·중복0·금지어0·특수문자0' ($okT -eq 3) (($t | ForEach-Object { "$($_.len)자/중복$($_.dup)/금지$($_.ban)" }) -join ', ')
      Chk '쿠팡' '상품명 3안 서로 다름' ($distinct -eq 3) ("고유 $distinct/3")
      $tags = @($r.tags)
      $tu = @($tags | Select-Object -Unique).Count
      $tl = @($tags | Where-Object { $_.Length -lt 2 -or $_.Length -gt 10 }).Count
      $tb = @($tags | Where-Object { $_ -match '최고|1위|정품보장|무조건|#' }).Count
      Chk '쿠팡' '태그 정확히 20·중복0·2~10자·금지어0' ($tags.Count -eq 20 -and $tu -eq 20 -and $tl -eq 0 -and $tb -eq 0) ("개수 $($tags.Count) · 고유 $tu · 길이위반 $tl · 금지어 $tb")
      Chk '쿠팡' '상세 PNG 폭780·높이≤12000·HTML과 블록순서·문구 동일' ($r.png.w -eq 780 -and $r.png.h -le 12000 -and $r.sameOrder -and $r.png.texts -eq $r.htmlTexts) ("$($r.png.w)×$($r.png.h) · 문구 PNG $($r.png.texts)/HTML $($r.htmlTexts) · 순서동일 $($r.sameOrder) · 블록 " + ($r.blocks -join '>'))
      # 다운로드: 상세 HTML·PNG
      Invoke-Js "KTS.goTab('tabDetail')" | Out-Null
      $f = Dl '#btnHtml' '상세_*.html'
      if ($f) { $txt = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8) -replace 'src="data:[^"]+"', ''; $ch = CustHits $txt; $pg = ([regex]::Matches($txt, 'class="pg ')).Count }
      Chk '쿠팡' 'G2 상세 HTML 원가·도매가·매입가·마진·수수료·전화 0건' ($f -and $ch -eq 0) $(if ($f) { "$($f.Name) $($f.Length)B · 금지 $ch 건 · 블록 $pg" } else { '다운로드 없음' })
      $f = Dl '#btnPng' '상세_*.png'
      $pw = 0; $phh = 0
      if ($f) { Add-Type -AssemblyName System.Drawing; $im = [System.Drawing.Image]::FromFile($f.FullName); $pw = $im.Width; $phh = $im.Height; $im.Dispose() }
      Chk '쿠팡' '상세 PNG 파일 System.Drawing 실측' ($pw -eq 780 -and $phh -gt 0 -and $phh -le 12000) $(if ($f) { "$($f.Name) $pw×$phh $($f.Length)B" } else { '다운로드 없음' })
      if ($f) { Copy-Item $f.FullName (Join-Path $global:BASE 'shots\상세_예시_방수테이프.png') -Force }
      Chk '쿠팡' 'G2 상세 PNG 문구 원가·마진·전화 0건' ($r.cust.ban.Count -eq 0 -and $r.cust.phone -eq 0) ("ban=" + ($r.cust.ban -join ',') + " phone=$($r.cust.phone)")
      # 적자 잠금
      Invoke-Js "KTS.goTab('tabMargin')" | Out-Null
      $low = [math]::Floor($r.margin.be) - 100
      Invoke-Js ("document.querySelector('#inTry').value='" + $low + "'; document.querySelector('#btnTry').click(); 1") | Out-Null
      Start-Sleep -Milliseconds 300
      $lk = J "(function(){var rs=[].slice.call(document.querySelectorAll('#marginTable tr')).filter(function(t){return /직접 입력/.test(t.textContent)}); if(!rs.length) return null; var r=rs[0]; return {loss:r.classList.contains('loss'), dis:!!r.querySelector('button[disabled]'), en:r.querySelectorAll('button:not([disabled])').length};})()"
      Chk '쿠팡' '손익분기가 아래 가격 잠금' ($lk -and $lk.loss -and $lk.dis -and $lk.en -eq 0) ("시험가 $low 원 < 손익분기 $([math]::Ceiling($r.margin.be)) · 빨간줄 $($lk.loss) · 비활성버튼 $($lk.dis) · 눌리는버튼 $($lk.en)")
      $f = Dl '#btnMarginCsv' '쿠팡_마진표_*.csv'
      Chk '쿠팡' '마진표 CSV 받기(BOM)' ($f -and (Bom $f.FullName)) $(if ($f) { "$($f.Name) $($f.Length)B BOM=$(Bom $f.FullName)" } else { '다운로드 없음' })
      # 등록 파일
      Invoke-Js "KTS.goTab('tabExcel')" | Out-Null
      $f = Dl '#btnXlsx' '쿠팡_Wing등록_*.xlsx'
      $x = if ($f) { Xlsx $f.FullName } else { @{ ok = $false } }
      Chk '쿠팡' 'Wing 엑셀 Expand-Archive·15열×1행·한글' ($x.ok -and $x.rows -eq 2 -and $x.c1 -eq 15 -and $x.c2 -ge 12 -and $x.ko) $(if ($f) { "$($f.Name) · 행 $($x.rows)(머리+1) · 머리 $($x.c1)칸 · 값 $($x.c2)칸(빈칸 제외) · 한글 $($x.ko) $($x.err)" } else { '다운로드 없음' })
      $f = Dl '#btnCsv' '쿠팡_Wing등록_*.csv'
      Chk '쿠팡' 'Wing CSV BOM(EF BB BF)' ($f -and (Bom $f.FullName)) $(if ($f) { "$($f.Name) BOM=$(Bom $f.FullName)" } else { '다운로드 없음' })
      $f = Dl '#btnPs1' 'upload_coupang*.ps1'
      $ps1ok = $false; if ($f) { $pt = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8); $ps1ok = ($pt -match 'COUPANG_SECRET_KEY') -and ($pt -match '\[switch\]\$Send') -and -not ($pt -match 'AIza|sk-[A-Za-z0-9]{16}') }
      Chk '쿠팡' '업로드 스크립트 받기(환경변수·-Send·키 0)' $ps1ok $(if ($f) { "$($f.Name) $($f.Length)B" } else { '다운로드 없음' })
      # 서명 일치: 브라우저 == PowerShell (2벡터)
      $vec = @(
        @{ sd = '261120T000000Z'; m = 'POST'; p = '/v2/providers/seller_api/apis/api/v1/marketplace/seller-products'; q = ''; k = 'kts-test-secret' },
        @{ sd = '261120T093015Z'; m = 'GET'; p = '/v2/providers/seller_api/apis/api/v1/marketplace/seller-products/1234567'; q = 'vendorId=A00012345'; k = 'another-secret-0123456789' }
      )
      $vi = 0
      foreach ($v in $vec) {
        $vi++
        $bs = Invoke-Js ("coupangSign('" + $v.k + "','" + $v.sd + "','" + $v.m + "','" + $v.p + "','" + $v.q + "').signature")
        $hm = New-Object System.Security.Cryptography.HMACSHA256 (, [Text.Encoding]::UTF8.GetBytes($v.k))
        $ps = -join ($hm.ComputeHash([Text.Encoding]::UTF8.GetBytes($v.sd + $v.m + $v.p + $v.q)) | ForEach-Object { $_.ToString('x2') })
        $env:COUPANG_SECRET_KEY = $v.k; $env:COUPANG_ACCESS_KEY = 'test-access'
        $upArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'upload_coupang.ps1'), '-SignedDate', $v.sd, '-Method', $v.m, '-Path', $v.p)
        if ($v.q) { $upArgs += @('-Query', $v.q) }
        $up = & powershell @upArgs
        $env:COUPANG_SECRET_KEY = $null; $env:COUPANG_ACCESS_KEY = $null
        $us = (($up | Where-Object { $_ -like 'SIGNATURE=*' }) -replace '^SIGNATURE=', '')
        Chk '쿠팡' ("서명 일치 벡터$vi 브라우저==PowerShell==upload_coupang.ps1") ($bs -eq $ps -and $ps -eq $us -and $bs.Length -eq 64) ("$($v.m) · 브라우저 $bs · PS $ps · ps1 $us")
        if ($vi -eq 1) { $global:SIG1 = $bs }
      }
      Clear-Dl; $n0 = Invoke-Js "window.__copies.length"; Click '#btnCopy' | Out-Null; Start-Sleep -Milliseconds 300; $n1 = Invoke-Js "window.__copies.length"
      Chk '쿠팡' '[이 탭 복사] 동작' ($n1 -gt $n0) ("복사 기록 $n0 → $n1")
    }
    $m = $r.margin
    foreach ($row in $m.rows) {
      $P = [double]$row.price
      $fee = JR ($P * $m.rate); $vat = if ($m.vatOn) { JR ($P / 11) } else { 0 }; $rv = JR ($P * $m.ret)
      $pf = $P - $m.cost - $m.ship - $fee - $vat - $rv
      $marginRows += [pscustomobject]@{ s = $s; label = $row.label; P = $P; js = $row.profit; ps = $pf; diff = [math]::Abs($pf - $row.profit); lock = $row.lock; be = $m.be }
    }
  }
  $bad = @($marginRows | Where-Object { $_.diff -gt 1 }).Count
  Chk '쿠팡' '마진표 손계산 ±1원 (샘플3×가격3=9행)' ($marginRows.Count -eq 9 -and $bad -eq 0) (($marginRows | ForEach-Object { "s$($_.s) $($_.P)원 순익 JS $($_.js)/PS $($_.ps)" }) -join ' · ')
  $badLock = @($marginRows | Where-Object { ($_.P -lt $_.be) -and -not $_.lock }).Count
  Chk '쿠팡' '3단 가격 모두 손익분기가 이상(잠금 규칙 위반 0)' ($badLock -eq 0) ("위반 $badLock")

  # ================= 과업 2 네이버 =================
  $d = Open-Sample 'naver.html?sample=1&auto=1'
  $r = J "window.__res"; $c = Common 'naver'
  Chk '네이버' '자동 완주·오류0·390·외부요청0' ($d -and $c.errs -eq 0 -and $c.sw -eq 390 -and $c.net -eq 0) ("done=$d · 오류 $($c.errs) · sw $($c.sw) · fetch $($c.net)")
  $t = @($r.titles)
  Chk '네이버' '상품명 3안 ≤100자·중복0·금지어0·메인키워드 포함' (@($t | Where-Object { $_.len -le 100 -and $_.dup -eq 0 -and $_.ban -eq 0 -and $_.kw -eq 1 }).Count -eq 3) (($t | ForEach-Object { "$($_.len)자(권장50)" }) -join ', ')
  Chk '네이버' '메인3+세부10+태그10=23·중복0·태그≤20자' (@($r.mains).Count -eq 3 -and @($r.details).Count -eq 10 -and @($r.tags).Count -eq 10 -and $r.all23 -eq 23 -and $r.uniq23 -eq 23 -and $r.tagMaxLen -le 20) ("메인 $(@($r.mains).Count) · 세부 $(@($r.details).Count) · 태그 $(@($r.tags).Count) · 고유 $($r.uniq23)/23 · 태그최장 $($r.tagMaxLen)자")
  $sc = $r.score
  $hand = $(if ($sc.titleHasKw) { 30 } else { 0 }) + $(if ($sc.dup -eq 0) { 15 } else { 0 }) + (JR (15 * $sc.filled / 10)) + $(if ($sc.firstHasKw) { 20 } else { 0 }) + $(if ($sc.titleLen -le 50) { 10 } elseif ($sc.titleLen -le 100) { 5 } else { 0 }) + $(if ($sc.banN -eq 0) { 10 } else { 0 })
  $reasons = Invoke-Js "document.querySelector('#tabSeo').textContent.indexOf('감점')>=0"
  Chk '네이버' 'SEO 점수 손계산 일치 + 감점 사유 표시' ($hand -eq $sc.total -and $reasons) ("화면 $($sc.total)점 · 손계산 $hand 점 (항목 " + ($sc.items -join '+') + ") · 감점사유 표시 $reasons")
  Chk '네이버' '상세 스토리 7블록 순서 고정·빈 블록 0' ((($r.story -join '>') -eq 'promise>why>scenes>spec>ship>faq>closing') -and $r.storyEmpty -eq 0) (($r.story -join '>') + " · 빈 블록 $($r.storyEmpty)")
  Chk '네이버' 'G2 상세 스토리 원가·마진·전화 0건' ($r.cust.ban.Count -eq 0 -and $r.cust.phone -eq 0) ("ban=" + ($r.cust.ban -join ',') + " phone=$($r.cust.phone)")
  $api = J "(function(){var b=document.querySelector('#btnApi'); return b?{dis:b.disabled, t:b.textContent}:null})()"
  Chk '네이버' '[API 업로드 — 준비 중(서버 필요)] 비활성' ($api -and $api.dis) $(if ($api) { "$($api.t) disabled=$($api.dis)" } else { '버튼 없음' })
  Invoke-Js "KTS.goTab('tabExcel')" | Out-Null
  $f = Dl '#btnXlsx' '스마트스토어_등록_*.xlsx'
  $x = if ($f) { Xlsx $f.FullName } else { @{ ok = $false } }
  Chk '네이버' '등록 엑셀 11열×1행·한글' ($x.ok -and $x.rows -eq 2 -and $x.c1 -eq 11 -and $x.ko) $(if ($f) { "$($f.Name) · 행 $($x.rows) · 머리 $($x.c1)칸 · 값 $($x.c2)칸" } else { '다운로드 없음' })
  $f = Dl '#btnCsv' '스마트스토어_등록_*.csv'
  Chk '네이버' '등록 CSV BOM' ($f -and (Bom $f.FullName)) $(if ($f) { "$($f.Name) BOM=$(Bom $f.FullName)" } else { '다운로드 없음' })
  $d = Open-Sample 'naver.html?sample=1&auto=1&nophoto=1'
  $r2 = J "window.__res"
  Chk '네이버' '사진 없이도 스토리 빈 블록 0·회색박스 0' ($d -and $r2.storyEmpty -eq 0 -and $r2.photos -eq 0 -and (Invoke-Js "document.querySelectorAll('#tabStory img').length") -eq 0) ("사진 $($r2.photos) · 빈 블록 $($r2.storyEmpty)")

  # ================= 과업 3 역직구 =================
  $d = Open-Sample 'global.html?sample=1&auto=1'
  $r = J "window.__res"; $c = Common 'global'
  Chk '역직구' '자동 완주·오류0·390·외부요청0' ($d -and $c.errs -eq 0 -and $c.sw -eq 390 -and $c.net -eq 0) ("done=$d · 오류 $($c.errs) · sw $($c.sw) · fetch $($c.net)")
  $k = $r.copy
  Chk '역직구' '3개국 문구 AI 키 0으로 생성(템플릿)' ($k.usTitle -gt 0 -and @($k.usBullets).Count -eq 5 -and $k.usDesc -eq 3 -and $k.jpCatch -eq 3 -and $k.jpKeywords -eq 10 -and $k.jpDesc -gt 0 -and $k.seaDesc -eq 3 -and $k.seaTags -eq 8) ("미국 제목·불릿$(@($k.usBullets).Count)·설명$($k.usDesc)·검색어 / 일본 제목·캐치$($k.jpCatch)·설명·키워드$($k.jpKeywords) / 쇼피 제목·설명$($k.seaDesc)·태그$($k.seaTags)")
  $bl = @($k.usBullets | Where-Object { $_ -gt 200 }).Count
  Chk '역직구' '글자/바이트 한도(미국200·불릿200·일본60·쇼피120·검색어250B)' ($k.usTitle -le 200 -and $bl -eq 0 -and $k.jpTitle -le 60 -and $k.seaTitle -le 120 -and $k.usSearchBytes -le 250) ("미국 $($k.usTitle)자 · 불릿 " + ($k.usBullets -join '/') + " · 일본 $($k.jpTitle)자 · 쇼피 $($k.seaTitle)자 · 검색어 $($k.usSearchBytes)B")
  Chk '역직구' '과장어0·이모지0·Made in Korea 표기' ($k.banEn -eq 0 -and $k.banJa -eq 0 -and $k.emoji -eq 0 -and $k.origin -eq 'Made in Korea 표기') ("과장어 EN $($k.banEn)/JA $($k.banJa) · 이모지 $($k.emoji) · $($k.origin)")
  $gRows = @(); $usBad = 0; $usN = 0
  foreach ($m in $r.margin) {
    foreach ($row in $m.rows) {
      if ($row.label -eq '입력 가격') { continue }
      $P = [double]$row.price; $won = JR ($P * $m.fx); $fee = JR ($won * $m.rate); $pay = JR ($won * $m.pay)
      $ex = $false
      if ($m.c -eq 'jp') { $ex = ($m.exempt -gt 0 -and $P * 0.6 -le $m.exempt) } elseif ($m.c -eq 'sea') { $ex = ($m.exempt -gt 0 -and $P -le $m.exempt) }
      if ($m.c -eq 'jp') { $tx = if ($ex) { 0 } else { JR ([math]::Max(0, $won - $m.ship) * 0.6) } } else { $tx = if ($ex) { 0 } else { $won } }
      $du = JR ($tx * $m.duty); $va = JR (($tx + $du) * $m.vat); $rt = JR ($won * $m.ret)
      $pf = $won - $m.cost - $m.ship - $fee - $pay - $du - $va - $rt
      $gRows += [pscustomobject]@{ c = $m.c; P = $P; js = $row.profit; ps = $pf; diff = [math]::Abs($pf - $row.profit); ex = $row.exempt; lock = $row.lock; be = $m.be }
      if ($m.c -eq 'us') { $usN++; if ($row.exempt -or $row.duty -le 0) { $usBad++ } }
    }
  }
  Chk '역직구' '마진표 손계산 ±1원 (3개국×3가격=9행)' ($gRows.Count -eq 9 -and @($gRows | Where-Object { $_.diff -gt 1 }).Count -eq 0) (($gRows | ForEach-Object { "$($_.c) $($_.P) 순익 JS $($_.js)/PS $($_.ps)" }) -join ' · ')
  Chk '역직구' '미국 면세 적용 0건(모든 가격 관세 반영)' ($usN -ge 3 -and $usBad -eq 0) ("미국 행 $usN · 면세/관세0 행 $usBad")
  $seaEx = @($gRows | Where-Object { $_.c -eq 'sea' -and $_.ex }).Count
  Chk '역직구' '쇼피 면세 없음 기본' ($seaEx -eq 0 -and ($r.margin | Where-Object { $_.c -eq 'sea' }).exempt -eq 0) ("쇼피 면세 행 $seaEx · 한도 $(($r.margin | Where-Object { $_.c -eq 'sea' }).exempt)")
  Chk '역직구' '3단 가격 손익분기 잠금 위반 0' (@($gRows | Where-Object { $_.P -lt $_.be -and -not $_.lock }).Count -eq 0) ("위반 0 기준 · 손익분기 " + (($r.margin | ForEach-Object { "$($_.c) " + [math]::Round($_.be, 2) }) -join ', '))
  Chk '역직구' '제도 안내 출처 URL 3·확인일 3·바뀝니다 고지' ($r.rules.urls -eq 3 -and $r.rules.checked -eq 3 -and $r.rules.notice) ("URL $($r.rules.urls) · 확인일 $($r.rules.checked) · 고지 $($r.rules.notice)")
  Invoke-Js "KTS.goTab('tabExcel')" | Out-Null
  $xs = @()
  foreach ($p in @(@{ id = 'us'; pat = '아마존_등록_*.xlsx'; cols = 14 }, @{ id = 'jp'; pat = '라쿠텐큐텐_등록_*.xlsx'; cols = 7 }, @{ id = 'sea'; pat = '쇼피_등록_*.xlsx'; cols = 8 })) {
    $f = Dl ('#xl_' + $p.id) $p.pat; $x = if ($f) { Xlsx $f.FullName } else { @{ ok = $false; c1 = 0; rows = 0 } }
    $xs += [pscustomobject]@{ id = $p.id; ok = ($x.ok -and $x.rows -eq 2 -and $x.c1 -eq $p.cols); ev = "$($p.id) $($x.c1)/$($p.cols)열 행$($x.rows)" }
  }
  Chk '역직구' '등록 엑셀 3종(아마존14·라쿠텐큐텐7·쇼피8열)' (@($xs | Where-Object { $_.ok }).Count -eq 3) (($xs | ForEach-Object { $_.ev }) -join ' · ')
  $f = Dl '#csv_jp' '라쿠텐큐텐_등록_*.csv'
  Chk '역직구' '등록 CSV BOM' ($f -and (Bom $f.FullName)) $(if ($f) { "$($f.Name) BOM=$(Bom $f.FullName)" } else { '다운로드 없음' })
  # 일본 16,666엔 경계 자동 판정
  $d = Open-Sample 'global.html?sample=1&auto=1&jpy=16660'
  $a = J "window.__res.margin[1].rows.filter(function(x){return x.label==='입력 가격'})[0]"
  $d = Open-Sample 'global.html?sample=1&auto=1&jpy=16670'
  $b = J "window.__res.margin[1].rows.filter(function(x){return x.label==='입력 가격'})[0]"
  $red = Invoke-Js "[].slice.call(document.querySelectorAll('#tabMargin .redline')).some(function(e){return /면세가 깨집니다/.test(e.textContent)})"
  Chk '역직구' '일본 16,666엔 경계 자동 판정 + 빨간 경고' ($a.exempt -and -not $b.exempt -and $b.breaks -and $b.duty -gt 0 -and $red) ("16,660엔 면세=$($a.exempt)(관세 $($a.duty)) · 16,670엔 면세=$($b.exempt)(과세가격 $($b.taxable)·관세 $($b.duty)·소비세 $($b.vat)) · 경고 $red")
  # 적자 잠금(입력 가격 5달러)
  Invoke-Js "document.querySelector('#pr_us').value='5'; document.querySelector('#btnGo').click(); 1" | Out-Null
  Start-Sleep -Milliseconds 500
  $u = J "window.__res.margin[0].rows.filter(function(x){return x.label==='입력 가격'})[0]"
  $dis = Invoke-Js "(function(){var t=[].slice.call(document.querySelectorAll('#mt_us tr')).filter(function(r){return /입력 가격/.test(r.textContent)})[0]; return !!t && t.classList.contains('loss') && !!t.querySelector('button[disabled]') && !t.querySelector('button:not([disabled])');})()"
  Chk '역직구' '손익분기가 아래 입력가 잠금' ($u.lock -and $dis) ("USD 5 → 순익 $($u.profit)원 · lock $($u.lock) · 버튼 잠김 $dis")
  $d = Open-Sample 'global.html?sample=1&auto=1&s=1'
  $o = J "window.__res.copy.origin"
  Chk '역직구' '원산지 한국 아님 → Made in Korea 허위표기 0' ($o -like '*Shipped*') ("손난로(중국 OEM): $o")

  # ================= 과업 4 블로그 =================
  $d = Open-Sample 'blog.html?sample=1&auto=1'
  $r = J "window.__res"; $c = Common 'blog'
  Chk '블로그' '자동 완주(샘플 사진 1장)·오류0·390·외부요청0' ($d -and $c.errs -eq 0 -and $c.sw -eq 390 -and $c.net -eq 0) ("done=$d · 직접넣기 $($r.direct) · 오류 $($c.errs) · sw $($c.sw) · fetch $($c.net)")
  $bn = $r.bone
  $six = (($bn.subs -is [int] -or $bn.subs -is [long] -or $bn.subs -is [double]) -and $bn.paras -ge 1 -and $bn.avgLen -ge 1 -and $bn.photos -ge 0 -and $bn.kw -ge 0 -and $bn.close)
  Chk '블로그' '상위 글 5편 → 뼈대 6항목 숫자' ($r.extN -eq 5 -and $six) ("도입 $($bn.first) · 소제목 $($bn.subs) · 문단 $($bn.paras) · 호흡 $($bn.avgLen)자 · 사진 $($bn.photos) · 키워드 $($bn.kw) · 마무리 $($bn.close)")
  Chk '블로그' '6어절 연속 일치 0건' ($r.plag.hit -eq 0 -and $r.plagOther.hit -eq 0) ("이 톤 $($r.plag.hit)/$($r.plag.grams)묶음 · 다른 톤 $($r.plagOther.hit)/$($r.plagOther.grams) · 기준 $($r.plag.refGrams)묶음")
  $st = $r.stats; $so = $r.otherStats
  Chk '블로그' '원고 1,200~1,800자·키워드3~5·금지어0 (두 톤)' ($st.chars -ge 1200 -and $st.chars -le 1800 -and $st.kw -ge 3 -and $st.kw -le 5 -and $st.ban -eq 0 -and $so.chars -ge 1200 -and $so.chars -le 1800 -and $so.kw -ge 3 -and $so.kw -le 5 -and $so.ban -eq 0) ("톤1 $($st.chars)자·키워드$($st.kw)·금지$($st.ban) / 톤2 $($so.chars)자·키워드$($so.kw)·금지$($so.ban)")
  Chk '블로그' '소제목3~5·문단 2~4문장·첫 문단 키워드' ($st.heads -ge 3 -and $st.heads -le 5 -and $st.paraMin -ge 2 -and $st.paraMax -le 4 -and $st.firstKw) ("소제목 $($st.heads) · 문장 $($st.paraMin)~$($st.paraMax) · 첫문단 $($st.firstKw)")
  Chk '블로그' '두 톤 같은 문장 0건' ($r.toneSame -eq 0) ("같은 문장 $($r.toneSame) / $($r.sentences)문장")
  Chk '블로그' 'G2 원고 원가·마진·전화 0건' ($st.cust.ban.Count -eq 0 -and $st.cust.phone -eq 0) ("ban=" + ($st.cust.ban -join ',') + " phone=$($st.cust.phone)")
  $tx = J "{a:document.querySelector('#btnAuto').textContent, at:document.querySelector('#autoTxt').textContent, d:document.querySelector('#btnDirect').textContent, dt:document.querySelector('#directTxt').textContent}"
  $exact = ($tx.a -eq '[ 완전 자동 ]' -and $tx.at -eq '사진 없이도 글 완성 (사진 자리는 표시만)' -and $tx.d -eq '[ 직접 넣기 (추천) ]' -and $tx.dt -eq '검색 노출 효과가 훨씬 크고 봇 차단(저품질) 위험이 0%입니다')
  Chk '블로그' '투트랙 두 버튼 + 안내 문구 글자 단위 일치' $exact ("'$($tx.a)' '$($tx.at)' / '$($tx.d)' '$($tx.dt)'")
  Invoke-Js "KTS.goTab('tabDraft')" | Out-Null
  Click '#btnFmt' | Out-Null; Start-Sleep -Milliseconds 300
  $fm = J "{f:window.__fmt, c:window.__copies[window.__copies.length-1]}"
  Chk '블로그' '[서식 그대로 복사] 소제목≥3·줄바꿈 유지' ($fm.f.h3 -ge 3 -and $fm.f.lines -ge 10 -and $fm.c.len -gt 0 -and $fm.c.html -gt 0) ("h3 $($fm.f.h3) · 줄 $($fm.f.lines) · 글자 $($fm.c.len) · HTML $($fm.c.html)")
  $d = Open-Sample 'blog.html?sample=1&nophoto=1&notop=1'
  $lock = J "{d:document.querySelector('#btnDirect').disabled, l:getComputedStyle(document.querySelector('#directLock')).display}"
  Chk '블로그' '사진 0장이면 [직접 넣기] 잠금' ($lock.d -and $lock.l -ne 'none') ("disabled=$($lock.d) · 안내 표시 $($lock.l)")
  Click '#btnAuto' | Out-Null; $ok = Wait-For "window.__done===true" 10000
  $r = J "window.__res"
  Chk '블로그' '상위 글 없이 기본 뼈대로 [완전 자동] 생성' ($ok -and $r.extN -eq 0 -and -not $r.direct -and $r.stats.chars -ge 1200 -and $r.stats.chars -le 1800 -and $r.stats.kw -ge 3 -and $r.stats.kw -le 5) ("extN $($r.extN) · $($r.stats.chars)자 · 키워드 $($r.stats.kw) · 사진자리 $($r.stats.photos)")

  # ================= 과업 5 인스타 =================
  $d = Open-Sample 'insta.html?sample=1&auto=1'
  $r = J "window.__res"; $c = Common 'insta'
  Chk '인스타' '자동 완주·오류0·390·외부요청0' ($d -and $c.errs -eq 0 -and $c.sw -eq 390 -and $c.net -eq 0) ("done=$d · 오류 $($c.errs) · sw $($c.sw) · fetch $($c.net)")
  $h = @($r.hooks)
  Chk '인스타' '첫 줄 3안 ≤40자·서로 다름·이모지≤1·첫12자 핵심' ($h.Count -eq 3 -and @($h | Where-Object { $_.len -le 40 -and $_.emoji -le 1 -and $_.head12 }).Count -eq 3 -and @($h | ForEach-Object { $_.t } | Select-Object -Unique).Count -eq 3) (($h | ForEach-Object { "$($_.k) $($_.len)자" }) -join ' · ')
  $tg = @($r.tags)
  $gc = @{}; foreach ($g in $r.groups) { $gc[$g] = 1 + [int]$gc[$g] }
  Chk '인스타' '해시태그 25·중복0·#포함·각≤20자·대5/중10/소·지역10' ($tg.Count -eq 25 -and @($tg | Select-Object -Unique).Count -eq 25 -and @($tg | Where-Object { $_ -notlike '#*' -or $_.Length -gt 20 }).Count -eq 0 -and $gc['대형'] -eq 5 -and $gc['중형'] -eq 10 -and ([int]$gc['소형'] + [int]$gc['지역']) -eq 10) ("개수 $($tg.Count) · 대형 $($gc['대형']) · 중형 $($gc['중형']) · 소형 $([int]$gc['소형']) · 지역 $([int]$gc['지역'])")
  Chk '인스타' '본문 350~700자·문단3~5·금지어0' ($r.bodyLen -ge 350 -and $r.bodyLen -le 700 -and $r.paras -ge 3 -and $r.paras -le 5 -and $r.bodyBan -eq 0) ("$($r.bodyLen)자 · $($r.paras)문단 · 금지어 $($r.bodyBan)")
  Chk '인스타' 'G2 원고 원가·마진·전화 0건' ($r.cust.ban.Count -eq 0 -and $r.cust.phone -eq 0) ("ban=" + ($r.cust.ban -join ',') + " phone=$($r.cust.phone)")
  Click '#btnCopy' | Out-Null; Start-Sleep -Milliseconds 300
  $fu = J "(function(){var t=window.__full.text, r=window.__res; var a=t.indexOf(r.hooks[0].t), b=t.indexOf(document.querySelector('#bodyBox p').textContent), c=t.indexOf(r.tags[0]); return {len:t.length,a:a,b:b,c:c};})()"
  Chk '인스타' '[전체 복사] ①첫줄→②본문→③해시태그 순서' ($fu.a -eq 0 -and $fu.b -gt $fu.a -and $fu.c -gt $fu.b) ("길이 $($fu.len) · 위치 ① $($fu.a) < ② $($fu.b) < ③ $($fu.c)")
  $code = [IO.File]::ReadAllText((Join-Path $global:BASE 'insta.html'), [Text.Encoding]::UTF8)
  $auto = ([regex]::Matches($code, '(?i)login|graph\.(instagram|facebook)|media_publish|instagram\.com/(api|accounts)|fetch\(|XMLHttpRequest|sendBeacon|follow\(|like\(')).Count
  Chk '인스타' '코드에 로그인·발행·API 호출 0건(grep)' ($auto -eq 0) ("grep 일치 $auto 건")
  $hl = Invoke-Js "document.querySelector('#humanLine').textContent"
  Chk '인스타' '업로드만 사람 안내 1줄' ($hl -eq '업로드 버튼만 사람이 누릅니다 — 계정 정지 위험 0%') $hl
} finally { Stop-CdpChrome }

$fail = @($ALL | Where-Object { $_.v -eq 'FAIL' }).Count
$pass = @($ALL | Where-Object { $_.v -eq 'PASS' }).Count
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('## verify.ps1 — 상품별 완료 판정 (' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ', 헤드리스 크롬 390×844, 새 프로필)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| # | 도구 | 항목 | 판정 | 근거(원문 숫자) |')
[void]$sb.AppendLine('|---|---|---|---|---|')
foreach ($x in $ALL) { [void]$sb.AppendLine('| ' + $x.n + ' | ' + $x.t + ' | ' + $x.i + ' | ' + $x.v + ' | ' + ($x.e -replace '\|', '/' -replace "`r?`n", ' ') + ' |') }
[void]$sb.AppendLine('')
[void]$sb.AppendLine("합계: PASS $pass · FAIL $fail (항목 " + $ALL.Count + ")")
[void]$sb.AppendLine('AI 호출: [대역] — 열쇠 없음, 모든 결과는 규칙 엔진(키 0). 쿠팡 실제 업로드: [대역] — 키 없음, 서명 일치 시험만.')
[IO.File]::WriteAllText((Join-Path $global:BASE 'shots\_verify.txt'), $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
. "$PSScriptRoot\measure.ps1"
Build-Measure $global:BASE
Write-Output ("verify: PASS $pass · FAIL $fail (항목 " + $ALL.Count + ")")
exit $fail

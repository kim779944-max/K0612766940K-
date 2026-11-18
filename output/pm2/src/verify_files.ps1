# 만든 xlsx·hwpx를 (1) ZIP을 직접 풀어 XML 값·수식 확인, (2) 더뷰(viewer.html)로 다시 열어 화면 글자 확인 + 캡처
. "$PSScriptRoot\pmlib.ps1"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$checks = @(
  @{ app = 'expense'; file = '지출결의서_11월영업팀경비_20261118.xlsx'; expect = @('지출결의서', '11월 영업팀 경비', '김민수 / 영업팀', '한빛식당', 'KTS문구', '서울택시', '43636', '4364', '48000', '120000', '12000', '132000', '15800', '179436', '16364', '195800', 'receipt_1_한빛식당.jpg'); formulas = @('H6-G6', 'H7-G7', 'H8-G8', 'SUM(F6:F8)', 'SUM(G6:G8)', 'SUM(H6:H8)') },
  @{ app = 'expense'; file = '지출결의서_출장.xlsx'; expect = @('출장비 지출결의서', '부산 해운대', '2026-11-10 ~ 2026-11-11', '거래처 설비 점검', '195800'); formulas = @('SUM(H') },
  @{ app = 'expense'; file = '지출결의서_접대.xlsx'; expect = @('접대비 지출결의서', '(주)한빛상사 김부장 외 1명', '3명', '연간 납품 계약 협의', '195800'); formulas = @('SUM(H') },
  @{ app = 'quote'; file = '견적서_2026-0001.hwpx'; expect = @('견 적 서', '견적번호: 2026-0001', '(주)한빛상사 귀하', 'KTS인테리어', '123-45-67890', '강화마루 시공', '1,485,000', '320,000', '1,955,000', '195,500', '2,150,500', '일금 이백일십오만오백원정', '2026년 12월 18일까지'); formulas = @() },
  @{ app = 'quote'; file = '견적서_2026-0003.hwpx'; expect = @('견적번호: 2026-0003', '박서준 귀하', '욕실 타일 보수', '500,000', '60,000', '560,000', '56,000', '616,000'); formulas = @() }
)
function ZipText([string]$path) {
  $z = [IO.Compression.ZipFile]::OpenRead($path); $sb = New-Object Text.StringBuilder; $raw = New-Object Text.StringBuilder; $names = @()
  try { foreach ($e in $z.Entries) { $names += $e.FullName; if ($e.FullName -match '(section\d+|sheet\d+|sharedStrings|workbook)\.xml$') { $r = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::UTF8); $t = $r.ReadToEnd(); $r.Close(); [void]$raw.Append($t); [void]$sb.Append($t) } } } finally { $z.Dispose() }
  $t = [regex]::Replace($sb.ToString(), '<[^>]+>', ' ')
  return @{ text = [Net.WebUtility]::HtmlDecode($t); raw = $raw.ToString(); names = $names }
}
$res = @()
Open-App 'oneclick\viewer.html' 9358
try {
  foreach ($c in $checks) {
    $dir = Join-Path $global:PM2 $c.app
    $p = Join-Path $dir (Join-Path 'files' $c.file)
    $x = ZipText $p
    $zipMiss = @($c.expect | Where-Object { $x.text -notlike ('*' + $_ + '*') })
    $fMiss = @($c.formulas | Where-Object { $x.raw -notlike ('*<f>' + $_ + '*') })
    $fCount = ([regex]::Matches($x.raw, '<f>')).Count
    Nav 'oneclick\viewer.html'
    Set-FileInput '#f' @($p)
    Start-Sleep -Milliseconds 2500
    $vt = Js 'return document.body.innerText'
    # 엑셀 숫자 칸은 더뷰가 천 단위 쉼표(#,##0)로 보여 준다 → 43636 은 화면에서 43,636 으로 확인
    $viewMiss = @($c.expect | Where-Object { ($vt -notlike ('*' + $_ + '*')) -and -not (($_ -match '^\d{4,}$') -and ($vt -like ('*' + ('{0:N0}' -f [long]$_) + '*'))) })
    $shot = 'open_' + [IO.Path]::GetFileNameWithoutExtension($c.file) + '_' + [IO.Path]::GetExtension($c.file).TrimStart('.')
    Save-Screenshot (Join-Path $dir ($shot + '.png'))
    $errs = Js 'return JSON.stringify(window.__errs)'
    $ok = ($zipMiss.Count -eq 0) -and ($fMiss.Count -eq 0) -and ($viewMiss.Count -eq 0) -and ($errs -eq '[]')
    $res += [pscustomobject]@{ file = $c.file; bytes = (Get-Item $p).Length; zipEntries = $x.names.Count; formulas = $fCount; zipMissing = ($zipMiss -join '|'); formulaMissing = ($fMiss -join '|'); viewerMissing = ($viewMiss -join '|'); viewerErrors = $errs; shot = $shot + '.png'; result = $(if ($ok) { 'PASS' } else { 'FAIL' }) }
  }
} finally { Stop-CdpChrome }
$res | Format-Table file, bytes, zipEntries, formulas, zipMissing, formulaMissing, viewerMissing, viewerErrors, result -AutoSize | Out-String -Width 260
$res | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $global:PM2 'verify_open.json')

# 만든 hwpx·xlsx 파일을 (1) 더뷰(viewer.html)로 다시 열어 화면 캡처 + 값 확인, (2) ZIP을 직접 풀어 XML 안의 값 확인
# 인쇄 레이아웃은 print 매체 흉내로 A4 폭 캡처
. "$PSScriptRoot\lib.ps1"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$base = (Resolve-Path "$PSScriptRoot\..\..").Path
$checks = @(
  @{ dir = 'theform_20261118'; file = '거래명세서_기본.hwpx'; expect = @('(주)한빛상사', 'A4 복사용지', '77,000', '48,000', '김민수') },
  @{ dir = 'theform_20261118'; file = '거래명세서_기본.xlsx'; expect = @('(주)한빛상사', 'A4 복사용지', '77000', '48000', '김민수') },
  @{ dir = 'theform_20261118'; file = '근로계약서_기본.hwpx'; expect = @('KTS 카페', '최지우', '2,200,000', '09:00 ~ 18:00', '(서명)') },
  @{ dir = 'theform_20261118'; file = '근로계약서_기본.xlsx'; expect = @('KTS 카페', '최지우', '2200000', '09:00 ~ 18:00') },
  @{ dir = 'theform_20261118'; file = '방문신청서_내양식.hwpx'; expect = @('방문 신청서', '박서준', '010-2345-6789', '2026년 11월 20일', '설비 점검 협의') },
  @{ dir = 'theform_20261118'; file = '방문신청서_내양식.xlsx'; expect = @('방문 신청서', '박서준', '010-2345-6789', '2026년 11월 20일', '설비 점검 협의') },
  @{ dir = 'contract_20261118'; file = '매매계약서_샘플.hwpx'; expect = @('부동산 매매계약서', '김매도', '이매수', '금 팔억오천만 원정', '금 사억육천오백만 원정', '2027년 1월 17일', '본 서식은 작성 보조용') },
  @{ dir = 'contract_20261118'; file = '주택임대차계약서_샘플.hwpx'; expect = @('주택 임대차계약서 (월세)', '박임대', '정임차', '금 오천만 원정', '금 일백이십만 원정', '2026년 12월 9일', '본 서식은 작성 보조용') },
  @{ dir = 'contract_20261118'; file = '상가임대차계약서_샘플.hwpx'; expect = @('상가건물 임대차계약서', '(주)KTS빌딩', '한카페', '금 삼천만 원정', '금 이백오십만 원정', '관리비 월', '업종: 카페', '본 서식은 작성 보조용') }
)
$res = @()
function XmlText([string]$path) {
  $z = [IO.Compression.ZipFile]::OpenRead($path); $sb = New-Object Text.StringBuilder; $names = @()
  try { foreach ($e in $z.Entries) { $names += $e.FullName; if ($e.FullName -match '(section\d+|sheet\d+|sharedStrings)\.xml$') { $r = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::UTF8); [void]$sb.Append($r.ReadToEnd()); $r.Close() } } } finally { $z.Dispose() }
  $t = [regex]::Replace($sb.ToString(), '<[^>]+>', ' ')
  return @{ text = [Net.WebUtility]::HtmlDecode($t); names = $names }
}
Open-App 'oneclick\viewer.html' 9343
try {
  foreach ($c in $checks) {
    $p = Join-Path $base (Join-Path $c.dir (Join-Path 'files' $c.file))
    $x = XmlText $p
    $zipMiss = @($c.expect | Where-Object { $x.text -notlike ('*' + $_ + '*') })
    Nav 'oneclick\viewer.html'
    Set-FileInput '#f' @($p)
    Start-Sleep -Milliseconds 2500
    $vt = Js 'return document.body.innerText'
    # 엑셀 숫자 칸은 더뷰가 천 단위 쉼표(#,##0)로 보여 준다 → 77000 은 화면에서 77,000 으로 확인
    $viewMiss = @($c.expect | Where-Object { ($vt -notlike ('*' + $_ + '*')) -and -not (($_ -match '^\d{4,}$') -and ($vt -like ('*' + ('{0:N0}' -f [long]$_) + '*'))) })
    $shot = 'open_' + [IO.Path]::GetFileNameWithoutExtension($c.file) + '_' + [IO.Path]::GetExtension($c.file).TrimStart('.')
    Save-Screenshot (Join-Path $base (Join-Path $c.dir ($shot + '.png')))
    $errs = Js 'return JSON.stringify(window.__errs)'
    $ok = ($zipMiss.Count -eq 0) -and ($viewMiss.Count -eq 0) -and ($errs -eq '[]')
    $res += [pscustomobject]@{ file = $c.file; bytes = (Get-Item $p).Length; zipEntries = $x.names.Count; zipMissing = ($zipMiss -join '|'); viewerMissing = ($viewMiss -join '|'); viewerErrors = $errs; shot = $shot + '.png'; result = $(if ($ok) { 'PASS' } else { 'FAIL' }) }
  }
  # 인쇄 레이아웃(print 매체) A4 폭 캡처 — 계약서 3종·더양식 1종
  $cap = [IO.File]::ReadAllText((Join-Path $base 'contract_20261118\src\cap_contract.ps1'), [Text.Encoding]::UTF8)
  foreach ($t in 'sale', 'house', 'shop') {
    $m = [regex]::Match($cap, '(?m)^\s*' + $t + '\s*=\s*''(\{.*?)''\s*\+\s*\$BR')
    $br = [regex]::Match($cap, '\$BR = ''(.*?)''').Groups[1].Value
    $json = $m.Groups[1].Value + $br + ',"cp":{"a":1,"b":1,"c":1}}'
    Nav 'oneclick\contract.html'
    Js ('localStorage.setItem("kc_contract_v1", JSON.stringify(' + $json + ')); return 1') | Out-Null
    Nav 'oneclick\contract.html'
    Js 'KC.doPrint(); await new Promise(r=>setTimeout(r,400)); return 1' | Out-Null
    Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 794; height = 1123; deviceScaleFactor = 1; mobile = $false } | Out-Null
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null
    Start-Sleep -Milliseconds 500
    $h = [int](Invoke-Js "Math.ceil(document.querySelector('#printArea .paper').getBoundingClientRect().height)")
    $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 794; height = $h; scale = 1 } }
    [IO.File]::WriteAllBytes((Join-Path $base ('contract_20261118\print_layout_' + $t + '.png')), [Convert]::FromBase64String($r['data']))
    $res += [pscustomobject]@{ file = 'print_layout_' + $t; bytes = 0; zipEntries = 0; zipMissing = ''; viewerMissing = ''; viewerErrors = (Js 'return JSON.stringify(window.__errs)'); shot = 'print_layout_' + $t + '.png (1부 높이 ' + $h + 'px)'; result = 'INFO' }
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
    Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  }
} finally { Stop-CdpChrome }
$res | Format-Table -AutoSize | Out-String -Width 300
$res | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $base 'theform_20261118\verify_open.json')

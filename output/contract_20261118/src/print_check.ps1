# 계약서 3종 × 3부 인쇄 PDF 다시 만들고, 1부 = A4 1장인지 쪽수로 확인 + 인쇄 레이아웃 캡처
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$out = (Resolve-Path "$PSScriptRoot\..").Path
$files = Join-Path $out 'files'
$cap = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cap_contract.ps1'), [Text.Encoding]::UTF8)
$br = [regex]::Match($cap, '\$BR = ''(.*?)''').Groups[1].Value
$NM = @{ sale = '매매'; house = '주택임대차'; shop = '상가임대차' }
$res = @()
Open-App 'oneclick\contract.html' 9344
try {
  foreach ($t in 'sale', 'house', 'shop') {
    $m = [regex]::Match($cap, '(?m)^\s*' + $t + '\s*=\s*''(\{.*?)''\s*\+\s*\$BR')
    $json = $m.Groups[1].Value + $br + ',"cp":{"a":1,"b":1,"c":1}}'
    Js ('localStorage.setItem("kc_contract_v1", JSON.stringify(' + $json + ')); return 1') | Out-Null
    Nav 'oneclick\contract.html'
    Js 'KC.go(3); KC.doPrint(); await new Promise(r=>setTimeout(r,400)); return 1' | Out-Null
    $pdf = Join-Path $files ($NM[$t] + '계약서_3부_인쇄.pdf')
    Print-Pdf $pdf
    $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pdf))
    $pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count
    # 인쇄 레이아웃(1부) 캡처: A4 인쇄 폭(210mm − 좌우 여백 24mm ≈ 703px)
    Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 703; height = 1050; deviceScaleFactor = 1; mobile = $false } | Out-Null
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null
    Start-Sleep -Milliseconds 500
    $h = [int](Invoke-Js "Math.ceil(document.querySelector('#printArea .paper').getBoundingClientRect().height)")
    $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 703; height = $h; scale = 1 } }
    [IO.File]::WriteAllBytes((Join-Path $out ('print_layout_' + $t + '.png')), [Convert]::FromBase64String($r['data']))
    Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
    Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
    $res += [pscustomobject]@{ type = $t; pdf = (Split-Path $pdf -Leaf); pages = $pages; copies = 3; onePagePerCopy = ($pages -eq 3); layoutHeightPx = $h; errs = (Js 'return JSON.stringify(window.__errs)') }
  }
} finally { Stop-CdpChrome }
$res | Format-Table -AutoSize | Out-String -Width 200
$res | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $out 'print_check.json')

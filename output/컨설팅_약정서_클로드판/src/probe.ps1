# 배치 점검: consult.html(?cap=1)을 열어 쪽별 내용 아래 끝·넘침을 출력
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$url = (To-FileUrl (Join-Path $OUT 'consult.html')) + '?cap=1'
Start-CdpChrome 9581 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 1000; height = 2600; deviceScaleFactor = 1; mobile = $false } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.navigate' @{ url = $url } | Out-Null; Start-Sleep -Milliseconds 1500
  $j = Invoke-Js ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'measure.js')))
  $o = $j | ConvertFrom-Json
  $mm = 25.4 / 96
  foreach ($p in $o.pages) { "{0}: bottom={1:N1}mm ({2:N1}%) scrollH={3} clientH={4} last={5}" -f $p.id, ($p.contentBottom * $mm), ($p.contentBottom / $p.h * 100), $p.scrollH, $p.clientH, $p.lastTag }
  foreach ($b in $o.blocks) { "  p{0} {1,-4} {2,-10} {3,7:N1}~{4,7:N1}mm {5}" -f $b.page, $b.tag, $b.cls, ($b.top * $mm), ($b.bottom * $mm), $b.text }
} finally { Stop-CdpChrome }

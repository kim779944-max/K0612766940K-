# 라이브 확인: 10종이 아직 실서비스에 없다(404)는 증거 — 우리 사이트 HEAD 요청 10건만(다른 외부 요청 없음)
$SL = @('swapcheck', 'rights1p', 'yieldcalc', 'pricegap', 'notice', 'bidcompare', 'balju', 'ledger', 'tagmaker', 'themenu')
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$out = @('확인 시각 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
foreach ($s in $SL) {
  $u = "https://autooneclick.com/$s.html"
  try { $r = Invoke-WebRequest $u -Method Head -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 0; $code = [int]$r.StatusCode }
  catch { $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { '오류: ' + $_.Exception.Message } }
  $out += "$u  →  $code"
}
$out | ForEach-Object { Write-Output $_ }
$out | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'live404_log.txt')

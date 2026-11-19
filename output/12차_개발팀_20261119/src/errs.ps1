# 빠른 점검: 앱을 열어 JS 오류 + 구문 오류 줄 번호 출력
param([string]$app = 'mealplan')
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
Open-App ("oneclick\" + $app + ".html") 9499
try {
  Write-Output ($app + ' errs=' + (Invoke-Js 'JSON.stringify(window.__errs)'))
  $src = Invoke-Js '[...document.scripts].map(s=>s.textContent).join("\n")'
  Send-Cdp 'Runtime.enable' | Out-Null; $r = Send-Cdp 'Runtime.compileScript' @{ expression = $src; sourceURL = 'x.js'; persistScript = $false }
  if ($r['exceptionDetails']) { $ln = $r['exceptionDetails']['lineNumber']; $lines = $src -split "`n"; Write-Output ("syntax line " + $ln + ": " + $lines[$ln]) } else { Write-Output 'compile ok' }
} finally { Stop-CdpChrome }

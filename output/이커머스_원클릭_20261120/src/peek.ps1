# 개발용: 도구 1개를 ?sample=1&auto=1 로 열어 window.__res 를 JSON 으로 출력
param([string]$Tool = 'insta.html', [string]$Q = 'sample=1&auto=1')
. "$PSScriptRoot\lib.ps1"
Open-Tool 9371
try {
  Go-Tool ($Tool + '?' + $Q)
  $ok = Wait-For "window.__done===true" 20000
  Write-Output ("done=" + $ok + " sw=" + (Invoke-Js "document.documentElement.scrollWidth") + " errs=" + (Errs))
  Write-Output (Invoke-Js "JSON.stringify(window.__res)")
} finally { Stop-CdpChrome }

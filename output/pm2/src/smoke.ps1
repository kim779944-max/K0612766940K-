param([string]$app = 'riskcheck', [string]$code = 'return 1')
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
Open-App ("oneclick\" + $app + ".html") 9351
try {
  Write-Output (Js ("try{ " + $code + " }catch(e){ return 'EXC '+e.message+' '+e.stack }"))
  Write-Output ("errs=" + (Js 'return JSON.stringify(window.__errs)') + " sw=" + (Invoke-Js 'document.documentElement.scrollWidth'))
} finally { Stop-CdpChrome }

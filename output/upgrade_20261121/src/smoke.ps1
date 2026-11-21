param([string]$page = 'hogang/', [string]$shot = '_smoke.png', [string]$js = '')
. "$PSScriptRoot\lib.ps1"
Start-Serve
try {
  Open-Page ($global:Base + $page) 9371
  Start-Sleep -Milliseconds 1200
  Write-Output ("SW " + (SW))
  if ($js) { Write-Output (J $js) }
  ShotP $shot
  Write-Output ("EVT " + ((Evts-Summary) | ConvertTo-Json -Compress))
  $global:EVTS | Select-Object -First 8 | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(300, $_.text.Length)) }
} finally { Stop-CdpChrome }

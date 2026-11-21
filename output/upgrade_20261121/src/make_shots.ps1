. "$PSScriptRoot\lib.ps1"
Start-Serve
$dst = Join-Path $global:OcRoot 'shots'
$list = @(
  @{ k = 'gagebu'; prep = "localStorage.removeItem('kts_gagebu_v2');location.reload();return 1"; prep2 = "var A=window.__GAGEBU_API;A.addLines('양파 1.8kg 3900원 하나로마트\n계란 30구 7200원 하나로마트\n우유 900ml 2500원 편의점',false);A.addLines('양파 1.5kg 2900원 동네시장\n계란 30구 6600원 동네시장',true);window.scrollTo(0,0);return 1"; clean = "localStorage.removeItem('kts_gagebu_v2');return 1" },
  @{ k = 'hogang'; prep = ''; prep2 = ''; clean = '' },
  @{ k = 'golf'; prep = ''; prep2 = ''; clean = '' },
  @{ k = 'petmind'; prep = ''; prep2 = ''; clean = '' }
)
$port = 9401
foreach ($it in $list) {
  try {
    Open-Page ($global:Base + $it.k + '/') $port
    Start-Sleep -Milliseconds 1500
    if ($it.prep) { J $it.prep | Out-Null; Start-Sleep -Milliseconds 1500 }
    if ($it.prep2) { J $it.prep2 | Out-Null; Start-Sleep -Milliseconds 2600 }
    J "window.scrollTo(0,0);return 1" | Out-Null; Start-Sleep -Milliseconds 400
    Save-Screenshot (Join-Path $dst ($it.k + '_home.png'))
    if ($it.clean) { J $it.clean | Out-Null }
    Write-Output ($it.k + ' ' + ((Evts-Summary) | ConvertTo-Json -Compress))
  } finally { Stop-CdpChrome; $global:EVTS.Clear() }
  $port++
}

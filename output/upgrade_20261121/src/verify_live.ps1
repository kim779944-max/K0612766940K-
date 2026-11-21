. "$PSScriptRoot\lib.ps1"
$R = [ordered]@{}
$pages = @(
  @{ k = 'navi2/'; js = "return JSON.stringify({cap0:NAVI.START[0].cap,img0:NAVI.START[0].img,optIm:0})" },
  @{ k = 'hogang/'; js = "return JSON.stringify(window.__HOGANG?{best:window.__HOGANG.best.way,dev:window.__HOGANG.best.dev}:null)" },
  @{ k = 'gagebu/'; js = "return JSON.stringify({head:document.getElementById('oneHead').textContent})" },
  @{ k = 'golf/'; js = "return JSON.stringify({svg:document.querySelectorAll('svg').length,imgs:document.querySelectorAll('img').length,items:window.__GOLF.ORDER.length})" },
  @{ k = 'petmind/'; js = "return JSON.stringify({svg:document.querySelectorAll('svg').length,imgs:document.querySelectorAll('img').length,items:window.__PET.ORDER.length,h1:document.querySelector('h1').firstChild.textContent})" },
  @{ k = 'slope/'; js = "window.__KTS_PXSET&&window.__KTS_PXSET('px',3);return JSON.stringify({px:!!window.__KTS_PX,st:window.__KTS_ST?window.__KTS_ST().jibun:null})" }
)
$port = 9420
foreach ($p in $pages) {
  try {
    Open-Page ('https://autooneclick.com/' + $p.k + '?nocache=' + (Get-Random)) $port
    Start-Sleep -Milliseconds 4500
    $o = [ordered]@{}
    $o.sw = SW
    try { $o.check = J $p.js } catch { $o.check = 'ERR ' + $_.Exception.Message.Substring(0, 120) }
    Start-Sleep -Milliseconds 1500
    $o.evts = Evts-Summary
    $o.evtList = @($global:EVTS | Select-Object -First 4 | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(200, $_.text.Length)) })
    $R[$p.k] = $o
  } finally { Stop-CdpChrome; $global:EVTS.Clear() }
  $port++
}
$R | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_live_result.json')
$R | ConvertTo-Json -Depth 5

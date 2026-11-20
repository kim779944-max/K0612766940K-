# 라이브 더뷰(https://autooneclick.com/viewer.html) 구형 .hwp 검수 — 390×844 헤드리스 크롬(CDP)
# 사용: live.ps1 -Files a.hwp,b.hwp -Tag on|off   → shots\live_<tag>_<n>.png + 결과 JSON 한 줄씩 출력
param([string[]]$Files, [string]$Tag = 'on', [int]$GapSec = 12)
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$shots = Join-Path $PSScriptRoot '..\shots'
$URL = 'https://autooneclick.com/viewer.html'
Start-CdpChrome 9351 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'DOM.enable' | Out-Null
  Send-Cdp 'Runtime.enable' | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);window.addEventListener('unhandledrejection',function(e){window.__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});(function(){var w=console.error;console.error=function(){window.__errs.push('CONSOLE '+[].slice.call(arguments).join(' '));return w.apply(console,arguments)}})();" } | Out-Null
  $i = 0
  foreach ($f in $Files) {
    $i++
    if ($i -gt 1) { Start-Sleep -Seconds $GapSec }   # 서버 레이트리밋(IP당 10초 1건)
    Send-Cdp 'Page.navigate' @{ url = $URL + '?nocache=' + [DateTime]::Now.Ticks } | Out-Null
    Start-Sleep -Seconds 4
    $doc = Send-Cdp 'DOM.getDocument' @{ depth = 0 }
    $n = Send-Cdp 'DOM.querySelector' @{ nodeId = $doc['root']['nodeId']; selector = '#f' }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Send-Cdp 'DOM.setFileInputFiles' @{ nodeId = $n['nodeId']; files = @($f) } | Out-Null
    $loaderSeen = ''
    for ($k = 0; $k -lt 160; $k++) {
      Start-Sleep -Milliseconds 250
      $st = Invoke-Js "(document.getElementById('loader').classList.contains('on')?'L:'+document.getElementById('lStep').textContent:'')+'|'+(typeof PP!=='undefined'?PP.kind:'')"
      if ($st -match '^L:(.+)\|' -and -not $loaderSeen) { $loaderSeen = $Matches[1] }
      if ($st -match '\|(pdf|notice|frame)$') { break }
    }
    $ms = $sw.ElapsedMilliseconds
    Start-Sleep -Seconds 3   # 캔버스 그리기
    $js = @'
(async()=>{
  const o = {kind: PP.kind, pages: (PP.pages||[]).length, sw: document.documentElement.scrollWidth, bw: document.body.scrollWidth, iw: innerWidth,
    canvases: document.querySelectorAll('.pppage canvas').length, card: !!document.querySelector('.ppnotice'),
    retryBtn: !!document.getElementById('ppRetry'), priv: (document.querySelector('.ppnotice .pppriv')||{}).textContent||'',
    h3: (document.querySelector('.ppnotice h3')||{}).innerText||'', errs: window.__errs, text1: ''};
  if (PP.pdf){ const tc = await (await PP.pdf.getPage(1)).getTextContent(); o.text1 = tc.items.map(x=>x.str).join(' ').replace(/\s+/g,' ').slice(0,400); }
  return JSON.stringify(o);
})()
'@
    $res = Invoke-Js $js -await
    $shot = Join-Path $shots ("live_{0}_{1}.png" -f $Tag, $i)
    Save-Screenshot $shot
    Write-Output ("{0}`t{1}ms`tloader={2}`t{3}" -f [IO.Path]::GetFileName($f), $ms, $loaderSeen, $res)
  }
} finally { Stop-CdpChrome }

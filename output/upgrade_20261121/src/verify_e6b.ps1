. "$PSScriptRoot\lib.ps1"
Start-Serve
$READY = "!!(window.__KTS_ST && document.querySelector('#resTag').textContent.indexOf('평균')>=0)"
$O = [ordered]@{}
# 페이지 안에서 rAF 마다 pointermove 1번 — CDP 왕복 없이 실제 그리기 비용만 잰다(120프레임)
$DRAG = @"
var cv=document.getElementById('mapcv'),r=cv.getBoundingClientRect(),x=r.left+80,y=r.top+200,n=0,ts=[];
function ev(t,X,Y){cv.dispatchEvent(new PointerEvent(t,{pointerId:7,isPrimary:true,pointerType:'touch',clientX:X,clientY:Y,bubbles:true,cancelable:true}))}
ev('pointerdown',x,y);
await new Promise(function(done){(function f(t){ts.push(t);if(n++>=120){ev('pointerup',x,y);done();return}x+=(n<60?3:-3);y+=(n<60?-1:1);ev('pointermove',x,y);requestAnimationFrame(f)})(performance.now())});
var d=[];for(var i=2;i<ts.length;i++)d.push(ts[i]-ts[i-1]);d.sort(function(a,b){return a-b});
return JSON.stringify({frames:ts.length,median:+d[Math.floor(d.length/2)].toFixed(1),p90:+d[Math.floor(d.length*0.9)].toFixed(1),max:+d[d.length-1].toFixed(1)});
"@
foreach ($v in @(@{ n = 'base'; u = 'slope/_base_index.html'; port = 9393 }, @{ n = 'new'; u = 'slope/'; port = 9394 })) {
  try {
    Open-Page ($global:Base + $v.u) $v.port
    Wait-Js $READY 30000 | Out-Null
    Start-Sleep -Milliseconds 4000
    J "var e=document.getElementById('rad');e.value='300';e.dispatchEvent(new Event('input'));return 1" | Out-Null
    Start-Sleep -Milliseconds 1500
    $O[$v.n + '_arrow_r300'] = Js $DRAG
    if ($v.n -eq 'new') {
      J "window.__KTS_PXSET('px',3);return 1" | Out-Null; Start-Sleep -Milliseconds 800
      $O.new_px3_r300 = Js $DRAG
      J "window.__KTS_PXSET('px',6);return 1" | Out-Null; Start-Sleep -Milliseconds 800
      $O.new_px6_r300 = Js $DRAG
      $O.new_state = J "return JSON.stringify({px:window.__KTS_PX(),st:window.__KTS_ST()})"
    }
    $O[$v.n + '_evts'] = Evts-Summary
  } finally { Stop-CdpChrome; $global:EVTS.Clear() }
}
$O | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_e6b_result.json')
$O | ConvertTo-Json -Depth 5

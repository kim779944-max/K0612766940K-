# 100선 이관 5종 — 이번 회차 390x844 @2x 재측정 (헤드리스 크롬 CDP)
# 이관 후 모습 그대로 보려고, 임시 폴더에 문의 링크만 실서비스 경로로 바꾼 사본을 두고 연다(저장소 파일은 손대지 않음)
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$PKG = (Resolve-Path "$PSScriptRoot\..").Path
$K = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$NEWLINK = 'https://autooneclick.com/#reserve'
$T = Join-Path $env:TEMP 'mig5_390'; if (Test-Path $T) { Remove-Item -Recurse -Force $T }; New-Item -ItemType Directory $T | Out-Null
New-Item -ItemType Directory -Force (Join-Path $PKG '390') | Out-Null
$SLUGS = @('swapcheck','rights1p','balju','ledger','tagmaker')
$log = @(); function L($s) { $script:log += $s; Write-Output $s }
function Js([string]$code) { return Invoke-Js ("(async()=>{ " + $code + " })()") -await }
$LAYOUT = @'
(()=>{const W=innerWidth,bad=[],clip=[];const vis=e=>{const cs=getComputedStyle(e);const d=e.closest("details:not([open])");if(d&&!e.closest("summary"))return false;return !(cs.display==="none"||cs.visibility==="hidden")};
document.querySelectorAll('#app *').forEach(e=>{if(!vis(e)||e.closest('.hide')||e.closest('.hscroll'))return;const r=e.getBoundingClientRect();if(!r.width||!r.height)return;const cs=getComputedStyle(e);
if(r.right>W+0.5||r.left<-0.5)bad.push(e.tagName+'.'+e.className);
if(!/INPUT|TEXTAREA|SELECT/.test(e.tagName)&&(cs.overflowX==='hidden'||cs.textOverflow==='ellipsis')&&e.scrollWidth>e.clientWidth+1&&!e.closest('.pv'))clip.push(e.tagName+'.'+e.className)});
const leaves=[...document.querySelectorAll('#app button, #app a, #app label, #app h1, #app h2, #app h3, #app p, #app input, #app textarea, #app select')].filter(e=>vis(e)&&!e.closest('.hide')&&!e.closest('.hscroll')).map(e=>({e,r:e.getBoundingClientRect()})).filter(o=>o.r.width>2&&o.r.height>2);
let ov=[];for(let i=0;i<leaves.length;i++)for(let j=i+1;j<leaves.length;j++){const a=leaves[i],b=leaves[j];if(a.e.contains(b.e)||b.e.contains(a.e))continue;const w=Math.min(a.r.right,b.r.right)-Math.max(a.r.left,b.r.left),h=Math.min(a.r.bottom,b.r.bottom)-Math.max(a.r.top,b.r.top);if(w>2&&h>2&&w*h>0.3*Math.min(a.r.width*a.r.height,b.r.width*b.r.height))ov.push(a.e.tagName+'/'+b.e.tagName+' "'+(a.e.textContent||'').trim().slice(0,10)+'"')}
return JSON.stringify({sw:document.documentElement.scrollWidth,out:bad.length,clip:clip.length,overlap:ov.length,sample:[...bad,...clip,...ov].slice(0,5)})})()
'@
Start-CdpChrome 9541 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);window.addEventListener('unhandledrejection',function(e){window.__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});window.print=function(){window.__printed=(window.__printed||0)+1};" } | Out-Null
  foreach ($s in $SLUGS) {
    $src = [IO.File]::ReadAllText((Join-Path $K "oneclick\$s.html"), [Text.Encoding]::UTF8)
    $n = ([regex]::Matches($src, [regex]::Escape('../misa-1116/form.html'))).Count
    $dst = Join-Path $T "$s.html"
    [IO.File]::WriteAllText($dst, $src.Replace('../misa-1116/form.html', $NEWLINK), (New-Object Text.UTF8Encoding $false))
    Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $dst) } | Out-Null; Start-Sleep -Milliseconds 2000
    Js 'localStorage.clear(); return 1' | Out-Null
    Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $dst) } | Out-Null; Start-Sleep -Milliseconds 2200
    $l0 = Invoke-Js $LAYOUT | ConvertFrom-Json
    Js 'document.querySelector("#sampleBtn").click(); await new Promise(r=>setTimeout(r,500)); document.querySelector("#runBtn").click(); await new Promise(r=>setTimeout(r,1200)); return 1' | Out-Null
    $res = Js 'const r=document.querySelector("#result"); const cs=getComputedStyle(r); return JSON.stringify({visible: cs.display!=="none" && r.getBoundingClientRect().height>0, chars:r.innerText.trim().length, head:r.innerText.trim().replace(/\s+/g," ").slice(0,60)})' | ConvertFrom-Json
    Js 'const r=document.querySelector("#result"); r.scrollIntoView({block:"start"}); window.scrollBy(0,-64); return 1' | Out-Null
    Start-Sleep -Milliseconds 400
    $png = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }; [IO.File]::WriteAllBytes((Join-Path $PKG "390\$s.png"), [Convert]::FromBase64String($png['data']))
    $l1 = Invoke-Js $LAYOUT | ConvertFrom-Json
    $cp = Js 'window.__copied=null; try{ navigator.clipboard.writeText=async t=>{window.__copied=t}; }catch(e){} const _ex=document.execCommand.bind(document); document.execCommand=function(c){ if(c==="copy"){ const s=document.getSelection&&String(document.getSelection()); const a=document.activeElement; window.__copied=window.__copied||(a&&a.value)||s||"(execCommand)"; return true } return _ex.apply(document,arguments) }; const b=document.querySelector("#copyBtn"); b.click(); await new Promise(r=>setTimeout(r,500)); const pb=document.querySelector("#printBtn"); if(pb) pb.click(); await new Promise(r=>setTimeout(r,400)); return JSON.stringify({copied: window.__copied? String(window.__copied).length : 0, printCalls: window.__printed||0, hasPrint: !!pb})' | ConvertFrom-Json
    $inq = Js 'const a=document.querySelector("#inqLink"); return a? a.getAttribute("href") : ""'
    $iconPath = Join-Path $K "oneclick\shots\ic_$s.png"
    $icon = Js ("const i=new Image(); const ok=await new Promise(r=>{i.onload=()=>r(true); i.onerror=()=>r(false); i.src=" + (ConvertTo-Json (To-FileUrl $iconPath)) + "}); return JSON.stringify({ok, w:i.naturalWidth, h:i.naturalHeight})") | ConvertFrom-Json
    $errs = Js 'return JSON.stringify(window.__errs)'
    $ext = Js 'return JSON.stringify([...document.querySelectorAll("script[src],link[href],img[src]")].map(e=>e.getAttribute("src")||e.getAttribute("href")).filter(u=>/^https?:/.test(u)))'
    $row = [ordered]@{ slug = $s; capture = "output/100선_이관_20261120/390/$s.png"; sw0 = $l0.sw; sw1 = $l1.sw; out = ($l0.out + $l1.out); overlap = ($l0.overlap + $l1.overlap); clip = ($l0.clip + $l1.clip); errs = $errs; result = $res; copy = $cp; inqOrig = $n; inqHref = $inq; icon = $icon; ext = $ext; samples = @($l0.sample + $l1.sample) }
    L ($row | ConvertTo-Json -Compress -Depth 5)
  }
} finally { Stop-CdpChrome }
$log | Set-Content -Encoding UTF8 (Join-Path $PKG '390\measure_log.jsonl')

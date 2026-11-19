# 교환계약서 손질 검증 — 헤드리스 크롬 390x844 @2x (CDP)
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$OC = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
# 손질 전 사본 (임시 폴더, 저장소 밖)
$BEF = Join-Path $env:TEMP 'oc_before_20261120'
if (Test-Path $BEF) { Remove-Item -Recurse -Force $BEF }
New-Item -ItemType Directory -Force (Join-Path $BEF 'contract') | Out-Null
Copy-Item "$OC\master.js","$OC\freekey.js","$OC\ai.js" $BEF
Copy-Item "$OC\contract\*.png" (Join-Path $BEF 'contract')
Copy-Item "$OUT\before_tpl_exchange.png" (Join-Path $BEF 'contract\tpl_exchange.png') -Force
Copy-Item "$OUT\before_forms.js" (Join-Path $BEF 'contract\forms.js')
Copy-Item "$OUT\before_index.html" (Join-Path $BEF 'contract\index.html')
$log = @(); function L($s) { $script:log += $s; Write-Output $s }
function Js([string]$code) { return Invoke-Js ("(async()=>{ " + $code + " })()") -await }
function Go([string]$path) { Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $path) } | Out-Null; Start-Sleep -Milliseconds 2500 }
function SavePng([string]$name) { $r2 = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }; [IO.File]::WriteAllBytes((Join-Path $OUT $name), [Convert]::FromBase64String($r2['data'])) }
Start-CdpChrome 9521 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);window.addEventListener('unhandledrejection',function(e){window.__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});window.print=function(){window.__printed=(window.__printed||0)+1};var __ce=console.error;console.error=function(){window.__errs.push('CONSOLE '+[].join.call(arguments,' '));__ce.apply(console,arguments)};" } | Out-Null

  # ---------- (b) 390px 문구 캡처 4장 ----------
  foreach ($k in @(@('tax','tax.html'), @('contract','contract\index.html'), @('organizer','organizer\index.html'), @('sign','sign\index.html'))) {
    Go (Join-Path $OC $k[1]); Js 'localStorage.clear(); return 1' | Out-Null; Go (Join-Path $OC $k[1])
    $r = Js 'const a=document.querySelector("a.ktsRsv"); a.scrollIntoView({block:"start"}); window.scrollBy(0,-12); const rr=a.getBoundingClientRect(); const i=a.querySelector("i"); const ir=i.getBoundingClientRect(); const lh=parseFloat(getComputedStyle(i).lineHeight)||ir.height; return JSON.stringify({href:a.getAttribute("href"), text:a.innerText.replace(/\n/g," / "), banner:[Math.round(rr.left),Math.round(rr.right),Math.round(rr.height)], iLines:Math.round(ir.height/lh), iEmpty:!i.textContent.trim(), sw:document.documentElement.scrollWidth, errs:window.__errs})'
    Start-Sleep -Milliseconds 300
    SavePng ('fix_문구_' + $k[0] + '.png')
    L ("문구[" + $k[0] + "]: " + $r)
  }

  # ---------- (a) 교환계약서 ----------
  $FILL = @'
const K=window.KC; const f=K.curForm();
for (const x of f.fields){ if (x.type==='sign') continue; if (x.id==='special') continue; K.setV(x.id, x.money? '123456789' : (x.dp==='y'?'2026':x.dp?'11':(x.label.length>4? x.label+' 가나다':'홍길동'))); }
const sc=document.createElement('canvas'); sc.width=600; sc.height=100; const sg=sc.getContext('2d'); sg.fillStyle='#000'; sg.fillRect(0,0,600,100); const SIGURL=sc.toDataURL();
const H=(c,x0,x1,y0,y1)=>{ const g=c.getContext('2d'); const k=c.width/1489; const X0=Math.round(x0*k),X1=Math.round(x1*k),Y0=Math.round(y0*k),Y1=Math.round(y1*k); const d=g.getImageData(X0,Y0,X1-X0,Y1-Y0).data; const W=X1-X0; const rows=[]; let minx=1e9; for(let y=0;y<Y1-Y0;y++){ let hit=false; for(let x=0;x<W;x++){ const i=(y*W+x)*4; if(d[i]<80&&d[i+1]<90&&d[i+2]>40&&d[i+2]<160&&d[i+2]-d[i]>25){ hit=true; if(x<minx)minx=x; } } rows.push(hit); } const bands=[]; let s=-1; rows.forEach((h,i)=>{ if(h&&s<0)s=i; if(!h&&s>=0){bands.push([s,i-1]); s=-1;} }); if(s>=0)bands.push([s,rows.length-1]); return {k, bands:bands.map(b=>[+(y0+b[0]/k).toFixed(1), +(y0+b[1]/k).toFixed(1)]), minx:+(x0+minx/k).toFixed(1)}; };
const BB=(c,x0,x1,y0,y1,dark)=>{const g=c.getContext('2d'); const k=c.width/1489; const W=Math.round((x1-x0)*k); const d=g.getImageData(Math.round(x0*k),Math.round(y0*k),W,Math.round((y1-y0)*k)).data; let mx=1e9; for(let i=0;i<d.length;i+=4){ if(d[i]<dark&&d[i+1]<dark&&d[i+2]<dark){ const x=(i/4)%W; if(x<mx)mx=x; } } return +(x0+mx/k).toFixed(1); };
K.setV('p26',SIGURL); K.setV('p31',SIGURL);
'@
  $MEAS = @'
document.querySelector('#toast').classList.remove('on'); document.querySelector('#toast').textContent='';
const c=await K.composite(); const sp=H(c,100,1420,1255,1730);
const n=sp.bands.length;
return JSON.stringify({canvas:[c.width,c.height], lines:n, first:sp.bands[0], last:sp.bands[n-1], pitch: n>1? +((sp.bands[n-1][0]-sp.bands[0][0])/(n-1)).toFixed(1):0, glyphH:+(sp.bands[0][1]-sp.bands[0][0]+1).toFixed(1), textMinX:sp.minx, labelX:BB(c,76,300,1223,1247,90), boxBottom:1263+454, sentenceTop:1731, signA_left:BB(c,1115,1410,1836,1878,10), signB_left:BB(c,1115,1410,1942,1984,10), toast:document.querySelector('#toast').textContent});
'@
  Go (Join-Path $OC 'contract\index.html'); Js 'localStorage.clear(); return 1' | Out-Null; Go (Join-Path $OC 'contract\index.html')
  L ("contract errs on load: " + (Js 'return JSON.stringify(window.__errs)'))
  Js 'KC.setForm("exchange"); await new Promise(r=>setTimeout(r,600)); return 1' | Out-Null
  L ("① 쇼룸 목록 버튼: " + (Js 'return JSON.stringify([...document.querySelectorAll("#pickGrid button")].map(b=>b.textContent).filter(t=>/교환/.test(t)))') + " / curForm().name=" + (Js 'return KC.curForm().name'))
  $six = (1..6 | ForEach-Object { "$_. 특약 시험 문장입니다 — 교환 목적물은 현 상태 그대로 인도한다." }) -join "`n"
  $twelve = (1..12 | ForEach-Object { "$_. 특약 시험 문장입니다 — 교환 목적물은 현 상태 그대로 인도한다." }) -join "`n"
  $forty = (1..40 | ForEach-Object { "$_. 넘침 시험" }) -join "`n"
  foreach ($case in @(@('6줄', $six), @('12줄', $twelve), @('40줄_경고', $forty))) {
    $r = Js ($FILL + "K.setV('special'," + (ConvertTo-Json $case[1]) + ");" + $MEAS)
    L ("특약 " + $case[0] + ": " + $r)
    $png = Js 'const c=await KC.composite(); return c.toDataURL("image/png").split(",")[1]'
    [IO.File]::WriteAllBytes((Join-Path $OUT ('after_composite_' + $case[0] + '.png')), [Convert]::FromBase64String($png))
    if ($case[0] -eq '12줄') {
      Js 'document.querySelector("#printBtn").click(); await new Promise(r=>setTimeout(r,2000)); return 1' | Out-Null
      Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null
      $pdf = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true }
      Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
      $pp = Join-Path $OUT 'after_print_12줄.pdf'; [IO.File]::WriteAllBytes($pp, [Convert]::FromBase64String($pdf['data']))
      $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pp))
      L ("인쇄 12줄: pdfPages=" + ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count + " print() calls=" + (Js 'return String(window.__printed||0)') + " printArea imgs=" + (Js 'return String(document.querySelectorAll("#printArea img").length)') + " file=after_print_12줄.pdf")
    }
  }
  # 미리보기 화면 (12줄 상태로)
  Js ("KC.setV('special'," + (ConvertTo-Json $twelve) + "); return 1") | Out-Null
  L ("미리보기 단계: " + (Js 'const st=KC.stepList(); KC.go(st[st.length-1]); await new Promise(r=>setTimeout(r,900)); KC.renderPreview(); await new Promise(r=>setTimeout(r,800)); const e=document.querySelector("#pvCv"); if(e) e.scrollIntoView({block:"start"}); const hs=[...document.querySelectorAll("h1,h2,h3,.ttl,.title,b,strong")].map(x=>x.textContent).filter(t=>/교환계약서/.test(t)); return JSON.stringify({steps:st, pv:!!e, pvSize:e?[e.width,e.height]:null, titles:hs.slice(0,4), sw:document.documentElement.scrollWidth})'))
  Start-Sleep -Milliseconds 300; SavePng 'after_preview_390.png'
  L ("contract errs end: " + (Js 'return JSON.stringify(window.__errs)'))

  # ---------- 다른 계약서 8종: 손질 전/후 합성 결과 비교 ----------
  $HASH = @'
const out={}; for (const fm of KC.FORMS){ if (fm.id==='exchange') continue; KC.setForm(fm.id); await new Promise(r=>setTimeout(r,500));
  const f=KC.curForm(); for (const x of f.fields){ if (x.type==='sign') continue; KC.setV(x.id, x.multi? '첫째 줄 특약\n둘째 줄 특약' : x.money? '5000000' : (x.dp==='y'?'2026':x.dp?'11':'홍길동 가나다')); }
  const c=await KC.composite(); const d=c.getContext('2d').getImageData(0,0,c.width,c.height).data; let h=2166136261>>>0; for(let i=0;i<d.length;i+=3){ h^=d[i]; h=Math.imul(h,16777619)>>>0; }
  out[fm.id+':'+fm.name]=c.width+'x'+c.height+':'+h.toString(16); }
return JSON.stringify(out);
'@
  Go (Join-Path $OC 'contract\index.html'); Js 'localStorage.clear(); return 1' | Out-Null; Go (Join-Path $OC 'contract\index.html')
  $after = Js $HASH | ConvertFrom-Json
  Js 'KC.setForm("sale"); await new Promise(r=>setTimeout(r,600)); return 1' | Out-Null
  $png = Js 'const c=await KC.composite(1200); return c.toDataURL("image/png").split(",")[1]'; [IO.File]::WriteAllBytes((Join-Path $OUT 'compare_sale_after.png'), [Convert]::FromBase64String($png))
  Go (Join-Path $BEF 'contract\index.html'); Js 'localStorage.clear(); return 1' | Out-Null; Go (Join-Path $BEF 'contract\index.html')
  $before = Js $HASH | ConvertFrom-Json
  Js 'KC.setForm("sale"); await new Promise(r=>setTimeout(r,600)); return 1' | Out-Null
  $png = Js 'const c=await KC.composite(1200); return c.toDataURL("image/png").split(",")[1]'; [IO.File]::WriteAllBytes((Join-Path $OUT 'compare_sale_before.png'), [Convert]::FromBase64String($png))
  $same = 0; $tot = 0
  foreach ($p in $after.PSObject.Properties) { $tot++; $b = $before.($p.Name); $eq = ($b -eq $p.Value); if ($eq) { $same++ }; L ("8종 비교 " + $p.Name + ": before=" + $b + " after=" + $p.Value + " same=" + $eq) }
  L ("8종 비교 합계: " + $same + "/" + $tot + " 동일")
  Js 'localStorage.clear(); return 1' | Out-Null
} finally { Stop-CdpChrome }
$log | Set-Content -Encoding UTF8 (Join-Path $OUT 'verify_log.txt')

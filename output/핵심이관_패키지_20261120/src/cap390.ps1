# 핵심 10종 — 이번 회차 390x844 @2x 재측정 (헤드리스 크롬 CDP) + 종별 추가 검사
#  이관 후 모습 그대로 보려고, 임시 폴더에 문의 링크만 실서비스 주소로 바꾼 사본을 두고 연다(저장소 파일은 손대지 않음)
#  공통: 저장 비우기 → 열기(측정1) → [예시] 1탭 → [만들기] 1탭 → 결과 캡처(측정2) → 복사·인쇄 → 문의 링크·아이콘·상세 캡처·외부 참조
#  추가: themenu QR 디코드(jsQR — 시험 전용, %LOCALAPPDATA%\Temp\jsqr\jsQR.js, 패키지·배포물에 넣지 않음)·A4 PDF 쪽수·한영
#        notice 발송 코드 0 · bidcompare 단가 빈칸 유지·확인 필요 쌍 미병합 · yieldcalc/pricegap 손 검산
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$PKG = (Resolve-Path "$PSScriptRoot\..").Path
$K = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$NEWLINK = 'https://autooneclick.com/#reserve'
$JSQR = Join-Path $env:LOCALAPPDATA 'Temp\jsqr\jsQR.js'
$T = Join-Path $env:TEMP 'mig10_390'; if (Test-Path $T) { Remove-Item -Recurse -Force $T }; New-Item -ItemType Directory $T | Out-Null
New-Item -ItemType Directory -Force (Join-Path $PKG '390') | Out-Null
$SLUGS = @('swapcheck', 'rights1p', 'yieldcalc', 'pricegap', 'notice', 'bidcompare', 'balju', 'ledger', 'tagmaker', 'themenu')
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
function PdfPages([string]$path) {
  $r = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true }
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($r['data']))
  $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($path))
  $mb = [regex]::Match($raw, '/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]')
  return [ordered]@{ pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count; mediaBox = ($mb.Groups[1].Value + 'x' + $mb.Groups[2].Value) }
}
Start-CdpChrome 9561 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  try { Send-Cdp 'Page.setDownloadBehavior' @{ behavior = 'deny' } | Out-Null } catch {}
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);window.addEventListener('unhandledrejection',function(e){window.__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});window.print=function(){window.__printed=(window.__printed||0)+1};" } | Out-Null
  foreach ($s in $SLUGS) { $global:STEP = "start"
    $src = [IO.File]::ReadAllText((Join-Path $K "oneclick\$s.html"), [Text.Encoding]::UTF8)
    $n = ([regex]::Matches($src, [regex]::Escape('../misa-1116/form.html'))).Count
    $dst = Join-Path $T "$s.html"
    [IO.File]::WriteAllText($dst, $src.Replace('../misa-1116/form.html', $NEWLINK), (New-Object Text.UTF8Encoding $false))
    Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $dst) } | Out-Null; Start-Sleep -Milliseconds 2000
    Js 'localStorage.clear(); return 1' | Out-Null
    Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $dst) } | Out-Null; Start-Sleep -Milliseconds 2200
    $global:STEP = "layout0"; $l0 = Invoke-Js $LAYOUT | ConvertFrom-Json
    Js 'document.querySelector("#sampleBtn").click(); await new Promise(r=>setTimeout(r,500)); document.querySelector("#runBtn").click(); await new Promise(r=>setTimeout(r,1200)); return 1' | Out-Null
    $res = Js 'const r=document.querySelector("#result"); const cs=getComputedStyle(r); return JSON.stringify({visible: cs.display!=="none" && r.getBoundingClientRect().height>0, chars:r.innerText.trim().length, head:r.innerText.trim().replace(/\s+/g," ").slice(0,60)})' | ConvertFrom-Json
    Js 'const t=document.querySelector("#toast"); t&&t.classList.remove("on"); const r=document.querySelector("#result"); r.scrollIntoView({block:"start"}); window.scrollBy(0,-64); return 1' | Out-Null
    Start-Sleep -Milliseconds 400
    $png = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }; [IO.File]::WriteAllBytes((Join-Path $PKG "390\$s.png"), [Convert]::FromBase64String($png['data']))
    $global:STEP = "layout1"; $l1 = Invoke-Js $LAYOUT | ConvertFrom-Json

    # ---- 종별 추가 검사 (복사·인쇄 전에: 결과 상태 그대로) ----
    $global:STEP = "extra"; $extra = [ordered]@{}
    if ($s -eq 'yieldcalc') {
      # 예시 1: 매매가 95,000 · 취득비 4,900 · 월세 380 · 공실 5% · 관리 30/월 · 세금 220/년 (만원)
      $gross = 380 * 12 / 95000; $noi = 380 * 12 * 0.95 - 30 * 12 - 220; $net = $noi / (95000 + 4900)
      $scr = Js 'return JSON.stringify({sG:document.querySelector("#sG").textContent, sN:document.querySelector("#sN").textContent, noi:CUR.noi})' | ConvertFrom-Json
      $extra.hand = ("총수익률 = 380×12 ÷ 95,000 = {0:P2} (화면 {1}) · NOI = 380×12×0.95 − 30×12 − 220 = {2:N1} (앱 {3:N1}) · 순수익률 = NOI ÷ (95,000+4,900) = {4:P2} (화면 {5})" -f $gross, $scr.sG, $noi, [double]$scr.noi, $net, $scr.sN)
      $extra.handOk = (($scr.sG -replace '\s', '') -eq ($gross * 100).ToString('0.00') + '%') -and (($scr.sN -replace '\s', '') -eq ($net * 100).ToString('0.00') + '%') -and ([math]::Abs($noi - [double]$scr.noi) -lt 0.01)
    }
    if ($s -eq 'pricegap') {
      $h = Js @'
const py=m2=>m2/3.3058; const rows=CUR.ok.map(r=>({addr:r.addr,ppy:r.v/py(r.a.m2)}));
const med=a=>{const b=[...a].sort((x,y)=>x-y),n=b.length;return n%2?b[(n-1)/2]:(b[n/2-1]+b[n/2])/2};
const m0=med(rows.map(r=>r.ppy)); const keep=rows.filter(r=>Math.abs(r.ppy/m0-1)<=CUR.lim); const m=med(keep.map(r=>r.ppy));
const askPpy=CUR.askV/py(CUR.askA.m2); const gap=askPpy/m-1;
return JSON.stringify({n:rows.length,keep:keep.length,handMed:m,appMed:CUR.med,sMed:document.querySelector("#sMed").textContent,handGap:gap,appGap:CUR.gap,bGap:document.querySelector("#bGap").textContent,row0:CUR.ok[0].v+"/("+CUR.ok[0].a.m2+"/3.3058)="+(CUR.ok[0].v/(CUR.ok[0].a.m2/3.3058)).toFixed(1)+" vs app "+CUR.ok[0].ppy.toFixed(1)})
'@ | ConvertFrom-Json
      $extra.hand = ("평당가 = 거래가 ÷ (㎡ ÷ 3.3058): {0} · 이상치(±{1}%) 뺀 {2}/{3}건 중앙값 손 계산 {4:N1} = 앱 {5:N1} (화면 {6}) · 괴리율 = 호가 평당가 ÷ 중앙값 − 1 = {7:P1} = 앱 {8:P1} (화면 {9})" -f $h.row0, 40, $h.keep, $h.n, [double]$h.handMed, [double]$h.appMed, $h.sMed, [double]$h.handGap, [double]$h.appGap, $h.bGap)
      $extra.handOk = ([math]::Abs([double]$h.handMed - [double]$h.appMed) -lt 0.01) -and ([math]::Abs([double]$h.handGap - [double]$h.appGap) -lt 0.0001)
    }
    if ($s -eq 'notice') {
      $pat = [ordered]@{ 'sms:' = 'sms:'; 'mailto:' = 'mailto:'; 'fetch(' = 'fetch\('; 'XMLHttpRequest' = 'XMLHttpRequest'; 'sendBeacon' = 'sendBeacon' }
      $cnt = [ordered]@{}; foreach ($pk in $pat.Keys) { $cnt[$pk] = ([regex]::Matches($src, $pat[$pk])).Count }
      $extra.sendCode = $cnt; $extra.sendCodeTotal = ($cnt.Values | Measure-Object -Sum).Sum
    }
    if ($s -eq 'bidcompare') {
      $b = Js @'
const amb=CUR.amb.map(a=>a[0]+"↔"+a[1]); const rowsTxt=JSON.stringify(CUR.rows);
const notMerged=CUR.amb.every(a=>rowsTxt.includes(JSON.stringify(a[0]))&&rowsTxt.includes(JSON.stringify(a[1])));
const keep=document.querySelector("#src").value;
document.querySelector("#src").value="X\n바닥, 1, , \n벽, 1, 100, 100\n\nY\n바닥, 1, 200, 200\n벽, 1, 120, 120"; run();
const it=CUR.V[0].items[0]; const blank={unit:String(it.unit), amt:String(it.amt)};
document.querySelector("#src").value=keep; run();
return JSON.stringify({amb, ambCount:CUR.amb.length, notMerged, rows:CUR.rows.length, blank})
'@ | ConvertFrom-Json
      $extra.amb = $b; $extra.blankKept = ($b.blank.unit -in @('NaN', '', 'null', 'undefined')) -and ($b.blank.amt -in @('NaN', '', 'null', 'undefined'))
    }
    if ($s -eq 'themenu') {
      $q = [ordered]@{}
      $q.langs = Js 'return JSON.stringify({items:CUR.items.length, ko:CUR.html.includes("김치찌개"), en:CUR.html.includes("Kimchi Stew")})' | ConvertFrom-Json
      if (Test-Path $JSQR) {
        $jsq = [IO.File]::ReadAllText($JSQR)
        Invoke-Js ("(function(){var module=undefined,exports=undefined,define=undefined;" + $jsq + "`n;window.jsQR=(typeof jsQR!=='undefined'?jsQR:window.jsQR);return typeof window.jsQR})()") | Out-Null
        $q.decode = Invoke-Js "(()=>{const q=CUR.q;const sc=4,n=q.size+8,c=document.createElement('canvas');c.width=c.height=n*sc;const g=c.getContext('2d');g.fillStyle='#fff';g.fillRect(0,0,c.width,c.height);g.fillStyle='#000';for(let y=0;y<q.size;y++)for(let x=0;x<q.size;x++)if(q.get(x,y))g.fillRect((x+4)*sc,(y+4)*sc,sc,sc);const d=g.getImageData(0,0,c.width,c.height);const r=jsQR(d.data,c.width,c.height);if(!r)return 'DECODE FAIL v'+q.version;return 'QR v'+q.version+' '+q.ecl+' '+q.bytes+'B decoded==url '+(r.data===CUR.url)+' (decoded '+r.data.length+'자)'})()"
        $q.decodeOk = $q.decode -match 'decoded==url true'
        Send-Cdp 'Page.reload' | Out-Null; Start-Sleep -Milliseconds 1800   # jsQR 흔적 제거 후 계속
        Js 'document.querySelector("#sampleBtn").click(); await new Promise(r=>setTimeout(r,500)); document.querySelector("#runBtn").click(); await new Promise(r=>setTimeout(r,1200)); return 1' | Out-Null
      } else { $q.decode = "jsQR 없음: $JSQR"; $q.decodeOk = $false }
      Js 'document.querySelector("#printBtn").click(); await new Promise(r=>setTimeout(r,600)); return 1' | Out-Null
      Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null
      $q.a4 = PdfPages (Join-Path $T 'themenu_print.pdf')
      Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
      $wh = $q.a4.mediaBox -split 'x'; $q.a4Ok = ($q.a4.pages -eq 1) -and ([math]::Abs([double]$wh[0] - 595.28) -lt 2) -and ([math]::Abs([double]$wh[1] - 841.89) -lt 2)   # A4 = 595.28 x 841.89 pt
      $extra.themenu = $q
      Send-Cdp 'Page.reload' | Out-Null; Start-Sleep -Milliseconds 1800
      Js 'document.querySelector("#sampleBtn").click(); await new Promise(r=>setTimeout(r,500)); document.querySelector("#runBtn").click(); await new Promise(r=>setTimeout(r,1200)); return 1' | Out-Null
    }

    $global:STEP = "copy"; $cp = Js 'window.__copied=null; try{ navigator.clipboard.writeText=async t=>{window.__copied=t}; }catch(e){} const _ex=document.execCommand.bind(document); document.execCommand=function(c){ if(c==="copy"){ const s=document.getSelection&&String(document.getSelection()); const a=document.activeElement; window.__copied=window.__copied||(a&&a.value)||s||"(execCommand)"; return true } return _ex.apply(document,arguments) }; const b=document.querySelector("#copyBtn"); b.click(); await new Promise(r=>setTimeout(r,500)); const pb=document.querySelector("#printBtn"); if(pb) pb.click(); await new Promise(r=>setTimeout(r,400)); return JSON.stringify({copied: window.__copied? String(window.__copied).length : 0, printCalls: window.__printed||0, hasPrint: !!pb})' | ConvertFrom-Json
    $inq = Js 'const a=document.querySelector("#inqLink"); return a? a.getAttribute("href") : ""'
    $global:STEP = "imgs"; $imgs = [ordered]@{}
    foreach ($ip in @("oneclick\shots\ic_$s.png", "oneclick\shots\${s}_home.png")) {
      $imgs[(Split-Path $ip -Leaf)] = Js ("const i=new Image(); const ok=await new Promise(r=>{i.onload=()=>r(true); i.onerror=()=>r(false); i.src=" + (ConvertTo-Json (To-FileUrl (Join-Path $K $ip))) + "}); return JSON.stringify({ok, w:i.naturalWidth, h:i.naturalHeight})") | ConvertFrom-Json
    }
    $global:STEP = "errs"; $errs = Js 'return JSON.stringify(window.__errs)'
    $ext = Js 'return JSON.stringify([...document.querySelectorAll("script[src],link[href],img[src]")].map(e=>e.getAttribute("src")||e.getAttribute("href")).filter(u=>/^https?:/.test(u)))'
    $row = [ordered]@{ slug = $s; capture = "output/핵심이관_패키지_20261120/390/$s.png"; sw0 = $l0.sw; sw1 = $l1.sw; out = ($l0.out + $l1.out); overlap = ($l0.overlap + $l1.overlap); clip = ($l0.clip + $l1.clip); errs = $errs; taps = 2; result = $res; copy = $cp; inqOrig = $n; inqHref = $inq; images = $imgs; ext = $ext; extra = $extra; samples = @($l0.sample + $l1.sample) }
    L ($row | ConvertTo-Json -Compress -Depth 6)
  }
} catch { L ("중단: slug=" + $s + " step=" + $global:STEP + " :: " + $_.Exception.Message); throw } finally { Stop-CdpChrome }
$log | Set-Content -Encoding UTF8 (Join-Path $PKG '390\measure_log.jsonl')

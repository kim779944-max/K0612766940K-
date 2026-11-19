# 52번 하네스 동적 검수: 원본(in) vs 결과(out) 같은 동작 3개 · 콘솔 오류 · 390px 넘침 · 터치 44px · before/after 캡처
param([string]$app = 'realty_parser', [int]$port = 9521)
. "$PSScriptRoot\..\..\output\theform_20261118\src\lib.ps1"
$DR = (Resolve-Path "$PSScriptRoot\..").Path
$shots = Join-Path $DR 'shots'; New-Item -ItemType Directory -Force $shots | Out-Null

$ACT = @{
 realty_parser = @(
  @('① 예시 → 1초 정리', 'document.querySelector("#btnSample").click(); await new Promise(r=>setTimeout(r,300)); document.querySelector("#btnParse").click(); await new Promise(r=>setTimeout(r,900)); return "total="+document.querySelector("#sTotal").textContent+" deal="+document.querySelector("#sDeal").textContent+" dup="+document.querySelector("#sDup").textContent+" cards="+document.querySelectorAll("#cards .card").length'),
  @('② 카드 열기(첫 카드 내용)', 'const c=document.querySelector("#cards .card"); return c? c.querySelector(".title").textContent+" | "+(c.querySelector(".price")||{}).textContent+" | "+(c.querySelector(".sum")||{textContent:""}).textContent.slice(0,40) : "no card"'),
  @('③ 원문 보기', 'const d=document.querySelector("#cards details.raw"); if(!d) return "no raw"; d.querySelector("summary").click(); await new Promise(r=>setTimeout(r,200)); return "open="+d.open+" len="+d.querySelector("p").textContent.length')
 )
 seller = @(
  @('① 세팅 저장 → 본 화면', 'const s=document.querySelector("#setupSource"); s.value="도매매"; s.dispatchEvent(new Event("input",{bubbles:true})); document.querySelector("#setupGo").click(); await new Promise(r=>setTimeout(r,700)); return "main hidden="+document.querySelector("#main").hidden+" sum="+document.querySelector("#sum").textContent.replace(/\s+/g," ").slice(0,90)'),
  @('② 세부설정 검색(마진)', 'const q=document.querySelector("#cfgQ"); q.value="마진"; q.dispatchEvent(new Event("input",{bubbles:true})); await new Promise(r=>setTimeout(r,400)); return "results="+document.querySelectorAll("#cfgList button").length+" first="+((document.querySelector("#cfgList button")||{}).textContent||"").replace(/\s+/g," ")'),
  @('③ 결과 열기 → 마진 설명', 'const b=document.querySelector("#cfgList button"); if(!b) return "no result"; b.click(); await new Promise(r=>setTimeout(r,600)); const s=document.querySelector("#sh"); const t=s.textContent.replace(/\s+/g," "); const r="sheet on="+s.classList.contains("on")+" explain="+document.querySelectorAll("#sh .explain").length+" text="+t.slice(0,80); document.querySelector("#shClose").click(); await new Promise(r=>setTimeout(r,400)); return r')
 )
 ad_magnet = @(
  @('① 주제(상품·타겟·동네) 입력', 'document.querySelector("#prodChips .chip").click(); await new Promise(r=>setTimeout(r,150)); document.querySelector("#targChips .chip").click(); const r=document.querySelector("#region"); r.value="미사"; r.dispatchEvent(new Event("input",{bubbles:true})); return "prod="+document.querySelector("#prodChips .chip.on").textContent.trim()+" targ="+document.querySelector("#targChips .chip.on").textContent.trim()'),
  @('② 결과 생성', 'document.querySelector("#goBtn").click(); await new Promise(r=>setTimeout(r,700)); return "cards="+document.querySelectorAll("#result .card").length+" first="+document.querySelector("#result .card .top b").textContent+" len="+document.querySelector("#result .card pre").textContent.length'),
  @('③ 복사', 'window.__cp=null; try{navigator.clipboard.writeText=t=>{window.__cp=t;return Promise.resolve()}}catch(e){} document.querySelector("#result [data-copy]").click(); await new Promise(r=>setTimeout(r,400)); return "toast="+document.querySelector("#toast").textContent+" copied="+(window.__cp||"").length+"자"')
 )
}
$acts = $ACT[$app]
$focusSel = @{ realty_parser = '#result'; seller = '#main'; ad_magnet = '#result' }[$app]
$TOUCH = @'
(()=>{const out=[];document.querySelectorAll('button,input,a,select,summary').forEach(e=>{const cs=getComputedStyle(e);if(e.type==='hidden'||cs.display==='none'||cs.visibility==='hidden'||e.hidden||e.closest('[hidden]'))return;const r=e.getBoundingClientRect();if(!r.width||!r.height)return;if(e.closest('.sheet')&&!e.closest('.sheet.on'))return;if(Math.min(r.width,r.height)<43.5)out.push(e.tagName.toLowerCase()+(e.id?'#'+e.id:'')+(e.className&&typeof e.className==='string'?'.'+e.className.trim().split(/\s+/).join('.'):'')+' '+Math.round(r.width)+'x'+Math.round(r.height)+' "'+(e.textContent||e.placeholder||'').trim().slice(0,14)+'"')});return JSON.stringify(out)})()
'@
$OVER = @'
(()=>{const W=innerWidth,bad=[];document.querySelectorAll('body *').forEach(e=>{const cs=getComputedStyle(e);if(cs.display==='none'||cs.visibility==='hidden'||e.closest('[hidden]'))return;if(cs.position==='fixed')return;if(e.closest('.sheet,.toast,#toast,.dock,.chips'))return;const r=e.getBoundingClientRect();if(!r.width||!r.height)return;if(r.right>W+0.5||r.left<-0.5)bad.push('OUT '+e.tagName+'.'+e.className+' '+Math.round(r.left)+'~'+Math.round(r.right));if(!/INPUT|TEXTAREA|SELECT|PRE/.test(e.tagName)&&cs.overflowX==='hidden'&&cs.textOverflow==='ellipsis'&&e.scrollWidth>e.clientWidth+1)bad.push('CLIP '+e.tagName+'.'+e.className+' "'+e.textContent.slice(0,20)+'"')});return JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,n:bad.length,bad:bad.slice(0,10)})})()
'@
function RunSide([string]$side, [string]$rel) {
  $res = [ordered]@{ side = $side; file = $rel }
  Nav $rel
  Js 'localStorage.clear(); sessionStorage.clear(); return 1' | Out-Null
  Nav $rel
  $res.over_start = (Invoke-Js $OVER | ConvertFrom-Json)
  Save-Screenshot (Join-Path $shots ($app + '_' + $side + '_390_top.png'))
  $res.actions = @()
  foreach ($a in $acts) { $v = ''; try { $v = Js $a[1] } catch { $v = 'ERROR ' + $_.Exception.Message.Substring(0, [Math]::Min(160, $_.Exception.Message.Length)) }; $res.actions += [ordered]@{ name = $a[0]; result = "$v" } }
  Invoke-Js ("(()=>{const e=document.querySelector('" + $focusSel + "'); if(e){e.scrollIntoView({block:'start'}); window.scrollBy(0,-70);} return 1})()") | Out-Null; Start-Sleep -Milliseconds 400
  $res.scrollY = Invoke-Js 'Math.round(scrollY)'
  Save-Screenshot (Join-Path $shots ($app + '_' + $side + '_390.png'))
  $res.over_end = (Invoke-Js $OVER | ConvertFrom-Json)
  $res.touch_under44 = @((Invoke-Js $TOUCH | ConvertFrom-Json))
  $res.errors = @((Invoke-Js 'JSON.stringify((window.__errs||[]).concat(window.__cerr||[]))' | ConvertFrom-Json))
  return $res
}
Open-App 'oneclick\icon.png' $port
try {
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__cerr=[];(function(){var o=console.error;console.error=function(){try{window.__cerr.push('console.error '+[].slice.call(arguments).join(' ').slice(0,160))}catch(e){};return o.apply(console,arguments)}})();" } | Out-Null
  $before = RunSide 'before' ("design_review\in\" + $app + ".html")
  $after = RunSide 'after' ("design_review\out\" + $app + "_design.html")
  # 개선 포인트 3곳 표시 캡처 (런타임 겹침 표시만 · 파일 변경 없음)
  $ANN = @{ realty_parser = @('#cards .card .price', '#chips', '.exports'); seller = @('.acts', '.cfgbox', '#sum'); ad_magnet = @('#result .card .foot .btn.pri', '#result .card .top b', '#result .card pre') }[$app]
  $annJs = "(()=>{const S=" + (ConvertTo-Json @($ANN) -Compress) + ";document.querySelectorAll('.kts-ann').forEach(e=>e.remove());S.forEach((s,i)=>{const e=document.querySelector(s);if(!e)return;const r=e.getBoundingClientRect();const d=document.createElement('div');d.className='kts-ann';d.style.cssText='position:fixed;z-index:99999;pointer-events:none;border:3px solid #FF2D2D;border-radius:8px;left:'+(r.left-4)+'px;top:'+(r.top-4)+'px;width:'+(r.width+8)+'px;height:'+(r.height+8)+'px';const b=document.createElement('span');b.textContent=String(i+1);b.style.cssText='position:absolute;left:-3px;top:-22px;background:#FF2D2D;color:#fff;font:900 12px sans-serif;padding:2px 7px;border-radius:6px';d.appendChild(b);document.body.appendChild(d)});return S.filter(s=>document.querySelector(s)).length})()"
  $nAnn = Invoke-Js $annJs
  Save-Screenshot (Join-Path $shots ($app + '_after_annotated.png'))
  $same = @(0..2 | Where-Object { $before.actions[$_].result -eq $after.actions[$_].result }).Count
  $ok = @($after.actions | Where-Object { $_.result -and $_.result -notmatch '^ERROR|no card|no raw|no result' }).Count
  $out = [ordered]@{ app = $app; when = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); viewport = '390x844@2x'; static = ((& perl (Join-Path $PSScriptRoot 'verify_static.pl') (Join-Path $DR ("in\" + $app + ".html")) (Join-Path $DR ("out\" + $app + "_design.html"))) | ConvertFrom-Json)
    function_ok = "$ok/3"; function_same_as_before = "$same/3"; annotated_marks = $nAnn; before = $before; after = $after }
  $json = ConvertTo-Json $out -Depth 8
  [IO.File]::WriteAllText((Join-Path $DR ('verify_' + $app + '.json')), $json, (New-Object Text.UTF8Encoding($false)))
  Write-Output ("{0}: function {1} same {2} | errors before={3} after={4} | over after sw={5} n={6} | touch<44 before={7} after={8} | ann={9}" -f $app, $out.function_ok, $out.function_same_as_before, $before.errors.Count, $after.errors.Count, $after.over_end.sw, $after.over_end.n, $before.touch_under44.Count, $after.touch_under44.Count, $nAnn)
} finally { Stop-CdpChrome }

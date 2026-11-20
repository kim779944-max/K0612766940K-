# 과제 B(119번 더싸인 다중 날인) · C(120번 무료 4칸 슬롯) 검수 — 헤드리스 크롬 390x844 @2x
. "$PSScriptRoot\lib3d.ps1"
. "$PSScriptRoot\px.ps1"
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$OutDir = (Resolve-Path "$PSScriptRoot\..").Path
$Shots = Join-Path $OutDir 'shots'
$Doc1 = Join-Path $OutDir 'test_doc_1.png'; $Doc2 = Join-Path $OutDir 'test_doc_2.png'
$R = [ordered]@{}
$SignUrl = To-FileUrl (Join-Path $OcRoot 'sign\index.html')
$IdxUrl = To-FileUrl (Join-Path $OcRoot 'index.html')

$HOOK = "window.__saved=[];saveBlob=function(b,n){window.__saved.push({n:n,size:b.size,type:b.type});window.__lastBlob=b;};1"
$B64 = "const b2=async b=>{const u=new Uint8Array(await b.arrayBuffer());let s='';for(let i=0;i<u.length;i+=32768)s+=String.fromCharCode.apply(null,u.subarray(i,i+32768));return btoa(s)};"
function Seal([string]$name, [string]$shape) {
  Invoke-Js ("(()=>{document.querySelector('#mk button[data-m=""seal""]').click();document.querySelector('#pSeal [data-s=""" + $shape + """]').click();const i=document.querySelector('#sealName');i.value='" + $name + "';i.dispatchEvent(new Event('input'));return 1})()") | Out-Null
  Start-Sleep -Milliseconds 300
}
function TapStage([double]$fx, [double]$fy) { $r = Rect '#stage'; Tap ($r.x + $r.w * $fx) ($r.y + $r.h * $fy); Start-Sleep -Milliseconds 250 }
function Upload([string[]]$files) { Set-FileInput '#docFile' $files; Start-Sleep -Milliseconds 1800 }
function Save-LastBlob([string]$path) { $b = Js ($B64 + "return await b2(window.__lastBlob)"); [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($b)) }
function StampsJson { return (Invoke-Js "JSON.stringify(stampsOf(docs[cur]).map((s,i)=>({i:i,sid:s.sid,x:+s.x.toFixed(4),y:+s.y.toFixed(4),w:+s.w.toFixed(4),mm:+(s.w*210).toFixed(1),png:s.cv.width+'x'+s.cv.height})))") }

& "$PSScriptRoot\make_doc.ps1" | Out-Null

# ======================= B: 더싸인 =======================
Open-Page $SignUrl 9381
try {
  Upload @($Doc1)
  # 도장 1: 갑(원형 21mm)
  Seal '김갑동' 'circle'; TapStage 0.40 0.86; TapSel '#szPre [data-mm="21"]' | Out-Null
  TapSel '#sigFix' | Out-Null; Start-Sleep -Milliseconds 400
  $R.boxAskShown = Invoke-Js "!document.querySelector('#boxAsk').classList.contains('hide')"
  TapSel '#boxYes' | Out-Null; Start-Sleep -Milliseconds 400
  $R.boxConfirmText = Invoke-Js "(document.querySelector('.ksl-dim')||{}).innerText||''"
  Shot (Join-Path $Shots 'C3_stampbox_confirm_modal.png')
  TapSel '.ksl-dim [data-a="ok"]' | Out-Null; Start-Sleep -Milliseconds 400
  $R.C3_box = Invoke-Js "JSON.stringify({n:stampBox.items().length,cap:stampBox.cap(),deleteButtons:document.querySelectorAll('#stampBox .ksl-cell button:not([data-use])').length,useButtons:document.querySelectorAll('#stampBox [data-use]').length})"
  # 도장 2: 을(사각 15mm)
  Seal '이을순' 'square'; TapStage 0.82 0.86; TapSel '#szPre [data-mm="15"]' | Out-Null
  TapSel '#sigFix' | Out-Null; Start-Sleep -Milliseconds 300; TapSel '#boxNo' | Out-Null
  # 도장 3: 입회인(타원, 슬라이더 12%)
  Seal '박병' 'oval'; TapStage 0.62 0.93
  Invoke-Js "(()=>{const s=document.querySelector('#sz');s.value=12;s.dispatchEvent(new Event('input'));return 1})()" | Out-Null
  TapSel '#sigFix' | Out-Null; Start-Sleep -Milliseconds 300; TapSel '#boxNo' | Out-Null
  $R.B1_stamps = StampsJson
  $R.B1_dom = Invoke-Js "document.querySelectorAll('#stage .sig.stamp').length"
  Shot-Clip (Join-Path $Shots 'B1_three_stamps_preview.png') '#stage'
  # B3: 두 번째 도장만 선택 → 끌기 → 18mm
  $before3 = StampsJson
  $e = Rect '#stage .sig[data-s="1"]'
  Drag ($e.x + $e.w / 2) ($e.y + $e.h / 2) ($e.x + $e.w / 2 - 60) ($e.y + $e.h / 2 - 50) 8
  Start-Sleep -Milliseconds 300
  TapSel '#szPre [data-mm="18"]' | Out-Null
  $R.B3_before = $before3; $R.B3_after = StampsJson
  $R.B3_sel = Invoke-Js "JSON.stringify({sel:sel,dashed:[...document.querySelectorAll('#stage .sig')].map(n=>n.dataset.s+':'+(n.classList.contains('uns')?'no':'yes'))})"
  Shot-Clip (Join-Path $Shots 'B3_second_moved_resized.png') '#stage'
  # B2: PDF 1회 저장 — 3개 다 찍힘
  Invoke-Js $HOOK | Out-Null
  TapSel '#outPdf' | Out-Null; Start-Sleep -Milliseconds 1500
  $R.B2_saved = Invoke-Js "JSON.stringify(window.__saved)"
  Save-LastBlob (Join-Path $Shots 'B2_three_stamps_once.pdf')
  $R.B2_redPixels = Invoke-Js "JSON.stringify((()=>{const c=composePage(0),x=c.getContext('2d');return stampsOf(docs[0]).map(s=>{const w=s.w*c.width,h=w*s.cv.height/s.cv.width;const d=x.getImageData(Math.round(s.x*c.width-w/2),Math.round(s.y*c.height-h/2),Math.round(w),Math.round(h)).data;let r=0;for(let i=0;i<d.length;i+=4)if(d[i]>150&&d[i+1]<110&&d[i+2]<110)r++;return r})})())"
  Js ($B64 + "const c=composePage(0);const b=await new Promise(r=>c.toBlob(r,'image/jpeg',0.9));window.__lastBlob=b;return 1") | Out-Null
  Save-LastBlob (Join-Path $Shots 'B2_composed_page1.jpg')
  # 도장함에서 꺼내 찍기
  $e2 = Rect '#stampBox [data-use]'
  Tap ($e2.x + $e2.w / 2) ($e2.y + $e2.h / 2); Start-Sleep -Milliseconds 600
  $R.C3_use = Invoke-Js "JSON.stringify({sig:!!sig,sigSize:sig?sig.width+'x'+sig.height:'',prevImg:!!document.querySelector('#prev img')})"
  Shot-Clip (Join-Path $Shots 'C3_stampbox_panel.png') '#stampBox'
  # 이 도장 빼기(선택만)
  TapSel '#stage .sig[data-s="2"]' | Out-Null
  TapSel '#sigDel' | Out-Null; Start-Sleep -Milliseconds 300
  $R.B3_delete = StampsJson
  $R.B_sw = Invoke-Js "document.documentElement.scrollWidth"
  $R.B_err = (Evts-Summary); $R.B_errList = @($global:EVTS | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(160, $_.text.Length)) })
} finally { Stop-CdpChrome }
Clear-Evts

# ---------- B4: 도장 1개 기존 흐름 — 149a7de 판과 결과 비교 ----------
$BaseDir = Join-Path $env:TEMP 'oc_base_sign_149a7de'
if (Test-Path $BaseDir) { Remove-Item -Recurse -Force $BaseDir }
New-Item -ItemType Directory -Force (Join-Path $BaseDir 'sign') | Out-Null
Copy-Item (Join-Path $OcRoot 'master.js') $BaseDir
Push-Location $OcRoot; $oldSign = (git show 149a7de:sign/index.html) -join "`n"; Pop-Location
[IO.File]::WriteAllText((Join-Path $BaseDir 'sign\index.html'), $oldSign, (New-Object Text.UTF8Encoding($false)))
function One-Stamp([string]$url, [string]$tag) {
  Open-Page $url 9382
  try {
    Upload @($Doc1); Seal '김갑동' 'circle'; TapStage 0.40 0.86; TapSel '#szPre [data-mm="21"]' | Out-Null
    Invoke-Js $HOOK | Out-Null
    TapSel '#outImg' | Out-Null; Start-Sleep -Milliseconds 1500
    $s = Invoke-Js "JSON.stringify(window.__saved)"
    Save-LastBlob (Join-Path $Shots ("B4_" + $tag + "_one_stamp.jpg"))
    $pl = Invoke-Js "JSON.stringify(docs[0].place)"
    $ev = (Evts-Summary)
  } finally { Stop-CdpChrome }
  Clear-Evts
  return [ordered]@{ saved = $s; place = $pl; evts = $ev }
}
$R.B4_base = One-Stamp (To-FileUrl (Join-Path $BaseDir 'sign\index.html')) 'base'
$R.B4_new = One-Stamp $SignUrl 'new'
$R.B4_pixDiff = [PxCmp]::Diff((Join-Path $Shots 'B4_base_one_stamp.jpg'), (Join-Path $Shots 'B4_new_one_stamp.jpg'), 0)
$R.B4_sha = @((Sha (Join-Path $Shots 'B4_base_one_stamp.jpg')), (Sha (Join-Path $Shots 'B4_new_one_stamp.jpg')))
Remove-Item -Recurse -Force $BaseDir

# ---------- B5: 무료 1쪽 · PRO 워터마크 · 간인 ----------
Open-Page $SignUrl 9383
try {
  Upload @($Doc1, $Doc2)
  $R.B5_free = Invoke-Js "JSON.stringify({plan:plan,pages:docs.length,multiple:document.querySelector('#docFile').multiple})"
  TapSel '.plan[data-p="pro"]' | Out-Null; Start-Sleep -Milliseconds 300
  Upload @($Doc1, $Doc2)
  Seal '김갑동' 'circle'; TapStage 0.40 0.86; TapSel '#sigFix' | Out-Null; TapSel '#boxNo' | Out-Null
  Seal '이을순' 'square'; TapStage 0.82 0.86
  TapSel '#ganin' | Out-Null; Start-Sleep -Milliseconds 400
  $R.B5_pro = Invoke-Js "JSON.stringify((()=>{const c=composePage(0),d=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let wm=0;for(let i=0;i<d.length;i+=4){if(Math.abs(d[i]-255)<10&&Math.abs(d[i+1]-209)<16&&Math.abs(d[i+2]-184)<16)wm++}return {plan:plan,unlocked:unlocked(),pages:docs.length,ganin:ganin,seams0:seamsFor(0).length,seams1:seamsFor(1).length,seamEls:document.querySelectorAll('#stage .seam').length,watermarkPx:wm,stamps:stampsOf(docs[0]).length,place:!!docs[0].place}})())"
  Shot-Clip (Join-Path $Shots 'B5_pro_preview_ganin.png') '#stage'
  Js ($B64 + "const c=composePage(0);const b=await new Promise(r=>c.toBlob(r,'image/jpeg',0.85));window.__lastBlob=b;return 1") | Out-Null
  Save-LastBlob (Join-Path $Shots 'B5_pro_watermark_page1.jpg')
  $R.B5_sw = Invoke-Js "document.documentElement.scrollWidth"
  $R.B5_err = (Evts-Summary)
} finally { Stop-CdpChrome }
Clear-Evts

# ======================= C: 단축바 4칸 =======================
Open-Page $IdxUrl 9384
try {
  $ids = (Invoke-Js "JSON.stringify([...document.querySelectorAll('#plist [data-fav]')].slice(0,6).map(b=>b.dataset.fav))") | ConvertFrom-Json
  $R.C_ids = $ids
  for ($i = 0; $i -lt 4; $i++) {
    Invoke-Js ("document.querySelector('#plist [data-fav=""" + $ids[$i] + """]').click();1") | Out-Null; Start-Sleep -Milliseconds 250
    if ($i -eq 0) { $R.C1_confirmText = Invoke-Js "(document.querySelector('.ksl-dim')||{}).innerText||''"; Shot (Join-Path $Shots 'C1_confirm_before_add.png') }
    Invoke-Js "document.querySelector('.ksl-dim [data-a=""ok""]').click();1" | Out-Null; Start-Sleep -Milliseconds 250
  }
  $R.C1_after4 = Invoke-Js "JSON.stringify(FAVSL.state())"
  Invoke-Js ("document.querySelector('#plist [data-fav=""" + $ids[4] + """]').click();1") | Out-Null; Start-Sleep -Milliseconds 400
  $R.C1_fifth = Invoke-Js "JSON.stringify({sheet:!!document.querySelector('.ksl-dim'),text:(document.querySelector('.ksl-dim')||{}).innerText||'',items:FAVSL.items().length})"
  Shot (Join-Path $Shots 'C1_fifth_add_sheet.png')
  Invoke-Js "document.querySelector('.ksl-dim [data-a=""close""]').click();1" | Out-Null
  Invoke-Js ("document.querySelector('#plist [data-fav=""" + $ids[0] + """]').click();1") | Out-Null; Start-Sleep -Milliseconds 300
  $R.C1_unpin = Invoke-Js "JSON.stringify({items:FAVSL.items().length,toast:(document.querySelector('.ksl-toast')||{}).textContent||''})"
  TapSel '#tabs button[data-c="fav"]' | Out-Null; Start-Sleep -Milliseconds 400
  $R.C1_panelButtons = Invoke-Js "JSON.stringify([...document.querySelectorAll('#favSlots button')].map(b=>b.textContent+(b.disabled?'(off)':'')))"
  $R.C1_favTab = Invoke-Js "JSON.stringify({count:document.querySelector('#count').textContent,cards:document.querySelectorAll('#plist .prow').length})"
  Shot (Join-Path $Shots 'C1_fav_tab_4_of_4.png')
  # C2 초기화
  TapSel '#favSlots [data-a="reset"]' | Out-Null; Start-Sleep -Milliseconds 300
  TapSel '.ksl-dim [data-a="ok"]' | Out-Null; Start-Sleep -Milliseconds 300
  $R.C2_after = Invoke-Js "JSON.stringify({st:FAVSL.state(),canReset:FAVSL.canReset(),next:FAVSL.nextReset(),panel:document.querySelector('#favSlots').innerText,resetDisabled:document.querySelector('#favSlots [data-a=""reset""]').disabled})"
  $R.C2_second = Js "return await FAVSL.reset()"
  $R.C2_toast = Invoke-Js "(document.querySelector('.ksl-toast')||{}).textContent||''"
  Invoke-Js ("document.querySelector('#tabs button[data-c=""all""]').click();document.querySelector('#plist [data-fav=""" + $ids[1] + """]').click();1") | Out-Null; Start-Sleep -Milliseconds 250
  Invoke-Js "document.querySelector('.ksl-dim [data-a=""ok""]').click();1" | Out-Null
  TapSel '#tabs button[data-c="fav"]' | Out-Null; Start-Sleep -Milliseconds 300
  $R.C2_resetBtnAfter = Invoke-Js "JSON.stringify({disabled:document.querySelector('#favSlots [data-a=""reset""]').disabled,sub:document.querySelector('#favSlots .sub').textContent})"
  Shot (Join-Path $Shots 'C2_reset_used_next_date.png')
  # C3 코드
  $R.C3_codes = Invoke-Js "JSON.stringify((()=>{const fnv=s=>{let h=0x811c9dc5;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,0x01000193)>>>0}return h};const yy=d=>String(d.getFullYear()).slice(2)+String(d.getMonth()+1).padStart(2,'0');const mk=m=>'KS'+m+'-'+fnv('kts-sign-'+m).toString(16).toUpperCase().padStart(8,'0').slice(0,4);const n=new Date(),p=new Date(n.getFullYear(),n.getMonth()-1,1);const cur=mk(yy(n)),prev=mk(yy(p));const r={cur:cur,prev:prev,okCur:KTSSlots.codeOk(cur),okPrev:KTSSlots.codeOk(prev),okJunk:KTSSlots.codeOk('KS'+yy(n)+'-0000')};r.unlockPrev=FAVSL.unlock(prev);r.capAfterPrev=FAVSL.cap();r.unlockCur=FAVSL.unlock(cur);r.capAfterCur=FAVSL.cap();return r})())"
  Invoke-Js "localStorage.setItem('kts_master','2899');1" | Out-Null
  Go-Url $IdxUrl
  $R.C3_master = Invoke-Js "JSON.stringify({master:window.KTS_MASTER,capInfinite:FAVSL.cap()===Infinity,full:FAVSL.full(),canReset:FAVSL.canReset()})"
  Invoke-Js "localStorage.removeItem('kts_master');1" | Out-Null
  # C5 초대
  $R.C5_link = Invoke-Js "KTSSlots.ref.link()"
  $R.C5_share = Js "return await KTSSlots.ref.share()"
  Go-Url ($IdxUrl + '?ref=ABCD2345')
  $R.C5_incoming = Invoke-Js "JSON.stringify({note:(document.querySelector('#refNote')||{}).innerText||'',from:localStorage.getItem('kts_ref_from'),cap:FAVSL.cap(),added:FAVSL.state().added})"
  Shot (Join-Path $Shots 'C5_ref_notice.png')
  $R.C_sw = Invoke-Js "document.documentElement.scrollWidth"
  $R.C_err = (Evts-Summary); $R.C_errList = @($global:EVTS | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(160, $_.text.Length)) })
} finally { Stop-CdpChrome }
Clear-Evts

# ---------- C4: 기존 kts_favs 5개 사용자 (유예) ----------
Open-Page $IdxUrl 9385
try {
  $ids5 = (Invoke-Js "JSON.stringify([...document.querySelectorAll('#plist [data-fav]')].slice(0,6).map(b=>b.dataset.fav))") | ConvertFrom-Json
  Invoke-Js ("localStorage.removeItem('kts_slots_v1_fav');localStorage.setItem('kts_favs',JSON.stringify(" + (ConvertTo-Json -Compress @($ids5[0..4])) + "));1") | Out-Null
  Go-Url $IdxUrl
  $R.C4_load = Invoke-Js "JSON.stringify({old:JSON.parse(localStorage.getItem('kts_favs')),st:FAVSL.state(),grace:FAVSL.grace(),full:FAVSL.full()})"
  Invoke-Js ("document.querySelector('#plist [data-fav=""" + $ids5[5] + """]').click();1") | Out-Null; Start-Sleep -Milliseconds 300
  $R.C4_add6 = Invoke-Js "JSON.stringify({sheet:!!document.querySelector('.ksl-dim'),items:FAVSL.items().length,oldKey:localStorage.getItem('kts_favs')})"
  Invoke-Js "document.querySelector('.ksl-dim [data-a=""close""]').click();1" | Out-Null
  TapSel '#tabs button[data-c="fav"]' | Out-Null; Start-Sleep -Milliseconds 300
  $R.C4_favTab = Invoke-Js "JSON.stringify({cards:document.querySelectorAll('#plist .prow').length,panel:document.querySelector('#favSlots').innerText})"
  Shot (Join-Path $Shots 'C4_grace_5_kept.png')
  $R.C4_err = (Evts-Summary)
} finally { Stop-CdpChrome }
Clear-Evts

$out = Join-Path $OutDir 'verify_bc_result.json'
$R | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $out
Write-Output "saved $out"

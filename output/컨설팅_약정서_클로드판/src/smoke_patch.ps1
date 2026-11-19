# patch/ 수정본을 TEMP 복사본에만 적용해 2쪽 합성(미리보기·인쇄 준비)을 시험 — oneclick 원본은 읽기만 함
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$ErrorActionPreference = 'Stop'
$PKG = (Resolve-Path "$PSScriptRoot\..").Path
$RAW = Join-Path $PKG '측정_원자료'
$OC = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$T = Join-Path $env:TEMP 'consult_smoke'
if (Test-Path $T) { Remove-Item -Recurse -Force $T }
New-Item -ItemType Directory -Force (Join-Path $T 'contract') | Out-Null
Copy-Item (Join-Path $OC 'contract\*') (Join-Path $T 'contract') -Recurse
foreach ($f in 'master.js', 'freekey.js', 'ai.js') { Copy-Item (Join-Path $OC $f) $T }
# 적용(복사본에만)
Copy-Item (Join-Path $PKG 'patch\index.html') (Join-Path $T 'contract\index.html') -Force
Copy-Item (Join-Path $PKG 'forms_consult.js') (Join-Path $T 'contract') -Force
Get-ChildItem $PKG -Filter 'tpl_consult_p*.png' | ForEach-Object { Copy-Item $_.FullName (Join-Path $T 'contract') -Force }
$log = @()
Start-CdpChrome 9591 | Out-Null
try {
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];addEventListener('error',function(e){var t=e.target;__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);window.print=function(){window.__printed=(window.__printed||0)+1};" } | Out-Null
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl (Join-Path $T 'contract\index.html')) } | Out-Null
  Start-Sleep -Milliseconds 2500
  # 시험 값(가짜·임시: 화면 안에서만, 저장소에 남기지 않음)
  $r = Invoke-Js @'
(async()=>{
  const K = window.KC; const forms = K.FORMS.map(f => f.id);
  K.setForm('consult');
  await new Promise(r => setTimeout(r, 300));
  const v = {a_name:'시험갑', b_name:'시험을', o_target:'시험 대상물', o_months:'6', t_from_y:'2026', t_to_d:'30', f_total:'1000000', f_r1:'10', f_m1:'100000', f_etc:'시험 특약 한 줄\n둘째 줄', date_y:'26', s_a_name:'시험갑', s_b_name:'시험을'};
  Object.keys(v).forEach(k => K.setV(k, v[k]));
  K.go(4);
  await new Promise(r => setTimeout(r, 4000));
  const pv = document.getElementById('pvCv'); const pvWH = [pv.width, pv.height];
  const p1 = await K.composite(1200, 1), p2 = await K.composite(1200, 2);
  document.getElementById('printBtn').click();
  await new Promise(r => setTimeout(r, 2500));
  const imgs = document.querySelectorAll('#printArea img').length;
  K.setForm('sale'); await new Promise(r => setTimeout(r, 300)); K.go(4); await new Promise(r => setTimeout(r, 1200));
  const pvSale = document.getElementById('pvCv');
  return JSON.stringify({forms, consultFields: K.FORMS.find(f => f.id === 'consult').fields.length, pv: pvWH, p1: [p1.width, p1.height], p2: [p2.width, p2.height], printImgs: imgs, printed: window.__printed || 0, salePv: [pvSale.width, pvSale.height], errs: window.__errs});
})()
'@ -await
  $log += "smoke: " + $r
  # 합성 결과 저장(시험 값이 그려진 2쪽) — 저장 후 시험 값 지움
  $b64 = Invoke-Js "(async()=>{const K=window.KC;K.setForm('consult');await new Promise(r=>setTimeout(r,300));const c=await K.composite(1200,2);return c.toDataURL('image/png').split(',')[1]})()" -await
  [IO.File]::WriteAllBytes((Join-Path $RAW 'smoke_patch_p2.png'), [Convert]::FromBase64String($b64))
  $b64 = Invoke-Js "(async()=>{const c=await window.KC.composite(1200,1);return c.toDataURL('image/png').split(',')[1]})()" -await
  [IO.File]::WriteAllBytes((Join-Path $RAW 'smoke_patch_p1.png'), [Convert]::FromBase64String($b64))
  Invoke-Js "(()=>{localStorage.clear();return 1})()" | Out-Null
} finally { Stop-CdpChrome }
Remove-Item -Recurse -Force $T
$log += "oneclick status: [" + ((& git -C $OC status --short) -join ' ') + "]"
$log | Set-Content -Encoding UTF8 (Join-Path $RAW 'smoke_patch_log.txt')
$log

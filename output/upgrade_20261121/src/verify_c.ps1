. "$PSScriptRoot\lib.ps1"
Start-Serve
$R = [ordered]@{}
try {
  Open-Page ($global:Base + 'hogang/') 9374
  Start-Sleep -Milliseconds 1500
  ShotP 'C2_hogang_first_390x844.png'
  # C2 첫 화면(스크롤 0) 안에 보이는지
  $R.C2 = J @"
var vh=innerHeight,ids=['t1Dev','t1Mon','t1Save'],o={scrollY:scrollY,vh:vh};
ids.forEach(function(i){var r=document.getElementById(i).getBoundingClientRect();o[i]=Math.round(r.bottom);});
var em=document.querySelector('.top1 .save em');o.wow=em.textContent;o.wowBottom=Math.round(em.getBoundingClientRect().bottom);
var li=document.querySelectorAll('#t1How li');o.howCount=li.length;o.howBottom=Math.round(li[li.length-1].getBoundingClientRect().bottom);
o.allVisible=[o.t1Dev,o.t1Mon,o.t1Save,o.wowBottom,o.howBottom].every(function(b){return b<=vh;});
o.dev=document.getElementById('t1Dev').textContent;o.mon=document.getElementById('t1Mon').textContent;o.save=document.getElementById('t1Save').textContent;
o.how=[].map.call(li,function(x){return x.textContent;});o.calcButton=!!document.querySelector('#btnGo');
return JSON.stringify(o);
"@
  # C1 입력 6종 각각 변경 → 1등 갱신 시간
  $tests = @(
    @('#iModel','13'), @('#iPlan','0'), @('#iLeft','12'), @('#iCombo','fam'), @('#iWay','self'), @('#iData','9999')
  )
  $c1 = @()
  foreach ($t in $tests) {
    $one = J @"
var e=document.querySelector('$($t[0])'),before=document.getElementById('top1').innerText;
var t0=performance.now();e.value='$($t[1])';e.dispatchEvent(new Event('change',{bubbles:true}));
var dt=performance.now()-t0,after=document.getElementById('top1').innerText;
return JSON.stringify({input:'$($t[0])',value:'$($t[1])',ms:+dt.toFixed(2),calcMs:window.__HOGANG.ms,changed:before!==after,best:window.__HOGANG.best});
"@
    $c1 += $one
  }
  $R.C1 = $c1
  # 기본값 복귀
  J "var s={'#iModel':'0','#iPlan':'2','#iLeft':'0','#iCombo':'none','#iWay':'chg','#iData':'100'};Object.keys(s).forEach(function(k){var e=document.querySelector(k);e.value=s[k];e.dispatchEvent(new Event('change'));});return 1" | Out-Null
  # C3 위약금 3케이스 (요금제 스탠다드 85,000 · 데이터 100GB)
  $c3 = @()
  foreach ($L in 6, 12, 18) {
    $c3 += (J @"
var e=document.querySelector('#iLeft');e.value='$L';e.dispatchEvent(new Event('change'));
var d=document.querySelector('#penBody details');
return JSON.stringify({left:$L,verdict:(document.getElementById('penVerdict')||{}).textContent,breakEven:(document.getElementById('penBE')||{}).textContent,pen:window.__HOGANG.pen,formulaShown:!!d&&d.textContent.indexOf('위약금 =')>=0});
"@)
    if ($L -eq 12) { J "document.querySelector('#penBody details').open=true;document.getElementById('penBox').scrollIntoView();return 1" | Out-Null; Start-Sleep -Milliseconds 300; ShotP 'C3_penalty_12m.png' }
  }
  $R.C3 = $c3
  # C4 요금제 연동: 선택약정 25% · 결합 · 유지조건 경고
  $R.C4 = J @"
function set(k,v){var e=document.querySelector(k);e.value=v;e.dispatchEvent(new Event('change'));}
set('#iLeft','0');set('#iData','15');set('#iPlan','0');set('#iCombo','none');
var a=window.__HOGANG.routes.slice();var mnp55=a[0].cond;var warnShown55=document.getElementById('planWarn').innerText.indexOf('조건 미충족')>=0;
set('#iPlan','1');var b=window.__HOGANG.routes.slice();var mnp69={cond:b[0].cond,warn:b[0].warn,keepIncluded:b[0].total};var warnShown69=document.getElementById('planWarn').innerText.indexOf('조건 미충족')>=0;
set('#iPlan','2');var sel=window.__HOGANG.routes[1];
set('#iCombo','net');var withNet=window.__HOGANG.routes[1];
set('#iCombo','none');
return JSON.stringify({plan55_cond:mnp55,plan55_badge:warnShown55,plan69:mnp69,plan69_badge:warnShown69,chg_kind:sel.kind,chg_mon_noCombo:sel.mon,chg_mon_netCombo:withNet.mon,selDiscount:'85000*0.75='+(85000*0.75),comboDelta:sel.mon-withNet.mon});
"@
  J "var e=document.querySelector('#iPlan');e.value='0';e.dispatchEvent(new Event('change'));document.getElementById('planWarn').scrollIntoView({block:'center'});return 1" | Out-Null
  Start-Sleep -Milliseconds 300; ShotP 'C4_keep_condition_warn.png'
  J "var e=document.querySelector('#iPlan');e.value='2';e.dispatchEvent(new Event('change'));var d=document.querySelector('#iData');d.value='100';d.dispatchEvent(new Event('change'));return 1" | Out-Null
  # C6 4경로 표
  $R.C6 = J @"
var rows=[].map.call(document.querySelectorAll('#cmp tbody tr'),function(tr){return {best:tr.classList.contains('best'),cells:[].map.call(tr.cells,function(td){return td.textContent;})};});
return JSON.stringify({rows:rows.length,allFilled:rows.every(function(r){return r.cells.length===6&&r.cells.every(function(c){return c.trim().length>0;});}),bestCount:rows.filter(function(r){return r.best;}).length,why:document.getElementById('why1').textContent,list:rows});
"@
  J "document.getElementById('cmp').scrollIntoView();return 1" | Out-Null; Start-Sleep -Milliseconds 300; ShotP 'C6_routes_table.png'
  # C5 기종 데이터
  $R.C5 = Js @"
return await fetch('data/models.json').then(function(r){return r.json();}).then(function(d){
  var need=['id','name','maker','launchPrice','display','chip','cam','batt','weight','img','source','asOf'],miss=[];
  d.models.forEach(function(m){need.forEach(function(k){if(m[k]===undefined||m[k]==='')miss.push(m.id+'.'+k);});});
  var ph=Object.keys(d.photos||{});
  return Promise.all(ph.map(function(id){var m=d.models.filter(function(x){return x.id===id;})[0];return fetch(m.img).then(function(r){return r.ok?1:0;});})).then(function(ok){
    return JSON.stringify({models:d.models.length,missingFields:miss.length,missList:miss,photos:ph.length,photoFilesOk:ok.reduce(function(a,b){return a+b;},0),noPhoto:d.models.filter(function(m){return ph.indexOf(m.id)<0;}).map(function(m){return m.id;})});
  });
});
"@
  # C7 정직 표기
  $R.C7 = J @"
var t=document.body.innerText;
return JSON.stringify({footnotes:(t.match(/2026-11-21 기준 예시값 · 통신사 공시지원금·요금제는 변동됩니다/g)||[]).length,realtime:(t.match(/실시간/g)||[]).length});
"@
  # C8 390·가로 스크롤
  $R.C8 = J @"
var over=[].filter.call(document.querySelectorAll('main *'),function(e){return e.scrollWidth-e.clientWidth>1&&getComputedStyle(e).overflowX!=='visible';}).map(function(e){return e.tagName+'.'+e.className;});
return JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,tableW:document.getElementById('cmp').scrollWidth,overflowEls:over});
"@
  J "document.getElementById('mdlBox').scrollIntoView();return 1" | Out-Null; Start-Sleep -Milliseconds 300; ShotP 'C5_model_cards.png'
  ShotFull 'C_hogang_full.png'
  $R.evts = Evts-Summary
  $R.evtList = @($global:EVTS | Select-Object -First 5 | ForEach-Object { $_.kind + ' :: ' + $_.text })
} finally { Stop-CdpChrome }
$R | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_c_result.json')
$R | ConvertTo-Json -Depth 6

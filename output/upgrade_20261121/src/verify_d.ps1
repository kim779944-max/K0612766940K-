. "$PSScriptRoot\lib.ps1"
Start-Serve
$R = [ordered]@{}
function Put([string]$sel, [string]$btn, [string]$txt) { return J "var e=document.querySelector('$sel');e.value='$txt';document.querySelector('$btn').click();return JSON.stringify(window.__GAGEBU.judges)" }
try {
  Open-Page ($global:Base + 'gagebu/') 9375
  J "localStorage.removeItem('kts_gagebu_v2');location.reload();return 1" | Out-Null
  Start-Sleep -Milliseconds 1500
  ShotP 'D_gagebu_first.png'
  # D1 팝업·결산
  $R.D1 = J @"
var vis=[].filter.call(document.querySelectorAll('.sheet,.modal,dialog,[role=dialog],.popup,.pop'),function(e){var s=getComputedStyle(e);return s.display!=='none'&&s.visibility!=='hidden';}).length;
var t=document.body.innerText;
return JSON.stringify({visibleOverlays:vis,word_gyeolsan:(t.match(/결산/g)||[]).length,sourceHits:(document.documentElement.outerHTML.match(/결산/g)||[]).length,btns:[].map.call(document.querySelectorAll('button'),function(b){return b.textContent.trim();})});
"@
  # D2 입력 3건 → 자동 분류 3/3 · 새로고침 유지 · 합계
  Put '#inBuy' '#btnAdd' '양파 1.8kg 3900원 하나로마트' | Out-Null
  Put '#inBuy' '#btnAdd' '샴푸 1개 8900원 다이소' | Out-Null
  Put '#inBuy' '#btnAdd' '커피 1개 4500원 편의점' | Out-Null
  $before = J "return JSON.stringify(window.__GAGEBU)"
  J "location.reload();return 1" | Out-Null
  Start-Sleep -Milliseconds 1500
  $after = J "return JSON.stringify(window.__GAGEBU)"
  $R.D2 = @{ before = $before; afterReload = $after; expectSum = (3900 + 8900 + 4500) }
  ShotP 'D2_three_items.png'
  # D3 분기: 데이터 없음 / 가장 쌈 / 일반 문형 / 양 많음 / 먼 곳 / 비교 불가
  $d3 = [ordered]@{}
  $d3.noData = J "return JSON.stringify(window.__GAGEBU.judges)"
  Put '#inPrice' '#btnPrice' '샴푸 1개 9900원 동네마트' | Out-Null
  Put '#inPrice' '#btnPrice' '양파 1.5kg 2900원 대형마트' | Out-Null
  $d3.cheapest_and_generic = J "return JSON.stringify(window.__GAGEBU.judges)"
  Put '#inBuy' '#btnAdd' '계란 30구 7200원 하나로마트' | Out-Null
  Put '#inPrice' '#btnPrice' '계란 10구 2000원 동네시장' | Out-Null
  $d3.many = J "return JSON.stringify(window.__GAGEBU.judges.filter(function(j){return j.name==='계란'}))"
  J "[].forEach.call(document.querySelectorAll('.pl'),function(b){if(b.dataset.p==='대형마트')b.click();});return 1" | Out-Null
  $d3.far = J "return JSON.stringify(window.__GAGEBU.judges.filter(function(j){return j.name==='양파'}))"
  Put '#inBuy' '#btnAdd' '두부 1개 1500원 하나로마트' | Out-Null
  Put '#inPrice' '#btnPrice' '두부 300g 1200원 동네시장' | Out-Null
  $d3.unitMismatch = J "return JSON.stringify(window.__GAGEBU.judges.filter(function(j){return j.name==='두부'}))"
  $d3.oneLine = J "return document.getElementById('oneLine').textContent"
  $R.D3 = $d3
  ShotP 'D3_one_line.png'
  # D4 한 줄 · 자세히 · 상태 기억
  $d4 = [ordered]@{}
  $d4.closedByDefault = J "return document.getElementById('detail').hidden"
  J "document.getElementById('btnDetail').click();return 1" | Out-Null
  $d4.openCols = J "return document.querySelectorAll('#dtTable thead th').length"
  $d4.headers = J "return [].map.call(document.querySelectorAll('#dtTable thead th'),function(t){return t.textContent}).join(' / ')"
  $d4.rows = J "return document.querySelectorAll('#dtTable tbody tr').length"
  $d4.concl = J "return document.getElementById('concl').textContent"
  ShotFull 'D4_detail_open_full.png'
  J "location.reload();return 1" | Out-Null
  Start-Sleep -Milliseconds 1500
  $d4.openAfterReload = J "return !document.getElementById('detail').hidden"
  $R.D4 = $d4
  # D5 단가 정규화
  $R.D5 = J @"
var N=window.__GAGEBU_API.norm,P=window.__GAGEBU_API.parse;
var c=['양파 1.8kg 3900원 A','우유 900ml 2500원 A','우유 2.3L 5600원 A','계란 30구 7200원 A','밀가루 500g 1500원 A'].map(function(s){var p=P(s);var n=N(p);return s+' → '+n.label+' '+Math.round(n.per)+'원 ('+n.kind+')';});
return JSON.stringify(c);
"@
  # D6 390 · 표 스택 · 오류
  $R.D6 = J "return JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,theadDisplay:getComputedStyle(document.querySelector('#dtTable thead')).display,trDisplay:getComputedStyle(document.querySelector('#dtTable tbody tr')).display})"
  $R.evts = Evts-Summary
  $R.evtList = @($global:EVTS | Select-Object -First 5 | ForEach-Object { $_.kind + ' :: ' + $_.text })
  J "localStorage.removeItem('kts_gagebu_v2');return 1" | Out-Null
} finally { Stop-CdpChrome }
$R | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_d_result.json')
$R | ConvertTo-Json -Depth 6

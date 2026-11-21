. "$PSScriptRoot\lib.ps1"
Start-Serve
$R = [ordered]@{}
try {
  Open-Page ($global:Base + 'navi2/') 9373
  Start-Sleep -Milliseconds 1500
  # A1 캡션 형식 · A3 재탕 · A7 나이대 3벌
  $R.A1 = J @"
var out=NAVI.START.map(function(p){var n=p.cap.length;return {id:p.id,cap:p.cap,len:n,ok:n>=12&&n<=20&&!/[.。]$/.test(p.cap)&&/(다|요)$/.test(p.cap),sub:(p.sub||'')};});
return JSON.stringify({all:out.every(function(x){return x.ok&&x.sub.length<=8;}),list:out});
"@
  $R.A3 = J @"
var keys={};Object.keys(NAVI.IMG).forEach(function(k){keys[k]=1;});
var startImgs=NAVI.START.map(function(p){return p.img;});
var n=0,hit=[],total=0;
Object.keys(NAVI.Q).forEach(function(lv){Object.keys(NAVI.Q[lv]).forEach(function(br){NAVI.Q[lv][br].opts.forEach(function(o){total++;if(o.im!==undefined){n++;if(keys[o.im]||startImgs.indexOf(NAVI.IMG[o.im])>=0)hit.push(lv+br+':'+o.im);}});});});
return JSON.stringify({optsTotal:total,optsWithIm:n,intersection:hit.length,hits:hit,renderMode:'text-only (보기 그림 제거)'});
"@
  $R.A7 = J @"
var C=window.CARDS,bands=['young','mid','senior'],P=NAVI.FATE.PAST,fields=['line','good','risk','hedge','rx','strength','softness'];
var seen={},dup=[],cnt=0;
Object.keys(C).forEach(function(k){bands.forEach(function(b){
  var parts=[C[k].line[b],P[k][b],C[k].good[b],C[k].risk[b],C[k].hedge[b]];
  var key=parts.join('|');cnt++;
  if(seen[key])dup.push(k+'/'+b);seen[key]=1;
  parts.forEach(function(s,i){var kk='f'+i+':'+s; if(seen[kk]) dup.push('field '+k+'/'+b+'#'+i); seen[kk]=1;});
});});
return JSON.stringify({combos:cnt,duplicates:dup.length,dupList:dup});
"@
  $R.evts = Evts-Summary
} finally { Stop-CdpChrome }
# A6 금지어 (파일 전수)
$ban = [string][char]0xC131 + [char]0xACA9
$hits = @(Get-ChildItem -Recurse -File (Join-Path $global:OcRoot 'navi2') | Where-Object { $_.Extension -in '.js','.html','.json','.md','.webmanifest' } | ForEach-Object { $t = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8); $c = ([regex]::Matches($t, $ban)).Count; if ($c) { "$($_.Name):$c" } })
$R.A6 = @{ count = $hits.Count; files = $hits }
$R | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\verify_a_result.json')
$R | ConvertTo-Json -Depth 6

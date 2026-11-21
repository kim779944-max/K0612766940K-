. "$PSScriptRoot\lib.ps1"
Start-Serve
$JS = @'
var c=await (await fetch('http://127.0.0.1:8765/catalog.json',{cache:'no-store'})).json();
function find(k){return c.products.filter(function(p){return p.k===k})[0]}
/* 지시서 6-2 객체 그대로 — 단 cat 은 허브에 'life' 칸이 없어 기존 'etc' 로 맞춤(지시서 허용) */
var add=[
{"k":"gagebu","nm":"원클릭 가계부","sub":"오늘 산 것 자동 정리 · 더 싼 곳 1초 비교","cat":"etc","badge":"NEW","status":"live","icon":"shots/ic_gagebu.png","price":"무료","price2":"기록은 기기 안에만","line":"오늘 뭘 샀는지만 넣으면, 다른 곳 값과 나란히 놓고 한 줄로 알려 줍니다.","blurb":"영수증 품목을 넣으면 자동 분류하고, 100g·1개·1L 단가로 바꿔 다른 곳과 비교합니다. 접혀 있을 때는 한 줄, 누르면 상세 표와 한 달 절약액까지.","link":"gagebu/","shot":"shots/gagebu_home.png","bullets":[["자동","품목·분류·금액 자동 정리"],["비교","단가 환산 · 더 싼 곳 안내"],["한 줄","오늘 결론은 한 줄, 누르면 표"]],"how":["오늘 산 품목을 넣습니다.","자동 분류된 오늘 목록을 봅니다.","더 싼 곳과 한 달 절약액을 확인합니다."],"notes":["가격은 입력·비교 시점 기준이며 실제 매장가와 다를 수 있습니다.","기록은 서버로 보내지 않고 기기 안에만 저장됩니다."]},
{"k":"hogang","nm":"호갱 탈출 내비","sub":"기종·요금제·약정 넣으면 최저가 한 줄","cat":"etc","badge":"NEW","status":"live","icon":"shots/ic_hogang.png","price":"무료","price2":"가입 없이 계산","line":"바꿀 때마다 다시 계산해서, 맨 위에 제일 싼 답 하나만 보여 줍니다.","blurb":"기종·요금제·약정 잔여·결합을 바꾸면 최종 휴대폰값과 월요금을 실시간으로 다시 계산합니다. 약정이 남았으면 위약금과 이득을 판정하고, 번호이동·기기변경·자급제+알뜰폰·인터넷 결합 네 길을 나란히 놓습니다.","link":"hogang/","shot":"shots/hogang_home.png","bullets":[["결론","최종 휴대폰값·월요금 1등만 위에"],["판정","위약금 vs 이득 손익분기"],["비교","4경로 2년 총액 비교"]],"how":["기종·요금제·약정 잔여를 고릅니다.","맨 위 최저가와 사는 법 1·2·3을 봅니다.","4경로 2년 총액을 비교합니다."],"notes":["금액은 기준일 예시값이며 통신사 공시지원금·요금제는 변동됩니다.","가입·개통을 대행하지 않습니다."]},
{"k":"golf","nm":"골프 스윙 교정","sub":"손목·각도 실사 비교 · 1·2·3 교정법","cat":"etc","badge":"NEW","status":"live","icon":"shots/ic_golf.png","price":"무료","price2":"로그인 없이","line":"사진으로 각도를 맞추고, 오늘 할 1·2·3만 따라 하면 됩니다.","blurb":"훅·슬라이스·캐스팅·머리 들림·체중 이동·얼리 익스텐션 6종을 실제 스윙 사진의 손목·페이스·머리 위치 비교로 짚고, 원인 판별부터 1·2·3 단계, 악화 신호, 레슨 의뢰 기준까지 정리합니다.","link":"golf/","shot":"shots/golf_home.png","bullets":[["사진","좋은 예·나쁜 예 실사 비교"],["6종","훅·슬라이스·캐스팅·머리·체중·얼리"],["단계","오늘 1단계부터 2주 훈련까지"]],"how":["내 증상을 고릅니다.","사진으로 손목·머리 위치를 대조합니다.","1·2·3 단계를 오늘 하나씩 해 봅니다."],"notes":["연습 참고용이며 부상·통증이 있으면 전문가와 상담하십시오.","진단·처방이 아닙니다."]},
{"k":"petmind","nm":"동물 번역기","sub":"강아지·고양이 행동 사진 비교 · 교정 1·2·3","cat":"etc","badge":"NEW","status":"live","icon":"shots/ic_petmind.png","price":"무료","price2":"로그인 없이","line":"그 행동이 무슨 뜻인지 사진으로 맞춰 보고, 오늘 할 교정을 알려 줍니다.","blurb":"꼬리·귀·몸짓을 실제 사진 두 장으로 비교해 지금 마음과 의도를 읽고, 분리불안·짖음·산책 당김 등 8가지 행동의 원인 판별과 1·2·3 교정 단계, 악화 신호, 수의사·훈련사 의뢰 기준을 정리합니다.","link":"petmind/","shot":"shots/petmind_home.png","bullets":[["사진","편안함·불편함 2장 비교"],["8종","분리불안·짖음·당김·배변 등"],["단계","오늘 1단계부터 2주까지"]],"how":["지금 보이는 행동을 고릅니다.","사진 두 장으로 상태를 대조합니다.","1·2·3 단계를 순서대로 해 봅니다."],"notes":["진단·처방이 아닙니다. 건강이 걱정되면 수의사와 상담하십시오.","행동은 개체·상황에 따라 다릅니다."]}
];
add.forEach(function(p){ if(!find(p.k)) c.products.push(p); });
/* navi — v2 실물(그림 16·10문항·고른 것 되풀이 없음·①선언 ②해석 ③예언 ④예방). 가격·배지는 그대로 */
var n=find('navi');
n.nm='독심술 v2';
n.sub='그림 16장 → 10문항 · 속마음과 앞일';
n.line='마음 가는 그림을 고르고 10문항만 답하면, 지금 마음과 앞으로 일어날 일을 읽어 줍니다.';
n.blurb='문항 없이 그림 16장 중 마음 가는 것을 여러 장 고르면, 10문항 스무고개가 그쪽으로 파고듭니다. 고른 그림·답은 결과지에 되풀이하지 않고 ①선언 ②속마음 해석 ③예언(자주 일어났거나 앞으로 일어날 일) ④오늘 조심할 것과 예방 순서로 풀어 줍니다.';
n.bullets=[['그림','상징 사진 16장 · 여러 장 골라도 됨'],['10문항','고른 그림 쪽으로 갈라지는 스무고개'],['결과','①선언 ②속마음 ③예언 ④오늘 조심할 것'],['비밀','고른 그림·답은 결과지에 다시 쓰지 않음']];
n.how=['마음 가는 그림을 여러 장 고릅니다.','10문항에 답합니다(나를 볼 때 · 남을 볼 때).','선언 → 속마음 → 예언 → 오늘 조심할 것 순서로 읽습니다.'];
n.notes=['심리검사·진단이 아닌 오락·참고용입니다. 결과는 상대와 상황에 따라 다릅니다.','답은 기기 밖으로 전송·저장되지 않습니다. 공유 링크에는 결 이름과 한 줄까지만 담깁니다.'];
/* redev — 모아타운 64곳(redev/data/redev.json meta.moa.n=64, 관리계획 승인·고시분) */
var r=find('redev'), d=await (await fetch('http://127.0.0.1:8765/redev/data/redev.json',{cache:'no-store'})).json(), moaN=(d.moa||[]).length;
if(moaN!==64) throw new Error('moa '+moaN);
r.sub='부동산·재개발 · 정비구역 지정부터 착공까지 진행단계 조회 · 모아타운 64곳 포함';
if(r.blurb.indexOf('모아타운')<0) r.blurb=r.blurb.replace('서울 1,198 · 경기 533 · 전국 1,566 정비사업을 지번·구역명·자치구로 바로 찾습니다.','서울 1,198 · 경기 533 · 전국 1,566 정비사업과 서울 모아타운 64곳(관리계획 승인·고시분)을 지번·구역명·자치구로 바로 찾습니다.');
r.notes=r.notes.map(function(t){return t.indexOf('1차 버전에는 신속통합기획(신통기획)·모아타운·시공사를 담지 않았습니다.')===0 ? '신속통합기획(신통기획)·시공사는 담지 않았습니다. 모아타운은 관리계획 승인·고시분 64곳만 담았습니다(대상지 선정·계획 수립 중인 곳 제외). 공개 데이터를 그대로 모은 참고 자료이고 법적 효력은 없습니다.' : t;});
c.count=c.products.length; c.v='20261121u'; c.updated='2026-11-21T23:30:00+09:00';
return JSON.stringify({catalog:JSON.stringify(c,null,1), products:JSON.stringify(c.products,null,1), count:c.count, moa:moaN, redevBlurbHasMoa:r.blurb.indexOf('모아타운 64곳')>=0});
'@
try {
  Open-Page ($global:Base + 'gagebu/') 9410
  Start-Sleep -Milliseconds 1500
  $res = Js $JS
  $o = $global:SER.DeserializeObject($res)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText((Join-Path $global:OcRoot 'catalog.json'), ($o['catalog'] -replace "`r?`n", "`r`n") + "`r`n", $enc)
  [IO.File]::WriteAllText((Join-Path $env:TEMP 'kts_products_arr.json'), $o['products'], $enc)
  Write-Output ("count=" + $o['count'] + " moa=" + $o['moa'] + " redevBlurb=" + $o['redevBlurbHasMoa'])
} finally { Stop-CdpChrome }

# 쇼룸 아이콘 192x192 (9차와 같은 톤: 딥네이비 둥근 네모 + 금색 테두리 + 흰 글자 + 오렌지 라벨)
param([string]$apps = '')
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$L = [ordered]@{ mealplan = @('장보기', '식단'); engquiz = @('ENG', '퀴즈'); cardbook = @('가계부', '카드'); tripcourse = @('여행', '코스'); subscribeclean = @('구독', '해지')
 reviewpolish = @('리뷰', '윤문'); fitnessweek = @('운동', '주간'); ideaboard = @('IDEA', '점검'); petcare = @('케어', '주기')
 dangol = @('단골', '재방문'); wonka = @('원가', '판매가'); balju = @('발주', '재고'); hygiene = @('위생', '일지'); shiftpay = @('알바', '급여'); settle = @('정산', '수수료')
 sellercalc_en = @('FBA', 'Margin'); listinggen_en = @('LIST', 'Copy'); globalship = @('SHIP', '통관'); digitalstore_en = @('SHOP', 'Digital') }
$sel = if ($apps) { $apps -split ',' } else { @($L.Keys) }
$map = @{}; foreach ($k in $sel) { $map[$k] = $L[$k] }
$js = @'
(()=>{const L=__L__,out={};
for (const k in L){
 const c=document.createElement('canvas');c.width=c.height=192;const g=c.getContext('2d');
 const rr=(x,y,w,h,r)=>{g.beginPath();g.moveTo(x+r,y);g.arcTo(x+w,y,x+w,y+h,r);g.arcTo(x+w,y+h,x,y+h,r);g.arcTo(x,y+h,x,y,r);g.arcTo(x,y,x+w,y,r);g.closePath();};
 const gr=g.createLinearGradient(0,0,0,192);gr.addColorStop(0,'#16244A');gr.addColorStop(1,'#0A1128');g.fillStyle=gr;rr(0,0,192,192,34);g.fill();
 g.strokeStyle='rgba(214,180,120,.75)';g.lineWidth=2;rr(10,10,172,172,26);g.stroke();
 g.fillStyle='#FF6B00';g.beginPath();g.arc(152,40,7,0,Math.PI*2);g.fill();
 g.textAlign='center';g.textBaseline='middle';
 const t=L[k][0];let fs=t.length>=4?40:(t.length===3?46:56);g.font='900 '+fs+'px "Malgun Gothic",sans-serif';g.fillStyle='#F3F6FA';g.fillText(t,96,92);
 const s=L[k][1];g.font='800 18px "Malgun Gothic",sans-serif';const w=Math.max(80,g.measureText(s).width+24);
 g.fillStyle='#FF6B00';rr(96-w/2,124,w,30,10);g.fill();g.fillStyle='#0A1128';g.fillText(s,96,140);
 out[k]=c.toDataURL('image/png').split(',')[1];
}
return JSON.stringify(out);})()
'@
$js = $js.Replace('__L__', (ConvertTo-Json $map -Compress))
Open-App 'oneclick\icon.png' 9481
try {
  $o = (Invoke-Js $js) | ConvertFrom-Json
  foreach ($n in $sel) { $p = Join-Path $global:ROOT ("oneclick\shots\ic_" + $n + ".png"); Save-B64 $o.$n $p; Write-Output ("icon ic_" + $n + ".png " + (Get-Item $p).Length + " bytes") }
} finally { Stop-CdpChrome }

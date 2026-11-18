# 쇼룸 아이콘 192x192 10장 (기존 ic_*.png 톤: 딥네이비 둥근 네모 + 금색 테두리 + 흰 글자 + 오렌지 점)
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$js = @'
(()=>{
const out={};
const L={faqbot:['FAQ','40'],csreply:['CS','답안'],leadscore:['A+','점수'],kakaotalk:['TALK','응대'],weeksummary:['TOP5','주간'],
 booking:['예약','노쇼'],visitlog:['방문','AS'],funnel3:['1·2·3','문자'],listing:['매물','A4'],docs:['서류','체크']};
for (const k in L){
 const c=document.createElement('canvas');c.width=c.height=192;const g=c.getContext('2d');
 const rr=(x,y,w,h,r)=>{g.beginPath();g.moveTo(x+r,y);g.arcTo(x+w,y,x+w,y+h,r);g.arcTo(x+w,y+h,x,y+h,r);g.arcTo(x,y+h,x,y,r);g.arcTo(x,y,x+w,y,r);g.closePath();};
 const gr=g.createLinearGradient(0,0,0,192);gr.addColorStop(0,'#16244A');gr.addColorStop(1,'#0A1128');g.fillStyle=gr;rr(0,0,192,192,34);g.fill();
 g.strokeStyle='rgba(214,180,120,.75)';g.lineWidth=2;rr(10,10,172,172,26);g.stroke();
 g.fillStyle='#FF6B00';g.beginPath();g.arc(152,40,7,0,Math.PI*2);g.fill();
 g.textAlign='center';g.textBaseline='middle';
 const t=L[k][0];let fs=t.length>=4?40:(t.length===3?46:56);g.font='900 '+fs+'px "Malgun Gothic",sans-serif';g.fillStyle='#F3F6FA';g.fillText(t,96,92);
 g.fillStyle='#FF6B00';rr(56,124,80,30,10);g.fill();g.fillStyle='#0A1128';g.font='800 18px "Malgun Gothic",sans-serif';g.fillText(L[k][1],96,140);
 out[k]=c.toDataURL('image/png').split(',')[1];
}
return JSON.stringify(out);})()
'@
Open-App 'oneclick\icon.png' 9381
try {
  $o = (Invoke-Js $js) | ConvertFrom-Json
  foreach ($n in 'faqbot', 'csreply', 'leadscore', 'kakaotalk', 'weeksummary', 'booking', 'visitlog', 'funnel3', 'listing', 'docs') {
    $p = Join-Path $global:ROOT ("oneclick\shots\ic_" + $n + ".png"); Save-B64 $o.$n $p
    Write-Output ("icon ic_" + $n + ".png " + (Get-Item $p).Length + " bytes")
  }
} finally { Stop-CdpChrome }

# 쇼룸 아이콘 192x192 4장 (기존 ic_*.png 톤: 딥네이비 둥근 네모 + 금색 테두리 + 흰 선 그림 + 오렌지 점)
. "$PSScriptRoot\pmlib.ps1"
$js = @'
(()=>{
const out={};
const base=(g)=>{const W=192;g.clearRect(0,0,W,W);
 const rr=(x,y,w,h,r)=>{g.beginPath();g.moveTo(x+r,y);g.arcTo(x+w,y,x+w,y+h,r);g.arcTo(x+w,y+h,x,y+h,r);g.arcTo(x,y+h,x,y,r);g.arcTo(x,y,x+w,y,r);g.closePath();};
 const gr=g.createLinearGradient(0,0,0,W);gr.addColorStop(0,'#16244A');gr.addColorStop(1,'#0A1128');g.fillStyle=gr;rr(0,0,W,W,34);g.fill();
 g.strokeStyle='rgba(214,180,120,.75)';g.lineWidth=2;rr(10,10,W-20,W-20,26);g.stroke();
 g.fillStyle='#FF6B00';g.beginPath();g.arc(152,40,7,0,Math.PI*2);g.fill();
 g.lineCap='round';g.lineJoin='round';return rr;};
const paper=(g,rr,x,y,w,h)=>{g.fillStyle='rgba(255,255,255,.06)';g.strokeStyle='#F3F6FA';g.lineWidth=4;rr(x,y,w,h,8);g.fill();g.stroke();};
const mk=(name,draw)=>{const c=document.createElement('canvas');c.width=c.height=192;const g=c.getContext('2d');const rr=base(g);draw(g,rr);out[name]=c.toDataURL('image/png').split(',')[1];};
mk('riskcheck',(g,rr)=>{paper(g,rr,52,40,74,100);g.strokeStyle='#F3F6FA';g.lineWidth=4;[62,80].forEach(y=>{g.beginPath();g.moveTo(66,y);g.lineTo(112,y);g.stroke();});
 g.strokeStyle='#FF6B00';g.beginPath();g.moveTo(66,98);g.lineTo(100,98);g.stroke();
 g.strokeStyle='#F3F6FA';g.lineWidth=6;g.beginPath();g.arc(118,118,22,0,Math.PI*2);g.fillStyle='#0E1B3A';g.fill();g.stroke();g.beginPath();g.moveTo(134,134);g.lineTo(150,150);g.stroke();
 g.fillStyle='#FF6B00';g.font='bold 30px Malgun Gothic';g.textAlign='center';g.textBaseline='middle';g.fillText('!',118,119);});
mk('expense',(g,rr)=>{g.strokeStyle='#F3F6FA';g.lineWidth=4;g.fillStyle='rgba(255,255,255,.06)';g.beginPath();g.moveTo(58,40);g.lineTo(134,40);g.lineTo(134,146);
 for(let i=0;i<6;i++){g.lineTo(134-(i*2+1)*6.33,138+(i%2?8:0));g.lineTo(134-(i*2+2)*6.33,i%2?138:146);}g.closePath();g.fill();g.stroke();
 [62,78,94].forEach((y,i)=>{g.strokeStyle=i===2?'#FF6B00':'#F3F6FA';g.beginPath();g.moveTo(70,y);g.lineTo(i===2?100:122,y);g.stroke();});
 g.fillStyle='#F3F6FA';g.font='bold 24px Malgun Gothic';g.textAlign='center';g.textBaseline='middle';g.fillText('₩',96,118);});
mk('quote',(g,rr)=>{paper(g,rr,54,38,84,112);g.fillStyle='#FF6B00';g.font='bold 15px Malgun Gothic';g.textAlign='left';g.textBaseline='middle';g.fillText('No.0001',64,56);
 g.strokeStyle='#F3F6FA';g.lineWidth=4;[78,94,110].forEach(y=>{g.beginPath();g.moveTo(66,y);g.lineTo(126,y);g.stroke();});
 g.strokeStyle='#FF6B00';g.beginPath();g.moveTo(98,132);g.lineTo(126,132);g.stroke();g.strokeStyle='#F3F6FA';g.lineWidth=3;g.beginPath();g.moveTo(66,124);g.lineTo(126,124);g.stroke();});
mk('letter',(g,rr)=>{paper(g,rr,48,60,96,72);g.strokeStyle='#F3F6FA';g.lineWidth=4;g.beginPath();g.moveTo(52,66);g.lineTo(96,100);g.lineTo(140,66);g.stroke();
 g.strokeStyle='#FF6B00';g.lineWidth=4;g.beginPath();g.arc(132,128,17,0,Math.PI*2);g.fillStyle='#0E1B3A';g.fill();g.stroke();
 g.fillStyle='#FF6B00';g.font='bold 15px Malgun Gothic';g.textAlign='center';g.textBaseline='middle';g.fillText('증',132,129);});
return JSON.stringify(out);})()
'@
Open-App 'oneclick\icon.png' 9359
try {
  $o = (Invoke-Js $js) | ConvertFrom-Json
  foreach ($n in 'riskcheck', 'expense', 'quote', 'letter') {
    $p = Join-Path $global:ROOT ("oneclick\shots\ic_" + $n + ".png"); Save-B64 $o.$n $p
    Write-Output ("icon " + $p + " " + (Get-Item $p).Length + " bytes")
  }
} finally { Stop-CdpChrome }

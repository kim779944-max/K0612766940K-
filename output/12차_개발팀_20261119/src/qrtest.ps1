# QR 인코더 실측: 앱의 QRgen 출력 → 캔버스 → 독립 디코더(jsQR, 테스트 전용 임시 파일 · 배포물에 포함 안 함)로 다시 읽어 원문과 비교
param([string]$app = 'themenu', [string]$jsqr = "$env:LOCALAPPDATA\Temp\jsqr\jsQR.js")
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
Open-App ("oneclick\" + $app + ".html") 9531
try {
  $src = [IO.File]::ReadAllText($jsqr)
  Invoke-Js ("(function(){var module=undefined,exports=undefined,define=undefined;" + $src + "`n;window.jsQR=(typeof jsQR!=='undefined'?jsQR:window.jsQR);return typeof window.jsQR})()") | Out-Null
  $t = @'
(()=>{function dec(q){const sc=4,n=q.size+8,c=document.createElement('canvas');c.width=c.height=n*sc;const g=c.getContext('2d');g.fillStyle='#fff';g.fillRect(0,0,c.width,c.height);g.fillStyle='#000';for(let y=0;y<q.size;y++)for(let x=0;x<q.size;x++)if(q.get(x,y))g.fillRect((x+4)*sc,(y+4)*sc,sc,sc);const d=g.getImageData(0,0,c.width,c.height);const r=jsQR(d.data,c.width,c.height);return r?r.data:null}
const out=[];const T=['HELLO','https://example.com/menu?x=1','한글 메뉴 김치찌개 9,000원','A'.repeat(300),'가'.repeat(400)];
for(const e of ['L','M','Q','H'])for(const s of T){let q;try{q=QRgen(s,e)}catch(x){out.push(e+':'+s.length+':'+x.message);continue}const r=dec(q);out.push(e+' v'+q.version+' m'+q.mask+' '+(r===s?'OK':'FAIL'))}
return JSON.stringify(out)})()
'@
  Write-Output ('vectors: ' + (Invoke-Js $t))
  if ($app -eq 'themenu') {
    Js 'document.querySelector("#sampleBtn").click(); await new Promise(r=>setTimeout(r,200)); run(); return 1' | Out-Null
    $r = Invoke-Js "(()=>{const q=CUR.q;const sc=4,n=q.size+8,c=document.createElement('canvas');c.width=c.height=n*sc;const g=c.getContext('2d');g.fillStyle='#fff';g.fillRect(0,0,c.width,c.height);g.fillStyle='#000';for(let y=0;y<q.size;y++)for(let x=0;x<q.size;x++)if(q.get(x,y))g.fillRect((x+4)*sc,(y+4)*sc,sc,sc);const d=g.getImageData(0,0,c.width,c.height);const r=jsQR(d.data,c.width,c.height);if(!r)return 'DECODE FAIL v'+q.version;const ok=r.data===CUR.url;const html=new TextDecoder().decode(Uint8Array.from(atob(r.data.split(',')[1]),ch=>ch.charCodeAt(0)));return 'menu QR v'+q.version+' '+q.ecl+' bytes='+q.bytes+' decoded==url '+ok+' | page has 김치찌개='+html.includes('김치찌개')+' Kimchi Stew='+html.includes('Kimchi Stew')+' 9,000원='+html.includes('9,000원')})()"
    Write-Output $r
  }
} finally { Stop-CdpChrome }

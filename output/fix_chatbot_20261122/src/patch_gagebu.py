import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()


def rep(a, b):
    global s
    assert s.count(a) == 1, (a[:80], s.count(a))
    s = s.replace(a, b)


rep(r""".addrow2 .btn{min-height:44px;font-weight:800}
""", r""".addrow2 .btn{min-height:44px;font-weight:800}
.paybox textarea{display:block;resize:vertical;line-height:1.5;font-size:14px;min-height:0}
.paybtns{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:8px}
.paybtns .btn{min-height:44px;font-weight:800}
.paynote{font-size:11.5px;color:var(--gray);margin:7px 0 0;line-height:1.55}
.paymore{margin-top:11px;padding-top:10px;border-top:1px dashed var(--line2)}
.paymore b.t{display:block;font-size:13px;margin-bottom:6px}
.paymore .btn{width:100%;margin-top:8px;min-height:42px;font-weight:800}
""")

rep(r"""    <h2><span class="n">1</span>오늘 산 것 넣기 <em>자동 분류</em></h2>
    <div class="addrow2">
      <input id="inBuy" placeholder="예: 양파 1.8kg 3900원 하나로마트" autocomplete="off" enterkeyhint="done">
      <button class="btn pri" id="btnAdd" type="button">넣기</button>
    </div>
    <p class="hint">품목 · 양(g·kg·ml·L·개) · 금액 · 산 곳 순서는 상관없습니다. 한 번에 여러 줄을 붙여 넣어도 됩니다.</p>
""", r"""    <h2><span class="n">1</span>결제 문자·알림 붙여넣기 <em>자동 분류</em></h2>
    <div class="paybox">
      <textarea id="inBuy" rows="5" autocomplete="off" placeholder="[국민카드] 11/22 14:03 스타벅스 강남 5,600원 일시불&#10;신한카드 11/22 13:20 GS25 역삼점 12,300원"></textarea>
      <div class="paybtns">
        <button class="btn" id="btnPaste" type="button">📋 붙여넣기</button>
        <button class="btn pri" id="btnAdd" type="button">정리하기</button>
      </div>
      <p class="paynote">· 카톡·문자 앱 내용을 자동으로 읽어오지 않습니다. 복사해서 붙여넣으면 됩니다.<br>· 잔액·누적·승인번호 줄은 기록하지 않습니다.</p>
      <div class="paymore">
        <b class="t">추가 내용 붙이기</b>
        <textarea id="inMore" rows="2" autocomplete="off" placeholder="양파 1.8kg 3900원 하나로마트"></textarea>
        <button class="btn" id="btnMore" type="button">추가로 정리</button>
        <p class="hint">품목 · 양(g·kg·ml·L·개) · 금액 · 산 곳 순서는 상관없습니다. 한 번에 여러 줄을 붙여 넣어도 됩니다.</p>
      </div>
    </div>
""")

rep(r"""function addLines(txt, asPrice){
  var lines=String(txt||'').split(/\n+/), ok=0, bad=0;
  lines.forEach(function(l){ if(!l.trim()) return; var p=parse(l); if(!p){bad++;return;}
""", r"""/* 결제 문자 한 줄 → parse() 앞단 정리. 카드사 태그·날짜·시각·승인번호·일시불/할부/승인·잔액/누적·(주) 를 버리고
   가맹점 이름 = 품목, 결제금액 = 금액, 카드사 이름 = 산 곳. 결제 문자가 아니면 줄을 그대로 돌려준다 */
var CARD_RE=/([A-Za-z가-힣]{1,10}(?:카드|체크))(?:\(\d{2,4}\))?/;
function parsePaySms(line){
  var s=String(line||'').replace(/\[Web발신\]|\(광고\)/gi,' '), card='', pay=false, m;
  if(/^\s*(잔액|누적|승인번호)/.test(s)) return {line:'',skip:'balance'};
  m=s.match(/[\[【]\s*([^\]】]+?)\s*[\]】]/);
  if(m){ card=m[1].replace(/\(\d{2,4}\)/,'').trim(); pay=true; s=s.replace(/[\[【][^\]】]*[\]】]/g,' '); }
  else { m=s.match(CARD_RE); if(m){ card=m[1]; pay=true; s=s.replace(m[0],' '); } }
  if(/\d{1,2}\/\d{1,2}/.test(s)&&/\d{1,2}:\d{2}/.test(s)) pay=true;
  if(!pay) return {line:String(line||''),pay:false};
  if(/취소/.test(s)) return {line:'',skip:'cancel'};          /* 취소 문자는 쓴 돈이 아니므로 기록하지 않는다 */
  s=s.replace(/(잔액|누적)[^\d]*[\d,]+\s*원/g,' ')
     .replace(/승인번호\s*:?\s*\d+/g,' ')
     .replace(/\d{2,4}[\/.-]\d{1,2}[\/.-]\d{1,2}|\d{1,2}\/\d{1,2}/g,' ')
     .replace(/\d{1,2}:\d{2}(?::\d{2})?/g,' ')
     .replace(/\(주\)|㈜|주식회사/g,' ')
     .replace(/\d+\s*개월/g,' ')
     .replace(/일시불|할부|승인|정상/g,' ')
     .replace(/\S*\*\S*/g,' ');                       /* 홍*동 같은 가린 이름 */
  var am=s.match(/(\d{1,3}(?:,\d{3})+|\d+)\s*원/);
  if(!am) return {line:'',skip:'noamount'};
  var merchant=s.replace(am[0],' ').replace(/\s+/g,' ').trim();
  return {line:(merchant||'카드 결제')+' '+am[1]+'원', pay:true, card:card, merchant:merchant||'카드 결제'};
}
function addLines(txt, asPrice){
  var lines=String(txt||'').split(/\n+/), ok=0, bad=0, skipped=0;
  lines.forEach(function(l){ if(!l.trim()) return;
    var ps=parsePaySms(l); if(ps.skip){ if(ps.skip==='noamount') bad++; else skipped++; return; }
    var p=parse(ps.line); if(!p){bad++;return;}
    if(ps.pay){ p.name=ps.merchant; p.place=ps.card||'(산 곳 미입력)'; p.qty=1; p.unit='개'; }
""")

rep(r"""  if(bad) toast('금액을 찾지 못한 줄이 '+bad+'개 있습니다 — 예: 양파 1.8kg 3900원 하나로마트');
  return ok;""", r"""  if(bad) toast('금액을 찾지 못한 줄이 '+bad+'개 있습니다 — 예: 양파 1.8kg 3900원 하나로마트');
  if(skipped&&!bad) setTimeout(function(){ toast('잔액·누적·취소 줄 '+skipped+'개는 기록하지 않았습니다'); }, ok?2500:0);
  return ok;""")

rep(r"""$('#btnAdd').addEventListener('click',function(){ if(addLines($('#inBuy').value,false)) $('#inBuy').value=''; });
$('#inBuy').addEventListener('keydown',function(e){ if(e.key==='Enter'){ e.preventDefault(); $('#btnAdd').click(); } });
""", r"""$('#btnAdd').addEventListener('click',function(){
  var a=$('#inBuy').value, b=$('#inMore').value;
  if(!a.trim()&&!b.trim()){ toast('결제 문자를 붙여넣어 주세요'); return; }
  if(a.trim()&&addLines(a,false)) $('#inBuy').value='';
  if(b.trim()&&addLines(b,false)) $('#inMore').value='';
});
$('#btnMore').addEventListener('click',function(){ if(!$('#inMore').value.trim()){ toast('추가할 내용을 적어 주세요'); return; } if(addLines($('#inMore').value,false)) $('#inMore').value=''; });
$('#btnPaste').addEventListener('click',function(){
  var fail=function(){ toast('길게 눌러 [붙여넣기] 해 주세요 · 붙여넣기가 막힌 브라우저입니다'); $('#inBuy').focus(); };
  try{
    if(!navigator.clipboard||!navigator.clipboard.readText){ fail(); return; }
    navigator.clipboard.readText().then(function(t){
      if(!t||!t.trim()){ toast('복사된 글이 없습니다 · 결제 문자를 먼저 복사해 주세요'); return; }
      var cur=$('#inBuy').value; $('#inBuy').value=cur&&cur.trim()? cur.replace(/\s*$/,'')+'\n'+t : t;
      toast('붙여넣었습니다 · 확인 후 [정리하기]를 누르세요');
    }, fail);
  }catch(e){ fail(); }
});
""")

rep("window.__GAGEBU_API={parse:parse,norm:norm,addLines:addLines};",
    "window.__GAGEBU_API={parse:parse,parsePaySms:parsePaySms,norm:norm,addLines:addLines};")
open(p, 'w', encoding='utf-8', newline='').write(s)
print('ok')

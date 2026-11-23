import io, sys
p = sys.argv[1]
s = io.open(p, encoding='utf-8', newline='').read()
assert '\r\n' not in s


def rep(a, b):
    global s
    assert s.count(a) == 1, (a[:70], s.count(a)); s = s.replace(a, b)


# 1) 숫자 토큰은 숫자 경계로 (411 → 1411·4110 제외, 411-2·411번지 포함)
rep("""function filtered(){
  var toks=Q.trim().toLowerCase().split(/\\s+/).filter(Boolean);
  var out=rows(TAB).filter(function(r){
    if(!pass(r)) return false;
    if(!toks.length) return true;
    var k=r._k;
    for(var i=0;i<toks.length;i++){ if(k.indexOf(norm(toks[i]))<0) return false; }
    return true;
  });
  return out;
}""", """function tokMatch(k,t){
  t=norm(t);
  if(/^\\d+(-\\d+)?$/.test(t)) return new RegExp('(^|[^0-9-])'+t.replace('-','\\\\-')+'(?![0-9])').test(k);  /* 164번: 숫자 경계 */
  return k.indexOf(t)>=0;
}
function filtered(){
  var toks=normQ(Q).trim().toLowerCase().split(/\\s+/).filter(Boolean);
  var out=rows(TAB).filter(function(r){
    if(!pass(r)) return false;
    if(!toks.length) return true;
    var k=r._k;
    for(var i=0;i<toks.length;i++){ if(!tokMatch(k,toks[i])) return false; }
    return true;
  });
  return out;
}

/* ---------- 164번: 지번으로 사업 여부 (동/읍/면 + 본번-부번) ---------- */
/* 전각 숫자·하이픈 정규화, '번지'·'일대'·쉼표·괄호 제거 */
function normQ(q){
  return String(q||'').replace(/[\\uFF10-\\uFF19]/g,function(c){return String.fromCharCode(c.charCodeAt(0)-0xFEE0);})
    .replace(/[\\uFF0D\\u2010-\\u2015\\u2212]/g,'-').replace(/[,，()（）\\[\\]]/g,' ')
    .replace(/(\\d)\\s*번지/g,'$1').replace(/일대|일원/g,' ').replace(/\\s*-\\s*/g,'-');
}
/* '번동 411' · '미아동 123-4' · '성사동 715번지' · '경기도 고양시 성사동 715번지' → {dong,bon,bu} */
function parseJibun(q){
  var s=normQ(q), m=/([가-힣][가-힣0-9]*?(?:동|읍|면|리|가))\\s*(?:산\\s*)?(\\d{1,5})(?:-(\\d{1,5}))?(?![0-9])(?!\\s*(?:구역|지구|단지|차|블록|공구))/.exec(s);
  if(!m) return null;
  var dong=m[1].replace(/^.*\\s/,'');
  return {dong:dong, bon:String(+m[2]), bu:m[3]?String(+m[3]):'', text:dong+' '+(+m[2])+(m[3]?'-'+(+m[3]):'')};
}
function rowJibun(r){
  if(r._jb!==undefined) return r._jb;
  var j=r.__tab==='nation'?null:parseJibun(r.j||'');
  if(j&&r.dn&&j.dong!==r.dn&&(r.j||'').indexOf(r.dn)>=0) j.dong=r.dn;
  r._jb=j; return j;
}
function jibunHits(J){
  var src=rows(TAB==='all'?'all':TAB).filter(function(r){ return r.__tab!=='nation'; });
  var hit=[], same=[];
  src.forEach(function(r){
    var j=rowJibun(r); if(!j||j.dong!==J.dong) return;
    if(j.bon===J.bon&&j.bu===J.bu) hit.push(r); else same.push(r);
  });
  same.sort(function(a,b){ var x=rowJibun(a), y=rowJibun(b); return Math.abs(+x.bon-+J.bon)-Math.abs(+y.bon-+J.bon)||(+x.bon-+y.bon); });
  return {hit:hit, same:same};
}
function byTabText(arr){
  var c={}, o=[]; arr.forEach(function(r){ var n=TABNM[r.__tab]; if(!c[n]){c[n]=0;o.push(n);} c[n]++; });
  return o.map(function(n){ return n+' '+c[n]+'곳'; }).join(' · ');
}
function jItemHTML(r,kind){
  var j=rowJibun(r);
  var badge=kind==='hit'?'<span class="jb hit">대표 지번 일치</span>':'<span class="jb near">같은 동 · 대표 지번 다름</span>';
  var h=itemHTML(r);
  var src='<span class="src'+(r.__tab==='moa'?' moa':'')+'">'+TABNM[r.__tab]+'</span>';
  h=h.replace('<div class="nm">','<div class="jtop">'+badge+(TAB==='all'?'':src)+'</div><div class="nm">');
  h=h.replace('<div class="bot">','<div class="jrep">대표 지번 <b>'+esc((r.g?r.g+' ':'')+j.text)+'</b></div><div class="bot">');
  return h;
}
function renderJibun(J){
  var R=jibunHits(J), box=$('list');
  $('cnt').textContent=R.hit.length.toLocaleString('ko-KR');
  $('more').style.display='none';
  var head='<div class="jsum"><b>'+esc(J.text)+'</b> → '+(R.hit.length?esc(byTabText(R.hit))+'(대표 지번 일치)':'대표 지번 일치 0곳')+
    ' · 같은 동 후보 '+R.same.length+'곳</div>';
  var note='<div class="jnote">대표 지번만 비교합니다. 구역은 여러 번지에 걸치므로 같은 동에 사업 구역은 있지만 이 번지가 그 구역에 포함되는지는 공부(公簿)·구청 확인이 필요합니다. '+
    '전국 자료('+won(rows('nation').length)+'건)는 시·군·구까지만 있어 지번으로 찾을 수 없습니다 — <b>여기 없다고 사업이 없다는 뜻은 아닙니다.</b></div>';
  var h=head;
  if(R.hit.length){
    h+=R.hit.map(function(r){ return jItemHTML(r,'hit'); }).join('');
  }else{
    h+='<div class="empty jnone"><b>이 지번이 들어간 사업 구역을 찾지 못했습니다</b>'+
      (R.same.length?'같은 동('+esc(J.dong)+') 사업 구역 '+R.same.length+'곳이 있습니다 — 아래를 펼쳐 대표 지번을 비교해 보세요.':'같은 동 이름으로도 실린 구역이 없습니다. 동 이름 철자(예: 미아동·번동)를 확인해 보세요.')+'</div>';
  }
  if(R.same.length){
    h+='<details class="jsame"><summary>같은 동 사업 구역 '+R.same.length+'곳 <small>대표 지번 가까운 순</small></summary>'+
      '<div class="jnote">같은 동에 사업 구역은 있지만 이 번지가 그 구역에 포함되는지는 공부(公簿)·구청 확인이 필요합니다.</div>'+
      R.same.map(function(r){ return jItemHTML(r,'near'); }).join('')+'</details>';
  }
  box.innerHTML=h+note;
}""")

# 2) render 분기
rep("""function render(){
  var arr=filtered();
  paintTabs();""", """function render(){
  var J=D&&Q.trim()?parseJibun(Q):null;
  if(J){
    paintTabs(); $('base').textContent=baseOf(TAB); $('muNote').style.display='none';
    $('totline').textContent=baseLine();
    renderJibun(J); return;
  }
  var arr=filtered();
  paintTabs();""")

# 3) CSS
rep(".empty{text-align:center;padding:18px 8px;color:var(--gray);font-size:12px}",
    ".empty{text-align:center;padding:18px 8px;color:var(--gray);font-size:12px}\n"
    "/* 164번: 지번 조회 ①②③ */\n"
    ".jsum{font-size:12px;color:var(--ink2);background:#0B1729;border:1px solid rgba(255,107,0,.45);border-radius:11px;padding:9px 11px;line-height:1.5;word-break:keep-all}\n"
    ".jsum b{color:#FFC98F}\n"
    ".jtop{display:flex;gap:5px;align-items:center;margin-bottom:4px;flex-wrap:wrap}\n"
    ".jb{font-size:9.5px;font-weight:900;border-radius:6px;padding:2px 6px;white-space:nowrap}\n"
    ".jb.hit{background:#4ADE80;color:#0B2C1B}\n"
    ".jb.near{background:#14213B;color:#FFC98F;border:1px solid rgba(255,162,77,.5)}\n"
    ".jrep{font-size:11px;color:var(--ink2);margin-top:4px}.jrep b{color:#fff}\n"
    ".jnote{font-size:10.5px;color:var(--gray);line-height:1.6;margin:6px 2px 0;word-break:keep-all}.jnote b{color:#C9D6E6}\n"
    ".jsame{border:1px solid var(--line);border-radius:12px;padding:0 8px 8px;background:rgba(255,255,255,.02)}\n"
    ".jsame summary{cursor:pointer;font-size:12.5px;font-weight:900;padding:10px 2px;list-style:none}.jsame summary::-webkit-details-marker{display:none}\n"
    ".jsame summary::before{content:'▸ ';color:#FFA24D}.jsame[open] summary::before{content:'▾ '}\n"
    ".jsame summary small{font-size:10px;color:var(--gray);font-weight:700;margin-left:4px}\n"
    ".jsame .item{margin-top:6px}")
rep('<script src="../helper.js?v=20261122a"></script>', '<script src="../helper.js?v=20261123a"></script>')
io.open(p, 'w', encoding='utf-8', newline='').write(s)
print('ok')

import os
HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, '..', '..', '..', '..', 'oneclick', 'petmind', 'index.html')
s = open(P, 'rb').read().decode('utf-8'); NL = '\r\n' if '\r\n' in s else '\n'
cat = open(os.path.join(HERE, 'petcat.js'), encoding='utf-8').read().replace('\r\n', '\n').rstrip('\n').split('\n')
def rep(a, b):
    global s
    a = a.replace('\n', NL); b = b.replace('\n', NL)
    assert s.count(a) == 1, (a[:80], s.count(a)); s = s.replace(a, b)

# 1) 고양이 표 추가 (GAL 다음, var W 앞)
rep("var W='dog';\n", NL.join(cat).replace(NL, '\n') + "\n\nvar W='dog';\n")
# 2) show(): 모드별 표 + 해시 #모드/키
rep("function show(k){\n  var f=FIX[k];",
    "function tbl(){ return W==='cat' ? FIX_CAT : FIX; }\nfunction ord(){ return W==='cat' ? ORDER_CAT : ORDER; }\nfunction show(k){\n  var f=tbl()[k];")
rep("  try{history.replaceState(null,'','#'+k);}catch(e){}",
    "  try{history.replaceState(null,'','#'+W+'/'+k);}catch(e){}")
# 3) 칩·갤러리를 모드별로 다시 그리기
rep("[].forEach.call(document.querySelectorAll('#who .chip'),function(b){b.addEventListener('click',function(){W=b.dataset.w;paintPairs();});});\n"
    "$('#probs').innerHTML=ORDER.map(function(k){return '<button type=\"button\" class=\"chip\" data-k=\"'+k+'\">'+esc(FIX[k].nm)+'<small>'+esc(FIX[k].sub)+'</small></button>';}).join('');\n"
    "[].forEach.call(document.querySelectorAll('#probs .chip'),function(b){b.addEventListener('click',function(){show(b.dataset.k);$('#fixBox').scrollIntoView({behavior:'smooth',block:'start'});});});\n"
    "$('#gal').innerHTML=GAL.map(function(g){return '<figure><img class=\"ph\" src=\"img/'+g[0]+'\" alt=\"'+esc(g[1])+' 실제 사진\" loading=\"lazy\"><figcaption><b>'+esc(g[1])+'</b> — '+esc(g[2])+'</figcaption></figure>';}).join('');\n"
    "paintPairs();\n"
    "var h0=(location.hash||'').slice(1); show(FIX[h0]?h0:'sep');\n"
    "window.__PET={FIX:FIX,ORDER:ORDER,PAIRS:PAIRS,GAL:GAL};\n",
    "function paintProbs(){\n"
    "  var T=tbl();\n"
    "  $('#probs').innerHTML=ord().map(function(k){return '<button type=\"button\" class=\"chip\" data-k=\"'+k+'\">'+esc(T[k].nm)+'<small>'+esc(T[k].sub)+'</small></button>';}).join('');\n"
    "  [].forEach.call(document.querySelectorAll('#probs .chip'),function(b){b.addEventListener('click',function(){show(b.dataset.k);$('#fixBox').scrollIntoView({behavior:'smooth',block:'start'});});});\n"
    "}\n"
    "function paintGal(){\n"
    "  $('#gal').innerHTML=(W==='cat'?GAL_CAT:GAL).map(function(g){return '<figure><img class=\"ph\" src=\"img/'+g[0]+'\" alt=\"'+esc(g[1])+' 실제 사진\" loading=\"lazy\"><figcaption><b>'+esc(g[1])+'</b> — '+esc(g[2])+'</figcaption></figure>';}).join('');\n"
    "}\n"
    "/* 모드 전환: 사진 비교·문제 칩·교정·몸짓 사전을 한꺼번에 그 동물 판으로 */\n"
    "function setMode(w,k){\n"
    "  W = w==='cat' ? 'cat' : 'dog';\n"
    "  paintPairs(); paintProbs(); paintGal();\n"
    "  show(tbl()[k] ? k : ord()[0]);\n"
    "}\n"
    "/* 해시: #cat/groom · #dog/sep (예전 주소 #sep 는 강아지 판으로) */\n"
    "function fromHash(){\n"
    "  var h=(location.hash||'').slice(1), p=h.split('/');\n"
    "  if (p.length===2 && (p[0]==='cat'||p[0]==='dog')) return {w:p[0], k:p[1]};\n"
    "  if (h==='cat'||h==='dog') return {w:h, k:''};\n"
    "  return {w:'dog', k:h};\n"
    "}\n"
    "[].forEach.call(document.querySelectorAll('#who .chip'),function(b){b.addEventListener('click',function(){ if(b.dataset.w!==W) setMode(b.dataset.w,''); });});\n"
    "window.addEventListener('hashchange',function(){ var r=fromHash(); setMode(r.w,r.k); });\n"
    "var h0=fromHash(); setMode(h0.w, FIX[h0.k]||FIX_CAT[h0.k] ? h0.k : (h0.w==='cat'?'hiss':'sep'));\n"
    "window.__PET={FIX:FIX,ORDER:ORDER,PAIRS:PAIRS,GAL:GAL,FIX_CAT:FIX_CAT,ORDER_CAT:ORDER_CAT,GAL_CAT:GAL_CAT,mode:function(){return W;}};\n")
open(P, 'wb').write(s.encode('utf-8')); print('ok')

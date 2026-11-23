"""oneclick/index.html 쇼룸 재배치 (151·156·165 · 2026-11-23) — 정확 문자열 치환, 하나라도 안 맞으면 멈춘다.
usage: python patch_index.py <oneclick 경로>"""
import os, sys
p = os.path.join(sys.argv[1], 'index.html')
b = open(p, 'rb').read(); crlf = b'\r\n' in b
s = b.decode('utf-8').replace('\r\n', '\n')

def R(a, c, n=1):
    global s
    assert s.count(a) == n, (a[:70], s.count(a))
    s = s.replace(a, c)

# CSS: 준비 중 카드 = 보이기만 + 칩
R(".row.soon{opacity:.62}\n",
  ".row.soon{opacity:.58;filter:grayscale(.3);pointer-events:none;cursor:default}\n"
  ".row.soon .main{cursor:default}\n"
  "/* 카테고리 칩 — 섹션 필터(151) */\n"
  ".chips{display:flex;gap:6px;overflow-x:auto;margin:18px 0 0;padding:2px 0 4px;scrollbar-width:none}\n"
  ".chips::-webkit-scrollbar{display:none}\n"
  ".chips button{flex:0 0 auto;font-family:inherit;font-size:11.5px;font-weight:900;color:#C9D4E3;background:#12203C;\n"
  "  border:1px solid #2A3C63;border-radius:999px;padding:0 12px;min-height:36px;cursor:pointer;white-space:nowrap}\n"
  ".chips button.on{color:#0A1224;background:linear-gradient(180deg,#FF8A2B,#FF6B00);border-color:#FF6B00}\n"
  ".chips button.s{color:#8FA0B8}\n"
  ".sec[hidden]{display:none}\n")
R('html[data-kts-theme="light"] .act .go[disabled]',
  'html[data-kts-theme="light"] .chips button{background:var(--k-panel-2);border-color:var(--k-line-2);color:var(--k-ink-2)}\n'
  'html[data-kts-theme="light"] .chips button.on{color:#fff;background:#FF6B00;border-color:#FF6B00}\n'
  'html[data-kts-theme="light"] .act .go[disabled]')
R('  <div id="allGroups">\n  <main id="sections"></main>',
  '  <div id="allGroups">\n  <nav class="chips" id="catChips" aria-label="카테고리"></nav>\n  <main id="sections"></main>')
# 푸터 번개알바 링크 제거(156)
R(' · <a href="exchange/">교환급매물</a> · <a href="bungee/">번개알바 도구</a><br>', ' · <a href="exchange/">교환급매물</a><br>')
# LOCAL / UNIT / GROUPS
R("""  ad_magnet:{nm:'답글생성기(광고용)', sub:'광고·댓글 답글 1분', link:'ad_magnet/', ico:'✦', badge:'NEW'},
  seller:{nm:'원클릭 셀러', sub:'담기 → 올리기 → 발주', link:'seller/', ico:'▦', badge:'NEW'},
  bungee_interior:{nm:'인테리어 평당 견적', sub:'평수·등급 → 3안 비교', link:'bungee/#interior', ico:'▤', badge:'NEW'},
  bungee_home:{nm:'단독 모바일 홈피', sub:'가게 정보 → 1장 홈피', link:'bungee/#home', ico:'▢', badge:'NEW'},
  bungee_poster:{nm:'포스터 만들기', sub:'업종·혜택 → A4 포스터', link:'bungee/#poster', ico:'▣', badge:'NEW'}
};""", """  seller:{nm:'원클릭 셀러', sub:'담기 → 올리기 → 발주', link:'seller/', ico:'▦', badge:'NEW'}
};
/* 2026-11-23 쇼룸 제외: 답글생성기 ad_magnet(내부용 · 165) · 번개알바 bungee_*(별도 플랫폼 · 156) — 폴더는 그대로 */""")
R("""var UNIT = {photo2doc:'장', theform:'장', contract:'부', sign:'장', thedetail:'장', thescan:'장', theeraser:'장',
  ad_magnet:'회', seller:'회', commerce:'회', keyword:'회'};""",
  """var UNIT = {theform:'장', contract:'부', sign:'장', thedetail:'장', thescan:'장', theeraser:'장',
  seller:'회', commerce:'회', keyword:'회'};""")
R("""var GROUPS = [
  {no:'01', t:'부동산·중개사', s:'매물·계약·권리·경사도', ks:['listing','realty','exchange','slope','redev','contract','theform','sign','viewer','thescan']},
  {no:'02', t:'쇼핑몰·셀러', s:'상품·상세·광고·등록', ks:['commerce','seller','thedetail','keyword','ad_magnet','photo2doc','theeraser']},
  {no:'03', t:'자영업·매장', s:'홍보·가계부·외국 손님·자금', ks:['bungee_home','bungee_poster','bungee_interior','gagebu','tongyeok','loan','tax','interior']},
  {no:'04', t:'개인·생활', s:'장보기·휴대폰·취미·기록', ks:['sale','hogang','golf','petmind','saycap','navi','organizer']},
  {no:'05', t:'준비 중', s:'나오면 맨 위에 알려 드립니다', ks:['append','youtube','travel']}
];""", """/* 마인드맵(2026-11-23 확정 · 쓰는 순서 축)과 1:1 — K0612766940K-/output/서비스_마인드맵_20261123/쇼룸_버튼구조.md */
var GROUPS = [
  {no:'01', cat:'realty', t:'부동산·중개', s:'경사도 → 매물수집 → 매물장 → 물건 포스터', ks:['slope','realty','listing','redev','exchange']},
  {no:'02', cat:'biz',    t:'사업자·매장', s:'상품·판매·자금·인테리어',                    ks:['thedetail','seller','commerce','keyword','sale','gagebu','tongyeok','loan','interior']},
  {no:'03', cat:'doc',    t:'서류·계약',   s:'스캔 → 열람 → 양식 → 서명 → 계약',            ks:['thescan','viewer','theform','theeraser','sign','contract']},
  {no:'04', cat:'life',   t:'생활·기록',   s:'정리·사진·휴대폰·취미',                       ks:['organizer','saycap','navi','hogang','golf','petmind']},
  {no:'05', cat:'soon',   t:'준비 중',     s:'나오면 맨 위에 알려 드립니다 (보기만)',        ks:['append','youtube','travel']}
];
var CHIPS = [{c:'all', t:'전체'},{c:'realty', t:'부동산·중개'},{c:'biz', t:'사업자·매장'},{c:'doc', t:'서류·계약'},{c:'life', t:'생활·기록'},{c:'soon', t:'준비 중'}];
var CHIP_KEY = 'kts_cat_chip';""")
# byK: LOCAL 표시
R("""  if (e) return {k:k, nm:e.nm, sub:e.sub, link:e.link, icon:e.icon||'', ico:e.ico||'', badge:e.badge||'', status:'live', price:''};""",
  """  if (e) return {k:k, nm:e.nm, sub:e.sub, link:e.link, icon:e.icon||'', ico:e.ico||'', badge:e.badge||'', status:'live', price:'', local:true};""")
# render(): 준비 중은 <a> 없이 · 카탈로그에 없는 LOCAL 은 상세 대신 [열기]와 같은 동작
R("""      var soon = (t.status==='soon') || !t.link;
      var mine = (window.KTS_KEYS && KTS_KEYS.inBox(k)) ? '<div class="mine">내 박스</div>' : '';
      var bd = t.badge ? '<span class="bd ' + (BADGE[t.badge]||'new') + '">' + t.badge + '</span>' : '';
      var lim = limLine(k);
      var detailHref = 'detail.html?k=' + encodeURIComponent(k);
      rows += '<div class="row' + (soon ? ' soon' : '') + '">' +
        '<div class="ico">' + (t.icon ? '<img src="' + t.icon + '" alt="" loading="lazy">' : (t.ico || '·')) + '</div>' +
        '<a class="main" href="' + detailHref + '">' +
          '<div class="nm"><span>' + t.nm + '</span>' + bd + '</div>' +
          '<div class="sub">' + (t.sub || '') + '</div>' + lim + '</a>' +""",
  """      var soon = (t.status==='soon') || !t.link;
      var mine = (!soon && window.KTS_KEYS && KTS_KEYS.inBox(k)) ? '<div class="mine">내 박스</div>' : '';
      /* 준비 중: '준비 중' 배지만(NEW·무료 배지 없음) */
      var bd = soon ? '<span class="bd soon">준비 중</span>'
                    : (t.badge ? '<span class="bd ' + (BADGE[t.badge]||'new') + '">' + t.badge + '</span>' : '');
      var lim = soon ? '' : limLine(k);
      var inner = '<div class="nm"><span>' + t.nm + '</span>' + bd + '</div>' +
          '<div class="sub">' + (t.sub || '') + '</div>' + lim;
      /* 151: 준비 중 = 보이기만(링크·tabindex·클릭 0) · 상세 페이지가 없는 LOCAL = [열기]와 같은 동작 */
      var main = soon ? '<div class="main" role="presentation">' + inner + '</div>'
               : (t.local ? '<div class="main" data-open="' + k + '" style="cursor:pointer">' + inner + '</div>'
                          : '<a class="main" href="detail.html?k=' + encodeURIComponent(k) + '">' + inner + '</a>');
      rows += '<div class="row' + (soon ? ' soon' : '') + '" data-k="' + k + '"' + (soon ? ' aria-disabled="true"' : '') + '>' +
        '<div class="ico">' + (t.icon ? '<img src="' + t.icon + '" alt="" loading="lazy">' : (t.ico || '·')) + '</div>' +
        main +""")
R("""    html += '<section class="sec" id="sec' + g.no + '"><div class="secH">""",
  """    html += '<section class="sec" id="sec' + g.no + '" data-cat="' + g.cat + '"><div class="secH">""")
R("""  $('#sections').innerHTML = html;
  renderFeat();""", """  $('#sections').innerHTML = html;
  renderChips();
  renderFeat();""")
# renderFeat: 준비 중이면 <a> 없이
R("""    return '<div class="row big' + (i===0 ? ' hi' : '') + (soon ? ' soon' : '') + '">' +
      '<div class="ico">' + (t.icon ? '<img src="' + t.icon + '" alt="" loading="lazy">' : (t.ico || '·')) + '</div>' +
      '<a class="main" href="detail.html?k=' + encodeURIComponent(f.k) + '">' +
        '<div class="nm"><span>' + t.nm + '</span></div>' +
        '<div class="one">' + f.one + '</div></a>' +""",
  """    var inner = '<div class="nm"><span>' + t.nm + '</span></div>' + '<div class="one">' + f.one + '</div>';
    return '<div class="row big' + (i===0 ? ' hi' : '') + (soon ? ' soon' : '') + '" data-k="' + f.k + '"' + (soon ? ' aria-disabled="true"' : '') + '>' +
      '<div class="ico">' + (t.icon ? '<img src="' + t.icon + '" alt="" loading="lazy">' : (t.ico || '·')) + '</div>' +
      (soon ? '<div class="main" role="presentation">' + inner + '</div>'
            : '<a class="main" href="detail.html?k=' + encodeURIComponent(f.k) + '">' + inner + '</a>') +""")
# 칩 렌더·필터
R("""function renderFeat(){""", """/* 카테고리 칩 — 누르면 그 섹션만(필터) · 마지막 선택은 이 기기에 기억 */
function chipNow(){ var c='all'; try{ c = localStorage.getItem(CHIP_KEY) || 'all'; }catch(e){}
  return CHIPS.some(function(x){ return x.c===c; }) ? c : 'all'; }
function applyChip(c){
  Array.prototype.forEach.call(document.querySelectorAll('#sections .sec'), function(s){
    s.hidden = !(c==='all' || s.getAttribute('data-cat')===c); });
  Array.prototype.forEach.call(document.querySelectorAll('#catChips button'), function(b){
    var on = b.getAttribute('data-cat')===c; b.classList.toggle('on', on); b.setAttribute('aria-pressed', on ? 'true' : 'false'); });
}
function renderChips(){
  var box = $('#catChips'); if (!box) return;
  box.innerHTML = CHIPS.map(function(x){
    return '<button type="button" data-cat="' + x.c + '"' + (x.c==='soon' ? ' class="s"' : '') + '>' + x.t + '</button>'; }).join('');
  applyChip(chipNow());
}
document.addEventListener('click', function(e){
  var b = e.target.closest ? e.target.closest('#catChips button[data-cat]') : null;
  if (!b) return;
  var c = b.getAttribute('data-cat');
  try{ localStorage.setItem(CHIP_KEY, c); }catch(err){}
  applyChip(c);
});

function renderFeat(){""")
# 히어로 점프: 대상 섹션이 칩으로 숨겨져 있으면 '전체'로
R("""  var el = document.getElementById(a.getAttribute('data-jump')); if (!el) return;
  e.preventDefault();""", """  var el = document.getElementById(a.getAttribute('data-jump')); if (!el) return;
  e.preventDefault();
  if (el.hidden) { try{ localStorage.setItem(CHIP_KEY,'all'); }catch(err){} applyChip('all'); }""")
# 열기 위임: 준비 중이면 즉시 return
R("""  var k = b.getAttribute('data-open'), t = byK(k);
  if (!t.link) { toastMsg('아직 주소가 없습니다'); return; }""", """  var k = b.getAttribute('data-open'), t = byK(k);
  if (t.status==='soon' || (b.closest && b.closest('.row.soon'))) return;   /* 151: 준비 중은 클릭 0 */
  if (!t.link) { toastMsg('아직 주소가 없습니다'); return; }""")
# 마스터 그리드: 답글생성기·번개알바 제거(165·156) · 상황판은 마스터 모드(#mst) 안에서만
R("""    '<a href="ad_magnet/">답글생성기</a><a href="seller/">원클릭 셀러</a><a href="bungee/">번개알바 도구</a><a href="ops/">군단 상황판</a>';""",
  """    '<a href="seller/">원클릭 셀러</a><a href="thescan/">더스캔</a><a href="theeraser/">더지우개</a><a href="ops/">군단 상황판</a>';""")
R('<script src="products.js?v=20261123a"></script>', '<script src="products.js?v=20261123c"></script>')
if crlf: s = s.replace('\n', '\r\n')
open(p, 'wb').write(s.encode('utf-8'))
print('ok', 'crlf' if crlf else 'lf')

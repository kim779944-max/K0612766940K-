"""133·138번: oneclick/index.html 패치 — shared/ 연결 + 히어로·대표 3종·4대 업종 묶음 + totop 위치."""
import io, sys

p = sys.argv[1]
s = io.open(p, encoding='utf-8').read()


def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (a[:60], s.count(a))
    s = s.replace(a, b)


rep('<html lang="ko">', '<html lang="ko" data-kts-theme="dark">')
rep('<meta property="og:url" content="https://autooneclick.com/">\n<style>',
    '<meta property="og:url" content="https://autooneclick.com/">\n'
    '<link rel="stylesheet" href="shared/kts-tokens.css?v=20261123a">\n'
    '<link rel="stylesheet" href="shared/kts-ui.css?v=20261123a">\n<style>')

LIGHT_AND_NEW = r'''.totop.on{opacity:1;transform:none;pointer-events:auto}

/* ===== 2026-11-23 공통 틀(shared/) 연결 — 기존 변수를 --k-* 별칭으로 (다크/라이트 두 벌을 따라온다) ===== */
:root,html[data-kts-theme]{--bg2:var(--k-bg);--card:var(--k-panel);--card2:var(--k-panel-2);--line:var(--k-line);--line2:var(--k-line-2);
  --ink:var(--k-ink);--ink2:var(--k-ink-2);--gray:var(--k-ink-3);--amber:var(--k-accent);--amber2:var(--k-accent-2)}
body{background:var(--k-glow),var(--bg2);font-family:var(--k-font)}
#app{padding-bottom:96px}
header.k-hd{margin:0 -15px;padding:0 15px;background:var(--k-hd-bg)}
header.k-hd .hd{min-height:56px;padding:0 1px}
header.k-hd .nb{margin-bottom:8px}
.hd .k-theme{width:44px;height:44px;font-size:17px}
@media (max-width:400px){.hd a.tel{padding:6px 7px;font-size:10.5px}.hd .brand{font-size:13.5px}.hd{gap:6px}}
/* 열기 버튼 — 터치 44px */
.act .go{min-height:44px;padding:0 14px;display:inline-flex;align-items:center;justify-content:center}
/* 히어로 (시안 2페이지) */
.heroBtns{display:flex;gap:8px;margin-top:12px}
.heroBtns .k-btn{flex:1;padding:0 10px;font-size:13.5px}
/* 대표 3종 — 큰 카드 */
.feat{margin-top:16px}
.feat .rows{gap:8px}
.row.big{padding:12px;min-height:92px;border-radius:14px;background:var(--k-panel)}
.row.big.hi{border-color:var(--k-accent);background:linear-gradient(150deg,rgba(255,107,0,.12),var(--k-panel) 60%)}
.row.big .ico{width:52px;height:52px;border-radius:12px}
.row.big .nm{font-size:16px}
.row.big .one{font-size:12.5px;color:var(--k-ink-2);margin-top:3px;line-height:1.45;word-break:keep-all}
.row.big .k-badge{font-size:10.5px;padding:2px 6px}
.secH .no{font-size:10.5px}
.secH p{font-size:10.5px}
/* 위로 버튼 — 왼쪽(도우미 버튼 위)으로: 카드 [열기]/[+] 자리를 비운다 */
.totop{left:10px;right:auto;bottom:calc(66px + env(safe-area-inset-bottom,0px))}
@media (min-width:720px){.totop{left:max(10px,calc(50% - 300px))}}

/* 라이트 벌 — 다크 전용으로 박혀 있던 글자·바탕만 덮는다(기존 규칙은 그대로) */
html[data-kts-theme="light"] .nm,html[data-kts-theme="light"] .lead b,html[data-kts-theme="light"] .boxwrap .lbl b,
html[data-kts-theme="light"] .cpnbar .t b,html[data-kts-theme="light"] .mstTop b,html[data-kts-theme="light"] .msheet b,
html[data-kts-theme="light"] .foot b,html[data-kts-theme="light"] .note b{color:var(--k-ink)}
html[data-kts-theme="light"] .sub,html[data-kts-theme="light"] .lead,html[data-kts-theme="light"] .nb,html[data-kts-theme="light"] .cpnbar .t span,
html[data-kts-theme="light"] .ask p,html[data-kts-theme="light"] .mstLine,html[data-kts-theme="light"] .msheet p,
html[data-kts-theme="light"] .note,html[data-kts-theme="light"] .foot,html[data-kts-theme="light"] .secH p,
html[data-kts-theme="light"] .boxwrap .lbl{color:var(--k-ink-2)}
html[data-kts-theme="light"] .row{background:var(--k-panel)}
html[data-kts-theme="light"] .row.big.hi{background:linear-gradient(150deg,rgba(255,107,0,.08),var(--k-panel) 60%)}
html[data-kts-theme="light"] .ico{background:var(--k-panel-2);border-color:var(--k-line-2)}
html[data-kts-theme="light"] .lim{color:#a2410a}
html[data-kts-theme="light"] .lim.zero{color:#15803d;background:rgba(22,163,74,.1)}
html[data-kts-theme="light"] .act .go[disabled],html[data-kts-theme="light"] .act .soonb{background:var(--k-panel-2);border-color:var(--k-line-2);color:var(--k-ink-3)}
html[data-kts-theme="light"] .nb{background:var(--k-panel);border-color:var(--k-line)}
html[data-kts-theme="light"] .nb button,html[data-kts-theme="light"] .hd .mkey:not(.on),html[data-kts-theme="light"] .hd a.tel{background:var(--k-panel);border-color:var(--k-line-2);color:var(--k-ink-2)}
html[data-kts-theme="light"] .hd .kbtn{color:#a2410a}
html[data-kts-theme="light"] .ask b[style]{color:#a2410a!important}
html[data-kts-theme="light"] .foot,html[data-kts-theme="light"] .foot a{border-color:var(--k-line-2)}
html[data-kts-theme="light"] .foot a{color:var(--k-ink-2)}
html[data-kts-theme="light"] .note{border-color:var(--k-line);background:var(--k-panel)}
html[data-kts-theme="light"] .mstGrid a,html[data-kts-theme="light"] .mstOff{background:var(--k-panel);border-color:var(--k-line-2);color:var(--k-ink)}
html[data-kts-theme="light"] .mstLine b{color:#a2410a}
html[data-kts-theme="light"] .msheet{background:var(--k-panel)}
html[data-kts-theme="light"] .msheet input{background:var(--k-panel-2);color:var(--k-ink);border-color:var(--k-line-2)}
html[data-kts-theme="light"] .mrow button.ghost{background:var(--k-panel-2);color:var(--k-ink);border-color:var(--k-line-2)}
html[data-kts-theme="light"] .ks-strip{background:var(--k-panel);border-color:var(--k-line)}
html[data-kts-theme="light"] .ks-strip .h{color:var(--k-ink)}
html[data-kts-theme="light"] .ks-strip .h button{background:var(--k-panel-2);border-color:var(--k-line-2);color:var(--k-ink)}
html[data-kts-theme="light"] .ks-strip .h .keys{color:#a2410a}
html[data-kts-theme="light"] .ks-strip .c{background:var(--k-panel-2);border-color:var(--k-line);color:var(--k-ink)}
html[data-kts-theme="light"] .ks-strip .c.full{background:rgba(255,107,0,.08);border-color:rgba(255,107,0,.6)}
html[data-kts-theme="light"] .ks-strip .c.lk{border-color:var(--k-line-2);color:var(--k-ink-3)}
</style>
<link rel="stylesheet" href="shared/kts-print.css?v=20261123a">
<script src="shared/kts-ui.js?v=20261123a" defer></script>
</head>'''
rep('.totop.on{opacity:1;transform:none;pointer-events:auto}\n</style>\n</head>', LIGHT_AND_NEW)

rep('  <header>\n    <div class="hd">', '  <header class="k-hd">\n    <div class="hd">')
rep('      <div class="sp"></div>\n      <button class="kbtn"',
    '      <div class="sp"></div>\n'
    '      <button class="k-theme" id="themeBtn" type="button" aria-pressed="false" aria-label="밝게 보기">☾</button>\n'
    '      <button class="kbtn"')

rep('''  <div class="hero">
    <span class="kicker">설치 없이 · 로그인 없이 · 결제 없이</span>
    <h1>폰 하나로 <em>서류·매물·장사</em>를<br>끝냅니다.</h1>
    <p class="lead">쓰는 순서대로 늘어놓았습니다. <b>위에서부터 4개를 박스에 담으면</b> 매일 바로 열립니다.</p>
  </div>
''', '''  <div class="hero">
    <span class="kicker">설치 없이 · 로그인 없이 · 결제 없이</span>
    <h1>반복 업무, <em>클릭 한 번</em>으로<br>끝내세요</h1>
    <p class="lead">설치 없이 바로 쓰는 사업자용 업무 도구. <b>매물 정리부터 상품 콘텐츠·서명까지.</b></p>
    <div class="heroBtns">
      <a class="k-btn" href="#sec01" data-jump="sec01">무료로 시작하기</a>
      <a class="k-btn ghost" href="#allGroups" data-jump="allGroups">도구 전체 보기</a>
    </div>
  </div>

  <section class="feat" id="feat" aria-label="대표 도구 3종">
    <div class="rows" id="featRows"></div>
  </section>
''')
rep('  <main id="sections"></main>', '  <div id="allGroups">\n  <main id="sections"></main>\n  </div>')
rep('  <div class="foot">\n    <b>KTS 원클릭</b> · 문의', '  <div class="foot k-foot">\n    <b>케이티에스 원클릭</b> · 문의')
rep('<a href="bungee/">번개알바 도구</a>\n  </div>',
    '<a href="bungee/">번개알바 도구</a><br>\n'
    '    이용약관 · 개인정보처리방침 — 준비 중(결제·회원가입이 없어 따로 모으는 개인정보가 없습니다)\n  </div>')
rep('products.js?v=20261122a', 'products.js?v=20261123a')
rep('helper.js?v=20261122a', 'helper.js?v=20261123a')

a = s.index('var GROUPS = [')
b = s.index('];', a) + 2
s = s[:a] + '''var GROUPS = [
  {no:'01', t:'부동산·중개사', s:'매물·계약·권리·경사도', ks:['listing','realty','exchange','slope','redev','contract','theform','sign','viewer','thescan']},
  {no:'02', t:'쇼핑몰·셀러', s:'상품·상세·광고·등록', ks:['commerce','seller','thedetail','keyword','ad_magnet','photo2doc','theeraser']},
  {no:'03', t:'자영업·매장', s:'홍보·가계부·외국 손님·자금', ks:['bungee_home','bungee_poster','bungee_interior','gagebu','tongyeok','loan','tax','interior']},
  {no:'04', t:'개인·생활', s:'장보기·휴대폰·취미·기록', ks:['sale','hogang','golf','petmind','saycap','navi','organizer']},
  {no:'05', t:'준비 중', s:'나오면 맨 위에 알려 드립니다', ks:['append','youtube','travel']}
];
/* 대표 3종 — 강조용 복제(목록 완전성 검사에서 제외) */
var FEATURED = [
  {k:'listing', one:'매물 하나가 영업하는 홈페이지가 됩니다'},
  {k:'sign',    one:'사인·도장 → 투명 PNG → 문서 날인'},
  {k:'slope',   one:'지번 하나로 필지 경사도·단면'}
];
window.__KTS_GROUPS = GROUPS;  /* 읽기 전용 노출 — 목록 완전성 검사용 */''' + s[b:]

rep("""    html += '<section class="sec"><div class="secH">""",
    """    html += '<section class="sec" id="sec' + g.no + '"><div class="secH">""")
rep("  $('#sections').innerHTML = html;", "  $('#sections').innerHTML = html;\n  renderFeat();")
rep('/* 열기 — 1회 무료 시연 → 내 박스 관문 */', r'''function renderFeat(){
  var box = $('#featRows'); if (!box) return;
  box.innerHTML = FEATURED.map(function(f, i){
    var t = byK(f.k);
    var soon = (t.status==='soon') || !t.link;
    var ft = (window.KTS_KEYS && KTS_KEYS.freeText) ? KTS_KEYS.freeText(f.k) : '';
    var badge = soon ? '<span class="k-badge soon">준비 중</span>' : (ft ? '<span class="k-badge lim">' + ft + '</span>' : '');
    return '<div class="row big' + (i===0 ? ' hi' : '') + (soon ? ' soon' : '') + '">' +
      '<div class="ico">' + (t.icon ? '<img src="' + t.icon + '" alt="" loading="lazy">' : (t.ico || '·')) + '</div>' +
      '<a class="main" href="detail.html?k=' + encodeURIComponent(f.k) + '">' +
        '<div class="nm"><span>' + t.nm + '</span></div>' +
        '<div class="one">' + f.one + '</div></a>' +
      '<div class="act">' + badge +
        (soon ? '<button class="go soonb" type="button" disabled>준비 중</button>'
              : '<button class="go" type="button" data-open="' + f.k + '">열기</button>') +
      '</div></div>';
  }).join('');
}
/* 히어로 버튼 — 부드럽게 내려가기(고정 헤더 높이만큼 덜) */
document.addEventListener('click', function(e){
  var a = e.target.closest ? e.target.closest('[data-jump]') : null;
  if (!a) return;
  var el = document.getElementById(a.getAttribute('data-jump')); if (!el) return;
  e.preventDefault();
  var hd = document.querySelector('header'), off = hd ? hd.getBoundingClientRect().height + 8 : 0;
  window.scrollTo({top: el.getBoundingClientRect().top + window.scrollY - off, behavior:'smooth'});
});

/* 열기 — 1회 무료 시연 → 내 박스 관문 */''')

io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('ok', len(s))

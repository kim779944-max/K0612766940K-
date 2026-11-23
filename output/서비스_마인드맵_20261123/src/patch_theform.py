"""158번 — 더양식에 탭 2개: ① 종이 양식 채우기(기존 #s1~#s3 그대로) | ② 표 사진 → 한글·엑셀(구 문서변환기 · convert.html)
usage: python patch_theform.py <oneclick>  — 기존 엔진 스크립트는 건드리지 않고 마크업·CSS·작은 탭 스크립트만 덧붙인다."""
import os, sys
p = os.path.join(sys.argv[1], 'theform', 'index.html')
b = open(p, 'rb').read(); crlf = b'\r\n' in b
s = b.decode('utf-8').replace('\r\n', '\n')
def R(a, c):
    global s
    assert s.count(a) == 1, (a[:60], s.count(a)); s = s.replace(a, c)

R('</style>\n</head><body>', """/* ── 더양식 탭 2개 (158 · 2026-11-23) ── */
.ftabs{display:flex;gap:6px;padding:0 14px 10px}
.ftabs button{flex:1;min-height:44px;border-radius:12px;border:1px solid var(--line2);background:#0F1B33;color:#AFBDD0;
 font-size:12.5px;font-weight:900;letter-spacing:-.3px;line-height:1.2;padding:6px 8px}
.ftabs button b{display:block;font-size:10px;font-weight:800;color:#7C8DA6;margin-top:2px}
.ftabs button.on{background:linear-gradient(180deg,#FF8A2B,#FF6B00);border-color:#FF6B00;color:#0A1224}
.ftabs button.on b{color:#3A1A00}
#cvPane{display:none}
body.cv #cvPane{display:block}
body.cv main,body.cv .bar,body.cv #steps,body.cv .ktsRsv,body.cv .kux-free,body.cv .kux-flow,body.cv .kuxguide,body.cv .kux-morebar{display:none!important}
#cvFrame{display:block;width:100%;border:0;background:#0A1128}
</style>
</head><body>""")
R(""" <nav class="steps" id="steps">""", """ <nav class="ftabs" id="ftabs" aria-label="더양식 기능">
  <button type="button" data-tab="form" aria-pressed="true">① 종이 양식 채우기<b>사진 위 빈칸 → 한글·엑셀·PDF</b></button>
  <button type="button" data-tab="convert" aria-pressed="false">② 표 사진 → 한글·엑셀<b>구 문서변환기 · 원본 서식 유지</b></button>
 </nav>
 <nav class="steps" id="steps">""")
R("""<main>\n<!-- ① 등록 -->""", """<section id="cvPane" aria-label="표 사진 → 한글·엑셀"><iframe id="cvFrame" title="표 사진 → 한글·엑셀 변환" loading="lazy"></iframe></section>
<main>\n<!-- ① 등록 -->""")
R("""<script src="../ux.js?v=20261121k"></script>""", """<script src="../ux.js?v=20261121k"></script>
<script>
/* 더양식 탭 — ?tab=convert 이면 ② 탭으로 연다. ② 는 구 문서변환기 엔진(js/converter.js)을 convert.html 로 그대로 띄운다. */
(function(){
  var frame = document.getElementById('cvFrame'), head = document.querySelector('header.top');
  function fit(){ if (frame) frame.style.height = Math.max(480, (window.innerHeight || 700) - (head ? head.offsetHeight : 0)) + 'px'; }
  function show(t){
    var cv = (t === 'convert');
    document.body.classList.toggle('cv', cv);
    Array.prototype.forEach.call(document.querySelectorAll('#ftabs button'), function(b){
      var on = b.getAttribute('data-tab') === t; b.classList.toggle('on', on); b.setAttribute('aria-pressed', on ? 'true' : 'false'); });
    if (cv && frame && !frame.getAttribute('src')) frame.setAttribute('src', 'convert.html?v=20261123c');
    if (cv) fit();
    try {
      var q = new URLSearchParams(location.search);
      if (cv) q.set('tab', 'convert'); else q.delete('tab');
      var qs = q.toString(); history.replaceState(history.state, '', location.pathname + (qs ? '?' + qs : '') + location.hash);
    } catch (e) {}
  }
  document.getElementById('ftabs').addEventListener('click', function(e){
    var b = e.target.closest('button[data-tab]'); if (b) { show(b.getAttribute('data-tab')); window.scrollTo(0, 0); }
  });
  window.addEventListener('resize', fit);
  var t = 'form'; try { t = new URLSearchParams(location.search).get('tab') === 'convert' ? 'convert' : 'form'; } catch (e) {}
  show(t);
})();
</script>""")
if crlf: s = s.replace('\n', '\r\n')
open(p, 'wb').write(s.encode('utf-8'))
print('ok theform/index.html')

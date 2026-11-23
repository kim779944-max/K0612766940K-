"""162번 — 사업자 대출: loan.html(기업 대출) · tax.html(창업·세무) 상단에 같은 탭 1벌을 넣어 서로 오가게 한다.
엔진(계산·리포트) 무변경. 탭 색·높이는 shared/kts-tokens.css 값(딥네이비 #141f38 · 오렌지 #ff6b00 · 44px).
usage: python patch_loan_tax.py <oneclick>"""
import os, sys
TABS = """<!-- 사업자 대출 탭 (162 · 2026-11-23) — loan.html · tax.html 공통 1벌 -->
<style>
.bizTabs{margin:0 0 12px}
.bizTabs .bt-t{font-size:11px;font-weight:900;color:#ff994b;letter-spacing:.02em;margin:0 0 6px}
.bizTabs .bt-r{display:flex;gap:6px}
.bizTabs a{flex:1;display:flex;align-items:center;justify-content:center;min-height:44px;border-radius:12px;text-decoration:none;
 font-size:13.5px;font-weight:900;letter-spacing:-.3px;color:#a5b1c7;background:#141f38;border:1px solid #36425c}
.bizTabs a.on{color:#141414;background:linear-gradient(180deg,#ff994b,#ff6b00);border-color:#ff6b00}
</style>
<nav class="bizTabs" aria-label="사업자 대출">
  <p class="bt-t">사업자 대출 — 한 화면 두 탭</p>
  <div class="bt-r">
    <a href="loan.html" data-bt="loan">기업 대출</a>
    <a href="tax.html?tab=biz" data-bt="tax">창업·세무</a>
  </div>
</nav>
<script>(function(){var f=/tax\\.html/.test(location.pathname)?'tax':'loan';
  Array.prototype.forEach.call(document.querySelectorAll('.bizTabs a'),function(a){
    var on=a.getAttribute('data-bt')===f; a.classList.toggle('on',on); if(on) a.setAttribute('aria-current','page');});})();</script>
"""
for rel, ico in [('loan.html', 'icon_loan.png'), ('tax.html', 'icon_tax.png')]:
    p = os.path.join(sys.argv[1], rel)
    b = open(p, 'rb').read(); crlf = b'\r\n' in b
    s = b.decode('utf-8').replace('\r\n', '\n')
    a = f'''    <a href="index.html" target="_blank" rel="noopener">← 원클릭</a>
  </div>
'''
    assert s.count(a) == 1, rel
    s = s.replace(a, a + '\n' + TABS)
    if crlf: s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))
    print('ok', rel)

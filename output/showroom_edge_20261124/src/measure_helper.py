# 도우미 버튼 가림 면적 측정 (390x844) — 사용: python -P -X utf8 measure_helper.py <base_url> <label> [top%]
import sys, json
from playwright.sync_api import sync_playwright

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
BASE = sys.argv[1].rstrip('/')
LABEL = sys.argv[2]
TOP = sys.argv[3] if len(sys.argv) > 3 else None
PAGES = ['/index.html', '/listing/index.html', '/theform/index.html', '/contract/index.html']

JS = r"""(() => {
  var b = document.querySelector('#kts-helper-btn'); if (!b) return {none:1};
  b = b.getBoundingClientRect();
  var hit = [...document.querySelectorAll('button,input,textarea,table,.acts,a.k-btn,select')].filter(e => e.id !== 'kts-helper-btn').map(function(e){
    var r = e.getBoundingClientRect(); if (!r.width || r.top > innerHeight || r.bottom < 0) return null;
    var cs = getComputedStyle(e); if (cs.visibility === 'hidden' || cs.display === 'none') return null;
    var w = Math.min(b.right, r.right) - Math.max(b.left, r.left), h = Math.min(b.bottom, r.bottom) - Math.max(b.top, r.top);
    return (w > 0 && h > 0) ? {a: Math.round(w*h), tag: e.tagName, t: (e.textContent || e.value || '').trim().slice(0, 14)} : null;
  }).filter(Boolean);
  return {btn: [Math.round(b.left), Math.round(b.top), Math.round(b.width), Math.round(b.height)], hit: hit,
          sum: hit.reduce((s, x) => s + x.a, 0)};
})()"""

out = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME)
    for path in PAGES:
        ctx = br.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=1, has_touch=True, is_mobile=True)
        pg = ctx.new_page()
        pg.goto(BASE + path, wait_until='load')
        if TOP:
            pg.add_style_tag(content='@media (max-width:719px){#kts-helper-btn{top:%s!important}}' % TOP)
        pg.wait_for_timeout(4300)
        res = {'scroll0': pg.evaluate(JS)}
        # 스크롤 중간·끝도 함께(본문이 지나갈 때 가림)
        tot = 0; n = 0
        H = pg.evaluate('document.documentElement.scrollHeight')
        for y in range(0, max(1, H - 844) + 1, 400):
            pg.evaluate('window.scrollTo(0,%d)' % y); pg.wait_for_timeout(120)
            r = pg.evaluate(JS); tot += r.get('sum', 0); n += 1
        res['scrollSum'] = tot; res['steps'] = n
        out[path] = res
        ctx.close()
    br.close()
tot0 = sum(v['scroll0'].get('sum', 0) for v in out.values())
totS = sum(v['scrollSum'] for v in out.values())
print(json.dumps({'label': LABEL, 'top': TOP, 'first_screen_total': tot0, 'all_scroll_total': totS, 'pages': out}, ensure_ascii=False, indent=1))

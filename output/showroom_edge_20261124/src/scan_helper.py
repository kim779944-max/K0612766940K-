# 도우미 버튼 자리 후보 스캔 — 오른쪽/왼쪽 × 세로 % · 3화면(쇼룸·더양식·더계약서; 매물장은 도우미 없음) 가림 면적 합
import sys, json
from playwright.sync_api import sync_playwright
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
BASE = sys.argv[1].rstrip('/')
PAGES = ['/index.html', '/theform/index.html', '/contract/index.html']
CANDS = [('oldLB', 0)] + [('right', t) for t in (12, 20, 30, 38, 45, 55, 65, 75, 82)] + [('left', t) for t in (38, 55, 75)]
JS = r"""(() => {
  var b = document.querySelector('#kts-helper-btn').getBoundingClientRect(), s = 0, l = [];
  document.querySelectorAll('button,input,textarea,table,.acts,a.k-btn,select').forEach(function(e){
    if (e.id === 'kts-helper-btn') return;
    var r = e.getBoundingClientRect(); if (!r.width || r.top > innerHeight || r.bottom < 0) return;
    var cs = getComputedStyle(e); if (cs.visibility === 'hidden' || cs.display === 'none') return;
    var w = Math.min(b.right, r.right) - Math.max(b.left, r.left), h = Math.min(b.bottom, r.bottom) - Math.max(b.top, r.top);
    if (w > 0 && h > 0) { s += w * h; l.push((e.textContent || '').trim().slice(0, 10)); }
  });
  return [Math.round(s), l];
})()"""
res = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME)
    for path in PAGES:
        c = br.new_context(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        c.add_init_script("try{localStorage.setItem('kts_tool_intro_seen_theform','1');localStorage.setItem('kts_tool_intro_seen_sign','1')}catch(e){}")
        pg = c.new_page()
        for side, t in CANDS:
            pg.goto(BASE + path, wait_until='load'); pg.wait_for_timeout(1800)
            if side == 'oldLB':
                css = 'left:10px!important;right:auto!important;top:auto!important;bottom:10px!important'
            else:
                css = ('left:auto!important;right:8px!important' if side == 'right' else 'right:auto!important;left:8px!important') + ';top:%d%%!important;bottom:auto!important' % t
            pg.add_style_tag(content='#kts-helper-btn{%s}' % css); pg.wait_for_timeout(100)
            H = pg.evaluate('document.documentElement.scrollHeight')
            ys = list(range(0, max(1, H - 844) + 1, 400))
            first = None; tot = 0
            for y in ys:
                pg.evaluate('window.scrollTo(0,%d)' % y); pg.wait_for_timeout(60)
                a, l = pg.evaluate(JS); tot += a
                if first is None: first = (a, l)
            res.setdefault('%s %d%%' % (side, t), {})[path] = {'first': first[0], 'scroll': tot, 'hit0': first[1], 'steps': len(ys)}
        c.close()
    br.close()
rows = []
for k, v in res.items():
    rows.append((k, sum(x['first'] for x in v.values()), sum(x['scroll'] for x in v.values()), {p: (x['first'], x['scroll']) for p, x in v.items()}))
for r in sorted(rows, key=lambda r: (r[2], r[1])):
    print(r[0], 'first=', r[1], 'scroll=', r[2], r[3])
json.dump(res, open(sys.argv[2], 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

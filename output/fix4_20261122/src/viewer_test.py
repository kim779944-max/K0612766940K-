# 더뷰 핀치·스크롤 실측 — python viewer_test.py <tag>
import json, sys, os
from playwright.sync_api import sync_playwright
TAG = sys.argv[1] if len(sys.argv) > 1 else 'after'
BASE = os.environ.get('FIX4_BASE', 'http://127.0.0.1:8765')
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, '..'); SH = os.path.join(OUT, 'shots')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
PDF = os.path.join(OUT, 'dl', 'test3p.pdf')
R = {'tag': TAG}; errs = []

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, headless=True)
    if not os.path.exists(PDF):
        p0 = br.new_page()
        p0.set_content('<style>div{height:1000px;font:40px sans-serif;border:4px solid #333;padding:30px}</style>' +
                       ''.join(f'<div style="page-break-after:always">페이지 {i} — 더뷰 핀치 시험 문서 {"가나다라마바사 " * 30}</div>' for i in range(1, 4)))
        p0.pdf(path=PDF, format='A4'); p0.close()
    c = br.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True)
    pg = c.new_page(); pg.on('pageerror', lambda e: errs.append(str(e)[:200]))
    pg.goto(BASE + '/viewer.html', wait_until='networkidle'); pg.wait_for_timeout(800)
    pg.set_input_files('#f', PDF)
    pg.wait_for_function("document.body.classList.contains('docopen') && document.getElementById('vtPct') && /%/.test(document.getElementById('vtPct').textContent)", timeout=30000)
    pg.wait_for_timeout(2500)
    cdp = c.new_cdp_session(pg)
    J = lambda js: pg.evaluate(js)
    pct = lambda: int(J("parseInt(document.getElementById('vtPct').textContent)"))
    box = J("(() => { const r = document.getElementById('out').getBoundingClientRect(); return {x: r.left, y: r.top, w: r.width, h: r.height}; })()")
    cx, cy = box['x'] + box['w'] / 2, box['y'] + box['h'] / 2
    R['touchAction'] = J("getComputedStyle(document.getElementById('out')).touchAction")
    def touch(typ, pts):
        cdp.send('Input.dispatchTouchEvent', {'type': typ, 'touchPoints': [{'x': x, 'y': y, 'id': i} for i, (x, y) in enumerate(pts)]})
    def pinch(d0, d1, steps=12):
        touch('touchStart', [(cx - d0 / 2, cy), (cx + d0 / 2, cy)])
        for s in range(1, steps + 1):
            d = d0 + (d1 - d0) * s / steps
            touch('touchMove', [(cx - d / 2, cy), (cx + d / 2, cy)]); pg.wait_for_timeout(16)
        touch('touchEnd', []); pg.wait_for_timeout(600)
    # 기준: 100%로 맞춘 뒤
    J("document.getElementById('vtOne').click()"); pg.wait_for_timeout(500)
    R['start'] = pct()
    pg.screenshot(path=os.path.join(SH, f'B0_viewer_start_{TAG}.jpg'), type='jpeg', quality=60)
    pinch(80, 200); R['pinchOut'] = pct()
    pg.screenshot(path=os.path.join(SH, f'B1_viewer_pinchout_{TAG}.jpg'), type='jpeg', quality=60)
    pinch(220, 90); R['pinchIn'] = pct()
    # +/- 버튼
    J("document.getElementById('vtOne').click()"); pg.wait_for_timeout(300)
    J("document.getElementById('vtIn').click()"); pg.wait_for_timeout(300); R['plus'] = pct()
    J("document.getElementById('vtOut').click()"); pg.wait_for_timeout(300); R['minus'] = pct()
    # 한 손가락 세로 스크롤
    J("document.getElementById('vtOne').click()"); pg.wait_for_timeout(300)
    J("document.getElementById('out').scrollTop = 0"); pg.wait_for_timeout(200)
    st0 = J("document.getElementById('out').scrollTop")
    touch('touchStart', [(cx, cy + 200)])
    for s in range(1, 11):
        touch('touchMove', [(cx, cy + 200 - 30 * s)]); pg.wait_for_timeout(16)
    touch('touchEnd', []); pg.wait_for_timeout(1200)
    R['scrollY'] = {'before': st0, 'after': J("document.getElementById('out').scrollTop"), 'page': J("(document.getElementById('ppLbl')||document.querySelector('[id*=pg]')||{}).textContent || ''")}
    # 확대 후 가로 스크롤
    J("document.getElementById('vtIn').click(); document.getElementById('vtIn').click(); document.getElementById('vtIn').click()"); pg.wait_for_timeout(500)
    sl0 = J("document.getElementById('out').scrollLeft")
    touch('touchStart', [(cx + 100, cy)])
    for s in range(1, 9):
        touch('touchMove', [(cx + 100 - 20 * s, cy)]); pg.wait_for_timeout(16)
    pg.wait_for_timeout(100); touch('touchEnd', []); pg.wait_for_timeout(800)
    R['scrollX'] = {'zoom': pct(), 'before': sl0, 'after': J("document.getElementById('out').scrollLeft"),
                    'scrollW': J("document.getElementById('out').scrollWidth"), 'clientW': J("document.getElementById('out').clientWidth")}
    # 닫기 → 다시 열기
    closed = J("""(() => { const b = [...document.querySelectorAll('button,a')].find(x => /닫기|처음|뒤로|←/.test(x.textContent) && x.offsetParent);
                 if (!b) return null; b.click(); return b.textContent.trim().slice(0,20); })()""")
    pg.wait_for_timeout(800)
    R['afterClose'] = {'btn': closed, 'docopen': J("document.body.classList.contains('docopen')"), 'touchAction': J("getComputedStyle(document.getElementById('out')).touchAction")}
    pg.set_input_files('#f', PDF)
    pg.wait_for_function("document.body.classList.contains('docopen')", timeout=30000); pg.wait_for_timeout(2000)
    J("document.getElementById('vtOne').click()"); pg.wait_for_timeout(300)
    pinch(80, 200); R['reopenPinch'] = pct()
    R['pageerrors'] = errs
    br.close()
with open(os.path.join(OUT, f'viewer_{TAG}.json'), 'w', encoding='utf-8') as f:
    json.dump(R, f, ensure_ascii=False, indent=1)
print(json.dumps(R, ensure_ascii=False))

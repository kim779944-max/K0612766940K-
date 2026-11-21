# 8개 화면 pageerror·콘솔 오류·HTTP 상태 — python smoke.py <base> <tag>
import json, sys, os
from playwright.sync_api import sync_playwright
BASE = sys.argv[1].rstrip('/'); TAG = sys.argv[2]
PAGES = ['/', '/navi2/', '/viewer.html', '/gagebu/', '/petmind/', '/redev/', '/saycap/', '/ad_magnet/']
R = {}
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    for w, h in ((390, 844), (360, 800)):
        c = b.new_context(viewport={'width': w, 'height': h}, is_mobile=True, has_touch=True)
        for path in PAGES:
            pg = c.new_page(); pe = []; ce = []
            pg.on('pageerror', lambda e: pe.append(str(e)[:160]))
            pg.on('console', lambda m: ce.append(m.text[:160]) if m.type == 'error' else None)
            resp = pg.goto(BASE + path, wait_until='networkidle', timeout=45000); pg.wait_for_timeout(1200)
            R[f'{w} {path}'] = {'status': resp.status if resp else None, 'pageerror': pe, 'consoleError': ce,
                                 'docW': pg.evaluate('document.documentElement.scrollWidth'), 'innerW': pg.evaluate('innerWidth')}
            pg.close()
        c.close()
    b.close()
json.dump(R, open(os.path.join(os.path.dirname(__file__), '..', f'smoke_{TAG}.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
for k, v in R.items():
    print(k, v['status'], 'pageerror', len(v['pageerror']), 'consoleErr', len(v['consoleError']), 'docW/innerW', v['docW'], v['innerW'], (v['consoleError'][:2] if v['consoleError'] else ''))

import json, sys, os
from playwright.sync_api import sync_playwright
TAG = sys.argv[1]; BASE = sys.argv[2]
SH = os.path.join(os.path.dirname(__file__), '..', 'shots')
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    c = b.new_context(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.goto(BASE + '/redev/', wait_until='networkidle')
    pg.wait_for_function("document.getElementById('stS').textContent.trim() !== '' && document.getElementById('stS').textContent !== '—'", timeout=20000)
    R = {'placeholder': pg.get_attribute('#q', 'placeholder'), 'tab': pg.evaluate("document.querySelector('#tabs .on').dataset.t")}
    import re
    ex = re.findall(r'예: ([^)]*)', R['placeholder'])[0].split(', ')
    def search(q):
        pg.fill('#q', q); pg.dispatch_event('#q', 'input'); pg.wait_for_timeout(500)
        return {'q': q, 'cnt': pg.evaluate("document.getElementById('cnt').textContent"),
                'empty': pg.evaluate("(document.querySelector('#list .empty')||{}).innerText || ''").replace('\n', ' / ')}
    R['examples'] = [search(q) for q in ex]
    pg.screenshot(path=os.path.join(SH, f'D4_redev_example_{TAG}.jpg'), type='jpeg', quality=65)
    R['beon411_seoul'] = search('번동 411')
    pg.screenshot(path=os.path.join(SH, f'D4_redev_beon411_{TAG}.jpg'), type='jpeg', quality=65)
    pg.click('#tabs button[data-t=moa]'); pg.wait_for_timeout(500)
    R['beon411_moa'] = search('번동 411')
    R['errs'] = errs
    b.close()
print(json.dumps(R, ensure_ascii=False, indent=1))

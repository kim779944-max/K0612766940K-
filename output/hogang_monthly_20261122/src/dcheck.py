# D-1: 기종 그리드 31칸 · 큰 사진 naturalWidth, '사진 준비 중' 개수, 캡처 2장
import json, os, sys
from playwright.sync_api import sync_playwright
URL = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8791/hogang/'
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, '..')
r = {}; errs = []
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    pg = b.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True).new_page()
    pg.on('pageerror', lambda e: errs.append('pageerror: ' + str(e)))
    pg.on('console', lambda m: errs.append('console.error: ' + m.text) if m.type == 'error' else None)
    pg.on('requestfailed', lambda q: errs.append('requestfailed: ' + q.url))
    pg.on('response', lambda s: errs.append('http%d: %s' % (s.status, s.url)) if s.status >= 400 else None)
    pg.goto(URL, wait_until='networkidle'); pg.wait_for_function('window.__HOGANG')
    n = pg.evaluate("document.querySelectorAll('.mg[data-i]').length")
    for i in range(n):
        pg.evaluate("(i)=>document.querySelectorAll('.mg[data-i]')[i].scrollIntoView({block:'center'})", i)
    pg.wait_for_timeout(800)
    r['grid'] = pg.evaluate("""Promise.all([...document.querySelectorAll('.mg[data-i]')].map(async b=>{const im=b.querySelector('img');
        if(im){try{await im.decode();}catch(e){}} return [b.querySelector('b').textContent, im?im.naturalWidth:0];}))""")
    r['placeholders'] = pg.evaluate("document.body.innerText.split('사진 준비 중').length-1")
    # 큰 사진: 기종 하나씩 선택
    big = []
    for i in range(n):
        big.append(pg.evaluate("""async (i)=>{const e=document.querySelector('#iModel');e.value=String(i);e.dispatchEvent(new Event('change'));
            const im=document.querySelector('#mdl img'); if(!im) return [i,0]; try{await im.decode();}catch(x){} return [document.querySelector('#mdl .nm').textContent, im.naturalWidth];}""", i))
    r['big'] = big
    pg.evaluate("(()=>{const e=document.querySelector('#iModel');e.value='2';e.dispatchEvent(new Event('change'));})()")
    pg.evaluate("document.querySelector('#mgrid').scrollIntoView({block:'start'}); window.scrollBy(0,-70)")
    pg.wait_for_timeout(400)
    pg.screenshot(path=os.path.join(OUT, 'shots', 'after_models_top_390.png'))
    pg.evaluate("document.querySelectorAll('.mg[data-i]')[%d].scrollIntoView({block:'end'}); window.scrollBy(0,40)" % (n - 1))
    pg.wait_for_timeout(400)
    pg.screenshot(path=os.path.join(OUT, 'shots', 'after_models_bottom_390.png'))
    r['sw'] = pg.evaluate('document.documentElement.scrollWidth')
    r['errors'] = errs
    b.close()
json.dump(r, open(os.path.join(OUT, 'data', 'dcheck.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('grid', len(r['grid']), 'zero', [g for g in r['grid'] if not g[1]], 'big zero', [g for g in r['big'] if not g[1]], 'ph', r['placeholders'], 'sw', r['sw'], 'errors', r['errors'])
print([g[1] for g in r['grid']])

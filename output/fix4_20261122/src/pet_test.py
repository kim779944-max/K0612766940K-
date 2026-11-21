import json, sys, os
from playwright.sync_api import sync_playwright
TAG = sys.argv[1]; BASE = sys.argv[2]
SH = os.path.join(os.path.dirname(__file__), '..', 'shots')
STATE = """(() => { const imgs = [...document.querySelectorAll('main img')].filter(i => i.offsetParent);
  const src = imgs.map(i => i.getAttribute('src'));
  return { hash: location.hash, chipOn: (document.querySelector('#who .chip.on')||{}).textContent,
    probs: [...document.querySelectorAll('#probs .chip')].map(b => b.childNodes[0].textContent),
    fixTitle: (document.querySelector('#fixBox h2')||{}).textContent,
    steps: document.querySelectorAll('#fixBox .steps6 li').length,
    dogImgs: src.filter(s => /dog_/.test(s)).length, catImgs: src.filter(s => /cats?_/.test(s)).length,
    uniqueCatImgs: [...new Set(src.filter(s => /cats?_/.test(s)))].length,
    broken: imgs.filter(i => i.complete && i.naturalWidth === 0).length,
    docW: document.documentElement.scrollWidth }; })()"""
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    c = b.new_context(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
    R = {}
    def settle():
        pg.evaluate("[...document.querySelectorAll('img')].forEach(i => i.loading = 'eager')")
        pg.wait_for_timeout(900)
    pg.goto(BASE + '/petmind/', wait_until='networkidle'); settle()
    R['dog_default'] = pg.evaluate(STATE)
    pg.screenshot(path=os.path.join(SH, f'D3_pet_dog_{TAG}.jpg'), type='jpeg', quality=60, full_page=True)
    pg.click('#who .chip[data-w=cat]'); settle()
    R['cat_mode'] = pg.evaluate(STATE)
    pg.screenshot(path=os.path.join(SH, f'D3_pet_cat_{TAG}.jpg'), type='jpeg', quality=60, full_page=True)
    # 고양이 8종 하나씩
    per = []
    for i in range(8):
        chips = pg.query_selector_all('#probs .chip')
        if i >= len(chips): break
        chips[i].click(); settle(); per.append(pg.evaluate(STATE))
    R['cat_each'] = [{'hash': x['hash'], 'title': x['fixTitle'], 'steps': x['steps'], 'dog': x['dogImgs'], 'cat': x['catImgs']} for x in per]
    R['cat_all_unique'] = len(set(sum([[s for s in pg.evaluate("window.__PET && window.__PET.FIX_CAT ? Object.values(window.__PET.FIX_CAT).flatMap(f => f.img) : []")]], [])))
    # 해시 복원: #cat/groom 새로고침
    pg.goto(BASE + '/petmind/#cat/groom', wait_until='networkidle'); settle()
    R['reload_cat_groom'] = pg.evaluate(STATE)
    pg.screenshot(path=os.path.join(SH, f'D3_pet_catgroom_{TAG}.jpg'), type='jpeg', quality=60)
    pg.reload(wait_until='networkidle'); settle()
    R['reload_again'] = {k: v for k, v in pg.evaluate(STATE).items() if k in ('hash', 'chipOn', 'fixTitle', 'dogImgs')}
    # 예전 주소 #bark → 강아지 판
    pg.goto(BASE + '/petmind/#bark', wait_until='networkidle'); settle()
    R['legacy_bark'] = {k: v for k, v in pg.evaluate(STATE).items() if k in ('hash', 'chipOn', 'fixTitle')}
    # 뒤로가기: #dog/sep → #cat/night 로 이동 후 back
    pg.goto(BASE + '/petmind/#dog/sep', wait_until='networkidle'); settle()
    pg.evaluate("location.hash = '#cat/night'"); settle()
    R['hash_nav'] = {k: v for k, v in pg.evaluate(STATE).items() if k in ('hash', 'chipOn', 'fixTitle')}
    pg.go_back(); settle()
    R['back'] = {k: v for k, v in pg.evaluate(STATE).items() if k in ('hash', 'chipOn', 'fixTitle')}
    R['disc'] = pg.evaluate("(document.querySelector('.disc')||{}).textContent")
    R['title'] = pg.evaluate("document.querySelector('h1').textContent")
    R['errs'] = errs
    b.close()
print(json.dumps(R, ensure_ascii=False, indent=1))

"""162 확인 — 기업 대출·창업·세무 두 엔진 실행 + 탭 양방향 이동. usage: python loan_tax_test.py BASE OUTDIR"""
import json, sys
from playwright.sync_api import sync_playwright
BASE, OUT = sys.argv[1].rstrip('/'), sys.argv[2]
r = {}; errs = []; bad = []
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers='block')
    pg = ctx.new_page()
    pg.on('pageerror', lambda e: errs.append(str(e))); pg.on('console', lambda m: m.type == 'error' and errs.append(m.text))
    pg.on('response', lambda x: x.status >= 400 and bad.append(x.url))
    pg.goto(f'{BASE}/loan.html', wait_until='load'); pg.wait_for_timeout(1500)
    r['loan_tabOn'] = pg.evaluate("document.querySelector('.bizTabs a.on').textContent")
    pg.evaluate("document.querySelector('#btnDemo').click()"); pg.wait_for_timeout(500)
    pg.evaluate("document.querySelector('#btnRun').click()"); pg.wait_for_timeout(1500)
    r['loan_result'] = pg.evaluate("""(()=>{const b=document.querySelector('#btnPrint');const box=b&&b.closest('section,div');
       return {printVisible: !!(b && b.offsetParent), text: (document.body.innerText.match(/(소진공|신보|중진공|기보|시중은행)/g)||[]).length,
               ratio: /부채비율/.test(document.body.innerText)};})()""")
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(200)
    pg.screenshot(path=f'{OUT}/after_loan_tabs.png')
    pg.screenshot(path=f'{OUT}/after_loan_result.png', full_page=True)
    pg.click('.bizTabs a[data-bt="tax"]'); pg.wait_for_load_state('load'); pg.wait_for_timeout(1500)
    r['to_tax_url'] = pg.url.replace(BASE, ''); r['tax_tabOn'] = pg.evaluate("document.querySelector('.bizTabs a.on').textContent")
    pg.evaluate("document.querySelector('#btnRun').click()"); pg.wait_for_timeout(1500)
    r['tax_result'] = pg.evaluate("""({outVisible: getComputedStyle(document.querySelector('#outBox')).display!=='none',
       len: document.querySelector('#outBox').innerText.length})""")
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(200)
    pg.screenshot(path=f'{OUT}/after_tax_tabs.png')
    pg.screenshot(path=f'{OUT}/after_tax_result.png', full_page=True)
    pg.click('.bizTabs a[data-bt="loan"]'); pg.wait_for_load_state('load'); pg.wait_for_timeout(800)
    r['back_to_loan_url'] = pg.url.replace(BASE, '')
    r['sw'] = pg.evaluate('document.documentElement.scrollWidth')
    br.close()
r['errors'] = errs; r['http4xx'] = bad
print(json.dumps(r, ensure_ascii=False, indent=1))

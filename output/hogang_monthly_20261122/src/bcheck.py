# B-1~B-5 · E-8 · E-5 · E-6 검사 + 펼침 캡처
import json, sys, os, re
from playwright.sync_api import sync_playwright
URL = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8791/hogang/'
MODEL = sys.argv[2] if len(sys.argv) > 2 else 's25'
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, '..')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
r = {}
errs = []
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = b.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True)
    pg = ctx.new_page()
    pg.on('pageerror', lambda e: errs.append('pageerror: ' + str(e)))
    pg.on('console', lambda m: errs.append('console.error: ' + m.text) if m.type == 'error' else None)
    pg.goto(URL, wait_until='networkidle'); pg.wait_for_function('window.__HOGANG')
    r['initialModel'] = pg.evaluate("document.querySelector('#iModel').selectedOptions[0].textContent")
    r['initialBest'] = pg.evaluate("JSON.parse(JSON.stringify(window.__HOGANG.best))")
    r['initialInput'] = pg.evaluate("window.__HOGANG.input")
    ids = pg.evaluate("fetch('data/models.json').then(r=>r.json()).then(d=>d.models.map(m=>m.id))")
    mi = ids.index(MODEL)
    pg.evaluate("""(mi)=>{const sel=(s,v)=>{const e=document.querySelector(s);e.value=String(v);e.dispatchEvent(new Event('change'));};
      sel('#iModel',mi);sel('#iPlan',2);sel('#iLeft',0);sel('#iCombo','none');sel('#iWay','chg');sel('#iData',100);}""", mi)
    h = pg.evaluate('JSON.parse(JSON.stringify(window.__HOGANG))')
    r['H'] = h
    r['B1_open'] = pg.evaluate("document.querySelector('#yr24').open")
    txt = pg.evaluate('document.body.innerText')
    tots = [f"{x['total']:,}" for x in h['routes']]
    r['B2'] = {'has2yr': '2년 총액' in txt, 'has24base': '24개월 기준' in txt, 'totalsFound': [t for t in tots if t in txt], 'saveFound': f"{h['save']:,}" in txt}
    r['E6_fn'] = pg.evaluate("[...document.querySelectorAll('.fn')].filter(f=>f.offsetParent).map(f=>f.innerText).filter(t=>t.includes('기준 예시값'))")
    r['E6_live'] = bool(re.search('실시간 공시|실시간 지원금', txt))
    r['E8'] = pg.evaluate("""()=>{const s=document.querySelector('#yr24 summary').getBoundingClientRect();
       return {sw:document.documentElement.scrollWidth, sum:[s.left,s.right,s.height], tbl:[...document.querySelectorAll('table')].filter(t=>t.offsetParent).map(t=>[t.id,t.scrollWidth,t.clientWidth])}}""")
    pg.evaluate("document.querySelector('#yr24').scrollIntoView({block:'start'})")
    pg.click('#yr24 summary')
    pg.wait_for_timeout(200)
    r['B3_open'] = pg.evaluate("document.querySelector('#yr24').open")
    t2 = pg.evaluate("document.querySelector('#yr24').innerText")
    r['B3_text'] = t2
    r['B3'] = {'totals': [t for t in tots if t in t2], 'diff1': '1등보다' in t2, 'chk': '× 24 =' in t2, 'save2y': f"{h['save']:,}" in t2}
    r['E8_open'] = pg.evaluate("[document.documentElement.scrollWidth,...[...document.querySelectorAll('#yr24 table')].map(t=>t.scrollWidth+'/'+t.clientWidth)]")
    pg.evaluate("window.scrollBy(0,-60)")
    pg.screenshot(path=os.path.join(OUT, 'shots', 'after_yr24_open_390.png'))
    pg.screenshot(path=os.path.join(OUT, 'shots', 'after_yr24_open_full.png'), full_page=True)
    # 위약금 잔여 12 펼친 상태
    pg.evaluate("(()=>{const e=document.querySelector('#iLeft');e.value='12';e.dispatchEvent(new Event('change'));})()")
    r['B3_pen12'] = pg.evaluate("document.querySelector('#yr24Body .graybox').innerText")
    r['B3_pen12_stillOpen'] = pg.evaluate("document.querySelector('#yr24').open")
    pg.evaluate("(()=>{const e=document.querySelector('#iLeft');e.value='0';e.dispatchEvent(new Event('change'));})()")
    pg.click('#yr24 summary'); pg.wait_for_timeout(150)
    r['B4_closed'] = pg.evaluate("document.querySelector('#yr24').open") is False
    h = pg.evaluate('JSON.parse(JSON.stringify(window.__HOGANG))')
    m24 = [round(x['total'] / 24) for x in h['routes']]  # JS Math.round와 .5 처리 차 확인용
    cards = pg.evaluate("[...document.querySelectorAll('#cmp tbody tr')].map(r=>r.cells[1].innerText)")
    mine = [x for x in h['routes'] if x['way'] == 'chg'][0]
    saveM = pg.evaluate("document.querySelector('#t1Save').innerText")
    sm = int(re.sub(r'\D', '', saveM.split('매달')[1]))
    r['B5'] = {'cmpMonthly': cards, 'rows': [[x['way'], int(re.sub(r'\D', '', c)), x['total'], abs(int(re.sub(r'\D', '', c)) * 24 - x['total'])] for x, c in zip(h['routes'], cards)],
               'saveM': sm, 'save2y': h['save'], 'saveErr': abs(sm * 24 - h['save'])}
    # E-5 운영자 시트
    pg.click('#btnOp'); r['E5_open'] = pg.evaluate("document.querySelector('#opSheet').classList.contains('on')")
    pg.fill('#opLink', 'https://example.com/p?partnerId=TEST'); pg.click('#opSave')
    r['E5_saved'] = pg.evaluate("[localStorage.getItem('kts_ajd_link'), document.querySelector('#btnAjd').href]")
    pg.click('#btnOp'); pg.click('#opClear')
    r['E5_cleared'] = pg.evaluate("localStorage.getItem('kts_ajd_link')")
    pg.click('#opClose')
    r['errors'] = errs
    b.close()
json.dump(r, open(os.path.join(OUT, 'data', 'bcheck_' + MODEL + '.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
for k, v in r.items():
    if k in ('H', 'B3_text'): continue
    print(k, json.dumps(v, ensure_ascii=False)[:600])

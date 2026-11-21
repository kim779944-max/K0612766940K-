# 호갱 탈출 내비 측정기 — 같은 조건에서 __HOGANG·화면 텍스트·캡처·콘솔 오류를 모은다
# 사용: py -3.12 -P -X utf8 probe.py <phase:before|after> <url>
import json, sys, os, itertools
from playwright.sync_api import sync_playwright

PHASE = sys.argv[1]
URL = sys.argv[2] if len(sys.argv) > 2 else 'http://127.0.0.1:8791/hogang/'
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..')
SHOTS = os.path.join(OUT, 'shots')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

SET = """(o)=>{const ids=[...document.querySelectorAll('#iModel option')];
 const mi=window.__MIDX?window.__MIDX(o.model):-1;
 const sel=(s,v)=>{const e=document.querySelector(s);e.value=String(v);e.dispatchEvent(new Event('change'));};
 sel('#iModel',mi); sel('#iPlan',o.plan); sel('#iLeft',o.left); sel('#iCombo',o.combo); sel('#iWay',o.way); sel('#iData',o.data);
 return JSON.parse(JSON.stringify(window.__HOGANG));}"""

# 모델 id → 옵션 인덱스 (models.json 순서가 바뀌어도 같은 기종으로 비교)
MIDX = """()=>{window.__MIDX=(id)=>{const names=[...document.querySelectorAll('#iModel option')].map(o=>o.textContent);
 return window.__MODELIDS.indexOf(id);};}"""

def main():
    errs = []
    res = {'phase': PHASE}
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=CHROME, headless=True)
        ctx = b.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True)
        pg = ctx.new_page()
        pg.on('pageerror', lambda e: errs.append('pageerror: ' + str(e)))
        pg.on('console', lambda m: errs.append('console.' + m.type + ': ' + m.text) if m.type == 'error' else None)
        pg.goto(URL, wait_until='networkidle')
        pg.wait_for_function('window.__HOGANG')
        ids = pg.evaluate("fetch('data/models.json').then(r=>r.json()).then(d=>d.models.map(m=>m.id))")
        pg.evaluate("(ids)=>{window.__MODELIDS=ids;}", ids)
        pg.evaluate(MIDX)
        res['modelIds'] = ids
        res['initial'] = pg.evaluate('JSON.parse(JSON.stringify(window.__HOGANG))')
        res['initialModelName'] = pg.evaluate("document.querySelector('#iModel').selectedOptions[0].textContent")

        base = dict(model='s25', plan=2, left=0, combo='none', way='chg', data=100)
        res['s25'] = pg.evaluate(SET, base)
        pg.evaluate('window.scrollTo(0,0)')
        pg.wait_for_timeout(300)
        res['text_s25'] = pg.evaluate('document.body.innerText')
        res['scrollWidth'] = pg.evaluate('document.documentElement.scrollWidth')
        res['dom'] = pg.evaluate("""()=>({t1Big:document.querySelector('#t1Big').innerText,t1Save:document.querySelector('#t1Save').innerText,
          t1Route:document.querySelector('#t1Route').innerText,
          ids:['t1Route','t1Big','t1Dev','t1Mon','t1Save','t1How'].map(i=>[i,!!document.getElementById(i)]),
          cmpHead:[...document.querySelectorAll('#cmp thead th')].map(t=>t.innerText),
          cmpRows:[...document.querySelectorAll('#cmp tbody tr')].map(r=>({best:r.classList.contains('best'),cells:[...r.cells].map(c=>[c.dataset.h,c.innerText])})),
          cands:[...document.querySelectorAll('#cands .cand .amt')].map(a=>a.innerText),
          candsTitle:[...document.querySelectorAll('section.card h2')].map(h=>h.innerText),
          why1:document.querySelector('#why1').innerText,
          calc:document.querySelector('#calcPre').textContent,
          yr24:document.querySelector('#yr24')?{open:document.querySelector('#yr24').open}:null,
          fn:[...document.querySelectorAll('.fn')].map(f=>f.innerText).filter(t=>t.includes('기준')),
          tblOverflow:[...document.querySelectorAll('table')].map(t=>t.scrollWidth>t.clientWidth+1)
        })""")
        sfx = 'before_S25' if PHASE == 'before' else 'after_monthly'
        pg.screenshot(path=os.path.join(SHOTS, sfx + '_390' + ('x844' if PHASE == 'before' else '') + '.png'))
        pg.screenshot(path=os.path.join(SHOTS, sfx + '_full.png'), full_page=True)

        # 약정 잔여 6·12·18
        res['pen'] = {}
        for L in (6, 12, 18):
            h = pg.evaluate(SET, dict(base, left=L))
            res['pen'][L] = {'pen': h['pen'], 'pen3': pg.evaluate("[...document.querySelectorAll('.pen3 div')].map(d=>d.innerText)"),
                             'judge': pg.evaluate("(document.querySelector('#penBody .judge')||{}).innerText")}
        # 로직 회귀 매트릭스 (기존 22종 × 요금제 × 결합 × 방식 × 데이터 × 잔여 일부)
        mat = {}
        old = [i for i in ids if i in ('s25','s25p','s25u','s25e','s25fe','s24fe','s24','flip7','fold7','flip6','a56','a36','a16','ip17','ipair','ip17p','ip17pm','ip16e','ip16','ip16p','ip15','ip13')]
        for m in old:
            for pl, cb, w, d, L in itertools.product(range(5), ('none','net','fam'), ('mnp','chg','self','net'), (5,15,100,9999), (0,12)):
                if (pl + d + L) % 3 and w != 'chg':
                    continue  # 표본 줄이기 (결정적)
                h = pg.evaluate(SET, dict(model=m, plan=pl, left=L, combo=cb, way=w, data=d))
                k = f'{m}|{pl}|{cb}|{w}|{d}|{L}'
                mat[k] = {'routes': [{kk: r[kk] for kk in ('way','dev','mon','total','kind','warn','cond')} for r in h['routes']],
                          'pen': {kk: h['pen'].get(kk) for kk in ('txt','L','be','pen')}, 'save': h['save'], 'best': h['best']}
        res['matrix'] = mat
        res['msMax'] = max(0, *[0])
        # 반응 시간: 6종 입력 하나씩 바꾸며 ms
        pg.evaluate(SET, base)
        ms = []
        for s, v in (('#iModel', 1), ('#iPlan', 3), ('#iLeft', 7), ('#iCombo', 'net'), ('#iWay', 'mnp'), ('#iData', 15)):
            t1 = pg.evaluate("(a)=>{const e=document.querySelector(a[0]);const before=document.querySelector('#t1Big').innerText+document.querySelector('#t1Save').innerText;e.value=String(a[1]);e.dispatchEvent(new Event('change'));return [window.__HOGANG.ms, before!==document.querySelector('#t1Big').innerText+document.querySelector('#t1Save').innerText];}", [s, v])
            ms.append([s] + t1)
        res['reactMs'] = ms
        res['errors'] = errs
        b.close()
    with open(os.path.join(OUT, 'data', PHASE + '_probe.json'), 'w', encoding='utf-8') as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print('matrix', len(res['matrix']), 'errors', len(errs), 'sw', res['scrollWidth'])
    print(json.dumps(res['s25'], ensure_ascii=False))
    print(json.dumps(res['dom'], ensure_ascii=False)[:3000])

main()

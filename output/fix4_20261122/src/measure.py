# 수리 전/후 공통 실측 — python -I measure.py <tag>   (tag = before | after)
import json, sys, os, time
from playwright.sync_api import sync_playwright

TAG = sys.argv[1] if len(sys.argv) > 1 else 'before'
BASE = os.environ.get('FIX4_BASE', 'http://127.0.0.1:8765')
OUT = os.path.join(os.path.dirname(__file__), '..')
SHOTS = os.path.join(OUT, 'shots'); os.makedirs(SHOTS, exist_ok=True)
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
R = {'tag': TAG, 'base': BASE, 'ts': time.strftime('%Y-%m-%d %H:%M:%S')}
ERRS = {}

def shot(page, name, full=False, clip=None):
    p = os.path.join(SHOTS, f'{name}_{TAG}.jpg')
    page.screenshot(path=p, full_page=full, clip=clip, type='jpeg', quality=70)
    return p

def ctx(br, w, h):
    return br.new_context(viewport={'width': w, 'height': h}, device_scale_factor=1, is_mobile=True, has_touch=True,
                          user_agent='Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Mobile Safari/537.36')

def track(page, key):
    ERRS.setdefault(key, [])
    page.on('pageerror', lambda e: ERRS[key].append(str(e)[:200]))

SHOW_JS = """(() => {
  const go = [...document.querySelectorAll('.rows .go')].map(b => Math.round(b.getBoundingClientRect().right));
  return { innerW: innerWidth, docW: document.documentElement.scrollWidth,
           maxGoRight: Math.max(...go), goCount: go.length,
           rowsW: [...document.querySelectorAll('.rows')].map(r => Math.round(r.getBoundingClientRect().width)),
           rowCounts: [...document.querySelectorAll('.rows')].map(r => r.querySelectorAll('.row').length) };
})()"""

with sync_playwright() as pw:
    br = pw.chromium.launch(executable_path=CHROME, headless=True)
    for (w, h) in [(390, 844), (360, 800)]:
        k = f'{w}'
        # ── 쇼룸 ──
        c = ctx(br, w, h); pg = c.new_page(); track(pg, f'show_{k}')
        pg.goto(BASE + '/', wait_until='networkidle'); pg.wait_for_timeout(800)
        m = pg.evaluate(SHOW_JS)
        # 04 섹션 찾기
        sec = pg.evaluate("""(() => { const hs=[...document.querySelectorAll('.secH')];
          const h = hs.find(x => /04/.test(x.textContent)); if(!h) return null;
          h.scrollIntoView(); const r=h.parentElement.getBoundingClientRect(); return {y: r.top + scrollY, h: r.height, t: h.textContent.trim().slice(0,30)}; })()""")
        m['sec04'] = sec
        if sec:
            pg.evaluate(f"window.scrollTo(0,{max(0, sec['y']-10)})"); pg.wait_for_timeout(300)
            shot(pg, f'C1_show04_{k}')
        pg.evaluate("window.scrollTo(0, document.documentElement.scrollHeight)"); pg.wait_for_timeout(700)
        m['bottom'] = pg.evaluate("""(() => { const go=[...document.querySelectorAll('.rows .go')]; const last=go[go.length-1];
           const t=document.getElementById('toTop'); const a=last.getBoundingClientRect(), b=t.getBoundingClientRect();
           return {lastGoBottom: Math.round(a.bottom), lastGoRight: Math.round(a.right), toTopTop: Math.round(b.top), toTopLeft: Math.round(b.left),
                   toTopOn: t.classList.contains('on'), lastName: last.closest('.row') && last.closest('.row').querySelector('.nm') ? last.closest('.row').querySelector('.nm').textContent.trim() : ''}; })()""")
        shot(pg, f'C2_showBottom_{k}')
        m['adRow'] = pg.evaluate("""(() => { const a=[...document.querySelectorAll('.row')].find(r => /ad_magnet/.test(r.innerHTML)); if(!a) return null;
           a.scrollIntoView({block:'center'}); const r=a.getBoundingClientRect(); return {h: Math.round(r.height), txt: a.innerText.replace(/\\s+/g,' ').slice(0,80)}; })()""")
        pg.wait_for_timeout(200); shot(pg, f'E1_showAdRow_{k}')
        R[f'show_{k}'] = m
        R[f'show_full_{k}'] = shot(pg, f'C0_showFull_{k}', full=True)
        c.close()

        # ── 독심술 ──
        c = ctx(br, w, h); pg = c.new_page(); track(pg, f'navi_{k}')
        pg.goto(BASE + '/navi2/', wait_until='networkidle'); pg.wait_for_timeout(800)
        g = pg.evaluate("""(() => { const g=document.getElementById('gal16'); const p=g.querySelector('.pic'); const cap=p.querySelector('.cap');
          const cs=getComputedStyle(g), cc=getComputedStyle(cap);
          const caps=[...g.querySelectorAll('.cap')]; const clipped=caps.filter(c => c.scrollHeight > c.clientHeight + 1 || c.scrollWidth > c.clientWidth + 1).map(c=>c.textContent);
          return { cols: cs.gridTemplateColumns.split(' ').length, gap: cs.columnGap, tileW: Math.round(p.getBoundingClientRect().width*10)/10,
                   capFont: cc.fontSize, capH: cc.height, lineH: cc.lineHeight, clipped, docW: document.documentElement.scrollWidth, innerW: innerWidth }; })()""")
        R[f'navi_gal_{k}'] = g
        pg.evaluate("document.getElementById('gal16').scrollIntoView()"); pg.wait_for_timeout(500)
        shot(pg, f'B1_gal16_{k}')
        shot(pg, f'B2_gal16full_{k}', full=True)
        # 그림 2장 고르고 시작
        pics = pg.query_selector_all('#gal16 .pic')
        pics[1].click(); pics[9].click()
        pg.click('#btnStart'); pg.wait_for_timeout(700)
        qs = []
        for lv in range(1, 11):
            pg.wait_for_function("document.getElementById('pnum').textContent.trim().indexOf('%d /') === 0" % lv, timeout=8000)
            pg.wait_for_timeout(150)
            try:
                pg.wait_for_function("[...document.querySelectorAll('#ogrid .opt img')].every(i => i.complete)", timeout=8000)
            except Exception:
                pass
            info = pg.evaluate("""(() => ({ q: document.getElementById('qtxt').textContent,
              cards: document.querySelectorAll('#ogrid .opt').length,
              imgs: document.querySelectorAll('#ogrid .opt img').length,
              broken: [...document.querySelectorAll('#ogrid .opt img')].filter(i => !i.complete || i.naturalWidth === 0).length,
              srcs: [...document.querySelectorAll('#ogrid .opt img')].map(i => i.getAttribute('src')),
              firstRowVisible: [...document.querySelectorAll('#ogrid .opt')].slice(0,2).map(o => Math.round(o.getBoundingClientRect().bottom)),
              overlap: [...document.querySelectorAll('#ogrid .opt')].map(o => { const n=o.querySelector('.no').getBoundingClientRect(), t=o.querySelector('.tx b').getBoundingClientRect();
                         return (n.bottom > t.top && n.right > t.left) ? 1 : 0; }).reduce((a,b)=>a+b,0),
              docW: document.documentElement.scrollWidth }))()""")
            info['lv'] = lv
            qs.append(info)
            if lv in (1, 5, 10):
                shot(pg, f'A2_quizL{lv}_{k}')
            pg.click('#ogrid .opt:nth-child(%d)' % (1 + (lv % 4)))
        R[f'navi_quiz_{k}'] = qs
        pg.wait_for_timeout(4500)
        try:
            pg.wait_for_selector('#sResult.on', timeout=15000)
            if pg.query_selector('#btnReveal') and pg.is_visible('#btnReveal'):
                pg.click('#btnReveal'); pg.wait_for_timeout(600)
            res = pg.evaluate("""(() => { const b=document.getElementById('resBody');
              return { secs: [...b.querySelectorAll('.sec[data-part]')].map(s => s.dataset.part).join('>'),
                       startImgs: b.querySelectorAll('img[src*="img/start"]').length, optImgs: b.querySelectorAll('img[src*="img/opts"]').length,
                       seongkyeok: (b.innerText.match(/성격/g)||[]).length }; })()""")
        except Exception as e:
            res = {'err': str(e)[:200]}
        R[f'navi_res_{k}'] = res
        if w == 390:
            R['navi_pool'] = pg.evaluate("""(async () => { const Q = NAVI.Q, list = []; for (const lv in Q) for (const k in Q[lv]) Q[lv][k].opts.forEach(o => list.push(o.img));
              const bad = []; await Promise.all(list.map(src => new Promise(r => { if(!src){bad.push(String(src)); return r();} const im = new Image();
              im.onload = () => { if (!im.naturalWidth) bad.push(src); r(); }; im.onerror = () => { bad.push(src); r(); }; im.src = src; })));
              return { total: list.length, unique: new Set(list.filter(Boolean)).size, bad: bad.length > 10 ? bad.slice(0,3).concat(['…'+bad.length]) : bad }; })()""")
            R['navi_poolStats'] = pg.evaluate("APP && APP.poolStats ? APP.poolStats() : (window.NAVI_APP && NAVI_APP.poolStats ? NAVI_APP.poolStats() : null)")
        c.close()

    br.close()

R['pageerrors'] = ERRS
with open(os.path.join(OUT, f'measure_{TAG}.json'), 'w', encoding='utf-8') as f:
    json.dump(R, f, ensure_ascii=False, indent=1)
print(json.dumps({k: v for k, v in R.items() if not k.startswith('navi_quiz')}, ensure_ascii=False, indent=1)[:6000])
for k in ('navi_quiz_390',):
    print(k, [(q['lv'], q['cards'], q['imgs'], q['broken'], q['overlap']) for q in R.get(k, [])])

# 쇼룸 5대 대문 · 내 메뉴 편집 · 색깔 1·2 · 도우미 · 소개 접힘 — 390x844 실측
# 사용: python -P -X utf8 verify.py <base_url> <shot_dir> [live]
import sys, json, os, time
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
BASE = sys.argv[1].rstrip('/')
SHOT = sys.argv[2]
LIVE = len(sys.argv) > 3
os.makedirs(SHOT, exist_ok=True)
HOST = urlparse(BASE).hostname
R = {}
def log(k, v):
    R[k] = v; print(k, '=', json.dumps(v, ensure_ascii=False))

def ctx_new(br):
    c = br.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True)
    return c

def watch(pg, bag):
    pg.on('console', lambda m: bag['console'].append(m.text + ' @' + str(m.location.get('url',''))) if m.type == 'error' else None)
    pg.on('response', lambda r: bag['console'].append('HTTP%d %s' % (r.status, r.url)) if r.status >= 400 else None)
    pg.on('pageerror', lambda e: bag['pageerror'].append(str(e)))
    pg.on('request', lambda r: bag['hosts'].add(urlparse(r.url).hostname or r.url[:20]))

def url(p):
    return BASE + p + (('?t=%d' % int(time.time())) if LIVE else '')

STATE = r"""(() => {
  const vis = e => !!e && e.getClientRects().length > 0 && getComputedStyle(e).display !== 'none';
  const gates = [...document.querySelectorAll('#gates .gate')].filter(vis);
  const inView = gates.filter(g => { const r = g.getBoundingClientRect(); return r.top >= 0 && r.bottom <= innerHeight; });
  const secs = [...document.querySelectorAll('#sections .sec')];
  const shown = secs.filter(s => !s.hidden && vis(s));
  return {sh: document.documentElement.scrollHeight, gatesVisible: gates.length, gatesInView: inView.length,
    gateCounts: gates.map(g => g.querySelector('.gno').textContent + ':' + g.querySelector('.gc').textContent),
    gateH: gates.map(g => Math.round(g.getBoundingClientRect().height)),
    secsShown: shown.map(s => s.dataset.cat), rowsShown: shown.reduce((n, s) => n + s.querySelectorAll('.row').length, 0),
    rowKs: shown.map(s => [...s.querySelectorAll('.row')].map(r => r.dataset.k).join(',')),
    allRows: document.querySelectorAll('#sections .row').length,
    chips: [...document.querySelectorAll('#catChips button')].map(b => b.textContent),
    gate: document.body.dataset.gate, hash: location.hash};
})()"""

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME)
    bag = {'console': [], 'pageerror': [], 'hosts': set()}
    c = ctx_new(br); pg = c.new_page(); watch(pg, bag)

    # ---------- B. 5대 대문 ----------
    pg.goto(url('/index.html'), wait_until='load'); pg.wait_for_timeout(1500)
    s = pg.evaluate(STATE); log('B_first', s)
    pg.screenshot(path=os.path.join(SHOT, '01_showroom_first.png'))
    pg.click('#gates .gate[data-gate="realty"]'); pg.wait_for_timeout(300)
    s = pg.evaluate(STATE); log('B_realty', s)
    log('B_realty_hidden_flags', pg.evaluate("[...document.querySelectorAll('#sections .sec')].map(s=>s.dataset.cat+':'+s.hidden)"))
    pg.screenshot(path=os.path.join(SHOT, '02_showroom_realty.png'))
    pg.reload(); pg.wait_for_timeout(1000)
    log('B_realty_after_reload', pg.evaluate(STATE)['secsShown'])
    pg.click('#catChips button.back'); pg.wait_for_timeout(300)
    s = pg.evaluate(STATE); log('B_back', {'gatesVisible': s['gatesVisible'], 'gate': s['gate'], 'hash': s['hash']})
    pg.click('#helpBtn2'); pg.wait_for_timeout(400)
    log('B_help_open', pg.evaluate("(()=>{const s=document.querySelector('.edge-sheet');return {on:s.classList.contains('on'),title:s.querySelector('.edge-hd b').textContent,txt:s.querySelector('.edge-bd').innerText.slice(0,80)}})()"))
    pg.screenshot(path=os.path.join(SHOT, '01b_help_sheet.png'))
    pg.click('.edge-sheet [data-edge="close"]'); pg.wait_for_timeout(300)
    s = pg.evaluate(STATE); log('B_help_closed', {'gatesVisible': s['gatesVisible'], 'sheetOn': pg.evaluate("document.querySelector('.edge-sheet').classList.contains('on')")})
    # 다른 도구의 #coupon 링크
    pg.goto(url('/index.html') + '#coupon'); pg.wait_for_timeout(1200)
    log('B_coupon_hash', pg.evaluate("(()=>{const r=document.querySelector('#coupon').getBoundingClientRect();return {visible:r.height>0, top:Math.round(r.top), scrollY:scrollY}})()"))

    # ---------- C. 내 메뉴 편집 ----------
    pg.goto(url('/index.html'), wait_until='load'); pg.wait_for_timeout(1000)
    log('C_saved_before', pg.evaluate("localStorage.getItem('kts_my_menu_v1')"))
    pg.click('#editBtn'); pg.wait_for_timeout(400)
    log('C_panel', pg.evaluate("(()=>{const p=document.querySelector('.edge-pn');const r=p.getBoundingClientRect();return {on:p.classList.contains('on'),w:Math.round(r.width),right:Math.round(r.right),items:p.querySelectorAll('.edge-li').length}})()"))
    pg.screenshot(path=os.path.join(SHOT, '03_edge_edit.png'))
    pg.click('.edge-li[data-k="listing"] [data-edge="out"]'); pg.wait_for_timeout(150)
    pg.click('.edge-pn [data-edge="done"]'); pg.wait_for_timeout(400)
    s = pg.evaluate(STATE); log('C_out_listing', {'gate01': s['gateCounts'][0], 'saved': pg.evaluate("localStorage.getItem('kts_my_menu_v1').length")})
    pg.reload(); pg.wait_for_timeout(1000)
    pg.click('#gates .gate[data-gate="realty"]'); pg.wait_for_timeout(300)
    s = pg.evaluate(STATE); log('C_out_after_reload', {'gate': s['secsShown'], 'rows': s['rowKs']})
    pg.click('#catChips [data-edit]'); pg.wait_for_timeout(400)
    pg.click('.edge-pn [data-edge="plus"]'); pg.wait_for_timeout(150)
    pg.screenshot(path=os.path.join(SHOT, '03b_edge_add.png'))
    pg.click('.edge-add [data-k="listing"]'); pg.wait_for_timeout(150)
    log('C_add_panel_last', pg.evaluate("[...document.querySelectorAll('.edge-li')].slice(-1)[0].dataset.k"))
    pg.click('.edge-pn [data-edge="done"]'); pg.wait_for_timeout(400)
    s = pg.evaluate(STATE); log('C_add_listing', {'rows': s['rowKs']})
    pg.click('#catChips button.back'); pg.wait_for_timeout(200)
    log('C_add_gate01', pg.evaluate(STATE)['gateCounts'][0])
    # ▲ 로 더양식을 맨 위로
    pg.click('#editBtn'); pg.wait_for_timeout(400)
    n = 0
    while n < 40 and not pg.evaluate("document.querySelector('.edge-li[data-k=\"theform\"] [data-edge=\"up\"]').disabled"):
        pg.click('.edge-li[data-k="theform"] [data-edge="up"]'); n += 1
    log('C_up_clicks', n)
    log('C_up_first', pg.evaluate("document.querySelector('.edge-li').dataset.k"))
    pg.click('.edge-pn [data-edge="done"]'); pg.wait_for_timeout(300)
    pg.reload(); pg.wait_for_timeout(1000)
    pg.click('#gates .gate[data-gate="doc"]'); pg.wait_for_timeout(300)
    log('C_up_after_reload_doc', pg.evaluate(STATE)['rowKs'])
    # ⠿ 끌어서 순서 바꾸기 (마우스 포인터)
    pg.click('#catChips [data-edit]'); pg.wait_for_timeout(400)
    order0 = pg.evaluate("[...document.querySelectorAll('.edge-li')].slice(0,4).map(l=>l.dataset.k)")
    g = pg.locator('.edge-li').nth(0).locator('.gr').bounding_box()
    pg.mouse.move(g['x'] + g['width'] / 2, g['y'] + g['height'] / 2); pg.mouse.down()
    for i in range(1, 13):
        pg.mouse.move(g['x'] + g['width'] / 2, g['y'] + g['height'] / 2 + i * 11); pg.wait_for_timeout(16)
    pg.mouse.up(); pg.wait_for_timeout(200)
    order1 = pg.evaluate("[...document.querySelectorAll('.edge-li')].slice(0,4).map(l=>l.dataset.k)")
    log('C_drag', {'before': order0, 'after': order1})
    # 처음 상태로 되돌리기
    pg.click('.edge-pn [data-edge="reset"]'); pg.wait_for_timeout(150)
    pg.click('.edge-pn [data-edge="done"]'); pg.wait_for_timeout(300)
    pg.click('#catChips button.back'); pg.wait_for_timeout(200)
    s = pg.evaluate(STATE); log('C_reset', {'allRows': s['allRows'], 'gateCounts': s['gateCounts'], 'saved': pg.evaluate("localStorage.getItem('kts_my_menu_v1')")})
    # 한 구역 전부 빼기 → '—'
    pg.click('#editBtn'); pg.wait_for_timeout(300)
    for k in ['append', 'youtube', 'travel']:
        pg.click('.edge-li[data-k="%s"] [data-edge="out"]' % k); pg.wait_for_timeout(60)
    pg.click('.edge-pn [data-edge="done"]'); pg.wait_for_timeout(300)
    log('C_empty_group', pg.evaluate(STATE)['gateCounts'][4])
    pg.click('#gates .gate[data-gate="soon"]'); pg.wait_for_timeout(200)
    log('C_empty_group_msg', pg.evaluate("document.querySelector('#sec05 .empty') ? document.querySelector('#sec05 .empty').innerText.slice(0,30) : null"))
    pg.evaluate("localStorage.removeItem('kts_my_menu_v1')")

    # ---------- A. 색깔 1·2 ----------
    for path in ['/index.html', '/listing/index.html', '/listing/build.html']:
        pg.goto(url(path), wait_until='load'); pg.wait_for_timeout(800)
        pg.click('[data-kts-theme-set="light"]'); pg.wait_for_timeout(200)
        pg.reload(); pg.wait_for_timeout(800)
        a = pg.evaluate("({theme:document.documentElement.dataset.ktsTheme, ls:localStorage.getItem('kts_theme'), bg:getComputedStyle(document.body).backgroundColor, pressed:[...document.querySelectorAll('[data-kts-theme-set]')].map(b=>b.dataset.ktsThemeSet+':'+b.getAttribute('aria-pressed')), keys:Object.keys(localStorage).filter(k=>/theme/i.test(k))})")
        if path == '/index.html':
            pg.screenshot(path=os.path.join(SHOT, '04_color2.png'))
        pg.click('[data-kts-theme-set="dark"]'); pg.wait_for_timeout(200)
        pg.reload(); pg.wait_for_timeout(800)
        b = pg.evaluate("({theme:document.documentElement.dataset.ktsTheme, ls:localStorage.getItem('kts_theme'), bg:getComputedStyle(document.body).backgroundColor})")
        log('A_' + path, {'color2_after_reload': a, 'color1_after_reload': b})
    # 인쇄(매물장) — 화면은 색깔 1(다크) 상태에서
    pg.goto(url('/listing/index.html'), wait_until='load'); pg.wait_for_timeout(1500)
    pg.emulate_media(media='print'); pg.wait_for_timeout(300)
    log('A_print_listing', pg.evaluate("({bodyBg:getComputedStyle(document.body).backgroundColor, theme2:getComputedStyle(document.querySelector('.k-theme2')).display, bar:getComputedStyle(document.querySelector('#bar')).display})"))
    pg.screenshot(path=os.path.join(SHOT, '05_print.png'), full_page=False)
    pg.emulate_media(media='screen')
    pg.goto(url('/index.html'), wait_until='load'); pg.wait_for_timeout(800)
    pg.emulate_media(media='print'); pg.wait_for_timeout(200)
    log('A_print_index', pg.evaluate("({bodyBg:getComputedStyle(document.body).backgroundColor, theme2:getComputedStyle(document.querySelector('.k-theme2')).display})"))
    pg.emulate_media(media='screen')

    # ---------- D. 도우미 위치 ----------
    for path, nm in [('/index.html', '06_helper_pos_showroom.png'), ('/theform/index.html', '06_helper_pos_theform.png')]:
        pg.goto(url(path), wait_until='load'); pg.wait_for_timeout(3600)
        log('D_pos_' + path, pg.evaluate("(()=>{const b=document.querySelector('#kts-helper-btn').getBoundingClientRect();return [Math.round(b.left),Math.round(b.top),Math.round(b.width),Math.round(b.height)]})()"))
        pg.screenshot(path=os.path.join(SHOT, nm))
    # 흐림: 스크롤 0.8초 이상
    pg.goto(url('/theform/index.html'), wait_until='load'); pg.wait_for_timeout(1000)
    for i in range(12):
        pg.mouse.wheel(0, 120); pg.wait_for_timeout(100)
    log('D_dim_scrolling', pg.evaluate("getComputedStyle(document.querySelector('#kts-helper-btn')).opacity"))
    pg.wait_for_timeout(900)
    log('D_dim_after_stop', pg.evaluate("getComputedStyle(document.querySelector('#kts-helper-btn')).opacity"))
    pg.goto(url('/contract/index.html'), wait_until='load'); pg.wait_for_timeout(1000)
    pg.evaluate("(()=>{const e=[...document.querySelectorAll('input:not([type=file]),textarea')].find(x=>x.getClientRects().length);if(e)e.focus();})()"); pg.wait_for_timeout(200)
    a1 = pg.evaluate("[document.activeElement.tagName+'#'+document.activeElement.id, getComputedStyle(document.querySelector('#kts-helper-btn')).opacity]")
    pg.evaluate("document.activeElement.blur()"); pg.wait_for_timeout(200)
    log('D_dim_focus', {'focused': a1, 'blurred': pg.evaluate("getComputedStyle(document.querySelector('#kts-helper-btn')).opacity")})
    # 저장값 존중
    pg.evaluate("localStorage.setItem('kts_helper_pos_v1', JSON.stringify({side:'left',y:600,r:600/844}))")
    pg.reload(); pg.wait_for_timeout(1500)
    log('D_saved_pos', pg.evaluate("(()=>{const b=document.querySelector('#kts-helper-btn').getBoundingClientRect();return [Math.round(b.left),Math.round(b.top)]})()"))
    pg.evaluate("localStorage.removeItem('kts_helper_pos_v1')")
    c.close()

    # ---------- B. 소개 처음 1회만 펼침 ----------
    for tool, path in [('theform', '/theform/index.html'), ('sign', '/sign/index.html')]:
        c = ctx_new(br); pg = c.new_page(); watch(pg, bag)
        pg.goto(url(path), wait_until='load'); pg.wait_for_timeout(500)
        H = "(()=>{const e=document.querySelector('[data-kts-intro]');return {c:e.classList.contains('kts-intro-c'),h:Math.round(e.getBoundingClientRect().height),seen:localStorage.getItem('kts_tool_intro_seen_%s')}})()" % tool
        a = pg.evaluate(H)
        pg.screenshot(path=os.path.join(SHOT, '07_intro_%s_first.png' % tool))
        pg.wait_for_timeout(3000)
        b = pg.evaluate(H)
        pg.screenshot(path=os.path.join(SHOT, '07_intro_%s_folded.png' % tool))
        pg.reload(); pg.wait_for_timeout(400)
        cc = pg.evaluate(H)
        pg.click('[data-kts-intro]'); pg.wait_for_timeout(150)
        d = pg.evaluate(H)
        log('B_intro_' + tool, {'first_0.5s': a, 'after_3.5s': b, 'reload': cc, 'tap': d})
        c.close()

    # ---------- 회귀: 각 화면 콘솔 에러 · 주요 버튼 1개 ----------
    REG = [('/theform/index.html', '#psSale'), ('/listing/index.html', '#fillBtn'), ('/contract/index.html', '#startBtn'),
           ('/sign/index.html', 'SIGNPAD'), ('/thedetail/index.html', None), ('/navi2/index.html', None),
           ('/sale/index.html', None), ('/slope/index.html', None), ('/listing/build.html', None), ('/index.html', '#gates .gate[data-gate="biz"]')]
    reg = {}
    for path, sel in REG:
        c = ctx_new(br); pg = c.new_page(); b2 = {'console': [], 'pageerror': [], 'hosts': set()}; watch(pg, b2)
        try:
            pg.goto(url(path), wait_until='load', timeout=30000); pg.wait_for_timeout(2500)
            clicked = None
            if sel == 'SIGNPAD':
                bb = pg.locator('#cv').bounding_box(); pg.mouse.move(bb['x']+40, bb['y']+60); pg.mouse.down()
                for i in range(20): pg.mouse.move(bb['x']+40+i*9, bb['y']+60+(i%5)*8); pg.wait_for_timeout(10)
                pg.mouse.up(); pg.wait_for_timeout(300)
                clicked = {'signpad_ink_px': pg.evaluate("(()=>{const c=document.querySelector('#cv'),x=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let n=0;for(let i=3;i<x.length;i+=4)if(x[i]>0)n++;return n})()"),
                           'placeholder_hidden': pg.evaluate("getComputedStyle(document.querySelector('#padPh')).display==='none'||getComputedStyle(document.querySelector('#padPh')).opacity==='0'||document.querySelector('#padPh').hidden")}
            elif sel and pg.locator(sel).count():
                pg.locator(sel).first.click(timeout=5000); pg.wait_for_timeout(800); clicked = sel
            reg[path] = {'console_err': b2['console'][:5], 'pageerror': b2['pageerror'][:5], 'clicked': clicked,
                         'ext_hosts': sorted(h for h in b2['hosts'] if h and h != HOST)}
        except Exception as e:
            reg[path] = {'fail': str(e)[:200]}
        bag['hosts'] |= b2['hosts']
        c.close()
    log('REG', reg)
    log('ALL_errors', {'console': bag['console'][:10], 'pageerror': bag['pageerror'][:10]})
    log('ALL_ext_hosts', sorted(h for h in bag['hosts'] if h and h != HOST))
    br.close()

with open(os.path.join(SHOT, 'verify_%s.json' % ('live' if LIVE else 'local')), 'w', encoding='utf-8') as f:
    json.dump(R, f, ensure_ascii=False, indent=1)

# 세이캡 전체화면 위치 배지 실측 — python saycap_test.py <tag> <base>
import json, sys, os
from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright
TAG = sys.argv[1]; BASE = sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, '..'); SH = os.path.join(OUT, 'shots'); DL = os.path.join(OUT, 'dl')
GEO = os.path.join(DL, 'sc_geo.jpg'); NOGEO = os.path.join(DL, 'sc_nogeo.jpg')
if not os.path.exists(GEO):
    for path, col, gps in ((GEO, (70, 120, 170), True), (NOGEO, (150, 110, 70), False)):
        im = Image.new('RGB', (1200, 1600), col); d = ImageDraw.Draw(im)
        for i in range(0, 1600, 80): d.line([(0, i), (1200, i + 300)], fill=(255, 255, 255), width=6)
        ex = Image.Exif(); ex[0x0132] = '2026:11:20 10:30:00'
        ifd = ex.get_ifd(0x8769); ifd[0x9003] = '2026:11:20 10:30:00'
        if gps:
            g = ex.get_ifd(0x8825)
            g[1] = 'N'; g[2] = (37.0, 30.0, 3.6); g[3] = 'E'; g[4] = (127.0, 1.0, 40.08)   # 37.501 N, 127.0278 E (서울 강남)
        im.save(path, 'JPEG', quality=85, exif=ex)
VIS = """(() => { const l = document.getElementById('viewLoc'), t = document.getElementById('viewTop'), ch = document.getElementById('viewChip');
  const cs = getComputedStyle(l), r = l.getBoundingClientRect();
  const shown = cs.display !== 'none' && parseFloat(cs.opacity) > 0.01 && cs.visibility !== 'hidden' && r.width > 0;
  return { locDisplay: cs.display, locOpacity: cs.opacity, locPE: cs.pointerEvents, locRect: [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)],
           locVisible: shown, locText: l.innerText.trim(), topOpacity: getComputedStyle(t).opacity,
           chipText: ch.innerText.replace(/\\s+/g, ' ').trim(),
           chipPlaceShown: getComputedStyle(ch.querySelector('.p')).display !== 'none' }; })()"""
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    c = b.new_context(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
    c.route('**/nominatim.openstreetmap.org/**', lambda r: r.fulfill(status=200, content_type='application/json',
            body=json.dumps({'display_name': '서울특별시 강남구 역삼동 823', 'address': {'city': '서울특별시', 'borough': '강남구', 'quarter': '역삼동', 'road': '테헤란로'}})))
    pg = c.new_page(); errs = []; pg.on('pageerror', lambda e: errs.append(str(e)[:200]))
    pg.goto(BASE + '/saycap/', wait_until='networkidle'); pg.wait_for_timeout(1200)
    pg.set_input_files('#filePick', [GEO, NOGEO]); pg.wait_for_timeout(2500)
    R = {}
    ids = pg.evaluate("""(async () => { const req = indexedDB.open ? null : null; return [...document.querySelectorAll('[data-id]')].map(a => a.dataset.id); })()""")
    R['ids'] = ids[:6]
    def open_by_name(name):
        return pg.evaluate("""(async (nm) => { const arts = [...document.querySelectorAll('[data-id]')];
            for (const a of arts) { a.click(); await new Promise(z => setTimeout(z, 900));
              const v = document.getElementById('viewer'); if (v && v.classList.contains('on')) return true; }
            return false; })""", name)
    # 갤러리 첫 카드 열기
    show = pg.evaluate("typeof show")
    opened = pg.evaluate("""(async () => { const ids = [...document.querySelectorAll('[data-id]')].map(a => a.dataset.id);
        for (const id of ids) { try { await openViewer(id); } catch (e) { return 'err ' + e; } await new Promise(z => setTimeout(z, 800));
          return id; } return null; })()""")
    R['opened'] = opened
    # 사진 2장 각각 상태
    states = []
    for i in range(2):
        pg.wait_for_timeout(700)
        st = pg.evaluate(VIS); st['count'] = pg.evaluate("document.getElementById('viewCount').textContent")
        st['geo'] = pg.evaluate("(() => { const p = viewerList[viewIndex]; return !!(p && (p.geo || p.exifGeo)); })()")
        if st['geo']:
            R['geo_ui_on'] = st
            pg.screenshot(path=os.path.join(SH, f'F2_saycap_ui_on_{TAG}.jpg'), type='jpeg', quality=60)
            pg.evaluate("document.getElementById('viewImg').click()"); pg.wait_for_timeout(700)
            R['geo_ui_off'] = pg.evaluate(VIS)
            pg.screenshot(path=os.path.join(SH, f'F2_saycap_ui_off_{TAG}.jpg'), type='jpeg', quality=60)
            pg.evaluate("document.getElementById('viewImg').click()"); pg.wait_for_timeout(700)
            R['geo_ui_back'] = pg.evaluate(VIS)
            # 지도 시트
            if R['geo_ui_back']['locVisible']:
                pg.click('#viewLoc'); pg.wait_for_timeout(900)
                R['map'] = pg.evaluate("""(() => ({ open: !!document.querySelector('#sheetMap.on, #sheetMap.open, #sheetMap[open]') || getComputedStyle(document.getElementById('sheetMap')).display !== 'none',
                    addr: document.getElementById('mapAddr').innerText.replace(/\\n/g, ' / '), kakao: document.getElementById('mapKakao').href.slice(0, 60), naver: document.getElementById('mapNaver').href.slice(0, 60) }))()""")
                pg.screenshot(path=os.path.join(SH, f'F4_saycap_map_{TAG}.jpg'), type='jpeg', quality=60)
                pg.keyboard.press('Escape'); pg.evaluate("try{closeSheet('sheetMap')}catch(e){}"); pg.wait_for_timeout(500)
        else:
            R['nogeo'] = st
            pg.screenshot(path=os.path.join(SH, f'F5_saycap_nogeo_{TAG}.jpg'), type='jpeg', quality=60)
        states.append(st['count'])
        pg.evaluate("document.getElementById('viewNext').click()"); pg.wait_for_timeout(600)
    R['visited'] = states
    R['errs'] = errs
    b.close()
print(json.dumps(R, ensure_ascii=False, indent=1))

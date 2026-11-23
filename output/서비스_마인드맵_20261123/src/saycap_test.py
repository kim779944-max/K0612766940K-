"""166 확인 — 세이캡 홈 [촬영하기]·[갤러리보기] 두 버튼이 각 화면을 여는지. usage: python saycap_test.py BASE OUTDIR"""
import json, sys
from playwright.sync_api import sync_playwright
BASE, OUT = sys.argv[1].rstrip('/'), sys.argv[2]
r = {}; errs = []
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True,
                           args=["--use-fake-device-for-media-stream", "--use-fake-ui-for-media-stream"])
    for which in ['촬영하기', '갤러리보기']:
        ctx = br.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True,
                             service_workers='block', permissions=['camera', 'microphone'])
        pg = ctx.new_page(); pg.on('pageerror', lambda e: errs.append(str(e)))
        pg.goto(f'{BASE}/saycap/', wait_until='load'); pg.wait_for_timeout(2500)
        before = pg.evaluate("[...document.querySelectorAll('section,.screen,[id^=sc],[id$=Screen]')].filter(e=>e.offsetParent!==null).map(e=>e.id).filter(Boolean)")
        el = pg.locator(f'span:text-is("{which}")').first
        el.evaluate("e => (e.closest('button,a,[onclick],[data-go]')||e).click()")
        pg.wait_for_timeout(1800)
        after = pg.evaluate("[...document.querySelectorAll('section,.screen,[id^=sc],[id$=Screen]')].filter(e=>e.offsetParent!==null).map(e=>e.id).filter(Boolean)")
        txt = pg.evaluate("document.body.innerText.slice(0,0)")
        r[which] = {'visibleBefore': before[:6], 'visibleAfter': after[:6], 'changed': before != after,
                    'galleryText': pg.evaluate("/갤러리/.test([...document.querySelectorAll('*')].filter(e=>e.offsetParent!==null&&e.children.length===0).map(e=>e.textContent).join(' '))")}
        if which == '갤러리보기': pg.screenshot(path=f'{OUT}/after_saycap_gallery.png')
        ctx.close()
    br.close()
r['errors'] = errs
print(json.dumps(r, ensure_ascii=False, indent=1))

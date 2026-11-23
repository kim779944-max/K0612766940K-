import sys
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe")
    for seen in (False, True):
        c = br.new_context(viewport={'width':390,'height':844}, device_scale_factor=2, is_mobile=True, has_touch=True)
        if seen: c.add_init_script("localStorage.setItem('kts_tool_intro_seen_theform','1')")
        pg = c.new_page(); pg.goto(sys.argv[1] + '/theform/index.html'); pg.wait_for_timeout(4500)
        print('seen' if seen else 'first', pg.evaluate("(()=>{const b=document.querySelector('#kts-helper-btn');const r=b.getBoundingClientRect();const q=document.querySelector('.kts-intro-bar button').getBoundingClientRect();return {btn:[Math.round(r.left),Math.round(r.top)],hit:b.dataset.hit,introQ:[Math.round(q.left),Math.round(q.top),Math.round(q.bottom)]}})()"))
        if not seen: pg.screenshot(path=sys.argv[2])
        c.close()
    br.close()

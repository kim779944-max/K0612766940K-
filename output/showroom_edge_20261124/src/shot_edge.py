import sys
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe")
    pg = br.new_page(viewport={'width':390,'height':844}, device_scale_factor=2, is_mobile=True, has_touch=True)
    pg.goto(sys.argv[1] + '/index.html'); pg.wait_for_timeout(1000)
    pg.click('#editBtn'); pg.wait_for_timeout(400)
    print(pg.evaluate("[...document.querySelectorAll('.edge-li')].slice(0,3).map(l=>{const r=l.getBoundingClientRect(),o=l.querySelector('.out').getBoundingClientRect();return [Math.round(r.right),Math.round(o.right),Math.round(r.height)]})"))
    pg.screenshot(path=sys.argv[2])
    br.close()

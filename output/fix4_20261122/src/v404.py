import sys
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
    c=b.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True); pg=c.new_page()
    pg.on('response', lambda r: print(r.status, r.url[:120]) if r.status>=400 else None)
    pg.goto(sys.argv[1]+'/viewer.html',wait_until='networkidle'); pg.wait_for_timeout(1500); b.close()

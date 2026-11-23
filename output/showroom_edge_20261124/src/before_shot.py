import json
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe")
    pg = br.new_page(viewport={'width':390,'height':844}, is_mobile=True, has_touch=True)
    pg.goto('http://127.0.0.1:8791/index.html'); pg.wait_for_timeout(1500)
    print(json.dumps(pg.evaluate("({sh:document.documentElement.scrollHeight, rows:document.querySelectorAll('#sections .row').length, secs:document.querySelectorAll('#sections .sec').length})")))
    pg.screenshot(path='../00_before_showroom_first.png')
    br.close()

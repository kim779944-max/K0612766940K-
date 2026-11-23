from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    pg=br.new_context(viewport={"width":390,"height":844},is_mobile=True,has_touch=True,device_scale_factor=2).new_page()
    pg.goto("http://127.0.0.1:8792/",wait_until="networkidle");pg.wait_for_timeout(800)
    print(pg.evaluate("""[...document.querySelectorAll('.k-theme, #featRows .go, #sections .go, .heroBtns .k-btn')].map(e=>[e.className,e.textContent,Math.round(e.getBoundingClientRect().height)]).filter(x=>x[2]<44)"""))
    print(pg.evaluate("[document.querySelector('.hero').getBoundingClientRect().top, document.querySelector('#nb').className, getComputedStyle(document.querySelector('h1')).fontSize]"))
    pg.wait_for_function("window.KTS_CATALOG && window.KTS_CATALOG.v==='20261123a'")
    print(pg.evaluate("[...document.querySelectorAll('#featRows .row')].map(e=>Math.round(e.getBoundingClientRect().top))"))
    print(pg.evaluate("""[...document.querySelectorAll('.k-theme, #featRows .go, #sections .go, .heroBtns .k-btn')].map(e=>[e.className,e.textContent,e.getBoundingClientRect().height]).filter(x=>x[2]<44)"""))

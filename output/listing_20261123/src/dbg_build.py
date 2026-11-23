from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    c=br.new_context(accept_downloads=True); pg=c.new_page()
    pg.on("console",lambda m: print("console",m.type,m.text[:200])); pg.on("pageerror",lambda e: print("err",e))
    pg.goto("http://127.0.0.1:8793/listing/build.html",wait_until="networkidle"); pg.wait_for_timeout(1500)
    pg.click("#save"); pg.wait_for_timeout(4000); print("toast:",pg.inner_text("#toast"))

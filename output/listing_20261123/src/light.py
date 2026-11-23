from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    c=br.new_context(viewport={"width":390,"height":844},device_scale_factor=1,is_mobile=True,has_touch=True)
    c.add_init_script("localStorage.setItem('kts_theme','light')")
    pg=c.new_page(); pg.goto("http://127.0.0.1:8793/listing/",wait_until="networkidle"); pg.wait_for_timeout(500)
    pg.screenshot(path="after_390_light_full.png",full_page=True)

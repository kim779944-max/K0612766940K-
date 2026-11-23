import json,time
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    pg=br.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True,service_workers="block").new_page()
    errs=[];pg.on("console",lambda m:errs.append(m.text[:120]) if m.type=="error" else None);pg.on("pageerror",lambda e:errs.append(str(e)[:120]))
    pg.goto("https://autooneclick.com/?t=%d"%time.time(),wait_until="networkidle");pg.wait_for_timeout(1500)
    r=pg.evaluate("({sw:document.documentElement.scrollWidth,theme:document.documentElement.getAttribute('data-kts-theme'),cat:(window.KTS_CATALOG||{}).v,feat:[...document.querySelectorAll('#featRows .row')].map(e=>Math.round(e.getBoundingClientRect().bottom)),rows:document.querySelectorAll('#sections .row').length,gagebu:[...document.querySelectorAll('#sections .nm span')].map(e=>e.textContent).filter(t=>t.indexOf('가계부')>=0)})")
    r["errors"]=errs;pg.screenshot(path="live_first_390.png");print(json.dumps(r,ensure_ascii=False))
    json.dump(r,open("live.json","w",encoding="utf-8"),ensure_ascii=False)

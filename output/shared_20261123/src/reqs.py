from playwright.sync_api import sync_playwright
B="http://127.0.0.1:8792/"
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    for path in ["","?master=2899","detail.html?k=gagebu","detail.html?k=listing","realty/","slope/","ecommerce/","thedetail/","gagebu/","loan.html","sale/","hogang/","sign/"]:
        c=br.new_context(viewport={"width":390,"height":844},service_workers="block");pg=c.new_page();bad=[]
        pg.on("response",lambda r:bad.append(str(r.status)+" "+r.url) if r.status>=400 else None)
        pg.on("requestfailed",lambda r:bad.append("FAIL "+r.url[:100]+" "+(r.failure or '')))
        pg.on("console",lambda m:bad.append("console "+m.text[:120]) if m.type=="error" else None)
        try: pg.goto(B+path,wait_until="networkidle",timeout=20000)
        except Exception as e: bad.append("goto "+str(e)[:60])
        pg.wait_for_timeout(1500);print(path or "/",bad);c.close()

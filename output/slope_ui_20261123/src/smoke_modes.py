import json, sys
from playwright.sync_api import sync_playwright
OUT=sys.argv[1]; res={}
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    for w,h in [(390,844),(1280,900)]:
        pg=br.new_page(viewport={"width":w,"height":h}); errs=[]
        pg.on("pageerror",lambda e: errs.append(str(e)[:150])); pg.on("console",lambda m: errs.append(m.text[:150]) if m.type=="error" else None)
        pg.goto("http://127.0.0.1:8791/slope/",wait_until="load"); pg.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'",timeout=40000); pg.wait_for_timeout(2000)
        r={"sw":pg.evaluate("document.documentElement.scrollWidth")}
        pg.click("#vmode button[data-v='3d']"); pg.wait_for_timeout(4000)
        r["3d_on"]=pg.evaluate("document.querySelector('.mapwrap').classList.contains('m3d')")
        pg.click("#vmode button[data-v='arch']"); pg.wait_for_timeout(4000)
        r["arch"]=pg.evaluate("[!document.getElementById('arch').classList.contains('hide'), getComputedStyle(document.getElementById('advBox')).display, getComputedStyle(document.querySelector('.outrow')).display]")
        pg.click("#vmode button[data-v='2d']"); pg.wait_for_timeout(1500)
        r["back2d"]=pg.evaluate("[document.getElementById('arch').classList.contains('hide'), getComputedStyle(document.querySelector('.outrow')).display]")
        if w>1000:
            pg.evaluate("document.getElementById('mapCard').scrollIntoView()"); pg.wait_for_timeout(500)
            pg.locator('#mapCard').screenshot(path=f"{OUT}/after_desktop_mapcard.png")
        r["errors"]=errs; res[w]=r; pg.close()
    br.close()
print(json.dumps(res,ensure_ascii=False))

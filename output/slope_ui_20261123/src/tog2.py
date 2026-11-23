import hashlib, json, sys, time
from playwright.sync_api import sync_playwright
OUT=sys.argv[1]
def mh(pg): pg.wait_for_timeout(500); return hashlib.md5(pg.locator('#mapcv').screenshot()).hexdigest()[:10]
res={}
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    for tag,url,sel in [("new","http://127.0.0.1:8791/slope/","#togs,#togsAdv"),("old_live","https://autooneclick.com/slope/?t=%d"%time.time(),"#togs")]:
        pg=br.new_page(viewport={"width":390,"height":844})
        pg.goto(url,wait_until="load"); pg.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'",timeout=40000); pg.wait_for_timeout(3000)
        r={}
        for view in ["px","arrow"]:
            pg.evaluate(f"document.querySelector('#pxView button[data-v={view}]').click()"); pg.wait_for_timeout(800)
            for k in ["parcel","zone"]:
                q=f"document.querySelector('#togs button[data-l={k}]')||document.querySelector('#togsAdv button[data-l={k}]')"
                h0=mh(pg); pg.evaluate(q+".click()"); pg.wait_for_timeout(5000); h1=mh(pg)
                if tag=="new" and k=="zone" and view=="arrow": pg.locator('#mapcv').screenshot(path=f"{OUT}/toggle_zone_on.png")
                r[view+"_"+k]=h0!=h1
                pg.evaluate(q+".click()"); pg.wait_for_timeout(1500)
        res[tag]=r; pg.close()
    br.close()
print(json.dumps(res))

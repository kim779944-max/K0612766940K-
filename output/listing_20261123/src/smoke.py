import sys, json
from playwright.sync_api import sync_playwright
B=sys.argv[1]; SHOT=sys.argv[2] if len(sys.argv)>2 else None; OUT=sys.argv[3] if len(sys.argv)>3 else None
R={}
import io
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    for path in ["listing/","listing/home.html","listing/build.html","listing/?m=BN-2055","detail.html?k=listing",""]:
        c=br.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True,service_workers="block");pg=c.new_page();bad=[]
        pg.on("response",lambda r:bad.append(str(r.status)+" "+r.url) if r.status>=400 else None)
        pg.on("console",lambda m:bad.append("console "+m.text[:120]) if m.type=="error" else None)
        pg.on("pageerror",lambda e:bad.append("pageerror "+str(e)[:120]))
        pg.goto(B+path,wait_until="networkidle",timeout=30000); pg.wait_for_timeout(1200)
        info={"bad":bad,"sw":pg.evaluate("document.documentElement.scrollWidth")}
        if path=="":
            info["listingCard"]=pg.evaluate("""(()=>{const a=[...document.querySelectorAll('a[href*="k=listing"]')].map(x=>x.closest('.row')).filter(Boolean);return a.map(r=>({text:r.innerText.replace(/s+/g,' | '),soon:r.classList.contains('soon')}))})()""")
            info["catalog"]=pg.evaluate("(window.KTS_CATALOG||{}).v||null")
        if path=="listing/" and SHOT: pg.screenshot(path=SHOT); info["h1"]=pg.evaluate("document.querySelector(\"h1\").textContent"); info["warn"]=pg.evaluate("!!document.getElementById(\"warn\")")
        if path=="detail.html?k=listing" and OUT: pg.screenshot(path=OUT+"/detail_listing.png"); info["title"]=pg.title()
        if path=="" and OUT: pg.screenshot(path=OUT+"/showroom_first_390.png")
        R[path or "/"]=info; c.close()
open(sys.argv[4] if len(sys.argv)>4 else "smoke.json","w",encoding="utf-8").write(json.dumps(R,ensure_ascii=False,indent=1))

from playwright.sync_api import sync_playwright
import collections
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    pg=br.new_context(viewport={"width":390,"height":844}).new_page()
    pg.goto("http://127.0.0.1:8792/",wait_until="networkidle");pg.wait_for_timeout(800)
    r=pg.evaluate("""[...document.querySelectorAll('body *')].filter(e=>e.offsetParent!==null&&[...e.childNodes].some(n=>n.nodeType===3&&n.textContent.trim())).filter(e=>parseFloat(getComputedStyle(e).fontSize)<10.5).map(e=>(e.className||e.tagName)+" "+(e.parentNode.className)+" "+e.textContent.slice(0,20)+' '+getComputedStyle(e).fontSize)""")
    print(collections.Counter(r))

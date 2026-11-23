import sys, json
from playwright.sync_api import sync_playwright
B="http://127.0.0.1:8793/listing/"
JS="""(()=>{const mm=v=>Math.round(v/3.7795*10)/10;const s=document.getElementById('sheet');const t=s.getBoundingClientRect().top;
const q=sel=>{const e=document.querySelector(sel);if(!e)return null;const r=e.getBoundingClientRect();return {top:mm(r.top-t),h:mm(r.height),w:mm(r.width)}};
return {sheet:q('#sheet'),phead:q('.phead'),title:q('.titleblk'),strip:q('.strip'),stats:q('.stats'),warn:q('.warn'),overview:q('.overview'),leases:q('.leases'),points:q('.highlights'),mid:q('.sheet-mid'),broker:q('#broker'),foot:q('.footnote'),bot:q('.sheet-bot')}})()"""
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    c=br.new_context(viewport={"width":718,"height":1047})
    pg=c.new_page(); pg.goto(B+(sys.argv[1] if len(sys.argv)>1 else ""),wait_until="networkidle"); pg.wait_for_timeout(400)
    pg.emulate_media(media="print"); pg.wait_for_timeout(200)
    print(json.dumps(pg.evaluate(JS),ensure_ascii=False,indent=0))

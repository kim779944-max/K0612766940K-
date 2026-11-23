import sys
from playwright.sync_api import sync_playwright
OUT=sys.argv[1]; B="http://127.0.0.1:8793/listing/"
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    c=br.new_context(viewport={"width":390,"height":844},device_scale_factor=2,is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("console",lambda m: errs.append(m.text) if m.type=="error" else None); pg.on("pageerror",lambda e: errs.append(str(e)))
    pg.goto(B+(sys.argv[2] if len(sys.argv)>2 else ""),wait_until="networkidle"); pg.wait_for_timeout(500)
    pg.screenshot(path=OUT+"/peek_full.png",full_page=True)
    print(errs, pg.evaluate("document.documentElement.scrollWidth"))
    pg.emulate_media(media="print"); pg.pdf(path=OUT+"/peek.pdf",prefer_css_page_size=True,print_background=True)
    import pypdfium2 as pdfium
    d=pdfium.PdfDocument(OUT+"/peek.pdf"); print("pages",len(d))
    for i in range(len(d)): d[i].render(scale=1.4).to_pil().save(OUT+f"/peek_p{i+1}.png")

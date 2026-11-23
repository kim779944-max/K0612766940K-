"""라이브 확인 — autooneclick.com/viewer.html 에 테스트셋 일부(사진2·PDF2·hwpx1)를 한 번에 첨부 → 장수·PDF 저장 쪽수"""
import json, os, sys, time
from playwright.sync_api import sync_playwright
OUT = sys.argv[1]; TS = os.path.join(OUT, "testset")
F = [os.path.join(TS, n) for n in ("01_사진.png", "02_사진.png", "21_PDF.pdf", "26_PDF_가로.pdf", "28_한글.hwpx")]
R = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block", accept_downloads=True)
    pg = ctx.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.goto("https://autooneclick.com/viewer.html?t=" + str(int(time.time())), wait_until="load"); pg.wait_for_timeout(1500)
    pg.set_input_files("#f", F)
    pg.wait_for_function("!MF.busy && MF.total>0", timeout=60000); pg.wait_for_timeout(800)
    R["state"] = pg.evaluate("({items:MF.items.length,total:MF.total,pgNo:document.getElementById('pgNo').textContent,vtName:document.getElementById('vtName').textContent,sw:document.documentElement.scrollWidth})")
    pg.screenshot(path=os.path.join(OUT, "live_attach_390.png"))
    with pg.expect_download(timeout=120000) as d:
        pg.click("#mfPdfBtn")
    fp = os.path.join(OUT, "dbg", "live.pdf"); d.value.save_as(fp)
    from pypdf import PdfReader
    rd = PdfReader(fp)
    R["pdf"] = {"name": d.value.suggested_filename, "pages": len(rd.pages)}
    R["pageErrors"] = errs
    br.close()
json.dump(R, open(os.path.join(OUT, "live.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps(R, ensure_ascii=False))

"""한 파일 표(hwpx) [그림 저장] 결과 확인 — URL 별로(원본/수정본) 비교"""
import os, sys
from playwright.sync_api import sync_playwright
URL, F, OUTP = sys.argv[1], sys.argv[2], sys.argv[3]
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block", accept_downloads=True)
    pg = ctx.new_page(); pg.goto(URL)
    pg.set_input_files("#f", [F]); pg.wait_for_function("document.body.classList.contains('docopen') && PP.sheet", timeout=30000); pg.wait_for_timeout(800)
    with pg.expect_download(timeout=30000) as d:
        pg.click("#vtSaveImg")
    d.value.save_as(OUTP)
    from PIL import Image
    im = Image.open(OUTP); print(im.size); im.convert("RGB").resize((im.width // 4, im.height // 4)).save(OUTP)
    br.close()

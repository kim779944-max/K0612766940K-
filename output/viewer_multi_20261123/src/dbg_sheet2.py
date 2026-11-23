"""여러 장 표/텍스트의 2번째 A4 장 그림 저장 확인"""
import sys
from playwright.sync_api import sync_playwright
F, OUTP = sys.argv[1], sys.argv[2]
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block", accept_downloads=True)
    pg = ctx.new_page(); pg.goto("http://127.0.0.1:8794/viewer.html?t=s2")
    pg.set_input_files("#f", [F]); pg.wait_for_function("PP.sheet", timeout=30000); pg.wait_for_timeout(800)
    print(pg.evaluate("PP.tops.length"), pg.evaluate("document.getElementById('pgNo').textContent"))
    pg.evaluate("goPage(1,false)"); pg.wait_for_timeout(400)
    with pg.expect_download() as d: pg.evaluate("saveSheetPage(1)")  # 2번째 장 직접 저장(한 파일 보기의 끝 장 감지는 기존 동작 그대로라 별도)
    d.value.save_as(OUTP)
    from PIL import Image
    im = Image.open(OUTP); print(d.value.suggested_filename, im.size); im.convert("RGB").resize((im.width // 4, im.height // 4)).save(OUTP)
    br.close()

"""고치기 전 캡처 — 사진 3장을 한 번에 골라도 1장만 열리는 것 · 하단 바."""
import json, os, sys
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
URL = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8794/viewer.html"
TS = os.path.join(OUT, "testset")
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page()
    pg.goto(URL + "?t=before", wait_until="load")
    pg.wait_for_timeout(800)
    multiple = pg.evaluate("document.getElementById('f').multiple")
    # 실제 <input> 에 multiple 이 없으므로 브라우저는 1개만 고르게 한다 — 속성을 잠시 켜서 3장을 넣어 봐도 files[0] 만 연다
    pg.evaluate("document.getElementById('f').multiple=true")
    pg.set_input_files("#f", [os.path.join(TS, f"0{i}_사진.png") for i in (1, 2, 3)])
    pg.wait_for_timeout(2000)
    r = pg.evaluate("({multipleAttr:%s, filesGiven:document.getElementById('f').files.length, pgNo:document.getElementById('pgNo').textContent, name:document.getElementById('vtName').textContent, pages:document.querySelectorAll('#out .pppage').length})" % ("true" if multiple else "false"))
    pg.screenshot(path=os.path.join(OUT, "before_single_only.png"))
    pg.locator("#pbar").screenshot(path=os.path.join(OUT, "before_pbar.png"))
    r["pbarH"] = pg.evaluate("document.getElementById('pbar').offsetHeight")
    print(json.dumps(r, ensure_ascii=False))
    json.dump(r, open(os.path.join(OUT, "before.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    br.close()

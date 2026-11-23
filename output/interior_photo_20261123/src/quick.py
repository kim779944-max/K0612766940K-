"""빠른 확인 — 거실 50% + 자재 선택 캡처(작업용).  usage: python quick.py URL OUTDIR"""
import sys, json
from playwright.sync_api import sync_playwright
URL, OUT = sys.argv[1], sys.argv[2]
errs = []
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page()
    pg.on("console", lambda m: m.type == "error" and errs.append(m.text))
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(URL, wait_until="load"); pg.wait_for_timeout(1500)
    print(json.dumps(pg.evaluate("__KTS_INTERIOR()"), ensure_ascii=False)[:400])
    for scene, mats in [("living", ["denbar", "floor"]), ("room", ["tile", "floor"]), ("shop", ["wallpaper", "floor"]), ("living", ["marble"])]:
        pg.click(f'#sceneTabs .tab[data-s="{scene}"]'); pg.wait_for_timeout(200)
        cur = pg.evaluate("__KTS_INTERIOR().mat")
        for z, v in cur.items():
            if v: pg.click(f'#matBox button[data-m="{v}"]'); pg.wait_for_timeout(100)
        for m in mats: pg.click(f'#matBox button[data-m="{m}"]'); pg.wait_for_timeout(400)
        pg.evaluate("document.querySelector('#rngSample').value=0;document.querySelector('#rngSample').dispatchEvent(new Event('input'))")
        pg.wait_for_timeout(200)
        pg.locator('#baSample canvas.af').screenshot(path=f"{OUT}/q_{scene}_{'_'.join(mats)}.png")
    print("ERR", errs)
    br.close()

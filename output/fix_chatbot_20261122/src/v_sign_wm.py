import sys, base64
from playwright.sync_api import sync_playwright
CAP, SAMPLE = sys.argv[1], sys.argv[2]
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    pg = b.new_page(viewport={"width": 390, "height": 844})
    errs=[]; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto("http://127.0.0.1:8791/sign/"); pg.evaluate("localStorage.setItem('kts_sign_plan','pro')"); pg.reload(); pg.wait_for_timeout(500)
    bx = pg.locator("#cv").bounding_box(); pg.mouse.move(bx["x"]+30,bx["y"]+40); pg.mouse.down()
    for k in range(12): pg.mouse.move(bx["x"]+30+k*15, bx["y"]+40+(k%3)*18)
    pg.mouse.up(); pg.wait_for_timeout(300)
    pg.set_input_files("#docFile", SAMPLE.split(",")); pg.wait_for_timeout(1200)
    pg.click("#ganin"); pg.wait_for_timeout(200)
    sb = pg.locator("#stage").bounding_box(); pg.mouse.click(sb["x"]+sb["width"]*0.6, sb["y"]+sb["height"]*0.7); pg.wait_for_timeout(300)
    url = pg.evaluate("composePage(0).toDataURL('image/png')")
    open(CAP + "/sign_05_pro_preview_composed_page1.png", "wb").write(base64.b64decode(url.split(",")[1]))
    print("ganin", pg.evaluate("ganin"), "errs", errs)
    b.close()

"""고치기 전 캡처 (라이브) — 표준 매매계약서 빈칸 지정 화면 · 사진 등록 후 빈칸 지정 화면 · 수치."""
import json, sys, time
from playwright.sync_api import sync_playwright
OUT, URL, PHOTO = sys.argv[1], sys.argv[2], sys.argv[3]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
R = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=3, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.goto(URL + "?t=%d" % time.time(), wait_until="load"); pg.wait_for_timeout(1200)
    pg.click("#psSale"); pg.wait_for_timeout(1500); pg.click("#pvStart"); pg.wait_for_timeout(1500)
    pg.evaluate("TF.go(2)"); pg.wait_for_timeout(1200)
    pg.screenshot(path=f"{OUT}/before_390_s2.png")
    R["sale_s2"] = pg.evaluate("(()=>{const r=document.getElementById('edStage').getBoundingClientRect();return {stageW:r.width,stageH:Math.round(r.height),fields:TF.CUR.fields.length,sw:document.documentElement.scrollWidth,autoBtn:!!document.getElementById('autoF')}})()")
    pg.evaluate("TF.go(1)"); pg.wait_for_timeout(500)
    pg.set_input_files("#photoIn", PHOTO); pg.wait_for_timeout(4000)
    pg.click("#nextBtn"); pg.wait_for_timeout(1200)
    pg.screenshot(path=f"{OUT}/before_390_photo.png")
    R["photo_s2"] = pg.evaluate("(()=>{const r=document.getElementById('edStage').getBoundingClientRect();return {stageW:r.width,stageH:Math.round(r.height),fields:TF.CUR.fields.length,sw:document.documentElement.scrollWidth,autoBtn:!!document.getElementById('autoF')}})()")
    R["errors"] = errs
    print(json.dumps(R, ensure_ascii=False))
    br.close()

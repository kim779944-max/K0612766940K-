import json, os, sys
from playwright.sync_api import sync_playwright
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
BASE = "http://127.0.0.1:8791"
CAP = sys.argv[1]
SAMPLE = sys.argv[2]  # 테스트용 문서 이미지 2장 (쉼표)
out = {}
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = b.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True)
    pg = ctx.new_page()
    errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
    pg.goto(BASE + "/sign/")
    pg.evaluate("localStorage.removeItem('kts_sign_plan')")
    pg.reload(); pg.wait_for_timeout(600)
    out["order"] = pg.evaluate("[...document.querySelectorAll('main section.card > h2')].map(h=>[h.textContent.trim(), Math.round(h.getBoundingClientRect().top+scrollY)])")
    out["free_bar_after_rsv"] = pg.evaluate("(()=>{const r=document.querySelector('.ktsRsv'),f=document.querySelector('.kux-free');return f?[r.nextElementSibling===f, Math.round(r.getBoundingClientRect().bottom), Math.round(f.getBoundingClientRect().top)]:'no .kux-free'})()")
    out["png_in_1"] = pg.evaluate("document.querySelector('#pngDl').closest('section').querySelector('h2').textContent")
    out["out_in_2"] = pg.evaluate("[document.querySelector('#outImg').closest('section').querySelector('h2').textContent,document.querySelector('#outPdf').closest('section').querySelector('h2').textContent]")
    out["ganin_in"] = pg.evaluate("document.querySelector('#ganin').closest('section').querySelector('h2').textContent")
    out["money_hidden"] = pg.evaluate("(()=>{const m=document.querySelector('[data-kts-money]');return [m.className, getComputedStyle(m).display, document.querySelectorAll('#ganin').length]})()")
    H = pg.evaluate("document.documentElement.scrollHeight")
    for i, y in enumerate([0, H // 2 - 422, H - 844]):
        pg.evaluate(f"scrollTo(0,{max(0,y)})"); pg.wait_for_timeout(200)
        pg.screenshot(path=f"{CAP}/sign_0{i+1}_{['top','mid','bot'][i]}_390.png")
    # 무료 상태 간인 클릭 → 토스트
    pg.click("#ganin"); pg.wait_for_timeout(150)
    out["free_toast"] = pg.evaluate("document.getElementById('toast').textContent")
    out["free_ganin_on"] = pg.evaluate("document.getElementById('ganin').classList.contains('on')")
    # 사인 그리기
    pg.evaluate("document.querySelector('#pad').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    bx = pg.locator("#cv").bounding_box()
    pg.mouse.move(bx["x"] + 30, bx["y"] + 40); pg.mouse.down()
    for k in range(12):
        pg.mouse.move(bx["x"] + 30 + k * 15, bx["y"] + 40 + (k % 3) * 18)
    pg.mouse.up(); pg.wait_for_timeout(400)
    # 이용권 펼치고 PRO
    pg.click(".kux-morebar button"); pg.wait_for_timeout(200)
    pg.click(".plan[data-p=pro]"); pg.wait_for_timeout(200)
    out["plan_tag"] = pg.evaluate("document.getElementById('planTag').textContent")
    pg.set_input_files("#docFile", SAMPLE.split(","))
    pg.wait_for_timeout(1500)
    out["docs"] = pg.evaluate("document.querySelectorAll('#pages > *').length")
    pg.click("#ganin"); pg.wait_for_timeout(300)
    out["pro_ganin_on"] = pg.evaluate("document.getElementById('ganin').classList.contains('on')")
    # 첫 쪽에 찍기
    pg.evaluate("document.querySelector('#stage').scrollIntoView({block:'center'})"); pg.wait_for_timeout(200)
    sb = pg.locator("#stage").bounding_box()
    pg.mouse.click(sb["x"] + sb["width"] * 0.6, sb["y"] + sb["height"] * 0.7); pg.wait_for_timeout(500)
    pg.screenshot(path=f"{CAP}/sign_04_pro_ganin_preview_390.png")
    out["wm_text_in_render"] = pg.evaluate("(()=>{const s=document.querySelector('#stage');return s.innerText.slice(0,120)})()")
    out["errors"] = errs
    b.close()
print(json.dumps(out, ensure_ascii=False, indent=1))

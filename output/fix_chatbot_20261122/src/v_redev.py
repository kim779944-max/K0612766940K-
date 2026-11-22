import json, os, sys
from playwright.sync_api import sync_playwright
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
BASE = "http://127.0.0.1:8791"
CAP = sys.argv[1]
os.makedirs(CAP, exist_ok=True)
out = {}
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = b.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True)
    pg = ctx.new_page()
    errs, reqs = [], []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
    pg.on("request", lambda r: reqs.append(r.url))
    pg.goto(BASE + "/redev/")
    pg.wait_for_function("document.getElementById('stM').textContent!=='—'")
    out["redev_req"] = [u for u in reqs if "redev.json" in u]
    out["stats"] = pg.evaluate("['stS','stG','stN','stM','moaCnt'].map(i=>document.getElementById(i).textContent)")
    out["tabs"] = pg.evaluate("[...document.querySelectorAll('#tabs button')].map(b=>b.dataset.t)")
    out["moa_in_tabs"] = pg.evaluate("!!document.querySelector('#tabs [data-t=moa]')")
    out["sw_init"] = pg.evaluate("document.documentElement.scrollWidth")
    pg.screenshot(path=f"{CAP}/redev_01_init_390.png")
    res = {}
    for q in ["번동", "구기동", "수유동", "개포동 138"]:
        pg.fill("#q", q)
        pg.wait_for_timeout(150)
        res[q] = pg.evaluate("""({tot:document.getElementById('totline').textContent,cnt:document.getElementById('cnt').textContent,
          chips:getComputedStyle(document.getElementById('chips')).display,
          on:[...document.querySelectorAll('#tabs button.on,#moaBtn.on')].length,
          badges:[...document.querySelectorAll('#list .src')].map(x=>x.textContent).join(','),
          sw:document.documentElement.scrollWidth})""")
        if q == "번동":
            pg.screenshot(path=f"{CAP}/redev_02_bundong_all_390.png", full_page=False)
    out["search"] = res
    # 구기동 → 모아타운 카드 → 상세
    pg.fill("#q", "구기동"); pg.wait_for_timeout(150)
    pg.screenshot(path=f"{CAP}/redev_03_gugidong_all_390.png")
    pg.click("#list .item")
    pg.wait_for_timeout(200)
    out["gugi_detail_head"] = pg.evaluate("document.querySelector('#sheet .shd span').textContent")
    out["gugi_detail_has_mlad"] = pg.evaluate("!!document.querySelector('#sheet .mlad')")
    pg.screenshot(path=f"{CAP}/redev_04_gugidong_moa_detail_390.png")
    pg.click("[data-act=close]")
    # 번동 → 서울 카드 상세는 사다리
    pg.fill("#q", "번동"); pg.wait_for_timeout(150)
    pg.click("#list .item[data-t=seoul]")
    out["bundong_seoul_detail"] = pg.evaluate("[document.querySelector('#sheet .shd span').textContent, !!document.querySelector('#sheet .lad .row')]")
    pg.click("[data-act=close]")
    pg.click("#list .item[data-t=nation]")
    out["bundong_nation_detail"] = pg.evaluate("document.querySelector('#sheet .shd span').textContent")
    pg.click("[data-act=close]")
    # 탭 직접 클릭 → 그 탭만 (검색어 유지)
    pg.click("#tabs [data-t=seoul]")
    out["pin_seoul"] = pg.evaluate("[document.getElementById('q').value,document.getElementById('cnt').textContent,[...document.querySelectorAll('#tabs button.on')].map(b=>b.dataset.t).join(),getComputedStyle(document.getElementById('chips')).display]")
    pg.click("#moaBtn")
    out["pin_moa"] = pg.evaluate("[document.getElementById('cnt').textContent,document.getElementById('moaBtn').className,[...document.querySelectorAll('#tabs button.on')].length,getComputedStyle(document.getElementById('muNote')).display]")
    pg.screenshot(path=f"{CAP}/redev_05_moa_pinned_390.png")
    # 지움 → 마지막 탭(모아타운)
    pg.click("#clr")
    out["after_clear"] = pg.evaluate("[document.getElementById('cnt').textContent,document.getElementById('base').textContent,document.getElementById('totline').textContent]")
    pg.click("#tabs [data-t=seoul]")
    out["seoul_default"] = pg.evaluate("document.getElementById('cnt').textContent")
    # 0건
    pg.fill("#q", "없는동네xyz"); pg.wait_for_timeout(100)
    out["empty"] = pg.evaluate("document.querySelector('#list .empty').textContent")
    # 더 보기 (통합)
    pg.fill("#q", "동"); pg.wait_for_timeout(200)
    out["more"] = pg.evaluate("[document.getElementById('more').textContent,document.getElementById('totline').textContent]")
    out["sw_end"] = pg.evaluate("document.documentElement.scrollWidth")
    out["errors"] = errs
    b.close()
print(json.dumps(out, ensure_ascii=False, indent=1))

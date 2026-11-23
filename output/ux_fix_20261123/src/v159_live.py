"""159 라이브 빠른 확인 — 크기·탭·드래그·스냅·저장 (autooneclick.com)"""
import json, sys
from playwright.sync_api import sync_playwright
B = "https://autooneclick.com/"
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    c = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    pg = c.new_page(); pg.goto(B + "sale/"); pg.wait_for_timeout(3500)
    S = "(()=>{const b=document.getElementById('kts-helper-btn');const r=b.getBoundingClientRect();return {v:KTS_HELPER.v,w:r.width,h:r.height,l:r.left,t:r.top,right:innerWidth-r.right,open:!!document.querySelector('#kts-helper.on'),pos:localStorage.getItem('kts_helper_pos_v1')}})()"
    a = pg.evaluate(S); cdp = c.new_cdp_session(pg)
    def t(typ, pts): cdp.send("Input.dispatchTouchEvent", {"type": typ, "touchPoints": [{"x": x, "y": y, "id": 1} for x, y in pts]})
    cx, cy = a["l"] + 19, a["t"] + 19
    t("touchStart", [(cx, cy)]); t("touchMove", [(cx + 3, cy)]); t("touchEnd", []); pg.wait_for_timeout(500)
    tap = pg.evaluate(S); pg.evaluate("KTS_HELPER.close()")
    t("touchStart", [(cx, cy)])
    for k in range(1, 11): t("touchMove", [(cx + (330 - cx) * k / 10, cy + (300 - cy) * k / 10)])
    t("touchEnd", []); pg.wait_for_timeout(500); d = pg.evaluate(S)
    pg.goto(B + "redev/"); pg.wait_for_timeout(2000); other = pg.evaluate(S)
    print(json.dumps({"default": a, "tap3": tap["open"], "drag": d, "other_page": other}, ensure_ascii=False, indent=1))
    json.dump({"default": a, "tap3": tap, "drag": d, "other_page": other}, open("159_live.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    br.close()

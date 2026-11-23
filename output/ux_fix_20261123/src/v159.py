"""159 도우미 검증 — 크기·탭/드래그·스냅·저장·자동회피 중지·본문 가림 면적(전/후)·회귀.
python -P -X utf8 v159.py <out_dir> [base_after] [base_before]"""
import json, sys, os
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
AFTER = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8791/"
BEFORE = sys.argv[3] if len(sys.argv) > 3 else "http://127.0.0.1:8792/"
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
PAGES = ["", "sale/", "redev/", "navi2/", "thescan/", "hogang/", "gagebu/", "theform/", "contract/", "sign/"]

# 버튼이 글자(텍스트 노드 줄 박스) 위에 걸리는 면적(px²) — 버튼·도우미 창 자신은 제외
COVER = """(()=>{
 const b=document.getElementById('kts-helper-btn'); if(!b) return null;
 const rb=b.getBoundingClientRect(); let area=0; const seen=[];
 const tw=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT,{acceptNode:n=>{
   if(!n.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
   const p=n.parentElement; if(!p||p.closest('#kts-helper-btn,#kts-helper,#kts-helper-toast,script,style')) return NodeFilter.FILTER_REJECT;
   const cs=getComputedStyle(p); if(cs.visibility==='hidden'||+cs.opacity===0) return NodeFilter.FILTER_REJECT;
   return NodeFilter.FILTER_ACCEPT;}});
 const rg=document.createRange(); let n;
 while((n=tw.nextNode())){ rg.selectNodeContents(n);
   for(const r of rg.getClientRects()){
     const x=Math.max(0,Math.min(rb.right,r.right)-Math.max(rb.left,r.left)), y=Math.max(0,Math.min(rb.bottom,r.bottom)-Math.max(rb.top,r.top));
     if(x*y>0){ // 버튼 앞에 실제로 보이는 글자만(버튼 아래 깔린 글자) — 중복 줄 박스는 한 번만
       const k=[Math.round(r.left),Math.round(r.top),Math.round(r.right),Math.round(r.bottom)].join(','); if(seen.includes(k)) continue; seen.push(k); area+=x*y; }
   }}
 return {area:Math.round(area), btn:[Math.round(rb.left),Math.round(rb.top),Math.round(rb.width),Math.round(rb.height)]};
})()"""

STATE = """(()=>{const b=document.getElementById('kts-helper-btn'); const r=b.getBoundingClientRect(); const cs=getComputedStyle(b);
 return {l:Math.round(r.left*10)/10,t:Math.round(r.top*10)/10,w:Math.round(r.width*10)/10,h:Math.round(r.height*10)/10,
  right:Math.round((innerWidth-r.right)*10)/10, sl:b.style.left, st:b.style.top, sb:b.style.bottom, sr:b.style.right,
  fs:getComputedStyle(b.querySelector('b')).fontSize, op:cs.opacity, ta:cs.touchAction, label:getComputedStyle(b.querySelector('span')).width,
  aria:b.getAttribute('aria-label'), open:!!document.querySelector('#kts-helper.on'), pos:localStorage.getItem('kts_helper_pos_v1'), bar:b.getAttribute('data-bar')};})()"""


def coverage(ctx, base):
    tot, rows = 0, []
    for u in PAGES:
        pg = ctx.new_page()
        pg.goto(base + u, wait_until="load"); pg.wait_for_timeout(1500)
        for frac in (0, 0.33, 0.66, 1.0):
            pg.evaluate(f"scrollTo(0,(document.documentElement.scrollHeight-innerHeight)*{frac})"); pg.wait_for_timeout(400)
            c = pg.evaluate(COVER)
            if c: tot += c["area"]; rows.append({"page": u or "index", "frac": frac, **c})
        pg.close()
    return tot, rows


def touch(cdp, typ, pts):
    cdp.send("Input.dispatchTouchEvent", {"type": typ, "touchPoints": [{"x": x, "y": y, "id": 1} for x, y in pts]})


res = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    def mk():
        return br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")

    # ---- 전/후 가림 면적
    cb = mk(); tb, rb_ = coverage(cb, BEFORE)
    pg = cb.new_page(); pg.goto(BEFORE + "sale/"); pg.wait_for_timeout(1500); pg.screenshot(path=os.path.join(OUT, "159_before.png"))
    res["before_state_sale"] = pg.evaluate("(()=>{const r=document.getElementById('kts-helper-btn').getBoundingClientRect();return [r.left,r.top,r.width,r.height]})()")
    cb.close()
    ca = mk(); ta, ra = coverage(ca, AFTER); ca.close()
    res["cover"] = {"before_px2": tb, "after_px2": ta, "reduce_pct": round((1 - ta / tb) * 100, 1) if tb else None,
                    "btn_area_before": None, "rows_before": rb_, "rows_after": ra}

    # ---- 후: 크기·탭·드래그·스냅·저장
    ctx = mk(); errs = []
    pg = ctx.new_page(); pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("console", lambda m: errs.append(m.text[:200]) if m.type == "error" else None)
    pg.goto(AFTER + "sale/"); pg.wait_for_timeout(1500)
    pg.evaluate("localStorage.removeItem('kts_helper_pos_v1')"); pg.reload(); pg.wait_for_timeout(1500)
    pg.screenshot(path=os.path.join(OUT, "159_after_38.png"))
    s0 = pg.evaluate(STATE); res["size"] = s0
    cdp = ctx.new_cdp_session(pg)
    cx, cy = s0["l"] + s0["w"] / 2, s0["t"] + s0["h"] / 2
    # 탭 3px (터치)
    touch(cdp, "touchStart", [(cx, cy)]); touch(cdp, "touchMove", [(cx + 3, cy)]); touch(cdp, "touchEnd", [])
    pg.wait_for_timeout(500); res["tap3_touch_open"] = pg.evaluate("!!document.querySelector('#kts-helper.on')")
    pg.evaluate("KTS_HELPER.close()"); pg.wait_for_timeout(300)
    # 탭 3px (마우스)
    pg.mouse.move(cx, cy); pg.mouse.down(); pg.mouse.move(cx + 3, cy); pg.mouse.up(); pg.wait_for_timeout(400)
    res["tap3_mouse_open"] = pg.evaluate("!!document.querySelector('#kts-helper.on')")
    pg.evaluate("KTS_HELPER.close()"); pg.wait_for_timeout(300)
    # 드래그 30px (터치) — 창 안 열림·버튼 따라옴
    touch(cdp, "touchStart", [(cx, cy)])
    for i in range(1, 7): touch(cdp, "touchMove", [(cx + 5 * i, cy - 5 * i)])
    mid = pg.evaluate(STATE)
    touch(cdp, "touchEnd", []); pg.wait_for_timeout(500)
    res["drag30_touch"] = {"mid": mid, "after": pg.evaluate(STATE)}
    # 드래그 큰 이동 (터치) — 오른쪽 위로, 중간 캡처
    s1 = pg.evaluate(STATE); cx, cy = s1["l"] + s1["w"] / 2, s1["t"] + s1["h"] / 2
    touch(cdp, "touchStart", [(cx, cy)])
    pts = [(cx + (300 - cx) * k / 12, cy + (300 - cy) * k / 12) for k in range(1, 13)]
    for x, y in pts: touch(cdp, "touchMove", [(x, y)])
    pg.wait_for_timeout(150); res["drag_mid"] = pg.evaluate(STATE); pg.screenshot(path=os.path.join(OUT, "159_drag_mid.png"))
    touch(cdp, "touchEnd", []); pg.wait_for_timeout(500)
    res["snap_right"] = pg.evaluate(STATE)
    # 마우스 드래그 → 왼쪽 가장자리로
    s2 = res["snap_right"]; cx, cy = s2["l"] + s2["w"] / 2, s2["t"] + s2["h"] / 2
    pg.mouse.move(cx, cy); pg.mouse.down(); pg.mouse.move(cx - 40, cy + 40, steps=4); pg.mouse.move(120, 420, steps=6); pg.mouse.up(); pg.wait_for_timeout(500)
    res["snap_left_mouse"] = pg.evaluate(STATE)
    # 다시 오른쪽 위로(저장 확인용 최종 자리)
    s3 = res["snap_left_mouse"]; cx, cy = s3["l"] + s3["w"] / 2, s3["t"] + s3["h"] / 2
    touch(cdp, "touchStart", [(cx, cy)])
    for k in range(1, 11): touch(cdp, "touchMove", [(cx + (340 - cx) * k / 10, cy + (260 - cy) * k / 10)])
    touch(cdp, "touchEnd", []); pg.wait_for_timeout(500)
    saved = pg.evaluate(STATE); res["saved_set"] = saved
    # 위·아래 끝 클램프
    touch(cdp, "touchStart", [(saved["l"] + 19, saved["t"] + 19)])
    for k in range(1, 8): touch(cdp, "touchMove", [(330, saved["t"] + 19 - k * 60)])
    touch(cdp, "touchEnd", []); pg.wait_for_timeout(400); res["clamp_top"] = pg.evaluate(STATE)
    st = pg.evaluate(STATE)
    touch(cdp, "touchStart", [(st["l"] + 19, st["t"] + 19)])
    for k in range(1, 18): touch(cdp, "touchMove", [(330, st["t"] + 19 + k * 60)])
    touch(cdp, "touchEnd", []); pg.wait_for_timeout(400); res["clamp_bottom"] = pg.evaluate(STATE)
    # 최종 자리로 되돌림 (localStorage 직접 = 마지막 저장값 재현)
    pg.evaluate("localStorage.setItem('kts_helper_pos_v1', %s)" % json.dumps(saved["pos"]))
    # 새로고침·다른 도구
    pg.reload(); pg.wait_for_timeout(1500); res["after_reload"] = pg.evaluate(STATE)
    pg.screenshot(path=os.path.join(OUT, "159_saved_after_reload.png"))
    pg.goto(AFTER + "redev/"); pg.wait_for_timeout(1500); res["other_tool_redev"] = pg.evaluate(STATE)
    pg.goto(AFTER + "thescan/"); pg.wait_for_timeout(1500); res["other_tool_thescan"] = pg.evaluate(STATE)
    # 자동 회피 중지 — 하단 바가 있는 페이지에서 10초
    pg.goto(AFTER + "sale/"); pg.wait_for_timeout(1200)
    a = pg.evaluate(STATE); pg.evaluate("scrollTo(0,document.documentElement.scrollHeight)"); pg.wait_for_timeout(10000); b = pg.evaluate(STATE)
    res["auto_stop_10s"] = {"t0": a, "t10": b, "changed": [k for k in ("l", "t", "sl", "st", "sb", "sr") if a[k] != b[k]]}
    # 회전(가로) — 비율로 다시 계산
    pg.set_viewport_size({"width": 844, "height": 390}); pg.wait_for_timeout(800); res["rotate_land"] = pg.evaluate(STATE)
    pg.set_viewport_size({"width": 390, "height": 844}); pg.wait_for_timeout(800); res["rotate_back"] = pg.evaluate(STATE)
    # 회귀 — 열기/닫기·탭 4개·문자 링크
    pg.evaluate("KTS_HELPER.open(0)"); pg.wait_for_timeout(300)
    tabs = []
    for i in range(4):
        pg.click(f'#kts-helper [data-kh-t="{i}"]'); pg.wait_for_timeout(150)
        tabs.append(pg.evaluate(f"!!document.querySelector('#kts-helper [data-kh-p=\"{i}\"].on')"))
    sms = pg.evaluate("[...document.querySelectorAll('#kts-helper a[href^=\"sms:\"]')].map(a=>a.getAttribute('href').slice(0,40))")
    pg.click('#kts-helper [data-kh="close"]'); pg.wait_for_timeout(300)
    res["regress"] = {"tabs": tabs, "sms": sms, "closed": not pg.evaluate("!!document.querySelector('#kts-helper.on')")}
    # 저장값 없을 때 하단바 회피 유지
    pg.evaluate("localStorage.removeItem('kts_helper_pos_v1')"); pg.reload(); pg.wait_for_timeout(2500)
    res["no_saved_default"] = pg.evaluate(STATE)
    res["sw"] = pg.evaluate("document.documentElement.scrollWidth")
    res["errors"] = errs
    ctx.close(); br.close()

json.dump(res, open(os.path.join(OUT, "159_verify.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
short = {k: v for k, v in res.items() if k != "cover"}
short["cover"] = {k: res["cover"][k] for k in ("before_px2", "after_px2", "reduce_pct")}
print(json.dumps(short, ensure_ascii=False, indent=1))

"""159 본문 가림 — 픽셀 비교. 버튼을 숨긴 화면에서 버튼 자리 안의 '글자 픽셀'(배경 중앙값과 휘도차 >60) 수를 센다.
전(:8792)·후(:8791) 같은 페이지·같은 스크롤 위치 10페이지×4위치."""
import io, json, os, sys
from PIL import Image
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
SETS = {"before": "http://127.0.0.1:8792/", "after": "http://127.0.0.1:8791/"}
PAGES = ["", "sale/", "redev/", "navi2/", "thescan/", "hogang/", "gagebu/", "theform/", "contract/", "sign/"]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"


def glyph_px(png, box):
    im = Image.open(io.BytesIO(png)).convert("L")
    x0, y0, x1, y1 = [int(round(v * 2)) for v in box]  # DPR 2
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(im.width, x1), min(im.height, y1)
    if x1 <= x0 or y1 <= y0: return 0, 0
    reg = im.crop((x0, y0, x1, y1)); px = list(reg.getdata())
    med = sorted(px)[len(px) // 2]
    return sum(1 for v in px if abs(v - med) > 60) / 4.0, len(px) / 4.0  # CSS px² 로 환산


res = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    for name, base in SETS.items():
        ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
        rows, tot, area = [], 0, 0
        for u in PAGES:
            pg = ctx.new_page(); pg.goto(base + u, wait_until="load"); pg.wait_for_timeout(1500)
            for frac in (0, 0.33, 0.66, 1.0):
                pg.evaluate(f"scrollTo(0,(document.documentElement.scrollHeight-innerHeight)*{frac})"); pg.wait_for_timeout(2300)
                r = pg.evaluate("(()=>{const b=document.getElementById('kts-helper-btn');const r=b.getBoundingClientRect();b.style.visibility='hidden';return [r.left,r.top,r.right,r.bottom]})()")
                png = pg.screenshot()
                pg.evaluate("document.getElementById('kts-helper-btn').style.visibility=''")
                g, a = glyph_px(png, r)
                tot += g; area += a; rows.append({"page": u or "index", "frac": frac, "btn": [round(v) for v in r], "glyph_px2": g})
            pg.close()
        res[name] = {"glyph_px2": tot, "btn_px2_sum": area, "rows": rows}
        ctx.close()
    br.close()
b, a = res["before"]["glyph_px2"], res["after"]["glyph_px2"]
res["reduce_pct"] = round((1 - a / b) * 100, 1) if b else None
json.dump(res, open(os.path.join(OUT, "159_cover_px.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps({"before": b, "after": a, "reduce_pct": res["reduce_pct"],
                  "btn_area_before": res["before"]["btn_px2_sum"], "btn_area_after": res["after"]["btn_px2_sum"]}, ensure_ascii=False))
for n in ("before", "after"):
    agg = {}
    for r in res[n]["rows"]: agg[r["page"]] = agg.get(r["page"], 0) + r["glyph_px2"]
    print(n, agg)

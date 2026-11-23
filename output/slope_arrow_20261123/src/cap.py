"""144번 캡처·실측 — 390x844 · 가평 신하리 → 상세 설정 [화살표] 켬 → 층 상태·타일·치수·캡처.
사용: cap.py <OUT> <URL> <before|after>"""
import io, json, sys
from urllib.parse import urlparse
from PIL import Image
from playwright.sync_api import sync_playwright

OUT, URL, PRE = sys.argv[1], sys.argv[2], sys.argv[3]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
R = {"url": URL.split("?")[0], "prefix": PRE}

STATE = """(()=>{const on=s=>{const b=document.querySelector(s);return b?b.classList.contains('on'):null};
const disp=id=>{const e=document.getElementById(id);return e?getComputedStyle(e).display:null};
const px=window.__KTS_PX?window.__KTS_PX():null;
return {pxView:[...document.querySelectorAll('#pxView button.on')].map(b=>b.dataset.v),
 btn_sat:on('#togs button[data-l="sat"]'),btn_arrow:on('#togsAdv button[data-l="arrow"]'),btn_slope:on('#togsAdv button[data-l="slope"]'),
 px_on:px?px.on:null, cbw:disp('cbw'),opRow:disp('opRow'),aleg:disp('aleg'),advOn:(document.getElementById('advOn')||{}).textContent,
 ar:window.__KTS_AR?window.__KTS_AR():(px?px.arrows:null)}})()"""
MEAS = """(()=>{const vis=b=>{const r=b.getBoundingClientRect();return r.width>0&&r.height>0&&!b.closest('details:not([open])')};
const ctl=[...document.querySelectorAll('#ctl button')].filter(vis);
return {sw:document.documentElement.scrollWidth,mapcvH:document.getElementById('mapcv').getBoundingClientRect().height,
 ctlVisibleButtons:ctl.length,
 minBtnH:Math.min(...[...document.querySelectorAll('#vmode button, #ctl button:not(.outrow button), #advBox>summary')].filter(vis).map(b=>b.getBoundingClientRect().height)),
 outBtnH:[...document.querySelectorAll('.outrow button')].map(b=>b.getBoundingClientRect().height),
 note:(document.querySelector('.arrow-note')||{}).textContent}})()"""


def shot_map(pg, name):
    pg.evaluate("document.querySelector('.mapwrap').scrollIntoView({block:'start'})"); pg.wait_for_timeout(400)
    b = pg.locator(".mapwrap").screenshot(path=f"{OUT}/{name}")
    return Image.open(io.BytesIO(b))


def zoom(im, name, cx, cy, half, k):
    d = 2  # device_scale_factor
    box = (int((cx - half) * d), int((cy - half) * d), int((cx + half) * d), int((cy + half) * d))
    c = im.crop(box); c = c.resize((c.width * k // d, c.height * k // d), Image.NEAREST); c.save(f"{OUT}/{name}")


def tilecount(us):
    return {"sat_arcgis": sum("arcgisonline" in u for u in us),
            "map_osm_vworld_base": sum(("openstreetmap" in u) or ("/Base/" in u) for u in us)}


with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True,
                         service_workers="block", accept_downloads=True)
    pg = ctx.new_page()
    errs, reqs = [], []
    pg.on("pageerror", lambda e: errs.append("pageerror " + str(e)[:200]))
    pg.on("console", lambda m: errs.append("console " + m.text[:200]) if m.type == "error" else None)
    pg.on("request", lambda r: reqs.append(r.url))
    pg.goto(URL, wait_until="load")
    pg.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'", timeout=40000)
    pg.click("#chips button:has-text('가평 신하리')")
    pg.wait_for_timeout(1500)
    pg.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'", timeout=40000)
    pg.wait_for_timeout(4000)
    R["state0"] = pg.evaluate(STATE)
    pg.evaluate("document.getElementById('advBox').open=true"); pg.wait_for_timeout(300)
    n0 = len(reqs)
    pg.click("#togsAdv button[data-l='arrow']")
    pg.wait_for_timeout(5000)
    R["tiles_after_arrow"] = tilecount(reqs[n0:])
    R["state_arrow_adv"] = pg.evaluate(STATE)
    R["measure"] = pg.evaluate(MEAS)
    pg.evaluate("document.getElementById('advBox').open=false"); pg.wait_for_timeout(400)
    im = shot_map(pg, f"{PRE}_arrow_390.png")
    samp = pg.evaluate("window.__KTS_ARROWS?window.__KTS_ARROWS('drawn'):[]")
    R["samples"] = len(samp)
    W, H = im.width // 2, im.height // 2
    zoom(im, f"{PRE}_arrow_zoom.png", W / 2, H / 2, 100, 4)
    if samp:
        mr = pg.evaluate("(()=>{const a=document.querySelector('.mapwrap').getBoundingClientRect(),c=document.getElementById('mapcv').getBoundingClientRect();return [c.left-a.left,c.top-a.top]})()")
        sp = min(samp, key=lambda q: (q["x"] - 167) ** 2 + (q["y"] - 196) ** 2)
        R["arrow_px_point"] = sp
        zoom(im, f"arrow_px_{PRE}.png", sp["x"] + mr[0], sp["y"] + mr[1], 12, 8)
    if PRE == "after":
        pg.click("#pxView button[data-v='px']"); pg.wait_for_timeout(1500)
        R["state_px"] = pg.evaluate(STATE)
        shot_map(pg, "after_arrow_px.png")
        # 픽셀 상태에서 위성 끄고 경사색 켠 뒤 진입로 ①(#pxView 화살표)이 다시 정리하는지
        pg.click("#togs button[data-l='sat']"); pg.evaluate("document.getElementById('advBox').open=true")
        pg.click("#togsAdv button[data-l='slope']"); pg.wait_for_timeout(400)
        R["state_px_user"] = pg.evaluate(STATE)
        pg.evaluate("document.getElementById('advBox').open=false")
        n1 = len(reqs)
        pg.click("#pxView button[data-v='arrow']"); pg.wait_for_timeout(2500)
        R["state_arrow_seg"] = pg.evaluate(STATE)
        R["tiles_after_seg"] = tilecount(reqs[n1:])
        # 수동 [위성] OFF
        pg.click("#togs button[data-l='sat']"); pg.wait_for_timeout(3000)
        R["manual_sat_off"] = pg.evaluate(STATE); shot_map(pg, "manual_sat_off.png")
        pg.wait_for_timeout(2000); R["manual_sat_off_2s_later_btn_sat"] = pg.evaluate(STATE)["btn_sat"]
        pg.click("#togs button[data-l='sat']"); pg.wait_for_timeout(2500)
        # 수동 [경사색] ON
        pg.evaluate("document.getElementById('advBox').open=true")
        pg.click("#togsAdv button[data-l='slope']"); pg.wait_for_timeout(800)
        pg.evaluate("document.getElementById('advBox').open=false")
        R["manual_slope_on"] = pg.evaluate(STATE); shot_map(pg, "manual_slope_on.png")
        pg.wait_for_timeout(2000); R["manual_slope_on_2s_later_btn_slope"] = pg.evaluate(STATE)["btn_slope"]
        pg.evaluate("document.getElementById('advBox').open=true")
        pg.click("#togsAdv button[data-l='slope']"); pg.wait_for_timeout(500)
        # 화살표 끄기 — 위성·경사색 되돌리지 않음
        pg.click("#togsAdv button[data-l='arrow']"); pg.wait_for_timeout(600)
        R["arrow_off"] = pg.evaluate(STATE)
        pg.click("#togsAdv button[data-l='arrow']"); pg.wait_for_timeout(1500)
        pg.evaluate("document.getElementById('advBox').open=false"); pg.wait_for_timeout(300)
        R["state_end"] = pg.evaluate(STATE)
        R["measure_end"] = pg.evaluate(MEAS)
        with pg.expect_download() as dl:
            pg.click("#saveImg")
        path = f"{OUT}/save_arrow_mode.png"; dl.value.save_as(path)
        R["saveImg"] = list(Image.open(path).size)
        pg.evaluate("window.__printed=0; window.print=function(){window.__printed++}")
        pg.click("#printA4"); pg.wait_for_timeout(600)
        R["print_called"] = pg.evaluate("window.__printed")
        pg.emulate_media(media="print")
        pg.pdf(path=f"{OUT}/print_arrow_mode.pdf", prefer_css_page_size=True, print_background=True)
        pg.emulate_media(media="screen")
    R["errors"] = errs
    R["hosts"] = sorted({urlparse(u).hostname for u in reqs if urlparse(u).hostname})
    br.close()

if PRE == "after":
    from pypdf import PdfReader
    import pypdfium2 as pdfium
    R["print_pages"] = len(PdfReader(f"{OUT}/print_arrow_mode.pdf").pages)
    pdfium.PdfDocument(f"{OUT}/print_arrow_mode.pdf")[0].render(scale=150 / 72).to_pil().save(f"{OUT}/print_arrow_mode_1.png")
json.dump(R, open(f"{OUT}/{PRE}_result.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps(R, ensure_ascii=False, indent=1)[:7000])

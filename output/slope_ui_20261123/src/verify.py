"""137번 검증: 390 실측 · 토글/슬라이더/결과뷰 · 이미지 저장(1600) · A4 인쇄(PDF 1쪽) · 미리보기 워터마크."""
import hashlib, io, json, sys, time
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
URL = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8791/slope/"
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
R = {}

MEAS = """(()=>{const m=document.getElementById('mapCard').getBoundingClientRect(),c=document.getElementById('mapcv').getBoundingClientRect();
const card=document.getElementById('mapCard');
const vis=b=>{const r=b.getBoundingClientRect();return r.width>0&&r.height>0&&!b.closest('details:not([open])')};
const ctl=[...document.querySelectorAll('#ctl button')].filter(vis);
const all=[...document.querySelectorAll('#vmode button, #ctl button, #ctl summary, #ctl input[type=range]')].filter(vis);
return {mapCardTop:Math.round(m.top*10)/10,mapcvH:c.height,mapcvW:c.width,sw:document.documentElement.scrollWidth,
 ctlVisibleButtons:ctl.length,ctlNames:ctl.map(b=>b.id||b.getAttribute('data-l')||b.getAttribute('data-v')||b.getAttribute('data-s')),
 minBtnH:Math.min(...[...document.querySelectorAll('#vmode button, #ctl button:not(.outrow button), #advBox>summary')].filter(vis).map(b=>b.getBoundingClientRect().height)),
 outBtnH:[...document.querySelectorAll('.outrow button')].map(b=>b.getBoundingClientRect().height),
 vmodeH:[...document.querySelectorAll('#vmode button')].map(b=>b.getBoundingClientRect().height),
 advOpen:document.getElementById('advBox').open, kEl:document.getElementById('kEl').textContent}})()"""
MAPHASH = "(()=>{const c=document.getElementById('mapcv');return c.toDataURL().length+':'+c.toDataURL().slice(-64)})()"


def mh(pg):
    pg.wait_for_timeout(700)
    # 지도 캔버스는 외부 타일로 taint 되어 toDataURL 이 막힌다 → 화면 캡처 바이트로 비교
    return hashlib.md5(pg.locator('#mapcv').screenshot()).hexdigest()[:10]


with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True,
                         service_workers="block", accept_downloads=True)
    pg = ctx.new_page()
    errs, hosts = [], set()
    pg.on("pageerror", lambda e: errs.append("pageerror " + str(e)[:200]))
    pg.on("console", lambda m: errs.append("console " + m.text[:200]) if m.type == "error" else None)
    pg.on("request", lambda r: hosts.add(urlparse(r.url).hostname))
    pg.goto(URL, wait_until="load")
    pg.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'", timeout=40000)
    pg.wait_for_timeout(3000)
    R["measure"] = pg.evaluate(MEAS)
    pg.screenshot(path=f"{OUT}/after_390_1.png")
    pg.evaluate("document.getElementById('ctl').scrollIntoView({block:'start'});scrollBy(0,-470)")
    pg.wait_for_timeout(600)
    pg.screenshot(path=f"{OUT}/after_390_2.png")

    # 토글 동작 — 지도 캔버스 그림이 실제로 바뀌는지(해시)
    tog = {}
    for k in ["cont", "grid", "parcel", "sat"]:
        b = f"#togs button[data-l='{k}']"
        h0 = mh(pg); pg.click(b); pg.wait_for_timeout(2500 if k in ("sat", "parcel") else 300); h1 = mh(pg)
        on = pg.evaluate(f"document.querySelector(\"{b}\").classList.contains('on')")
        tog[k] = {"changed": h0 != h1, "onAfter": on}
        if k == "grid":
            pg.evaluate("document.querySelector('.mapwrap').scrollIntoView({block:'start'})"); pg.wait_for_timeout(300)
            pg.locator(".mapwrap").screenshot(path=f"{OUT}/toggle_grid_on.png")
        if k == "sat":
            pg.wait_for_timeout(2500)
            pg.evaluate("document.querySelector('.mapwrap').scrollIntoView({block:'start'})"); pg.wait_for_timeout(300)
            pg.locator(".mapwrap").screenshot(path=f"{OUT}/toggle_sat_on.png")
        pg.click(b); pg.wait_for_timeout(400)  # 원상복구
    pg.evaluate("document.getElementById('advBox').open=true"); pg.wait_for_timeout(300)
    for k in ["arrow", "slope", "zone"]:
        b = f"#togsAdv button[data-l='{k}']"
        h0 = mh(pg); pg.click(b); pg.wait_for_timeout(2500 if k == "zone" else 400); h1 = mh(pg)
        on = pg.evaluate(f"document.querySelector(\"{b}\").classList.contains('on')")
        tog[k] = {"changed": h0 != h1, "onAfter": on, "advOn": pg.evaluate("document.getElementById('advOn').textContent")}
        if k == "arrow":
            tog[k]["pxViewSync"] = pg.evaluate("[...document.querySelectorAll('#pxView button.on')].map(b=>b.dataset.v)")
        pg.click(b); pg.wait_for_timeout(400)
    R["toggles"] = tog
    # 슬라이더
    sl = {}
    sl["rad_before"] = pg.evaluate("[document.getElementById('radv').textContent,document.getElementById('kAvg').textContent,document.getElementById('pxStat').textContent.length]")
    h0 = mh(pg)
    pg.evaluate("(()=>{const r=document.getElementById('rad');r.value=160;r.dispatchEvent(new Event('input',{bubbles:true}))})()")
    pg.wait_for_timeout(2500)
    sl["rad_after"] = pg.evaluate("[document.getElementById('radv').textContent,document.getElementById('kAvg').textContent,document.getElementById('pxStat').textContent.length]")
    sl["rad_map_changed"] = h0 != mh(pg)
    pg.evaluate("(()=>{const r=document.getElementById('rad');r.value=100;r.dispatchEvent(new Event('input',{bubbles:true}))})()")
    pg.wait_for_timeout(1500)
    # op 슬라이더는 '경사색' 켜고 '화살표' 보기일 때 보인다(기존 규칙)
    pg.click("#pxView button[data-v='arrow']"); pg.click("#togsAdv button[data-l='slope']"); pg.wait_for_timeout(500)
    sl["opRowVisible"] = pg.evaluate("getComputedStyle(document.getElementById('opRow')).display")
    h0 = mh(pg)
    pg.evaluate("(()=>{const r=document.getElementById('op');r.value=80;r.dispatchEvent(new Event('input',{bubbles:true}))})()")
    sl["opv"] = pg.evaluate("document.getElementById('opv').textContent")
    sl["op_map_changed"] = h0 != mh(pg)
    pg.evaluate("(()=>{const r=document.getElementById('op');r.value=38;r.dispatchEvent(new Event('input',{bubbles:true}))})()")
    pg.click("#togsAdv button[data-l='slope']"); pg.click("#pxView button[data-v='px']"); pg.wait_for_timeout(800)
    R["sliders"] = sl
    pg.evaluate("document.getElementById('advBox').open=false")

    # 메인 [이미지 저장]
    with pg.expect_download() as dl:
        pg.click("#saveImg")
    d = dl.value; path = f"{OUT}/save_main.png"; d.save_as(path)
    from PIL import Image
    im = Image.open(path); R["saveImg"] = {"file": d.suggested_filename, "size": im.size}
    # 결과뷰 + [저장] + [공유하기]
    pg.click("#chkGo"); pg.wait_for_timeout(1200)
    R["res_open"] = pg.evaluate("getComputedStyle(document.getElementById('res')).display")
    with pg.expect_download() as dl2:
        pg.click("#savePng")
    im2 = Image.open(io.BytesIO(open(dl2.value.path(), "rb").read()))
    R["savePng_res"] = {"file": dl2.value.suggested_filename, "size": im2.size}
    pg.click("#shareBtn"); pg.wait_for_timeout(800)
    R["share_toast"] = pg.evaluate("document.getElementById('toast').textContent")
    pg.click("#resClose"); pg.wait_for_timeout(500)

    # A4 인쇄 — 버튼 경로(window.print 가로채기) → 같은 판으로 PDF
    pg.evaluate("window.__printed=0; window.print=function(){window.__printed++}")
    pg.evaluate("document.getElementById('printA4').scrollIntoView({block:'center'})")
    pg.evaluate("document.getElementById('printA4').click()"); pg.wait_for_timeout(500)
    R["print_called_js_click"] = pg.evaluate("window.__printed")
    pg.evaluate("window.__printed=0")
    pg.click("#printA4"); pg.wait_for_timeout(500)
    R["print_called"] = pg.evaluate("window.__printed")
    pg.emulate_media(media="print")
    R["print_blocks"] = pg.evaluate("""[...document.querySelectorAll('#printSheet>*')].map(e=>{const r=e.getBoundingClientRect();return [e.className, Math.round(r.height/3.7795*10)/10, e.scrollHeight>e.clientHeight+1?'OVER':'ok']})""")
    R["print_sheet_h_mm"] = pg.evaluate("Math.round(document.getElementById('printSheet').getBoundingClientRect().height/3.7795*10)/10")
    R["print_visible_others"] = pg.evaluate("[...document.body.children].filter(e=>e.id!=='printSheet'&&getComputedStyle(e).display!=='none').map(e=>e.tagName+'#'+e.id)")
    R["print_rows"] = pg.evaluate("document.querySelectorAll('#psTbl tbody tr').length")
    R["print_sum"] = pg.evaluate("document.querySelector('#psTbl tr.sum td:last-child').textContent")
    pg.pdf(path=f"{OUT}/print_a4.pdf", prefer_css_page_size=True, print_background=True)
    pg.emulate_media(media="screen")
    R["errors"] = errs[:]
    R["hosts"] = sorted(h for h in hosts if h)

    # 계산 전 버튼 방어 — 새 창에서 바로 누르기
    p2 = ctx.new_page(); p2.route("**/s3.amazonaws.com/**", lambda r: r.abort()); p2.route("https://s3.amazonaws.com/**", lambda r: r.abort())
    p2.goto(URL, wait_until="load"); p2.wait_for_timeout(1500)
    p2.evaluate("window.print=function(){window.__printed=1}")
    p2.click("#printA4"); t1 = p2.evaluate("document.getElementById('toast').textContent")
    p2.click("#saveImg"); t2 = p2.evaluate("document.getElementById('toast').textContent")
    R["before_calc"] = {"print_toast": t1, "save_toast": t2, "printed": p2.evaluate("window.__printed||0")}
    p2.close()

    # 미리보기(무료 3건 소진) 상태 인쇄 — 워터마크 확인
    ctx2 = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, service_workers="block")
    ctx2.add_init_script("""(()=>{const t=new Date(Date.now()+9*3600e3);const d=t.getUTCFullYear()+'-'+('0'+(t.getUTCMonth()+1)).slice(-2)+'-'+('0'+t.getUTCDate()).slice(-2);
      localStorage.setItem('kts_slope_day',d);localStorage.setItem('kts_slope_free','3');localStorage.setItem('kts_slope_cred','0');})()""")
    p3 = ctx2.new_page(); p3.goto(URL, wait_until="load")
    p3.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'", timeout=40000)
    p3.wait_for_timeout(2500)
    pv = p3.evaluate("!document.getElementById('pv').classList.contains('hide')")
    if not pv:
        p3.click("#chips button >> nth=0"); p3.wait_for_timeout(6000)
        pv = p3.evaluate("!document.getElementById('pv').classList.contains('hide')")
    p3.evaluate("window.print=function(){}"); p3.click("#printA4"); p3.wait_for_timeout(500)
    p3.emulate_media(media="print")
    p3.pdf(path=f"{OUT}/print_a4_preview.pdf", prefer_css_page_size=True, print_background=True)
    R["preview_state"] = pv
    # Ctrl+P 경로(버튼 없이 바로 인쇄) — beforeprint 로 같은 판이 채워지는지
    p4 = ctx.new_page(); p4.goto(URL, wait_until="load")
    p4.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'", timeout=40000); p4.wait_for_timeout(2500)
    p4.emulate_media(media="print")
    p4.pdf(path=f"{OUT}/print_a4_ctrlp.pdf", prefer_css_page_size=True, print_background=True)
    R["ctrlp_filled"] = p4.evaluate("document.getElementById('psAddr').textContent")
    br.close()

# PDF 쪽수·크기 + 1쪽 렌더
from pypdf import PdfReader
import pypdfium2 as pdfium
for name in ["print_a4", "print_a4_preview", "print_a4_ctrlp"]:
    rd = PdfReader(f"{OUT}/{name}.pdf"); mb = rd.pages[0].mediabox
    R[name + "_pdf"] = {"pages": len(rd.pages), "size_pt": [round(float(mb.width), 1), round(float(mb.height), 1)]}
    doc = pdfium.PdfDocument(f"{OUT}/{name}.pdf")
    doc[0].render(scale=150 / 72).to_pil().save(f"{OUT}/{name}_1.png")
print(json.dumps(R, ensure_ascii=False, indent=1))

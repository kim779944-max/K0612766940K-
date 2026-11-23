"""134·140·141·142번 검증: 매물장 뷰어 390 실측 · 사진 슬롯 · vcf · 챗봇 · 비공개 · 필터 · 보기 전환 · 빌더 · A4 인쇄 · 콘솔 · 외부 요청."""
import json, sys, os, re, pathlib
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
BASE = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8793/"
SHOTS = sys.argv[3] if len(sys.argv) > 3 else None
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
L = BASE + "listing/"
R = {"console": [], "external": []}
DATA = json.loads(pathlib.Path(sys.argv[4]).read_text(encoding="utf-8")) if len(sys.argv) > 4 else None


def ctx_new(br, w=390, h=844, **kw):
    return br.new_context(viewport={"width": w, "height": h}, device_scale_factor=2, is_mobile=w < 700, has_touch=w < 700,
                          service_workers="block", accept_downloads=True, **kw)


def watch(pg, tag):
    pg.on("console", lambda m: R["console"].append(f"{tag} {m.text[:160]}") if m.type == "error" else None)
    pg.on("pageerror", lambda e: R["console"].append(f"{tag} pageerror {str(e)[:160]}"))
    def req(r):
        u = r.url
        if not (u.startswith(BASE) or u.startswith("data:") or u.startswith("blob:") or u.startswith("file:")):
            R["external"].append(f"{tag} {u[:120]}")
    pg.on("request", req)


MIN_BTN = """(()=>{const els=[...document.querySelectorAll('button,a[role=button],a.btn,.fab a,.toolbtns a,.qchips button,.thumb button,.oitem,.card')].filter(e=>e.offsetParent!==null&&getComputedStyle(e).display!=='none');
const hs=els.map(e=>({h:Math.round(e.getBoundingClientRect().height*10)/10,t:(e.innerText||e.getAttribute('aria-label')||e.className).trim().slice(0,20)}));
hs.sort((a,b)=>a.h-b.h);return {count:hs.length,min:hs[0],low:hs.filter(x=>x.h<44)}})()"""

SLOT = """(()=>{const s=[...document.querySelectorAll('#thumbs > *')];return s.map(e=>{const r=e.getBoundingClientRect();return {tag:e.tagName,top:Math.round(r.top+scrollY),left:Math.round(r.left),h:Math.round(r.height)}})})()"""

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)

    # ── 1. 뷰어 390 ──
    ctx = ctx_new(br, permissions=["clipboard-read", "clipboard-write"])
    pg = ctx.new_page(); watch(pg, "index")
    pg.goto(L, wait_until="networkidle"); pg.wait_for_timeout(600)
    R["sw"] = pg.evaluate("document.documentElement.scrollWidth")
    R["order"] = pg.evaluate("""[...document.querySelectorAll('#sheet > div > *')].filter(e=>getComputedStyle(e).display!=='none').map(e=>(e.className||e.tagName).split(' ').slice(0,2).join('.'))""")
    R["firstScreen"] = pg.evaluate("""[...document.querySelectorAll('#sheet > div > *')].filter(e=>{const r=e.getBoundingClientRect();return getComputedStyle(e).display!=='none'&&r.top<844-64&&r.bottom>48}).map(e=>(e.className||e.tagName).split(' ')[0])""")
    R["stats"] = pg.evaluate("[...document.querySelectorAll('.stat')].map(e=>e.innerText.replace(/\\n+/g,' | '))")
    R["warn"] = pg.evaluate("(document.getElementById('warn')||{}).innerText||null")
    R["calcDetails"] = pg.evaluate("(()=>{const d=document.querySelector('details.calc');d.open=true;return d.innerText})()")
    R["minBtn"] = pg.evaluate(MIN_BTN)
    R["bodyPadBottom"] = pg.evaluate("getComputedStyle(document.body).paddingBottom")
    R["fab"] = pg.evaluate("(()=>{const f=document.querySelector('.fab');const r=f.getBoundingClientRect();return {pos:getComputedStyle(f).position,h:Math.round(r.height),top:Math.round(r.top)}})()")
    R["slots4"] = pg.evaluate(SLOT)
    pg.screenshot(path=f"{OUT}/after_390_top.png")
    if SHOTS:
        pg.screenshot(path=f"{SHOTS}/listing_home.png")
    pg.locator(".overview").scroll_into_view_if_needed(); pg.evaluate("window.scrollBy(0,-60)"); pg.wait_for_timeout(300)
    pg.screenshot(path=f"{OUT}/after_390_mid.png")
    # 스크롤 끝: 하단 바가 본문을 가리는지
    pg.evaluate("window.scrollTo(0,document.documentElement.scrollHeight)"); pg.wait_for_timeout(400)
    R["bottomCover"] = pg.evaluate("(()=>{const f=document.querySelector('.fab').getBoundingClientRect();const n=document.querySelector('.footnote').getBoundingClientRect();return {footnoteBottom:Math.round(n.bottom),fabTop:Math.round(f.top),covered:n.bottom>f.top}})()")
    pg.locator("#broker").scroll_into_view_if_needed(); pg.wait_for_timeout(300)
    pg.screenshot(path=f"{OUT}/after_390_bot.png")
    pg.screenshot(path=f"{OUT}/after_390_full.png", full_page=True)

    # vcf
    with pg.expect_download() as dl:
        pg.click("#vcfBtn")
    d = dl.value; vp = f"{OUT}/{d.suggested_filename}"; d.save_as(vp)
    vt = pathlib.Path(vp).read_bytes().decode("utf-8")
    R["vcf"] = {"file": d.suggested_filename, "firstLine": vt.split("\r\n")[0], "crlf": "\r\n" in vt and "\n" not in vt.replace("\r\n", ""),
                "fields": [x.split(":")[0].split(";")[0] for x in vt.strip().split("\r\n") if x not in ("BEGIN:VCARD", "END:VCARD")], "text": vt}

    # 링크 복사 · 경사도
    pg.click("#copyBtn"); pg.wait_for_timeout(400)
    R["copyToast"] = pg.inner_text("#toast")
    R["clipLink"] = pg.evaluate("navigator.clipboard.readText()")
    with ctx.expect_page() as np_:
        pg.click("#slopeBtn")
    newp = np_.value; newp.wait_for_load_state("domcontentloaded"); pg.wait_for_timeout(500)
    R["slope"] = {"newTab": newp.url, "toast": pg.inner_text("#toast"), "clip": pg.evaluate("navigator.clipboard.readText()"),
                  "attrs": pg.evaluate("[...document.querySelectorAll('.toolbtns a')].map(a=>a.textContent+' '+a.getAttribute('href')+' '+a.target+' '+a.rel)")}
    newp.close()
    # 홈 화면 안내 시트
    pg.click("#homeBtn"); pg.wait_for_timeout(300)
    R["homeSheetOpen"] = pg.evaluate("document.getElementById('homeSheet').open")
    pg.screenshot(path=f"{OUT}/home_sheet_390.png")
    pg.click("#homeSheet [data-close]"); pg.wait_for_timeout(200)
    R["homeSheetClosed"] = not pg.evaluate("document.getElementById('homeSheet').open")

    # 챗봇
    pg.evaluate("window.scrollTo(0,0)")
    R["chips"] = pg.evaluate("[...document.querySelectorAll('#qchips button')].map(b=>b.innerText.trim())")
    known = ["주차 몇 대 돼요?", "수익률 얼마예요?", "층별 임대 현황은요?", "가격이 얼마예요?"]
    unknown = ["재개발 되나요?", "층고는요?", "주차장 지하 있나요?"]
    chat = []
    for q in known + unknown:
        n0 = pg.evaluate("document.querySelectorAll('#log .msg.bot').length")
        pg.fill("#askI", q); pg.press("#askI", "Enter"); pg.wait_for_timeout(150)
        a = pg.evaluate("(()=>{const b=[...document.querySelectorAll('#log .msg.bot')];return b[b.length-1].innerText})()")
        cards = pg.evaluate("document.querySelectorAll('#log .smscard').length")
        chat.append({"q": q, "a": a, "smscards": cards})
    R["chat"] = chat
    pg.fill("#log .smscard:last-child input", "010-1234-5678")
    R["smsHref"] = pg.evaluate("(()=>{const c=[...document.querySelectorAll('#log .smscard')].pop();return {href:c.querySelector('a').href,body:c.querySelector('.body').innerText,fields:[...c.querySelectorAll('dt')].map(x=>x.textContent),mock:c.querySelector('.mock').textContent}})()")
    R["smsHref"]["len"] = len(R["smsHref"]["href"])
    pg.locator("#chat").scroll_into_view_if_needed(); pg.wait_for_timeout(200)
    pg.locator("#chat").screenshot(path=f"{OUT}/chat_390.png")
    ctx.close()

    # ── 2. 사진 2장 매물 · 비공개 매물 ──
    ctx = ctx_new(br); pg = ctx.new_page(); watch(pg, "index?m=BN-2051")
    pg.goto(L + "?m=BN-2051", wait_until="networkidle"); pg.wait_for_timeout(500)
    R["slots2"] = pg.evaluate(SLOT)
    R["warn2051"] = pg.evaluate("(document.getElementById('warn')||{}).innerText||null")
    R["points2051"] = pg.evaluate("[...document.querySelectorAll('.point b')].map(e=>e.textContent)")
    R["unk2051"] = pg.evaluate("document.querySelectorAll('.unk').length")
    pg.screenshot(path=f"{OUT}/after_390_2photo.png")
    pg.goto(L + "?m=BN-2055", wait_until="networkidle"); pg.wait_for_timeout(500)
    R["private"] = pg.evaluate("({title:document.querySelector('h1').textContent,badge:!!document.querySelector('.hero .pv'),chip:(document.querySelector('.chip.pvt')||{}).textContent||null,others:[...document.querySelectorAll('.oitem b')].map(e=>e.textContent)})")
    pg.screenshot(path=f"{OUT}/private_390.png")
    pg.goto(L + "?m=NOPE", wait_until="networkidle"); pg.wait_for_timeout(700)
    R["notFound"] = pg.evaluate("({title:document.querySelector('h1').textContent,toast:document.getElementById('toast').textContent})")
    ctx.close()

    # ── 3. 업자 홈페이지 ──
    ctx = ctx_new(br); pg = ctx.new_page(); watch(pg, "home")
    pg.goto(L + "home.html", wait_until="networkidle"); pg.wait_for_timeout(500)
    H = {}
    cards = lambda: pg.evaluate("[...document.querySelectorAll('#list .card')].map(c=>c.dataset.id+' '+c.querySelector('.t').textContent+' ['+[...c.querySelectorAll('.kv div')].map(d=>d.innerText.replace(/\\n/,' ')).join(' / ')+']')")
    cnt = lambda: pg.inner_text("#cnt")
    H["sw"] = pg.evaluate("document.documentElement.scrollWidth")
    H["start"] = {"count": cnt(), "cards": cards()}
    H["privateInList"] = pg.evaluate("!!document.querySelector('#list [data-id=\"BN-2055\"]')")
    pg.screenshot(path=f"{OUT}/home_390.png")
    pg.screenshot(path=f"{OUT}/home_390_investor.png", full_page=True)
    pg.click("[data-view=use]"); pg.wait_for_timeout(200)
    H["user"] = {"count": cnt(), "cards": cards()}
    pg.screenshot(path=f"{OUT}/home_390_user.png", full_page=True)
    pg.click("[data-view=inv]")
    pg.click("[data-f=p40]"); H["p40"] = {"count": cnt(), "cards": cards()}
    pg.click("[data-f=p40]"); pg.click("[data-f=y6]"); H["y6"] = {"count": cnt(), "cards": cards()}
    pg.click("[data-f=y6]"); pg.click("[data-f=now]"); H["now"] = {"count": cnt(), "cards": cards()}
    pg.click("[data-f=now]"); pg.click("[data-f=p40]"); pg.click("[data-f=y6]")
    H["p40+y6"] = {"count": cnt(), "empty": pg.evaluate("(document.querySelector('.empty')||{}).innerText||null")}
    pg.screenshot(path=f"{OUT}/home_390_empty.png")
    pg.click("#clr2"); H["cleared"] = cnt()
    pg.fill("#maxP", "30"); H["maxP30"] = cnt(); pg.fill("#maxP", "")
    pg.fill("#minY", "9"); H["minY9"] = {"count": cnt(), "cards": cards()}; pg.fill("#minY", "")
    H["minBtn"] = pg.evaluate(MIN_BTN)
    with pg.expect_download() as dl:
        pg.click("#vcf")
    H["vcf"] = dl.value.suggested_filename
    pg.click("#list .card >> nth=0"); pg.wait_for_load_state("networkidle")
    H["cardClick"] = pg.url
    R["home"] = H
    ctx.close()

    # ── 4. 빌더 ──
    ctx = br.new_context(viewport={"width": 1280, "height": 900}, accept_downloads=True, service_workers="block")
    pg = ctx.new_page(); watch(pg, "build")
    pg.goto(L + "build.html", wait_until="networkidle"); pg.wait_for_timeout(1500)
    B = {"checklist0": pg.evaluate("[...document.querySelectorAll('#chk li')].map(l=>l.innerText)")}
    pg.fill("[name=title]", "세아빌딩 리모델링"); pg.fill("[name='p.sale']", "430000"); pg.fill("[name='f.parking']", "3")
    pg.wait_for_timeout(600)
    fr = pg.frame_locator("#pvf")
    B["previewTitle"] = fr.locator("h1").inner_text()
    B["checklist1"] = pg.evaluate("[...document.querySelectorAll('#chk li')].map(l=>l.innerText)")
    pg.screenshot(path=f"{OUT}/build_1280.png")
    with pg.expect_download() as dl:
        pg.click("#save")
    d = dl.value; sp = f"{OUT}/{d.suggested_filename}"; d.save_as(sp)
    B["file"] = d.suggested_filename; B["size"] = os.path.getsize(sp)
    ctx.close()
    ctx = ctx_new(br); pg = ctx.new_page(); ext = []
    pg.on("request", lambda r: ext.append(r.url[:100]) if not (r.url.startswith("file:") or r.url.startswith("data:") or r.url.startswith("blob:")) else None)
    errs = []; pg.on("console", lambda m: errs.append(m.text[:150]) if m.type == "error" else None); pg.on("pageerror", lambda e: errs.append(str(e)[:150]))
    pg.goto(pathlib.Path(sp).resolve().as_uri(), wait_until="load"); pg.wait_for_timeout(800)
    B["reopen"] = pg.evaluate("({title:document.querySelector('h1').textContent,sale:document.querySelector('.stat.s0 strong').textContent,parking:[...document.querySelectorAll('.spec tr')].find(t=>t.querySelector('th').textContent.startsWith('승강기')).querySelector('td').textContent,photos:document.querySelectorAll('#thumbs button').length,imgOk:[...document.images].every(i=>i.complete&&i.naturalWidth>0),theme:!!document.querySelector('.k-theme').textContent})")
    B["reopenExternal"] = ext; B["reopenConsole"] = errs
    pg.screenshot(path=f"{OUT}/build_saved_reopen_390.png")
    R["build"] = B
    ctx.close()

    # ── 5. A4 인쇄 ──
    MM = """(()=>{const mm=v=>Math.round(v/3.7795*10)/10;const s=document.getElementById('sheet');const t=s.getBoundingClientRect().top;
    const q=sel=>{const e=document.querySelector(sel);if(!e)return null;const r=e.getBoundingClientRect();return {top:mm(r.top-t),h:mm(r.height),bottom:mm(r.bottom-t)}};
    return {sheet:q('#sheet'),top:q('.sheet-top'),strip:q('.strip'),stats:q('.stats'),overview:q('.overview'),leases:q('.leases'),points:q('.highlights'),mid:q('.sheet-mid'),broker:q('#broker'),foot:q('.footnote'),
      rows:document.querySelectorAll('.leases tbody tr').length,photos:document.querySelectorAll('.strip img').length,multi:s.classList.contains('multi')}})()"""
    from pypdf import PdfReader
    import pypdfium2 as pdfium
    P = {}
    for mid, name in [("BN-2048", "listing_a4"), ("BN-2051", "print_2photo_5rows"), ("BN-2055", "print_9floors")]:
        ctx = br.new_context(viewport={"width": 718, "height": 1047}, service_workers="block"); pg = ctx.new_page(); watch(pg, "print " + mid)
        pg.goto(L + "?m=" + mid, wait_until="networkidle"); pg.wait_for_timeout(500)
        pg.emulate_media(media="print"); pg.wait_for_timeout(300)
        m = pg.evaluate(MM)
        pg.pdf(path=f"{OUT}/{name}.pdf", prefer_css_page_size=True, print_background=True)
        rd = PdfReader(f"{OUT}/{name}.pdf"); mb = rd.pages[0].mediabox
        texts = [pg_.extract_text() for pg_ in rd.pages]
        doc = pdfium.PdfDocument(f"{OUT}/{name}.pdf")
        pngs = []
        for i in range(len(doc)):
            fn = f"{name}_p{i + 1}.png" if name != "listing_a4" else f"print_a4_{i + 1}.png"
            doc[i].render(scale=150 / 72).to_pil().save(f"{OUT}/{fn}"); pngs.append(fn)
        P[mid] = {"pages": len(rd.pages), "size_pt": [round(float(mb.width), 1), round(float(mb.height), 1)], "measure_mm": m, "png": pngs,
                  "theadOnEachPage": [("호실" in t and "보증금" in t) for t in texts], "brokerOnLastPage": "등록번호" in texts[-1],
                  "rowsPerPage": [len(re.findall(r"\n(?:B0\d|\d0\d|옥상)\s", "\n" + t)) for t in texts]}
        ctx.close()
    R["print"] = P
    br.close()

json.dump(R, open(f"{OUT}/verify.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps(R, ensure_ascii=False, indent=1)[:12000])

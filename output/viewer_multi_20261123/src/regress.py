"""145번 회귀 — 구형 .hwp 안내 카드 · ?f= IndexedDB 진입 · 쇼룸 뒤로가기 가드 · [변환기] · 묶음 인쇄(PDF 쪽수/빈 장) · 메뉴/목록 재캡처.
사용: python -P -X utf8 regress.py <출력 폴더> [URL]
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
URL = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8794/viewer.html"
TS = os.path.join(OUT, "testset")
FILES = sorted(os.path.join(TS, f) for f in os.listdir(TS) if os.path.isfile(os.path.join(TS, f)))
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
R = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block", accept_downloads=True)
    pg = ctx.new_page()
    errs, failed = [], []
    pg.on("requestfailed", lambda r: failed.append(r.url[:120] + " " + str(r.failure)))
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("console", lambda m: errs.append(m.text[:200]) if m.type == "error" and "favicon" not in (m.location or {}).get("url", "") else None)
    pg.goto(URL + "?t=" + str(int(time.time())), wait_until="load"); pg.wait_for_timeout(600)
    R["shopguardState"] = pg.evaluate("history.state && history.state.v")
    R["shopGuardOn"] = pg.evaluate("SHOP_GUARD")

    # 구형 .hwp → 사무실 PC 변환 서버 없음(로컬) → 안내 카드
    hwp = os.path.join(OUT, "dbg", "old.hwp")
    os.makedirs(os.path.dirname(hwp), exist_ok=True)
    open(hwp, "wb").write(b"\xd0\xcf\x11\xe0" + b"\0" * 2000)
    pg.set_input_files("#f", [hwp])
    pg.wait_for_function("PP.kind==='notice'", timeout=40000); pg.wait_for_timeout(400)
    R["hwpNotice"] = {"card": pg.evaluate("!!document.querySelector('#out .ppnotice')"), "noticeMode": pg.evaluate("document.body.classList.contains('ppnoticemode')"),
                      "pbar": pg.evaluate("getComputedStyle(document.getElementById('pbar')).display"), "retryBtn": pg.evaluate("!!document.getElementById('ppRetry')")}
    pg.evaluate("resetView()")

    # 묶음 안의 구형 .hwp — 그 자리에 안내 카드, 나머지는 계속
    pg.set_input_files("#f", [FILES[0], hwp, FILES[20]])
    pg.wait_for_function("!MF.busy && MF.items.length===3", timeout=60000); pg.wait_for_timeout(500)
    R["hwpInBundle"] = pg.evaluate("({kinds:MF.items.map(i=>i.kind),total:MF.total,pgNo:document.getElementById('pgNo').textContent})")
    # 깨진 PDF — 그 자리에 '열지 못했습니다' 카드
    bad = os.path.join(OUT, "dbg", "broken.pdf"); open(bad, "wb").write(b"%PDF-1.4 broken")
    pg.evaluate("resetView()")
    pg.set_input_files("#f", [FILES[0], bad, FILES[1]])
    pg.wait_for_function("!MF.busy && MF.items.length===3", timeout=60000); pg.wait_for_timeout(500)
    R["brokenInBundle"] = pg.evaluate("({kinds:MF.items.map(i=>i.kind),total:MF.total,card:!!document.querySelector('.mfblk .ppnotice h3')})")
    pg.evaluate("resetView()")

    # ?f= IndexedDB 진입로 (변환기에서 넘어오는 길)
    pg.evaluate("""(async()=>{const b=await (await fetch('/viewer.html')).blob();const png=new Blob([new Uint8Array(await (await fetch('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==')).arrayBuffer())],{type:'image/png'});
      await new Promise((ok,no)=>{const rq=indexedDB.open('kts',1);rq.onupgradeneeded=()=>rq.result.createObjectStore('files');rq.onsuccess=()=>{const tx=rq.result.transaction('files','readwrite');tx.objectStore('files').put({blob:png,name:'idb_test.png'},'k145');tx.oncomplete=ok;tx.onerror=no;};rq.onerror=no;});})()""")
    pg.goto(URL + "?f=k145&n=idb_test.png", wait_until="load")
    pg.wait_for_function("document.body.classList.contains('docopen')", timeout=20000); pg.wait_for_timeout(500)
    R["idbEntry"] = pg.evaluate("({name:document.getElementById('vtName').textContent,pgNo:document.getElementById('pgNo').textContent,multi:MF.multi,items:MF.items.length})")

    # [변환기]
    pg.click("#vtConv"); pg.wait_for_load_state("load"); R["convLink"] = pg.url.split("?")[0].rsplit("/", 1)[-1]

    # 묶음 28개 → 메뉴/목록 재캡처 · 인쇄 준비 후 Chrome PDF 출력
    pg.goto(URL + "?t=p" + str(int(time.time())), wait_until="load"); pg.wait_for_timeout(500)
    pg.set_input_files("#f", FILES)
    pg.wait_for_function("!MF.busy && MF.total===34", timeout=120000); pg.wait_for_timeout(800)
    pg.evaluate("goPage(11,false)"); pg.wait_for_timeout(400)
    pg.click("#mfSaveMore"); pg.wait_for_timeout(300)
    pg.screenshot(path=os.path.join(OUT, "after_save_menu.png"))
    R["menuOnTopOfHelper"] = pg.evaluate("""(()=>{const z=getComputedStyle(document.getElementById('mfMenu')).zIndex;const b=document.getElementById('mfSaveZip').getBoundingClientRect();
      const e=document.elementFromPoint(b.left+b.width*0.3,b.top+b.height/2);return {z:z,hitIsZip:!!(e&&e.closest('#mfSaveZip'))}})()""")
    pg.click("#mfSaveMore"); pg.wait_for_timeout(200)
    pg.click("#mfListBtn"); pg.wait_for_timeout(300)
    pg.screenshot(path=os.path.join(OUT, "after_list.png"))
    pg.click("#mfListX")
    pg.evaluate("(()=>{window.__pc=0;window.print=function(){window.__pc++}})()")
    pg.click("#vtPrint"); pg.wait_for_function("window.__pc===1", timeout=60000)
    R["printPrep"] = pg.evaluate("({canvases:document.querySelectorAll('#out canvas').length,pdfPages:MF.items.filter(i=>i.kind==='pdf').reduce((a,i)=>a+i.pages.length,0)})")
    pdfp = os.path.join(OUT, "dbg", "print_multi.pdf")
    pg.pdf(path=pdfp, format="A4", print_background=True)
    from pypdf import PdfReader
    import pypdfium2 as pdfium
    rd = PdfReader(pdfp); doc = pdfium.PdfDocument(pdfp)
    blank = []
    for i in range(len(doc)):
        im = doc[i].render(scale=0.2).to_pil().convert("L"); h = im.histogram(); n = sum(h); m = sum(k * v for k, v in enumerate(h)) / n
        if sum(v * (k - m) ** 2 for k, v in enumerate(h)) / n < 5: blank.append(i + 1)
    R["printPdf"] = {"pages": len(rd.pages), "blank": blank}
    doc[20].render(scale=0.5).to_pil().save(os.path.join(OUT, "dbg", "print_multi_p21.png"))
    pg.evaluate("dispatchEvent(new Event('afterprint'))"); pg.wait_for_timeout(1200)
    R["afterPrintCanvases"] = pg.evaluate("document.querySelectorAll('#out canvas').length")
    R["errors"] = errs
    R["failedRequests"] = failed
    br.close()
json.dump(R, open(os.path.join(OUT, "regress.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps(R, ensure_ascii=False, indent=1))

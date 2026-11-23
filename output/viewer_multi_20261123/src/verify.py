"""145번 검증 — 390×844 · 28개 파일(34장) 한 번에 첨부 · 연속 열람 · 메모리 · PNG/ZIP/PDF 저장 · 추가·목록·삭제 · 1개 파일 회귀.
사용: python -P -X utf8 verify.py <출력 폴더> [URL]
"""
import io, json, os, sys, time, zipfile
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
URL = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8794/viewer.html"
TS = os.path.join(OUT, "testset")
DL = os.path.join(OUT, "downloads")
os.makedirs(DL, exist_ok=True)
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
FILES = sorted(os.path.join(TS, f) for f in os.listdir(TS) if os.path.isfile(os.path.join(TS, f)))
EXTRA = sorted(os.path.join(TS, "extra", f) for f in os.listdir(os.path.join(TS, "extra")))
R = {"files": len(FILES)}

ST = """(()=>({items:MF.items.length,total:MF.total,multi:MF.multi,cur:PP.cur,pgNo:document.getElementById('pgNo').textContent,
 vtName:document.getElementById('vtName').textContent,canvas:document.querySelectorAll('#out canvas').length,
 sw:document.documentElement.scrollWidth,names:MF.items.map(i=>i.name),zoom:Math.round(PP.zoom*1000)/1000,
 pbarH:document.getElementById('pbar').offsetHeight,mName:document.getElementById('mName').textContent}))()"""


def st(pg):
    return pg.evaluate(ST)


def wait_ready(pg, timeout=120000):
    pg.wait_for_function("!MF.busy && document.body.classList.contains('docopen')", timeout=timeout)
    pg.wait_for_timeout(600)


with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True,
                         service_workers="block", accept_downloads=True)
    pg = ctx.new_page()
    errs, hosts, posts, res404 = [], set(), [], []
    pg.on("pageerror", lambda e: errs.append("pageerror " + str(e)[:300]))
    pg.on("console", lambda m: errs.append("console " + m.text[:300]) if m.type == "error" else None)
    pg.on("request", lambda r: (hosts.add(urlparse(r.url).hostname), posts.append(r.url) if r.method not in ("GET", "HEAD") else None))
    pg.on("response", lambda r: res404.append(r.url) if r.status >= 400 else None)
    pg.goto(URL + "?t=" + str(int(time.time())), wait_until="load")
    pg.wait_for_timeout(800)
    pg.evaluate("(()=>{window.__rv=0;const o=URL.revokeObjectURL.bind(URL);URL.revokeObjectURL=function(u){window.__rv++;return o(u)};})()")
    R["inputMultiple"] = pg.evaluate("document.getElementById('f').multiple")

    # ---------- A. 28개(34장) 한 번에 ----------
    t0 = time.time()
    pg.set_input_files("#f", FILES)
    wait_ready(pg)
    R["attach"] = st(pg); R["attach"]["sec"] = round(time.time() - t0, 1)
    R["attach"]["topsStable"] = pg.evaluate("(()=>{const a=PP.tops.slice();mfRelayout();return JSON.stringify(a)===JSON.stringify(PP.tops)&&MF.items.every(i=>PP.tops[i.first]===i.blk.offsetTop)})()")
    R["orderOk"] = R["attach"]["names"] == [os.path.basename(f) for f in FILES]
    pg.screenshot(path=os.path.join(OUT, "after_attach_34.png"))

    # [›] 33회 → 마지막 장
    labels = []
    for i in range(33):
        pg.click("#pgNext"); pg.wait_for_timeout(800)
        labels.append(pg.evaluate("document.getElementById('pgNo').textContent"))
    pg.wait_for_timeout(900)
    R["next33"] = {"last": pg.evaluate("document.getElementById('pgNo').textContent"), "nextDisabled": pg.evaluate("document.getElementById('pgNext').disabled"),
                   "vtName": pg.evaluate("document.getElementById('vtName').textContent"), "seqOk": labels == [f"{i + 2} / 34" for i in range(33)]}
    # 스크롤 감지 — 각 장 위치로 스크롤해서 #pgNo 가 같은 장(±1)인지
    det = pg.evaluate("""(async()=>{const r=[];for(let n=0;n<MF.total;n+=3){out.scrollTop=Math.round((PP.tops[n]+40)*PP.zoom);
      await new Promise(ok=>setTimeout(ok,120));ppTrack();r.push([n,PP.cur]);}return r})()""")
    R["scrollDetect"] = {"checked": len(det), "maxErr": max(abs(a - b) for a, b in det)}

    # 중간: 20번 사진 → 21번 PDF 경계
    pg.evaluate("goPage(20,false)"); pg.wait_for_timeout(400)
    pg.evaluate("out.scrollTop-=260"); pg.wait_for_timeout(900)
    pg.screenshot(path=os.path.join(OUT, "after_scroll_mid.png"))
    R["mid"] = st(pg)

    # 메모리 — 위↔아래 3회 왕복하며 캔버스 개수 최대
    mx = pg.evaluate("""(async()=>{let mx=0;const H=out.scrollHeight;for(let k=0;k<3;k++){for(let y=0;y<=H;y+=500){out.scrollTop=y;
      await new Promise(ok=>setTimeout(ok,90));mx=Math.max(mx,document.querySelectorAll('#out canvas').length);}
      for(let y=H;y>=0;y-=500){out.scrollTop=y;await new Promise(ok=>setTimeout(ok,90));mx=Math.max(mx,document.querySelectorAll('#out canvas').length);}}
      await new Promise(ok=>setTimeout(ok,1500));return {max:mx,after:document.querySelectorAll('#out canvas').length}})()""")
    R["memory"] = mx
    # PDF 장 근처에서 실제로 그려졌는지(빈 장 아님)
    pg.evaluate("goPage(22,false)"); pg.wait_for_timeout(1800)
    R["pdfNear"] = pg.evaluate("(()=>{const g=MF.pages[22];return {kind:g.it.kind,hasCanvas:!!g.it.pages[g.pi].canvas,canvas:document.querySelectorAll('#out canvas').length}})()")

    # ---------- B. 저장 ----------
    pg.evaluate("goPage(11,false)"); pg.wait_for_timeout(500)
    R["at12"] = pg.evaluate("document.getElementById('pgNo').textContent")
    pg.click("#mfSaveMore"); pg.wait_for_timeout(300)
    pg.screenshot(path=os.path.join(OUT, "after_save_menu.png"))
    with pg.expect_download(timeout=60000) as d:
        pg.click("#mfSaveCur")
    dd = d.value; fp = os.path.join(DL, dd.suggested_filename); dd.save_as(fp)
    from PIL import Image
    im = Image.open(fp)
    R["png12"] = {"name": dd.suggested_filename, "size": im.size, "bytes": os.path.getsize(fp)}
    # 지금 장 PNG — PDF 장(23번째)도
    pg.evaluate("goPage(22,false)"); pg.wait_for_timeout(500)
    with pg.expect_download(timeout=60000) as d:
        pg.click("#vtSaveImg")
    dd = d.value; fp = os.path.join(DL, dd.suggested_filename); dd.save_as(fp)
    R["png23pdf"] = {"name": dd.suggested_filename, "size": Image.open(fp).size}
    # 표 장(34번째 · 한글)
    pg.evaluate("goPage(33,false)"); pg.wait_for_timeout(500)
    with pg.expect_download(timeout=60000) as d:
        pg.click("#vtSaveImg")
    dd = d.value; fp = os.path.join(DL, dd.suggested_filename); dd.save_as(fp)
    R["png34hwpx"] = {"name": dd.suggested_filename, "size": Image.open(fp).size}
    Image.open(fp).convert("RGB").resize((397, 562)).save(os.path.join(OUT, "png34_hwpx_small.png"))

    cv0 = pg.evaluate("document.querySelectorAll('#out canvas').length")
    # ZIP
    t0 = time.time()
    with pg.expect_download(timeout=240000) as d:
        pg.click("#mfSaveMore"); pg.wait_for_timeout(200); pg.click("#mfSaveZip")
    dd = d.value; zp = os.path.join(DL, dd.suggested_filename); dd.save_as(zp)
    pg.wait_for_timeout(400)
    pg.screenshot(path=os.path.join(OUT, "after_zip_done.png"))
    with zipfile.ZipFile(zp) as z:
        nl = z.namelist()
    R["zip"] = {"name": dd.suggested_filename, "count": len(nl), "first": nl[:3], "last": nl[-3:], "MB": round(os.path.getsize(zp) / 1048576, 2),
                "sec": round(time.time() - t0, 1), "canvasBefore": cv0, "canvasAfter": pg.evaluate("document.querySelectorAll('#out canvas').length")}
    # PDF
    pg.wait_for_timeout(2200)
    t0 = time.time()
    with pg.expect_download(timeout=300000) as d:
        pg.click("#mfPdfBtn")
    dd = d.value; pp = os.path.join(DL, dd.suggested_filename); dd.save_as(pp)
    pg.wait_for_timeout(400)
    pg.screenshot(path=os.path.join(OUT, "after_pdf_done.png"))
    R["lastPageVisible"] = pg.evaluate("(()=>{const g=MF.pages[MF.total-1],r=(g.it.sheet||g.it.pages[0].el).getBoundingClientRect(),o=out.getBoundingClientRect();return r.bottom>o.top&&r.top<o.bottom})()")
    R["pdf"] = {"name": dd.suggested_filename, "MB": round(os.path.getsize(pp) / 1048576, 2), "sec": round(time.time() - t0, 1),
                "last": pg.evaluate("MF.last"), "canvasAfter": pg.evaluate("document.querySelectorAll('#out canvas').length")}
    from pypdf import PdfReader
    rd = PdfReader(pp)
    sizes = [(round(float(pq.mediabox.width)), round(float(pq.mediabox.height))) for pq in rd.pages]
    R["pdf"]["pages"] = len(rd.pages)
    R["pdf"]["sizes"] = {f"{w}x{h}": sizes.count((w, h)) for (w, h) in sorted(set(sizes))}
    R["pdf"]["landscapePages"] = [i + 1 for i, s in enumerate(sizes) if s[0] > s[1]]
    import pypdfium2 as pdfium
    doc = pdfium.PdfDocument(pp)
    blank = []
    for i in range(len(doc)):
        img = doc[i].render(scale=0.25).to_pil().convert("L")
        hist = img.histogram(); n = sum(hist); mean = sum(k * v for k, v in enumerate(hist)) / n
        var = sum(v * (k - mean) ** 2 for k, v in enumerate(hist)) / n
        if var < 5: blank.append(i + 1)
        if i + 1 in (1, 12, 34):
            doc[i].render(scale=1.0).to_pil().save(os.path.join(OUT, f"pdf_page_{i + 1}.png"))
    R["pdf"]["blankPages"] = blank

    # ---------- 추가 3개 ----------
    pg.evaluate("goPage(5,false)"); pg.wait_for_timeout(400)
    top_before = pg.evaluate("out.scrollTop")
    pg.evaluate("MF.pick='add'")      # [＋] 버튼 = mfPick(true) → 파일 대화상자. 대화상자 대신 같은 플래그로 input 에 넣는다
    pg.set_input_files("#f", EXTRA)
    wait_ready(pg)
    s = st(pg)
    R["append"] = {"items": s["items"], "total": s["total"], "tail": s["names"][-4:], "orderOk": s["names"] == [os.path.basename(f) for f in FILES + EXTRA],
                   "scrollKept": abs(pg.evaluate("out.scrollTop") - top_before) <= 2, "pgNo": s["pgNo"]}
    R["append"]["topsStable"] = pg.evaluate("(()=>{const a=PP.tops.slice();mfRelayout();return JSON.stringify(a)===JSON.stringify(PP.tops)&&MF.items.every(i=>PP.tops[i.first]===i.blk.offsetTop)})()")
    # [＋] 버튼이 실제로 파일 대화상자를 여는지
    with pg.expect_file_chooser(timeout=5000) as fc:
        pg.click("#mfAddBtn")
    R["append"]["plusOpensChooser"] = fc.value.is_multiple()
    fc.value.set_files([])
    pg.evaluate("MF.pick=''")

    # ---------- 목록 · 이동 · 삭제 ----------
    pg.click("#mfListBtn"); pg.wait_for_timeout(400)
    pg.screenshot(path=os.path.join(OUT, "after_list.png"))
    R["list"] = {"rows": pg.evaluate("document.querySelectorAll('#mfRows .mfrow').length"), "sum": pg.evaluate("document.getElementById('mfListSum').textContent")}
    pg.click("#mfRows .mfrow:nth-child(3) .go"); pg.wait_for_timeout(600)
    R["list"]["goto3"] = {"pgNo": pg.evaluate("document.getElementById('pgNo').textContent"), "vtName": pg.evaluate("document.getElementById('vtName').textContent")}
    rv0 = pg.evaluate("window.__rv")
    before = st(pg)
    pg.click("#mfListBtn"); pg.wait_for_timeout(300)
    pg.click("#mfRows .mfrow:nth-child(3) .x"); pg.wait_for_timeout(900)
    after = st(pg)
    R["delete"] = {"items": [before["items"], after["items"]], "total": [before["total"], after["total"]],
                   "orderOk": after["names"] == [n for n in before["names"] if n != "03_사진.png"], "revokeCalls": pg.evaluate("window.__rv") - rv0,
                   "pgNo": after["pgNo"], "listRows": pg.evaluate("document.querySelectorAll('#mfRows .mfrow').length")}
    pg.click("#mfListX"); pg.wait_for_timeout(300)
    pg.screenshot(path=os.path.join(OUT, "after_delete.png"))
    # 블록 머리줄 ✕ 로도 삭제(26번 PDF 가로)
    pg.evaluate("goPage(MF.items[MF.items.length-4].first,false)"); pg.wait_for_timeout(500)
    b2 = st(pg)
    pg.evaluate("MF.items[MF.items.length-4].hd.querySelector('.mfx').click()"); pg.wait_for_timeout(800)
    a2 = st(pg)
    R["deleteHeaderX"] = {"items": [b2["items"], a2["items"]], "total": [b2["total"], a2["total"]]}
    R["sw"] = pg.evaluate("document.documentElement.scrollWidth")

    # 모두 닫기
    rv1 = pg.evaluate("window.__rv")
    pg.click("#mfListBtn"); pg.wait_for_timeout(300)
    pg.click("#mfCloseAll"); pg.wait_for_timeout(700)
    R["closeAll"] = {"docopen": pg.evaluate("document.body.classList.contains('docopen')"), "pbarVisible": pg.evaluate("getComputedStyle(document.getElementById('pbar')).display"),
                     "items": pg.evaluate("MF.items.length"), "revokeCalls": pg.evaluate("window.__rv") - rv1, "outChildren": pg.evaluate("out.children.length")}

    # ---------- 1개 파일 회귀 ----------
    pg.set_input_files("#f", [FILES[0]])
    pg.wait_for_function("document.body.classList.contains('docopen') && document.querySelectorAll('#out .pppage').length===1", timeout=30000)
    pg.wait_for_timeout(800)
    one = st(pg)
    one["mfblk"] = pg.evaluate("document.querySelectorAll('#out .mfblk').length")
    one["kind"] = pg.evaluate("PP.kind")
    z0 = pg.evaluate("PP.zoom")
    # 두 손가락 확대(CDP 터치)
    cdp = ctx.new_cdp_session(pg)
    def touch(t, pts):
        cdp.send("Input.dispatchTouchEvent", {"type": t, "touchPoints": [{"x": x, "y": y, "id": i} for i, (x, y) in enumerate(pts)]})
    touch("touchStart", [(150, 400), (240, 400)])
    for k in range(1, 9):
        touch("touchMove", [(150 - k * 12, 400), (240 + k * 12, 400)])
    touch("touchEnd", [])
    pg.wait_for_timeout(500)
    one["pinchZoom"] = [round(z0, 3), round(pg.evaluate("PP.zoom"), 3)]
    pg.screenshot(path=os.path.join(OUT, "after_1file.png"))
    # 그림 저장(한 파일 = 원래 saveImage → 원본 파일)
    with pg.expect_download(timeout=30000) as d:
        pg.click("#vtSaveImg")
    one["saveName"] = d.value.suggested_filename
    # 더편집 켜고 끄기
    pg.click("#pgEdit"); pg.wait_for_timeout(400)
    one["editOn"] = pg.evaluate("document.body.classList.contains('editing')")
    pg.click("#edDone"); pg.wait_for_timeout(300)
    one["editOff"] = not pg.evaluate("document.body.classList.contains('editing')")
    # 출력 1회
    pg.evaluate("(()=>{window.__pc=0;window.print=function(){window.__pc++}})()")
    pg.click("#vtPrint"); pg.wait_for_timeout(600)
    one["printCalls"] = pg.evaluate("window.__pc")
    one["listRows"] = (pg.click("#mfListBtn"), pg.wait_for_timeout(300), pg.evaluate("document.querySelectorAll('#mfRows .mfrow').length"))[2]
    pg.click("#mfListX")
    R["oneFile"] = one

    # 한 파일 → [＋] 로 1개 더 → 묶음 2개
    pg.evaluate("MF.pick='add'")
    pg.set_input_files("#f", [FILES[20]])
    wait_ready(pg)
    s = st(pg)
    R["oneToMulti"] = {"items": s["items"], "total": s["total"], "names": s["names"], "pgNo": s["pgNo"]}
    # 묶음에서 1개 남게 지우면 한 파일 보기로
    pg.evaluate("MF.items[1].hd.querySelector('.mfx').click()"); pg.wait_for_timeout(1500)
    R["multiToOne"] = {"multi": pg.evaluate("MF.multi"), "pgNo": pg.evaluate("document.getElementById('pgNo').textContent"), "mfblk": pg.evaluate("document.querySelectorAll('#out .mfblk').length")}

    # 묶음 [출력] — 모든 PDF 장이 그려진 뒤 print 1회
    pg.evaluate("resetView()")
    pg.set_input_files("#f", FILES[20:23])
    wait_ready(pg)
    pg.evaluate("(()=>{window.__pc=0;window.print=function(){window.__pc++;window.__pcv=document.querySelectorAll('#out canvas').length}})()")
    pg.click("#vtPrint"); pg.wait_for_timeout(3000)
    R["multiPrint"] = {"printCalls": pg.evaluate("window.__pc"), "canvasAtPrint": pg.evaluate("window.__pcv"), "pdfPages": pg.evaluate("MF.total")}
    pg.emulate_media(media="print")
    pg.pdf if False else None
    pg.emulate_media(media="screen")
    pg.evaluate("dispatchEvent(new Event('afterprint'))")

    # 드래그&드롭(본문) — DataTransfer 로 파일 2개 떨어뜨리기
    n0 = pg.evaluate("MF.items.length")
    pg.evaluate("""(async()=>{const dt=new DataTransfer();for(const n of ['dropA.png','dropB.png']){const c=document.createElement('canvas');c.width=300;c.height=400;
      const g=c.getContext('2d');g.fillStyle='#cde';g.fillRect(0,0,300,400);g.fillStyle='#000';g.font='120px sans-serif';g.fillText(n[4],100,250);
      const b=await new Promise(ok=>c.toBlob(ok,'image/png'));dt.items.add(new File([b],n,{type:'image/png'}));}
      out.dispatchEvent(new DragEvent('dragover',{dataTransfer:dt,bubbles:true,cancelable:true}));
      out.dispatchEvent(new DragEvent('drop',{dataTransfer:dt,bubbles:true,cancelable:true}));})()""")
    wait_ready(pg)
    R["dropBody"] = {"items": [n0, pg.evaluate("MF.items.length")], "tail": pg.evaluate("MF.items.slice(-2).map(i=>i.name)")}
    # 첫 화면 드롭
    pg.evaluate("resetView()"); pg.wait_for_timeout(300)
    pg.evaluate("""(async()=>{const dt=new DataTransfer();for(const n of ['d1.png','d2.png','d3.png']){const c=document.createElement('canvas');c.width=200;c.height=300;
      const b=await new Promise(ok=>c.toBlob(ok,'image/png'));dt.items.add(new File([b],n,{type:'image/png'}));}
      const el=document.getElementById('drop');el.dispatchEvent(new DragEvent('dragover',{dataTransfer:dt,bubbles:true,cancelable:true}));
      el.dispatchEvent(new DragEvent('drop',{dataTransfer:dt,bubbles:true,cancelable:true}));})()""")
    wait_ready(pg)
    R["dropFirst"] = {"items": pg.evaluate("MF.items.length"), "pgNo": pg.evaluate("document.getElementById('pgNo').textContent")}

    # 60개 한도
    pg.evaluate("resetView()"); pg.wait_for_timeout(300)
    pg.evaluate("""(async()=>{const dt=new DataTransfer();const c=document.createElement('canvas');c.width=60;c.height=80;
      const b=await new Promise(ok=>c.toBlob(ok,'image/png'));for(let i=0;i<63;i++)dt.items.add(new File([b],'lim'+i+'.png',{type:'image/png'}));
      const el=document.getElementById('drop');el.dispatchEvent(new DragEvent('drop',{dataTransfer:dt,bubbles:true,cancelable:true}));})()""")
    wait_ready(pg)
    pg.wait_for_timeout(200)
    R["limit60"] = {"items": pg.evaluate("MF.items.length"), "toast": pg.evaluate("(document.querySelector('.toast')||{}).textContent")}
    pg.evaluate("resetView()")
    R["swEnd"] = pg.evaluate("document.documentElement.scrollWidth")

    R["errors"] = errs
    R["hosts"] = sorted(h for h in hosts if h)
    R["nonGet"] = posts
    R["http4xx"] = res404
    br.close()

json.dump(R, open(os.path.join(OUT, "verify.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps(R, ensure_ascii=False, indent=1))

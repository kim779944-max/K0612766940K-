import json, sys
from playwright.sync_api import sync_playwright
CAP = sys.argv[1]
L3 = "[국민카드] 11/22 14:03 스타벅스 강남 5,600원 일시불\n신한카드 11/22 13:20 GS25 역삼점 12,300원 승인\n우리카드 11/22 09:12 이마트 성수점 45,800원 일시불 잔액 320,000원"
out = {}
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = b.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True)
    pg = ctx.new_page()
    errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:8791/gagebu/")
    pg.evaluate("localStorage.removeItem('kts_gagebu_v2')"); pg.reload(); pg.wait_for_timeout(400)
    out["ui"] = pg.evaluate("[document.getElementById('inBuy').tagName, document.getElementById('inBuy').rows, !!document.getElementById('inMore'), document.getElementById('btnPaste').textContent, document.getElementById('btnAdd').textContent]")
    out["parsePaySms"] = pg.evaluate("t=>t.split('\\n').map(l=>window.__GAGEBU_API.parsePaySms(l))", L3)
    # 붙여넣기 버튼 (권한 없음 → 토스트)
    pg.click("#btnPaste"); pg.wait_for_timeout(300)
    out["paste_denied_toast"] = pg.evaluate("document.getElementById('toast').textContent")
    pg.fill("#inBuy", L3)
    pg.evaluate("document.getElementById('inBuy').scrollIntoView({block:'start'})"); pg.wait_for_timeout(200)
    pg.screenshot(path=f"{CAP}/gagebu_01_before_390.png")
    pg.click("#btnAdd"); pg.wait_for_timeout(400)
    out["result"] = pg.evaluate("({count:__GAGEBU.count,sum:__GAGEBU.sum,items:__GAGEBU.items,oneLine:__GAGEBU.oneLine})")
    out["has_320000"] = pg.evaluate("JSON.stringify(localStorage.getItem('kts_gagebu_v2')).indexOf('320000')>=0")
    out["page_text_today"] = pg.evaluate("[...document.querySelectorAll('*')].map(e=>e.childNodes.length===1&&e.textContent.indexOf('품목')>=0&&e.textContent.length<60?e.textContent:null).filter(Boolean).slice(0,6)")
    pg.evaluate("document.getElementById('inBuy').scrollIntoView({block:'start'})"); pg.wait_for_timeout(200)
    pg.screenshot(path=f"{CAP}/gagebu_02_after_390.png")
    # 추가 내용 붙이기
    pg.fill("#inMore", "양파 1.8kg 3900원 하나로마트"); pg.click("#btnMore"); pg.wait_for_timeout(300)
    out["after_more"] = pg.evaluate("[__GAGEBU.count,__GAGEBU.sum,__GAGEBU.items[3]]")
    # paste 이벤트 (textarea 여러 줄)
    pg.evaluate("localStorage.removeItem('kts_gagebu_v2')"); pg.reload(); pg.wait_for_timeout(300)
    pg.evaluate("""t=>{const dt=new DataTransfer();dt.setData('text/plain',t);document.getElementById('inBuy').dispatchEvent(new ClipboardEvent('paste',{clipboardData:dt,bubbles:true,cancelable:true}))}""", L3)
    pg.wait_for_timeout(300)
    out["paste_event"] = pg.evaluate("[__GAGEBU.count,__GAGEBU.sum]")
    out["sw"] = pg.evaluate("document.documentElement.scrollWidth")
    out["errors"] = errs
    b.close()
print(json.dumps(out, ensure_ascii=False, indent=1))

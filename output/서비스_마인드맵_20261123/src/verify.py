"""쇼룸 실측 (390x844) — 지시서 §5-1 항목을 숫자로 뽑고 캡처한다.
usage: python verify.py BASE_URL OUTDIR PREFIX(before|after)"""
import json, sys, time
from playwright.sync_api import sync_playwright

BASE, OUT, PREFIX = sys.argv[1].rstrip('/'), sys.argv[2], sys.argv[3]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

MEAS = r"""(()=>{
 const secs=[...document.querySelectorAll('#sections .sec')];
 const rows=[...document.querySelectorAll('#sections .row')];
 const ks=rows.map(r=>r.getAttribute('data-k')|| (r.querySelector('[data-open]')||{}).getAttribute?.('data-open') || (r.querySelector('a.main')||{}).getAttribute?.('href') || r.textContent.trim().slice(0,12));
 const cnt={}; ks.forEach(k=>cnt[k]=(cnt[k]||0)+1);
 const soon=[...document.querySelectorAll('#sections .row.soon')];
 const H=innerHeight;
 const soonInView=[...document.querySelectorAll('.row.soon')].filter(r=>{const b=r.getBoundingClientRect(); return b.top<H && b.bottom>0 && r.offsetParent!==null;}).length;
 const txt=document.body.innerText;
 const foot=document.querySelector('.foot');
 return {
  sections:secs.length,
  secInfo:secs.map(s=>[(s.querySelector('h2')||{}).textContent, s.querySelectorAll('.row').length]),
  catalogItems:(window.KTS_CATALOG&&window.KTS_CATALOG.items)?window.KTS_CATALOG.items.length:null,
  catalogVer:window.KTS_CATALOG?window.KTS_CATALOG.version:null,
  catalogSrc:window.KTS_CATALOG?window.KTS_CATALOG.source:null,
  products:(window.PRODUCTS||[]).length,
  dupKeys:Object.entries(cnt).filter(([k,v])=>v>1),
  soonRows:soon.length,
  soonAnchors:document.querySelectorAll('#sections .row.soon a').length,
  soonAllAnchors:document.querySelectorAll('.row.soon a').length,
  soonPE:soon.map(r=>getComputedStyle(r).pointerEvents),
  soonOpacity:soon.map(r=>getComputedStyle(r).opacity),
  soonInFirstViewport:soonInView,
  adMagnetCards:document.querySelectorAll('#sections [href*="ad_magnet"],#sections [data-open="ad_magnet"],#sections [data-k="ad_magnet"]').length,
  bungeeCards:document.querySelectorAll('#sections [href*="bungee"],#sections [data-open^="bungee"],#sections [data-k^="bungee"]').length,
  footBungee:foot?foot.querySelectorAll('a[href*="bungee"]').length:null,
  footAdMagnet:foot?foot.querySelectorAll('a[href*="ad_magnet"]').length:null,
  opsVisible:[...document.querySelectorAll('a[href^="ops"]')].filter(a=>a.offsetParent!==null).length,
  photo2docCards:document.querySelectorAll('#sections [data-k="photo2doc"],#sections [data-open="photo2doc"],#sections a[href*="k=photo2doc"]').length,
  taxCards:document.querySelectorAll('#sections [data-k="tax"],#sections [data-open="tax"],#sections a[href*="k=tax"]').length,
  loanCards:document.querySelectorAll('#sections [data-k="loan"],#sections [data-open="loan"]').length,
  saycapCards:document.querySelectorAll('#sections [data-k="saycap"],#sections [data-open="saycap"]').length,
  name_더상세:(txt.match(/더상세/g)||[]).length,
  name_문서변환기:(txt.match(/문서변환기/g)||[]).length,
  name_설명서제작기:(txt.match(/설명서 제작기/g)||[]).length,
  name_답글생성기:(txt.match(/답글생성기/g)||[]).length,
  name_번개알바:(txt.match(/번개알바/g)||[]).length,
  name_갤러리카드:[...document.querySelectorAll('#sections .row .nm')].filter(n=>/갤러리/.test(n.textContent)).length,
  chips:[...document.querySelectorAll('#catChips button')].map(b=>b.textContent.trim()),
  scrollWidth:document.documentElement.scrollWidth
 };})()"""

res = {}
errs, bad, hosts = [], [], set()
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True,
                         has_touch=True, service_workers="block")
    pg = ctx.new_page()
    pg.on("console", lambda m: m.type == "error" and errs.append(m.text))
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("request", lambda r: hosts.add(r.url.split('/')[2] if '://' in r.url else r.url[:20]))
    pg.on("response", lambda r: r.status >= 400 and bad.append(f"{r.status} {r.url}"))
    t = int(time.time())
    pg.goto(f"{BASE}/?t={t}", wait_until="load"); pg.wait_for_timeout(1800)
    pg.screenshot(path=f"{OUT}/{PREFIX}_showroom_top.png")
    res["measure"] = pg.evaluate(MEAS)
    # 커밍순 카드 클릭 10회 → URL 변화
    soon = pg.query_selector_all('#sections .row.soon')
    changes = 0
    if soon:
        soon[0].scroll_into_view_if_needed(); pg.wait_for_timeout(300)
        if PREFIX == "before":
            pg.screenshot(path=f"{OUT}/before_soon_card_click.png")
        for i in range(10):
            u0 = pg.url
            tgt = pg.query_selector_all('#sections .row.soon')[i % 3]
            box = tgt.bounding_box()
            # 카드 제목 영역(왼쪽 1/3) 클릭 — pointer-events:none 이면 아래로 통과
            pg.mouse.click(box["x"] + box["width"] * 0.35, box["y"] + box["height"] / 2)
            pg.wait_for_timeout(350)
            if pg.url != u0:
                changes += 1
                if PREFIX == "before" and changes == 1:
                    pg.wait_for_timeout(900); pg.screenshot(path=f"{OUT}/before_soon_card_click.png")
                pg.goto(f"{BASE}/?t={t}", wait_until="load"); pg.wait_for_timeout(1200)
                pg.query_selector_all('#sections .row.soon')[0].scroll_into_view_if_needed()
    res["soonClickUrlChanges"] = changes
    if PREFIX == "after":
        pg.goto(f"{BASE}/?t={t}", wait_until="load"); pg.wait_for_timeout(1500)
        pg.query_selector_all('#sections .row.soon')[0].scroll_into_view_if_needed(); pg.wait_for_timeout(300)
        pg.screenshot(path=f"{OUT}/after_soon_row.png")
        for n in ['01', '02', '03', '04']:
            pg.evaluate(f"document.getElementById('sec{n}').scrollIntoView({{block:'start'}}); scrollBy(0,-70)")
            pg.wait_for_timeout(250)
            pg.screenshot(path=f"{OUT}/after_section_{n}.png")
        # 칩 필터
        pg.evaluate("scrollTo(0,0)")
        chip = pg.query_selector('#catChips button[data-cat="doc"]')
        chip.scroll_into_view_if_needed(); chip.click(); pg.wait_for_timeout(400)
        vis = pg.evaluate("[...document.querySelectorAll('#sections .sec')].filter(s=>s.offsetParent!==null).map(s=>s.id)")
        pg.evaluate("document.getElementById('catChips').scrollIntoView({block:'start'}); scrollBy(0,-70)")
        pg.wait_for_timeout(250)
        pg.screenshot(path=f"{OUT}/after_chip_filter.png")
        pg.reload(wait_until="load"); pg.wait_for_timeout(1500)
        vis2 = pg.evaluate("[...document.querySelectorAll('#sections .sec')].filter(s=>s.offsetParent!==null).map(s=>s.id)")
        act = pg.evaluate("(document.querySelector('#catChips button.on')||{}).textContent")
        pg.evaluate("document.getElementById('catChips').scrollIntoView({block:'start'}); scrollBy(0,-70)")
        pg.wait_for_timeout(250)
        pg.screenshot(path=f"{OUT}/after_chip_persist.png")
        res["chipFilter"] = {"afterClickVisible": vis, "afterReloadVisible": vis2, "activeChip": act}
        allc = pg.query_selector('#catChips button[data-cat="all"]'); allc.click(); pg.wait_for_timeout(300)
        res["chipAllVisible"] = pg.evaluate("[...document.querySelectorAll('#sections .sec')].filter(s=>s.offsetParent!==null).length")
        pg.evaluate("localStorage.removeItem('kts_cat_chip')")
        # 세이캡 카드
        sc = pg.query_selector('#sections .row[data-k="saycap"]')
        sc.scroll_into_view_if_needed(); pg.evaluate("scrollBy(0,-200)"); pg.wait_for_timeout(250)
        pg.screenshot(path=f"{OUT}/after_saycap_card.png")
        pg.evaluate("scrollTo(0,document.body.scrollHeight)"); pg.wait_for_timeout(300)
        pg.screenshot(path=f"{OUT}/after_no_admagnet_footer.png")
        res["footerText"] = pg.evaluate("(document.querySelector('.foot')||{}).innerText")
    # 커밍순 상세 직접 진입
    pg.goto(f"{BASE}/detail.html?k=append&t={t}", wait_until="load"); pg.wait_for_timeout(1200)
    res["detailAppend"] = pg.evaluate("""(()=>{const o=document.getElementById('open')||document.querySelector('a.open,#openBtn');
      return {url:location.href.replace(/^https?:\\/\\/[^/]+/,''), openHref:o?o.getAttribute('href'):null, openText:o?o.textContent.trim():null,
      hasSoonText:/출시 준비 중/.test(document.body.innerText)};})()""")
    if PREFIX == "after":
        pg.screenshot(path=f"{OUT}/after_detail_append.png")
        for k in ['photo2doc', 'tax', 'thedetail']:
            pg.goto(f"{BASE}/detail.html?k={k}&t={t}", wait_until="load"); pg.wait_for_timeout(1200)
            res[f"detail_{k}"] = {"url": pg.url.replace(BASE, ''), "title": pg.title(),
                                  "더상세": pg.evaluate("(document.body.innerText.match(/더상세/g)||[]).length")}
        pg.goto(f"{BASE}/converter.html?t={t}", wait_until="load"); pg.wait_for_timeout(2500)
        res["converterRedirect"] = pg.url.replace(BASE, '')
        pg.screenshot(path=f"{OUT}/after_converter_redirect.png")
    ctx.close(); br.close()
res["consoleErrors"] = errs
res["http4xx"] = bad
res["hosts"] = sorted(hosts)
print(json.dumps(res, ensure_ascii=False, indent=1))

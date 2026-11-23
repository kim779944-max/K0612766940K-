"""160 오늘의 특가 검증 — 금지 문구·정가 비율·탭·정렬·도매 블록·발주서·넘침·캡처.
python -P -X utf8 v160.py <out_dir> [base_after] [base_before]"""
import json, os, re, sys, urllib.request
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
AFTER = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8791/"
BEFORE = sys.argv[3] if len(sys.argv) > 3 else "http://127.0.0.1:8792/"
TAG = sys.argv[4] if len(sys.argv) > 4 else ""
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
res = {}

src = urllib.request.urlopen(AFTER + "sale/index.html").read().decode("utf-8") + urllib.request.urlopen(AFTER + "sale/data.js").read().decode("utf-8")
res["forbidden"] = {w: src.count(w) for w in ("정가 빼고", "정가 제외", "정가 뺐습니다")}
res["bungaealba_in_source"] = src.count("bungaealba")

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    def ctx():
        return br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    if not TAG:
        c = ctx(); pg = c.new_page(); pg.goto(BEFORE + "sale/"); pg.wait_for_timeout(1500)
        pg.evaluate("localStorage.removeItem('kts_helper_pos_v1')")
        pg.screenshot(path=os.path.join(OUT, "160_before_top.png"))
        res["before"] = pg.evaluate("""(()=>({tabs:[...document.querySelectorAll('#tabs button b')].map(b=>b.textContent),
          kicker:document.querySelector('.kicker').textContent, rowsWithOrg:document.querySelectorAll('.row .pr small').length,
          rows:document.querySelectorAll('.row').length}))()""")
        c.close()

    c = ctx(); pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("console", lambda m: errs.append(m.text[:200]) if m.type == "error" else None)
    reqs = set(); pg.on("request", lambda r: reqs.add(re.sub(r"^(https?://[^/]+).*$", r"\1", r.url)))
    pg.goto(AFTER + "sale/"); pg.wait_for_timeout(1500)
    pg.screenshot(path=os.path.join(OUT, f"160_after_top{TAG}.png"))
    m = pg.evaluate("""(()=>{
      const cards=[...document.querySelectorAll('.g')];
      const withOrg=cards.filter(c=>c.querySelector('.row .org s')&&c.querySelector('.row .pct')).length;
      const noPctButOrg=cards.filter(c=>c.querySelector('.pct')&&!c.querySelector('.org')).length;
      const pcts=[...document.querySelectorAll('#list > .g')].map(c=>Math.max(0,...[...c.querySelectorAll('.pct')].map(x=>+x.textContent.replace(/[^0-9]/g,''))));
      const blk=id=>[...document.querySelectorAll(id+' .g')].map(c=>({nm:c.querySelector('.nm').textContent, src:(c.querySelector('.store')||{}).textContent||'',
          pct:(c.querySelector('.pct')||{}).textContent||'', org:(c.querySelector('.org')||{}).textContent||''}));
      const whbTop=document.getElementById('whb').getBoundingClientRect().top+scrollY, tabsTop=document.getElementById('tabs').getBoundingClientRect().top+scrollY, listTop=document.getElementById('list').getBoundingClientRect().top+scrollY;
      return {cards:cards.length, withOrg, ratio:Math.round(withOrg/cards.length*1000)/10, noPctButOrg,
        tabs:[...document.querySelectorAll('#tabs button')].map(b=>b.querySelector('b').firstChild.textContent.trim()),
        filters:[...document.querySelectorAll('#filters button')].map(b=>b.textContent),
        top5:pcts.slice(0,5), sortedDesc:pcts.every((v,i)=>i==0||pcts[i-1]>=v),
        whole:blk('#whWhole'), ddang:blk('#whDdang'), order:{whbTop,tabsTop,listTop},
        kicker:document.querySelector('.kicker').textContent, h1:document.querySelector('h1').textContent, lead:document.querySelector('.lead').textContent,
        banners:[...document.querySelectorAll('.banners a')].map(a=>a.href), sw:document.documentElement.scrollWidth};})()""")
    m["blockTop5Whole"] = [x["pct"] for x in m["whole"]]; m["blockTop5Ddang"] = [x["pct"] for x in m["ddang"]]
    res["after"] = m
    # 블록 캡처
    pg.evaluate("document.getElementById('whb').scrollIntoView()"); pg.wait_for_timeout(300)
    pg.screenshot(path=os.path.join(OUT, f"160_after_wholesale{TAG}.png"))
    # 카드 확대 (정가 취소선)
    el = pg.locator("#whWhole .g").first
    el.screenshot(path=os.path.join(OUT, f"160_after_card{TAG}.png"))
    # 탭별
    tabs = {}
    for i, nm in enumerate(m["tabs"]):
        pg.click(f"#tabs button:nth-child({i+1})"); pg.wait_for_timeout(250)
        tabs[nm] = pg.evaluate("""(()=>({n:document.querySelectorAll('.g').length, kinds:document.querySelector('#catnote b').textContent}))()""")
    res["tabs"] = tabs
    pg.click("#tabs button:nth-child(1)"); pg.wait_for_timeout(200)
    # 필터
    flt = {}
    for f in ("half", "bogo", "today", "each", "all"):
        pg.click(f'#filters button[data-f="{f}"]'); pg.wait_for_timeout(250)
        flt[f] = pg.evaluate("""(()=>({n:document.querySelectorAll('.g').length, count:document.getElementById('count').textContent,
            minPct:Math.min(...[...document.querySelectorAll('.g')].map(c=>Math.max(0,...[...c.querySelectorAll('.pct')].map(x=>+x.textContent.replace(/[^0-9]/g,'')))))}))()""")
    res["filters"] = flt
    # 발주서: 도매 1 + 땡처리 1 + 편의점 1 담기
    pg.evaluate("scrollTo(0,0)")
    pg.locator("#whWhole .row").first.click(); pg.locator("#whDdang .row").first.click()
    pg.locator("#list .row:not(.off)").first.click(); pg.wait_for_timeout(200)
    res["bar"] = pg.evaluate("[document.getElementById('barCnt').textContent, document.getElementById('barSum').textContent]")
    pg.click("#btnSheet"); pg.wait_for_timeout(400)
    res["sheet"] = pg.evaluate("document.getElementById('sheetText').textContent")
    pg.screenshot(path=os.path.join(OUT, f"160_after_sheet{TAG}.png"))
    res["errors"] = errs; res["origins"] = sorted(reqs)
    c.close(); br.close()

json.dump(res, open(os.path.join(OUT, f"160_verify{TAG}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
a = res["after"]
print(json.dumps({k: v for k, v in res.items() if k not in ("after",)}, ensure_ascii=False, indent=1)[:4000])
print(json.dumps({k: a[k] for k in ("cards", "withOrg", "ratio", "noPctButOrg", "tabs", "filters", "top5", "sortedDesc", "blockTop5Whole", "blockTop5Ddang", "order", "kicker", "h1", "lead", "banners", "sw")}, ensure_ascii=False, indent=1))

"""164 재개발 지번 조회 검증 — 입력 8건 + 숫자 경계 + 넘침·콘솔·캡처 (전 :8792 / 후 :8791)."""
import json, os, sys
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
AFTER = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8791/"
BEFORE = sys.argv[3] if len(sys.argv) > 3 else "http://127.0.0.1:8792/"
TAG = sys.argv[4] if len(sys.argv) > 4 else ""
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
INPUTS = ["번동 411", "개포동 138", "미아동 476", "성사동 715", "성사동 715번지", "번동 999", "411", "번동", "번동 413", "번동 411-2",
          "미아동１２３－４", "번동3-1구역", "미아동 476 (일대)", "138", "476", "15", "4"]

STATE = """(()=>{
 const L=document.getElementById('list');
 const hits=[...L.querySelectorAll(':scope > .item')].map(b=>({nm:b.querySelector('.nm').textContent, badge:(b.querySelector('.jb')||{}).textContent||'', rep:(b.querySelector('.jrep')||{}).textContent||'', src:(b.querySelector('.src')||{}).textContent||''}));
 const same=[...L.querySelectorAll('.jsame .item')].map(b=>({nm:b.querySelector('.nm').textContent, rep:(b.querySelector('.jrep')||{}).textContent||''}));
 return {sum:(L.querySelector('.jsum')||{}).textContent||'', none:(L.querySelector('.jnone')||{}).textContent||'', empty:(L.querySelector('.empty')||{}).textContent||'',
   cnt:document.getElementById('cnt').textContent, nItems:L.querySelectorAll('.item').length, hits:hits.slice(0,6), nHits:hits.length, nSame:same.length, same:same.slice(0,3),
   sameOpen:!!(L.querySelector('.jsame')||{}).open, note:(L.querySelector(':scope > .jnote')||{}).textContent||'',
   more:document.getElementById('more').style.display, sw:document.documentElement.scrollWidth};})()"""


def run(base, inputs, shots):
    out = {}
    with sync_playwright() as p:
        br = p.chromium.launch(executable_path=CHROME, headless=True)
        c = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
        pg = c.new_page(); errs = []
        pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
        pg.on("console", lambda m: errs.append(m.text[:200]) if m.type == "error" else None)
        pg.goto(base + "redev/"); pg.wait_for_function("document.getElementById('cnt').textContent!=='—'", timeout=20000); pg.wait_for_timeout(500)
        pg.evaluate("localStorage.removeItem('kts_helper_pos_v1')")
        for q in inputs:
            pg.fill("#q", q); pg.wait_for_timeout(350)
            st = pg.evaluate(STATE)
            if st["more"] == "block":  # 전체 개수 (더 보기 포함)
                st["cntAll"] = st["cnt"]
            if q == "411":
                st["boundary"] = pg.evaluate("""(()=>{const t=[...document.querySelectorAll('#list .item')].map(b=>b.textContent);
                    return {has1411:t.filter(x=>/1411/.test(x)).length, has4110:t.filter(x=>/4110/.test(x)).length}})()""")
            out[q] = st
            if q in shots:
                if shots[q].get("open"):
                    pg.evaluate("(()=>{const d=document.querySelector('.jsame'); if(d){d.open=true; d.scrollIntoView();}})()"); pg.wait_for_timeout(300)
                else:
                    pg.evaluate("document.getElementById('q').scrollIntoView()"); pg.wait_for_timeout(200)
                pg.screenshot(path=os.path.join(OUT, shots[q]["f"]))
        # 상세 열기 회귀 (번동 411 → 첫 카드)
        pg.fill("#q", "번동 411"); pg.wait_for_timeout(300)
        first = pg.locator("#list .item").first
        if first.count():
            first.click(); pg.wait_for_timeout(500)
            out["_detail"] = pg.evaluate("(()=>{const p=document.getElementById('panel');return {open:getComputedStyle(p).display!=='none'&&p.classList.length>0, cls:p.className, txt:(p.innerText||'').slice(0,120)}})()")
        out["_errors"] = errs
        c.close(); br.close()
    return out


res = {}
if not TAG:
    res["before"] = run(BEFORE, ["번동 411", "개포동 138", "미아동 476", "성사동 715", "번동 999", "411", "번동", "성사동 715번지", "138", "476", "15", "4"],
                        {"번동 411": {"f": "164_before.png"}})
res["after"] = run(AFTER, INPUTS, {"번동 411": {"f": f"164_hit_bundong411{TAG}.png"}, "번동 999": {"f": f"164_none{TAG}.png"},
                                   "번동 413": {"f": f"164_same_dong{TAG}.png", "open": True}})
json.dump(res, open(os.path.join(OUT, f"164_verify{TAG}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
for side in res:
    print("=====", side)
    for q, v in res[side].items():
        if q.startswith("_"): print(q, v); continue
        print(f"[{q}] cnt={v['cnt']} items={v['nItems']} hits={v['nHits']} same={v['nSame']} sum={v['sum'][:70]!r} none={v['none'][:40]!r} sw={v['sw']}",
              [h['nm'][:22] + '|' + h['badge'] + '|' + h['rep'][:24] for h in v['hits'][:3]], v.get('boundary', ''))

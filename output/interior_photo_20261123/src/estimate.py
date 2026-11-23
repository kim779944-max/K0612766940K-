"""견적 회귀 기준값 — 같은 입력으로 전/후 금액 비교.  usage: python estimate.py URL OUT.json"""
import json, sys
from playwright.sync_api import sync_playwright
URL, OUT = sys.argv[1], sys.argv[2]
JS_SET = """([r,g])=>{const st=window.__KTS_INTERIOR().state;
  if(r==='layout'){const b=document.querySelector('#layoutSeg button[data-l="'+g+'"]'); if(st.layout!==g) b.click(); return;}
  const cur=st[r]; if(cur===g) return; const b=document.querySelector('[data-r="'+r+'"] .gr button[data-g="'+(g||cur)+'"]'); b.click();}"""
res = []
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page(); pg.goto(URL, wait_until="load"); pg.wait_for_timeout(800)
    def setv(r, g): pg.evaluate(JS_SET, [r, g])
    def last(): return pg.evaluate("()=>{const L=window.__KTS_INTERIOR().last;return L?{area:L.area,c1:L.c1,c2:L.c2,c3:L.c3,days:L.days}:null}")
    res.append({"case": "기본(4.0×2.4m · 벽 하)", **last()})
    for g in "lmh":
        setv('layout', 'keep'); setv('wall', g); setv('light', '')
        res.append({"case": f"4.0×2.4m · 벽 {g}", **last()})
    pg.click('#modeBtn'); pg.fill('#inPy', '30'); pg.dispatch_event('#inPy', 'input')
    for g in "lmh":
        setv('layout', 'keep'); setv('wall', g); setv('light', g)
        res.append({"case": f"30평 · 벽 {g} + 조명 {g}", **last()})
        setv('layout', 'move'); setv('furn', g)
        res.append({"case": f"30평 · 벽 {g} + 조명 {g} + 배치 바꾸기 가구 {g}", **last()})
    br.close()
json.dump(res, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
for r in res: print(json.dumps(r, ensure_ascii=False))

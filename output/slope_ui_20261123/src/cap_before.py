"""경사도 변경 전 캡처 — 390x844 위에서 2화면 + 지도 카드 위치 실측."""
import json, sys, time
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
URL = sys.argv[2] if len(sys.argv) > 2 else "https://autooneclick.com/slope/?t=%d" % int(time.time())
PREFIX = sys.argv[3] if len(sys.argv) > 3 else "before"
MEAS = """(()=>{const m=document.getElementById('mapCard').getBoundingClientRect(),c=document.getElementById('mapcv').getBoundingClientRect();
const card=document.getElementById('mapCard'); const vis=[...card.querySelectorAll('button,input[type=range]')].filter(b=>{if(b.closest('.mapwrap')||b.closest('#arch'))return false;const r=b.getBoundingClientRect();return r.width>0&&r.height>0});
return {mapCardTop:Math.round(m.top*10)/10,mapcvH:c.height,mapcvW:c.width,sw:document.documentElement.scrollWidth,
 visibleCtl:vis.length,ctl:vis.map(b=>(b.id||b.getAttribute('data-l')||b.getAttribute('data-v')||b.getAttribute('data-s')||b.textContent.trim().slice(0,8))+':'+Math.round(b.getBoundingClientRect().height))}})()"""
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page()
    pg.goto(URL, wait_until="load"); pg.wait_for_timeout(6000)
    m = pg.evaluate(MEAS)
    pg.screenshot(path=f"{OUT}/{PREFIX}_390_1.png")
    pg.evaluate("scrollTo(0,844)"); pg.wait_for_timeout(800)
    pg.screenshot(path=f"{OUT}/{PREFIX}_390_2.png")
    print(json.dumps(m, ensure_ascii=False))
    br.close()

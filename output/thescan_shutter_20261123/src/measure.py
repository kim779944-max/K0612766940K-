"""더스캔 셔터 실측 — 지시서 §3-1 측정 스크립트 그대로 + 캡처.
usage: python measure.py OUTDIR URL PREFIX"""
import json, sys
from playwright.sync_api import sync_playwright

OUT, URL, PREFIX = sys.argv[1], sys.argv[2], sys.argv[3]
MEAS = """(()=>{ const r=document.querySelector('#btnShoot').getBoundingClientRect();
  const vv=window.visualViewport;
  const H=vv?vv.height:innerHeight;
  const pts=[0.15,0.5,0.85].map(f=>{const x=r.left+r.width*f, y=r.top+r.height/2;
    const el=document.elementFromPoint(x,y); return el? (el.closest('#btnShoot')?'btnShoot':(el.id||el.className)) : 'none';});
  return {mode:document.body.classList.contains('live')?'live':'static',
    vh:innerHeight, vvH:Math.round(H),
    top:+r.top.toFixed(1), bottom:+r.bottom.toFixed(1), h:+r.height.toFixed(1),
    inside:(r.top>=0 && r.bottom<=H+0.5),
    aboveToolbar128: r.bottom <= H-128,
    scrollH:document.documentElement.scrollHeight,
    noScroll: document.documentElement.scrollHeight <= H+1,
    topmost:pts,
    capboxH:+document.querySelector('#capbox').getBoundingClientRect().height.toFixed(1),
    capboxLive:document.querySelector('#capbox').classList.contains('live'),
    sw:document.documentElement.scrollWidth,
    appW:+document.querySelector('#app').getBoundingClientRect().width.toFixed(1),
    appL:+document.querySelector('#app').getBoundingClientRect().left.toFixed(1)};
})()"""
TB = """(()=>{const tb=document.createElement('div');tb.id='tb128';
tb.style.cssText='position:fixed;left:0;right:0;bottom:0;height:128px;background:rgba(0,0,0,.85);z-index:999;pointer-events:none';
document.body.appendChild(tb);})()"""
res = []
errs = []
hosts = set()
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True,
        args=["--use-fake-device-for-media-stream", "--use-fake-ui-for-media-stream"])
    def run(w, h, live, shot=None, toolbar=False, mobile=True):
        ctx = br.new_context(viewport={"width": w, "height": h}, device_scale_factor=2 if mobile else 1,
                             is_mobile=mobile, has_touch=mobile, service_workers="block", permissions=["camera"])
        pg = ctx.new_page()
        pg.on("console", lambda m: m.type == "error" and errs.append(m.text))
        pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.on("request", lambda r: hosts.add(r.url.split('/')[2] if '://' in r.url else r.url[:20]))
        pg.goto(URL, wait_until="load"); pg.wait_for_timeout(2500)
        if live:
            pg.click('#btnLive'); pg.wait_for_timeout(2500)
        if toolbar: pg.evaluate(TB)
        m = pg.evaluate(MEAS); m["vp"] = f"{w}x{h}"; m["toolbar"] = toolbar
        if shot: pg.screenshot(path=f"{OUT}/{shot}")
        res.append(m); ctx.close()
    run(390, 844, False, f"{PREFIX}_390_static.png")
    run(390, 844, True, f"{PREFIX}_390_live.png")
    run(390, 844, True, f"{PREFIX}_390_live_toolbar128.png", toolbar=True)
    run(390, 740, True)
    run(390, 716, True, f"{PREFIX}_390_live_716.png" if PREFIX == "after" else None)
    run(390, 640, True)
    run(390, 560, True, f"{PREFIX}_390_live_560.png" if PREFIX == "after" else None)
    run(1280, 800, False, mobile=False)
    run(1280, 800, True, f"{PREFIX}_1280_live.png" if PREFIX == "after" else None, mobile=False)
    br.close()
for m in res: print(json.dumps(m, ensure_ascii=False))
print("ERRORS", errs)
print("HOSTS", sorted(hosts))

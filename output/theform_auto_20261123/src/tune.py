"""자동 빈칸 튜닝: 표준 양식 배경을 내 양식처럼 얹고 자동 감지 → 표준 양식의 칸 좌표(정답)와 맞대 본다."""
import json, sys
from playwright.sync_api import sync_playwright
URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8792/theform/"
OUT = sys.argv[2] if len(sys.argv) > 2 else None
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
JS = """async ([pid, src]) => {
  const im = new Image(); await new Promise(r => { im.onload = r; im.src = src; });
  const gt = TF.BUILT.find(f => f.id === pid).fields.filter(f => !f.pg || f.pg === 1);
  TF.CUR = {id:'tune' + pid, name:'시험', fields:[]}; TF.BG = im; TF.go(2);
  const r = TF.autoDetectFields();
  const hit = d => gt.some(g => { const cx = d.x + d.w / 2, cy = d.y + d.h / 2; return cx >= g.x - 1 && cx <= g.x + g.w + 1 && cy >= g.y - 1 && cy <= g.y + g.h + 1; });
  const covered = g => r.fields.some(d => { const cx = d.x + d.w / 2, cy = d.y + d.h / 2; return cx >= g.x - 1 && cx <= g.x + g.w + 1 && cy >= g.y - 1 && cy <= g.y + g.h + 1; });
  const fp = r.fields.filter(d => !hit(d));
  return {n:r.fields.length, ms:r.ms, nH:r.nH, nV:r.nV, kinds:r.kinds, gt:gt.length, gtCovered:gt.filter(covered).length, fp:fp.length,
    fpList:fp.map(d => [d.k, d.x, d.y, d.w, d.h]).join(' | '), miss:gt.filter(g => !covered(g)).map(g => g.label).join(','),
    png:(() => { const c = document.createElement('canvas'); c.width = 900; c.height = Math.round(900 * im.height / im.width); const g = c.getContext('2d'); g.drawImage(im, 0, 0, c.width, c.height);
      g.lineWidth = 2; r.fields.forEach(d => { g.strokeStyle = hit(d) ? '#FF6B00' : '#DC2626'; g.fillStyle = hit(d) ? 'rgba(255,107,0,.18)' : 'rgba(220,38,38,.35)';
        const X = d.x / 100 * c.width, Y = d.y / 100 * c.height, W = d.w / 100 * c.width, H = d.h / 100 * c.height; g.fillRect(X, Y, W, H); g.strokeRect(X, Y, W, H); });
      return c.toDataURL('image/png'); })()};
}"""
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    pg = br.new_page(viewport={"width": 390, "height": 844}, device_scale_factor=2)
    errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto(URL, wait_until="load"); pg.wait_for_timeout(800)
    res = {}
    for pid, src in [("p_sale", "tpl_sale.png"), ("p_lease", "tpl_lease.png"), ("p_power", "tpl_power.png"), ("p_exchange", "tpl_exchange.png")]:
        r = pg.evaluate(JS, [pid, src])
        import base64
        png = r.pop('png')
        if OUT: open(f"{OUT}/tune_{pid}.png", 'wb').write(base64.b64decode(png.split(',')[1]))
        res[pid] = r
    print(json.dumps(res, ensure_ascii=False, indent=1)[:8000]); print("errors", errs)
    br.close()

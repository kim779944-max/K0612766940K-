import sys,json
from playwright.sync_api import sync_playwright
url=sys.argv[1]; js=sys.argv[2]; w=int(sys.argv[3]) if len(sys.argv)>3 else 390; mob=(sys.argv[4]=='1') if len(sys.argv)>4 else False
with sync_playwright() as p:
  b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
  c=b.new_context(viewport={'width':w,'height':844},is_mobile=mob,has_touch=True)
  pg=c.new_page(); errs=[]; pg.on('pageerror',lambda e:errs.append(str(e)))
  pg.goto(url,wait_until='networkidle'); pg.wait_for_timeout(800)
  print(json.dumps(pg.evaluate(js),ensure_ascii=False,indent=0)[:5000]); print('pageerrors',errs)

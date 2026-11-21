import json,sys,os,urllib.parse
from playwright.sync_api import sync_playwright
TAG=sys.argv[1]; BASE=sys.argv[2]; SH=os.path.join(os.path.dirname(__file__),'..','shots')
with sync_playwright() as p:
  b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True); R={}
  for w in (390,360):
    c=b.new_context(viewport={'width':w,'height':844},is_mobile=True,has_touch=True); pg=c.new_page(); errs=[]; pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto(BASE+'/',wait_until='networkidle'); pg.wait_for_timeout(600)
    R[f'show_{w}']=pg.evaluate("""(()=>{const a=[...document.querySelectorAll('.row')].find(r=>/ad_magnet/.test(r.innerHTML)); a.scrollIntoView({block:'center'}); const r=a.getBoundingClientRect(); const nm=a.querySelector('.nm span')||a.querySelector('.nm');
       const sub=a.querySelector('.sub'); return {h:Math.round(r.height), nm:nm.textContent, nmClipped: nm.scrollWidth>nm.clientWidth+1, sub: sub&&sub.textContent, subClipped: sub? sub.scrollWidth>sub.clientWidth+1:null, tail:[...document.querySelectorAll('a[href="ad_magnet/"]')].map(x=>x.textContent)}})()""")
    pg.wait_for_timeout(200); pg.screenshot(path=os.path.join(SH,f'E1_showAdRow_{w}_{TAG}.jpg'),type='jpeg',quality=65)
    pg.goto(BASE+'/ad_magnet/',wait_until='networkidle'); pg.wait_for_timeout(600)
    R[f'ad_{w}']=pg.evaluate("""(()=>{const h=document.querySelector('.hd h1'); const cs=getComputedStyle(h); return {title:document.title, h1:h.innerText, h1H:Math.round(h.getBoundingClientRect().height), lineH:cs.lineHeight, oneLine: h.getBoundingClientRect().height < parseFloat(cs.fontSize)*1.3*1.6,
       foot:[...document.querySelectorAll('footer, .foot, body')].map(x=>x.innerText).join(' ').match(/KTS 어벤져스 [^·]*·/)?.[0], sms:[...document.querySelectorAll('a[href^="sms:"]')].map(a=>decodeURIComponent(a.getAttribute('href').split('body=')[1]||'')), docW:document.documentElement.scrollWidth}})()""")
    pg.screenshot(path=os.path.join(SH,f'E2_adHeader_{w}_{TAG}.jpg'),type='jpeg',quality=65,clip={'x':0,'y':0,'width':w,'height':160})
    R[f'errs_{w}']=errs; c.close()
  print(json.dumps(R,ensure_ascii=False,indent=1))

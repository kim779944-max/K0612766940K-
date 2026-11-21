import json,sys,os
from playwright.sync_api import sync_playwright
TAG=sys.argv[1]; BASE=sys.argv[2]; SH=os.path.join(os.path.dirname(__file__),'..','shots')
with sync_playwright() as p:
  b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
  R={}
  for w,h in [(390,844),(360,800)]:
    c=b.new_context(viewport={'width':w,'height':h},is_mobile=True,has_touch=True); pg=c.new_page(); errs=[]; pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto(BASE+'/gagebu/',wait_until='networkidle'); pg.wait_for_timeout(500)
    empty=pg.evaluate("({concl:document.getElementById('concl').textContent, visible: !!document.getElementById('concl').offsetParent})")
    for t in ['양파 1.8kg 3900원 하나로마트','양파 1.8kg 2900원 동네마트','우유 1L 2980원 편의점','우유 1L 2480원 하나로마트']:
      pg.fill('#inBuy',t); pg.click('#btnAdd'); pg.wait_for_timeout(250)
    pg.evaluate("scrollTo(0,0)"); pg.wait_for_timeout(300)
    r=pg.evaluate("""(()=>{const c=document.getElementById('concl'),a=document.getElementById('assume'),d=document.getElementById('detail');const rc=c.getBoundingClientRect(), ra=a.getBoundingClientRect();
      return {concl:c.textContent, inOneBox: !!c.closest('#oneBox'), inDetail: !!c.closest('#detail'), visible: !!c.offsetParent, conclBottom: Math.round(rc.bottom), innerH: innerHeight,
              assumeFont: getComputedStyle(a).fontSize, assumeVisible: !!a.offsetParent, detailHidden: d.hidden, dupInDetail: d.innerText.indexOf('줄일 수 있습니다')>=0,
              api: window.__GAGEBU && window.__GAGEBU.concl, docW: document.documentElement.scrollWidth}})()""")
    r['empty']=empty; r['errs']=errs; R[w]=r
    pg.screenshot(path=os.path.join(SH,f'D1_gagebu_{w}_{TAG}.jpg'),type='jpeg',quality=70)
    c.close()
  print(json.dumps(R,ensure_ascii=False,indent=1))

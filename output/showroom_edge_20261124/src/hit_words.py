import json, re, sys
from playwright.sync_api import sync_playwright
BASE = sys.argv[1]
JS = r"""(() => { var b=document.querySelector('#kts-helper-btn'); if(!b) return null; b=b.getBoundingClientRect(); var out=[];
 document.querySelectorAll('button,input,textarea,table,.acts,a[href],select').forEach(function(e){ if(e.id==='kts-helper-btn')return;
  var r=e.getBoundingClientRect(); if(!r.width||r.top>innerHeight||r.bottom<0)return; var cs=getComputedStyle(e); if(cs.display==='none'||cs.visibility==='hidden')return;
  var w=Math.min(b.right,r.right)-Math.max(b.left,r.left),h=Math.min(b.bottom,r.bottom)-Math.max(b.top,r.top);
  if(w>0&&h>0) out.push((e.tagName+':'+(e.textContent||e.value||'').trim()).slice(0,30)); }); return out; })()"""
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe")
    for path in ['/index.html', '/index.html#cat-biz', '/theform/index.html', '/contract/index.html', '/sign/index.html', '/listing/build.html']:
        pg = br.new_page(viewport={'width':390,'height':844}, is_mobile=True, has_touch=True)
        pg.goto(BASE + path); pg.wait_for_timeout(4000)
        H = pg.evaluate('document.documentElement.scrollHeight'); hits = set()
        for y in range(0, max(1, H-844)+1, 200):
            pg.evaluate('scrollTo(0,%d)' % y); pg.wait_for_timeout(750)
            r = pg.evaluate(JS) or []; hits |= set(r)
        bad = [h for h in hits if re.search('저장|인쇄|결제|PDF|내보내기|구매|신청', h)]
        print(path, 'H=', H, 'hits=', sorted(hits)[:12], 'BAD=', bad)
        pg.close()
    br.close()

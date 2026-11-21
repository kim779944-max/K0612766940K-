import sys,re
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
    pg=b.new_page(viewport={'width':390,'height':844}); pg.goto('http://127.0.0.1:8791/hogang/',wait_until='networkidle'); pg.wait_for_function('window.__HOGANG')
    for L in ('0','12'):
        pg.evaluate("(L)=>{const e=document.querySelector('#iLeft');e.value=L;e.dispatchEvent(new Event('change'));}",L)
        t=pg.evaluate('document.body.innerText'); s=pg.evaluate("document.querySelector('#yr24 summary').innerText")
        lines=[l for l in t.split('\n') if '2년 총액' in l]; print(L,lines, 'without summary:', '2년 총액' in t.replace(s,''))
        print(' six-digit+ numbers:', sorted(set(re.findall(r'\d{1,3}(?:,\d{3}){2,}',t))))
    b.close()

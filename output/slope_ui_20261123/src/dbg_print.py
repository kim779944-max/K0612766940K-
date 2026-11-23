from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    br=p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",headless=True)
    for mobile in (False,True):
        ctx=br.new_context(viewport={"width":390,"height":844},is_mobile=mobile,has_touch=mobile)
        pg=ctx.new_page(); pg.goto("http://127.0.0.1:8791/slope/",wait_until="load")
        pg.wait_for_function("document.getElementById('kEl').textContent.trim()[0]!=='—'",timeout=40000)
        pg.evaluate("window.__st=[];window.print=function(){window.__st.push(new Error().stack.split(String.fromCharCode(10)).slice(1,4).join(' | '))}")
        pg.evaluate("document.getElementById('printA4').click()"); pg.wait_for_timeout(300)
        print(mobile,'js',pg.evaluate("window.__st"))
        pg.evaluate("window.__st=[]"); pg.click("#printA4"); pg.wait_for_timeout(300)
        print(mobile,'pw',pg.evaluate("window.__st"))
        ctx.close()
    br.close()

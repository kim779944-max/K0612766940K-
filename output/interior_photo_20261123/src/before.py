import json, sys
from playwright.sync_api import sync_playwright
URL, OUT = sys.argv[1], sys.argv[2]
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page(); pg.goto(URL, wait_until="load"); pg.wait_for_timeout(1000)
    pg.evaluate("document.querySelector('#secSample').scrollIntoView()"); pg.wait_for_timeout(300)
    pg.screenshot(path=OUT + "/before_390_room_svg.png")
    m = pg.evaluate("""()=>({scene:__KTS_INTERIOR().state.scene, tabOn:document.querySelector('#sceneTabs .tab.on').textContent,
      badge:!!document.querySelector('#sampleBadge')&&!document.querySelector('#sampleBadge').hidden,
      domyeon:(document.body.innerText.match(/도면/g)||[]).length, sw:document.documentElement.scrollWidth,
      kn:(r=>[r.width,r.height])(document.querySelector('#baSample .kn').getBoundingClientRect())})""")
    open(OUT + "/measure_before.json", "w", encoding="utf-8").write(json.dumps(m, ensure_ascii=False, indent=1))
    br.close()

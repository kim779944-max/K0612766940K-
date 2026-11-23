"""URL 을 열고 JSON 응답(API) 목록과 본문 일부를 저장 — 상품 API 찾기용."""
import json, sys, os
from playwright.sync_api import sync_playwright

url, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
seen = []
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    pg = br.new_page(viewport={"width": 1280, "height": 900}, user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36")
    def on_resp(r):
        ct = r.headers.get("content-type", "")
        if "json" in ct:
            try:
                b = r.body()
            except Exception:
                return
            i = len(seen); seen.append({"i": i, "url": r.url, "len": len(b)})
            open(os.path.join(out, f"r{i:03d}.json"), "wb").write(b)
    pg.on("response", on_resp)
    pg.goto(url, wait_until="load", timeout=60000); pg.wait_for_timeout(5000)
    for _ in range(4):
        pg.mouse.wheel(0, 3000); pg.wait_for_timeout(1200)
    open(os.path.join(out, "page.txt"), "w", encoding="utf-8").write(pg.inner_text("body"))
    br.close()
json.dump(seen, open(os.path.join(out, "index.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
for s in seen: print(s["i"], s["len"], s["url"][:160])

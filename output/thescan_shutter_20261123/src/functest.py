"""더스캔 기능 회귀 — 실시간 자동촬영 / 끄기 / 권한거부 / 연결·분리·전체저장.
usage: python functest.py OUTDIR URL"""
import json, sys, os
from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright
OUT, URL = sys.argv[1], sys.argv[2]
# 합성 '종이' 스트림: 어두운 책상 위 흰 A4 사각형
FAKE = """(()=>{const c=document.createElement('canvas');c.width=720;c.height=960;const x=c.getContext('2d');
function d(){x.fillStyle='#3a3226';x.fillRect(0,0,720,960);x.fillStyle='#f4f4ef';x.beginPath();x.moveTo(110,130);x.lineTo(620,110);x.lineTo(640,850);x.lineTo(90,860);x.closePath();x.fill();
x.fillStyle='#222';for(let i=0;i<14;i++)x.fillRect(160,200+i*44,380-(i%3)*60,10);}
d();setInterval(d,100);const s=c.captureStream(15);
navigator.mediaDevices.getUserMedia=async()=>s;})()"""
DENY = """navigator.mediaDevices.getUserMedia=async()=>{throw new DOMException('Permission denied','NotAllowedError')};"""
tmp = os.path.join(OUT, "src", "_pages"); os.makedirs(tmp, exist_ok=True)
files = []
for i in range(2):
    im = Image.new("RGB", (900, 1200), (60, 50, 40)); dr = ImageDraw.Draw(im)
    dr.polygon([(120, 140), (780, 120), (800, 1080), (100, 1090)], fill=(245, 245, 240))
    for k in range(16): dr.rectangle([180, 220 + k * 50, 600 - (k % 3) * 80, 232 + k * 50], fill=(30, 30, 30))
    p = os.path.join(tmp, f"page{i+1}.jpg"); im.save(p, quality=92); files.append(p)
R = {}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    def ctx(init):
        c = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True,
                           service_workers="block", accept_downloads=True)
        if init: c.add_init_script(init)
        pg = c.new_page(); errs = []
        pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.on("console", lambda m: m.type == "error" and errs.append(m.text))
        pg.goto(URL, wait_until="load"); pg.wait_for_timeout(2000)
        return c, pg, errs
    st = "()=>({bodyLive:document.body.classList.contains('live'),capLive:document.querySelector('#capbox').classList.contains('live'),gal:getComputedStyle(document.querySelector('.gal')).display,count:document.querySelector('#gcount').textContent,label:document.querySelector('#btnLive').textContent.trim(),scrollH:document.documentElement.scrollHeight,bodyOv:getComputedStyle(document.body).overflow,toast:document.querySelector('#toast').textContent})"
    # 1) 실시간 + 자동 촬영
    c, pg, errs = ctx(FAKE)
    pg.evaluate("document.querySelector('#btnLive').click()"); pg.wait_for_timeout(3000)
    R["live_3s"] = pg.evaluate(st)
    pg.wait_for_timeout(4000); R["live_7s"] = pg.evaluate(st)
    pg.screenshot(path=f"{OUT}/after_390_live_autocapture.png")
    pg.evaluate("document.querySelector('#btnLive').click()"); pg.wait_for_timeout(800)
    R["after_stop"] = pg.evaluate(st)
    pg.evaluate("scrollTo(0,9999)"); R["after_stop_scrollY"] = pg.evaluate("scrollY")
    R["live_errors"] = [e for e in errs if '404' not in e]; R["live_404"] = [e for e in errs if '404' in e]; c.close()
    # 2) 권한 거부
    c, pg, errs = ctx(DENY)
    pg.evaluate("document.querySelector('#btnLive').click()"); pg.wait_for_timeout(500)
    R["denied"] = pg.evaluate(st)
    R["denied_shutterTop"] = pg.evaluate("document.querySelector('#btnShoot').getBoundingClientRect().top"); c.close()
    # 3) 사진첩 2장 → 연결(긴 이미지/PDF) · 분리 · 전체 저장
    c, pg, errs = ctx(None)
    pg.set_input_files('#fFile', files); pg.wait_for_function("document.querySelector('#gcount').textContent==='2장'", timeout=30000)
    dl = []
    def grab(fn):
        with pg.expect_download(timeout=20000) as d: fn()
        dl.append(d.value.suggested_filename)
    pg.evaluate("document.querySelector('#btnJoin').click()"); pg.wait_for_timeout(400)
    grab(lambda: pg.evaluate("document.querySelector('#goJoin').click()")); pg.wait_for_timeout(800)
    pg.evaluate("closeSheet()")
    pg.evaluate("document.querySelector('#btnJoin').click()"); pg.wait_for_timeout(400)
    pg.evaluate("document.querySelector('#sheet .opt[data-f=pdf]').click()")
    grab(lambda: pg.evaluate("document.querySelector('#goJoin').click()")); pg.wait_for_timeout(800)
    pg.evaluate("closeSheet()")
    pg.evaluate("document.querySelector('#btnSplit').click()"); pg.wait_for_timeout(400)
    pg.evaluate("document.querySelectorAll('#pl .pick').forEach(x=>{if(!x.classList.contains('sel'))x.click()})")
    grab(lambda: pg.evaluate("document.querySelector('#goSplit').click()")); pg.wait_for_timeout(1500)
    pg.evaluate("closeSheet()")
    grab(lambda: pg.evaluate("document.querySelector('#btnAll').click()")); pg.wait_for_timeout(1500)
    R["downloads"] = dl; R["file_errors"] = [e for e in errs if '404' not in e]; c.close()
    br.close()
print(json.dumps(R, ensure_ascii=False, indent=1))

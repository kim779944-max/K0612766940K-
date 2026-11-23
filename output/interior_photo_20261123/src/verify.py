"""인테리어 실사 비포/애프터 검증 (지시서 §4) — 390×844 · 캡처 · 픽셀 비교.
usage: python verify.py URL OUTDIR"""
import json, re, sys
from playwright.sync_api import sync_playwright

URL, OUT = sys.argv[1], sys.argv[2]
R = {}
errs, hosts, posts, codes = [], set(), [], {}

DIFF = """async ([scene, zone])=>{
  const reg = await (await fetch('regions.json?v=x')).json();
  const r = reg.photos[scene];
  const im = new Image(); im.src = r.file; await im.decode();
  const o = document.createElement('canvas'); o.width=1200; o.height=900; const og=o.getContext('2d'); og.drawImage(im,0,0,1200,900);
  const O = og.getImageData(0,0,1200,900).data;
  const A = document.querySelector('#baSample canvas.af').getContext('2d').getImageData(0,0,1200,900).data;
  function mask(pts){const c=document.createElement('canvas');c.width=1200;c.height=900;const g=c.getContext('2d');g.beginPath();
    pts.forEach((p,i)=>i?g.lineTo(p[0],p[1]):g.moveTo(p[0],p[1]));g.closePath();g.fillStyle='#fff';g.fill();return g.getImageData(0,0,1200,900).data;}
  const Z = mask(r[zone]);
  const mats = reg.materials.filter(m=>m.zone===zone);
  const m = mats.find(x=>x.id===window.__KTS_INTERIOR().mat[zone]);
  const bundleKeys = {'걸레받이':'base','몰딩':'mold'};
  const B = (m.bundle||[]).filter(n=>bundleKeys[n]&&r[bundleKeys[n]]).map(n=>mask(r[bundleKeys[n]]));
  let inN=0,inC=0,outN=0,outC=0,outNB=0,outCB=0;
  for(let i=0;i<O.length;i+=4){
    const ch = Math.max(Math.abs(O[i]-A[i]),Math.abs(O[i+1]-A[i+1]),Math.abs(O[i+2]-A[i+2]))>10;
    if(Z[i+3]>=128){inN++; if(ch)inC++;}
    else {outN++; if(ch)outC++; if(!B.some(b=>b[i+3]>=128)){outNB++; if(ch)outCB++;}}
  }
  return {scene, zone, mat:m.id, inRate:+(inC/inN*100).toFixed(2), outRate:+(outC/outN*100).toFixed(2),
          outRateExclBundle:+(outCB/outNB*100).toFixed(3), bundle:m.bundle, inPx:inN, outPx:outN};
}"""

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page()
    pg.on("console", lambda m: m.type == "error" and errs.append(m.text))
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("request", lambda r: (hosts.add(r.url.split('/')[2] if '://' in r.url else r.url[:16]), r.method == 'POST' and posts.append(r.url)))
    pg.on("response", lambda r: codes.__setitem__(r.url.split('?')[0].split('/interior/')[-1], r.status))
    pg.goto(URL, wait_until="load"); pg.wait_for_timeout(1500)

    def shot(name, sel='#secSample'):
        pg.evaluate(f"document.querySelector('{sel}').scrollIntoView()"); pg.wait_for_timeout(250)
        pg.screenshot(path=f"{OUT}/{name}")

    def clip(sel='#baSample'):
        return pg.evaluate(f"document.querySelector('{sel} canvas.af').style.clipPath")

    def mat(scene, ids):
        pg.click(f'#sceneTabs .tab[data-s="{scene}"]'); pg.wait_for_timeout(150)
        cur = pg.evaluate("__KTS_INTERIOR().mat")
        for v in cur.values():
            if v: pg.click(f'#matBox button[data-m="{v}"]'); pg.wait_for_timeout(80)
        for m in ids: pg.click(f'#matBox button[data-m="{m}"]'); pg.wait_for_timeout(80)
        pg.wait_for_function("__KTS_INTERIOR().sampleOk"); pg.wait_for_timeout(700)

    # 첫 화면
    R['first'] = pg.evaluate("""()=>({scene:__KTS_INTERIOR().state.scene, tabs:[...document.querySelectorAll('#sceneTabs .tab')].map(t=>t.textContent),
      tabOn:document.querySelector('#sceneTabs .tab.on').textContent, sampleBadge:!!document.querySelector('#sampleBadge'),
      domyeon:(document.body.innerText.match(/도면/g)||[]).length, svgImgs:document.querySelectorAll('svg').length,
      svgShellRef:/svgShell/.test(document.documentElement.innerHTML), photoReady:__KTS_INTERIOR().photoReady,
      regions:__KTS_INTERIOR().regions, sampleOk:__KTS_INTERIOR().sampleOk, layoutOk:__KTS_INTERIOR().layoutOk,
      exLine:document.querySelector('#exLine').textContent, sw:document.documentElement.scrollWidth})""")
    shot("after_390_living_50.png")

    # 슬라이더: 마우스 끌기 0 → 100 → 50
    box = pg.locator('#baSample').bounding_box()
    cy = box['y'] + box['height'] / 2
    sl = {}
    pg.mouse.move(box['x'] + box['width'] / 2, cy); pg.mouse.down()
    pg.mouse.move(box['x'] - 40, cy, steps=6); sl['drag_to_0'] = [pg.evaluate("__KTS_INTERIOR().gauge"), clip()]
    shot("after_390_living_0.png")
    pg.mouse.move(box['x'] + box['width'] + 40, cy, steps=8); sl['drag_to_100'] = [pg.evaluate("__KTS_INTERIOR().gauge"), clip()]
    shot("after_390_living_100.png")
    pg.mouse.move(box['x'] + box['width'] / 2, cy, steps=6); pg.mouse.up(); sl['drag_to_50'] = [pg.evaluate("__KTS_INTERIOR().gauge"), clip()]
    pg.focus('#baSample'); pg.keyboard.press('End'); pg.keyboard.press('ArrowRight'); sl['key_End_Right'] = pg.evaluate("__KTS_INTERIOR().gauge")
    pg.keyboard.press('Home'); pg.keyboard.press('ArrowLeft'); sl['key_Home_Left'] = pg.evaluate("__KTS_INTERIOR().gauge")
    pg.evaluate("(()=>{const r=document.querySelector('#rngSample');r.value=-20;r.dispatchEvent(new Event('input'))})()"); sl['rng_-20'] = pg.evaluate("__KTS_INTERIOR().gauge")
    pg.evaluate("(()=>{const r=document.querySelector('#rngSample');r.value=101;r.dispatchEvent(new Event('input'))})()"); sl['rng_101'] = pg.evaluate("__KTS_INTERIOR().gauge")
    for pos in (0, 100, 50):
        pg.evaluate(f"(()=>{{const r=document.querySelector('#rngSample');r.value={pos};r.dispatchEvent(new Event('input'))}})()")
        knr = pg.evaluate("""()=>{const k=document.querySelector('#baSample .kn').getBoundingClientRect(),b=document.querySelector('#baSample').getBoundingClientRect();
          const hit=document.elementFromPoint(k.left+k.width/2,k.top+k.height/2);
          return {w:k.width,h:k.height,left:+k.left.toFixed(1),right:+k.right.toFixed(1),boxL:+b.left.toFixed(1),boxR:+b.right.toFixed(1),
                  inScreen:k.left>=0&&k.right<=innerWidth, hitIsKnob:!!(hit&&hit.closest('.kn'))}}""")
        sl[f'knob_at_{pos}'] = knr
    sl['touchAction'] = pg.evaluate("[getComputedStyle(document.querySelector('#baSample')).touchAction, getComputedStyle(document.querySelector('#baSample .kn')).touchAction]")
    R['slider'] = sl

    # 자재 5종(거실) + 픽셀 비교
    diffs = []
    for m, z in [("denbar", "wall"), ("marble", "wall"), ("wallpaper", "wall"), ("tile", "wall"), ("floor", "floor")]:
        mat("living", [m]); diffs.append(pg.evaluate(DIFF, ["living", z]))
        shot(f"after_mat_{m}.png")
    mat("room", ["denbar"]); diffs.append(pg.evaluate(DIFF, ["room", "wall"])); shot("after_room_mat_denbar.png")
    # 원룸 콘센트 keep 확인
    R['room_outlet_kept'] = pg.evaluate("""async()=>{const im=new Image();im.src='img/ba_room.jpg';await im.decode();const c=document.createElement('canvas');c.width=1200;c.height=900;
      const g=c.getContext('2d');g.drawImage(im,0,0);const O=g.getImageData(821,586,25,35).data;const A=document.querySelector('#baSample canvas.af').getContext('2d').getImageData(821,586,25,35).data;
      let d=0;for(let i=0;i<O.length;i+=4)if(Math.abs(O[i]-A[i])>10||Math.abs(O[i+1]-A[i+1])>10||Math.abs(O[i+2]-A[i+2])>10)d++;return {changedPx:d,totalPx:O.length/4};}""")
    mat("shop", ["marble"]); diffs.append(pg.evaluate(DIFF, ["shop", "wall"])); shot("after_shop_mat_marble.png")
    for sc in ("room", "shop"):
        mat(sc, ["floor"]); diffs.append(pg.evaluate(DIFF, [sc, "floor"]))
    R['diff'] = diffs
    with open(f"{OUT}/diff_wall_in_out.txt", "w", encoding="utf-8") as f:
        f.write("# 시공 후 캔버스 vs 원본 사진 — 픽셀 변화(어느 채널이든 차이 > 10) 비율 %\n")
        f.write("# inRate = 자재 다각형 안 / outRate = 다각형 밖 전체 / outRateExclBundle = 다각형 밖에서 묶음 띠(걸레받이·몰딩) 제외\n")
        for d in diffs:
            f.write(f"{d['scene']:7} {d['zone']:5} {d['mat']:10} in {d['inRate']:6.2f}%  out {d['outRate']:5.2f}%  out(묶음 제외) {d['outRateExclBundle']:6.3f}%  bundle={','.join(d['bundle']) or '-'}  (in {d['inPx']}px / out {d['outPx']}px)\n")

    # 묶음 표시: 덴바보드 + 강마루
    mat("living", ["denbar", "floor"])
    R['bundle'] = pg.evaluate("""()=>({badges:[...document.querySelectorAll('#matBox .mt button')].map(b=>[b.dataset.m,(b.querySelector('.bd')||{}).textContent||'']),
       line:document.querySelector('#bundleTxt').textContent})""")
    shot("after_bundle_badge.png", '#matBox')

    # 저장 버튼(다운로드 파일명)
    with pg.expect_download() as dl:
        pg.click('#svSample')
    R['save'] = dl.value.suggested_filename

    # 가구 배치
    lay = {}
    for pos in (0, 100, 50):
        pg.evaluate(f"(()=>{{const r=document.querySelector('#rngLayout');r.value={pos};r.dispatchEvent(new Event('input'))}})()")
        lay[pos] = [pg.evaluate("__KTS_INTERIOR().layoutGauge"), clip('#baLayout')]
        if pos in (0, 100): shot(f"after_layout_{pos}.png", '#secLayout')
    lay['labels'] = pg.evaluate("[document.querySelector('#layLbA').textContent,document.querySelector('#layLbB').textContent]")
    lay['note'] = pg.evaluate("document.querySelector('#secLayout .cap').textContent")
    lay['sizes'] = pg.evaluate("""async()=>{const o={};for(const f of ['img/living_setA.jpg','img/living_setB.jpg']){const i=new Image();i.src=f;await i.decode();o[f]=[i.naturalWidth,i.naturalHeight];}return o;}""")
    # 자재를 바꿔도 배치 캔버스는 그대로인지
    h1 = pg.evaluate("document.querySelector('#baLayout canvas.af').toDataURL().length")
    mat("living", ["marble"])
    h2 = pg.evaluate("document.querySelector('#baLayout canvas.af').toDataURL().length")
    lay['independentOfMaterial'] = h1 == h2
    R['layout'] = lay

    # 견적 3안 화면
    shot("after_estimate.png", '#secCalc')
    # 인쇄 — window.print 를 막고 printArea 를 PDF(A4)로
    pg.evaluate("window.print=function(){window.__printed=(window.__printed||0)+1}")
    pg.click('#prBtn'); pg.wait_for_timeout(800)
    R['print'] = pg.evaluate("({printed:window.__printed||0, img:!!document.querySelector('#printArea img'), imgLen:(document.querySelector('#printArea img')||{src:''}).src.length, text:document.querySelector('#printArea pre').textContent.slice(0,60)})")
    pdf = pg.pdf(format="A4", print_background=True)
    open(f"{OUT}/after_print.pdf", "wb").write(pdf)
    R['print']['pdfPages'] = len(re.findall(rb'/Type\s*/Page[^s]', pdf))
    pg.emulate_media(media="print"); pg.wait_for_timeout(300)
    pg.screenshot(path=f"{OUT}/after_print.png", full_page=True)
    pg.emulate_media(media="screen")

    R['final'] = pg.evaluate("({sw:document.documentElement.scrollWidth, domyeon:(document.body.innerText.match(/도면/g)||[]).length})")
    br.close()

R['console_errors'] = errs
R['hosts'] = sorted(hosts)
R['posts'] = posts
R['http'] = {k: v for k, v in codes.items() if k.startswith('img/') or k.startswith('regions')}
R['http_not_200'] = {k: v for k, v in codes.items() if v >= 400}
open(f"{OUT}/verify.json", "w", encoding="utf-8").write(json.dumps(R, ensure_ascii=False, indent=1))
print(json.dumps(R, ensure_ascii=False, indent=1))

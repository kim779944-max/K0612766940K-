"""158 품질 확인 — 같은 표 사진을 원본 converter.html(이관 전)과 더양식 ② 탭(이관 후)에 넣어
hwpx·xlsx 를 뽑고, 열 너비·병합·배경색을 파일 안에서 꺼내 비교한다.
usage: python conv_compare.py BASE_URL ORIG_PATH OUTDIR"""
import json, os, re, sys, zipfile
from PIL import Image, ImageDraw, ImageFont
from playwright.sync_api import sync_playwright

BASE, ORIG, OUT = sys.argv[1].rstrip('/'), sys.argv[2], sys.argv[3]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
os.makedirs(OUT, exist_ok=True)

# ── 시험 표 사진: 열 너비 3:2:1:2 · 머리 2칸 병합 · 머리 배경색 ──
img_p = os.path.join(OUT, 'test_table.png')
W, H = 1200, 520
im = Image.new('RGB', (W, H), 'white'); d = ImageDraw.Draw(im)
try: F = ImageFont.truetype(r'C:\Windows\Fonts\malgunbd.ttf', 30)
except Exception: F = ImageFont.load_default()
x0, y0 = 60, 60
cw = [420, 280, 140, 280]; rh = 80
xs = [x0]; [xs.append(xs[-1] + c) for c in cw]
ys = [y0 + i * rh for i in range(6)]
d.rectangle([xs[0], ys[0], xs[-1], ys[1]], fill=(255, 214, 170))            # 머리 배경
d.rectangle([xs[0], ys[1], xs[-1], ys[2]], fill=(214, 228, 250))            # 둘째 줄 배경
for y in ys: d.line([xs[0], y, xs[-1], y], fill='black', width=3)
for i, x in enumerate(xs):
    d.line([x, ys[1] if i == 1 else ys[0], x, ys[-1]], fill='black', width=3)  # 첫 줄 0~1열 병합
txt = [['거래명세서 품목', None, '수량', '금액'], ['품명', '규격', '개', '원'],
       ['사과', '5kg', '3', '45,000'], ['배', '7.5kg', '2', '58,000'], ['합계', '', '5', '103,000']]
for r, row in enumerate(txt):
    for c, t in enumerate(row):
        if t is None: continue
        x1 = xs[c + 2] if (r == 0 and c == 0) else xs[c + 1]
        d.text(((xs[c] + x1) / 2, (ys[r] + ys[r + 1]) / 2), t, fill='black', font=F, anchor='mm')
im.save(img_p)

def analyse(path):
    z = zipfile.ZipFile(path); names = z.namelist(); out = {'files': len(names)}
    if path.endswith('.xlsx'):
        sh = z.read('xl/worksheets/sheet1.xml').decode('utf-8')
        out['cols'] = re.findall(r'<col [^>]*width="([\d.]+)"', sh)
        out['merges'] = re.findall(r'<mergeCell ref="([A-Z0-9:]+)"', sh)
        st = z.read('xl/styles.xml').decode('utf-8')
        out['fills'] = sorted(set(re.findall(r'fgColor rgb="([0-9A-Fa-f]{6,8})"', st)))
    else:
        sec = [n for n in names if re.search(r'section0\.xml$', n)]
        x = z.read(sec[0]).decode('utf-8') if sec else ''
        out['cellWidths'] = re.findall(r'<hp:cellSz width="(\d+)"', x)[:12]
        out['spans'] = [s for s in re.findall(r'<hp:cellSpan colSpan="(\d+)" rowSpan="(\d+)"', x) if s != ('1', '1')]
        hd = z.read('Contents/header.xml').decode('utf-8') if 'Contents/header.xml' in names else ''
        out['fills'] = sorted(set(re.findall(r'faceColor="(#[0-9A-Fa-f]{6})"', hd)))
    return out

res = {}; errs = []
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    for label, url, framed in [('orig', f'{BASE}/{ORIG}', False), ('theform', f'{BASE}/theform/?tab=convert', True)]:
        ctx = br.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=2, is_mobile=True, has_touch=True,
                             accept_downloads=True, service_workers='block')
        pg = ctx.new_page()
        pg.on('pageerror', lambda e, l=label: errs.append(f'{l}: {e}'))
        pg.on('console', lambda m, l=label: m.type == 'error' and errs.append(f'{l}: {m.text}'))
        pg.goto(url, wait_until='load'); pg.wait_for_timeout(2500)
        if framed:
            pg.screenshot(path=os.path.join(OUT, '..', 'captures', 'after_theform_convert_tab.png'))
            fr = pg.frame_locator('#cvFrame')
            fh = pg.query_selector('#cvFrame').content_frame()
        else:
            fr = pg; fh = pg.main_frame
        fh.set_input_files('#file', img_p)
        # 변환 화면(#work)에 표가 그려질 때까지
        fh.wait_for_function("document.querySelector('#pvTable') && document.querySelector('#pvTable').querySelectorAll('td,th').length>0", timeout=120000)
        pg.wait_for_timeout(4000)
        pg.screenshot(path=os.path.join(OUT, f'{label}_work.png'))
        res[label] = {}
        for kind, btn in [('hwpx', '#btnHwpx'), ('xlsx', '#btnXlsx')]:
            with pg.expect_download(timeout=60000) as dl:
                fh.evaluate("s => document.querySelector(s).click()", btn)   # 화면 버튼과 같은 onclick
            f = os.path.join(OUT, f'{label}.{kind}'); dl.value.save_as(f)
            res[label][kind] = analyse(f); res[label][kind]['bytes'] = os.path.getsize(f)
            pg.wait_for_timeout(1500)
            pg.screenshot(path=os.path.join(OUT, f'{label}_after_{kind}.png'))
            # 저장 후 결과 화면이 뜨면 변환 화면으로 되돌아가기
            try:
                if fh.is_visible('#btnResBack'): fh.click('#btnResBack'); pg.wait_for_timeout(800)
            except Exception: pass
        res[label]['cells'] = fh.evaluate("[...document.querySelectorAll('#pvTable td,#pvTable th')].length")
        ctx.close()
    br.close()
same = {k: {f: res['orig'][k][f] == res['theform'][k][f] for f in res['orig'][k] if f != 'bytes'} for k in ('hwpx', 'xlsx')}
print(json.dumps({'result': res, 'same': same, 'errors': errs}, ensure_ascii=False, indent=1))

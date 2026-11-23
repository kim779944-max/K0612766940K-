"""145번 테스트셋 — 28개 파일 = 34장 (사진 PNG 20 · PDF 6×2쪽 · 엑셀 xlsx 1 · 한글 hwpx 1).
파일명 앞 번호 = 첨부 순서. 사진·PDF 쪽마다 큰 번호(전체 장 번호)를 박아 어느 장인지 눈으로 구분한다.
추가 첨부 테스트용 3개(extra/): 사진 2 + PDF 1쪽 1 → 37개 파일.
사용: python -P -X utf8 make_testset.py <출력 폴더>
"""
import io, os, sys, zipfile
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
EXTRA = os.path.join(OUT, "extra")
os.makedirs(EXTRA, exist_ok=True)
for d in (OUT, EXTRA):
    for f in os.listdir(d):
        if os.path.isfile(os.path.join(d, f)):
            os.remove(os.path.join(d, f))

FONT = r"C:\Windows\Fonts\malgunbd.ttf"
def font(sz):
    try:
        return ImageFont.truetype(FONT, sz)
    except Exception:
        return ImageFont.load_default()

COLORS = ["#FFE8D6", "#DDF3FF", "#E6FFDD", "#F3E5FF", "#FFF6CC"]

def card(w, h, big, sub, color):
    im = Image.new("RGB", (w, h), color)
    g = ImageDraw.Draw(im)
    g.rectangle([20, 20, w - 21, h - 21], outline="#333333", width=6)
    f1 = font(int(min(w, h) * 0.42))
    bb = g.textbbox((0, 0), big, font=f1)
    g.text(((w - (bb[2] - bb[0])) / 2 - bb[0], (h - (bb[3] - bb[1])) / 2 - bb[1] - h * 0.05), big, fill="#111111", font=f1)
    f2 = font(int(min(w, h) * 0.06))
    bb = g.textbbox((0, 0), sub, font=f2)
    g.text(((w - (bb[2] - bb[0])) / 2, h * 0.78), sub, fill="#333333", font=f2)
    # 모서리 표시 — 저장본이 잘리지 않았는지 확인용
    for (x, y) in [(40, 40), (w - 90, 40), (40, h - 90), (w - 90, h - 90)]:
        g.rectangle([x, y, x + 50, y + 50], fill="#FF6B00")
    return im

plan = []   # (파일명, 장수, 형식)
page_no = 0
fno = 0

# 1~20: 사진 PNG 1200×1600
for i in range(20):
    fno += 1; page_no += 1
    name = f"{fno:02d}_사진.png"
    card(1200, 1600, str(page_no), f"파일 {fno} · 사진 · 전체 {page_no}장째", COLORS[i % 5]).save(os.path.join(OUT, name))
    plan.append((name, 1, "PNG 1200×1600"))

# 21~26: PDF 2쪽 (A4 비율 · 26번은 가로 A4 — 가로 장 전환 확인)
for k in range(6):
    fno += 1
    land = (k == 5)
    w, h = (1754, 1240) if land else (1240, 1754)   # 150dpi A4
    pages = []
    for j in range(2):
        page_no += 1
        pages.append(card(w, h, str(page_no), f"파일 {fno} · PDF {j + 1}/2쪽 · 전체 {page_no}장째" + (" · 가로" if land else ""), "#FFFFFF"))
    name = f"{fno:02d}_PDF{'_가로' if land else ''}.pdf"
    pages[0].save(os.path.join(OUT, name), "PDF", resolution=150.0, save_all=True, append_images=pages[1:])
    plan.append((name, 2, "PDF 2쪽" + (" (가로 A4)" if land else " (A4)")))

def zwrite(path, files):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for n, s in files.items():
            z.writestr(n, s.encode("utf-8"))

# 27: 엑셀 xlsx (A4 1장 분량 · inlineStr)
fno += 1; page_no += 1
rows = []
hdr = ["번호", "품목", "수량", "단가", "금액", "비고"]
def c(ref, v):
    if isinstance(v, (int, float)):
        return f'<c r="{ref}"><v>{v}</v></c>'
    return f'<c r="{ref}" t="inlineStr"><is><t>{v}</t></is></c>'
cols = "ABCDEF"
rows.append('<row r="1">' + "".join(c(f"{cols[i]}1", hdr[i]) for i in range(6)) + "</row>")
for r in range(2, 26):
    q = r * 3; u = 1000 + r * 250
    vals = [r - 1, f"테스트 품목 {r - 1}", q, u, q * u, f"{page_no}장째 엑셀"]
    rows.append(f'<row r="{r}">' + "".join(c(f"{cols[i]}{r}", vals[i]) for i in range(6)) + "</row>")
sheet = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
         '<sheetData>' + "".join(rows) + '</sheetData></worksheet>')
name = f"{fno:02d}_엑셀.xlsx"
zwrite(os.path.join(OUT, name), {
    "[Content_Types].xml": '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
    "_rels/.rels": '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    "xl/workbook.xml": '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>',
    "xl/_rels/workbook.xml.rels": '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
    "xl/worksheets/sheet1.xml": sheet,
})
plan.append((name, 1, "XLSX 25행×6열"))

# 28: 한글 hwpx (A4 1장 분량)
fno += 1; page_no += 1
paras = [f"한글 hwpx 테스트 문서 — 전체 {page_no}장째"] + [f"{i}. 더뷰 다중 첨부 검증용 문단입니다. 순서·장수·저장 확인." for i in range(1, 26)]
HP = 'xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph" xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"'
sec = ('<?xml version="1.0" encoding="UTF-8"?><hs:sec ' + HP + '>' +
       "".join(f'<hp:p paraPrIDRef="0"><hp:run charPrIDRef="0"><hp:t>{t}</hp:t></hp:run></hp:p>' for t in paras) + '</hs:sec>')
name = f"{fno:02d}_한글.hwpx"
zwrite(os.path.join(OUT, name), {
    "mimetype": "application/hwp+zip",
    "Contents/section0.xml": sec,
})
plan.append((name, 1, "HWPX 문단 26개"))

# 추가 첨부용 3개
for i in range(2):
    card(1200, 1600, f"+{i + 1}", f"추가 첨부 사진 {i + 1}", "#E0E7FF").save(os.path.join(EXTRA, f"29_추가사진{i + 1}.png"))
card(1240, 1754, "+3", "추가 첨부 PDF 1쪽", "#FFFFFF").save(os.path.join(EXTRA, "31_추가PDF.pdf"), "PDF", resolution=150.0)

tot = sum(p[1] for p in plan)
print(f"파일 {len(plan)}개 · {tot}장")
for p in plan:
    print(" ", p[0], p[1], p[2])
assert len(plan) == 28 and tot == 34

"""shots/listing_home.png — 상세 페이지용 '준비 중' 미리보기(780×1388). 실제 화면 캡처가 아님을 그림 안에 적는다."""
import sys
from PIL import Image, ImageDraw, ImageFont

icon, out = sys.argv[1], sys.argv[2]
W, H = 780, 1388
NAVY, PANEL, LINE, OR, INK, MUTED = (11, 19, 43), (20, 31, 56), (42, 53, 78), (255, 107, 0), (244, 246, 251), (165, 177, 199)
F = r"C:\Windows\Fonts\malgun.ttf"; FB = r"C:\Windows\Fonts\malgunbd.ttf"
f = lambda sz, b=False: ImageFont.truetype(FB if b else F, sz)
im = Image.new('RGB', (W, H), NAVY); d = ImageDraw.Draw(im)

d.text((40, 40), "케이티에스 원클릭", font=f(26, True), fill=INK)
d.rounded_rectangle((560, 36, 740, 80), radius=10, fill=OR)
d.text((650, 58), "출시 준비 중", font=f(22, True), fill=(20, 20, 20), anchor="mm")
ic = Image.open(icon).convert('RGB').resize((300, 300), Image.LANCZOS)
im.paste(ic, ((W - 300) // 2, 130))
d.text((W // 2, 480), "매물장 뷰어", font=f(56, True), fill=INK, anchor="mm")
d.text((W // 2, 545), "매물 하나가 중개사 명함과 홈페이지를 달고 다닙니다", font=f(25), fill=MUTED, anchor="mm")

y = 610
for i, (t, s) in enumerate([("요약", "매매가·보증금·월세·수익률"), ("제원", "9항목 2열 표"), ("명함", "연락처 저장·전화·문자"), ("인쇄", "A4 210×297mm 한 장")]):
    yy = y + i * 132
    d.rounded_rectangle((40, yy, W - 40, yy + 112), radius=16, fill=PANEL, outline=OR if i == 0 else LINE, width=2)
    d.rounded_rectangle((68, yy + 30, 168, yy + 82), radius=10, fill=(48, 42, 45))
    d.text((118, yy + 56), t, font=f(26, True), fill=(255, 145, 67), anchor="mm")
    d.text((196, yy + 56), s, font=f(30, True), fill=INK, anchor="lm")

d.rounded_rectangle((40, 1160, W - 40, 1290), radius=16, fill=PANEL, outline=LINE, width=2)
d.text((W // 2, 1205), "지금은 소개만 열려 있습니다", font=f(28, True), fill=INK, anchor="mm")
d.text((W // 2, 1250), "도구가 나오면 쇼룸 맨 위에 알려 드립니다", font=f(24), fill=MUTED, anchor="mm")
d.text((W // 2, 1340), "※ 출시 전 안내 그림 · 실제 화면이 아닙니다", font=f(21), fill=(125, 139, 163), anchor="mm")
im.save(out, optimize=True)
print(out, im.size)

"""shots/ic_listing.png — 512×512, 딥네이비 바탕 + 오렌지 건물·명함 라인 (직접 그림)."""
import sys
from PIL import Image, ImageDraw

out = sys.argv[1]
S = 4  # 4배로 그리고 줄여서 계단 없애기
W = 512 * S
NAVY, PANEL, OR, OR2, INK = (11, 19, 43), (20, 31, 56), (255, 107, 0), (255, 153, 75), (244, 246, 251)
im = Image.new('RGB', (W, W), NAVY)
d = ImageDraw.Draw(im)
k = lambda *v: [x * S for x in v]

d.rounded_rectangle(k(36, 36, 476, 476), radius=64 * S, fill=PANEL)
# 건물 3동 (오렌지 라인)
lw = 14 * S
d.rounded_rectangle(k(118, 150, 228, 360), radius=10 * S, outline=OR, width=lw)
d.rounded_rectangle(k(214, 96, 330, 360), radius=10 * S, outline=OR, width=lw)
d.rounded_rectangle(k(316, 186, 398, 360), radius=10 * S, outline=OR2, width=lw)
for y in (140, 186, 232, 278):           # 가운데 동 창문
    d.rounded_rectangle(k(244, y, 266, y + 22), radius=4 * S, fill=OR2)
    d.rounded_rectangle(k(280, y, 302, y + 22), radius=4 * S, fill=OR2)
for y in (196, 246, 296):                # 왼쪽 동 창문
    d.rounded_rectangle(k(146, y, 168, y + 20), radius=4 * S, fill=OR2)
d.line(k(96, 360, 420, 360), fill=OR, width=lw)
# 명함 카드
d.rounded_rectangle(k(150, 330, 362, 430), radius=14 * S, fill=INK)
d.rounded_rectangle(k(166, 350, 210, 394), radius=8 * S, fill=OR)
d.rounded_rectangle(k(224, 354, 340, 366), radius=6 * S, fill=NAVY)
d.rounded_rectangle(k(224, 378, 312, 388), radius=5 * S, fill=(125, 139, 163))
d.rounded_rectangle(k(224, 400, 296, 410), radius=5 * S, fill=(125, 139, 163))

im.resize((512, 512), Image.LANCZOS).save(out, optimize=True)
print(out, Image.open(out).size)

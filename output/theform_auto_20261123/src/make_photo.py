"""시험 3번 종이: 실제 폰 사진이 없어 tpl_consult_p1.png 를 '사진처럼' 합성 — 8° 회전 + 책상 배경 + 좌상단 그늘 그라데이션 + 약한 노이즈."""
import random, sys
from PIL import Image, ImageDraw, ImageFilter
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGB')                       # 1489x2105
paper = im.resize((1240, 1753), Image.LANCZOS)
W, H = 1700, 2200
desk = Image.new('RGB', (W, H), (92, 74, 60))
d = ImageDraw.Draw(desk)
for y in range(0, H, 7):                                  # 나뭇결 느낌
    c = 84 + (y * 13 % 23)
    d.line([(0, y), (W, y + 40)], fill=(c, int(c * .8), int(c * .65)), width=3)
rot = paper.convert('RGBA').rotate(8, resample=Image.BICUBIC, expand=True)
desk.paste(rot, ((W - rot.width) // 2, (H - rot.height) // 2), rot)
# 좌상단 그늘 (최대 45% 어둡게) + 오른쪽 아래 살짝 밝은 조명
sh = Image.new('L', (W, H), 0); sd = ImageDraw.Draw(sh)
for i in range(60):
    r = int(1500 * (1 - i / 60)); a = int(115 * (1 - i / 60) ** 1.2)
    sd.ellipse([-r // 2 - 200, -r // 2 - 200, r, r], fill=255 - a if False else a)
sh = sh.filter(ImageFilter.GaussianBlur(120))
dark = Image.new('RGB', (W, H), (0, 0, 0))
ph = Image.composite(dark, desk, sh)
random.seed(7)
px = ph.load()
for _ in range(60000):
    x, y = random.randrange(W), random.randrange(H); r, g, b = px[x, y]; n = random.randint(-14, 14)
    px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))
ph = ph.filter(ImageFilter.GaussianBlur(.6))
ph.save(out, quality=88)
print(out, ph.size)

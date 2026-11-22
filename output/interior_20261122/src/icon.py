# shots/ic_interior.png — 512x512 딥네이비 + 오렌지 벽(템바 결)·간접등 라인
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops
S=4; W=512*S
im=Image.new('RGB',(W,W),(10,17,40))
d=ImageDraw.Draw(im)
# 둥근 카드 바탕
d.rounded_rectangle([24*S,24*S,488*S,488*S],radius=96*S,fill=(15,27,51),outline=(38,55,95),width=4*S)
# 간접등 글로우(천장 라인)
glow=Image.new('RGB',(W,W),(0,0,0)); g=ImageDraw.Draw(glow)
g.rounded_rectangle([110*S,112*S,402*S,128*S],radius=8*S,fill=(255,170,90))
glow=glow.filter(ImageFilter.GaussianBlur(26*S))
im=ImageChops.add(im,glow)
d=ImageDraw.Draw(im)
d.rounded_rectangle([110*S,112*S,402*S,126*S],radius=7*S,fill=(255,236,205))
# 벽(템바보드 세로 결) — 오렌지
x0,y0,x1,y1=128*S,160*S,384*S,392*S
d.rectangle([x0,y0,x1,y1],fill=(255,107,0))
step=32*S
for i,x in enumerate(range(x0,x1,step)):
    d.rectangle([x,y0,x+step//2-2*S,y1],fill=(255,162,77))
    d.rectangle([x+step-5*S,y0,x+step-1*S,y1],fill=(204,82,0))
# 바닥선·가구(낮은 테이블)
d.rectangle([96*S,392*S,416*S,402*S],fill=(175,189,208))
d.rounded_rectangle([196*S,330*S,316*S,346*S],radius=4*S,fill=(243,246,250))
d.rectangle([206*S,346*S,216*S,392*S],fill=(243,246,250)); d.rectangle([296*S,346*S,306*S,392*S],fill=(243,246,250))
im=im.resize((512,512),Image.LANCZOS)
im.save(sys.argv[1],optimize=True)
print(im.size)

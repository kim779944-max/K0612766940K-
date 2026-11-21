import re,os
from PIL import Image,ImageDraw,ImageFont
root='../../../oneclick/navi2/'
s=open(root+'js/data.pool.js',encoding='utf-8').read()
pairs=re.findall(r"\{ l:'([^']*)'[^\n]*?img:'([^']*)'",s)
assert len(pairs)==100
f=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',17); W,H,C=280,210,5
rows_out=[]
for si in range(0,100,25):
    ch=pairs[si:si+25]; rows=(len(ch)+C-1)//C; sh=Image.new('RGB',(C*W,rows*(H+52)),'white'); d=ImageDraw.Draw(sh)
    for i,(l,img) in enumerate(ch):
        im=Image.open(root+img).convert('RGB'); im.thumbnail((W,H)); x,y=(i%C)*W,(i//C)*(H+52); sh.paste(im,(x,y))
        d.text((x+3,y+H+2),'%d. %s'%(si+i+1,l),fill='black',font=f); d.text((x+3,y+H+26),os.path.basename(img),fill='#666',font=f)
    sh.save('A4_pairs_%d.jpg'%(si//25+1),quality=72)
with open('A4_pairs.md','w',encoding='utf-8') as o:
    o.write('| # | 보기 문장 | 사진 |\n|---|---|---|\n')
    for i,(l,img) in enumerate(pairs): o.write('| %d | %s | `%s` |\n'%(i+1,l,img))
print('ok')

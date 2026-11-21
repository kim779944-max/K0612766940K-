import sys,os,glob
from PIL import Image,ImageDraw,ImageFont
src,out,per=sys.argv[1],sys.argv[2],int(sys.argv[3]) if len(sys.argv)>3 else 24
files=sorted(f for f in glob.glob(os.path.join(src,'*')) if f.lower().endswith(('.jpg','.jpeg','.webp','.png')) and 'nav_photo' not in f)
W,H,C=300,225,6
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
for si in range(0,len(files),per):
    chunk=files[si:si+per]; rows=(len(chunk)+C-1)//C
    sh=Image.new('RGB',(C*W,rows*(H+26)),'white'); d=ImageDraw.Draw(sh)
    for i,f in enumerate(chunk):
        im=Image.open(f).convert('RGB'); im.thumbnail((W,H))
        x,y=(i%C)*W,(i//C)*(H+26); sh.paste(im,(x,y)); d.text((x+4,y+H+2),os.path.basename(f),fill='black',font=font)
    sh.save(os.path.join(out,'sheet_%02d.jpg'%(si//per)),quality=80)
print(len(files))

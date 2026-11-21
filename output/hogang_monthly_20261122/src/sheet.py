import sys,os
from PIL import Image,ImageDraw,ImageFont
fs=sys.argv[2:]; out=sys.argv[1]; S=300; cols=4; rows=(len(fs)+cols-1)//cols
sh=Image.new('RGB',(cols*S,rows*(S+24)),'white'); d=ImageDraw.Draw(sh)
try: f=ImageFont.truetype('malgun.ttf',16)
except: f=None
for i,p in enumerate(fs):
    im=Image.open(p).convert('RGB'); im.thumbnail((S,S)); x=(i%cols)*S; y=(i//cols)*(S+24)
    sh.paste(im,(x+(S-im.width)//2,y+24+(S-im.height)//2)); d.text((x+4,y+2),os.path.basename(p),fill='black',font=f)
sh.save(out)

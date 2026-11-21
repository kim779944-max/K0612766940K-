import sys,os,json
from PIL import Image
B=json.load(open(sys.argv[1],encoding='utf-8')); OUT=sys.argv[2]; os.makedirs(OUT,exist_ok=True)
for k,(src,box) in B.items():
    im=Image.open(src).convert('RGB'); W,H=im.size
    c=im.crop((int(box[0]*W),int(box[1]*H),int(box[2]*W),int(box[3]*H)))
    s=max(c.size); sq=Image.new('RGB',(s,s),'white'); sq.paste(c,((s-c.width)//2,(s-c.height)//2))
    sq=sq.resize((480,480),Image.LANCZOS); p=os.path.join(OUT,k+'.webp'); sq.save(p,'WEBP',quality=78,method=6)
    print(k,os.path.getsize(p))

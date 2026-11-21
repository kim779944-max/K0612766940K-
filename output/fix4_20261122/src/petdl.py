import json,urllib.request,urllib.parse,html,time,os
from PIL import Image,ImageDraw,ImageFont
UA={'User-Agent':'KTS-fix4-imagepicker/1.0 (educational)'}
PICK=[('cand_scratch','c019','cat_scratcher.webp'),('cand_scratch','c017','cat_scratch_wrong.webp'),
      ('cand_litter','c028','cat_litter_box.webp'),('cand_mark','c005','cat_plant_pot.webp'),
      ('cand_hide','c000','cat_hiding.webp'),('cand_lick','c004','cat_licking.webp'),
      ('cand_meow','c000','cat_meowing.webp'),('cand_two','c004','cats_together.webp'),('cand_two','c012','cats_fighting.webp')]
D='../../../oneclick/petmind/img/'
def get(u):
    for i in range(6):
        try: return urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=60).read()
        except urllib.error.HTTPError as e:
            if e.code==429: time.sleep(15*(i+1)); continue
            raise
    raise RuntimeError('429 repeated')
rows=[]
for d,k,out in PICK:
    m=json.load(open(d+'/meta.json',encoding='utf-8'))[k]
    rows.append(dict(file=out,title=m['title'][5:],page=m['page'],artist=html.unescape(m['artist']),lic=m['lic']))
    src='dl/'+out.replace('.webp','_src.jpg')
    if not os.path.exists(src):
        # 이미 받은 480px 후보보다 큰 원본: 메타의 orig 대신 썸네일 API(1280)
        import shutil; shutil.copy(os.path.join(d,k+'.jpg'), src)   # 429 지속 → 검색 때 받은 480px 사본 사용
    im=Image.open(src).convert('RGB'); w,h=im.size
    if w/h>4/3: tw,th=int(h*4/3),h
    else: tw,th=w,int(w*3/4)
    l=(w-tw)//2; tp=(h-th)//2; im=im.crop((l,tp,l+tw,tp+th)); im=im.resize((800,600) if tw>=800 else (tw - tw%4, (tw - tw%4)*3//4),Image.LANCZOS)
    im.save(D+out,'WEBP',quality=80); print(out,(w,h),m['lic'],m['artist'][:40],flush=True)
json.dump(rows,open('dl/pet_credits.json','w',encoding='utf-8'),ensure_ascii=False,indent=1)
f=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18); sh=Image.new('RGB',(3*400,3*322),'white'); dr=ImageDraw.Draw(sh)
for i,rw in enumerate(rows):
    im=Image.open(D+rw['file']); im.thumbnail((400,300)); x,y=(i%3)*400,(i//3)*322; sh.paste(im,(x,y)); dr.text((x+3,y+301),rw['file'],fill='black',font=f)
sh.save('shots/D2_cat_new_photos.jpg',quality=75)

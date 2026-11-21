# 후보 썸네일 내려받아 시트로: wmcands.py outdir "q1" "q2" ...
import sys,os,json,re,urllib.request,urllib.parse
from PIL import Image,ImageDraw,ImageFont
UA={'User-Agent':'KTS-fix4-imagepicker/1.0 (educational)'}
OKL=re.compile(r'^(cc0|public domain|pd.*|cc by(-sa)? [1-4]\.\d.*)$',re.I)
out=sys.argv[1]; os.makedirs(out,exist_ok=True)
meta={}
if os.path.exists(os.path.join(out,'meta.json')): meta=json.load(open(os.path.join(out,'meta.json'),encoding='utf-8'))
def api(p):
    p.update(format='json'); u='https://commons.wikimedia.org/w/api.php?'+urllib.parse.urlencode(p)
    return json.load(urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=30))
for q in sys.argv[2:]:
    if q.startswith('Category:'):
        p=dict(action='query',generator='categorymembers',gcmtitle=q,gcmtype='file',gcmlimit=30,prop='imageinfo',iiprop='url|extmetadata|size|mime',iiurlwidth=480)
    else:
        p=dict(action='query',generator='search',gsrsearch=q+' filetype:bitmap',gsrnamespace=6,gsrlimit=20,prop='imageinfo',iiprop='url|extmetadata|size|mime',iiurlwidth=480)
    r=api(p)
    for pg in r.get('query',{}).get('pages',{}).values():
        ii=pg['imageinfo'][0]; md=ii.get('extmetadata',{})
        lic=md.get('LicenseShortName',{}).get('value','?')
        if not OKL.match(lic.strip()) or 'nc' in lic.lower() or 'nd' in lic.lower(): continue
        if ii.get('mime') not in ('image/jpeg','image/png','image/webp'): continue
        if (ii.get('width') or 0) < 600: continue
        art=re.sub('<[^>]+>','',md.get('Artist',{}).get('value','?')).strip()[:80]
        key='c%03d'%len(meta)
        if any(v['title']==pg['title'] for v in meta.values()): continue
        try:
            data=urllib.request.urlopen(urllib.request.Request(ii['thumburl'],headers=UA),timeout=30).read()
        except Exception as e: print('fail',pg['title'],e); continue
        open(os.path.join(out,key+'.jpg'),'wb').write(data)
        meta[key]={'title':pg['title'],'lic':lic,'artist':art,'page':ii['descriptionurl'],'orig':ii['url'],'w':ii['width'],'h':ii['height'],'q':q}
json.dump(meta,open(os.path.join(out,'meta.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
# 시트
keys=sorted(meta); W,H,C=240,180,6; font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
for si in range(0,len(keys),36):
    ch=keys[si:si+36]; rows=(len(ch)+C-1)//C; sh=Image.new('RGB',(C*W,rows*(H+22)),'white'); d=ImageDraw.Draw(sh)
    for i,k in enumerate(ch):
        try: im=Image.open(os.path.join(out,k+'.jpg')).convert('RGB'); im.thumbnail((W,H))
        except Exception: continue
        x,y=(i%C)*W,(i//C)*(H+22); sh.paste(im,(x,y)); d.text((x+3,y+H+1),k,fill='black',font=font)
    sh.save(os.path.join(out,'_sheet%d.jpg'%(si//36)),quality=80)
print(len(meta))

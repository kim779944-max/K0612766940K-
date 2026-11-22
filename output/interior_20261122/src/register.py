# 적립 128번 — interior 등록 5곳(catalog.json·products.js·index.html·sitemap.xml·slots.js LIMIT) 1회 실행용
import json,os,sys
here=os.path.dirname(os.path.abspath(__file__))
item=json.load(open(os.path.join(here,'item.json'),encoding='utf-8'))
os.chdir(sys.argv[1])
raw=open('catalog.json',encoding='utf-8').read()
assert '"k": "interior"' not in raw
blk=json.dumps(item,ensure_ascii=False,indent=1)
blk='\n'.join('  '+l for l in blk.split('\n'))
idx=raw.rstrip().rfind(']')
head=raw[:idx].rstrip(); assert head.endswith('}')
new=head+',\n'+blk+'\n '+raw[idx:]
new=new.replace('"v": "20261121u"','"v": "20261122a"',1).replace('"updated": "2026-11-21T23:30:00+09:00"','"updated": "2026-11-22T14:30:00+09:00"',1).replace('"count": 26,','"count": 27,',1)
d2=json.loads(new); assert d2['count']==27 and len(d2['products'])==27 and d2['v']=='20261122a' and d2['products'][-1]==item
open('catalog.json','w',encoding='utf-8',newline='').write(new)
p=open('products.js',encoding='utf-8').read()
marker='\n];\n/* ↑ catalog.json products 배열과 같은 내용'
i=p.index(marker); assert p[:i].rstrip().endswith('}')
pb=json.dumps(item,ensure_ascii=False,indent=1); pb='\n'.join(' '+l for l in pb.split('\n'))
p=p[:i].rstrip()+',\n'+pb+p[i:]
p=p.replace('(2026-11-21 동기화 · 26종)','(2026-11-22 동기화 · 27종)',1)
open('products.js','w',encoding='utf-8',newline='').write(p)
h=open('index.html',encoding='utf-8').read()
a="ks:['sale','gagebu','hogang','golf','petmind','saycap']"; assert h.count(a)==1
h=h.replace(a,"ks:['sale','gagebu','hogang','golf','petmind','interior','saycap']")
open('index.html','w',encoding='utf-8',newline='').write(h)
s=open('sitemap.xml',encoding='utf-8').read()
u='  <url>\n    <loc>https://autooneclick.com/interior/</loc>\n    <lastmod>2026-11-22</lastmod>\n    <changefreq>monthly</changefreq>\n    <priority>0.8</priority>\n  </url>\n'
s=s.replace('</urlset>',u+'</urlset>',1)
open('sitemap.xml','w',encoding='utf-8',newline='').write(s)
t=open('slots.js',encoding='utf-8').read()
a1="var LIMIT = { photo2doc: 3, ad_magnet: 3 };"; a2="var LIMIT_UNIT = { photo2doc: '장', ad_magnet: '건' };"
assert a1 in t and a2 in t
t=t.replace(a1,"var LIMIT = { photo2doc: 3, ad_magnet: 3, interior: 1 };",1).replace(a2,"var LIMIT_UNIT = { photo2doc: '장', ad_magnet: '건', interior: '장' };",1)
open('slots.js','w',encoding='utf-8',newline='').write(t)
print('ok')

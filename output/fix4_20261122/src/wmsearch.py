import sys,json,urllib.request,urllib.parse
UA={'User-Agent':'KTS-fix4-imagepicker/1.0 (educational; contact via repo)'}
def api(params):
    params.update(format='json')
    u='https://commons.wikimedia.org/w/api.php?'+urllib.parse.urlencode(params)
    return json.load(urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=30))
q=sys.argv[1]; n=int(sys.argv[2]) if len(sys.argv)>2 else 12
r=api(dict(action='query',generator='search',gsrsearch=q+' filetype:bitmap',gsrnamespace=6,gsrlimit=n,prop='imageinfo',iiprop='url|extmetadata|size',iiurlwidth=640))
ok=('cc0','public domain','pd','cc by 4.0','cc by 3.0','cc by 2.0','cc by-sa 4.0','cc by-sa 3.0','cc by-sa 2.0','cc by 2.5','cc by-sa 2.5')
for p in sorted(r.get('query',{}).get('pages',{}).values(),key=lambda x:x.get('index',0)):
    ii=p['imageinfo'][0]; md=ii.get('extmetadata',{})
    lic=md.get('LicenseShortName',{}).get('value','?')
    art=md.get('Artist',{}).get('value','?')
    import re; art=re.sub('<[^>]+>','',art).strip()[:60]
    print(json.dumps({'t':p['title'],'lic':lic,'art':art,'w':ii.get('width'),'h':ii.get('height'),'thumb':ii.get('thumburl'),'page':ii.get('descriptionurl')},ensure_ascii=False))

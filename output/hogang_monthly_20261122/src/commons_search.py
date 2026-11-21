# 위키미디어 공용 파일 검색 — 제목·라이선스·저자·480px 썸네일 URL만 출력 (내려받기 X)
import json, sys, time, os, urllib.request, urllib.parse, urllib.error
UA = 'KTS-hogang-photo-check/1.0 (research script)'
def api(params):
    params.update(format='json')
    u = 'https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params)
    req = urllib.request.Request(u, headers={'User-Agent': UA})
    for i in range(6):
        try:
            return json.load(urllib.request.urlopen(req, timeout=30))
        except urllib.error.HTTPError as e:
            if e.code != 429: raise
            time.sleep(20 + 10 * i)
    raise SystemExit('429 계속')
OUTF = sys.argv[0].replace('.py', '_out.json')
out = json.load(open(OUTF, encoding='utf-8')) if os.path.exists(OUTF) else {}
for q in sys.argv[1:]:
    r = api({'action': 'query', 'generator': 'search', 'gsrsearch': q, 'gsrnamespace': 6, 'gsrlimit': 12,
             'prop': 'imageinfo', 'iiprop': 'url|extmetadata|size', 'iiurlwidth': 480})
    pages = (r.get('query') or {}).get('pages', {})
    rows = []
    for p in sorted(pages.values(), key=lambda p: p.get('index', 0)):
        ii = (p.get('imageinfo') or [{}])[0]; md = ii.get('extmetadata', {})
        g = lambda k: (md.get(k) or {}).get('value', '')
        rows.append({'title': p['title'], 'lic': g('LicenseShortName'), 'artist': g('Artist')[:120], 'w': ii.get('width'), 'h': ii.get('height'),
                     'thumb': ii.get('thumburl'), 'page': ii.get('descriptionurl'), 'date': g('DateTimeOriginal')[:40]})
    out[q] = rows
    print('##', q)
    for x in rows: print('  ', x['title'], '|', x['lic'], '|', x['w'], 'x', x['h'])
    json.dump(out, open(OUTF, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    time.sleep(4)

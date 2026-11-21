# 지정 파일의 메타데이터(저자·라이선스·원본 URL) + 800px 썸네일을 dl/ 에 저장. 실행: py -I
import json, sys, time, os, urllib.request, urllib.parse, urllib.error, re, html
UA = 'KTS-hogang-photo-check/1.0 (research script)'
HERE = os.path.dirname(os.path.abspath(__file__))
DL = os.path.join(HERE, '..', 'dl'); os.makedirs(DL, exist_ok=True)
META = os.path.join(DL, 'meta.json')
meta = json.load(open(META, encoding='utf-8')) if os.path.exists(META) else {}
def get(u, binary=False):
    req = urllib.request.Request(u, headers={'User-Agent': UA})
    for i in range(7):
        try:
            d = urllib.request.urlopen(req, timeout=40).read()
            return d if binary else json.loads(d)
        except urllib.error.HTTPError as e:
            if e.code != 429: raise
            time.sleep(25 + 15 * i)
    raise SystemExit('429 계속: ' + u)
jobs = json.load(open(sys.argv[1], encoding='utf-8'))  # [[key, "File:..."], ...]
for key, title in jobs:
    out = os.path.join(DL, key + '.jpg')
    if os.path.exists(out) and os.path.getsize(out) > 0 and key in meta: continue
    r = get('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode({'action': 'query', 'titles': title, 'prop': 'imageinfo',
            'iiprop': 'url|extmetadata|size', 'iiurlwidth': 800, 'format': 'json'}))
    p = list(r['query']['pages'].values())[0]; ii = p['imageinfo'][0]; md = ii['extmetadata']
    g = lambda k: html.unescape(re.sub('<[^>]+>', '', (md.get(k) or {}).get('value', ''))).strip()
    data = get(ii['thumburl'], binary=True)
    open(out, 'wb').write(data)
    meta[key] = {'title': title, 'page': ii['descriptionurl'], 'artist': g('Artist'), 'lic': g('LicenseShortName'), 'licUrl': g('LicenseUrl'),
                 'w': ii['width'], 'h': ii['height'], 'desc': g('ImageDescription')[:300], 'date': g('DateTimeOriginal')[:40]}
    json.dump(meta, open(META, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('ok', key, len(data), meta[key]['artist'][:40], meta[key]['lic'])
    time.sleep(6)

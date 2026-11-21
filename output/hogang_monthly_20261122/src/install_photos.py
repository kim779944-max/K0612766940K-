# crop/*.webp 14장을 oneclick/hogang/img 로 복사하고 models.json photos · CREDITS.md · CREDITS.html 갱신
import json, os, shutil, html, re, urllib.parse
HERE = os.path.dirname(os.path.abspath(__file__)); W = os.path.join(HERE, '..')
HG = os.path.abspath(os.path.join(W, '..', '..', '..', 'oneclick', 'hogang'))
meta = json.load(open(os.path.join(W, 'dl', 'meta.json'), encoding='utf-8'))
ORDER = ['s26u', 's26p', 's26', 'fold8u', 'fold8', 'flip8', 'ip18pm', 'ip18p', 'ipduo', 's25fe', 'flip7', 'ip17', 'ip16', 'ip13']
SAM = {'s25fe': {'title': '갤럭시 S25 FE 제품 이미지 (삼성전자 뉴스룸, 2025-09-04 기사 첨부)',
                 'page': 'https://news.samsung.com/kr/%ec%82%bc%ec%84%b1%ec%a0%84%ec%9e%90-%ec%b5%9c%ec%8b%a0-%ea%b0%a4%eb%9f%ad%ec%8b%9c-ai-%ea%b2%bd%ed%97%98%ec%9d%84-%ec%a0%9c%ea%b3%b5%ed%95%98%eb%8a%94-%ea%b0%a4%eb%9f%ad%ec%8b%9c-s25-fe',
                 'artist': '삼성전자 (제조사 제공)', 'lic': '제조사 제공 보도용 이미지'}}
rows = []
photos = {}
for k in ORDER:
    shutil.copyfile(os.path.join(W, 'crop', k + '.webp'), os.path.join(HG, 'img', k + '.webp'))
    if k in SAM:
        m = SAM[k]; photos[k] = '삼성전자 뉴스룸 · 제조사 제공'
    else:
        m = meta[k + '_a']; m = dict(m, title=m['title'].replace('File:', '', 1)); photos[k] = m['artist'] + ' · ' + m['lic'] + ' (위키미디어 공용)'
    rows.append((k, m))
# models.json photos — 줄 단위로 끼워 넣어 기존 서식 유지
mp = os.path.join(HG, 'data', 'models.json'); s = open(mp, encoding='utf-8').read()
add = ''.join(',\n    ' + json.dumps(k, ensure_ascii=False) + ':' + json.dumps(v, ensure_ascii=False) for k, v in photos.items())
s = s.replace('"ip15":"ThePhotoGraphIc · CC BY-SA 4.0 (위키미디어 공용)"', '"ip15":"ThePhotoGraphIc · CC BY-SA 4.0 (위키미디어 공용)"' + add, 1)
json.loads(s); open(mp, 'w', encoding='utf-8', newline='').write(s)
FAIL_MD_OLD = re.compile(r"확보 실패\(사진 없이 '사진 준비 중' 표시\):[^\n]*?(?=갤럭시 S25는)")
NOTE = '2026-11-22 추가 14장: 위키미디어 공용 13장 + 제조사(삼성전자 뉴스룸) 제공 1장(갤럭시 S25 FE — 공용에 사진이 없음). 이로써 사진 없는 기종은 없습니다. '
# CREDITS.md
cp = os.path.join(HG, 'img', 'CREDITS.md'); md = open(cp, encoding='utf-8').read()
md = md.replace('라이선스는 CC0 · 퍼블릭도메인 · CC BY · CC BY-SA 만 썼습니다.', '라이선스는 CC0 · 퍼블릭도메인 · CC BY · CC BY-SA 만 썼습니다. 단, 공용에 사진이 없는 기종은 제조사 공식 보도용 제품 이미지를 쓰고 "제조사 제공"으로 표기합니다.', 1)
md = md.replace('확인일: 2026-11-21', '확인일: 2026-11-21 · 추가 확인일: 2026-11-22', 1)
mdrows = ''.join('| `%s.webp` | [%s](%s) | %s | %s |\n' % (k, m['title'].replace('|', '/'), m['page'].replace('(', '%28').replace(')', '%29'), m['artist'], m['lic']) for k, m in rows)
md = md.replace('\n\n확보 실패', '\n' + mdrows + '\n확보 실패', 1)
md = FAIL_MD_OLD.sub(NOTE, md, 1)
open(cp, 'w', encoding='utf-8', newline='').write(md)
# CREDITS.html
hp = os.path.join(HG, 'img', 'CREDITS.html'); h = open(hp, encoding='utf-8').read()
h = h.replace('라이선스는 CC0 · 퍼블릭도메인 · CC BY · CC BY-SA 만 썼습니다.', '라이선스는 CC0 · 퍼블릭도메인 · CC BY · CC BY-SA 만 썼습니다. 단, 공용에 사진이 없는 기종은 제조사 공식 보도용 제품 이미지를 쓰고 "제조사 제공"으로 표기합니다.', 1)
h = h.replace('<p>확인일: 2026-11-21</p>', '<p>확인일: 2026-11-21 · 추가 확인일: 2026-11-22</p>', 1)
hrows = ''.join('<tr><td> <code>%s.webp</code></td><td><a href="%s" rel="noopener">%s</a></td><td>%s</td><td>%s </td></tr>\n' % (k, html.escape(m['page']), html.escape(m['title']), html.escape(m['artist']), html.escape(m['lic'])) for k, m in rows)
h = h.replace('</table>', hrows + '</table>', 1)
h = FAIL_MD_OLD.sub(NOTE, h, 1)
open(hp, 'w', encoding='utf-8', newline='').write(h)
print(json.dumps(photos, ensure_ascii=False, indent=1))

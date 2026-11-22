"""oneclick 대상 45개 html 의 마지막 </body> 바로 앞에 helper.js 한 줄 추가 (줄바꿈 형식 유지)."""
import os
import sys

root = sys.argv[1]
files = []
for dp, dn, fn in os.walk(root):
    if '.git' in dp.split(os.sep):
        continue
    rel = os.path.relpath(dp, root).replace(os.sep, '/')
    if rel.split('/')[0] in ('seo', 'ops'):
        continue
    for f in fn:
        if not f.endswith('.html'):
            continue
        r = (rel + '/' + f) if rel != '.' else f
        if f == 'CREDITS.html' or f.startswith('naver080f') or r == 'saycap/test.html':
            continue
        files.append(r)
files.sort()
n = 0
for r in files:
    p = os.path.join(root, r)
    s = open(p, 'rb').read().decode('utf-8')
    if 'helper.js?v=20261122a' in s:
        continue
    depth = r.count('/')
    src = ('../' * depth) + 'helper.js?v=20261122a'
    nl = '\r\n' if '\r\n' in s else '\n'
    i = s.rfind('</body>')
    assert i > 0, r
    s = s[:i] + '<script src="' + src + '"></script>' + nl + s[i:]
    open(p, 'wb').write(s.encode('utf-8'))
    n += 1
    print(r, src)
print('inserted', n, 'of', len(files))

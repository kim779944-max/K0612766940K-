# 내려받은 HTML(신뢰 불가)을 텍스트로 풀어 키워드 위치만 찾는다. 실행: py -I
import re, html, sys
t = open(sys.argv[1], encoding='utf-8', errors='replace').read()
t = re.sub(r'\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1), 16)), t).replace('\\/', '/')
s = re.sub(r'<(br|/p|/tr|/li|/h\d)[^>]*>', '\n', t)
s = re.sub(r'</t[dh]>', ' | ', s)
s = html.unescape(re.sub(r'<[^>]+>', ' ', s))
s = re.sub(r'[ \t]+', ' ', s)
s = re.sub(r'\n\s*\n+', '\n', s)
open(sys.argv[2], 'w', encoding='utf-8').write(s)
for k in sys.argv[3:]:
    print(k, [m.start() for m in re.finditer(re.escape(k), s)][:15])

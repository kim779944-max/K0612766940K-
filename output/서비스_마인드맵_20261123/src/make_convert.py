"""158번 — 문서변환기(converter.html)를 더양식 안으로.
usage: python make_convert.py <oneclick> <원본 커밋(converter.html 이 엔진이던 판)>
 · theform/js/converter.js  = converter.html 본 스크립트 그대로(경로만 ../ 로)
 · theform/convert.html     = converter.html 화면 그대로(경로만 ../ · 스크립트는 js/converter.js)
                              더양식 ② 탭의 iframe 으로 열린다. 단독으로 열어도 동작.
 · converter.html           = 안내 + 즉시 이동(theform/?tab=convert) — 404 없음"""
import os, re, subprocess, sys
OC, BASE = sys.argv[1], sys.argv[2]
src = subprocess.run(['git', '-C', OC, 'show', f'{BASE}:converter.html'], capture_output=True, check=True).stdout.decode('utf-8')
crlf = '\r\n' in src
src = src.replace('\r\n', '\n')

# 본 스크립트(가장 긴 인라인 <script>) 분리
blocks = [m for m in re.finditer(r'<script>\n?(.*?)</script>', src, re.S)]
main = max(blocks, key=lambda m: len(m.group(1)))
js = main.group(1)
assert len(js) > 60000, len(js)

def R(s, a, c, n=None):
    k = s.count(a)
    assert k >= 1 and (n is None or k == n), (a, k)
    return s.replace(a, c)

# 경로 배선만 바꾼다(엔진 로직 무변경)
js = R(js, "fetch('tpl/' + f)", "fetch('../tpl/' + f)", 1)
js = R(js, "location.href = 'viewer.html?f=' +", "KTS_TOP().location.href = '../viewer.html?f=' +", 1)
js = R(js, "location.href = 'viewer.html'; }", "KTS_TOP().location.href = '../viewer.html'; }", 2)
js = R(js, "location.href = 'sms:", "KTS_TOP().location.href = 'sms:")
head = ("/* KTS 더양식 ② 표 사진 → 한글·엑셀 (구 문서변환기 converter.html 엔진 · 2026-11-23 이관 · 158번)\n"
        "   변환 로직은 converter.html(" + BASE + ") 그대로이고, 파일 경로만 theform/ 기준(../)으로 바꿨다. */\n"
        "function KTS_TOP(){ try { return (window.top && window.top.location.host === location.host) ? window.top : window; } catch (e) { return window; } }\n")
js = head + js.lstrip('\n')

html = src[:main.start()] + '<script src="js/converter.js?v=20261123c"></script>' + src[main.end():]
for a, c in [('<script src="master.js', '<script src="../master.js'),
             ('href="manifest.webmanifest"', 'href="../manifest.webmanifest"'),
             ('<link rel="icon" href="icon.png">', '<link rel="icon" href="../icon.png">'),
             ('<script src="localocr.js', '<script src="../localocr.js'),
             ('<script src="freekey.js"', '<script src="../freekey.js"'),
             ('<script src="ai.js"', '<script src="../ai.js"'),
             ('<script src="ux.js', '<script src="../ux.js'),
             ('<a class="tel" href="index.html" target="_blank" rel="noopener">← 원클릭</a>',
              '<a class="tel" href="../index.html" target="_top">← 원클릭</a>')]:
    html = R(html, a, c, 1)
# 더양식 탭 안(iframe)에서는 도우미 버튼을 겉 화면 것 하나만 쓴다
html = R(html, '<script src="helper.js?v=20261122a"></script>',
         '<script>if (window.top === window) document.write(\'<script src="../helper.js?v=20261122a"><\\/script>\');</script>', 1)
# 이름: 더양식 ② 탭 · 더양식 안(iframe)에서는 겉 머리줄 하나만 보이게
html = R(html, 'KTS <small>문서변환기</small>', 'KTS <small>더양식 · 표 사진 → 한글·엑셀</small>', 1)
html = R(html, '</head>', "<script>if (window.top !== window) document.documentElement.classList.add('inform');</script>\n"
         "<style>.inform header.top,.inform .ktsRsv{display:none!important}</style>\n</head>", 1)
html = re.sub(r'<title>KTS 문서변환기 — ', '<title>KTS 더양식 · 표 사진 → 한글·엑셀 — ', html, count=1)

def W(rel, s):
    p = os.path.join(OC, rel); os.makedirs(os.path.dirname(p), exist_ok=True)
    if crlf: s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))
    print('wrote', rel, len(s.encode('utf-8')))

W('theform/js/converter.js', js)
W('theform/convert.html', html)
W('converter.html', """<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>문서변환기 → 더양식으로 통합되었습니다 — KTS 원클릭</title>
<meta http-equiv="refresh" content="0;url=theform/?tab=convert">
<link rel="canonical" href="https://autooneclick.com/theform/?tab=convert">
<link rel="icon" href="icon.png">
<script>location.replace('theform/?tab=convert' + (location.hash || ''));</script>
<style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#0A1128;color:#F3F6FA;
font-family:-apple-system,"Apple SD Gothic Neo","Malgun Gothic",sans-serif;text-align:center;padding:24px}
a{color:#FFA24D;font-weight:900}</style>
</head><body>
<p>문서변환기는 <a href="theform/?tab=convert">더양식</a> 안으로 통합되었습니다.<br>
<small>더양식 → [② 표 사진 → 한글·엑셀] 탭에서 그대로 쓰실 수 있습니다.</small></p>
</body></html>
""")

"""kts_gate.py 대체(이식판 · output/thescan_shutter_20261123/src/gate_thescan.ps1 과 같은 G1 정적 검사) —
바뀐 파일마다 기준 커밋(전)과 작업본(후)을 같이 검사한다. exit = 새로 생긴 FAIL 수.
usage: python kts_gate_port.py <oneclick> <기준 커밋> file1 file2 ..."""
import math, os, re, subprocess, sys
OC, BASE, FILES = sys.argv[1], sys.argv[2], sys.argv[3:]
TAGS = ['div', 'section', 'main', 'header', 'nav', 'table', 'script', 'style', 'label', 'select', 'button', 'a', 'ol', 'ul', 'p',
        'h1', 'h2', 'h3', 'textarea']

def check(src, d, html):
    r = {}
    mk = src
    if html:
        mk = re.sub(r'(?is)(<script\b[^>]*>).*?(</script>)', r'\1\2', src)
        mk = re.sub(r'(?is)(<style\b[^>]*>).*?(</style>)', r'\1\2', mk)
        bad = []
        for t in TAGS:
            o = len(re.findall(rf'(?i)<{t}(\s[^>]*)?>', mk)); c = len(re.findall(rf'(?i)</{t}>', mk))
            if o != c: bad.append(f'{t} {o}/{c}')
        r['G1-2 태그 짝'] = 'FAIL ' + ','.join(bad) if bad else 'PASS'
    sz = [math.floor(len(m) * 3 / 4) for m in re.findall(r'data:[a-z/+.-]+;base64,([A-Za-z0-9+/=]+)', src)]
    mx, sm = (max(sz) if sz else 0), sum(sz)
    r['G1-3 Base64'] = ('FAIL' if mx > 153600 or sm > 512000 else 'PASS') + f' max={mx} sum={sm}'
    k = len(re.findall(r'sk-[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_\-]{20,}|apiKey\s*=\s*["\'][^"\']{8,}', src))
    r['G1-5 API키'] = ('FAIL' if k else 'PASS') + f' {k}'
    tx = re.sub(r'data:[^"\')\s]+', '', src)
    pii = (len(re.findall(r'01[016789][-. ]?\d{3,4}[-. ]?\d{4}', tx)) + len(re.findall(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', tx))
           + len(re.findall(r'\d{6}-[1-4]\d{6}', tx)))
    r['G1-6 연락처·주민번호'] = ('FAIL' if pii else 'PASS') + f' {pii}'
    if html:
        br = []
        for u in re.findall(r'(?i)(?:href|src)="([^"]+)"', mk):
            if re.match(r'^(https?:|data:|mailto:|tel:|sms:|javascript:|#|blob:)', u): continue
            rel = re.sub(r'[?#].*$', '', u)
            if rel and not os.path.exists(os.path.join(d, rel)): br.append(u)
        r['G1-8 내부 링크'] = 'FAIL ' + ','.join(br) if br else 'PASS'
        r['G1-9 viewport'] = 'PASS' if '<meta name="viewport" content="width=device-width' in src else 'FAIL'
    r['개인경로·PC이름'] = 'FAIL' if re.search(r'C:\\Users|DESKTOP-02|OneDrive', src) else 'PASS'
    return r

new = 0; fb = fa = 0
for f in FILES:
    html = f.endswith('.html')
    d = os.path.dirname(os.path.join(OC, f))
    try: old = subprocess.run(['git', '-C', OC, 'show', f'{BASE}:{f}'], capture_output=True, check=True).stdout.decode('utf-8')
    except subprocess.CalledProcessError: old = None
    cur = open(os.path.join(OC, f), encoding='utf-8').read()
    a = check(old, d, html) if old is not None else None
    b = check(cur, d, html)
    print(f'== {f}' + (' (새 파일)' if old is None else ''))
    for key, bv in b.items():
        av = a[key] if a else '(없음)'
        fb += av.startswith('FAIL'); fa += bv.startswith('FAIL')
        line = f'  {key:<14} 전: {av:<34} 후: {bv}'
        if bv.startswith('FAIL') and not av.startswith('FAIL'): new += 1; line += '   ← 새 FAIL'
        print(line)
print(f'FAIL 합계 전 {fb} → 후 {fa} · 새로 생긴 FAIL: {new}')
sys.exit(new)

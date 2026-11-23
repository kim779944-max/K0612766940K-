"""detail.html · helper.js 명칭·통합 배선 (158·161·162·165 · 2026-11-23). usage: python patch_detail_helper.py <oneclick>"""
import os, sys
OC = sys.argv[1]

def patch(rel, pairs):
    p = os.path.join(OC, rel)
    b = open(p, 'rb').read(); crlf = b'\r\n' in b
    s = b.decode('utf-8').replace('\r\n', '\n')
    for a, c in pairs:
        assert s.count(a) == 1, (rel, a[:70], s.count(a))
        s = s.replace(a, c)
    if crlf: s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))
    print('ok', rel)

patch('detail.html', [
    # 통합된 상품으로 바로 들어오면 새 자리로(404·'찾지 못함' 금지)
    ('<meta charset="utf-8">\n',
     '<meta charset="utf-8">\n'
     '<script>/* 2026-11-23 통합: 문서변환기 → 더양식(158) · 창업·세무 → 사업자 대출(162) */\n'
     '(function(){var M={photo2doc:\'theform\',tax:\'loan\'},q=new URLSearchParams(location.search),k=q.get(\'k\')||\'theform\';\n'
     ' if(M[k]){q.set(\'k\',M[k]);location.replace(\'detail.html?\'+q.toString());}})();</script>\n'),
    ("const key = new URLSearchParams(location.search).get('k') || 'photo2doc';",
     "const key = new URLSearchParams(location.search).get('k') || 'theform';"),
    ("  var k = new URLSearchParams(location.search).get('k') || 'photo2doc';",
     "  var k = new URLSearchParams(location.search).get('k') || 'theform';"),
    ("  if (p.k === 'photo2doc') base.push(['사진 글자를 자동으로 읽나요?',",
     "  if (p.k === 'theform') base.push(['표 사진 글자를 자동으로 읽나요?',"),
    ("  if (p.k === 'tax') base.push(['세무 상담을 대신하나요?',",
     "  if (p.k === 'loan') base.push(['[창업·세무] 탭이 세무 상담을 대신하나요?',"),
    ("    loan:'어느 기관에 넣을지 몰라 여기저기 전화 문의',\n    tax:'창업 순서·통장·과세 유형을 몰라 처음부터 상담',",
     "    loan:'어느 기관에 넣을지, 창업 순서·통장·과세 유형은 어떻게 할지 몰라 여기저기 문의',\n"
     "    theform:'종이 양식·표 사진을 보며 한글·엑셀에 한 칸씩 다시 타이핑',"),
    ('<script src="products.js?v=20261122a"></script>', '<script src="products.js?v=20261123c"></script>'),
])

patch('helper.js', [
    ("    thedetail: { nm: '더상세', k: 'thedetail' },", "    thedetail: { nm: '설명서 제작기', k: 'thedetail' },"),
    ("    theform: { nm: '더양식', k: 'theform' },", "    theform: { nm: '더양식 (양식 채우기 · 표 변환 탭)', k: 'theform' },"),
    ("    converter: { nm: '문서변환기', k: 'photo2doc' },\n", ""),
    ("    loan: { nm: '대출 점검', k: 'loan' },\n    tax: { nm: '세무 점검', k: 'tax' },",
     "    loan: { nm: '사업자 대출 · 기업 대출', k: 'loan' },\n    tax: { nm: '사업자 대출 · 창업·세무', k: 'tax' },"),
    ("      { t: '01~09 쓰는 순서대로 고르기', d: '받은 서류 열기(01)부터 생활(08)까지, 하는 일 순서대로 늘어놓았습니다.', sel: ['#sections'] },",
     "      { t: '카테고리 칩 → 01~04 쓰는 순서대로 고르기', d: '부동산·중개(01) · 사업자·매장(02) · 서류·계약(03) · 생활·기록(04) — 칩을 누르면 그 묶음만 보입니다. 준비 중은 보기만 됩니다.', sel: ['#catChips', '#sections'] },"),
    ("      { t: '양식 고르기·등록', d: '표준 양식을 바로 쓰거나, 내 종이 양식 사진을 등록합니다.', sel: ['#s1'] },",
     "      { t: '양식 고르기·등록', d: '표준 양식을 바로 쓰거나, 내 종이 양식 사진을 등록합니다. 표 사진을 한글·엑셀로 바꾸려면 위쪽 [② 표 사진 → 한글·엑셀] 탭.', sel: ['#s1'] },"),
])

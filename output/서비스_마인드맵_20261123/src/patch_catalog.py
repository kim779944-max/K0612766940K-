"""catalog.json + products.js 원장 정리 (151·158·161·162·163·166 · 2026-11-23)
usage: python patch_catalog.py <oneclick 경로>  — 두 파일을 같은 배열로 다시 쓴다. 가격 숫자는 건드리지 않는다."""
import json, re, sys, os

OC = sys.argv[1]
cp, pp = os.path.join(OC, 'catalog.json'), os.path.join(OC, 'products.js')
cat = json.load(open(cp, encoding='utf-8'))
P = cat['products']
assert len(P) == 28, len(P)
by = {x['k']: x for x in P}
old_prices = {x['k']: (x.get('price'), x.get('price2')) for x in P}

# ── 158 · 162 : 두 항목 삭제 ──
tax = by['tax']
P = [x for x in P if x['k'] not in ('photo2doc', 'tax')]
by = {x['k']: x for x in P}

# ── 162 : 사업자 대출 하나로 (두 엔진 기능 모두 표기 · 가격 숫자 그대로) ──
L = by['loan']
L['nm'] = '사업자 대출'
L['sub'] = '기업 대출 · 창업·세무 — 한 화면 두 탭'
L['line'] = '어디에 넣을지, 무엇부터 할지 — 기업 대출과 창업·세무를 한 화면 두 탭으로.'
L['blurb'] = ('[기업 대출] 탭: 대차대조표·손익계산서 사진/PDF를 올리고 네 가지만 확인하면 재무비율·가능 기관·부족한 항목의 원인과 준비 순서가 나옵니다. '
              '[창업·세무] 탭: 직장 4대보험 유지 vs 개업 순서, 자금·통장 분리, 간이/일반·개인/법인 선택 기준과 세무사 확인용 체크리스트를 미리 정리합니다.')
L['price2'] = '실행계획 리포트 29,000원 · 세무구조 내비 19,000원(세무사 체크리스트 포함)'
L['bullets'] = [
    ['기업 대출', '재무제표 사진·PDF → 부채비율·이자보상배율·차입금의존도'],
    ['매칭', '소진공·신보·중진공·기보·시중은행 · 부족 항목 → 준비 순서'],
    ['창업·세무', '4대보험·등록·형태·대출·명의·통장 · 간이/일반 · 개인/법인'],
    ['출력', '진단서 인쇄 · 세무사 체크리스트 인쇄'],
]
L['how'] = ['위쪽 탭에서 [기업 대출] 또는 [창업·세무]를 고릅니다.',
            '기업 대출은 재무제표 숫자 8칸 + 확인 4가지, 창업·세무는 지금 상황을 고릅니다.',
            '진단서·체크리스트를 저장하거나 인쇄해 상담에 씁니다.']
L['notes'] = L['notes'] + tax['notes']

# ── 161 : 더상세 → 설명서 제작기 (경로 thedetail/ 유지) ──
D = by['thedetail']
D['nm'] = '설명서 제작기'
D['sub'] = '상품·매물 상세설명서 1초'
D['line'] = '사진 넣고 1초, 쿠팡형 상세설명서 — 부동산은 매물 브리핑으로.'
D['blurb'] = D['blurb'].replace('상세페이지', '상세설명서')
# how 의 '[1초 만에 상세페이지 만들기]' 는 도구 안 버튼 이름이라 그대로 둔다

# ── 166 : 세이캡 + 갤러리 ──
S = by['saycap']
S['nm'] = '세이캡'
S['sub'] = '말로 남기는 사진 기록 · 갤러리 한 곳'
S['blurb'] = '찍은 사진은 갤러리 한 곳에 모이고, 말하면 자막이 새겨져 단어 하나로 다시 찾습니다. 촬영 위치·지도·낙서·앨범 제목까지.'
S['bullets'] = [['기능', '음성 자막 · 단어 검색'], ['갤러리', '[촬영하기] · [갤러리보기] 한 앱 안에서'],
                ['보관', '원본 무손실'], ['추가', '위치 · 지도 · 낙서'], ['비용', '무료']]
S['how'] = ['사진을 찍고 말로 설명합니다.', '[갤러리보기]에서 모아 보고, 단어로 검색해 다시 꺼냅니다.']

# ── 160 : 오늘의 특가 문구 ──
by['sale']['line'] = '정가 대비 할인율 · 도매 대량 · 발주서 1초'

# ── 163 : 매물장 → 물건 포스터는 준비 중으로만 표기(버튼·링크 없음) ──
G = by['listing']
G['blurb'] = G['blurb'].rstrip() + ' 준비 중: 매물장에서 클릭 한 번으로 물건 포스터(A4).'
G['bullets'] = G['bullets'] + [['다음', '준비 중 — 매물장에서 사진만 넣으면 물건 포스터(A4)까지']]

# ── 158 : 더양식 = 양식 채우기 + 표 변환 탭 ──
F = by['theform']
F['nm'] = '더양식'
F['sub'] = '종이 양식 빈칸 채우기 · 표 사진 → 한글·엑셀'
F['blurb'] = F['blurb'] + ' [② 표 사진 → 한글·엑셀] 탭에서는 표 사진을 원본의 병합·열 너비·배경색 그대로 한글·엑셀 파일로 바꿉니다.'
F['bullets'] = F['bullets'] + [['표 변환', '표 사진 → 한글(.hwpx)·엑셀(.xlsx) · 병합·열 너비·배경색 유지']]

# ── cat 코드 통일 (쇼룸 섹션과 같게) ──
CAT = {'realty': ['slope', 'realty', 'listing', 'redev', 'exchange'],
       'biz': ['thedetail', 'commerce', 'keyword', 'sale', 'gagebu', 'tongyeok', 'loan', 'interior'],
       'doc': ['viewer', 'theform', 'sign', 'contract'],
       'life': ['organizer', 'saycap', 'navi', 'hogang', 'golf', 'petmind'],
       'soon': ['append', 'youtube', 'travel']}
for c, ks in CAT.items():
    for k in ks: by[k]['cat'] = c
assert all(x['cat'] in CAT for x in P), [x['k'] for x in P if x['cat'] not in CAT]

# ── 가격 숫자 불변 확인 ──
for x in P:
    a = re.findall(r'[\d,]+', ' '.join(filter(None, old_prices[x['k']])))
    b = re.findall(r'[\d,]+', ' '.join(filter(None, (x.get('price'), x.get('price2')))))
    if x['k'] == 'loan':
        a += re.findall(r'[\d,]+', ' '.join(filter(None, old_prices['tax'])))
    assert sorted(a) == sorted(b) or x['k'] == 'loan' and set(a) <= set(b), (x['k'], a, b)

assert len(P) == 26
cat['products'] = P
cat['count'] = len(P)
cat['v'] = '20261123c'
cat['updated'] = '2026-11-23T23:00:00+09:00'
with open(cp, 'w', encoding='utf-8', newline='\n') as f:
    f.write(json.dumps(cat, ensure_ascii=False, indent=1) + '\n')

s = open(pp, encoding='utf-8').read()
i = s.index('window.PRODUCTS = ') + len('window.PRODUCTS = ')
_, end = json.JSONDecoder().raw_decode(s[i:])
body = json.dumps(P, ensure_ascii=False, indent=1)
rest = s[i + end:]
rest = re.sub(r'\(2026-\d\d-\d\d 동기화 · \d+종\)', '(2026-11-23 동기화 · 26종)', rest, count=1)
with open(pp, 'w', encoding='utf-8', newline='\n') as f:
    f.write(s[:i] + body + rest)

# 검증: 두 파일이 같은 배열
s2 = open(pp, encoding='utf-8').read()
i2 = s2.index('window.PRODUCTS = ') + len('window.PRODUCTS = ')
p2, _ = json.JSONDecoder().raw_decode(s2[i2:])
c2 = json.load(open(cp, encoding='utf-8'))
print('catalog', len(c2['products']), 'products.js', len(p2), 'same', p2 == c2['products'], 'v', c2['v'])

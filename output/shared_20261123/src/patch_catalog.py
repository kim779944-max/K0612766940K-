"""133번: gagebu 이름 통일 + listing(준비 중) 등록 — products.js · catalog.json 동시."""
import io, json, sys, os

oc = sys.argv[1]
LISTING = {
    "k": "listing", "nm": "매물장 뷰어", "sub": "매물 하나가 영업하는 홈페이지 · 명함·A4",
    "cat": "realty", "badge": "준비", "status": "soon", "icon": "shots/ic_listing.png",
    "price": "무료", "price2": "1호 무료 · 문자·카톡 매물 자동 정리",
    "line": "매물 하나가 중개사 명함과 홈페이지를 달고 다닙니다.",
    "blurb": "매물 정보와 사진 2~4장을 넣으면 세아빌딩형 매물장이 만들어집니다. 감정가 대비·수익률 요약, 제원 2열 표, 층별 임대차, 사업자 명함(연락처 저장·전화·문자), 비공개 매물 구분, A4 210×297mm 한 장 인쇄까지.",
    "link": "", "bullets": [["요약", "매매가·보증금·월세·수익률"], ["제원", "9항목 2열 표"], ["명함", "vcf 저장·전화·문자"], ["인쇄", "A4 210×297mm 한 장"]],
    "how": ["매물 정보와 사진 2~4장을 넣습니다.", "요약·제원·층별 임대차를 확인합니다.", "명함을 붙이고 [A4 인쇄]로 한 장을 뽑습니다."],
    "notes": ["예시 매물입니다. 실제 투자 판단은 계약 조건과 공부(公簿) 확인이 기준입니다.", "이 사이트는 결제를 받지 않습니다."],
    "shot": "shots/listing_home.png"
}
OLD_NM, NEW_NM = '"nm": "원클릭 가계부"', '"nm": "결제문자 가계부"'
OLD_SUB, NEW_SUB = '"sub": "오늘 산 것 자동 정리 · 더 싼 곳 1초 비교"', '"sub": "카드 결제 문자를 붙여넣으면 정리"'

# ---- catalog.json (원래 서식 그대로: indent=1)
cp = os.path.join(oc, 'catalog.json')
raw = io.open(cp, encoding='utf-8').read()
d = json.loads(raw)
same = json.dumps(d, ensure_ascii=False, indent=1) == raw.rstrip('\n')
print('catalog 재직렬화 동일:', same)
assert raw.count(OLD_NM) == 1 and raw.count(OLD_SUB) == 1
raw = raw.replace(OLD_NM, NEW_NM).replace(OLD_SUB, NEW_SUB)
d = json.loads(raw)
assert not any(p['k'] == 'listing' for p in d['products'])
d['v'] = '20261123a'
d['updated'] = '2026-11-23T13:30:00+09:00'
d['products'].append(LISTING)
d['count'] = len(d['products'])
out = json.dumps(d, ensure_ascii=False, indent=1) + ('\n' if raw.endswith('\n') else '')
io.open(cp, 'w', encoding='utf-8', newline='\n').write(out)

# ---- products.js (배열 맨 끝에 1개)
pp = os.path.join(oc, 'products.js')
s = io.open(pp, encoding='utf-8').read()
assert s.count(OLD_NM) == 1 and s.count(OLD_SUB) == 1
s = s.replace(OLD_NM, NEW_NM).replace(OLD_SUB, NEW_SUB)
end = s.index('\n];')
item = json.dumps(LISTING, ensure_ascii=False, indent=1)
item = '\n'.join(' ' + ln for ln in item.split('\n'))
s = s[:end] + ',\n' + item + s[end:]
io.open(pp, 'w', encoding='utf-8', newline='\n').write(s)
print('catalog', d['v'], d['count'], len(d['products']))

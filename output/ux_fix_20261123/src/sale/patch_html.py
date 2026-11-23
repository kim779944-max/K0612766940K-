import io, re, sys
p = sys.argv[1]
s = io.open(p, encoding='utf-8', newline='').read()
CRLF = chr(13)+chr(10) in s
s = s.replace(chr(13)+chr(10), chr(10))


def rep(a, b, regex=False):
    global s
    if regex:
        n = len(re.findall(a, s, re.S)); assert n == 1, (a[:60], n)
        s = re.sub(a, lambda m: b, s, flags=re.S)
    else:
        assert s.count(a) == 1, (a[:60], s.count(a)); s = s.replace(a, b)


rep('<title>[^<]*</title>', '<title>오늘의 특가 — 정가 대비 할인율 높은 순 & 1초 발주서</title>', True)
rep(r'<meta name="description" content="[^"]*">',
    '<meta name="description" content="정가 대비 얼마나 싼지 그대로 보여 줍니다. 도매 대용량·유통기한 임박 땡처리부터 편의점 1+1·2+1까지 식자재·공산품·생활용품으로 묶어 할인율 높은 순으로. 체크하면 장보기·카톡 발주서가 1초에 만들어집니다.">', True)
rep(r'<meta property="og:title" content="[^"]*">', '<meta property="og:title" content="오늘의 특가 — 정가 대비 할인율 높은 순">', True)
rep(r'<meta property="og:description" content="[^"]*">',
    '<meta property="og:description" content="정가 대비 얼마나 싼지 그대로 · 도매 대용량·땡처리부터. 체크하면 발주서가 1초에 나옵니다.">', True)
rep(r'<span class="kicker">.*?</p>',
    '<span class="kicker">정가 대비 얼마나 싼지 그대로</span>\n'
    '    <h1>오늘 <em>특가만</em>, <em>발주서 1초</em></h1>\n'
    '    <p class="lead"><b>도매 대용량·땡처리</b>부터 편의점 1+1까지 — 정가와 비교해 할인율 높은 순으로.</p>', True)
rep(r'  <div class="tabs" id="tabs"></div>\s*<div class="filters" id="filters">.*?</div>',
    '''  <section class="whb" id="whb" aria-label="오늘의 도매 특가">
    <div class="whh"><b>오늘의 <em>도매 특가</em></b><span>박스·업소 대용량 · 유통기한 임박 땡처리</span></div>
    <div class="whs" id="whWhole"></div>
    <div class="whs" id="whDdang"></div>
  </section>

  <div class="tabs" id="tabs"></div>
  <div class="filters" id="filters">
    <button class="on" data-f="all">전체</button>
    <button data-f="half">40% 이상</button>
    <button data-f="bogo">1+1</button>
    <button data-f="today">오늘 끝</button>
    <button data-f="each">개당 최저가순</button>
  </div>''', True)
# 번개알바 배너 2개 제거 (156 원칙)
rep(r'    <a class="bn dark" href="https://bungaealba\.kr/".*?</a>\n', '', True)
rep(r'    <a class="bn" href="https://bungaealba\.kr/".*?</a>\n', '', True)
rep(r' · <a href="https://bungaealba\.kr/"[^>]*>번개알바</a>', '', True)
rep(r'    값은 마트 전단과 각 사 공개 행사 페이지에서.*?<b>결제 전 매장에서 확인하세요\.</b><br>',
    '    <span id="footNotice"></span><br>\n'
    '    정가는 같은 상품·같은 규격의 할인 전 값이 확인된 것만 적었습니다. 편의점 1+1·2+1 의 정가는 공식 행사목록의 1개 값 × 집는 개수입니다.<br>', True)
rep(r'<p class="tip">값은 2026-11-17 기준 특가이고.*?</p>',
    '<p class="tip" id="sheetTip">1+1·2+1 품목은 묶음 수량으로 계산했습니다. 결제 전 매장에서 확인하세요.</p>', True)
rep('helper.js?v=20261122a', 'helper.js?v=20261123a')
io.open(p, 'w', encoding='utf-8', newline='').write(s.replace(chr(10), chr(13)+chr(10)) if CRLF else s)
print('ok')

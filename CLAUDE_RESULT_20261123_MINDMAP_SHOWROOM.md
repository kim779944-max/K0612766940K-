# 결과 — 2026-11-23 서비스 마인드맵 확정 → 쇼룸 버튼 구조 전개 (148·151·152·156·158·161·162·163·165·166)
시작 HEAD: oneclick `fc16cda` / K0612766940K- `f3aabe3`
끝   HEAD: oneclick `b30a19f` / K0612766940K- (이 보고서 커밋 — `git log -1` 참조)
커밋(단계 순서):
- §2 마인드맵 — K0612766940K- `70eac5c` docs(mindmap): 서비스 마인드맵 확정 — 쓰는 순서 축 4대분류+준비 중 · 배치표·현행 대조표·148 겹침표 · PNG 3574px · 쇼룸 버튼구조
- §3 쇼룸 — oneclick `6d95e65` feat(showroom): 마인드맵대로 쇼룸 재배치 — 4대분류+준비 중 · 커밍순 보이기만 · 카테고리 칩 필터 · 원장 26종 · 번개알바·답글생성기 제외
- §4-1 — oneclick `3ff43d7` feat(theform): 문서변환기 → 더양식 ② 탭 통합 (158)
- §4-3 — oneclick `2d85b78` feat(loan): 사업자 대출 — loan·tax 공통 탭 양방향 (162)
- §4-2 — oneclick `bdfc741` fix(thedetail): 더상세 → 설명서 제작기 — 제목·머리 브랜드·바닥 문구 (161)
- §4-1 보완 — oneclick `b30a19f` fix(converter): 이동 안내 페이지 noindex 제거 — sitemap 항목 유지
- §5 결과 — K0612766940K- 이 보고서 + 실측·캡처·게이트

**판정: 최소 합격선 전부 충족** — 마인드맵 MD+PNG · 실질 우선·커밍순 비활성 · 중복 0 · 통합 4건(158·161·162·166) · 제외 2건(156·165). 게이트는 아래 §6 설명대로 "새 연락처 0, 기존 대표번호 위치 이동만"이다.

## 1. 저장소·기준
- pull 결과: oneclick `fc16cda`(기준 `16ccac8` 보다 2커밋 앞: 146·147번) → 원격 변경 없음, 그대로 작업. K0612766940K- `f3aabe3`(기준 `a807af1` 이후 문서 커밋) → 원격 변경 없음.
- oneclick 바뀐 파일(+/−줄, `fc16cda..b30a19f`):
  | 파일 | + | − |
  |---|---|---|
  | catalog.json | 65 | 136 |
  | products.js | 63 | 134 |
  | index.html | 73 | 30 |
  | detail.html | 10 | 7 |
  | helper.js | 6 | 7 |
  | converter.html | 10 | 2133 (안내+이동 페이지로) |
  | theform/index.html | 42 | 0 |
  | theform/convert.html (새) | 461 | 0 |
  | theform/js/converter.js (새) | 1680 | 0 |
  | loan.html | 20 | 0 |
  | tax.html | 20 | 0 |
  | thedetail/index.html | 3 | 3 |
- 손대지 않은 것 확인: `bungee/`·`ad_magnet/` diff **0줄** · `sitemap.xml` **무변경** · slope/listing/sale/navi2/redev/interior/sign/viewer.html/thescan/theeraser **무변경**.
- 되돌리기: `git -C oneclick revert b30a19f bdfc741 2d85b78 3ff43d7 6d95e65` (순서대로) · 마인드맵 문서는 `git revert 70eac5c`.

## 2. A. 마인드맵 (152)
- 산출물 4종 (`output/서비스_마인드맵_20261123/`):
  | 파일 | 크기 |
  |---|---|
  | 마인드맵.md (트리 + 표 ①배치표 ②현행 대조표 ③시중 겹침표) | 14,227 B |
  | 마인드맵.png — 수평 좌→우, **3574×3009px**, 딥네이비 #0B1730·오렌지 #FF6B00 | 489,289 B |
  | 쇼룸_버튼구조.md (GROUPS 코드 그대로 + 섹션별 카드 문구) | 6,521 B |
  | 겹침표_요약.md (● / △ / ○ 3분류) | 2,215 B |
  - 다시 뽑기: `python -X utf8 src/make_mindmap.py .` (HTML → Chrome 캡처, 문구는 `TREE` 만 고치면 됨)
  - PNG 자동 검사: 노드 겹침 **0** · 글자 잘림(scrollWidth>clientWidth) **0** · 노드 31개. 육안으로도 한글 잘림 없음 확인.
- 트리는 지시서 §2-2 그대로(임의 변경 없음). 판단 근거 5개는 `마인드맵.md` 에 옮겨 적었다.
- 상품 커버리지: 카탈로그 28종 + LOCAL 4종(thescan·theeraser·seller·ad_magnet) = **32항목이 배치표에 1회씩 Y** · 중복 **0**. 이 중 통합 2(photo2doc→더양식, tax→사업자 대출) · 쇼룸 제외 1(ad_magnet) → **쇼룸 카드 29장**.
- 148 표시(30행 = 쇼룸 카드 29 + 물건 포스터 1): **● 2 · △ 14 · ○ 14** (합계 30). 지니 1차 판정은 그대로 옮김. 지니 표에 없던 유튜브 1초 최적화(○)·여행 패스(△) 2건만 PC가 추가 판정하고 근거를 적음(대표님 판정 대기).

## 3. B. 쇼룸 구조 (151)
- GROUPS: 01 부동산·중개 **5** · 02 사업자·매장 **9** · 03 서류·계약 **6** · 04 생활·기록 **6** · 05 준비 중 **3** (= `쇼룸_버튼구조.md` 와 순서·글자 1:1)
- 커밍순: `.row.soon` **3** · 그 안 `<a>` **0 → Y** · pointer-events **none ×3** · opacity 0.58 + grayscale(.3) · 카드 클릭 10회 URL 변화 **0** (작업 전: **10/10회 상세로 이동** — `before_soon_card_click.png`)
  - 렌더: 준비 중은 `<div class="main" role="presentation">`, 카드에 `aria-disabled="true"`, `준비 중` 배지만(NEW·무료 배지 없음), `[data-open]` 위임 핸들러도 soon 이면 즉시 return. FEATURED(renderFeat)도 같은 규칙.
- 직접 진입(`detail.html?k=append`): **'출시 준비 중'** (버튼 href `#`) · 도구 화면 진입 0
- 중복 k: **0개** (interior + bungee_interior 중복 해소)
- 카테고리 칩: `전체·부동산·중개·사업자·매장·서류·계약·생활·기록·준비 중` 6개 · [서류·계약] 누르면 `sec03` 만 보임 · 새로고침 후에도 `sec03`만 + 칩 유지(localStorage `kts_cat_chip`) · [전체] → 5섹션. 히어로 [무료로 시작하기]가 숨은 섹션을 가리키면 자동으로 '전체'로 돌림.
- 첫 뷰포트 soon 카드: **0**
- 카탈로그에 없는 LOCAL(더스캔·더지우개·셀러)은 카드 제목이 '상품을 찾지 못했습니다' 상세로 가던 것을 → [열기]와 같은 동작으로 바꿈(빈 상세 0).
- 원장: catalog.json·products.js **양쪽 26종 · 배열 완전 일치** · `v` = `20261123c` · cat 코드 `realty/biz/doc/life/soon` 로 통일 · 가격 숫자 불변(스크립트에서 assert) · sale `line` = '정가 대비 할인율 · 도매 대량 · 발주서 1초'.
- sitemap.xml: **무변경**. (`detail.html?k=`·gallery 0건 확인. 단 `converter.html` 항목 1건이 있어 이동 페이지에서 noindex 를 빼고 canonical → `theform/?tab=convert` 만 둠)

## 4. C. 통합·제외
- **158 문서변환기→더양식**: 탭 **2개**(① 종이 양식 채우기 · ② 표 사진 → 한글·엑셀) · `theform/?tab=convert` → ② 탭 선택 상태로 열림 · `converter.html` → `theform/?tab=convert` **이동 확인(404 0)**.
  - 엔진: converter.html 본 스크립트를 `theform/js/converter.js` 로 **그대로 복사**(바꾼 것은 `tpl/`·`viewer.html` 경로를 `../` 로, 뷰어·문자 이동을 겉 창으로 하는 4곳뿐). 화면은 `theform/convert.html` 로 옮겨 ② 탭 안에 iframe 으로 띄움(두 엔진 전역 변수·id 충돌을 막기 위해 한 문서에 섞지 않음). 탭 안에서는 변환기 머리줄·도우미·더양식 무료 띠를 숨겨 머리줄 1개.
  - 변환 결과 실측(같은 시험 표 사진 `conv_test/test_table.png` · 열 너비 3:2:1:2 · 머리 2칸 병합 · 배경색 2종, 기기 안 OCR 경로):
    | 비교 | 이관 전 converter.html | 더양식 ② 탭 | 같음 |
    |---|---|---|---|
    | hwpx 셀 너비 | 26220/5244/10488/15732… | 동일 | Y |
    | hwpx 병합 | colSpan 2 ×1 | 동일 | Y |
    | hwpx 배경색 | #D6E4FA · #FFD6AA | 동일 | Y |
    | xlsx 열 너비 | 39 / 26 / 13 / 26 (=3:2:1:2) | 동일 | Y |
    | xlsx 병합 | A1:B1 | 동일 | Y |
    | xlsx 배경색 | FFD6E4FA · FFFFD6AA | 동일 | Y |
    | 파일 크기 | hwpx 6,563 B · xlsx 2,780 B | 동일 | Y |
    결과 파일·전문: `conv_test/` · `conv_compare.txt` · 나란히 캡처 `captures/after_convert_compare.png`
  - ① 탭(양식 채우기)은 146번 자동 빈칸 포함 기존 스크립트 무변경(마크업·CSS·탭 스크립트만 덧붙임).
- **161 더상세→설명서 제작기**: 쇼룸 화면 '더상세' **0건** · '설명서 제작기' **1** · `detail.html?k=thedetail` 제목 '설명서 제작기' · '더상세' 0 · `thedetail/` 경로 유지 **Y** · 도구 `<title>`·머리 브랜드·바닥 문구 교체.
- **162 대출 통합**: 쇼룸 카드 **1**(loan, '사업자 대출') · tax 카드 0 · 기업 엔진 **동작**([예시 값]→[진단하기] → 부채비율·기관 매칭 5종·인쇄 버튼) · 창업 엔진 **동작**([결과 보기] → `#outBox` 2,238자) · 탭 이동 **양방향**(loan → `tax.html?tab=biz` → loan) · `detail.html?k=tax` → `k=loan` 로 이동. 가격 숫자 29,000원·19,000원 그대로 price2 에 함께 표기.
- **163 부동산 흐름 표기**: 마인드맵·쇼룸_버튼구조·GROUPS 부제 '경사도 → 매물수집 → 매물장 → 물건 포스터' **반영** · listing blurb/bullets 에 **'준비 중:'** 명시 · 물건 포스터 카드/버튼/링크 **만들지 않음 확인**.
- **166 세이캡+갤러리**: 쇼룸 카드 **1**('세이캡 · 말로 남기는 사진 기록 · 갤러리 한 곳') · 갤러리 별도 카드 0 · `saycap/` [촬영하기] → camera 화면 **동작** · [갤러리보기] → gallery 화면 **동작** · 발견한 gallery URL **없음**(카탈로그·sitemap·링크 0건, 더스캔 내부 변수명만 있음 → 처리 불필요).
- **156·165 제외**: ad_magnet 카드 0·푸터 0·**폴더 유지(diff 0)** · bungee_* 카드 0·푸터 '번개알바 도구' 링크 제거·**폴더 diff 0** · ops 링크: 마스터 모드 그리드(`#mst`, 마스터일 때만 보임) 안에만 있음 — 손님 화면 보이는 ops 링크 **0**. 마스터 그리드에서도 답글생성기·번개알바 링크는 빼고 셀러·더스캔·더지우개·상황판만 둠.

## 5. 검증 숫자 (Chrome 390×844 · `?t=<타임스탬프>` · 로컬 + 라이브 동일)
| 항목 | 기대 | 실측(로컬) | 실측(라이브 autooneclick.com) |
|---|---|---|---|
| 섹션 수 | 5 | 5 | 5 |
| 카탈로그 종수 | 26 | KTS_CATALOG 26 · PRODUCTS 26 · v 20261123c | 동일 |
| 중복 k | 0 | 0 | 0 |
| 커밍순 `.row.soon` / `<a>` / pointer-events / 클릭 10회 URL 변화 | 3 / 0 / none / 0 | 3 / 0 / none×3 / 0 | 3 / 0 / none×3 / 0 |
| `detail.html?k=append` | 출시 준비 중 | 출시 준비 중 | 출시 준비 중 |
| 첫 뷰포트 soon | 0 | 0 | 0 |
| ad_magnet·bungee 카드 / 푸터 | 0 / 0 | 0 / 0 | 0 / 0 |
| photo2doc / tax / loan 카드 | 0 / 0 / 1 | 0 / 0 / 1 | 0 / 0 / 1 |
| converter.html | → theform/?tab=convert | 이동 | 이동 |
| '더상세' / '문서변환기' / '설명서 제작기' | 0 / 0 / ≥1 | 0 / 0 / 1 | 0 / 0 / 1 |
| 세이캡 카드 / 갤러리 카드 | 1 / 0 | 1 / 0 | 1 / 0 |
| 카테고리 칩 | 6 · 필터 · 유지 | 6 · sec03만 · 새로고침 후 유지 | 동일 |
| scrollWidth | 390 | 390 (쇼룸·더양식 ②탭·loan) | 390 |
| 콘솔 에러 / 404 | 0 / 0 | 0 / 0 (쇼룸·상세·더양식 ②탭·loan·tax·변환) · 세이캡은 페이지 오류 0 | 0 / 0 |
| 새 외부 도메인 | 0 | 0 (쇼룸 요청 호스트 = 자기 도메인만 · 변환기 CDN 은 기존 jsdelivr/unpkg/tessdata 그대로) | 0 |
| 마인드맵 PNG | 폭 ≥3200 | 3574×3009 · 489,289 B · 잘림 0 | — |
- 전문: `measure_before.txt` · `measure_after.txt` · `measure_live.txt` · `loan_tax_test.txt` · `saycap_test.txt` · `conv_compare.txt`
- 캡처 (`captures/`):
  1. `before_showroom_top.png` · `before_soon_card_click.png`(커밍순 카드 → 상세로 넘어간 화면)
  2. `mindmap.png`
  3. `after_showroom_top.png`
  4. `after_section_01.png` ~ `after_section_04.png`
  5. `after_soon_row.png`
  6. `after_chip_filter.png` · `after_chip_persist.png`
  7. `after_theform_convert_tab.png` · `after_theform_form_tab.png` · `after_converter_redirect.png` · `after_convert_compare.png`
  8. `after_loan_tabs.png` · `after_loan_result.png` · `after_tax_tabs.png` · `after_tax_result.png`
  9. `after_saycap_card.png` · `after_saycap_gallery.png`
  10. `after_no_admagnet_footer.png` · (추가) `after_detail_append.png`

## 6. 게이트
- `output/kts_gate.py` 는 저장소에 없다(이전 회차들도 이식판 사용). 같은 G1 검사(태그 짝·Base64·API키·연락처·내부 링크·viewport·개인경로)를 파이썬으로 옮긴 `src/kts_gate_port.py` 로 **바뀐 파일 12개 전부**를 전(`fc16cda`)/후로 돌렸다. 전문 `gate.txt`.
- 결과: **FAIL 항목 전 8 → 후 9 · 표시상 '새 FAIL' 2** — 둘 다 G1-6(연락처)이고 새 파일 `theform/convert.html`·`theform/js/converter.js` 에 **converter.html 에 있던 대표번호 010-2002-2899 가 옮겨 온 것**이다(converter.html 은 FAIL 2 → PASS 0).
  - 적중 문자열 전체: 전 **22건** {010-2002-2899, 01020022899, 010-0000-0000·010-1234-5678(입력 예시), sample@example.com} → 후 **22건** 같은 집합. **새 번호·새 이메일 0.**
  - G1-6 FAIL 은 지시서 0-2-7("기존 010-2002-2899 표기는 그대로 둔다")에 따라 없앨 수 없는 대표번호 표기라 기준 커밋에서부터 8개 파일이 FAIL 이었다. 지시서 대상 3파일(index.html·products.js·catalog.json) 기준으로는 **전/후 동일**(index.html G1-6 FAIL 6 → 6, 나머지 전부 PASS).
  - 그 밖 G1-2·G1-3·G1-5·G1-8·G1-9·개인경로: **전 파일 PASS**.

## 7. 라이브
- 푸시 `fc16cda..b30a19f` 2026-11-24 00:01 KST → 00:02 배포 확인.
- `curl https://autooneclick.com/?t=…` 원문에서 "설명서 제작기" **안 잡힘(0)** — 쇼룸 이름은 index.html 원문이 아니라 catalog.json 에서 그리기 때문이다. `catalog.json` 원문 **1건 잡힘**, Chrome 으로 연 라이브 화면 **1건**(§5 라이브 열). 2026-11-24 00:03 KST.
- 라이브 `theform/js/converter.js`·`theform/?tab=convert`·`loan.html`(bizTabs)·`thedetail/`(설명서 제작기)·`converter.html`(이동) 전부 200 + 새 내용 확인.

## 8. 남은 것 / 판단이 필요한 것
- 물건 포스터 구현(매물장에서 클릭 → A4 포스터)은 다음 회차 — 이번엔 마인드맵·준비 중 문구만.
- 설명서 제작기가 **만들어 내는 결과물 안** 워터마크·파일명('KTS 더상세', `KTS_더상세_….png`)과 [하단에 KTS 더상세 표시 넣기] 체크 문구는 렌더 로직 안 문자열이라 이번엔 두었다(배지 폭 계산과 붙어 있음). 바꿀지 판단 필요.
- 범위 밖 페이지의 '더상세' 링크 글자: `ecommerce/*.html`(7개 파일 8곳)·`exchange/index.html`·`saycap/index.html`·`sale/index.html`·`navi2/index.html`·`viewer.html`·옛 `thedetail.html` — 지시서 대상 파일이 아니거나 '손대지 않는 것'이라 그대로. 다음 회차 일괄 교체 권장.
- helper.js 이름 사전의 `ad_magnet`·`bungee` 항목은 해당 폴더(내부용·별도 플랫폼) 페이지에서 도우미 제목으로만 쓰여 쇼룸 노출과 무관해 유지.
- 148 겹침표 유튜브(○)·여행 패스(△) PC 추가 판정 — 대표님 최종 판정 대기.
- 더양식 ② 탭과 쇼룸 첫 화면에서 왼쪽 아래 [? 도우미] 버튼(133번 위치)이 하단 첫 버튼/첫 칩 일부를 덮는다(기존 위치 그대로 · 클릭은 각각 가능). 위치 조정은 helper.js 쪽 회차에서.

# 결과 — 2026-11-23 공통 틀 + 쇼룸 개편 + 검수 2건 (133·138번)
시작 HEAD: oneclick `631fa3a` / K0612766940K- `5d3226f`
끝   HEAD: oneclick `d4f5ca0` / K0612766940K- (이 보고서 커밋 — `git log -1` 참조)
커밋(oneclick, origin/main 푸시 완료):
- `89e7335` feat(shared): 공통 틀 1벌 — 다크/라이트 토큰·헤더·카드·44px 버튼·인쇄 규칙 (138번)
- `311e766` feat(showroom): 대표 3종 → 4대 업종 묶음 개편 + 다크/라이트 토글 · 가계부 이름 통일 · 매물장 뷰어 준비 중 등록 (133·138번)
- `d4f5ca0` fix(helper): 도우미 버튼이 카드 [열기]/[+]를 가리지 않게 — 390 왼쪽 아래 48px · 넓은 화면 본문 바깥 (133번)

되돌리기: `git -C oneclick revert d4f5ca0 311e766 89e7335` (또는 `git reset --hard 631fa3a` 후 강제 푸시 — 비권장)

## 1. 저장소
- pull 결과: `631fa3a` → `631fa3a`(이미 최신). 기준선 `d6f95a9` 위에 1순위 `631fa3a feat(slope)…(137번)`이 이미 올라가 있었고, 그 위에 쌓았다.
- 1순위(slope)와 충돌: **없음**. 이번 변경은 `slope/` 를 건드리지 않는다(`git diff 631fa3a HEAD -- slope sign theform contract viewer.html realty redev gagebu sale` = 0줄). 푸시 직전 `pull --rebase` 도 새 커밋 없음.
- 3순위(매물장 뷰어)는 아직 시작 전 — `listing/` 폴더 없음 확인.

## 2. 시안에서 읽은 값 (`refs/v0_listing_20261123/app/globals.css`)
- 색 5: `--bg:#0b132b` · `--panel:#141f38` · `--line:#2a354e` · `--muted:#a5b1c7` · `--accent:#ff6b00` (+ 글자 `#f4f6fb`, 포커스 `#ff994b`)
- radius **12px**(hero 14px) · 카드 padding **21px 23px**(390은 16px) · 본문 **15px** · 섹션 제목 **19px/690** · 표 칸 **11px 12px** · 표 머리 `#1d2942` 12px
- 터치: 시안 자체엔 최소 높이 규칙 없음 → 지시서대로 **44px**(`--k-tap`)
- 폰트 판단: **시스템 폰트 사용**(`--k-font`). 시안의 `pretendard.woff2`(약 2MB)를 폰에서 첫 방문마다 내려받게 하면 첫 화면이 늦어지고 데이터 손해 — 맑은고딕/Apple SD 고딕으로 충분.

## 3. 공통 틀 (shared/)
| 파일 | 용량 | 줄 |
|---|---|---|
| `kts-tokens.css` | 1,876B | 34 |
| `kts-ui.css` | 4,117B | 65 |
| `kts-print.css` | 1,249B | 21 |
| `kts-ui.js` | 2,580B | 57 |
| `README.md` | 1,847B | 29 |
- 토큰 변수: 다크 **17** / 라이트 **17** / 공통 19(radius·간격·글자·tap·그림자·폰트). 오렌지 `#ff6b00` 두 벌 동일.
- 지시서 값 그대로 + 추가 3개(두 벌 모두): `--k-hd-bg`(헤더 반투명 바탕), `--k-tog-on`(켜진 토글 글자 `#ffd9a6`/`#a2410a`), `--k-glow`(기존 쇼룸 상단 은은한 빛).
- 배지 `.k-badge`: 지시서는 무료 초록·PRO 오렌지·NEW 파랑·준비 회색이었지만, 같은 칸에 "기존 `BADGE` 색값과 같게"가 함께 있어 **기존 쇼룸 값 그대로**(무료 `#4ade80` · PRO 금색 · NEW 오렌지 · 준비 `#fcd34d`) 썼다. 바꾸려면 `kts-ui.css` 4줄만 고치면 된다.
- 테마: `<html data-kts-theme="dark">` 마크업 고정 → JS 없이 다크. `kts-ui.js` 가 `localStorage['kts_theme']` 를 읽어 덮어쓰고 ☾/☀ · `aria-pressed` · `aria-label`("밝게 보기"/"어둡게 보기")을 채운다. 서버 전송 없음.
  - 실측: 시작 `dark`(저장값 null) → 토글 `light`(저장 `light`, 바탕 `rgb(246,247,249)`) → 새로고침 **라이트 유지** → 토글 `dark` → 새로고침 **다크 유지**.
- 인쇄 강제 라이트: 다크·라이트 두 상태 모두 `print` 에서 body `rgb(255,255,255)` · 이름/제목 글자 `rgb(17,24,39)` · 헤더/테마 버튼/도우미 `display:none`. 캡처 `output/shared_20261123/print_a4.png`, `print_preview_dark.png`, `print_preview_light.png`, PDF `print_a4.pdf`.
- 적용 범위: **`index.html` 만** 링크(다른 도구 페이지 0건 — `grep -l "shared/kts-" -r` 결과 index.html 1개).

## 4. 쇼룸 개편
- 순서(실측 DOM): 헤더(+공지 띠) → 히어로 → **대표 3종** → 내 박스 → `#allGroups`(01~04 업종 + 05 준비 중) → 쿠폰 → 해주세요 → 안내문 → 푸터
- 히어로: "반복 업무, 클릭 한 번으로 끝내세요" / 부제 시안 문구 / `[무료로 시작하기]`(→`#sec01`) `[도구 전체 보기]`(→`#allGroups`, 클릭 후 묶음 머리가 헤더 바로 아래 y=109). **`[가격 보기]`·요금표 없음.**
- 목록 완전성(콘솔 스크립트, `window.__KTS_GROUPS` 읽기 전용 노출 1줄 추가): **products 28 + LOCAL 7 = 전체 35 · 묶음 35 · 누락 [] · 중복 [] · 엉뚱한 키 []** · 화면 행 35개. 묶음별 01 부동산·중개사 10 / 02 쇼핑몰·셀러 7 / 03 자영업·매장 8 / 04 개인·생활 7 / 05 준비 중 3.
- 대표 3종 y좌표(390×844, 카드 위~아래): ① 매물장 뷰어 336~428 ② 더싸인 436~533 ③ 토지정보(경사도) 541~633 → **3장 모두 844 안**. 첫 카드만 오렌지 1px 테두리, 카드 높이 92~97px.
  - 표시명은 `nm.split(' — ')[0]` 규칙 그대로라 ③은 "토지정보(경사도)"로 뜬다(`products.js` nm 무변경).
  - 한도 배지: `KTS_KEYS.freeText()` 값을 그대로 씀 → 더싸인 "한 장 무료", 경사도는 무료 문구가 없어 배지 없음, 매물장 뷰어 "준비 중".
- 보존 기능: 내 박스 strip/`KTS_KEYS` 관문 **확인**(같은 기기에서 경사도 두 번째 열기 → 박스 안내창 뜸, `gate_second_open.png`) · 마스터 `?master=2899` **확인**(패널 표시, `mstN`=23 = live 23) · 해주세요 버튼 **확인** · 무료 이용권 `sms:01020022899` **확인** · `master.js/products.js/slots.js/status.js/helper.js` 로드 **확인** · `detail.html?k=` 링크 39개 · 맨 위로 버튼 **확인**.
  - `[★ 내 단축바]` 탭: `index.html` 안에는 원래 이 이름의 요소가 없다(박스 strip이 그 역할). 이번에 지운 것 없음 — 대표님이 말한 탭이 다른 화면이면 알려 주세요.
- 헤더 우측 `[☾/☀]` 44×44 — 열쇠·마스터·전화 왼쪽. 390에서 헤더 한 줄 56px, 1280에서 68px, 가로 넘침 없음.
- 390 글자 10.5px 미만 0개(배지·한도·공지 띠·박스 칸 글자를 10.5px로 올림 — 쇼룸 CSS 덮어쓰기만, slots.js 무변경).
- 푸터: `케이티에스 원클릭` · `tel:` 010-2002-2899 · "올린 파일은 서버로 보내지 않고…" 유지.
  - **이용약관·개인정보처리방침 링크는 걸지 않았다** — 저장소에 해당 페이지가 없어 링크하면 404가 된다. 대신 "준비 중(결제·회원가입이 없어 따로 모으는 개인정보가 없습니다)" 문구만 넣었다. 법적 문서를 지어내지 않았다(아래 '확인 필요').

## 5. 수리 2건
- helper(133-①):
  - `helper.js` — ≤719px: `left:10px; bottom:calc(10px + safe-area); 48×48` / ≥720px: `left:max(10px, calc(50% - 300px))`. 버튼 크기 44px 이상 유지, 숨김·`pointer-events:none` 안 씀.
  - 위치 계산 `place()` 수정: 예전엔 `.totop` 이 어디 있든 무조건 그 위로 올렸다 → **같은 세로줄에 있고 도우미 자리보다 아래에서 시작할 때만** 피하도록. 인라인 bottom 은 바닥 바가 있을 때만 쓴다(그 외에는 CSS 자리).
  - `index.html` `.totop` → 왼쪽 `left:10px; bottom:calc(66px + safe-area)`(넓은 화면 76px) · `#app{padding-bottom:96px}`.
  - 390 스크롤 3곳(y=0 / 2001 / 3158): 화면 안 `.act .go`·`.soonb`·박스 칸 9/11/4개 대비 **도우미 교차 0 · 위로 교차 0**(전 위치). 1280: 도우미 (340, bottom 14px) · 위로 (340, bottom 76px) — 본문(360~920) 바깥, 교차 0.
  - `[열기]` 클릭: 4묶음 2개씩 8/8 → realty·slope·ecommerce·thedetail·gagebu·loan.html·sale·hogang **전부 200**. 대표 3종 더싸인·경사도 2/2 200 + `history.back()` 복귀 확인. (합계 10/10)
  - 남는 점: 왼쪽 아래 도우미가 스크롤 중 카드 **왼쪽 아이콘**과 겹쳐 보이는 순간이 있다(`helper_390_mid.png`). 아이콘은 버튼이 아니라 누르는 데 문제는 없음.
- 가계부(133-②):
  - `products.js`·`catalog.json` gagebu `nm` = **`결제문자 가계부`** ✔ · `sub` = **`카드 결제 문자를 붙여넣으면 정리`** ✔ (지시서는 "유지"였지만 실제 값은 예전 영수증 문구 `오늘 산 것 자동 정리 · 더 싼 곳 1초 비교` 였다 → 130번 결제문자 개편과 맞게 지시서 문구로 바꿨다).
  - 쇼룸 카드 실측 텍스트: `결제문자 가계부 / NEW / 카드 결제 문자를 붙여넣으면 정리 / 열기` — 같은 문구 반복 없음.
  - `detail.html?k=gagebu` 제목 "결제문자 가계부 — KTS 원클릭", 옛 이름 0회 ✔ (`detail_gagebu.png`).
  - 중복 문구 원인: **찾음 — 쇼룸 카드가 아니라 가계부 도구 안의 목록 한 줄.** `gagebu/index.html` 318행이 `수량+단위 · 사용처 · 단가라벨 단가` 순서로 그린다 → 1개짜리 결제는 `1개 · 국민카드 · 1개 5,600원` 처럼 "1개"가 두 번 나온다. ① `freeText('gagebu')`='' 정상 ② 박스 strip은 이름만 그림 ③ `render()` 는 `sub` 만 씀 — 셋 다 아님. **제0원칙(도구 로직 불변)에 걸려 고치지 않았다.** 고치려면 다음 회차에 gagebu 318행에서 수량이 1이면 단가 라벨을 빼는 1줄 수정 권장.

## 6. listing 카드
- `status:'soon'` · `link:''` → 쇼룸/대표 3종 모두 `[준비 중]` 비활성, **404 0**. `sitemap.xml` 미등록.
- icon `shots/ic_listing.png` **512×512**(Pillow로 직접 그림 — 딥네이비 바탕 + 오렌지 건물 3동 + 명함). seongsu.png 자르기 안 씀.
- `shot: shots/listing_home.png` 도 없으면 상세 페이지 이미지가 깨져서(첫 검증에서 404 3건 발견) **780×1388 "출시 전 안내 그림"** 을 만들어 넣었다. 그림 안에 "※ 출시 전 안내 그림 · 실제 화면이 아닙니다" 명시. 3순위에서 실제 캡처로 바꾸면 된다.
- catalog `v=20261123a` · `count=28` · `len(products)=28` (`python -c …` 결과 `20261123a 28 28`).
- 3순위에서 live 로 바꿀 자리: `products.js` **1131행**(`"k": "listing"`) 블록의 `status`·`link` · `catalog.json` **1131행** 같은 블록.

## 7. 검증
- scrollWidth **390** · 새 버튼 최소 높이 **44px**(테마·히어로 2·대표 열기·묶음 열기 41개) · 콘솔 에러 **0**(쇼룸·마스터·detail 2종 — 로컬·라이브 둘 다). 검증 중 들어간 `realty/` 도구 페이지에서 404 1건은 원래 있던 것(이번 변경 무관, 미수정).
- 캡처(`output/shared_20261123/`): `first_390.png` · `first_390_light.png` · `full_390_dark.png` · `full_390_light.png` · `helper_390_top/mid/bottom.png` · `master_390.png` · `gate_second_open.png` · `print_a4.png`(+`print_a4.pdf`) · `print_preview_dark/light.png` · `detail_gagebu.png` · `detail_listing.png` · `wide_1280.png` · `live_first_390.png`. 수치 전체 `verify.json`, 스크립트 `src/`.
- 게이트: `kts_gate.py` 가 PC에 없어 137번 회차 PowerShell 이식판(`gate_slope.ps1`)을 복사해 대상 파일 8개로 넓히고 실명(`김태수`) 검사 1줄을 더한 `src/gate_shared.ps1` 로 돌렸다 → **새로 생긴 FAIL 0** (`output/shared_20261123/gate.txt`).
  - index.html `G1-6 FAIL 6 → 6`, helper.js `2 → 2`: 대표 문의번호 010-2002-2899(지시서가 푸터에 넣으라고 한 번호) — 변경 전부터 있던 것이고 늘지 않았다.
  - index.html `G1-2` 전 FAIL은 `git show` 를 PowerShell로 받을 때 생기는 측정 잡음, 후 PASS. G1-4(모달 닫기)·G1-7(원가·내부문구)은 이식판에 없는 항목이라 따로 확인: 새 모달 없음, 새 문구에 원가·내부 메모 없음.

## 8. 라이브 (autooneclick.com, 푸시 후 약 1분)
- `결제문자 가계부`: products.js ✔ · catalog.json ✔ · 라이브 390 화면 카드명 ✔
- `shared/kts-tokens.css` `k-accent` ✔ (kts-ui.css·kts-print.css·kts-ui.js 200)
- catalog `listing` ✔ (`v 20261123a · count 28`) · `ic_listing.png`·`listing_home.png` 200
- 라이브 390 실측: scrollWidth 390 · 다크 시작 · 대표 3종 아래끝 428/533/633 · 묶음 행 35 · 콘솔 0 (`live_first_390.png`, `live.json`)

## 건드리지 않은 것 (확인함)
- 도구 27종의 JS·계산·저장 로직 0건(`slope/ sign/ theform/ contract/ viewer.html realty/ redev/ gagebu/ sale/` 변경 0줄). 바뀐 파일: `shared/*`(새로 만듦) · `index.html` · `helper.js`(위치 CSS + 위치 계산) · `products.js` · `catalog.json` · `shots/` 그림 2장.
- 요금표 신설 0건 · 가격 문구 0건(`[가격 보기]` 없음) · 대외 광고·문자 발송·업로드 0건 · 실명·키·PC 경로 0건.
- 참고: `helper.js` 는 46개 페이지가 같이 쓴다 → 모든 도구에서 도우미가 390 왼쪽 아래로 옮겨 간다(지시서 4-1 의도대로). 바닥 고정 바가 있는 도구는 기존처럼 그 바 위로 뜬다.

## 대표님 확인 필요
1) 첫 화면에서 대표 3종이 크게 보이고 4묶음이 3초 안에 눈에 들어오는지
2) 다크/라이트 토글이 손에 맞는지(기본 다크)
3) 도우미 버튼이 이제 [열기]를 가리지 않는지 — 대신 왼쪽 아이콘 위에 잠깐 겹쳐 보이는 건 괜찮은지
4) 이용약관·개인정보처리방침: 문서가 없어 링크 대신 "준비 중" 문구만 넣음 — 문안을 주시면 페이지로 만들어 연결
5) 가계부 도구 안 `1개 · 국민카드 · 1개 5,600원` 의 "1개" 반복은 도구 로직이라 이번엔 손대지 않음 — 다음 회차에 1줄 수정할지
6) 해주세요 투표 목록에 아직 `결제문자 가계부`(ledger 3표)가 남아 있다 — 이제 실제 도구 이름이 됐으니 투표 목록에서 뺄지

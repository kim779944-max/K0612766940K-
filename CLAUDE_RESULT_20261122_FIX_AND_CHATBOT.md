# 결과 — 2026-11-22 수리 3건 + 전 상품 도우미 (125·126·130·127·129)
시작 HEAD: oneclick `52a722c` / K0612766940K- `efc8a32` (지시서 기준선 `2923722` 뒤에 지시서 정정 커밋 3개가 있었음 — 그 위에서 작업)
끝   HEAD: oneclick `9878404` / K0612766940K- (이 보고서 커밋 — `git log -1` 참조)
커밋(oneclick, 일반 push `52a722c..9878404`, force 없음):
- `bc6b6a1` fix(redev): 모아타운 캐시 수리 · 버튼 분리 · 통합검색 (125번) — `redev/index.html`
- `3ad4d08` fix(sign): 쓰는 순서 재배치 — 만들기→찍기→간인, 요금은 아래로 (126번) — `sign/index.html`
- `25df8d9` fix(gagebu): 결제문자 붙여넣기 중심 · 카톡 표현 제거 (130번) — `gagebu/index.html`, `index.html`
- `9878404` feat(helper): 전 상품 [? 도우미] 사용설명서·챗봇 (127·129번) — `helper.js` 신규 + html 45개 한 줄씩

검증 방법: 로컬 `python -m http.server 8791`(oneclick 폴더) + Playwright(설치된 Chrome headless, 390×844, 모바일·터치 에뮬레이션).
스크립트·원자료: `output/fix_chatbot_20261122/src/v_redev.py · v_sign.py · v_sign_wm.py · v_gagebu.py · v_helper.py`, 도우미 측정 원본 `output/fix_chatbot_20261122/v_helper.json`.

## 1. 125번 재개발
- 캐시: `redev/index.html:277`
  - 전: `fetch('data/redev.json',{cache:'force-cache'}).then(function(r){return r.json();})`
  - 후: `get('data/redev.json?v=20261122a',{cache:'no-cache'})` → 실패 시 `.catch` 에서 `get('data/redev.json?_='+Date.now(),{cache:'no-store'})` 1회 재시도(`get` = fetch + `r.ok` 확인 + json). 재시도도 실패하면 기존 문구 `자료를 열지 못했습니다` 그대로.
  - 실측 요청 URL: `http://127.0.0.1:8791/redev/data/redev.json?v=20261122a` (1건)
  - 통계 4칸: `#stS`=1,198 · `#stG`=533 · `#stN`=1,566 · **`#stM`=64** · `#moaCnt`=64(`rows('moa').length`)
- 통합검색 실측(카운트 줄 `#totline` 그대로):
  - `번동` → `통합 22건 · 서울 18 · 경기 0 · 전국 1 · 모아타운 3`
  - `구기동` → `통합 1건 · 서울 0 · 경기 0 · 전국 0 · 모아타운 1` (배지 `모아타운`)
  - `수유동` → `통합 9건 · 서울 8 · 경기 0 · 전국 0 · 모아타운 1`
  - `개포동 138` → `통합 1건 · 서울 1 · 경기 0 · 전국 0 · 모아타운 0`
  - 지시서 기대값과 4개 모두 **정확히 일치**(±1 차이 없음). 통합 모드에서는 칩 `display:none`, 지역 탭·모아타운 버튼 `.on` 0개.
- 모아타운 버튼: `#tabs` 버튼 3개(seoul·gyeonggi·nation), `data-t="moa"` 는 `#tabs` 안에 없음, `#moaBtn` 은 별도 줄 `#moaRow`. 누르면 `#moaBtn.on` + 지역 탭 `.on` 0개 + `#muNote` 보임. 검색어 `번동` 유지 상태에서 누르면 모아타운만 3건.
- 그 밖의 동작: 지역 탭 직접 클릭 → 그 탭만(`번동` 서울 18건, 검색어 유지, 칩 다시 보임) · `지움` → 마지막 탭 복귀(모아타운 64건 → 서울 탭 클릭 시 1,198) · 0건 → `정비사업·모아타운 어디에도 없습니다` + `지번은 「동 이름 + 번지」…` · `더 보기` 통합 총건수 기준(`동` 검색 시 `더 보기 (40/2,188)`).
- 구조: `load()` 에서 행마다 `r.__tab` 을 심고, 목록·상세·라벨·주소·복사 문구·카드 저장(`itemHTML·stageLabel·datesHTML·addrOf·dealHTML·sheetHTML·shareText·drawCard`)이 전부 `r.__tab` 을 보게 바꿈. 전역 `TAB` 은 화면 상태(`seoul|gyeonggi|nation|moa|all`)만. `openSheet` 는 `[자료 탭, 행 번호]` 로 열림. `data/redev.json` 무변경.
- 통합 모드에서 모아타운 카드 → 상세: **확인** — `구기동` 카드 클릭 시 상단 `모아타운 · 확인 결과` + 모아타운 4단 사다리(`.mlad`). `번동` 서울 카드 → `서울 · 추진위원회승인` + 7단 사다리, 전국 카드 → `전국 · 추진위구성`.
- 390 scrollWidth: 처음 390 · 검색 4건 각각 390 · 마지막 390 (넘침 0) · 콘솔 에러 0건
- 캡처: `_captures/fix_chatbot_20261122/redev_01_init_390.png` · `redev_02_bundong_all_390.png` · `redev_03_gugidong_all_390.png` · `redev_04_gugidong_moa_detail_390.png` · `redev_05_moa_pinned_390.png`
- 캐시 "오염" 재현: headless 새 프로필이라 예전(모아타운 0건) 사본을 심어 재현하지는 못했음. 대신 요청 URL 자체가 `?v=20261122a` 로 바뀐 것을 확인 → 예전 `data/redev.json` 캐시 항목은 다시 쓰이지 않음.

## 2. 126번 더싸인
- 카드 순서(390, 위 → 아래, 문서 y좌표): `1 사인·도장 만들기`(389) → `2 문서에 도장 찍기`(1087) → `3 간인 찍기 · 사이간자 · PRO`(1313) → `이용권 여러 장·간인 쓰기`(1564)
- `[투명 PNG 저장]` = ① 안 · `[날인본 이미지 저장]`·`[PDF 한 권 저장]` = ② 안 (DOM 확인)
- `#ganin` 위치: ③ 카드 안(1개, 중복 0) · 이제 문서를 올리기 전에도 항상 보임
- 무료 상태 클릭 시 토스트: `간인(사이간자)은 월 4,900원 PRO — 아래 [이용권]에서 고르면 미리보기로 써 볼 수 있습니다` · 켜지지 않음(`.on` false)
- 이용권 카드: `data-kts-money="여러 장 · 간인 쓰기"` → ux.js 가 접힘으로 시작(`kux-hid`, display none) 확인. ※ 카드 제목은 보이도록 속성을 **카드 안쪽 감싸개 div** 에 붙였음(카드째 접으면 제목까지 사라져서).
- PRO 선택 후 간인: **확인** — 접힘 펼치기 → PRO → `#planTag`=`PRO 미리보기` → 테스트 문서 2쪽 → `#ganin` 켜짐. 1쪽 결과(`composePage(0)`)에 `KTS 더싸인 미리보기` 워터마크와 오른쪽 아래 간인 반쪽 도장 확인(`sign_05_pro_preview_composed_page1.png`).
- `KTS_UX_CFG` 에 `after:'.ktsRsv'` 한 가지만 추가 → 무료 띠 `.kux-free` 가 사전예약 배너 바로 다음(배너 bottom 113px, 띠 top 122px).
- id·class·data 속성 무변경, 요금 로직(`plan/isPro/unlocked/paintPlan`) 무변경.
- 콘솔 에러 0건(`Cannot read properties` 없음) · 캡처 `sign_01_top_390.png` · `sign_02_mid_390.png` · `sign_03_bot_390.png` · `sign_04_pro_ganin_preview_390.png` · `sign_05_pro_preview_composed_page1.png`

## 3. 130번 가계부
- 입력 UI: `#inBuy` = `TEXTAREA`(rows 5) · `#inMore`(rows 2) · `[📋 붙여넣기]` `[정리하기]` `[추가로 정리]`. 제목 `1 결제 문자·알림 붙여넣기`. 안내 2줄(`카톡·문자 앱 내용을 자동으로 읽어오지 않습니다…` / `잔액·누적·승인번호 줄은 기록하지 않습니다.`).
- `[📋 붙여넣기]`: `navigator.clipboard.readText()` 성공 시 `#inBuy` 에 넣기만 함(자동 정리 안 함). headless 에서는 권한 거부 → 토스트 `길게 눌러 [붙여넣기] 해 주세요 · 붙여넣기가 막힌 브라우저입니다` 확인.
- Enter 는 줄바꿈(기존 Enter→넣기 핸들러 제거). 여러 줄 `paste` 이벤트 처리(기존)는 textarea 에서도 동작 확인(3줄 붙여넣기 → 3품목 · 63,700원).
- 결제문자 3줄 결과(`parsePaySms` → `parse`):

| 입력 | 품목 | 금액 | 산 곳 |
|---|---|---|---|
| `[국민카드] 11/22 14:03 스타벅스 강남 5,600원 일시불` | 스타벅스 강남 | 5,600 | 국민카드 |
| `신한카드 11/22 13:20 GS25 역삼점 12,300원 승인` | GS25 역삼점 | 12,300 | 신한카드 |
| `우리카드 11/22 09:12 이마트 성수점 45,800원 일시불 잔액 320,000원` | 이마트 성수점 | 45,800 | 우리카드 |

  - 화면 요약 줄: **`오늘 3품목 · 63,700원`** (이번 달 줄 `3건 · 63,700원`)
- 잔액·누적 줄 처리: 기록 안 됨(확인) — `localStorage` 안에 `320000` 없음. 잔액·누적만 있는 줄은 통째로 건너뜀.
- 규칙 메모(사실대로): 기존 `parse()` 는 `역삼점·성수점` 의 `점` 을 산 곳으로 잡기 때문에, 결제문자로 판별된 줄은 `parse()` 결과의 품목·산 곳을 `parsePaySms` 가 뽑은 가맹점·카드사로 덮어씀(양은 1개). `parse()` 본문은 무수정. 결제문자 판별 = 카드사 태그(`[..]`/`【..】`) 또는 `○○카드/체크` 또는 날짜+시각. **`취소` 문자는 쓴 돈이 아니므로 기록하지 않도록** 넣었음(지시서는 '취소' 글자 제거만 적었으나, 지우면 취소 건이 지출로 잡혀서). 여러 줄로 쪼개진 실제 은행 문자(가맹점·금액이 다른 줄)는 줄 단위라 맞히지 못할 수 있음 — 폰 확인 필요.
- `#inMore` 에 `양파 1.8kg 3900원 하나로마트` → 양파 · 1.8kg · 3,900 · 하나로마트(기존 규칙 그대로).
- 쇼룸 `index.html:344`
  - 전: `{k:'ledger', nm:'카톡·문자 가계부', sub:'카드·문자 결제를 한 장으로', votes:3}`
  - 후: `{k:'ledger', nm:'결제문자 가계부', sub:'카드 결제 문자를 붙여넣으면 정리', votes:3}`
- '카톡' 글자 수: gagebu **1건**(지시서가 넣으라고 한 안내 문구 `카톡·문자 앱 내용을 자동으로 읽어오지 않습니다` 1곳). 사이트 전체(seo·ops 제외) 20개 파일 61건 — products.js 10 · catalog.json 10 · slots.js 6 · realty 6 · slope 5 · sale 5 · thedetail·redev·navi2·converter·bungee·ad_magnet 각 2 · ux.js·thescan·thescan.html·navi2 데이터 2개·exchange·detail.html 각 1. 전부 '카톡으로 공유/붙여넣기' 같은 다른 도구 문맥이고, **가계부를 카톡 연동으로 설명하는 곳은 0건**.
- 390 가로 넘침 0(scrollWidth 390) · 콘솔 에러 0건 · 캡처 `gagebu_01_before_390.png` · `gagebu_02_after_390.png`

## 4. 127·129 도우미
- `helper.js` 31,343 B(`window.KTS_HELPER`, v20261122a). script 추가 페이지 **45개** — 지시서 검산 명령(PowerShell `Select-String`) 결과 `45`.
  - 루트 13: index · detail · converter · contract · loan · longtail · sign · tax · thedetail · theeraser · theform · thescan · viewer
  - 폴더 32: ad_magnet · bungee · contract · ecommerce 8개(blog·coupang·detail100·global·index·insta·naver·열매핑) · exchange · gagebu · golf · hogang · navi2 · organizer · petmind · realty · redev · sale · saycap · seller · sign · slope · thedetail · theeraser · theform · thescan · thescan/theeraser.html · thetongyeok · ytsummary
  - 제외: ops/ · seo/ · naver080f… · saycap/test.html · */img/CREDITS.html 4개. `interior/` 는 아직 저장소에 없어서 46개가 아니라 45개.
  - `</body>` 가 두 번 나오는 4개(bungee·viewer·ecommerce/coupang·naver — 앞의 것은 JS 문자열 안)는 **마지막** `</body>` 앞에 넣음. 45개 모두 로드 시 `KTS_HELPER` + 버튼 생성, pageerror 0건.
- 사전 적용 도구 **11개**: index(쇼룸) · redev · sign · gagebu · slope · hogang · thescan · thedetail(더상세, `theview` 폴더는 없음) · theform · contract · sale. interior 는 없어 미적용. 나머지 페이지는 `main h2 / .card h2` 앞 3개 자동(예: 문서변환기 → `표 사진 넣기`·`무엇이 나오나요` 2단계).
- 단계 대상(여기로) 확인: 9개 도구는 3단계 대상이 모두 보이고 화면 위→아래 순서. 예외 2가지는 사실대로:
  - theform·contract 는 단계 화면(마법사)이라 ②③(`#s2·#s3` / `#s1·#s4`)이 처음엔 숨겨져 있음 → [여기로]를 누르면 `그 단계는 앞 단계를 마치면 나타납니다` 토스트.
  - 쇼룸은 ①`01~09 쓰는 순서`(y 398)가 ②`내 박스`(y 261)보다 아래에 있음 — 고른 뒤 담는 순서라서 순서를 그대로 둠.
- 390 실측(버튼 52×52, z 240 / 시트 폭 390, max-height 88vh, z 250):

| 화면 | 하단 바 | 바 높이 | 버튼 bottom | 바와 겹침 | .totop 과 겹침 |
|---|---|---|---|---|---|
| 쇼룸 | 없음 | — | 62px(.totop 18+34+10) | 0 | 0 (.totop 311,804–376,838 / 버튼 326,730–378,782) |
| 재개발·더싸인·토지(slope)·더스캔 | 없음 | — | 14px | 0 | — |
| 가계부·호갱 | .sitebar | 47 | 57px | 0 | — |
| 더상세 | .bar | 107 | 117px | 0 | — |
| 더양식 | .bar | 72 | 82px | 0 | — |
| 더계약서 | .bar | 72 | 82~84px | 0 | — |
| 오늘의 특가 | .bar | 62 | 72px | 0 | — |
| 문서변환기 | #dockHome | 88 | 98px | 0 | — |

  끝까지 스크롤한 뒤에도 같은 값(버튼 바닥 고정), 다른 fixed 요소와 겹침 0. 하단 바는 2초마다·스크롤·리사이즈 때 다시 계산(늦게 붙는 바 대응, 계산만 함).
- 네트워크 요청 0건: 12개 화면에서 패널 열기→FAQ→묻기 2회→신고→문의→여기로→닫기 동안 새 요청 0건. `helper.js` 안에 `fetch/XMLHttpRequest/sendBeacon/EventSource/import(` 0건(grep).
- 인쇄 미노출: `print` 미디어에서 버튼 `display:none` (12개 화면 모두).
- 신고 localStorage: 화면마다 1건씩 쌓여 12건(`{at,path,tool,text}`), `[문자로 보내기]` href = `sms:01020022899?body=%5BKTS%20%EB%8F%84%EC%9A%B0%EB%AF%B8%5D%20%ED%99%94%EB%A9%B4…`(`[KTS 도우미] 화면:{path} / {내용}`). **실제로 문자앱이 열리는지는 폰 확인 필요**(PC headless 라 링크값만 확인).
- 1:1 문의: `tel:01020022899` · `sms:01020022899?body=[KTS] {도구명} 문의`.
- FAQ 무료 답(기기 안): 더싸인 `한 장 무료입니다.` · 더양식 `기본 양식 5종 무료입니다.` · 더계약서 `서식 3종 무료입니다.` · 문서변환기 `하루 3장 무료입니다.`(KTS_KEYS.freeText) · 토지 `하루 3건 무료입니다.`(화면 h2 문구를 사전에 넣음) · 쇼룸은 이용권 안내가 있어 `이 화면은 무료로 열어 쓸 수 있습니다. 더 쓸 때의 안내는…` · 나머지 `이 도구는 무료입니다.`
  - 직접 묻기: `주차장 몇 대 있어요?` → `정확히 확인하지 못했습니다. ④ 1:1 문의로 문자 주시면 바로 답해 드립니다.` / `저장이 안 돼요` → 저장 FAQ 답. (키워드 규칙 매칭, 지어내지 않음)
- 콘솔 에러: 더스캔에서 1건(`/favicon.ico` 404 — 페이지 자체에 아이콘 링크가 없어 생기는 것, 도우미와 무관). 나머지 0건.
- 캡처: `helper_<도구>_390.png`(패널) + `helper_<도구>_btn_390.png`(바닥까지 스크롤한 버튼 위치) — index·redev·sign·gagebu·slope·hogang·thescan·thedetail·theform·contract·sale·converter_auto, 그 외 `helper_redev_faq_390.png` · `helper_index_report_390.png`

## 5. 라이브 (푸시 약 2분 뒤, `?t=` 캐시 우회 curl)
- `redev/` `moaBtn` — **확인**(3줄 잡힘)
- `sign/` `간인 찍기` — **확인**(2줄)
- `gagebu/` `붙여넣기` — **확인**(3줄)
- `helper.js` `KTS_HELPER` — **확인**(3줄)

## 건드리지 않은 것 (확인함)
- sale/ · bungee/#interior · ops/ · seo/ · slots.js·ux.js 본문 · redev/data/redev.json — 내용 수정 0. 단 지시서 4-7 표대로 `sale/index.html`·`bungee/index.html` 에는 `</body>` 앞 helper.js **한 줄만** 추가함.
- 결제·외부 API·문자 발송 0건

## 대표님 확인 필요 (폰에서)
1) 재개발에서 '번동' 넣었을 때 모아타운 3곳이 같이 보이는지
2) 더싸인 위에서부터 ①→②→③ 순서로 읽히는지
3) 가계부에 결제 문자를 붙여넣었을 때 이름·금액이 맞는지 (특히 실제 카드사 문자가 여러 줄로 나뉘어 오는 경우)
4) 아무 도구나 열어 우측 하단 [? 도우미] 를 눌렀을 때 하단 바를 가리지 않는지 · [문자로 보내기]가 문자앱으로 열리는지

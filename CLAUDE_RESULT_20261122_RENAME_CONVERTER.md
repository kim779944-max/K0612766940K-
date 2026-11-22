# 결과 — 2026-11-22 명칭 변경: 원클릭 변환기 → 문서변환기
시작 HEAD: oneclick af9b6aa / K0612766940K- 63a6a43
끝   HEAD: oneclick 52a722c / K0612766940K- (이 보고서 커밋)

> 기준선 차이: 지시서 기준선은 `53ff0c3`/`d5bed67`인데, `git pull --rebase` 후 실제 HEAD는 그보다 최신인 `af9b6aa`/`63a6a43`이었습니다(특가·폰정리 트랙 커밋이 그 뒤에 쌓임). 이 때문에 index.html의 대상 줄은 237이 아니라 **238**이었고, 문자열로 찾아서 고쳤습니다.

## 바꾼 곳 (파일:줄 — 전 → 후)
1) products.js:51 — `"nm": "원클릭 변환기",` → `"nm": "문서변환기",`
2) catalog.json:51 — `"nm": "원클릭 변환기",` → `"nm": "문서변환기",`
3) converter.html:4 — `<title>KTS 원클릭 변환기 — 사진 한 장이…</title>` → `<title>KTS 문서변환기 — 사진 한 장이…</title>`
4) converter.html:216 — `KTS <small>원클릭 변환기</small>` → `KTS <small>문서변환기</small>`
5) index.html:238 — `products.js?v=20261121u` → `products.js?v=20261122a`
6) detail.html:135 — `products.js?v=20261121u` → `products.js?v=20261122a`

oneclick 커밋: `52a722c rename: 원클릭 변환기 -> 문서변환기 (표시 명칭만, photo2doc 키·파일명 무변경)` — `af9b6aa..52a722c main -> main` 푸시 완료(일반 push, force 아님).

## 실측 숫자
- 수정 전 `원클릭 변환기` 매치: 4 (products.js 1 · catalog.json 1 · converter.html 2) / 수정 후: 0
- 수정 후 `문서변환기` 매치: 4 (1 · 1 · 2)
- `products.js?v=20261122a` 매치: 2 (index.html 1 · detail.html 1)
- `git diff --stat`: 파일 5 · +6 −6 (`git diff --unified=0`에서 바뀐 줄은 위 6줄뿐임을 눈으로 확인)
- JSON 검사: `python json.load(catalog.json)` → `catalog ok`
- 파일 길이(커밋된 내용 바이트, `git cat-file -s` af9b6aa → 52a722c):
  - products.js 38217 → 38213 (−4) · catalog.json 37007 → 37003 (−4) · converter.html 133160 → 133152 (−8) · index.html 30741 그대로 · detail.html 19959 그대로
  - 지시서의 기대 숫자(23654→23652 등)는 `53ff0c3` 시점·글자 수 기준이라 그대로 비교할 수는 없습니다. 바이트 차이는 UTF-8 기준 `원클릭 변환기`(19바이트) → `문서변환기`(15바이트)라서 한 곳당 −4가 맞고, `?v=` 값은 길이가 같아 0입니다.
  - 참고: 작업 PC의 작업 폴더 사본은 CRLF였는데 `sed -i`로 고치면서 LF가 됐습니다. 저장소 쪽(index)은 원래 LF라서 커밋 내용에는 영향이 없습니다(`git ls-files --eol` → `i/lf`, diff는 6줄뿐).

## 화면 (390×844 · PC 크롬 헤드리스, scale 2)
- 캡처 폴더: `_captures/rename_20261122/` (이 저장소)
- 쇼룸 카드 이름: `_captures/rename_20261122/index.png` — 「02 문서로 만든다」 칸의 카드 이름이 **문서변환기**, 부제 `표 사진 → 한글(.hwpx)·엑셀(.xlsx)`는 그대로
- converter.html 탭 제목·헤더 브랜드: `_captures/rename_20261122/converter.png` — DOM `<title>KTS 문서변환기 — 사진 한 장이 원본 그대로 한글·엑셀이 됩니다</title>`, 헤더가 `KTS 문서변환기` 한 줄로 보임(줄바꿈 없음)
- detail.html?k=photo2doc 탭 제목: `_captures/rename_20261122/detail.png` — 스크립트 실행 뒤 DOM `<title>문서변환기 — KTS 원클릭</title>`, 상세 화면 큰 제목도 문서변환기
- 콘솔 에러: 0건(Chrome `--enable-logging` 출력 기준). 그 밖에 index.html에서 INFO 1건(`[DOM] Password field is not contained in a form`)이 찍혔는데, 이번 작업과 무관한 기존 메시지입니다. 경고(warning)는 0건.
- 캡처 한계: 헤드리스 크롬 캡처는 오른쪽 끝이 일부 잘려서 보입니다(창 크기 처리 방식 때문에 생기는 현상으로, 이번 변경 전부터 그랬음). 390px에서 정말 넘치지 않는지는 실기기 확인으로 넘깁니다.

## 라이브 (푸시 직후 12:33 KST, 캐시 우회 `?t=`)
- https://autooneclick.com/products.js → 문서변환기 **확인** (1건)
- https://autooneclick.com/converter.html → 문서변환기 **확인** (2건)
- 추가 확인: catalog.json 문서변환기 1건 · index.html·detail.html의 `products.js?v=20261122a` 각 1건

## 건드리지 않은 것 (확인함)
- 파일명 converter.html·URL·photo2doc 키(`k`)·`link: converter.html`·아이콘 `shots/ic_photo2doc.png`·스크린샷 `shots/photo2doc_home.png`·slots.js·localStorage 키: 무변경(이번 diff에 없음)
- converter.html 모드 토글 `변환기`/`더뷰`(318·383줄), viewer.html 토글, ops/status.json, status.js, slots.js 주석, ad_magnet cta: 무변경
- converter.html:1765 문자 의뢰 문구 `[원클릭] 변환기 커스텀 의뢰`: `원클릭 변환기` 7글자 패턴이 아니라서 바꾸지 않음(무변경)
- 다른 도구 이름·기능·요금·레이아웃·색: 무변경

## 남은 것 (범위 밖이라 손대지 않음)
- **상세 화면의 시연 영상 `v/photo2doc.mp4`(포스터 `v/photo2doc.jpg`)** 화면 안에 예전 이름 `KTS 원클릭 변환기`가 그대로 찍혀 있습니다(detail.png 상단 영상 프레임). 영상을 다시 녹화하거나 포스터를 교체해야 하는데, 이번 지시 범위(6곳)를 벗어나서 손대지 않았습니다. 바꿀지는 대표님·지니가 정해 주세요.

## 대표님 확인 필요 (1줄)
- 폰에서 새로고침(캐시 비우기) 후 쇼룸 카드와 변환기 화면 상단에 '문서변환기'가 보이는지

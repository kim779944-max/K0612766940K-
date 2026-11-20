# PC 클로드 코드 결과 보고 — 2026-11-20 WATCHFIX (감시기 한도 재시도 보강 + 핵심 10종 이관 패키지)

> 실행: 2026-11-20 12:20 ~ 12:55 · 자동감시기 12:20 회차가 이 지시서를 물어 실행(시도 1/3) · 지시서: `CLAUDE_TASK_20261120_WATCHFIX.md`

## 1. 한 줄 요약

| 과업 | 판정 | 요약 |
|---|---|---|
| 과업 1 — `auto_watch.ps1` 한도 안전장치 | **완료** | S1~S5 구현 · 가짜 claude 시험 T1~T8 **52/52 PASS**(회귀 R1~R8 포함) · 시험 통과 후 실 저장소 `auto_watch.ps1` 교체 · 실환경 1회 실행 확인 |
| 과업 2 — 핵심 10종 이관 패키지 | **완료** | `output/핵심이관_패키지_20261120/` · manifest 30/30 · 390px 10종 FAIL 0 · `%TEMP%` 사본 적용(복사 30·count 29·타일 10·깨진 그림 0·2회차 0건) · 실서비스 `oneclick` 변경 0 · 라이브 10종 404 |

## 2. 과업 1 — `auto_watch.ps1` 보강

- 교체 전: `output/watchfix_20261120/before_auto_watch.ps1` (192줄) → 교체 후: `auto_watch.ps1` (354줄, `+175 / −13`). 같은 내용 사본 `output/watchfix_20261120/after_auto_watch.ps1`(시험 대상). 맨 위 주석에 S1~S5 요약 5줄. **BOM 포함 UTF-8**로 저장, `powershell -NoProfile -File`·`[scriptblock]::Create` 둘 다 오류 0.
- 새 함수 4개: `Test-RateLimit`(43행) · `Get-ResetHint`(50행) · `ConvertTo-ArgString`(77행) · `Invoke-Claude`(88행). 기존 블록(보관 커밋·fetch·reset/rebase·지시서 선택·큐·커밋·푸시)은 글자 그대로.

| # | 구현 위치 | 내용 |
|---|---|---|
| S1 | `Test-RateLimit` + 301행~ | 결과 파일 없음 + 한도 신호 + (종료코드≠0 또는 출력 400자 미만) → `{task}.try`를 직전 값으로(0이었으면 파일 삭제) · BLOCKED 안 만듦 · `RATE_HIT.log` 1줄 · 리셋 시각을 읽으면 `RATE_HIT.txt` · 커밋·푸시는 그대로 |
| S2 | 121행~ (뮤텍스 뒤·git 전) | `resetAt` 전이면 `한도 대기 중 → … 건너뜀` 후 종료 · 지났으면 `한도 리셋 시각 지남 → 이어서 재시도` · 판독 실패면 파일 지우고 진행 · 한도가 아닌 결과가 나오면 `RATE_HIT.txt` 삭제 |
| S3 | `Get-ResetHint` | 지시서 정규식 + `limit reached\|<유닉스초>` 추가. **규칙: 오늘 그 시각이 지났으면 내일로, 7시간 넘게 뒤면 오독으로 보고 `$null` → 10분 재시도**(AddMinutes(-2) 방식은 쓰지 않음) |
| S4 | 249행~ · 288행~ | `claude --help`에서 `--session-id`/`--resume`/`--continue` 지원 확인(이 PC의 claude 2.x는 셋 다 지원). 첫 시도 `--session-id <GUID>` → `{task}.session`. 다음 시도 `--resume <GUID>` → `--continue` → 문구만. '이어서' 문구를 프롬프트 맨 앞에. 재개가 바로 실패하면 같은 회차 `-p` 단독 1회만 |
| S5 | `Invoke-Claude` | `Start-Process -PassThru` + `WaitForExit` · `$MaxRunMinutes = 90` 초과 시 `taskkill /T /F` · 로그 `실행 상한 초과로 종료(90 분)` · 시도 안 셈 · stdout/stderr → `{task}.out.txt`/`{task}.err.txt`, 누적 `{task}.history.txt` · stdin은 빈 파일 |

### 시험 T1~T8 (`%TEMP%\aw_test` · 가짜 claude.exe · 실제 claude 호출 0)

| # | 결과 | 로그 |
|---|---|---|
| T1 | try 1→1 · RATE_HIT.log 1줄(`… usage limit reached. Your limit will reset at 3:00 PM · 2026-11-20 15:00`) · RATE_HIT.txt `resetAt 2026-11-20T15:00:00` · BLOCKED 0 · 결과 없음 — 6/6 | `output/watchfix_20261120/test/logs/T1.txt` |
| T2 | `한도 대기 중 → 리셋 예상 11-20 15:00 까지 건너뜀` · claude 호출 1→1(0회) — 3/3 | `T2.txt` |
| T3 | `한도 리셋 시각 지남 → 이어서 재시도` · argv `--resume <GUID>` + 이어서 문구 — 4/4 | `T3.txt` |
| T4 | 429 → RATE_HIT.txt 미생성 · try 변화 0 · 다음 회차 바로 호출 — 4/4 | `T4.txt` |
| T5 | try 삭제 · RATE_HIT.txt 삭제 · `git push 완료` · 원격 커밋 — 5/5 | `T5.txt` |
| T6 | 상한 1분 → 61초 종료 · 로그 1줄 · 남은 프로세스 0 · try 안 셈 · 다음 회차 정상 — 5/5 | `T6.txt` |
| T7 | 문법 오류 0 · BOM — 3/3 | `T7.txt` |
| T8 | R1~R8 + S4-4 — 22/22 | `T8.txt` |

### 회귀 R1~R8

R1 뮤텍스 PASS · R2 보관 커밋 PASS · R3 원격 맞추기 3가지(원격만/둘 다/로컬만) PASS · R4 큐 순서 1개씩 PASS · R5 `unknown option` → `--permission-mode bypassPermissions` PASS · R6 try 삭제 PASS · R7 5MB 접기·LAST_RUN PASS · R8 푸시 실패 → rebase → 재푸시 PASS. 상세는 `output/watchfix_20261120/README.md`.

### 교체 직후 실제 1회 실행

- `setup_autowatch.bat run` → `INFO: scheduled task "KTS_AutoWatch" is currently running.` — 작업 스케줄러가 **지금 이 회차(12:20 시작)**가 돌고 있어 새 인스턴스를 띄우지 않았습니다(작업 설정 '새 인스턴스 시작 안 함').
- 그래서 실 저장소의 새 `auto_watch.ps1`을 실제 상태 폴더로 직접 1회 실행했습니다(먼저 `KTS_AutoWatch` 뮤텍스가 잡혀 있는지 확인 — 안 잡혀 있으면 이 지시서를 중복 실행할 위험이 있어서). 결과: 종료코드 0, `%LOCALAPPDATA%\KTS_autowatch\autowatch.log`에 `2026-11-20 12:33:35  이전 실행이 아직 진행 중 → 건너뜀` 1줄 — 실환경 파싱·뮤텍스 정상.
- 새 판으로 첫 실제 회차는 이 회차가 끝난 뒤 다음 10분 정각(작업 스케줄러)입니다. 지금 도는 12:20 회차는 메모리에 읽어 둔 **옛 판**으로 끝까지 돕니다(종료 후 결과 파일이 있으므로 `.try` 삭제).

## 3. 과업 2 — 핵심 10종 이관 패키지 (`output/핵심이관_패키지_20261120/`)

0단계 확인: `oneclick\swapcheck.html`·`rights1p.html`·`balju.html`·`ledger.html`·`tagmaker.html` 모두 있음 → 과업 2 진행. 기존 5종 패키지 폴더(`output/100선_이관_20261120/`)는 손대지 않았습니다.

### 선정 10종 (지시서 표 그대로)

| 순 | # | slug | 이름 | 고객 | 한 줄 가치 | 패키지 |
|---|---|---|---|---|---|---|
| 1 | #71 | `swapcheck` | 더교환판정 | 교환 중개·상대 양쪽 | 교환 성사 가능성 6축 점수 · A~D 등급 · 해소 문장 | 기존 5종 |
| 2 | #65 | `rights1p` | 더권리 | 중개사·매수 검토자 | 등기부등본 글자 → 위험 신호 A4 1장 | 기존 5종 |
| 3 | #69 | `yieldcalc` | 더수익 | 상가·수익형 매물주 | 총/순 수익률·자기자본 수익률·손익분기 공실률·상환 3방식 | 추가 5종 |
| 4 | #67 | `pricegap` | 더시세 | 급매 판단하는 중개사·매수자 | 실거래 표본에서 이상치를 빼고 평당가·괴리율·공시지가 배율 | 추가 5종 |
| 5 | #74 | `notice` | 더통지 | 임대인·중개사 | 해지·연체 독촉·갱신 거절 통지문 3종 × 3단 톤 · 필수항목 점검 | 추가 5종 |
| 6 | #70 | `bidcompare` | 더견적비교 | 인테리어·공사 발주자 | 3곳 견적 항목 대조 · 과다(×배) 신호 · 누락 항목 질문 | 추가 5종 |
| 7 | #57 | `balju` | 더발주 | 식자재 쓰는 식당·카페 | 거래명세서 → 재고 → 부족분만 거래처별 발주서 | 기존 5종 |
| 8 | #76 | `ledger` | 더장부 | 개인사업자 | 카드·은행 내역 → 매입매출 장부 + 부가세 요약 | 기존 5종 |
| 9 | #88 | `tagmaker` | 더태그 | 위탁판매 셀러 | 상품 1건 → 마켓 4곳 제목 + 검색어 30개(과장·상표 제거) | 기존 5종 |
| 10 | #61 | `themenu` | 더메뉴 | 음식점·카페 사장님 | 메뉴 12개 → 한·영 QR 메뉴판(A4 인쇄 + QR) | 추가 5종 |

**추가 5종을 넣은 이유(지시서 원문)**: 기존 5종은 '한 파일로 바로 파는 도구' 기준을 통과한 5개였습니다. 이번에 10종으로 넓히면 ① 부동산 상담 흐름이 `시세(pricegap) → 권리(rights1p) → 수익(yieldcalc) → 교환판정(swapcheck) → 통지(notice)`로 한 줄로 완결되어, 한 상담에서 도구를 3~5개 쓰게 되고 재방문이 생깁니다. ② `bidcompare`는 대표님 본인 신하리 공사비(1.1억) 검증에 바로 쓰는 도구로, 60만~100만 원대 과다 항목을 잡아내면 그 자체가 즉시 현금 절감입니다. ③ `themenu`는 판매가 아니라 **번개알바 업소 DB에 붙는 유입 상품**입니다(사장님이 QR을 찍어 보는 순간 설득이 끝남). 셋 중 하나라도 대표님이 빼라고 하시면 나머지로 9종·8종 패키지를 그대로 만들 수 있게 `copy_manifest.json`·`products_추가분.js`를 **slug 단위로 잘라 쓸 수 있게** 작성했습니다(`apply.ps1 -Exclude themenu` → 9종 시험 완료).

중복 확인·근거 파일 경로: `output/핵심이관_패키지_20261120/선정_10종.md` (라이브 19종 대비 키 중복 0 · 링크 중복 0).

### 390px 실측 (이번 회차 · `390px_검수표.md`, 원문 `390/measure_log.jsonl`)

| slug | 가로 넘침 | 겹침 | 잘린 글자 | JS 오류 | 예시→결과 | 복사 | 인쇄 | 외부 참조 | 판정 |
|---|---|---|---|---|---|---|---|---|---|
| swapcheck | 0 (390) | 0 | 0 | 0 | 2탭 · 684자 | 310자 | 1회 | 0 | PASS |
| rights1p | 0 (390) | 0 | 0 | 0 | 2탭 · 1,406자 | 403자 | 1회 | 0 | PASS |
| yieldcalc | 0 (390) | 0 | 0 | 0 | 2탭 · 1,185자 | 179자 | 1회 | 0 | PASS |
| pricegap | 0 (390) | 0 | 0 | 0 | 2탭 · 1,860자 | 140자 | 1회 | 0 | PASS |
| notice | 0 (390) | 0 | 0 | 0 | 2탭 · 874자 | 465자 | 1회 | 0 | PASS |
| bidcompare | 0 (390) | 0 | 0 | 0 | 2탭 · 1,202자 | 257자 | 1회 | 0 | PASS |
| balju | 0 (390) | 0 | 0 | 0 | 2탭 · 1,184자 | 83자 | 1회 | 0 | PASS |
| ledger | 0 (390) | 0 | 0 | 0 | 2탭 · 6,680자 | 337자 | 1회 | 0 | PASS |
| tagmaker | 0 (390) | 0 | 0 | 0 | 2탭 · 831자 | 311자 | (버튼 없음) | 0 | PASS |
| themenu | 0 (390) | 0 | 0 | 0 | 2탭 · 528자 | 368자 | 1회 | 0 | PASS |

- `themenu`: QR v33 L 1974B **디코드 문자열 == 링크(true)** · A4 PDF **1쪽**(594.96×841.92pt) · 한(`김치찌개`)·영(`Kimchi Stew`) 둘 다 true
- `notice`: `sms:` 0 · `mailto:` 0 · `fetch(` 0 · `XMLHttpRequest` 0 · `sendBeacon` 0
- `bidcompare`: 단가 빈칸 → `unit=NaN`·`amt=NaN` 유지 · 확인 필요 2쌍(`조명 교체↔LED 조명`, `폐기물 처리↔폐기물`) 따로 남음(14행)
- `yieldcalc` 검산: 380×12 ÷ 95,000 = 4.80%(화면 4.80%) · NOI 380×12×0.95 − 30×12 − 220 = 3,752(앱 3,752.0) · 3,752 ÷ 99,900 = 3.76%(화면 3.76%)
- `pricegap` 검산: 92,000 ÷ (84.9 ÷ 3.3058) = 3,582.3(앱 3,582.3) · ±40% 뺀 22/24건 중앙값 3,565.1(화면 3,565) · 괴리율 +11.4%(화면 +11.4%)

### 패키지 검사 (`src/check_add_log.txt`)

`products_추가분.js` 크롬 `<script src>` 읽기 `syntax errors: []` · 10개 · 기존 `k` 중복 `[]`(products.js·catalog.json 둘 다) · 키 구성 기존 항목과 **10/10 동일** · price: themenu `무료`, 나머지 `무료 체험` · `catalog_추가분.json` 항목 키 = 라이브 catalog.json 항목 키, 차이 0 · 기존 5종 객체는 `output/100선_이관_20261120/products_추가분.js`와 글자 단위 동일.

### dry-run (`src/dryrun_apply.ps1` → `src/dryrun_log.txt`, 라이브 HEAD `b664d30`을 `%TEMP%\mig10_dry`에 clone)

| 항목 | 결과 |
|---|---|
| `-WhatIf` | 바뀔 것 30개·+10·count 19→29 출력, 사본 `status --short` 0줄 |
| 복사 | **30개** · `copy_manifest.json` Test-Path **30/30** · 문의 링크 새 주소 10곳 · 옛 주소 0곳 |
| diff | `products.js` **+101 / −1**(지운 줄 = 마지막 객체 끝 `notes:[…]}` → 쉼표 추가) · `catalog.json` +413 / −1(`count` 줄) |
| count | `catalog.json` count **29 == products 29** |
| 쇼룸 | 로컬 http(`src/serve.ps1`)로 `index.html` → catalog.json 반영 · 타일 전체 29 · **새 타일 10** · 그림 59개 중 **깨진 그림 0** · JS 오류 0 |
| 상세 | `detail.html?k=…` 10/10 제목 정상 · 상세 캡처 780×1688 로드 · 깨진 그림 0 · 오류 0 |
| 미커밋 재실행 | 멈춤(종료코드 2) + 변경 목록 안내 |
| **2회차(커밋 후)** | **추가 0건** · 복사 0(같은 파일 30) · count 29→29 · status 0줄 |
| 기존 5종 먼저 적용된 저장소 | 나머지 5종만: 복사 15 · +5 · count 24 → 29 · k 중복 0 |
| `-Exclude themenu` | 9종 · count 19 → 28 · themenu.html 안 들어감 |
| 실서비스 저장소 | `git -C oneclick status --short` **빈 출력** · HEAD `b664d30` 그대로 |

### 완료 판정 (지시서 2-4)

- [x] 10종 html·아이콘·상세 캡처 저장소에 있음 · `copy_manifest.json` 30줄 Test-Path **30/30**
- [x] `products_추가분.js` 구문 오류 0 · 10개 · 기존 `k` 중복 `[]` · 키 구성 **10/10 동일**
- [x] `catalog_추가분.json` 형식 = 라이브 `catalog.json` 항목(키 누락 0)
- [x] 390px 10종 **FAIL 0**(넘침·겹침·잘림·JS 오류 0 · 2탭 · 복사 · 외부 참조 0)
- [x] `themenu` QR 디코드 일치 · A4 1쪽 · 한·영
- [x] `notice` 자동 발송 코드 0
- [x] `bidcompare` 빈칸 추정 안 함 · 확인 필요 쌍 미병합
- [x] `yieldcalc`·`pricegap` 화면 값 = 손 검산
- [x] `apply.ps1` `%TEMP%` 사본: 복사 30 · products.js +101/−1 · count == products · 타일 10 · 깨진 그림 0 · 상세 정상 · **2회차 0건**
- [x] `oneclick` 실제 변경 **0**
- [x] 라이브 10종 **404**(12:46:17 확인, 대조군 `tax.html` 200) — `src/live404_log.txt`

## 4. 막힌 것 · 지시서와 다르게 한 것

1. **`setup_autowatch.bat run` 실행 불가(정상 동작)** — 원문: `INFO: scheduled task "KTS_AutoWatch" is currently running.` 이 회차 자체가 그 작업이라 스케줄러가 새 인스턴스를 띄우지 않음. 대신 새 스크립트를 실 상태 폴더로 직접 1회 실행(위 2장).
2. **시험용 환경변수 3개 추가** — 지금 이 회차가 실제 뮤텍스 `KTS_AutoWatch`를 쥐고 있어 사본 시험이 전부 '진행 중 → 건너뜀'이 되므로, `KTS_AW_STATEDIR`·`KTS_AW_MUTEX`·`KTS_AW_MAXRUNMIN`으로 상태 폴더·뮤텍스·상한만 바꿀 수 있게 함. 평소엔 비어 있어 동작 그대로.
3. **T6 대기 시간** — 지시서 '30초 대기'는 상한 1분보다 짧아 워치독이 발동하지 않으므로 120초 대기로 시험.
4. **가짜 claude를 .cmd 대신 exe** — 실제 `claude.exe`처럼 인자를 받게 하려고 C# 소스(`test/shim/claude_shim.cs`)를 `Add-Type`로 `%TEMP%`에 빌드. 저장소에는 소스(.cs)만.
5. **`{task}.out.txt`의 의미** — 예전엔 회차마다 덧붙이던 파일, 지금은 회차마다 새로 쓰는 stdout(지시서 S5) · 누적은 `{task}.history.txt`.
6. **시험 중 고친 것(원문 오류)**
   - 과업 1 T3·T4 첫 실행 FAIL: 이어서 프롬프트에 줄바꿈이 있어 가짜 claude의 argv 기록이 두 줄로 쪼개짐 → 프롬프트 줄바꿈을 공백으로 바꿈(명령줄 인자로도 안전). 이후 PASS.
   - 과업 2 `check_add.ps1` 첫 실행: `syntax errors: ["Uncaught SyntaxError: Unexpected identifier '객체'"]` — 내가 쓴 머리 주석 안의 `*/` 문자열이 주석을 일찍 닫음 → 주석 문구 수정 후 `[]`.
   - `cap390.ps1` 첫 실행: `notice` 단계 `JS exception … SyntaxError: Unexpected token '}'` — PowerShell 변수 `$k`가 저장소 경로 `$K`를 덮어씀(대소문자 구분 없음) → 이름 변경. 같은 원인으로 `apply.ps1` 첫 시험에서 `원본 없음: themenu\oneclick\swapcheck.html` → `$SrcRoot`로 변경.
   - `apply.ps1` 첫 시험 `복사 0개`: PS 5.1 `ConvertFrom-Json`이 JSON 배열을 한 덩어리로 내보냄 → 풀어서 처리.
   - A4 판정식이 594.96×841.92를 FAIL로 봄 → ±2pt 허용 후 10종 전부 재측정.
7. QR 디코더 jsQR은 지난 회차가 받아 둔 `%LOCALAPPDATA%\Temp\jsqr\jsQR.js`(시험 전용)를 그대로 썼고, 이번 회차 외부 요청은 라이브 404 확인용 `autooneclick.com` HEAD 11건(10종 + 대조군 1)뿐입니다.
8. 참고: 라이브 `products.js`는 18개, `catalog.json`은 19개(`thedetail`은 catalog에만 있음). 그래서 `count`는 catalog의 products 길이로 계산합니다.

## 5. 커밋

| 항목 | 값 |
|---|---|
| 손대기 전 HEAD (과업 1 · 과업 2 공통, 0단계 `git rev-parse HEAD`) | `e20e2e299d92ded1b23e4f28bc5641ac11a4f8c2` |
| 작업 중 `auto_watch.ps1`의 커밋 흔적 | 없음(작업 동안 `git log`·`origin/main` 새 커밋 0) |
| 이번 커밋 | `da20bf95a5c83f63241e9151599397daace987b6` — `feat(WATCHFIX): auto_watch 한도 안전장치(S1~S5) + 핵심 10종 이관 패키지` (51개 파일) · 이 표의 해시·푸시 결과는 다음 커밋 `docs(WATCHFIX): 결과 보고서 커밋 해시 기입`으로 덧붙임 |
| 푸시 결과 | `git pull --rebase origin main` → `Current branch main is up to date.` · `git push origin main` → `e20e2e2..da20bf9  main -> main` 성공 |
| 실서비스 `oneclick` | 변경 0 · HEAD `b664d30` |

## 6. 다음 회차 인수인계

1. 새 `auto_watch.ps1`의 첫 실제 회차는 이 회차가 끝난 뒤입니다. 다음에 한도에 걸리면 `%LOCALAPPDATA%\KTS_autowatch\RATE_HIT.log`·`RATE_HIT.txt`·`{task}.history.txt`를 보면 됩니다. 되돌리기: `Copy-Item output\watchfix_20261120\before_auto_watch.ps1 auto_watch.ps1 -Force` → 커밋.
2. 대표님 승인(관문 6) 후 `output\핵심이관_패키지_20261120\apply.ps1 -WhatIf` → `apply.ps1` → `git -C oneclick status --short`(M 2 · ?? 30) → oneclick 커밋·푸시 → `src/live404.ps1`로 10종이 200이 되는지 확인.
3. 대표님이 1~2종을 빼라고 하시면 `apply.ps1 -Exclude <slug>`로 9종·8종 그대로 적용됩니다(9종 시험 완료). 기존 5종 `apply.ps1`을 먼저 돌렸어도 상관없습니다(나머지 5종만 들어감, 시험 완료).

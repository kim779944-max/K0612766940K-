# 2026-11-22 쓰레드·블로그 자동화 결과

- 지시서: `CLAUDE_TASK_20261122_SNS_AUTO.md` · 실행: PC 클로드 코드 · 2026-11-22 02:30~02:45 KST
- 시작 HEAD `a740b4a` (기준선 `fe66561` 이후, 1순위 SLOPE_PRO 결과 포함) → 코드 커밋 `7c7598b` → 이 보고서 커밋
- 진행: A(골격+쓰레드+드라이런) ✅ · B(네이버 임시저장) ✅ 코드·드라이런까지 · C(생성기 2종) ✅ · D(스케줄 .bat) ✅ 등록은 조건 미충족으로 **안 함** · E(가이드·보고) ✅
- 변경 범위: `tools/sns_auto/` 신규 파일 + `.gitignore` 3줄. `oneclick`·쇼룸·가격·문구는 건드리지 않음(catalog.json 은 읽기만). `post_queue.json` 은 **변경 0**(손글 10편 그대로).

## 1. 만든 파일 (경로·크기·역할)

| 파일 (`tools/sns_auto/`) | 크기(B) | 역할 |
|---|---:|---|
| `threads_autopost.py` | 14,946 | ① 쓰레드 하루 1건 게시 + 첫 댓글. `--list/--dry-run/--live/--refresh/--resolve`, 인자 없음 = 스케줄러 모드 |
| `threads_token.py` | 5,920 | ①-b code → 단기 → 장기(60일) 토큰 → 사용자 ID, `.env.local` 기록 / `--refresh` |
| `threads_token.bat` | 545 | 위 스크립트를 1(새 토큰)/2(갱신) 메뉴로 실행 (README 1단계 11번이 부르는 파일) |
| `naver_blog_draft.py` | 19,526 | ② 네이버 블로그 **임시저장만**. `--list/--dry-run/--live --count N/--probe`, 인자 없음 = 하루 1건 |
| `build_product_posts.py` | 10,976 | catalog.json → 상품별 블로그 원고+쓰레드 훅 → 큐 뒤에 추가 (`--list/--add/--update/--capture/--only`) |
| `build_realestate_posts.py` | 7,111 | `data/listings.json` → 매물 글 → 큐 (`--list/--add`) |
| `README_설정가이드.md` | 7,100 | 대표님용 처음 설정 10분 가이드(§7 원문 + 실제 파일명 반영) |
| `register_sns_schedule.bat` + `.ps1` | 371 + 3,086 | 작업 스케줄러 등록(08:10 쓰레드 / 08:20 네이버). **§4-1 조건을 스스로 검사해 미충족이면 등록 거부(종료 3)** |
| `unregister_sns_schedule.bat` | 169 | 두 작업 삭제 |
| `start_sns_chrome.bat` | 638 | 전용 프로필(`%USERPROFILE%\KTS_SNS_CHROME`) 크롬 + 9222 포트 |
| `run_threads.bat` / `run_naver.bat` | 428 / 560 | 스케줄러 실행 래퍼(`logs\run_*_YYYYMMDD.log`) |
| `fill_naver_10.bat` | 484 | 처음 1회 임시저장함 10편 채우기(`--live --count 10`) |
| `requirements.txt` | 229 | playwright (쓰레드는 표준 라이브러리만) |
| `post_queue.json` | 47,039 | 기존 파일(발령 때 커밋) — **수정 없음**, 10건 |

`.gitignore` 추가: `tools/sns_auto/data/`(매물·연락처 보호), `tools/sns_auto/*.tmp`(원자적 저장 중 `.env.tmp` 에 토큰이 잠깐 들어감), `tools/sns_auto/__pycache__/`. 기존 `.env.local`·`logs/`·`images/` 차단은 이미 있었고 확인함.

환경: 이 PC에 파이썬이 없어서(WindowsApps 스텁뿐) `winget install Python.Python.3.12 --scope user` 로 **사용자 범위 설치**(UAC 없음) → Python 3.12.10, `py` 런처 `%LOCALAPPDATA%\Programs\Python\Launcher`. `pip install playwright` → **Version 1.65.2**. `playwright install` 은 하지 않음.

### 지시서 참조 구현에서 바꾼 점 (이유)
1. **error 항목도 진행 차단**(종료 2) — 참조 `pick_item` 은 `error` 를 건너뛰고 다음 글로 넘어가 §3-8 "다음 항목으로 넘어가지 않는다"와 어긋남. `--resolve` 가 `publishing`·`error` 둘 다 `pending` 으로 되돌림.
2. **`publishing` 검사를 큐 전체에서** — 참조는 pending 이 먼저 나오면 뒤쪽 publishing 을 못 봄.
3. **게시 성공 직후 바로 `posted` 저장** — 참조는 댓글·permalink 뒤에 저장해서, 그 사이에 죽으면 `publishing` 으로 남음(재게시 위험은 없지만 불필요한 확인필요). 본문 게시 뒤엔 어떤 실패도 `error` 로 돌리지 않음.
4. **첫 댓글에 `reply_to_id` 실제 전달** — 참조 코드의 `create_container` 호출에 `reply_to_id` 가 빠져 있어 댓글이 아니라 **두 번째 새 글**로 올라갈 뻔함(하루 1건 위반). 수정함.
5. **스케줄러 모드 하루 1건 가드** — 오늘 `posted_at`/`drafted_at` 이 있으면 건너뜀(같은 날 재실행 대비).
6. **본문 3줄 초과도 거부**(§8-1 기준), 한도 초과 응답은 **종료 4** 로 분리, 모든 로그·예외 문자열은 토큰 마스킹(`scrub`) 통과.
7. 네이버: 에디터는 `#mainFrame` iframe/새 `postwrite` 둘 다 지원. 저장 버튼은 `임시저장`·`저장`(개수 붙은 `저장 3` 포함)만 허용하고 **글자나 클래스에 `발행`/`publish` 가 섞인 요소는 아예 후보에서 제외**. 재시도는 **저장 버튼을 누르기 전에 실패한 경우에만 1회(3분 뒤)**(중복 임시저장 방지).
8. 네이버 태그: SmartEditor ONE 은 태그 칸이 `발행` 설정창 안에 있어 발행 버튼을 열지 않고는 못 넣음 → 화면에 태그 칸이 보이면 거기, 아니면 **본문 끝에 `#태그` 한 줄**로 넣고 로그에 남김(README 3단계에 안내).
9. `build_product_posts.py --update` 는 **`자동 생성` 표시가 있는 pending 글만** 갱신(참조는 손글 10편을 자동 문구로 덮어쓸 수 있었음 — §6-2 "문구를 임의로 고치지 않는다" 위반). 중복 판별은 `product_key` + **첫 댓글 링크**(손글 10편엔 product_key 가 없어 그대로면 slope·viewer 등이 중복 추가됨).
10. 스케줄 등록은 인라인 `powershell -Command ^` 대신 `.ps1`(BOM) 분리 — 경로에 공백·한글(`바탕 화면`)이 있어 따옴표가 깨지기 쉬움. 작업 동작은 `.bat` 을 직접 실행.

## 2. 검증 결과 (§8-1)

| 검사 | 합격 기준 | 결과 |
|---|---|---|
| 문법 | 5개 파일 오류 0 | ✅ `py_compile` exit 0 |
| 큐 | items ≥10, 모든 `threads.text` ≤500자·`http` 없음·3줄 이내 | ✅ `items 10` · 92~121자 · 전부 3줄 · http 0 |
| 쓰레드 드라이런 | `[DRY]` 줄+본문, 네트워크 0건, 종료 0 | ✅ 종료 0 · **urlopen/socket 을 막은 상태에서 실행 → network calls: 0** |
| 블로그 드라이런 | 제목·본문·태그 출력, 종료 0 | ✅ 종료 0 (1,909자 · 사진자리 [1,2,3] · 태그 12개) |
| 비밀값 | `git status` 에 `.env.local`·`logs/`·`images/` 안 보임 | ✅ `.env.local` 없음, `logs/` 는 ignore 확인, 커밋 diff 에 토큰·실명경로 없음 |
| 실제 게시 | 0건 | ✅ 로그에서 `게시 완료`/`임시저장 완료` **0건** |

명령 출력 원문:
```
== py -3 --version
Python 3.12.10
== py_compile
exit 0
== queue
items 10
== threads --list
2026-11-22 02:38:43 2026-11-23_slope           pending    113자  토지정보(경사도)
2026-11-22 02:38:43 2026-11-24_doksim          pending     96자  독심술 v2
2026-11-22 02:38:43 2026-11-25_viewer          pending    105자  더뷰
2026-11-22 02:38:43 2026-11-26_sign            pending     98자  더싸인
2026-11-22 02:38:43 2026-11-27_thescan         pending    104자  더스캔
2026-11-22 02:38:43 2026-11-28_realty          pending     92자  매물수집기
2026-11-22 02:38:43 2026-11-29_bungee          pending    110자  번개알바
2026-11-22 02:38:43 2026-11-30_redev           pending     94자  재개발 진행조회기
2026-11-22 02:38:43 2026-12-01_hogang          pending    113자  호갱 탈출 내비
2026-11-22 02:38:43 2026-12-02_converter       pending    121자  원클릭 변환기
exit 0
== build_product_posts --list
catalog 20261121u · live+링크 22개 · 큐 10건
sale          오늘의 특가            없음
photo2doc     원클릭 변환기           있음
theform       더양식 — 내 양식 1초     없음
contract      계약서 1초 생성기        없음
thedetail     더상세 — 상세페이지 1초    없음
viewer        더뷰 — 만능 뷰어        있음
loan          기업 대출·자금 조회기      없음
tax           창업·대출 세무구조 내비     없음
navi          독심술 v2            있음
saycap        세이캡 2026          없음
organizer     폰정리               없음
keyword       롱테일 키워드 생성기       없음
sign          더싸인 — 폰 전자서명      있음
tongyeok      더통역               없음
realty        매물수집기             있음
slope         토지정보(경사도)         있음
commerce      이커머스 원클릭 5종       없음
redev         재개발 진행조회기         있음
gagebu        원클릭 가계부           없음
hogang        호갱 탈출 내비          있음
golf          골프 스윙 교정          없음
petmind       동물 번역기            없음
exit 0
== build_realestate --list
[안내] 매물 데이터가 없습니다: data/listings.json
       지시서 §6-8 형식으로 대표님이 정리한 매물을 넣고 다시 실행하세요.
exit 3      ← 정상(데이터 미입력)
== 네트워크 차단 드라이런
## threads_autopost.py --dry-run exit=0
## naver_blog_draft.py --dry-run exit=0
## network calls: 0
```

토큰 없는 상태(§4-3 수동 1회 테스트 포함):
```
threads_autopost.py --live        → [SKIP] 토큰/사용자ID 없음 — threads_token.py 를 먼저 실행하세요   exit 3
threads_autopost.py (인자 없음)   → 같은 줄                                                         exit 3
naver_blog_draft.py --live --count 1 → [SKIP] NAVER_BLOG_ID 없음 (.env.local)                       exit 3
run_threads.bat  → exit 3, logs\run_threads_20261122.log: "[SKIP] 토큰/사용자ID 없음 — …"
run_naver.bat    → exit 3, logs\run_naver_20261122.log:   "[SKIP] NAVER_BLOG_ID 없음 (.env.local)"
register_sns_schedule.ps1 -CheckOnly →
  [등록 안 함] 아래 조건이 아직 안 됐습니다 (README_설정가이드.md 1~2단계):
    - THREADS_ACCESS_TOKEN 없음 (.env.local)
    - THREADS_USER_ID 없음 (.env.local)
    - NAVER_BLOG_ID 없음 (.env.local)
  exit 3
schtasks /Query KTS_SNS_THREADS / KTS_SNS_NAVER → 둘 다 없음(exit 1)
```

추가 검증(지시서 밖, 실제 API 0건): **임시 폴더 사본 + 로컬 가짜 Threads 서버**로 `--live` 흐름 전체를 돌림(실제 `post_queue.json` 은 안 건드림).
```
1) live → exit 0 · 한도 0/250 → 컨테이너(IMAGE) → 상태 FINISHED → publish → 첫 댓글(reply_to_id=P1) → permalink · 큐 posted
2) 같은 날 스케줄러 재실행 → exit 0 "[SKIP] 오늘 이미 1건 게시했습니다(하루 1건)"
3) publish 500 → exit 1 · 큐 error
4) error 남은 채 재실행 → exit 2 [확인필요] (다음 글로 안 넘어감)
5) publishing 남은 채 재실행 → exit 2 [확인필요]
6) --resolve → exit 0 · pending 복구
7) 본문에 링크 → exit 1 "본문에 링크가 있습니다"
8) 로그에 토큰 원문 → False
```
(이 시험에서 실제로 나간 요청은 `autooneclick.com/shots/slope_full.png` 이미지 확인 HEAD 1건뿐. Meta API 호출은 0건.)

네이버 저장 버튼 가드 — 헤드리스 크롬(PC 설치본, `launch(executable_path=…)`)에서 실제 `click_by_text` 실행:
```
A clicked: 저장3 :: save_btn__y | log: [save_btn__y]     ← 발행 버튼·'임시저장 목록 발행' 옆에 있어도 저장만 눌림
B blocked: 금지 버튼 클릭 차단: 발행                         ← '발행'을 직접 요청해도 예외
C not found (publish untouched): 버튼 못 찾음: ['임시저장', '저장'] | log: ''   ← 발행 버튼만 있는 화면에서는 아무것도 안 누르고 실패
D split: [('text', 3), ('photo', 1), ('text', 3), ('photo', 2)]
E suspect PostView: True      ← 저장 뒤 PostView 로 바뀌면 종료 2
F still writing: None
```

## 3. 드라이런 출력 원문

### 쓰레드 1건
```
2026-11-22 02:38:44 [DRY] 항목 2026-11-23_slope · 주제 토지정보(경사도)
2026-11-22 02:38:44 [DRY] 본문 113자 / 한도 500자 · 3줄
2026-11-22 02:38:44 [DRY] 이미지 https://autooneclick.com/shots/slope_full.png  (드라이런: URL 확인 생략)
2026-11-22 02:38:44 [DRY] 첫 댓글 지번 넣고 바로 볼 수 있습니다 → https://autooneclick.com/slope/
[DRY] ---- 본문 ----
땅 보러 갔는데 '경사가 좀 있는 편'이라는 말만 듣고 왔습니다.
그 땅이 5도인지 20도인지에 따라 건축비와 배수가 완전히 달라집니다.
지번만 넣으면 그 자리 경사가 그림으로 나옵니다. (링크는 댓글)
[DRY] ---- 끝 ----
exit 0
```

### 블로그 1건 (머리 부분, 본문 전문은 `post_queue.json` 1번 항목과 동일)
```
2026-11-22 02:38:44 [DRY] 항목 2026-11-23_slope · 제목 땅 경사도, 계약 전에 지번으로 확인하는 방법 — 5도와 20도의 차이
2026-11-22 02:38:44 [DRY] 본문 1909자 · 문단묶음 4 · 사진자리 [1, 2, 3]
2026-11-22 02:38:44 [DRY] 태그 12개: 토지경사도, 평균경사도, 지번조회, 필지경계, 임야경사도, 토지매입, 경사도지도, 건축가능여부, 5m격자, 부동산토지, 절토성토, 개발행위허가
2026-11-22 02:38:44 [DRY] 사진1 slope_1.png · 없음(건너뜀)
2026-11-22 02:38:44 [DRY] 사진2 slope_2.png · 없음(건너뜀)
2026-11-22 02:38:44 [DRY] 사진3 slope_3.png · 없음(건너뜀)
[DRY] ---- 본문 ----
■ '경사가 좀 있다'는 말로는 판단이 안 됩니다
땅을 보러 가면 대개 이 말로 끝납니다. '경사가 좀 있는 편입니다.' …
(중략 — 1,909자)
■ 무료로 먼저
하루 3건까지 무료이고 자정에 다시 채워집니다. 더 필요하면 10건권 9,000원입니다(부가세 별도).
https://autooneclick.com/slope/
…
[DRY] ---- 끝 ----
exit 0
```

## 4. 하지 않은 것
- **쓰레드 실제 게시 0건** · Meta API 호출 0건 (토큰 없음. 가짜 서버 시험만).
- **네이버 임시저장 0건 · 발행 0건** — `NAVER_BLOG_ID`·로그인된 전용 크롬이 없어 라이브 실행 불가. 코드에 발행 클릭 경로 없음.
- **스케줄 등록 안 함** — §4-1 조건(토큰·사용자ID·블로그ID) 미충족. `register_sns_schedule.bat` 은 만들었고, 실행해도 조건 검사에서 거부됨(위 출력).
- `build_product_posts.py --add` / `build_realestate_posts.py --add` **실행 안 함** — 큐는 손글 10편 그대로(§6-7 "한 번에 다 넣지 않는다", 순서는 사람이 정함).
- `--capture`(실물 캡처) 안 함 — 전용 크롬(CDP) 없음. `images/` 비어 있음 → 지금은 `[사진N]` 자리를 건너뛰고 글만 들어감.
- `.env.local` 만들지 않음(대표님/`threads_token.py` 가 만듦).

## 5. 대표님이 하실 일 (총 약 15~25분, 처음 한 번)
1. **쓰레드 토큰 (5분)** — `README_설정가이드.md` 1단계 → `threads_token.bat` → `1` → 앱 ID·시크릿·code.
2. **네이버 로그인 (3분)** — `start_sns_chrome.bat` → 로그인 → `.env.local` 에 `NAVER_BLOG_ID=…` 한 줄.
3. **첫 확인 (2분)** — `py -3 naver_blog_draft.py --probe` 로 에디터 구조 덤프(아무것도 입력·저장 안 함) → 이어서 `py -3 naver_blog_draft.py --live --count 1` 로 1편만 넣어 임시저장함을 눈으로 확인. 괜찮으면 `fill_naver_10.bat`(10~15분).
4. **자동 시작 (30초)** — `register_sns_schedule.bat`. 조건이 맞으면 `[OK] KTS_SNS_THREADS 매일 08:10 · 다음 실행 …` 이 나옴.
   - 등록 명령(같은 내용): `tools\sns_auto\register_sns_schedule.bat`
   - **첫 실제 쓰레드 게시는 다음 날 08:10 자동 실행 또는 대표님이 `py -3 threads_autopost.py --live` 를 직접 실행할 때** 일어남.
5. (선택) 사진: `images\{key}_1~3.png` (`slope_1.png` …). 전용 크롬이 켜져 있으면 `py -3 build_product_posts.py --capture --only slope` 로 상품 페이지를 찍을 수 있음(단, 손글 10편의 key 중 `doksim`·`thescan`·`bungee`·`converter` 는 catalog key 와 이름이 달라 `--capture` 가 그 이름으로 찍지 않음 → 손으로 저장).

## 6. 실패·막힌 것
- **파이썬 없음** → `winget … --scope user` 로 설치해 해결(UAC 없음, 1~2분).
- 검증 중 하네스 문제 2건(제품 문제 아님): PowerShell 5.1 이 here-string 을 `py -c` 로 넘길 때 따옴표를 깨뜨림 → 임시 `.py` 파일로 실행. `cmd /c run_threads.bat` 이 현재 폴더 bat 을 못 찾음(PowerShell 위치 ≠ 프로세스 현재 폴더) → 전체 경로로 실행해 통과. 스케줄러는 전체 경로로 부르므로 영향 없음.
- **네이버 셀렉터는 라이브 화면에서 확인 못 함**(로그인 계정 없음). 제목 `.se-documentTitle .se-text-paragraph`, 본문 `.se-section-text .se-text-paragraph`, 사진 버튼 `.se-image-toolbar-button` 은 2026-11 알려진 구조 기준 추정. 처음 실행에서 `제목/본문 칸을 못 찾음` 이 나오면 `--probe` 덤프로 맞춰야 함(좌표 클릭 우회는 넣지 않음).
- 사진 삽입 뒤 커서 위치(사진 다음 줄로 이어 쓰기)도 라이브 미확인.

## 7. 남은 위험
- **토큰 60일**: 45일 지나면 게시 실행 때 자동 갱신. PC가 60일 넘게 꺼져 있었으면 갱신 불가 → `threads_token.bat` 1번으로 재발급.
- **에디터 개편**: 네이버가 SmartEditor 를 바꾸면 제목/본문 칸을 못 찾고 종료 1(글은 안 올라감). 저장 버튼은 글자로 찾으므로 비교적 오래 감. 발행 버튼은 어떤 경우에도 안 누름.
- **저품질**: 발행은 사람이 하므로 위험 낮음. 다만 10편이 같은 구조(■ 소제목·한계 문단)라 발행 간격은 하루 1편 유지 권장.
- **임시저장 10건 보관**: 네이버 임시저장함 보관 기간·개수 한도가 있을 수 있음(미확인). 오래 묵히지 말고 순서대로 발행.
- **`#태그` 한 줄**: 태그 칸 대신 본문 끝에 들어가므로 발행 전에 확인.
- **이미지 URL**: 큐의 쓰레드 이미지 중 `sign`·`thescan`·`bungee`·`hogang` 은 `image_url` 이 비어 있어 텍스트 글로 나감(`sign` 은 notes 에 "sign_home.png 캡처 필요" 메모만 있음). 나머지 6개 URL 은 오늘 200 image/png 확인.
- `run_*.bat` 로그 파일명의 `%date%` 자르기는 이 PC(한국어 `2026-11-22` 형식) 기준. 파이썬 쪽 `logs\threads_YYYY-MM-DD.log` 는 형식과 무관.

## 8. 되돌리기
- 되돌리기 기준 HEAD: 코드 커밋 전 `a740b4a`, 코드 커밋 `7c7598b`.
- 스케줄(등록했을 때만): `unregister_sns_schedule.bat` 또는
  ```
  schtasks /Delete /TN "KTS_SNS_THREADS" /F
  schtasks /Delete /TN "KTS_SNS_NAVER" /F
  ```
- 즉시 정지: `.env.local` 에 `SNS_DAILY_ENABLED=0`, 또는 `.env.local` 삭제.
- 파일 삭제 목록(`tools/sns_auto/`): `threads_autopost.py threads_token.py threads_token.bat naver_blog_draft.py build_product_posts.py build_realestate_posts.py README_설정가이드.md register_sns_schedule.bat register_sns_schedule.ps1 unregister_sns_schedule.bat start_sns_chrome.bat run_threads.bat run_naver.bat fill_naver_10.bat requirements.txt` → `git revert 7c7598b` 한 번이면 됨(`.gitignore` 3줄 포함). `post_queue.json` 은 발령 커밋 것이라 그대로 남음.
- 전용 크롬 프로필: `%USERPROFILE%\KTS_SNS_CHROME` 폴더 삭제(아직 안 만들어짐). 네이버 임시저장 글은 블로그 화면에서 직접 삭제.
- 파이썬: 설정 → 앱 → "Python 3.12.10 (64-bit)" / "Python Launcher" 제거.

남은 것: 라이브 확인 3가지 — ① 대표님 토큰 입력 후 첫 쓰레드 실제 게시, ② 네이버 로그인 후 `--probe`·`--count 1`로 셀렉터 확인, ③ 조건이 갖춰진 뒤 스케줄 등록.

# PC 클로드 코드 작업 지시서 — 2026-11-22 · 쓰레드 자동 게시 + 네이버 블로그 임시저장 자동화

> 발령: 2026-11-22 00:5x · 사령관 지니 → PC 클로드 코드(Pro)
> 대표님 지시: **"오늘 만들어 내일부터 매일 올리게"**
> 대상: **`kim779944-max/K0612766940K-` 저장소 안 `tools/sns_auto/` 한 곳만.** `oneclick` 사이트·쇼룸·가격·문구는 **손대지 않는다**(제0원칙).
> 결과 보고서: **`CLAUDE_RESULT_20261122_SNS_AUTO.md`** (이 저장소에 작성·커밋·푸시)
> 기준선(2026-11-22 00:50 KST): `K0612766940K-` **`fe66561`**
> 실행 순서: 이 지시서는 **2순위**다. 1순위(`CLAUDE_TASK_20261122_SLOPE_PRO.md`)가 끝난 뒤 자동 실행기가 이 문서를 집는다.

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 0-1. 이번 회차 결과물 (한 문장)
**아침에 PC가 혼자 켜져서 ① 쓰레드에 오늘 몫 글 1건(본문 링크 0 + 첫 댓글에 링크 1개)을 올리고, ② 네이버 블로그에는 같은 소재의 글을 사진·태그까지 넣어 '임시저장' 상태로 올려 두며, 대표님은 블로그 화면에서 `발행`만 누르면 되는 상태.**

### 0-2. 하지 않는 것 (하나라도 어기면 그 항목은 실패로 기록)

1. **실제 게시·발행 금지 (이번 회차 한정)** — 지금은 **쓰레드 액세스 토큰이 아직 없다.** 토큰 없이 도는 코드를 만들고 `--dry-run`까지만 검증한다. **API로 실제 글을 올리는 호출 0건.** 네이버는 **`임시저장` 버튼까지만** 누르고 **`발행`은 절대 누르지 않는다**(§5-4 가드 참조).
2. **네이버 완전 자동 발행 금지** — 하루 1건씩 기계가 발행하면 저품질·차단 위험이 있다. **임시저장까지만** 하고 마지막 `발행`은 사람이 누른다. 이건 이번 회차의 설계 원칙이지 나중에 바꿀 옵션이 아니다.
3. **비밀값 커밋 금지** — 저장소는 **공개**다. 토큰·앱 시크릿·비밀번호·쿠키·`C:\Users\...` 실명 경로·PC 이름을 **커밋하지 않는다**. 비밀값은 **`tools/sns_auto/.env.local`** 하나에만 둔다(`.gitignore`에 이미 등록됨 — §1-4).
4. **문구에 원리·내부구조 노출 금지** — 대표님 확립 원칙(2026-11-21 23:47): **"우리가 어떻게 만들었는지는 절대원리가 나가면 안 된다."** 글에 알고리즘·계산식·"어떻게 만들었는지"·특허·군단·매출 구조를 쓰지 않는다. **손님이 겪는 상황과 눈에 보이는 결과만** 쓴다.
5. **과장·아부·허위 수치 금지** — 확인하지 않은 성능·매출·후기·"최고/유일/보장" 금지. 쇼룸 `catalog.json`에 적힌 사실(가격·무료 조건·링크)만 쓴다.
6. **쓰레드 본문에 링크 금지** — 본문 링크 0개, **링크는 첫 댓글에 1개만**. (§3-6)
7. **하루 1건 초과 게시 금지** — 큐에서 1건만 꺼낸다. 재실행해도 이미 올린 글을 다시 올리지 않는다(§3-8).
8. **다른 파일 변경 금지** — 이번에 만드는 것은 **`tools/sns_auto/` 아래 신규 파일 + `.gitignore` 한 줄 확인**뿐이다. `oneclick` 저장소는 **읽기만** 한다.
9. **스케줄 등록은 조건부** — `.env.local`에 유효한 토큰이 **없으면** 스케줄을 등록하지 않는다(매일 실패 로그만 쌓인다). `.bat` 파일만 만들어 두고 **등록 명령을 결과 보고서에 적어** 대표님이 토큰 넣은 뒤 한 번 실행하게 한다. (§4)

### 0-3. 진행 규칙
- **A → B → C → D → E** 순서(§2~§7). 자동 실행기는 한 번에 90분까지만 돈다. **덩어리마다 커밋**해서 다음 실행이 이어받게 한다.
- **A(공통 골격 + 쓰레드 스크립트 + 드라이런 통과)** 가 최소 합격선이다. 시간이 모자라면 남은 것을 정직하게 보고하고 보고서 마지막 줄에 `남은 것: …`을 적는다.
- 이미 끝난 항목은 다시 만들지 않는다.

---

## 1. 0단계 — 저장소·파이썬·폴더 (10분)

### 1-1. 저장소 최신화
```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull --rebase
git rev-parse --short HEAD          # 기대: fe66561 이상 (1순위 결과가 올라왔으면 그 뒤여도 정상)
```
> 경로가 없으면 `KTS_작업실` 폴더 안에서 `.git\config`에 `K0612766940K-.git`이 들어 있는 폴더를 찾아 쓴다. **force-push 금지, 남의 커밋 되돌리기 금지.** 원격이 앞서 있으면 `git pull --rebase` 후 양쪽을 살려서 푸시한다.

### 1-2. 파이썬 확인
```powershell
py -3 --version        # 3.10 이상이면 OK. 없으면 python --version 시도
py -3 -m pip --version
```
없으면 `winget install Python.Python.3.12` 로 설치하고 **새 창**에서 다시 확인한다.

### 1-3. 폴더 구조 (그대로 만든다)
```
tools/sns_auto/
├─ threads_autopost.py          # ① 쓰레드 자동 포스팅
├─ threads_token.py             # ①-b 토큰 발급·갱신 (대표님 1분 설정용)
├─ naver_blog_draft.py          # ② 네이버 블로그 임시저장
├─ post_queue.json              # ③ 7일치 초기 콘텐츠 큐
├─ README_설정가이드.md          # ④ 대표님용 1분 설정 가이드
├─ register_sns_schedule.bat    # ④-b 작업 스케줄러 등록
├─ unregister_sns_schedule.bat  # ④-c 해제
├─ start_sns_chrome.bat         # ②-b 네이버 로그인 창(전용 프로필) 실행
├─ run_threads.bat              # 스케줄러가 부르는 실행 래퍼(로그 남김)
├─ run_naver.bat                # 위와 같음
├─ requirements.txt             # playwright 등 (쓰레드는 표준 라이브러리만 씀)
├─ .env.local                   # ★비밀값 (커밋 금지, 대표님이 채움)
├─ images/                      # 블로그용 사진 (커밋 금지)
└─ logs/                        # 실행 로그·스크린샷 (커밋 금지)
```

### 1-4. `.env.local` 차단 확인 (필수)
`.gitignore`에 아래가 **이미 들어가 있다**(발령 때 추가함). 없으면 추가하고, 반드시 무시되는지 확인한다.
```powershell
git check-ignore -v tools/sns_auto/.env.local
# 기대 출력: .gitignore:…:.env.local   tools/sns_auto/.env.local
```
무시가 안 되면 **더 진행하지 말고** `.gitignore`를 고친 뒤 확인부터 한다.

### 1-5. 의존성
```powershell
py -3 -m pip install --upgrade playwright
py -3 -m playwright --version
```
- **`playwright install`은 하지 않는다.** 이미 PC에 깔린 크롬에 CDP로 붙는 방식이라 브라우저를 새로 받을 필요가 없다.
- 쓰레드 스크립트는 **표준 라이브러리(urllib)만** 쓴다. `requests` 설치 실패로 아침 작업이 죽는 일을 막기 위해서다.

---

## 2. 공통 규칙 — 비밀값·설정·로그

### 2-1. `.env.local` 키 (이 5개만)
| 키 | 뜻 | 누가 채우나 |
|---|---|---|
| `THREADS_ACCESS_TOKEN` | Threads 장기 액세스 토큰(60일) | `threads_token.py` 가 자동 기록 |
| `THREADS_USER_ID` | Threads 사용자 숫자 ID | `threads_token.py` 가 자동 기록 |
| `THREADS_TOKEN_ISSUED` | 토큰 발급일 `YYYY-MM-DD` | 위와 같음 |
| `NAVER_BLOG_ID` | 네이버 블로그 아이디 | 대표님이 직접 (블로그 주소 `blog.naver.com/○○○`의 ○○○) |
| `SNS_DAILY_ENABLED` | `1`이면 스케줄 실행, `0`이면 아무것도 안 함(비상 정지) | 대표님 |

### 2-2. 절대 규칙
- **토큰을 화면·로그에 통째로 찍지 않는다.** 마스킹 함수 하나만 쓴다: `mask(t) = t[:6] + "…" + t[-4:]`.
- **`.env.local`을 읽어 콘솔에 전체 출력하는 코드를 만들지 않는다.** `--show-env` 같은 편의 기능도 만들지 않는다.
- 로그 파일은 `tools/sns_auto/logs/` 아래에만 쓴다. 로그에도 토큰 원문이 남지 않게 마스킹한다.
- 예외 메시지에 요청 URL을 그대로 넣지 않는다(쿼리에 `access_token`이 들어 있다). **반드시 `mask()`를 거친 문자열**만 남긴다.

### 2-3. 공통 종료 코드 (두 스크립트 동일)
| 코드 | 뜻 | 스케줄러 동작 |
|---|---|---|
| `0` | 정상 (게시 완료 / 임시저장 완료 / 오늘 할 일 없음) | 조용히 끝 |
| `1` | 일반 오류 (API 오류·셀렉터 실패) | 로그만 남김 |
| `2` | **확인 필요** (중복 위험 상태, 사람이 봐야 함) | 로그에 `확인필요` 표시 |
| `3` | 설정 없음 (토큰·블로그ID 없음 / 크롬 미실행 / 로그인 만료) | 로그만 남김 |
| `4` | 하루 한도 초과 (API가 거절) | 로그만 남김 |

---

## 3. ① 쓰레드(Threads) 자동 포스팅 — `tools/sns_auto/threads_autopost.py`

### 3-1. 방식 (Meta 공식 Threads API, 2026-11 기준 확인)
글은 **한 번에 안 올라간다. 2단계**다.
1. **컨테이너 만들기** — `POST https://graph.threads.net/v1.0/{user-id}/threads` 에 `media_type`(`TEXT`/`IMAGE`)·`text`·(이미지면)`image_url`·`access_token` 전달 → `{"id": "<container>"}`
2. **발행** — `POST /{user-id}/threads_publish` 에 `creation_id=<container>` → `{"id": "<post>"}`
- 이미지 글은 컨테이너 만든 뒤 **평균 30초** 기다렸다가 상태를 확인한다: `GET /{container}?fields=status,error_message` → `FINISHED` 면 발행, `ERROR`/`EXPIRED` 면 중단. **1분에 1회, 최대 5분**까지만 확인한다.
- **이미지는 공개 URL이어야 한다.** Meta 서버가 직접 받아간다(로컬 파일 경로 불가).
- **첫 댓글**도 같은 2단계다: `reply_to_id=<post-id>` 를 붙여 텍스트 컨테이너를 만들고 발행한다.

### 3-2. 확인된 제약 (지어내지 말고 이 값을 코드에 상수로 넣는다)
| 항목 | 값 | 비고 |
|---|---|---|
| 글자 수 | **본문 500자** | 넘으면 발행 거절. 스크립트가 **499자에서 자르지 말고 실패**시킨다(문구가 잘리면 안 됨) |
| 이미지 | JPEG/PNG, **8MB 이하**, 폭 320px 이상, 종횡비 10:1 이내 | 권장 1080×1080 |
| 게시 한도 | 프로필당 **24시간 250건** | 우리는 하루 1건이라 닿지 않음 |
| 댓글 한도 | 24시간 1,000건 | 위와 같음 |
| 토큰 수명 | 장기 토큰 **60일**, 하루 1번 이상 지난 뒤 갱신 가능 | 60일 지나면 갱신 불가 → **45일 지나면 자동 갱신** |
| 권한 | `threads_basic`, `threads_content_publish`, `threads_manage_replies` | 앱 설정에서 승인 |

> 한도 확인용(선택, 실패해도 게시는 계속): `GET /{user-id}/threads_publishing_limit?fields=quota_usage,config`.

### 3-2b. 쓰레드 본문은 **짧은 2~3줄 훅**이다 (대표님 지시)
- **2~3줄, 100~200자**를 목표로 한다. 500자는 API 한도일 뿐, 우리 글의 목표 길이가 아니다. 길게 쓰면 읽히지 않는다.
- 구성: **① 상황 한 줄(선입견 깨기) ② 사실 한 줄 ③ 이어지는 곳 한 줄(링크는 여기서 말하지 않고 '링크는 댓글'로만)**.
- 링크는 본문에 넣지 않는다(스크립트가 `http` 발견 시 거부). 첫 댓글에만 넣는다.
- 긴 설명·사례·수치·표는 **블로그 원고가 맡는다**(§6-4). 쓰레드는 블로그로 들어오는 입구다.
- 예(경사도): `땅 보러 갔는데 '경사가 좀 있는 편'이라는 말만 듣고 왔습니다. / 그 땅이 5도인지 20도인지에 따라 건축비와 배수가 완전히 달라집니다. / 지번만 넣으면 그 자리 경사가 그림으로 나옵니다. (링크는 댓글)`

### 3-3. CLI
```
py -3 tools\sns_auto\threads_autopost.py --list      # 큐 상태 표로 보기
py -3 tools\sns_auto\threads_autopost.py --dry-run   # 오늘 올릴 글을 화면에만 출력 (API 호출 0건)
py -3 tools\sns_auto\threads_autopost.py --live      # 실제 게시 (토큰 있을 때만. 대표 승인 후)
py -3 tools\sns_auto\threads_autopost.py --refresh   # 토큰 갱신만
py -3 tools\sns_auto\threads_autopost.py --resolve   # 'publishing'에 멈춘 항목을 사람 확인 후 정리
```
- `--dry-run`은 **네트워크 요청을 한 번도 보내지 않는다**(이미지 URL 확인도 생략). 출력은 `[DRY]` 로 시작하는 줄로: 항목 id, 글자 수, 이미지 URL, 첫 댓글 문구, 본문 전문.
- 인자 없이 실행하면 **`--live`와 같게** 동작하되, `SNS_DAILY_ENABLED`가 `0`이면 아무것도 하지 않고 `0`으로 끝난다(스케줄러가 이 형태로 부른다).

### 3-4. 흐름 (그대로 구현)
1. `.env.local` 읽기 → 키 없으면 `[SKIP] 토큰 없음 (threads_token.py 먼저 실행)` 출력, **종료 3**
2. 큐 읽기 → `status`가 `publishing`인 항목이 있으면 **아무것도 하지 않고 종료 2** (중복 위험, 사람 확인 필요)
3. `status == "pending"` 인 **첫 항목** 선택. 없으면 `[SKIP] 큐에 남은 글이 없습니다` **종료 0**
4. 본문 검증: 500자 초과 → **종료 1**(자르지 않음). 본문에 `http` 포함 → **종료 1**(링크는 첫 댓글에만)
5. 큐에 `status="publishing"`, `attempt_at=<ISO시각>` 기록 후 **파일 저장**(원자적: `.tmp` → `replace`)
6. 이미지: `image_url`이 있고 **HTTP 200 + `Content-Type: image/*`** 일 때만 이미지 글. 아니면 텍스트 글 + 로그에 `이미지 생략` 기록
7. 컨테이너 생성 → (이미지면) 상태 확인 → 발행 → **첫 댓글** 생성·발행
8. 성공 시 큐 항목에 `status="posted"`, `posted_at`, `post_id`, `reply_id`, `permalink` 기록 → 종료 0. 실패 시 `status="error"`, `error` 메모 → 종료 1
9. 모든 단계 `logs/threads_YYYY-MM-DD.log` 에 시각·단계·결과를 남긴다

### 3-5. 참조 구현 (그대로 써도 됩니다 — 표준 라이브러리만 사용)
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""KTS 쓰레드 자동 포스팅 — 하루 1건 (Meta Threads API v1.0)
   python threads_autopost.py [--list|--dry-run|--live|--refresh|--resolve]
"""
import argparse, datetime, json, os, sys, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

BASE = "https://graph.threads.net/v1.0"
ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
ENV = ROOT / ".env.local"
LOGDIR = ROOT / "logs"
MAX_TEXT = 500
IMAGE_WAIT_TRIES = 5       # 1분 간격 5회 = 최대 5분

def mask(t: str) -> str:
    if not t:
        return "(없음)"
    return t[:6] + "…" + t[-4:] if len(t) > 12 else "…"

def log(msg: str) -> None:
    LOGDIR.mkdir(exist_ok=True)
    line = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}"
    print(line)
    with open(LOGDIR / f"threads_{datetime.date.today():%Y-%m-%d}.log", "a", encoding="utf-8") as f:
        f.write(line + "\n")

def load_env() -> dict:
    cfg = {}
    if ENV.exists():
        for raw in ENV.read_text(encoding="utf-8-sig").splitlines():
            s = raw.strip()
            if not s or s.startswith("#") or "=" not in s:
                continue
            k, v = s.split("=", 1)
            cfg[k.strip()] = v.strip().strip('"').strip("'")
    for k in ("THREADS_ACCESS_TOKEN", "THREADS_USER_ID"):
        if not cfg.get(k) and os.environ.get(k):
            cfg[k] = os.environ[k]
    return cfg

def save_env_key(key: str, value: str) -> None:
    """기존 .env.local 의 다른 줄은 건드리지 않고 key 한 줄만 바꾼다."""
    lines = ENV.read_text(encoding="utf-8-sig").splitlines() if ENV.exists() else []
    out, done = [], False
    for raw in lines:
        if raw.strip().startswith(key + "="):
            out.append(f"{key}={value}")
            done = True
        else:
            out.append(raw)
    if not done:
        out.append(f"{key}={value}")
    tmp = ENV.with_suffix(".tmp")
    tmp.write_text("\n".join(out) + "\n", encoding="utf-8")
    os.replace(tmp, ENV)

def api_get(path: str, params: dict) -> dict:
    url = f"{BASE}/{path}?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP {e.code} {e.read().decode('utf-8', 'replace')[:400]}") from None
    except urllib.error.URLError as e:
        raise RuntimeError(f"연결 실패: {e.reason}") from None

def api_post(path: str, data: dict) -> dict:
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(f"{BASE}/{path}", data=body, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP {e.code} {e.read().decode('utf-8', 'replace')[:400]}") from None
    except urllib.error.URLError as e:
        raise RuntimeError(f"연결 실패: {e.reason}") from None

def url_ok(url: str) -> bool:
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.status == 200 and r.headers.get("Content-Type", "").startswith("image/")
    except Exception:
        return False

def load_queue() -> dict:
    return json.loads(QUEUE.read_text(encoding="utf-8"))

def save_queue(q: dict) -> None:
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, QUEUE)

def pick_item(q: dict) -> dict | None:
    for it in q.get("items", []):
        if it.get("status", "pending") == "publishing":
            return it            # 호출부에서 '확인 필요'로 처리
        if it.get("status", "pending") == "pending":
            return it
    return None

def create_container(uid, token, media_type, text, image_url=None) -> str:
    data = {"media_type": media_type, "text": text, "access_token": token}
    if image_url:
        data["image_url"] = image_url
    return api_post(f"{uid}/threads", data)["id"]

def wait_ready(cid: str, token: str) -> None:
    for i in range(IMAGE_WAIT_TRIES):
        time.sleep(60)
        st = api_get(cid, {"fields": "status,error_message", "access_token": token})
        status = st.get("status")
        if status == "FINISHED":
            return
        if status in ("ERROR", "EXPIRED"):
            raise RuntimeError(f"컨테이너 {status}: {st.get('error_message', '')}")
        log(f"  컨테이너 준비 중… ({status}, {i + 1}/{IMAGE_WAIT_TRIES})")
    raise RuntimeError("컨테이너 준비 시간 초과(5분)")

def publish(uid: str, token: str, cid: str) -> str:
    return api_post(f"{uid}/threads_publish", {"creation_id": cid, "access_token": token})["id"]

def maybe_refresh(cfg: dict) -> None:
    issued = cfg.get("THREADS_TOKEN_ISSUED", "")
    if not issued or not cfg.get("THREADS_ACCESS_TOKEN"):
        return
    age = (datetime.date.today() - datetime.date.fromisoformat(issued)).days
    if age < 45:
        return
    log(f"토큰 나이 {age}일 → 갱신 시도")
    r = api_get("refresh_access_token", {"grant_type": "th_refresh_token",
                                         "access_token": cfg["THREADS_ACCESS_TOKEN"]})
    save_env_key("THREADS_ACCESS_TOKEN", r["access_token"])
    save_env_key("THREADS_TOKEN_ISSUED", f"{datetime.date.today():%Y-%m-%d}")
    log(f"토큰 갱신 완료 ({mask(r['access_token'])}, {r.get('expires_in')}초)")

def main() -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--list", action="store_true")
    g.add_argument("--dry-run", action="store_true")
    g.add_argument("--live", action="store_true")
    g.add_argument("--refresh", action="store_true")
    g.add_argument("--resolve", action="store_true")
    a = ap.parse_args()

    cfg = load_env()

    if a.list:
        q = load_queue()
        for it in q["items"]:
            log(f"{it['id']:<26} {it.get('status', 'pending'):<10} {it.get('topic', '')}")
        return 0

    if a.resolve:
        q = load_queue()
        for it in q["items"]:
            if it.get("status") == "publishing":
                it["status"] = "pending"
                it["note"] = "사람 확인 후 pending 복구"
                log(f"[RESOLVE] {it['id']} → pending")
        save_queue(q)
        return 0

    if a.refresh:
        if not cfg.get("THREADS_ACCESS_TOKEN"):
            log("[SKIP] 토큰 없음")
            return 3
        r = api_get("refresh_access_token", {"grant_type": "th_refresh_token",
                                             "access_token": cfg["THREADS_ACCESS_TOKEN"]})
        save_env_key("THREADS_ACCESS_TOKEN", r["access_token"])
        save_env_key("THREADS_TOKEN_ISSUED", f"{datetime.date.today():%Y-%m-%d}")
        log(f"[OK] 토큰 갱신 {mask(r['access_token'])}")
        return 0

    q = load_queue()
    item = pick_item(q)
    if item is None:
        log("[SKIP] 큐에 남은 글이 없습니다")
        return 0

    text = item["threads"]["text"]
    first_comment = item["threads"].get("first_comment", "")
    image_url = item["threads"].get("image_url", "")

    if a.dry_run:
        log(f"[DRY] 항목 {item['id']} · 주제 {item.get('topic', '')}")
        log(f"[DRY] 본문 {len(text)}자 / 한도 {MAX_TEXT}자")
        log(f"[DRY] 이미지 {image_url or '(없음)'}")
        log(f"[DRY] 첫 댓글 {first_comment or '(없음)'}")
        print("[DRY] ---- 본문 ----")
        print(text)
        print("[DRY] ---- 끝 ----")
        return 0

    if cfg.get("SNS_DAILY_ENABLED", "1") == "0":
        log("[SKIP] SNS_DAILY_ENABLED=0")
        return 0
    if not cfg.get("THREADS_ACCESS_TOKEN") or not cfg.get("THREADS_USER_ID"):
        log("[SKIP] 토큰/사용자ID 없음 — threads_token.py 를 먼저 실행하세요")
        return 3
    if item.get("status") == "publishing":
        log(f"[확인필요] {item['id']} 가 publishing 상태입니다. --resolve 로 정리한 뒤 다시 실행하세요")
        return 2
    if len(text) > MAX_TEXT:
        log(f"[실패] 본문이 {len(text)}자로 한도({MAX_TEXT})를 넘습니다. 문구를 줄여야 합니다")
        return 1
    if "http" in text:
        log("[실패] 본문에 링크가 있습니다. 링크는 첫 댓글에만 넣습니다")
        return 1

    maybe_refresh(cfg)
    token, uid = cfg["THREADS_ACCESS_TOKEN"], cfg["THREADS_USER_ID"]

    item["status"] = "publishing"
    item["attempt_at"] = f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}"
    save_queue(q)

    try:
        use_image = bool(image_url) and url_ok(image_url)
        if image_url and not use_image:
            log(f"[주의] 이미지 URL 응답 없음 → 텍스트로만 게시: {image_url}")
        cid = create_container(uid, token, "IMAGE" if use_image else "TEXT", text,
                               image_url if use_image else None)
        log(f"  컨테이너 {cid} ({'IMAGE' if use_image else 'TEXT'})")
        if use_image:
            wait_ready(cid, token)
        post_id = publish(uid, token, cid)
        log(f"[OK] 게시 완료 post_id={post_id}")

        reply_id = ""
        if first_comment:
            time.sleep(10)
            try:
                rcid = create_container(uid, token, "TEXT", first_comment)
                time.sleep(5)
                reply_id = publish(uid, token, rcid)
                log(f"[OK] 첫 댓글 reply_id={reply_id}")
            except RuntimeError as e:
                log(f"[주의] 첫 댓글 실패(본문은 게시됨): {e}")

        try:
            permalink = api_get(post_id, {"fields": "permalink", "access_token": token}).get("permalink", "")
        except RuntimeError:
            permalink = ""

        item.update({"status": "posted", "posted_at": f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}",
                     "post_id": post_id, "reply_id": reply_id, "permalink": permalink})
        save_queue(q)
        return 0
    except RuntimeError as e:
        item.update({"status": "error", "error": str(e)[:400]})
        save_queue(q)
        log(f"[실패] {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

### 3-6. 첫 댓글 규칙
- 본문에는 **링크를 넣지 않는다**(`http`가 있으면 스크립트가 거부한다). 이유: 본문에 링크가 있으면 노출이 줄고, 대표님이 정한 방식은 **공감을 끄는 본문 + 첫 댓글 링크**다(2026-11-21 확정).
- 첫 댓글은 **한 줄 소개 + 링크 1개**. 예: `여기서 지번 넣고 바로 볼 수 있습니다 → https://autooneclick.com/slope/`
- 댓글 문구는 큐의 `threads.first_comment`에 그대로 들어 있다. **댓글에도 원리 설명을 쓰지 않는다.**
- 댓글 발행이 실패해도 본문은 이미 올라간 상태다. **본문을 다시 올리지 않는다**(중복). 로그에 `첫 댓글 실패`만 남기고 사람이 손으로 단다.

### 3-7. 토큰 발급·갱신 — `tools/sns_auto/threads_token.py`
대표님이 Meta 화면에서 **코드 한 줄만 복사**해 넣으면 나머지를 자동 처리한다.
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""쓰레드 토큰 발급·갱신 — 대표님 1분 설정용
   py -3 threads_token.py --code "복사한코드"
   py -3 threads_token.py --refresh
"""
import argparse, datetime, json, os, sys, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

BASE = "https://graph.threads.net"
ENV = Path(__file__).resolve().parent / ".env.local"

def mask(t): return (t[:6] + "…" + t[-4:]) if t and len(t) > 12 else "(없음)"

def get_json(url):
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"[실패] HTTP {e.code} {e.read().decode('utf-8', 'replace')[:300]}")
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"[실패] 연결: {e.reason}")
        sys.exit(1)

def save_env(pairs: dict):
    lines = ENV.read_text(encoding="utf-8-sig").splitlines() if ENV.exists() else []
    out = []
    for raw in lines:
        k = raw.split("=", 1)[0].strip()
        out.append(raw if k not in pairs else f"{k}={pairs[k]}")
    have = {l.split("=", 1)[0].strip() for l in out if "=" in l}
    for k, v in pairs.items():
        if k not in have:
            out.append(f"{k}={v}")
    tmp = ENV.with_suffix(".tmp")
    tmp.write_text("\n".join(out) + "\n", encoding="utf-8")
    os.replace(tmp, ENV)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--code", help="승인 화면 주소창의 code= 값")
    ap.add_argument("--redirect-uri", default="https://localhost/")
    ap.add_argument("--refresh", action="store_true")
    a = ap.parse_args()

    if a.refresh:
        cur = {}
        for raw in (ENV.read_text(encoding="utf-8-sig").splitlines() if ENV.exists() else []):
            if "=" in raw:
                k, v = raw.split("=", 1)
                cur[k.strip()] = v.strip()
        tok = cur.get("THREADS_ACCESS_TOKEN", "")
        if not tok:
            print("[실패] .env.local 에 THREADS_ACCESS_TOKEN 이 없습니다.")
            return 1
        url = (f"{BASE}/refresh_access_token?" + urllib.parse.urlencode(
            {"grant_type": "th_refresh_token", "access_token": tok}))
        r = get_json(url)
        save_env({"THREADS_ACCESS_TOKEN": r["access_token"],
                  "THREADS_TOKEN_ISSUED": f"{datetime.date.today():%Y-%m-%d}"})
        print(f"[OK] 갱신 완료 {mask(r['access_token'])} · 앞으로 60일")
        return 0

    if not a.code:
        print("사용법: python threads_token.py --code \"승인 후 주소창의 code 값\"")
        print("   또는: python threads_token.py --refresh")
        return 1

    app_id = input("Meta 앱 ID(App ID)를 붙여넣고 Enter: ").strip()
    app_secret = input("Meta 앱 시크릿(App secret)을 붙여넣고 Enter: ").strip()
    if not app_id or not app_secret:
        print("[실패] 앱 ID/시크릿이 비었습니다.")
        return 1

    # 1) code → 단기 토큰
    body = urllib.parse.urlencode({"client_id": app_id, "client_secret": app_secret,
                                   "grant_type": "authorization_code",
                                   "redirect_uri": a.redirect_uri, "code": a.code.strip()}).encode()
    req = urllib.request.Request(f"{BASE}/oauth/access_token", data=body, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            short = json.loads(r.read().decode("utf-8"))["access_token"]
    except urllib.error.HTTPError as e:
        print(f"[실패] 코드 교환 HTTP {e.code} {e.read().decode('utf-8', 'replace')[:300]}")
        print("→ 코드는 한 번만 쓸 수 있고 10분 안에 써야 합니다. 승인 화면을 다시 열어 새 코드를 받으세요.")
        return 1
    print(f"[1/3] 단기 토큰 {mask(short)}")

    # 2) 단기 → 장기(60일)
    url = (f"{BASE}/access_token?" + urllib.parse.urlencode(
        {"grant_type": "th_exchange_token", "client_secret": app_secret, "access_token": short}))
    long_tok = get_json(url)["access_token"]
    print(f"[2/3] 장기 토큰 {mask(long_tok)} · 60일")

    # 3) 내 Threads 사용자 ID
    me = get_json(f"{BASE}/v1.0/me?" + urllib.parse.urlencode(
        {"fields": "id,username", "access_token": long_tok}))
    print(f"[3/3] 계정 @{me.get('username')} · id={me.get('id')}")

    save_env({"THREADS_ACCESS_TOKEN": long_tok, "THREADS_USER_ID": str(me["id"]),
              "THREADS_TOKEN_ISSUED": f"{datetime.date.today():%Y-%m-%d}"})
    print("[OK] .env.local 저장 완료. 이제 --dry-run 으로 확인하세요.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```
> 앱 시크릿은 **키보드 입력으로만** 받는다(파일·인자로 저장하지 않는다). 화면 표시도 `mask()`만.

### 3-8. 중복 방지 (가장 중요)
- **발행 직전에** 큐에 `publishing`을 적고 저장한다. 중간에 죽으면 다음 실행이 `publishing`을 보고 **아무것도 하지 않고 종료 2**로 멈춘다.
- 자동 재시도 금지. 같은 글을 두 번 올리는 사고가, 한 번 못 올리는 것보다 훨씬 나쁘다. **사람이 `--resolve` 로 풀어야** 다시 돈다.
- 실패 항목은 `status="error"` 로 남기고 다음 항목으로 넘어가지 않는다(순서가 꼬이면 무료 체험 안내 글이 엉뚱한 날 나간다). 보고서에 실패 사유를 적는다.

---

## 4. 스케줄 등록 — `register_sns_schedule.bat`

### 4-1. 등록 전 조건 (지키지 않으면 등록하지 않는다)
1. `tools/sns_auto/.env.local` 에 `THREADS_ACCESS_TOKEN`·`THREADS_USER_ID`·`NAVER_BLOG_ID` 가 있다
2. `threads_autopost.py --dry-run` 이 **종료 0**
3. `naver_blog_draft.py --dry-run` 이 **종료 0**

조건이 안 되면 `.bat` 파일만 만들고 **등록은 하지 않는다.** 결과 보고서에 "등록 명령"만 적어 대표님이 토큰 넣은 뒤 한 번 실행하게 한다.

### 4-2. `register_sns_schedule.bat` (내용 그대로)
```bat
@echo off
chcp 65001 >nul
setlocal
set "DIR=%~dp0"
set "PY=py -3"
where py >nul 2>nul || set "PY=python"

echo [1/2] 쓰레드 게시 작업 등록 (매일 08:10)
powershell -NoProfile -Command ^
  "$a=New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c \"%DIR%run_threads.bat\"' -WorkingDirectory '%DIR%';" ^
  "$t=New-ScheduledTaskTrigger -Daily -At 08:10;" ^
  "$s=New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 30);" ^
  "Register-ScheduledTask -TaskName 'KTS_SNS_THREADS' -Action $a -Trigger $t -Settings $s -Description 'KTS 쓰레드 하루 1건 자동 게시' -Force"

echo [2/2] 네이버 임시저장 작업 등록 (매일 08:20)
powershell -NoProfile -Command ^
  "$a=New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c \"%DIR%run_naver.bat\"' -WorkingDirectory '%DIR%';" ^
  "$t=New-ScheduledTaskTrigger -Daily -At 08:20;" ^
  "$s=New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 30);" ^
  "Register-ScheduledTask -TaskName 'KTS_SNS_NAVER' -Action $a -Trigger $t -Settings $s -Description 'KTS 네이버 블로그 임시저장' -Force"

echo.
echo 등록 결과:
schtasks /Query /TN "KTS_SNS_THREADS" /FO LIST | findstr /C:"작업 이름" /C:"Task Name" /C:"다음 실행" /C:"Next Run"
schtasks /Query /TN "KTS_SNS_NAVER"   /FO LIST | findstr /C:"작업 이름" /C:"Task Name" /C:"다음 실행" /C:"Next Run"
echo.
echo * StartWhenAvailable: PC가 꺼져 있어 못 돌린 날은 켜지면 곧바로 한 번 돌립니다.
echo * 시간 바꾸기: schtasks /Change /TN "KTS_SNS_THREADS" /ST 19:30
pause
```
- `run_threads.bat` / `run_naver.bat` (둘 다 같은 모양, 스크립트 이름만 다름):
```bat
@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist logs mkdir logs
py -3 threads_autopost.py >> logs\run_threads_%date:~0,4%%date:~5,2%%date:~8,2%.log 2>&1
exit /b %errorlevel%
```
- `unregister_sns_schedule.bat`: `schtasks /Delete /TN "KTS_SNS_THREADS" /F` + `schtasks /Delete /TN "KTS_SNS_NAVER" /F`
- **비상 정지**: `.env.local` 의 `SNS_DAILY_ENABLED=0` 한 줄이면 두 작업이 아무것도 하지 않고 끝난다(작업 삭제 없이 멈춤).

### 4-3. 등록 후 반드시 할 수동 1회 테스트
```powershell
tools\sns_auto\run_threads.bat
type tools\sns_auto\logs\threads_*.log
```
- 토큰이 없으면 `[SKIP] 토큰/사용자ID 없음 …` 로 끝나는 것이 **정상**이다(그 줄이 로그에 남는지 확인).
- **실제 게시는 대표님이 토큰을 넣은 뒤 첫 실행에서 일어난다.** 이번 회차에서는 발생하지 않아야 한다.

---

## 5. ② 네이버 블로그 자동 임시저장 — `tools/sns_auto/naver_blog_draft.py`

### 5-1. 왜 '완전 자동 발행'이 아니라 '임시저장'인가
네이버 블로그에는 **공식 글쓰기 API가 없다**(2024년 폐지). 그래서 브라우저를 직접 조작하는 방식뿐인데, 하루 1건씩 기계가 **발행**까지 하면 같은 IP·같은 시간대·같은 문체의 글이 반복돼 **저품질·차단** 위험이 커진다. 그래서 역할을 나눈다.
- **기계**: 제목·본문·사진·태그를 넣고 **`임시저장`까지만** 누른다.
- **대표님**: 알림을 보고 화면에서 **10초 안에 확인하고 `발행`** 을 누른다(문장 다듬기·사진 순서도 이때).
이 선은 이번 회차 설계 원칙이다. 코드에 `발행` 클릭 경로를 **아예 만들지 않는다**.

### 5-2. 크롬 준비 — 전용 로그인 창 (`start_sns_chrome.bat`)
**중요(2026년 크롬 기준):** 크롬 136부터 **기본 프로필 폴더로는 원격 디버깅 포트가 열리지 않는다**(쿠키 탈취 방지). 또 이미 켜져 있는 크롬은 새 옵션을 무시한다. 그래서 **전용 폴더 하나를 만들어 한 번만 네이버 로그인**해 두고 계속 그 창을 쓴다. (기본 프로필을 복사해 쓰는 방법은 암호화 키가 달라 로그인이 살아나지 않는다 — 하지 말 것.)
```bat
@echo off
chcp 65001 >nul
set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
set "PROFILE=%USERPROFILE%\KTS_SNS_CHROME"
if not exist "%PROFILE%" mkdir "%PROFILE%"
echo 전용 크롬을 엽니다. 이 창에서 네이버에 한 번만 로그인해 두세요.
start "" "%CHROME%" --remote-debugging-port=9222 --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check "https://blog.naver.com"
```
- 이 창에서 **대표님이 직접** 네이버 로그인(아이디·비밀번호는 **스크립트에 저장하지 않는다**). 로그인 상태는 `%USERPROFILE%\KTS_SNS_CHROME` 폴더에 남아 다음부터 자동.
- 로그인 확인: 이 창에서 `https://blog.naver.com/{블로그ID}` 가 내 블로그로 열리면 OK.
- **이 창을 닫으면 임시저장이 안 된다.** 스크립트가 못 붙으면 `[SKIP] 크롬 창이 없습니다 — start_sns_chrome.bat 을 먼저 실행하세요` 로 끝난다(종료 3).

### 5-3. CLI — **한 번에 10건을 채우는 일괄 모드가 기본** (대표님 지시)
```
py -3 tools\sns_auto\naver_blog_draft.py --list              # 블로그 큐 상태(대기/임시저장/발행)
py -3 tools\sns_auto\naver_blog_draft.py --dry-run           # 1건 본문을 화면에만 출력
py -3 tools\sns_auto\naver_blog_draft.py --live --count 10   # ★임시저장함에 10건을 한꺼번에 채운다(기본값 10)
py -3 tools\sns_auto\naver_blog_draft.py --live --count 1    # 1건만(스케줄러가 매일 부르는 형태)
py -3 tools\sns_auto\naver_blog_draft.py --probe             # 에디터 구조 덤프
```
- 대표님은 **임시저장함에 쌓인 글을 하루 1건씩 열어 확인하고 `발행`**만 누르면 된다(그때 뜨는 자동입력 방지 문자·봇 확인은 사람이 처리).
- 일괄 모드는 **한 건 끝나고 다음 건**으로 넘어간다(탭을 닫고 새로 연다). 건 사이 **20~40초** 쉰다. 10건이면 8~15분 걸린다.
- 중간에 실패하면 **거기서 멈춘다**(그 뒤 건은 다음 실행으로). 이미 `drafted` 된 건은 다시 만들지 않는다.
- 실행이 끝나면 `임시저장 N건 완료 · 실패 M건`을 로그 마지막 줄에 남긴다.

### 5-4. 흐름과 가드
1. `NAVER_BLOG_ID` 없으면 **종료 3**
2. CDP 확인: `http://127.0.0.1:9222/json/version` 응답 없으면 **종료 3**
3. `blog.status == "pending"` 첫 항목 선택. 없으면 **종료 0**
4. 새 탭에서 `https://blog.naver.com/{id}?Redirect=Write` 열기 → `#mainFrame` iframe 로드 대기
5. 팝업 정리: "작성 중인 글" → **취소**(새 글로 시작). 도움말 패널 닫기
6. 제목 입력 → 본문 문단 입력 → 사진 업로드(있으면) → 태그 입력
7. **`임시저장` 버튼만** 텍스트로 찾아 클릭. **아래 가드를 코드에 반드시 넣는다.**
   ```python
   ALLOW = ["임시저장"]
   FORBID = ["발행", "공개발행", "예약발행"]

   def click_by_text(frame, texts, forbid=FORBID):
       """프레임 안에서 '정확히 이 글자'인 보이는 요소를 눌러라. 금지어면 누르지 말고 예외."""
       for t in texts:
           if any(b in t for b in forbid):
               raise RuntimeError(f"금지 버튼 클릭 차단: {t}")
       hit = frame.evaluate(
           """(wanted) => {
                const els = [...document.querySelectorAll('button, a, span, div')];
                for (const el of els) {
                  if (!el.offsetParent) continue;
                  const t = (el.textContent || '').trim();
                  if (wanted.includes(t) && !el.querySelector('button, a')) {
                    el.click(); return t;
                  }
                }
                return null;
              }""", texts)
       if not hit:
           raise RuntimeError(f"버튼 못 찾음: {texts}")
       return hit
   ```
8. 저장 확인: 토스트/알림 텍스트(`저장`, `임시저장`) 확인 + **URL이 글쓰기 페이지 그대로인지 확인**. URL이 `PostView`로 바뀌었으면 **즉시 중단·스크린샷·종료 2** (발행되면 안 되는데 발행된 사고이므로 사람이 바로 알아야 한다).
9. 스크린샷 `logs/naver_YYYY-MM-DD_HHMM.png` 저장 → 큐 `blog.status="drafted"`, `drafted_at` 기록 → **종료 0**
10. 재실행 시 `drafted` 항목은 건너뛴다(**같은 날 두 번 임시저장하지 않는다** — 임시저장이 쌓이면 대표님이 헷갈린다).

### 5-5. 참조 구현 (Playwright + CDP)
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""네이버 블로그 임시저장 (발행 금지) — PC 크롬 전용 프로필에 CDP로 붙는다."""
import argparse, datetime, json, sys, time, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
ENV = ROOT / ".env.local"
LOGDIR = ROOT / "logs"
IMGDIR = ROOT / "images"
CDP = "http://127.0.0.1:9222"
FORBID = ["발행", "공개발행", "예약발행"]

def log(msg):
    LOGDIR.mkdir(exist_ok=True)
    line = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}"
    print(line)
    with open(LOGDIR / f"naver_{datetime.date.today():%Y-%m-%d}.log", "a", encoding="utf-8") as f:
        f.write(line + "\n")

def load_env():
    cfg = {}
    if ENV.exists():
        for raw in ENV.read_text(encoding="utf-8-sig").splitlines():
            s = raw.strip()
            if s and not s.startswith("#") and "=" in s:
                k, v = s.split("=", 1)
                cfg[k.strip()] = v.strip().strip('"').strip("'")
    return cfg

def cdp_alive():
    try:
        with urllib.request.urlopen(f"{CDP}/json/version", timeout=5) as r:
            return r.status == 200
    except Exception:
        return False

def load_queue(): return json.loads(QUEUE.read_text(encoding="utf-8"))
def save_queue(q):
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    tmp.replace(QUEUE)

def click_by_text(fl, texts, exact=True):
    for t in texts:
        if any(b in t for b in FORBID):
            raise RuntimeError(f"금지 버튼 클릭 차단: {t}")
    hit = fl.locator("body").evaluate(
        """([wanted, exact]) => {
             const els = [...document.querySelectorAll('button, a, span, div, li')];
             for (const el of els) {
               if (!el.offsetParent) continue;
               const t = (el.textContent || '').trim();
               const ok = exact ? wanted.includes(t) : wanted.some(w => t.includes(w));
               if (ok && !el.querySelector('button, a')) { el.click(); return t; }
             }
             return null;
           }""", [texts, exact])
    if not hit:
        raise RuntimeError(f"버튼 못 찾음: {texts}")
    return hit

def dump_buttons(fl, tag=""):
    """에디터 개편으로 셀렉터가 바뀌었을 때 원인을 찾는 진단용."""
    info = fl.locator("body").evaluate(
        """() => ({
             buttons: [...document.querySelectorAll('button')]
               .filter(b => b.offsetParent)
               .map(b => (b.className || '') + ' :: ' + (b.textContent || '').trim()).slice(0, 60),
             placeholders: [...document.querySelectorAll('[contenteditable="true"], input')]
               .filter(e => e.offsetParent)
               .map(e => (e.tagName + '.' + (e.className || '') + ' ph=' + (e.getAttribute('placeholder') || ''))).slice(0, 40)
           })""")
    log(f"[PROBE:{tag}] buttons={info['buttons']}")
    log(f"[PROBE:{tag}] inputs={info['placeholders']}")

def type_title(fl, title):
    for sel in (".se-title-text", ".se-documentTitle .se-text-paragraph", ".se-placeholder.__se_placeholder"):
        loc = fl.locator(sel).first
        if loc.count() and loc.is_visible():
            loc.click()
            fl.page.keyboard.type(title, delay=15) if hasattr(fl, "page") else None
            return sel
    raise RuntimeError("제목 칸을 못 찾음")

def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--list", action="store_true")
    g.add_argument("--dry-run", action="store_true")
    g.add_argument("--live", action="store_true")
    g.add_argument("--probe", action="store_true")
    a = ap.parse_args()

    cfg = load_env()
    q = load_queue()

    if a.list:
        for it in q["items"]:
            b = it.get("blog", {})
            log(f"{it['id']:<26} blog={b.get('status', 'pending'):<8} {b.get('title', '')[:40]}")
        return 0

    item = next((i for i in q["items"] if i.get("blog", {}).get("status", "pending") == "pending"), None)
    if item is None:
        log("[SKIP] 블로그 큐에 남은 글이 없습니다")
        return 0
    blog = item["blog"]

    if a.dry_run:
        log(f"[DRY] 항목 {item['id']} · 제목 {blog['title']}")
        log(f"[DRY] 태그 {', '.join(blog.get('tags', []))}")
        log(f"[DRY] 사진 {blog.get('images', [])}")
        print("[DRY] ---- 본문 ----")
        print(blog["body"])
        print("[DRY] ---- 끝 ----")
        return 0

    blog_id = cfg.get("NAVER_BLOG_ID", "")
    if not blog_id:
        log("[SKIP] NAVER_BLOG_ID 없음 (.env.local)")
        return 3
    if not cdp_alive():
        log("[SKIP] 크롬 창이 없습니다 — start_sns_chrome.bat 을 먼저 실행하세요")
        return 3

    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(CDP)
        ctx = browser.contexts[0]
        page = ctx.new_page()
        page.set_default_timeout(20000)
        try:
            page.goto(f"https://blog.naver.com/{blog_id}?Redirect=Write", wait_until="domcontentloaded")
            time.sleep(4)
            if "nid.naver.com" in page.url:
                log("[SKIP] 네이버 로그인이 풀렸습니다 — start_sns_chrome.bat 창에서 다시 로그인하세요")
                return 3

            frame = page.frame_locator("#mainFrame")
            frame.locator("body").wait_for(timeout=20000)

            # 팝업·도움말 정리
            for t in (["취소"], ["새로 작성"], ["확인"]):
                try:
                    click_by_text(frame, t)
                    time.sleep(1)
                except RuntimeError:
                    pass
            frame.locator("body").evaluate(
                """() => document.querySelectorAll('[class*="se-help"], [class*="help-panel"]')
                        .forEach(e => e.remove())""")

            title = blog["title"]
            body = blog["body"]

            if a.probe:
                dump_buttons(frame, "before")
                return 0

            # 제목
            title_sel = None
            for sel in (".se-title-text", ".se-documentTitle .se-text-paragraph"):
                loc = frame.locator(sel).first
                if loc.count() and loc.is_visible():
                    title_sel = sel
                    loc.click()
                    break
            if not title_sel:
                dump_buttons(frame, "title-fail")
                raise RuntimeError("제목 칸을 못 찾음 — --probe 로 구조 확인 필요")
            page.keyboard.type(title, delay=15)
            time.sleep(1)

            # 본문 (문단 단위로 Enter)
            body_loc = None
            for sel in (".se-content", ".se-component-content", "[contenteditable='true']"):
                loc = frame.locator(sel).first
                if loc.count() and loc.is_visible():
                    body_loc = loc
                    break
            if body_loc is None:
                dump_buttons(frame, "body-fail")
                raise RuntimeError("본문 칸을 못 찾음")
            body_loc.click()
            for block in [b for b in body.split("\n\n") if b.strip()]:
                for line in block.split("\n"):
                    page.keyboard.type(line, delay=8)
                    page.keyboard.press("Enter")
                    time.sleep(0.1)
                page.keyboard.press("Enter")
                time.sleep(0.15)
            time.sleep(2)

            # 사진
            for img in blog.get("images", [])[:3]:
                path = (IMGDIR / img).resolve() if not Path(img).is_absolute() else Path(img)
                if not path.exists():
                    log(f"[주의] 사진 없음, 건너뜀: {path}")
                    continue
                try:
                    frame.locator("input[type=file]").first.set_input_files(str(path))
                    time.sleep(6)
                except Exception as e:
                    log(f"[주의] 사진 업로드 실패({path.name}): {e}")

            # 태그
            for tag in blog.get("tags", [])[:12]:
                try:
                    tagbox = frame.locator("input[placeholder*='태그']").first
                    if tagbox.count():
                        tagbox.click()
                        page.keyboard.type(tag, delay=10)
                        page.keyboard.press("Enter")
                        time.sleep(0.3)
                except Exception:
                    pass

            # 임시저장 (발행 금지)
            clicked = click_by_text(frame, ["임시저장"])
            log(f"클릭: {clicked}")
            time.sleep(4)

            if "PostView" in page.url or "Redirect=Write" not in page.url and "blog.naver.com" in page.url and "postwrite" not in page.url.lower():
                LOGDIR.mkdir(exist_ok=True)
                shot = LOGDIR / f"naver_ALERT_{datetime.datetime.now():%Y%m%d_%H%M}.png"
                page.screenshot(path=str(shot), full_page=True)
                log(f"[확인필요] 글쓰기 화면을 벗어났습니다(발행 의심). 스크린샷 {shot}")
                return 2

            LOGDIR.mkdir(exist_ok=True)
            shot = LOGDIR / f"naver_{datetime.datetime.now():%Y%m%d_%H%M}.png"
            page.screenshot(path=str(shot), full_page=False)
            log(f"[OK] 임시저장 완료 · 스크린샷 {shot}")

            blog["status"] = "drafted"
            blog["drafted_at"] = f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}"
            save_queue(q)
            return 0
        except Exception as e:
            LOGDIR.mkdir(exist_ok=True)
            try:
                page.screenshot(path=str(LOGDIR / f"naver_ERR_{datetime.datetime.now():%Y%m%d_%H%M}.png"))
            except Exception:
                pass
            log(f"[실패] {e}")
            return 1
        finally:
            try:
                page.close()
            except Exception:
                pass

if __name__ == "__main__":
    sys.exit(main())
```
### 5-5b. 일괄(10건) 모드 + 본문 속 사진 자리 처리
위 코드는 **1건 처리**다. 일괄은 그 처리를 반복하면 된다. 핵심 두 가지만 추가한다.

**(1) 본문에 `[사진1]`·`[사진2]`·`[사진3]` 줄이 있으면 그 자리에서 사진을 넣는다.**
큐의 원고는 장문이고, 사진을 글 중간에 넣어야 읽힌다. 본문을 사진 표시로 잘라 순서대로 처리한다.
```python
def split_by_photo(body: str):
    """본문을 [(타입, 값)] 로 자른다. 타입은 'text' 또는 'photo'."""
    import re
    parts, last = [], 0
    for m in re.finditer(r"^\[사진(\d)\]\s*$", body, flags=re.M):
        if body[last:m.start()].strip():
            parts.append(("text", body[last:m.start()]))
        parts.append(("photo", int(m.group(1))))
        last = m.end()
    if body[last:].strip():
        parts.append(("text", body[last:]))
    return parts
```
입력 루프는 이렇게 바뀐다(사진은 현재 커서 위치에 들어간다).
```python
for kind, val in split_by_photo(body):
    if kind == "text":
        for block in [b for b in val.split("\n\n") if b.strip()]:
            for line in block.split("\n"):
                page.keyboard.type(line, delay=8)
                page.keyboard.press("Enter")
            page.keyboard.press("Enter")
            time.sleep(0.15)
    else:
        img = blog.get("images", [])[val - 1] if len(blog.get("images", [])) >= val else None
        path = (IMGDIR / img) if img else None
        if path and path.exists():
            frame.locator("input[type=file]").first.set_input_files(str(path))
            time.sleep(6)
        else:
            log(f"[주의] [사진{val}] 파일 없음 — 자리만 건너뜀")
```

**(2) 여러 건 반복**
```python
def pending_items(q, n):
    out = []
    for it in q["items"]:
        if it.get("blog", {}).get("status", "pending") == "pending":
            out.append(it)
        if len(out) >= n:
            break
    return out

# main 안에서
items = pending_items(q, a.count)
ok = fail = 0
for it in items:
    code = do_one(page, it)          # 위 1건 로직을 함수로 빼서 호출
    if code == 0:
        ok += 1
    else:
        fail += 1
        break                        # 실패하면 멈춘다(뒤 건은 다음 실행)
    time.sleep(30)                   # 건 사이 20~40초
log(f"임시저장 {ok}건 완료 · 실패 {fail}건")
```
- **같은 글을 두 번 임시저장하지 않는다.** `blog.status`를 `drafted`로 바꾼 뒤에만 다음 건으로 넘어간다.
- 네이버 화면이 느려 밀리면 `time.sleep`을 늘린다. **빨리 끝내는 것보다 10건이 다 들어가는 게 목적**이다.

> **셀렉터는 살아 있는 화면에서 확인하며 맞춘다.** 위 값은 2026년 11월 기준 알려진 구조다. 빠르게 확인하는 방법: `--probe` 로 `[PROBE]` 줄을 보고, 제목·본문·임시저장 요소의 실제 클래스/문구를 맞춘다. **화면에 보이는 글자('임시저장')로 찾는 방식이 클래스명보다 오래 간다**(에디터는 개편 때마다 클래스에 해시를 붙인다).
- 글자 입력이 너무 느리면 `delay=8`을 `4`로 낮춘다. 너무 빠르면 에디터가 글자를 흘리므로 **한 줄씩 넣고 `time.sleep(0.1)`** 을 유지한다.
- 사진은 **최대 3장**만 넣는다(많으면 저장이 느리고 실패 지점이 늘어난다).

### 5-6. 실패했을 때 (그대로 보고, 억지로 우회하지 않는다)
| 증상 | 처리 |
|---|---|
| `크롬 창이 없습니다` | `start_sns_chrome.bat` 실행 안내 → 종료 3 |
| `로그인이 풀렸습니다` | 그 창에서 대표님이 1회 로그인 → 종료 3 |
| `제목/본문 칸을 못 찾음` | `--probe` 덤프를 로그에 남기고 종료 1. **추측으로 좌표 클릭(마우스 매크로) 금지** |
| `임시저장 버튼 못 찾음` | 덤프 + 스크린샷 남기고 종료 1. 발행 버튼을 대신 누르지 않는다 |
| 캡차·추가 인증 | **멈추고** 스크린샷만 남긴다(사람이 처리) |
- **자동 재시도는 1회만**(3분 뒤). 그 뒤에도 실패하면 그날은 비운다. 같은 글을 여러 번 임시저장하면 대표님이 어느 것이 최종인지 헷갈린다.

---

---

## 6. ③ 초기 콘텐츠 큐 — 10건 장문 원고 `tools/sns_auto/post_queue.json`

> **이 파일은 이미 저장소에 넣어 두었다**(`tools/sns_auto/post_queue.json`, 10건 · 약 20KB). 그대로 쓰면 된다. 아래는 그 내용과 **문체 규칙**이다.

### 6-1. 문체 3단 구조 (대표님 확립 — 쓰레드·블로그·자동 생성기 모두 공통)
1. **① 상황·공감으로 선입견 깨기** — 첫마디는 상품 소개가 아니라 **독자가 이미 겪고 있는 장면**. "무료로 쓰세요"로 시작하면 바로 아웃된다. 그 사람이 **좋아할 상황**을 먼저 만들어 준다.
2. **② 과장 없는 사실·구체적 수치·현장 스토리로 신뢰** — 같이 느낄 수 있는 설명과 사실적인 얘기. 숫자는 확인된 것만. 감탄·아부·"최고/유일/보장" 금지.
3. **③ 자연스러운 행동** — 신뢰가 생긴 뒤에야 링크·문의로 진도. 링크는 **쓰레드 본문 0 / 첫 댓글 1**, 블로그는 글 끝에 1회.
- **원리 비공개**: 어떻게 만들었는지, 어떤 계산·알고리즘인지 쓰지 않는다. 손님이 겪는 일과 눈에 보이는 결과만.
- 순서를 바꾸면(③을 ①에 붙이면) 글 전체가 광고로 읽힌다. **이 순서가 이 문서에서 가장 중요한 규칙**이다.

### 6-2. 저장된 10건 (그대로 사용)
| order | id | 주제 | 쓰레드 훅 | 블로그 원고 | 사진 자리 |
|---|---|---|---|---|---|
| 1 | `2026-11-23_slope` | 토지정보(경사도) | 113자 | 1,909자 | 3 |
| 2 | `2026-11-24_doksim` | 독심술 v2 | 96자 | 1,491자 | 3 |
| 3 | `2026-11-25_viewer` | 더뷰 | 105자 | 1,422자 | 3 |
| 4 | `2026-11-26_sign` | 더싸인 | 98자 | 1,442자 | 3 |
| 5 | `2026-11-27_thescan` | 더스캔 | 104자 | 1,399자 | 3 |
| 6 | `2026-11-28_realty` | 매물수집기 | 92자 | 1,344자 | 3 |
| 7 | `2026-11-29_bungee` | 번개알바 | 110자 | 1,408자 | 3 |
| 8 | `2026-11-30_redev` | 재개발 진행조회기 | 94자 | 1,415자 | 3 |
| 9 | `2026-12-01_hogang` | 호갱 탈출 내비 | 113자 | 1,465자 | 3 |
| 10 | `2026-12-02_converter` | 원클릭 변환기 | 121자 | 1,287자 | 3 |

- **문구를 임의로 고치지 않는다**(원칙 검수를 통과한 글이다). 오탈자만 고친다. 고칠 때도 §6-1의 3단 구조를 유지한다.
- `order` 순서대로 하루 1건씩 나간다. 10일이면 한 바퀴다.
- 파일 형식(그대로 유지):
```json
{
  "id": "2026-11-23_slope", "order": 1, "topic": "토지정보(경사도)", "status": "pending",
  "product_key": "slope",
  "threads": { "text": "2~3줄 훅", "image_url": "https://autooneclick.com/shots/…png", "first_comment": "링크 1개" },
  "blog": { "status": "pending", "title": "…", "body": "…[사진1]…", "tags": ["…"], "images": ["slope_1.png","slope_2.png","slope_3.png"] },
  "notes": "…"
}
```
- `threads.status`와 `blog.status`는 따로 관리한다(쓰레드만 실패해도 블로그는 나가야 한다).

### 6-3. 쓰레드 훅 규칙 (짧게)
- **2~3줄 / 100~200자.** 그 이상은 읽히지 않는다.
- 1줄: 상황(선입견 깨기) · 2줄: 사실 한 줄 · 3줄: "링크는 댓글" 또는 이어지는 한 줄.
- 숫자는 1개 이하로. 여러 개 넣으면 훅이 아니라 스펙이 된다.
- 좋은 예: `서류 5장을 사진 5장으로 보내면, 받는 쪽은 순서부터 다시 맞춥니다. / 종이에 폰만 대고 찍으면 펴고 그림자 지운 채로 저장됩니다. / 찍은 것들은 한 권 PDF로 묶입니다. (링크는 댓글)`

### 6-4. 블로그 원고 규칙 (길고 완성도 높게 — 대표님 지시)
- **1,300자 이상**(10건 평균 약 1,450자). 짧은 광고글이 아니라 **읽고 저장하는 글**로 쓴다.
- 반드시 들어갈 것:
  1. **현장 사례** — 실제로 겪는 장면(계약서 앞, 대리점 계산기, 아침 매물 문자 등). 가정이면 "예를 들어"로 시작해 가정임을 밝힌다.
  2. **구체적 수치** — 5m 격자·5도 구간, 15/18/21mm, 96만 원÷24개월=4만 원, 1,000㎡=40칸처럼 **계산이 맞는 숫자**만. 계산값은 "계산값"이라고 밝힌다.
  3. **실물 사진 3장 자리** — 본문에 `[사진1]`·`[사진2]`·`[사진3]` 줄. 실제 이미지는 §6-5에서 채운다.
  4. **한계·주의 문단** — 참고값임을 밝히고, 법적 판단은 공부·측량·고시 기준이라고 적는다. 이 문단이 신뢰를 만든다.
  5. **글 끝 링크 1회** + 가격·무료 조건(쇼룸에 적힌 그대로).
- 금지: 원리·알고리즘 설명, 확인 안 된 후기·매출·"1위", 다른 상표 비교, 개인정보.
- 태그는 10~14개. 지역·상황·증상 단어를 섞는다(예: `한글파일열기`, `폰hwp`, `견적서확인`).

### 6-5. 실물 사진 준비 (`images/`)
1. PC에서 `start_sns_chrome.bat` 창을 띄우고, 각 상품 페이지를 연다.
2. 아래 세 장을 찍어 `tools/sns_auto/images/` 에 저장한다(창 폭 1200px 기준).
   - `{key}_1.png` — 첫 화면(상단)
   - `{key}_2.png` — 실제 결과 화면(입력 후 결과가 보이는 상태)
   - `{key}_3.png` — 표·요약·버튼 등 핵심 부분 확대
3. 파일명은 큐의 `blog.images` 와 정확히 맞춘다(`slope_1.png` …).
4. **개인정보 가리기**: 이름·전화번호·주소가 찍히면 모자이크/자르기 후 저장한다.
5. 사진이 없으면 `[사진N]` 자리는 건너뛰고 글로만 올라간다(실패 아님, 로그에 남김).

### 6-6. 큐 운영
- 쓰레드: `pending` 첫 항목 → 발행 → `posted`. 블로그: `pending` → 임시저장 → `drafted` → (대표님 발행) → 보고서에만 기록.
- 10건이 소진되면 `[SKIP] 큐에 남은 글이 없습니다`로 끝난다. **지니가 다음 10편을 채워 넣는다**(PC가 임의로 새 글을 지어내지 않는다).
- 큐를 새로 채울 때는 §6-7·§6-8 생성기를 쓰고, 생성된 글은 **사람이 한 번 읽고** `status`를 `pending`으로 둔다.

### 6-7. 상품별 자동 생성기 — `tools/sns_auto/build_product_posts.py` (대표님 추가 지시)
**무엇을 하나**: `oneclick` 의 상품 목록(`https://autooneclick.com/catalog.json`, 라이브 200 확인)을 읽어, **상품마다 블로그 상세 원고 + 쓰레드 훅**을 만들어 `post_queue.json` 뒤에 **추가**한다. 이미 있는 상품은 건너뛴다(중복 금지). 새 상품이 쇼룸에 등록되면 이 스크립트를 한 번 돌리면 글이 생긴다.
- 실물 캡처가 없으면 `--capture` 로 상품 페이지를 찍어 `images/{key}_1~3.png` 를 만든다(Playwright, CDP 크롬 재사용).
- **문체 규칙은 §6-1 그대로**: 상황·공감 → 사실·수치 → 행동. 스펙 나열 금지.
- 상품별 '상황 첫마디'는 `SITUATION` 표에 있다. 새 상품은 **표에 한 줄 추가**하면 문체가 유지된다(표에 없으면 일반 문장으로 대체되고 `notes`에 `상황문장 없음`을 남긴다).
- 수치는 **catalog.json에 있는 값만** 쓴다(가격·무료 조건·기능 목록). 없는 수치를 만들지 않는다.
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""상품별 상세 글 생성기 — catalog.json → 블로그 원고 + 쓰레드 훅 → post_queue.json
   py -3 build_product_posts.py --list
   py -3 build_product_posts.py --add          # 새 상품만 추가
   py -3 build_product_posts.py --update       # pending 글 문구만 최신 정보로 갱신
   py -3 build_product_posts.py --capture      # 상품 페이지 실물 캡처(images/)
"""
import argparse, datetime, json, re, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
IMGDIR = ROOT / "images"
CATALOG = "https://autooneclick.com/catalog.json"
SITE = "https://autooneclick.com/"

# ① 상황 첫마디 — 상품 key 별. 새 상품은 여기에 한 줄 추가한다.
SITUATION = {
    "sale": "장 볼 때마다 '여기가 싼가' 싶어서 몇 집을 돌아다닌 적 있습니다.",
    "photo2doc": "거래명세표 사진을 받고 엑셀로 다시 타이핑하다가 마지막에 합계가 안 맞았습니다.",
    "theform": "관공서 양식을 받아 놓고 어디에 무엇을 써야 하는지 몰라 한참 멈춘 적 있습니다.",
    "contract": "계약서를 급하게 써야 해서 예전 문서를 복사했는데, 남의 주소가 그대로 남아 있었습니다.",
    "thedetail": "매물 사진은 많은데 손님께 보여 줄 한 장이 없어서 결국 전화로 설명했습니다.",
    "viewer": "카톡으로 온 한글파일이 폰에서 안 열려서 '집 가서 볼게요' 하고 넘긴 적 있습니다.",
    "loan": "자금이 필요한데 어디에 넣어야 할지 몰라 은행만 세 번 바꿔 갔습니다.",
    "tax": "돈은 필요한데 순서를 몰라 통장부터 만들다가 꼬인 적이 있습니다.",
    "navi": "답장이 짧아졌다고 화난 걸로 단정했다가, 그냥 바빴다는 걸 나중에 알았습니다.",
    "saycap": "사진은 많은데 그 사진을 다시 찾으려면 갤러리를 한참 넘겨야 합니다.",
    "organizer": "앱이 백 개가 되니 홈 화면에서 필요한 걸 못 찾겠습니다.",
    "keyword": "검색창에 무슨 단어를 쳐야 할지 몰라 고민만 하다 끝난 적 있습니다.",
    "sign": "서명 한 장 때문에 프린터 있는 곳을 찾아다닌 적 있습니다.",
    "tongyeok": "외국인 손님 앞에서 말이 막혀 손짓만 했습니다.",
    "realty": "아침에 온 매물 문자 20건 중 절반은 광고였습니다.",
    "slope": "땅 보러 갔는데 '경사가 좀 있다'는 말만 듣고 왔습니다.",
    "commerce": "상품 하나 올리려는데 제목·상세·엑셀을 각각 따로 만들어야 했습니다.",
    "redev": "'곧 될 겁니다'만 듣고 계약했다가 몇 년을 기다린 이야기를 주변에서 봤습니다.",
    "gagebu": "이번 달에 얼마 썼는지 물으면 답을 못 합니다.",
    "hogang": "대리점에서 '이게 제일 싸다'고 해서 바꿨는데, 집에 와서도 확신이 없었습니다.",
    "golf": "영상은 봤는데 내 자세가 뭐가 틀렸는지 몰라 그대로 쳤습니다.",
    "petmind": "강아지가 자꾸 같은 행동을 해서 혼냈는데, 나중에 뜻이 달랐습니다.",
}
FALLBACK = "{nm}이(가) 필요한 순간은 대개 일이 막혔을 때입니다. 검색해 보고, 앱을 깔고, 결국 다시 원래대로 돌아옵니다."
STOP = ["최고", "1위", "유일", "보장", "완벽", "혁명"]

def fetch_catalog():
    with urllib.request.urlopen(CATALOG, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))

def load_queue():
    return json.loads(QUEUE.read_text(encoding="utf-8")) if QUEUE.exists() else {"version": 2, "items": []}

def save_queue(q):
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    tmp.replace(QUEUE)

def make_hook(p):
    sit = SITUATION.get(p["k"]) or FALLBACK.format(nm=p["nm"])
    fact = (p.get("line") or p.get("sub") or "").strip().rstrip(".")
    return f"{sit}\n{fact}.\n바로 써볼 수 있습니다. (링크는 댓글)"

def make_blog(p):
    nm, sub = p["nm"], p.get("sub", "")
    sit = SITUATION.get(p["k"]) or FALLBACK.format(nm=nm)
    how = p.get("how") or []
    bullets = p.get("bullets") or []
    notes = p.get("notes") or []
    price, price2 = p.get("price", ""), p.get("price2", "")
    link = SITE + (p.get("link") or "")

    lines = [f"■ {sit}", 
             "그때 필요한 건 설명이 아니라 화면 하나입니다. 이 글에서는 무엇을 어떻게 확인하는지 순서대로 적었습니다.", "",
             f"■ {nm}가 하는 일", p.get("blurb", ""), "", "[사진1]", "",
             "■ 쓰는 순서"]
    for i, h in enumerate(how, 1):
        lines.append(f"{i}. {h}")
    lines += ["", "■ 한눈에 보는 항목"]
    for b in bullets:
        if isinstance(b, list) and len(b) >= 2:
            lines.append(f"- {b[0]}: {b[1]}")
    lines += ["", "[사진2]", "", "■ 실제로 이렇게 씁니다",
              "급할 때 열어 보고, 결과를 그대로 저장하거나 보내는 식으로 씁니다. 한 번 써 두면 다음부터는 검색하지 않게 됩니다.",
              "", "[사진3]", "", "■ 주의"]
    for n in notes:
        lines.append(f"- {n}")
    lines += ["- 화면에 나오는 값은 참고용입니다. 법적 판단·계약은 공부(등기·대장)와 원본 서류를 기준으로 하세요.",
              "", "■ 비용", f"{price}" + (f" / {price2}" if price2 else ""), "", link]

    body = "\n".join([l for l in lines if l is not None]).strip()
    for w in STOP:
        body = body.replace(w, "")
    title = f"{nm}, 이럴 때 이렇게 씁니다 — {sub}" if sub else f"{nm} 쓰는 방법"
    tags = [nm.replace(" ", ""), p.get("cat", ""), "무료", "사용법", "정리", "업무", "생활", "초보"] + \
           [b[0] for b in bullets if isinstance(b, list)][:4]
    return title, body, [t for t in dict.fromkeys([x for x in tags if x])][:14]

def make_item(p, order):
    title, body, tags = make_blog(p)
    key = p["k"]
    return {
        "id": f"{datetime.date.today():%Y-%m-%d}_{key}", "order": order, "topic": p["nm"],
        "status": "pending", "product_key": key,
        "threads": {"text": make_hook(p),
                    "image_url": (SITE + p["shot"]) if p.get("shot") else "",
                    "first_comment": f"{p['nm']} 바로 써보기 → {SITE}{p.get('link', '')}"},
        "blog": {"status": "pending", "title": title, "body": body, "tags": tags,
                 "images": [f"{key}_1.png", f"{key}_2.png", f"{key}_3.png"]},
        "notes": ("상황문장 없음(일반 문장 사용) " if key not in SITUATION else "") +
                 "자동 생성 — 발행 전 사람이 한 번 읽고 다듬기",
    }

def capture(p, cdp="http://127.0.0.1:9222"):
    from playwright.sync_api import sync_playwright
    IMGDIR.mkdir(exist_ok=True)
    with sync_playwright() as pw:
        b = pw.chromium.connect_over_cdp(cdp)
        page = b.contexts[0].new_page(viewport={"width": 1200, "height": 900})
        page.goto(SITE + (p.get("link") or ""), wait_until="networkidle", timeout=45000)
        time_sleep = __import__("time").sleep
        time_sleep(2)
        page.screenshot(path=str(IMGDIR / f"{p['k']}_1.png"))
        page.mouse.wheel(0, 900); time_sleep(1)
        page.screenshot(path=str(IMGDIR / f"{p['k']}_2.png"))
        page.mouse.wheel(0, 900); time_sleep(1)
        page.screenshot(path=str(IMGDIR / f"{p['k']}_3.png"))
        page.close()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--add", action="store_true")
    ap.add_argument("--update", action="store_true")
    ap.add_argument("--capture", action="store_true")
    ap.add_argument("--only", help="상품 key 하나만")
    a = ap.parse_args()

    cat = fetch_catalog()
    prods = [p for p in cat["products"] if p.get("status") == "live" and p.get("link")]
    if a.only:
        prods = [p for p in prods if p["k"] == a.only]
    q = load_queue()
    have = {it.get("product_key") for it in q["items"] if it.get("product_key")}

    if a.list:
        for p in prods:
            print(f"{p['k']:<14}{p['nm']:<18}{'있음' if p['k'] in have else '없음'}")
        return 0

    if a.capture:
        for p in prods:
            try:
                capture(p)
                print(f"[OK] 캡처 {p['k']}")
            except Exception as e:
                print(f"[실패] {p['k']}: {e}")
        return 0

    added = 0
    for p in prods:
        if p["k"] in have and not a.update:
            continue
        if p["k"] in have and a.update:
            for it in q["items"]:
                if it.get("product_key") == p["k"] and it.get("status") == "pending":
                    it.update(make_item(p, it["order"]))
                    print(f"[UPDATE] {p['k']}")
            continue
        order = max([it.get("order", 0) for it in q["items"]] or [0]) + 1
        q["items"].append(make_item(p, order))
        added += 1
        print(f"[ADD] {p['k']} → order {order}")
    q["updated"] = f"{datetime.date.today()}"
    save_queue(q)
    print(f"완료: 추가 {added}건 · 전체 {len(q['items'])}건")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
```
- **한 번에 다 넣지 않는다.** `--add` 로 추가한 뒤 `status`는 `pending` 이지만, **발행 순서는 사람이 정한다**(`order` 조정). 자동 생성 글은 원고 초안이므로 대표님이 발행 전 한 번 읽는다.
- 자동 생성 글은 **10건 큐 뒤에 붙는다**(먼저 손으로 쓴 10편이 나간 뒤).

### 6-8. 부동산 매물 포스팅 생성기 — `tools/sns_auto/build_realestate_posts.py` (대표님 추가 지시)
**무엇을 하나**: 대표님이 정리한 매물 데이터(`tools/sns_auto/data/listings.json`)를 읽어 **네이버 블로그용 상세 매물 글**(검색 키워드 태그 · 수치 요약 · 사진 자리)을 만들어 `post_queue.json` 의 `blog` 큐에 넣는다. 쓰레드 훅도 함께 만든다(본문 링크 0).

**입력 데이터 형식** (`data/listings.json`) — 이 형식만 지키면 글이 나온다:
```json
{
  "listings": [
    {
      "id": "sinhari-01",
      "region": "경기도 가평군 조종면 신하리",
      "jibun": "산 103-4",
      "kind": "임야·전원주택 부지",
      "area_pyeong": 300,
      "area_m2": 991,
      "price_krw": 300000000,
      "loan_krw": 80000000,
      "exchange_want": ["수도권 아파트", "상가", "현금 일부"],
      "features": ["도로 접함", "전기 인입", "남향", "계곡 인접"],
      "photos": ["sinhari_1.jpg", "sinhari_2.jpg", "sinhari_3.jpg"],
      "price_public": true,
      "note": "교환·매매 모두 가능"
    }
  ]
}
```
- `equity`(에쿼티)는 **매매가 − 대출**로 스크립트가 계산한다. 데이터에 없어도 된다(직접 넣으면 그 값을 우선).
- `price_public: false` 면 **금액을 쓰지 않고** "가격·조건은 문의"로 생성한다(공개하면 안 되는 물건 보호).

**글 구조(§6-1 3단)**:
1. **① 상황** — "현금 없이 집을 바꾸려는 사람이 가장 먼저 막히는 지점"부터 시작한다. 매물 소개로 시작하지 않는다.
2. **② 사실** — 수치 요약(매매가·대출·에쿼티·평당·면적) + 특징 + 교환 조건. 전부 계산값/입력값이라 정확하다.
3. **③ 행동** — 확인해야 할 서류(등기부·토지대장·건축물대장·토지이용계획확인원)와 문의 한 줄.
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""부동산 매물 → 네이버 블로그 상세 글 + 쓰레드 훅 → post_queue.json
   py -3 build_realestate_posts.py --list
   py -3 build_realestate_posts.py --add
"""
import argparse, datetime, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
DATA = ROOT / "data" / "listings.json"
ENV = ROOT / ".env.local"

def won(n):
    n = int(n or 0)
    eok, man = divmod(n, 100000000)
    man //= 10000
    out = []
    if eok:
        out.append(f"{eok}억")
    if man:
        out.append(f"{man:,}만")
    return " ".join(out) or "0"

def load_env():
    cfg = {}
    if ENV.exists():
        for raw in ENV.read_text(encoding="utf-8-sig").splitlines():
            if "=" in raw and not raw.strip().startswith("#"):
                k, v = raw.split("=", 1)
                cfg[k.strip()] = v.strip()
    return cfg

def load_queue():
    return json.loads(QUEUE.read_text(encoding="utf-8")) if QUEUE.exists() else {"version": 2, "items": []}

def save_queue(q):
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    tmp.replace(QUEUE)

def area_line(L):
    py, m2 = L.get("area_pyeong"), L.get("area_m2")
    if py and m2:
        return f"{py:,}평(약 {m2:,}㎡)"
    if py:
        return f"{py:,}평(약 {round(py * 3.3058):,}㎡)"
    return f"{m2:,}㎡" if m2 else "면적 미기재"

def money_block(L):
    if not L.get("price_public", True):
        return ["- 매매가: 문의", "- 대출·에쿼티: 문의", "- 교환 조건: 문의"]
    price, loan = int(L.get("price_krw") or 0), int(L.get("loan_krw") or 0)
    equity = int(L.get("equity_krw") or (price - loan))
    out = [f"- 매매가: {won(price)} 원", f"- 대출: {won(loan)} 원(승계 가능 여부 확인)",
           f"- 에쿼티(매매가−대출): {won(equity)} 원"]
    if L.get("area_pyeong"):
        out.append(f"- 평당: 약 {round(price / L['area_pyeong'] / 10000):,}만 원(계산값)")
    return out

def make_blog(L):
    where = f"{L.get('region', '')} {L.get('jibun', '')}".strip()
    kind = L.get("kind", "매물")
    title = f"{where} {area_line(L)} {kind} — 교환 매물 정리"
    if L.get("price_public", True) and L.get("price_krw"):
        title += f" (매가 {won(L['price_krw'])})"

    lines = [
        "■ 현금이 없어서 막히는 자리",
        "집을 바꾸고 싶은데 지금 집이 안 팔리면, 다음 집을 볼 수도 없습니다. 대출 한도는 줄고, 기다리는 동안 시세는 움직입니다.",
        "그래서 요즘은 '팔고 사는' 대신 '바꾸는' 쪽을 먼저 봅니다. 교환은 상대가 원하는 것과 내가 가진 것이 맞아야 성립하므로, 조건을 숫자로 정리해 두는 것이 먼저입니다.",
        "", f"■ {where} {area_line(L)} {kind}", "", "[사진1]", "",
        "■ 숫자로 보는 조건", *money_block(L), "",
        "■ 이 땅(물건)의 특징",
    ]
    for f in L.get("features", []) or ["특징 미기재"]:
        lines.append(f"- {f}")
    lines += ["", "[사진2]", "", "■ 교환 희망 조건",
              "- " + (", ".join(L.get("exchange_want", [])) if L.get("exchange_want") else "협의 가능")]
    if L.get("note"):
        lines += ["", "■ 참고", f"- {L['note']}"]
    lines += [
        "", "■ 계약 전에 확인할 서류",
        "- 등기부등본(근저당·가압류)",
        "- 토지대장·건축물대장(지목·면적·구조)",
        "- 토지이용계획확인원(용도지역·규제)",
        "- 실제 경계(측량 필요 시 비용·기간 확인)",
        "", "[사진3]", "",
        "■ 문의",
        "교환·매매 조건은 상대에 따라 달라집니다. 보고 계신 조건과 맞는지 편하게 문의 주세요.",
    ]
    contact = load_env().get("CONTACT_PHONE", "")
    if contact:
        lines.append(f"연락처: {contact}")
    return title, "\n".join(lines)

def make_item(L, order):
    title, body = make_blog(L)
    where = f"{L.get('region', '')} {L.get('jibun', '')}".strip()
    hook = (f"집을 바꾸고 싶은데 지금 집이 안 팔려서 다음 집을 못 보고 있습니다.\n"
            f"{where} {area_line(L)} {L.get('kind', '')} — 교환 조건을 숫자로 정리해 뒀습니다.\n"
            f"조건은 댓글에 적어 두었습니다.")
    return {
        "id": f"{datetime.date.today():%Y-%m-%d}_{L['id']}", "order": order,
        "topic": f"매물 {where}", "status": "pending", "product_key": f"listing:{L['id']}",
        "threads": {"text": hook, "image_url": "",
                    "first_comment": "매물 상세와 조건 → https://autooneclick.com/exchange/"},
        "blog": {"status": "pending", "title": title, "body": body,
                 "tags": [w for w in [L.get("region", "").split()[-1] if L.get("region") else "",
                                      L.get("kind", ""), "교환매물", "급매", "토지", "부동산",
                                      f"{L.get('area_pyeong', '')}평" if L.get("area_pyeong") else ""] if w][:12],
                 "images": L.get("photos", [])[:3]},
        "notes": "매물 자동 생성 — 금액·조건은 대표님 입력값. 발행 전 확인 필수",
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--add", action="store_true")
    a = ap.parse_args()
    if not DATA.exists():
        print(f"[안내] 매물 데이터가 없습니다: {DATA}")
        print("       위 형식(data/listings.json)으로 대표님이 정리한 매물을 넣고 다시 실행하세요.")
        return 3
    data = json.loads(DATA.read_text(encoding="utf-8"))
    Ls = data.get("listings", []) or data.get("items", [])
    q = load_queue()
    if a.list:
        have0 = {it.get("product_key") for it in q["items"]}
        for L in Ls:
            mark = "있음" if f"listing:{L['id']}" in have0 else "없음"
            print(f"{L['id']:<18}{mark}")
        return 0
    have = {it.get("product_key") for it in q["items"]}
    added = 0
    for L in Ls:
        key = f"listing:{L['id']}"
        if key in have:
            continue
        order = max([it.get("order", 0) for it in q["items"]] or [0]) + 1
        q["items"].append(make_item(L, order))
        added += 1
        print(f"[ADD] {L['id']} → order {order}")
    save_queue(q)
    print(f"완료: 추가 {added}건 · 전체 {len(q['items'])}건")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
```
- **법적 표시**: 중개사가 광고하는 매물이면 **중개사무소 명칭·등록번호·보증보험 가입 여부**를 글에 넣어야 한다(공인중개사법 광고 규정). 대표님이 중개사가 아니면 "교환·매매 중개 의뢰" 문구 대신 **당사자 간 거래**임을 밝힌다. 이 판단은 대표님 몫이므로 **생성기는 그 문구를 넣지 않고, `notes`에 `표시광고 확인 필요`를 남긴다**.
- 매물 글은 **쓰레드 본문에 금액을 넣지 않는다**(훅은 상황·지역·면적까지만, 링크는 댓글). 개인정보·정확 주소 노출은 `region`/`jibun` 수준에서 그친다.
- 사진은 `images/` 에 실제 파일이 있어야 들어간다. 없으면 `[사진N]` 자리를 건너뛴다.

---

## 7. ④ 1분 설정 가이드 — `tools/sns_auto/README_설정가이드.md`

> 아래 내용을 **그대로 저장**한다. 그림 없이, 대표님이 처음 보는 사람 기준으로 쓴 글이다.

```markdown
# 쓰레드·블로그 자동 올리기 — 처음 설정 10분

이 문서만 따라 하면 내일 아침부터 자동으로 올라갑니다.
준비물: ① 쓰레드(인스타) 계정 ② 네이버 블로그 ③ 이 PC의 크롬.

---

## 1단계. 쓰레드 토큰 받기 (5분 · 한 번만)

1. 인터넷 창에서 `developers.facebook.com` 을 엽니다. 페이스북 계정으로 로그인합니다.
2. 오른쪽 위 **내 앱** → **앱 만들기**를 누릅니다.
3. 앱 이름을 아무거나 적습니다(예: `KTS 글자동`). 사용 사례를 고르라고 하면 **Threads API**가 있는 항목을 고릅니다. 없으면 **기타**로 만들고 다음 화면에서 추가합니다.
4. 앱 화면 왼쪽에서 **제품 추가** → **Threads API** 를 찾아 **설정**을 누릅니다.
5. **역할(Roles) → Threads 테스터 추가**에서 **내 쓰레드 사용자 이름**을 넣고 추가합니다.
6. 폰의 **쓰레드 앱 → 설정 → 계정 → 웹사이트 권한 → 초대**에 들어가 **수락**을 누릅니다. (이 단계를 빠뜨리면 3번에서 막힙니다.)
7. 앱 화면의 **앱 설정 → 기본**에서 두 가지를 메모합니다.
   - **앱 ID** (숫자)
   - **앱 시크릿** (영문·숫자 섞인 긴 문자열, `보기`를 눌러야 보입니다)
8. 같은 화면의 **Threads API 설정**에서 **리디렉션 URI** 칸에 아래를 넣고 저장합니다.
   `https://localhost/`
9. 아래 주소를 브라우저에 붙여 넣고, 권한 화면에서 **허용**을 누릅니다. (앱 ID 부분만 7번 값으로 바꿉니다)
   `https://threads.net/oauth/authorize?client_id=내앱ID&redirect_uri=https://localhost/&scope=threads_basic,threads_content_publish,threads_manage_replies&response_type=code`
10. 허용하면 주소창이 `https://localhost/?code=AQ...` 처럼 바뀝니다(화면은 하얗게 나옵니다 — 정상입니다).
    **주소창의 `code=` 뒤부터 `#` 앞까지**를 통째로 복사합니다.
11. 이 폴더에서 `threads_token.bat` 을 실행하고, 물어보면 **앱 ID → 앱 시크릿 → 복사한 code** 순서로 붙여 넣습니다.
    마지막에 `[OK] .env.local 저장 완료` 가 나오면 끝입니다.
    - `code`는 **한 번만** 쓸 수 있고 **10분** 안에 써야 합니다. 실패하면 9번부터 다시 하세요.
    - 토큰은 **60일**짜리입니다. 45일이 지나면 자동으로 갱신됩니다. `threads_token.bat` 을 다시 실행해 `--refresh` 를 골라도 됩니다.

---

## 2단계. 네이버 블로그 연결 (3분 · 한 번만)

1. `start_sns_chrome.bat` 을 두 번 누릅니다. **전용 크롬 창**이 하나 열립니다(평소 쓰는 크롬과 따로입니다).
2. 그 창에서 `blog.naver.com` 으로 들어가 **네이버에 로그인**합니다.
   - 아이디·비밀번호는 **어디에도 저장하지 않습니다.** 이 창에만 남습니다.
   - `로그인 상태 유지`가 있으면 체크해 두세요.
3. 내 블로그 주소를 확인합니다. 주소가 `blog.naver.com/abcd1234` 이면 **`abcd1234`** 가 블로그 아이디입니다.
4. 이 폴더의 `.env.local` 을 메모장으로 열어 아래 한 줄을 채웁니다.
   `NAVER_BLOG_ID=abcd1234`
5. **이 크롬 창은 닫지 마세요.** 닫으면 자동 임시저장이 안 됩니다. (PC를 끄면 다시 켜고 이 파일을 한 번 실행하면 됩니다.)

---

## 3단계. 글 10편 미리 채우기 (1번만 · 10~15분)

1. `run_naver.bat` 을 두 번 누릅니다(또는 아래 명령).
   `py -3 naver_blog_draft.py --live --count 10`
2. 크롬 창이 스스로 움직이며 블로그 **임시저장함**에 글을 하나씩 넣습니다. **발행은 하지 않습니다.**
3. 끝나면 로그에 `임시저장 10건 완료` 가 찍힙니다.
4. 네이버 블로그 → **글쓰기 → 임시저장** 목록에서 10편을 확인합니다. 사진이 빠진 글이 있으면 그 글만 손으로 사진을 넣습니다.

> 처음 한 번만 하면 됩니다. 이후로는 **하루 1편씩 새 글이 자동으로 채워집니다**(대표님이 1편 발행하면 다음 날 1편이 새로 채워지는 구조).

---

## 4단계. 자동 시작 걸기 (30초)

1. `register_sns_schedule.bat` 을 두 번 누릅니다.
2. `다음 실행` 날짜가 보이면 성공입니다.
   - 쓰레드: **매일 08:10**
   - 네이버 임시저장: **매일 08:20**
3. PC가 꺼져 있어 못 돌린 날은 **PC를 켜면 곧바로 한 번** 돌아갑니다.
4. 시간을 바꾸고 싶으면:
   `schtasks /Change /TN "KTS_SNS_THREADS" /ST 19:30`

---

## 매일 하실 일 (3분)

1. 아침에 폰으로 **네이버 블로그 앱 → 임시저장**을 엽니다.
2. 맨 위 글을 읽고, 필요하면 문장 하나만 고칩니다.
3. **발행**을 누릅니다. (자동입력 방지 문자가 뜨면 그 자리에서 입력하시면 됩니다.)
4. 쓰레드는 **이미 올라가 있습니다.** 댓글에 링크가 달렸는지 한 번만 봐 주세요.

이게 전부입니다. 글 소재와 원고는 미리 10편이 쌓여 있고, 떨어지면 다시 채우면 됩니다.

---

## 잘 안 될 때

| 화면에 이렇게 나오면 | 뜻 | 이렇게 하세요 |
|---|---|---|
| `[SKIP] 토큰/사용자ID 없음` | 1단계를 안 했거나 토큰이 지났습니다 | `threads_token.bat` 다시 실행 |
| `[SKIP] 크롬 창이 없습니다` | 전용 크롬이 꺼졌습니다 | `start_sns_chrome.bat` 실행 후 다시 |
| `[SKIP] 네이버 로그인이 풀렸습니다` | 네이버가 로그아웃됐습니다 | 그 크롬 창에서 다시 로그인 |
| `[확인필요]` | 글이 두 번 올라갈 수 있는 상태 | 손대지 말고 지니에게 알려 주세요 |
| `[SKIP] 큐에 남은 글이 없습니다` | 10편을 다 썼습니다 | 지니에게 "글 더 채워줘" |

## 멈추고 싶을 때

- **잠깐 멈춤**: `.env.local` 에 `SNS_DAILY_ENABLED=0` 한 줄을 넣습니다. (다시 하려면 `1`)
- **완전히 끄기**: `unregister_sns_schedule.bat` 실행.
- **비밀번호·토큰이 걱정될 때**: `.env.local` 파일을 지우면 자동 게시가 즉시 멈춥니다. Meta 화면에서 토큰도 폐기할 수 있습니다.
```

---

## 8. ⑤ 검증과 보고

### 8-1. 검증 명령 (전부 통과해야 한다)
```powershell
cd tools\sns_auto
py -3 -m py_compile threads_autopost.py threads_token.py naver_blog_draft.py build_product_posts.py build_realestate_posts.py
py -3 -c "import json;d=json.load(open('post_queue.json',encoding='utf-8'));print('items',len(d['items']))"
py -3 threads_autopost.py --list
py -3 threads_autopost.py --dry-run
py -3 naver_blog_draft.py --dry-run
py -3 build_product_posts.py --list
```
| 검사 | 합격 기준 |
|---|---|
| 문법 | 5개 파일 모두 오류 0 |
| 큐 | `items 10` 이상, 모든 `threads.text` ≤500자·`http` 없음·3줄 이내 |
| 쓰레드 드라이런 | `[DRY]` 로 시작하는 줄과 본문이 출력되고 **네트워크 요청 0건**, 종료 0 |
| 블로그 드라이런 | 제목·본문·태그가 출력되고 종료 0 |
| 비밀값 | `git status` 에 `.env.local`·`logs/`·`images/` 가 **안 보임** |
| 실제 게시 | **0건**(로그에 `게시 완료` 없음) |

### 8-2. 결과 보고서 `CLAUDE_RESULT_20261122_SNS_AUTO.md` (이 형식으로)
```
# 2026-11-22 쓰레드·블로그 자동화 결과
## 1. 만든 파일 (경로·크기·역할)
## 2. 검증 결과 (8-1 표 그대로, 명령 출력 원문 붙임)
## 3. 드라이런 출력 원문 (쓰레드 1건 · 블로그 1건)
## 4. 하지 않은 것 (실제 게시 0건 · 네이버 발행 0건 · 스케줄 등록 여부)
## 5. 대표님이 하실 일 (3단계, 걸리는 시간)
## 6. 실패·막힌 것 (원문 그대로, 우회했으면 무엇을 어떻게)
## 7. 남은 위험 (토큰 60일, 에디터 개편, 저품질, 임시저장 10건 보관)
## 8. 되돌리기 (파일 삭제 목록 · 스케줄 해제 명령)
```
- **지어내지 않는다.** 라이브가 아직 안 떴으면 "안 떴다"고 쓴다. 실제로 게시하지 않았으면 "0건"이라고 쓴다.

### 8-3. 보고 후 하지 말 것
- **첫 실제 게시를 대신 눌러 주지 않는다.** 토큰은 대표님이 넣고, 첫 실행은 대표님이 확인한 뒤다.
- 스케줄은 §4-1 조건(토큰·블로그ID·드라이런 통과)을 **모두** 만족할 때만 등록한다. 아니면 `.bat`만 만들고 **등록 명령을 보고서에 적는다**.

---

## 9. 대표님이 내일 아침 하실 일 (총 15분)

1. **쓰레드 토큰** — `README_설정가이드.md` 1단계(5분). `threads_token.bat` 실행해 code 넣기.
2. **네이버 로그인** — `start_sns_chrome.bat` 열고 로그인, `.env.local` 에 `NAVER_BLOG_ID` 한 줄.
3. **글 10편 채우기** — `run_naver.bat` (또는 `--count 10`). 10~15분 뒤 임시저장함 확인.
4. **자동 시작** — `register_sns_schedule.bat`.
5. 그다음부터는 **매일 아침 임시저장 1편 발행 + 쓰레드 댓글 확인**만.

---

## 10. 부록

### 10-1. Threads API 오류 대응
| 코드/메시지 | 뜻 | 조치 |
|---|---|---|
| `190` / `Invalid OAuth access token` | 토큰 만료·오류 | `threads_token.bat` 재실행 |
| `36000` / `The requested resource does not exist` | 컨테이너 만료(24시간) 또는 잘못된 id | 새로 컨테이너 생성 |
| `4` / `Application request limit reached` | 호출 한도 | 1시간 뒤 재시도(우리는 하루 1건이라 거의 없음) |
| `100` / `Invalid parameter` | 500자 초과·이미지 URL 형식 오류 | 본문 길이·URL 확인 |
| `throttled` / 게시 한도 | 24시간 250건 초과 | 중단(정상 사용에선 불가능) |

### 10-2. 참고 링크 (확인한 문서)
- Threads API 개요·한도·이미지 규격: https://developers.facebook.com/docs/threads/overview/
- 장기 토큰(60일) 교환·갱신: https://developers.facebook.com/docs/threads/get-started/long-lived-tokens/
- 게시 문제 해결(컨테이너 상태): https://developers.facebook.com/docs/threads/troubleshooting/
- 크롬 136 원격 디버깅 변경: https://developer.chrome.com/blog/remote-debugging-port

### 10-3. 되돌리기
```powershell
schtasks /Delete /TN "KTS_SNS_THREADS" /F
schtasks /Delete /TN "KTS_SNS_NAVER" /F
git rm -r --cached tools/sns_auto   # (필요 시) 저장소에서만 제거
```
- `.env.local` 삭제 = 자동 게시 즉시 정지. 네이버 임시저장 글은 블로그 화면에서 직접 삭제.
- 되돌리기 전에 `git rev-parse HEAD` 값을 보고서에 적어 둔다.

### 10-4. 이번 회차에서 **일부러 하지 않은 것** (대표님 판단 필요)
1. **쓰레드 실제 게시** — 토큰이 없어 불가. 토큰 입력 후 첫 실행에서 일어난다.
2. **네이버 자동 발행** — 저품질·차단 위험. 임시저장까지만. (설계 원칙)
3. **이미지 자동 생성** — 실물 캡처가 원칙. 없는 상품은 텍스트로 먼저 올라간다.
4. **스케줄 등록** — 조건 충족 시에만. 아니면 명령만 남긴다.
5. **매물 글 자동 발행** — `listings.json` 형식으로 대표님이 정리한 매물만. 표시광고(중개사 명칭·등록번호)는 대표님 확인 후.

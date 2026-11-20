# PC 클로드 코드 작업 지시서 — 2026-11-20 (113번 · 더뷰 구형 `.hwp` PC 변환 서버 연결)

> 발령: 2026-11-20 23:4x · 사령관 지니 → PC 클로드 코드
> 대표님 적립메모 **113번**: "`더뷰` 구형 `.hwp` PC 한컴 변환 서버 연결 — 사무실 PC(`DESKTOP-02`) 변환 서버 + Cloudflare 무료 HTTPS 터널 연결 → 구형 `.hwp` 1:1 인화식 열람"
> 결과 보고서: **`CLAUDE_RESULT_20261120_HWP.md`** (작업 후 `git add → commit → push`)
> 저장소 2개: ① `K0612766940K-`(이 지시서·결과) ② `oneclick`(실서비스 autooneclick.com)

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 하지 않는 것 (하나라도 어기면 그 항목은 실패로 기록)
1. **제0원칙** — 이 지시서가 지정한 것 외에는 **틀·색감·기능·문구를 일절 바꾸지 않는다.** `viewer.html`의 다른 형식(hwpx·xlsx·docx·pdf·사진) 처리 코드는 **한 줄도 건드리지 않는다.**
2. **새 상품을 만들지 않는다.** 쇼룸 등록·상품 문구·가격 변경 없음.
3. 외부 발송(문자·메일·SNS)·결제·스토어 업로드·유료 API **0건**.
4. **관문 6** — 대표님 직접 시연 통과 전 대외 판매·광고·문자 발송 금지.
5. **비밀값 커밋 금지** — `oneclick` 저장소는 공개다. 토큰·인증서·개인 경로(`C:\Users\...`)·PC 이름을 커밋하지 않는다.
6. **되돌릴 수 있게** — 손대기 전 각 저장소의 `git rev-parse HEAD`를 적어 두고 보고서 ④에 넣는다.
7. **실패는 그대로 보고** — 어떤 명령이 어떤 오류 메시지로 막혔는지 원문 그대로. 추측으로 넘어가지 않는다.

### 이번 회차 결과물 (한 문장)
**폰에서 구형 `.hwp`를 열면, 사무실 PC의 한컴오피스가 PDF로 바꿔 돌려주고, 더뷰가 그 PDF를 종이 1:1로 그린다. PC가 꺼져 있으면 지금의 안내 카드가 그대로 뜬다.**

---

## 1. 0단계 — 지금 상태 확인 (10분)

### 1-1. 두 저장소 위치
```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull; git rev-parse HEAD

$base = "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실"
$oc = Get-ChildItem $base -Directory | Where-Object { Test-Path (Join-Path $_.FullName '.git\config') } |
      Where-Object { (Get-Content (Join-Path $_.FullName '.git\config') -Raw) -match 'kim779944-max/oneclick\.git' } |
      Select-Object -First 1 -ExpandProperty FullName
if (-not $oc) { git clone https://github.com/kim779944-max/oneclick.git (Join-Path $base 'oneclick'); $oc = Join-Path $base 'oneclick' }
cd $oc; git pull; git rev-parse HEAD
```

### 1-2. 한컴오피스가 이 PC에서 실제로 변환되는지 (가장 중요 — 여기서 막히면 나머지는 의미 없음)
```powershell
# ① 한글 설치 확인
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
  ForEach-Object { $_.GetValue('DisplayName') } | Where-Object { $_ -match '한글|Hangeul|HWP' }

# ② COM 오토메이션 확인 (창 없이 PDF로 저장되는지)
$h = New-Object -ComObject HWPFrame.HwpObject
$h.RegisterModule("FilePathCheckDLL","FilePathCheckerModule")   # 보안 승인창 회피용 모듈
$h.Open("C:\Windows\Temp\kts_test.hwp")                          # 아무 .hwp 하나 준비
$h.SaveAs("C:\Windows\Temp\kts_test.pdf", "PDF", "")
$h.Quit()
Test-Path C:\Windows\Temp\kts_test.pdf
```
- `False` 또는 예외가 나오면 **§2-B(대체 경로)** 로 간다. 추측으로 넘어가지 말고 오류 원문을 보고서에 적는다.
- 보안 승인창이 떠서 멈추면: 한글 → 도구 → 환경설정 → 보안 → "파일 경로 접근 차단 해제" 또는 `FilePathCheckerModule` 등록(`regsvr32`).

---

## 2. 과업 — 세 덩어리

### A. PC 변환 서버 (`DESKTOP-02` 안에서만 도는 프로그램)

**위치**: `K0612766940K-` 저장소에 `hwp-server/` 폴더로 넣는다(코드는 공개돼도 무방 — 비밀값 없음).

**요구사항 (전부 지킬 것)**
| 항목 | 규칙 |
|---|---|
| 포트 | `127.0.0.1:8799` 에만 바인딩 (외부 직접 노출 금지 — 터널로만 나간다) |
| 엔드포인트 | `GET /health` → `{"ok":true,"ver":"1.0"}` / `POST /convert` (multipart 또는 `application/octet-stream` + `X-KTS-Name`) |
| 받는 것 | `.hwp` `*.hwpx` **만**. 확장자·매직바이트 둘 다 확인. 그 외 415 |
| 크기 제한 | 20MB 초과 413 |
| 처리 | 임시폴더에 저장 → 한글 COM `Open` → `SaveAs PDF` → PDF 바이트를 응답 → **임시파일 즉시 삭제**(finally) |
| 타임아웃 | 45초. 넘으면 한글 `Quit()` 강제 종료 후 504 |
| 동시 실행 | **1건**. 이미 변환 중이면 429 + `Retry-After: 5` (한글 COM은 동시 호출에 취약) |
| CORS | `Access-Control-Allow-Origin: https://autooneclick.com` **만**. `OPTIONS` 프리플라이트 응답 |
| 레이트리밋 | IP당 10초에 1건 (초과 429) |
| 로그 | 파일명·바이트 수·소요시간만. **문서 내용·문서 이름 원문은 남기지 않는다**(이름은 해시) |
| 안전장치 | `hwp-server/OFF` 파일이 있으면 모든 요청 503 (대표님이 즉시 끌 수 있는 스위치) |
| 시작/종료 | `start-hwp-server.ps1` / `stop-hwp-server.ps1` (작업 스케줄러 등록은 하지 않는다 — 켜고 끄는 것은 대표님 몫) |

- 구현 언어는 PowerShell + `System.Net.HttpListener` 또는 Node 중 **이 PC에서 실제로 도는 쪽**으로. 새 유료 의존성 금지.
- 한글 COM은 STA 스레드에서만 안정적이다. PowerShell이면 `-STA`로 띄운다.

### B. 대체 경로 (한글 COM이 막힐 때만)
1. LibreOffice(`soffice --headless --convert-to pdf`)로 시도 → `.hwp`가 깨지면 실패로 기록.
2. 둘 다 안 되면 **서버를 만들지 말고**, 더뷰에는 지금의 안내 카드만 남긴 채 "왜 막혔는지"를 보고서에 적는다. **억지 우회 금지.**

### C. 무료 HTTPS 터널 (Cloudflare)
```powershell
winget install --id Cloudflare.cloudflared -e
cloudflared tunnel --url http://127.0.0.1:8799
```
- 출력되는 `https://<무작위>.trycloudflare.com` 주소를 **`oneclick/hwp-host.json`** 에 적고 커밋한다(주소는 매번 바뀐다 → 서버 시작 스크립트가 자동으로 갱신·커밋하도록 만든다):
```json
{ "url": "https://<무작위>.trycloudflare.com", "ver": "1.0", "at": "2026-11-20T23:50:00+09:00" }
```
- **인증키는 넣지 않는다**(공개 저장소). 대신 A의 CORS·레이트리밋·크기제한·OFF 스위치로 막는다.
- `start-hwp-server.ps1` 순서: ① 서버 기동 → ② `/health` 확인 → ③ 터널 기동 → ④ 새 주소를 `hwp-host.json`에 쓰고 `git commit -m "chore(hwp): 터널 주소 갱신" → git push` → ⑤ 창 유지.

### D. 더뷰(`oneclick/viewer.html`) — 구형 `.hwp`만 연결
- 지금: `.hwp` → `{kind:'notice'}` 안내 카드.
- 바꿀 것: `.hwp`를 고르면 **① `../hwp-host.json`을 읽어 `url`을 얻고 ② `fetch(url + '/convert')`로 파일을 보내 PDF를 받아 ③ 지금 있는 PDF 그리는 함수(`buildPdf`)로 그대로 그린다.**
  - 실패(PC 꺼짐·404·타임아웃 10초·CORS)하면 **지금의 안내 카드를 그대로** 띄운다. 카드 문구는 바꾸지 않는다.
  - 진행 표시: 로더 문구를 `'구형 한글 → PDF로 바꾸는 중… (사무실 PC)'` 로 1줄 추가.
  - 안내 카드 아래에 작은 버튼 하나: `[사무실 PC로 변환 다시 시도]`.
  - **개인정보 1줄 고지**(카드 안, 기존 문구 아래): `구형 .hwp는 사무실 PC에서 PDF로 바꿉니다. 파일은 그 PC를 거쳐 이 기기로 돌아오고 저장되지 않습니다.`
  - 다른 형식의 처리 분기·CSS·문구는 **무변경**.

---

## 3. 검수 (스스로 통과 못 하면 보고 금지)

| # | 확인 | 방법(결정론) | 판정 기준 |
|---|---|---|---|
| 1 | 서버 기동·정지 | `start` → `curl http://127.0.0.1:8799/health` → `stop` | `{"ok":true}` |
| 2 | 실제 변환 | 1쪽짜리 `.hwp` 1개 + 30쪽짜리 1개를 POST | 둘 다 PDF 반환, 첫 쪽 텍스트가 원본과 같다(육안 1:1 대조 캡처) |
| 3 | 잘못된 입력 | `.exe`·`.hwp` 아닌 것·21MB 파일 | 415 / 413 / 429, 서버 안 죽음 |
| 4 | 동시 요청 | 2건 동시 POST | 1건 변환 + 1건 429 |
| 5 | OFF 스위치 | `hwp-server/OFF` 만들고 POST | 503 |
| 6 | 터널 | 폰(모바일 데이터)에서 `https://<주소>/health` | `{"ok":true}` |
| 7 | 더뷰 성공 | 라이브 `https://autooneclick.com/viewer.html`에서 구형 `.hwp` | 종이 1:1로 그려짐, 콘솔 에러 0 |
| 8 | 더뷰 실패(PC 끔) | 서버 끄고 같은 파일 | 지금과 같은 안내 카드, 에러로 멈추지 않음 |
| 9 | 390px | 390×844 실측 | 가로 잘림 0, 스크롤폭=390, 콘솔·pageerror 0 |
| 10 | 게이트 | `python3 output/kts_gate.py <oneclick>/viewer.html` | exit 0 |
| 11 | 제0원칙 | `git diff --stat` | `viewer.html` 변경이 `.hwp` 분기+카드 1줄+CSS 2줄 이내, 다른 파일 무변경 |

---

## 4. 보고서 형식 (`CLAUDE_RESULT_20261120_HWP.md`)
1. **결론 3줄** — 됐다/안 됐다를 첫 줄에.
2. **관문표** — 위 11항목 각 PASS/FAIL + 근거 숫자·명령 출력·캡처 경로.
3. **증거** — `curl` 출력 원문, 변환 전/후 캡처, `hwp-host.json` 커밋 해시, 두 저장소 `HEAD` 해시.
4. **못 한 것 / 남은 위험** — PC가 꺼져 있으면 안 된다는 점, trycloudflare 주소가 매번 바뀐다는 점, 한글 COM 보안 승인창.
5. **대표님 결정 1건** — 지금 막는 것 하나만.

---

## 5. 이어서 하기 (재시도 규칙)
자동 실행기가 이 지시서를 여러 번 실행할 수 있다. 다시 시작하면 **이미 끝난 항목은 건너뛰고** 남은 것만 한다. 결과 보고서 마지막 줄에 `남은 것: …`을 적어 다음 실행이 이어받게 한다.

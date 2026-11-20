# CLAUDE_RESULT_20261120_HWP — 113번 · 더뷰 구형 `.hwp` PC 한컴 변환 서버 연결

## 1. 결론 3줄
1. **됐다.** 라이브 `https://autooneclick.com/viewer.html`에서 구형 `.hwp`(1쪽 계약서 양식·30쪽 시험 문서)를 열면 사무실 PC 한컴오피스 2024가 PDF로 바꾸고 더뷰가 종이 1:1로 그렸습니다(4~5초, 콘솔 에러 0).
2. PC 서버·터널을 끄면 **기존 안내 카드가 그대로** 뜹니다(0.3~0.6초, 멈춤 없음). 카드에는 개인정보 고지 1줄과 `[사무실 PC로 변환 다시 시도]` 버튼만 더했습니다.
3. 검수 11개 중 **PASS 9 · 부분 2**: #6은 폰 모바일 데이터 실측을 못 해서 PC→Cloudflare 경유로만 확인했고, #10은 `kts_gate.py`가 없어 PowerShell 이식판으로 돌렸습니다. **서버는 지금 꺼져 있습니다**(켜고 끄는 것은 대표님 몫이라서).

## 2. 관문표

| # | 확인 | 판정 | 근거 |
|---|---|---|---|
| 1 | 서버 기동·정지 | **PASS** | `start-hwp-server.ps1` → `curl 127.0.0.1:8799/health` = `{"ok":true,"ver":"1.0"}` → `stop` = "꺼졌습니다." |
| 2 | 실제 변환 1쪽+30쪽 | **PASS** | 1쪽 `200 77630B 3.4~3.9s`(첫 기동은 8.3s) · 30쪽 `200 26394B 2.75s X-KTS-Pages: 30`. 첫 쪽 텍스트가 원본과 같음: 30쪽은 PDF 1쪽 텍스트 `KTS 변환 시험 문서 - 1 쪽 / 30 쪽 . 가나다라마바사 ABC 123.` = 원본, 1쪽 계약서는 제1~8조 문구가 원본 `GetTextFile`과 같음. 캡처 `output/hwp_20261120/shots/live_on_1.png`, `live_on_2.png`, 원본 `orig_t30_p1.png` |
| 3 | 잘못된 입력 | **PASS** | `.exe`→415 · 내용은 exe인데 이름만 `.hwp`→415 · `.txt` 이름→415 · 21MB `.hwp`→413 · 같은 IP 10초 안 재요청→429(`Retry-After: 10`). 시험 뒤 `/health` 200(서버 살아 있음) |
| 4 | 동시 요청 | **PASS** | 2건 동시 POST → `A 200 / B 429`, `Retry-After: 5` |
| 5 | OFF 스위치 | **PASS** | `hwp-server/OFF` 생성 → POST 503 `{"ok":false,"err":"off"}`, `/health`도 503. 지우면 200 |
| 6 | 터널 | **부분** | `https://pursue-griffin-massage-kentucky.trycloudflare.com/health` → OK(PC→Cloudflare 엣지 경유), 라이브 더뷰(외부 오리진)에서 변환까지 성공. **폰 모바일 데이터 실측은 못 했음** → 대표님 시연 때 확인 필요 |
| 7 | 더뷰 성공 | **PASS** | 라이브 사이트 390×844 헤드리스 크롬: 로더 `구형 한글 → PDF로 바꾸는 중… (사무실 PC)` 표시 → `kind:pdf`, 1쪽=1페이지·30쪽=30페이지, `errs:[]` |
| 8 | 더뷰 실패(PC 끔) | **PASS** | 서버만 끔(터널 502): 564ms 뒤 안내 카드 · 서버+터널 끔: 293ms 뒤 안내 카드. h3 문구 그대로, `errs:[]`. 캡처 `live_off_server_1.png`, `live_off_all_1.png` |
| 9 | 390px | **PASS** | 4개 경우 모두 `scrollWidth=390 / innerWidth=390`, pageerror·console.error 0 |
| 10 | 게이트 | **부분** | `kts_gate.py`가 이 PC·저장소에 없고 python도 없음(`python3` = WindowsApps 스텁, exit 49). 같은 G1 정적 검사를 PowerShell로 이식한 `output/hwp_20261120/src/gate_viewer.ps1`을 변경 전(b932497)·후에 같이 돌림 → **새로 생긴 FAIL 0, exit 0**. 변경 전부터 있던 FAIL 2건(G1-6 연락처 2, G1-8 `sms:010…` 링크)은 그대로 둠(제0원칙) |
| 11 | 제0원칙 | **PASS(주의)** | 내 커밋의 변경 파일은 `viewer.html`(+28 −2), `hwp-host.json`(신규)뿐. 내용: CSS 1줄, 카드 고지 1줄 + 다시 시도 버튼 1줄, `.hwp` 분기 5줄, 버튼 연결 2줄, 변환 함수 `hwpViaPc` 17줄. 다른 형식 분기·CSS·문구는 손대지 않음. "분기+카드 1줄+CSS 2줄 이내"보다는 큼: 변환 함수를 분기 안에 끼워 넣지 않고 따로 뺐기 때문 |

추가 확인(지시서 요구 항목)
- **45초 타임아웃 → 504**: 시험용 `-TimeoutSec 1`로 확인. `504 1.29s`, 그 변환이 띄운 한글 프로세스만 종료(`killed=1`), 대표님이 열어 둔 한글 창(`빈 문서 1`)은 그대로, 직후 `/health` 200(39ms). 처음 구현은 504가 31초 뒤에 나가서 "응답 먼저 → 비동기 정리" 순서로 고쳤음.
- **임시파일**: 모든 시험 뒤 `%TEMP%\kts-hwp-server` 잔여 0.
- **로그**: 문서 이름 원문 0건(이름은 SHA-256 앞 12자리), 바이트·쪽수·ms만.
- **CORS**: `OPTIONS` → 204 + `Access-Control-Allow-Origin: https://autooneclick.com` 하나만.

## 3. 증거

### 저장소 HEAD (되돌리기용)
| 저장소 | 손대기 전 | 이번 커밋 |
|---|---|---|
| `K0612766940K-` | `2805cab08edf0859a2749b2006aa0124f4b8f507` | 이 보고서 커밋(`git log -1`) |
| `oneclick` | `b9324979e19132bcb330c354712c08f19a48956d` | `9c9d0b0` feat(viewer) · `ea3c522` chore(hwp): 터널 주소 갱신(`hwp-host.json`) |

되돌리기: `oneclick`에서 `git revert ea3c522 9c9d0b0` → 더뷰가 원래 안내 카드 전용으로 돌아감. (중간에 다른 작업자의 `f159485` 쇼룸 커밋이 끼어 있어서 rebase 뒤 push함. 그 커밋은 건드리지 않음.)

### curl 원문 (최종 코드 회귀)
```
#1 health: {"ok":true,"ver":"1.0"}
#2 1p  -> 200 77630B 8.308066s
#2 30p -> 200 26394B 2.751289s X-KTS-Pages: 30
#3 exe -> 415
#3 fake.hwp -> 415
#3 21MB -> 413
#3 rate(같은IP 재요청) -> 429
#4 A 200 / #4 B 429
#5 OFF -> 503
health after: {"ok":true,"ver":"1.0"}
```
터널: `start-hwp-server.ps1` 출력 `③ 터널: https://pursue-griffin-massage-kentucky.trycloudflare.com / 터널 경유 /health: OK`. 서버만 끈 뒤 같은 주소 `/health` → 502.

### 라이브 더뷰 결과(`output/hwp_20261120/src/live.ps1`)
```
매매계약서_1쪽.hwp 5256ms loader=구형 한글 → PDF로 바꾸는 중… (사무실 PC) {"kind":"pdf","pages":1,"sw":390,"canvases":1,"errs":[], ...}
시험문서_30쪽.hwp 4439ms loader=구형 한글 → PDF로 바꾸는 중… (사무실 PC) {"kind":"pdf","pages":30,"sw":390,"errs":[], ...}
(서버 끔)   293~564ms {"kind":"notice","card":true,"retryBtn":true,"priv":"구형 .hwp는 사무실 PC에서 PDF로 바꿉니다. 파일은 그 PC를 거쳐 이 기기로 돌아오고 저장되지 않습니다.","errs":[]}
```

### 만든 파일
- `hwp-server/hwp-server.ps1` — PowerShell 5.1 + `HttpListener`. STA 작업자 런스페이스 1개에서 한글 COM(`HWPFrame.HwpObject`)으로 `Open` → `SaveAs PDF`. 메인 루프는 비동기라서 변환 중에도 429/503/health 응답 가능
- `hwp-server/start-hwp-server.ps1` — ①~⑤ 순서. 옵션 `-NoTunnel -NoPush -NoWait`. oneclick 저장소 위치는 형제 폴더를 찾아서 정함(개인 경로 하드코딩 없음)
- `hwp-server/stop-hwp-server.ps1`, `README.md`, `.gitignore`(`logs/ run/ bin/ OFF`)
- `output/hwp_20261120/src/live.ps1`(라이브 CDP 검수), `gate_viewer.ps1`(게이트 이식판), `shots/`
- `oneclick/viewer.html`, `oneclick/hwp-host.json`

### 0단계 사실 확인
- 설치: `한컴오피스 2024 Edu`, `한컴오피스 2014`, `한컴오피스 2024 뷰어` · `HWPFrame.HwpObject` 등록돼 있음 · PC 이름은 지시서와 같음
- COM 변환: `Open=True, PageCount=1, SaveAs PDF=True`, 77,630B. **보안 승인창은 뜨지 않았음.** 단 `RegisterModule("FilePathCheckDLL",…)`의 반환값은 `False`(모듈 DLL이 등록돼 있지 않음)
- §2-B(LibreOffice 대체 경로)는 필요 없어서 하지 않음

## 4. 못 한 것 / 남은 위험
1. **PC가 꺼져 있거나 서버를 안 켜면 변환이 안 됩니다** → 안내 카드로 돌아갑니다(시험으로 확인).
2. **trycloudflare 주소는 켤 때마다 바뀝니다.** `start` 스크립트가 `hwp-host.json`을 자동으로 커밋·push하지만 GitHub Pages 반영에 1~2분 걸립니다. 그 사이에는 예전 주소 → 안내 카드가 뜹니다. 무료 터널이라 가동 시간 보장(SLA)이 없습니다.
3. **한글 COM 보안 승인창**: 이번에는 뜨지 않았지만 `FilePathCheckerModule`은 등록돼 있지 않습니다. 한컴 업데이트 뒤 승인창이 뜨면 변환이 멈춥니다. 그러면 45초 뒤 504가 나가고, 그 변환이 띄운 한글만 종료됩니다.
4. **winget 설치 실패**: `winget install Cloudflare.cloudflared`가 MSI 관리자 승인(UAC) 대기에서 5분 넘게 멈춰서 중단했습니다. 대신 GitHub 공식 릴리스의 `cloudflared-windows-amd64.exe` 2026.11.1을 `hwp-server/bin/`에 받았습니다(Authenticode `Valid`, 서명자 Cloudflare, Inc., SHA-256 `341DEDA3…955E35`). 커밋하지 않았습니다.
5. **업로드 동의**: 지시서대로 `.hwp`를 고르면 바로 사무실 PC로 보냅니다. 고지 문구는 실패 카드 안에만 있어서, 변환에 성공하면 손님이 고지를 보지 못합니다. 첫 화면의 "파일은 서버로 올라가지 않고 이 기기 안에서만 처리됩니다" 문구는 제0원칙 때문에 바꾸지 않았습니다. 구형 `.hwp`에는 사실과 다른 문구입니다.
6. **타임아웃 해석**: 더뷰는 `hwp-host.json`과 `/health` 확인에 각각 10초, 변환 응답에는 50초를 줍니다. 서버 한도가 45초라서 변환까지 10초로 자르면 느린 폰 업로드나 큰 문서가 멀쩡히 변환 중인데도 실패로 처리되기 때문입니다.
7. 30쪽 시험 문서는 한글 COM으로 만든 합성 문서입니다(실제 30쪽 업무 문서가 아님). 1쪽 원본의 Hancom `CreatePageImage` 캡처는 629×26으로 깨져 나와서, 그 문서는 텍스트로 대조했습니다.
8. 기존부터 있던 현상(이번에 손대지 않음): 390px에서 안내 카드가 x=50에서 시작해 오른쪽 끝에 붙어 보입니다. 변경 전 버전도 같았습니다(가로 스크롤은 없음). 게이트 FAIL 2건(연락처·`sms:` 링크)도 변경 전부터 있었습니다.
9. 레이트리밋은 `CF-Connecting-IP` 기준입니다. 같은 사무실 Wi-Fi(공인 IP 1개)를 쓰는 여러 명이 10초 안에 연달아 열면 뒷사람은 안내 카드를 봅니다.

## 5. 대표님 결정 1건
**변환에 성공할 때도 "사무실 PC를 거친다"는 고지를 보여 줄지(또는 올리기 전에 한 번 묻는 단계를 둘지)** 정해 주세요. 지금은 지시서대로 실패 카드에만 고지가 있고, 첫 화면의 "서버로 올라가지 않습니다" 문구와도 맞지 않습니다. 관문 6(대표님 직접 시연) 전에 정할 일입니다.

시연 방법: `hwp-server\start-hwp-server.ps1` 실행 → "커밋 … 1~2분 뒤 반영"이 보이면 2분 기다림 → 폰 모바일 데이터로 더뷰에서 구형 `.hwp` 열기(#6 실측) → 끝나면 `stop-hwp-server.ps1`.

남은 것: #6 폰 모바일 데이터 실측(대표님 시연) · 대표님 결정 1건(고지 위치) · `kts_gate.py` 원본이 생기면 #10 다시 실행

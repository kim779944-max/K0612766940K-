# auto_watch.ps1 한도(rate limit) 안전장치 보강 — 2026-11-20 WATCHFIX

## 무엇이 바뀌었나 · 왜

클로드 5시간 한도에 걸리면 `claude`가 0이 아닌 코드로 끝나 그 회차가 '결과 파일 없음'으로 기록되고 시도 횟수(`{task}.try`)가 깎였습니다. 3번이면 `BLOCKED.txt`에 박혀 그 지시서는 다시 자동 실행되지 않았습니다. 또 `claude`가 끝나지 않으면 뮤텍스를 쥔 채 이후 회차가 전부 '진행 중'으로 건너뛰었습니다.

| # | 안전장치 | 위치(`auto_watch.ps1`) |
|---|---|---|
| S1 | 한도 감지(`usage limit`·`429`·`rate limit`… 대소문자 무시) → `{task}.try`를 직전 값으로 되돌림 · BLOCKED 안 만듦 · `RATE_HIT.log` 1줄(시각 · task · 판정문 200자 · 리셋예상) · 리셋 시각을 읽으면 `RATE_HIT.txt`(JSON `task`·`hitAt`·`resetAt`) · 커밋·푸시는 그대로 | `Test-RateLimit`(43행) · 판정·처리(301행~) |
| S2 | 한도 대기 게이트: 뮤텍스 잡은 뒤·git 작업 전에 `RATE_HIT.txt`의 `resetAt` 전이면 `한도 대기 중 → … 건너뜀`. 지났으면 `한도 리셋 시각 지남 → 이어서 재시도`. 리셋 시각을 못 읽었으면 파일이 없으므로 10분마다 그대로 재시도 | 121행~ |
| S3 | 리셋 시각 읽기: `reset at 3:00 PM` · `resets 15:00` · `reset 2:30pm` · `resets 5am` + `limit reached\|<유닉스초>`. **규칙: 오늘 그 시각이 지났으면 내일, 7시간 넘게 뒤면 오독으로 보고 `$null`(10분 재시도)** | `Get-ResetHint`(50행) |
| S4 | 이어서 실행: 첫 시도에 `--session-id <GUID>`(지원 시) → `{task}.session` 저장, 미지원이면 `{task}.resume` 표시. 다음 시도는 `--resume <GUID>` → 없으면 `--continue` → 없으면 '이어서' 문구만. 프롬프트 맨 앞에 지시서의 '이어서' 문구. 재개가 바로 실패(세션 없음 등)하면 **같은 회차에 `-p` 단독 1회만** 재시도하고 로그에 남김 | 249행~, 288행~ |
| S5 | 워치독: `Start-Process` + `WaitForExit` · `$MaxRunMinutes = 90` 넘으면 `taskkill /T /F`(프로세스 트리) · 로그 `실행 상한 초과로 종료(90 분)` · 시도 횟수 안 셈 · 표준출력·오류는 `{task}.out.txt`·`{task}.err.txt`(회차마다 새로), 누적은 `{task}.history.txt` | `Invoke-Claude`(88행) |

- 그 밖: 인자 따옴표 처리 함수 `ConvertTo-ArgString`(77행, 프롬프트를 인자 1개로 정확히 전달 — 시험에서 argc 확인). 시험용 덮어쓰기 환경변수 3개(`KTS_AW_STATEDIR`·`KTS_AW_MUTEX`·`KTS_AW_MAXRUNMIN`, 평소엔 비어 있어 동작 무변경).
- 줄 수: 192 → 354줄(+175 / −13, `git diff --numstat`). 바뀐 기존 줄은 맨 위 주석·상태 폴더/뮤텍스 이름 변수화·`& $claude` 직접 호출 → `Invoke-Claude`·결과 생성 시 지우는 파일 목록뿐이고, 보관 커밋·fetch·reset/rebase·지시서 선택·큐·커밋·푸시 블록은 글자 그대로입니다.
- 한도 판정은 **결과 파일이 없고**, 출력에 신호가 있고, (종료코드 ≠ 0 이거나 출력이 400자 미만)일 때만 합니다. 정상 작업 보고에 'rate limit' 낱말이 섞여도 시도 횟수가 무한히 안 깎이는 일이 없게 하려는 조건입니다.

## 시험 결과 (실제 claude 호출 0 · `%TEMP%\aw_test` 사본 · 가짜 claude.exe)

가짜 claude는 `test/shim/claude_shim.cs`를 `Add-Type`로 exe로 빌드해 `PATH` 맨 앞에 둡니다(실제 `claude.exe`와 같은 방식으로 인자를 받게 하려고 .cmd 대신 exe). 상태 폴더·뮤텍스는 시험 전용이라 실제 감시기(지금 이 회차를 돌리는 중)와 섞이지 않습니다.

| # | 내용 | 결과 | 로그 |
|---|---|---|---|
| T1 | `usage limit reached … reset at 3:00 PM` · exit 1 | try 1→1 · RATE_HIT.log 1줄 · RATE_HIT.txt `resetAt 15:00` · BLOCKED 0 · 결과 없음 · 첫 시도 `--session-id` (6/6 PASS) | `test/logs/T1.txt` |
| T2 | T1 직후 2회차 | `한도 대기 중 → 리셋 예상 11-20 15:00 까지 건너뜀` · claude 호출 0회 (3/3) | `T2.txt` |
| T3 | resetAt 1분 전으로 고친 뒤 | `한도 리셋 시각 지남 → 이어서 재시도` · argv `--resume <GUID>` + 이어서 문구 · 완료 후 try·session·RATE_HIT.txt 삭제 (4/4) | `T3.txt` |
| T4 | `429 Too Many Requests` · exit 1 | RATE_HIT.txt 미생성 · try 변화 0 · 다음 회차 바로 호출(+1) · `--resume` (4/4) | `T4.txt` |
| T5 | 정상 종료 + 결과 파일 | try 삭제 · RATE_HIT.txt 삭제 · `git push 완료` · 원격에 `auto: … 자동 실행 결과` (5/5) | `T5.txt` |
| T6 | 120초 대기 · 상한 1분 | 61초 만에 종료 · 상한 초과 로그 1줄 · 가짜 claude 프로세스 0 · try 안 셈 · 다음 회차 정상 진입·완료 (5/5) | `T6.txt` |
| T7 | 문법 | `[scriptblock]::Create` 오류 0 · 파서 오류 0 · BOM 있음 (3/3) | `T7.txt` |
| T8 | 회귀 R1~R8 + S4-4 | 22/22 PASS (아래) | `T8.txt` |

합계 **52/52 PASS**. 지시서 T6 의 '30초 대기'는 상한 1분보다 짧아 워치독이 발동하지 않으므로 가짜 claude 대기를 120초로 바꿔 시험했습니다.

| R | 기존 동작 | 결과 |
|---|---|---|
| R1 | 뮤텍스 | 1번이 도는 중 2번 → `이전 실행이 아직 진행 중 → 건너뜀` PASS. **실환경에서도** 교체 직후 실제 상태 폴더로 1회 실행 → 같은 줄 기록(이 회차를 돌리는 12:20 실행이 뮤텍스를 쥐고 있음) |
| R2 | 보관 커밋 | 추적 파일 수정 → `auto: 이전 실행 잔여 변경 보관` 커밋 + 로그 1줄 PASS |
| R3 | 원격 맞추기 | 원격만 앞섬 → `원격 최신으로 맞춤(1 커밋)` · 둘 다 앞섬 → `rebase 완료(원격 1 위에 로컬 1)` · 로컬만 앞섬 → 그대로 푸시 PASS |
| R4 | 지시서 선택 | 큐 첫 줄 1개만 → 끝나면 다음 줄 PASS |
| R5 | 플래그 재시도 | `unknown option` → `--permission-mode bypassPermissions`로 2번째 호출 PASS |
| R6 | try 삭제 | 결과 생성 후 삭제 PASS |
| R7 | 로그 접기·LAST_RUN | 6MB 로그 → `autowatch.log.1` · LAST_RUN 갱신 PASS |
| R8 | 푸시 실패 재시도 | 실행 중 다른 PC가 먼저 푸시 → `git push 재시도 성공` · 원격에 두 커밋 PASS |
| S4-4 | 재개 실패 | `--resume` 세션 없음 → 같은 회차 `-p` 단독 1회 · 로그 PASS · `--session-id`/`--resume`/`--continue` 모두 없는 claude → `.resume` 표시 → 다음 시도는 이어서 문구만 PASS |

다시 돌리기: `powershell -NoProfile -ExecutionPolicy Bypass -File output\watchfix_20261120\test\run_all.ps1` (약 3분 · `test/logs/T*.txt` 덮어씀)

## 파일

| 파일 | 내용 |
|---|---|
| `before_auto_watch.ps1` | 교체 전 원본 사본 |
| `after_auto_watch.ps1` | 보강본(= 저장소 루트 `auto_watch.ps1`과 같은 파일 · 시험 대상) |
| `test/shim/claude_shim.cs` | 가짜 claude 소스(모드: ratelimit_reset·r429·ok·hang·badflag·resumefail·fail) |
| `test/_lib.ps1` · `test/run_T1.ps1`…`run_T8.ps1` · `test/run_all.ps1` | 시험 스크립트 |
| `test/logs/T1.txt`…`T8.txt` | 시험 로그 원문 |

## 되돌리기

```powershell
Copy-Item output\watchfix_20261120\before_auto_watch.ps1 auto_watch.ps1 -Force   # → 커밋
```

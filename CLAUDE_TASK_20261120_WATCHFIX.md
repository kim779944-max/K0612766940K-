# PC 클로드 코드 작업 지시서 — 2026-11-20 WATCHFIX (감시기 한도 재시도 보강 + 핵심 10종 이관 패키지)

> 발령: 2026-11-20 12:2x · 사령관 지니 → PC 클로드 코드(Pro 정액제)
> 결과 보고서: **`CLAUDE_RESULT_20261120_WATCHFIX.md`** (작업 후 `git add -A → commit → push origin main`)
> 큐 등록: `CLAUDE_QUEUE.txt` 맨 끝에 이 파일이 들어 있습니다. **이 파일 하나만 읽고 과업 1 → 과업 2 순서로 끝까지 실행**하세요.

---

## 0. 이번 회차 규칙 (하나라도 어기면 그 항목은 실패로 기록)

1. **제0원칙** — 이 지시서가 지정한 파일·폴더 밖은 건드리지 않습니다. 기존 코드 정리·포맷·주석·리팩터링 금지.
2. **실서비스 무변경** — `oneclick` 저장소는 **한 줄도 바꾸지 않습니다**(관문 6 대표님 시연 전). 이관 준비는 패키지 폴더와 `%TEMP%` 시험 사본에서만.
3. 외부 발송(문자·메일·SNS)·결제·스토어 업로드·유료 API **0건**. 웹폰트·CDN·외부 요청 **0건**.
4. **비밀값·상품파일 커밋 금지** — 이 저장소는 공개입니다. APK·keystore·토큰·비밀번호·개인정보를 올리지 않습니다.
5. **되돌릴 수 있게** — 과업마다 손대기 전 `git rev-parse HEAD` 해시를 적어 보고서에 넣습니다.
6. **실패는 그대로 보고** — 어떤 파일·줄에서 어떤 명령이 어떤 오류로 막혔는지 원문 그대로. 추측으로 넘어가지 않습니다.
7. 이 PC에는 **Python·Node가 없습니다**(11-20 결과 보고 ⑧). 렌더링·측정은 PowerShell + 헤드리스 크롬 CDP(`output/theform_20261118/src/cdp.ps1`)로 하고, 쓴 스크립트는 `output/핵심이관_패키지_20261120/src/`에 남겨 다시 돌리면 같은 결과가 나오게 합니다.
8. **자동감시기와 동시 실행 주의** — `auto_watch.ps1`이 10분마다 돌아 이 저장소에 `git add -A`를 합니다. 커밋·푸시 전에 `git pull --rebase origin main`을 한 번 넣고, 충돌하면 `git rebase --abort` 후 보관 커밋(`auto: …`)을 확인하고 다시 시도하세요. **작업 도중 `auto_watch.ps1`이 커밋한 흔적이 있으면 지우지 말고 보고서에 적습니다.**

### 0단계 — 저장소 최신화

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull --rebase origin main
git rev-parse HEAD      # 이 값을 보고서 6장에
Get-Command claude | Select-Object -ExpandProperty Source
Test-Path auto_watch.ps1
Test-Path oneclick\swapcheck.html
```

`oneclick\swapcheck.html`·`rights1p.html`·`balju.html`·`ledger.html`·`tagmaker.html`이 없으면 **과업 2를 시작하지 말고** 그 사실을 보고서에 적습니다(100선 산출물이 다른 브랜치에 있을 수 있음).

---

# 과업 1 — `auto_watch.ps1` 한도(rate limit) 안전장치 보강

> 대표님 지시(2026-11-20): "클로드 5시간 한도 에러로 멈췄을 때 **10분마다 자동 재시도**하거나 **재개 문구를 이어서 실행**하도록 안전장치를 넣어라."
> 지금 문제: 한도에 걸리면 `$claude`가 0이 아닌 코드로 끝나고 → 그 회차는 '결과 파일 없음'으로 기록되고 **시도 횟수(`{task}.try`)가 소모**됩니다. 3회면 `BLOCKED.txt`에 박혀 그 지시서는 자동으로 영영 실행되지 않습니다. 실제로 11-20 오전에 5시간 한도로 멈춘 구간이 있었습니다.

## 1-1. 반드시 지켜야 하는 기존 동작 (회귀 금지 — 하나라도 깨지면 실패)

| # | 기존 동작 | 확인 방법 |
|---|---|---|
| R1 | 뮤텍스로 동시 실행 차단 | 스크립트 2개 동시 실행 → 두 번째가 `이전 실행이 아직 진행 중 → 건너뜀` |
| R2 | 미커밋 변경은 '보관 커밋' 후 계속 | 더미 파일 생성 → 실행 → 커밋 생성·로그 1줄 |
| R3 | 원격 최신 맞추기(`reset --hard` / `pull --rebase`) | 로컬·원격 앞뒤 상황 3가지 시험 |
| R4 | 지시서 선택 규칙(결과 파일 없는 것 + `CLAUDE_QUEUE.txt` 순서 우선) | 큐 순서대로 1개만 고르는지 |
| R5 | `--dangerously-skip-permissions` 실패 시 `--permission-mode bypassPermissions` 재시도 | 가짜 claude가 'unknown option'을 내면 2번째 인자로 재시도 |
| R6 | 결과 파일이 생기면 `{task}.try` 삭제 | 정상 완료 1회 |
| R7 | 로그 5MB 접기·`LAST_RUN.txt` 갱신 | 그대로 |
| R8 | 실행 후 커밋·푸시, 실패 시 rebase 1회 재시도 | 그대로 |

## 1-2. 새로 넣을 안전장치 (S1~S5)

### S1. 한도 걸림 감지 — 시도 횟수를 깎지 않는다

`$claude` 실행 결과 문자열에서 아래 신호를 찾습니다(대소문자 무시). **한도는 우리 잘못이 아니므로 실패로 세지 않습니다.**

```powershell
function Test-RateLimit([string]$out){
  if ([string]::IsNullOrWhiteSpace($out)) { return $false }
  $p = '(?i)(usage limit reached|5[- ]hour limit|hit your (?:usage )?limit|reached your (?:usage )?limit|limit (?:will )?reset|rate[_ -]?limit_error|rate[_ -]?limit|429 ?(?:Too Many Requests|too many requests)|quota exceeded|You are out of (?:extra )?usage|Please try again (?:later|in \d+))'
  return ($out -match $p)
}
```

한도로 판정했을 때 처리:

1. `{task}.try` 값을 **직전 값으로 되돌립니다**(= 이번 시도를 세지 않음).
2. `BLOCKED.txt`·`{task}.blocked`를 **만들지 않습니다**(한도는 '직접 확인 필요'가 아님).
3. `%LOCALAPPDATA%\KTS_autowatch\RATE_HIT.log`에 한 줄 추가: `시각 · task · 판정문(200자) · 리셋예상` .
4. 리셋 시각을 읽었으면 `RATE_HIT.txt`(JSON: `task`, `hitAt`, `resetAt`)에 저장. 못 읽었으면 **파일을 남기지 않고** 다음 회차(10분 뒤) 그대로 재시도.
5. 커밋·푸시는 **그대로 수행**해 중간 산출물을 보존합니다(기존 4) 단계 유지).

### S2. 10분마다 자동 재시도 — 한도 대기 게이트

스크립트 맨 앞(뮤텍스 잡은 뒤, `git` 작업 전)에서:

```powershell
$rateFile = Join-Path $StateDir 'RATE_HIT.txt'
if (Test-Path -LiteralPath $rateFile) {
  $w = $null
  try { $w = Get-Content -LiteralPath $rateFile -Raw | ConvertFrom-Json } catch { Write-Log 'RATE_HIT.txt 판독 실패 → 무시하고 진행'; Remove-Item $rateFile -Force -EA SilentlyContinue }
  if ($w -and $w.resetAt) {
    $resetAt = $null
    try { $resetAt = [datetime]::Parse($w.resetAt, [Globalization.CultureInfo]::InvariantCulture) } catch {}
    if ($resetAt -and (Get-Date) -lt $resetAt) {
      Write-Log ("한도 대기 중 → 리셋 예상 " + $resetAt.ToString('MM-dd HH:mm') + " 까지 건너뜀 (" + $w.task + ")")
      exit 0
    }
    Write-Log ("한도 리셋 시각 지남(" + $resetAt + ") → 이어서 재시도")
  }
}
```

- 리셋 시각을 못 읽어 파일이 없으면 **10분마다 그대로 재시도**합니다(요구사항 그대로).
- 결과 파일이 생기거나 정상 종료하면 `RATE_HIT.txt`를 지웁니다.

### S3. 리셋 시각 읽기 (실패해도 무해)

```powershell
function Get-ResetHint([string]$out){
  # "Your limit will reset at 3:00 PM" · "resets at 15:00" · "reset 2:30pm" · "resets 5am"
  $m = [regex]::Match($out, '(?i)reset(?:s)?(?:\s+(?:at|on))?\s*:?\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?')
  if (-not $m.Success) { return $null }
  $h = [int]$m.Groups[1].Value
  $mi = if ($m.Groups[2].Success) { [int]$m.Groups[2].Value } else { 0 }
  $ap = $m.Groups[3].Value.ToLower()
  if ($ap -eq 'pm' -and $h -lt 12) { $h += 12 }
  if ($ap -eq 'am' -and $h -eq 12) { $h = 0 }
  if ($h -gt 23 -or $mi -gt 59) { return $null }
  $now  = Get-Date
  $cand = Get-Date -Year $now.Year -Month $now.Month -Day $now.Day -Hour $h -Minute $mi -Second 0
  if ($cand -le $now) { $cand = $cand.AddDays(1) }      # 오늘 그 시각이 지났으면 내일
  if ($cand -gt $now.AddHours(7)) { return $null }       # 5시간 한도인데 7시간 뒤는 오독 → 무시(10분 재시도로 처리)
  return $cand
}
```

- **시각대를 못 믿겠으면 `$null`을 돌려주고 재시도 방식으로 넘어갑니다**(추측으로 5시간을 세우지 않음).
- 이미 지난 시각이면 '다음 날'로 넘기지 말고 `AddMinutes(-2)` 정도로 잡아 **바로 재시도**하게 해도 됩니다(어느 쪽이든 보고서에 어느 규칙을 썼는지 적기).

### S4. '이어서 실행' — 세션 재개

한도나 중단으로 끊긴 뒤에는 **처음부터 다시 하지 않고 이어서** 합니다.

1. 첫 시도 때 세션 id를 남깁니다(지원하는 경우):
   - `claude --help` 출력에 `--session-id`가 있으면 `--session-id <GUID>`를 붙여 실행하고, 그 GUID를 `{task}.session`에 저장.
   - 없으면 `{task}.resume` 표시 파일만 만듭니다.
2. 같은 지시서의 **2회차 이후** 시도에서:
   - `--resume`이 지원되고 `{task}.session`이 있으면 `claude --resume <GUID> -p "<프롬프트>"`;
   - `--continue`(짧게 `-c`)가 지원되면 `claude --continue -p "<프롬프트>"`;
   - 둘 다 없으면 기존처럼 `-p`에 아래 '이어서' 문구를 넣습니다.
3. 재개 프롬프트에 반드시 넣을 문구:

```
이전 실행이 중간에 끊겼습니다(한도·중단). 이미 만든 파일·이미 끝낸 과업은 다시 만들지 말고,
① 지금 저장소 상태를 먼저 확인하고 ② 남은 부분만 이어서 끝낸 뒤
③ 결과 보고서 맨 위에 "이어서 실행(앞 실행 산출물 승계)" 이라고 적고 git add -A → commit → push origin main 까지 마쳐 주세요.
```

4. `--resume`/`--continue`가 오류(세션 없음 등)로 실패하면 **같은 회차에서 `-p` 단독으로 1회만** 다시 시도하고, 그 사실을 로그·보고서에 적습니다(무한 재시도 금지).

### S5. 멈춘 채 매달리지 않게 — 실행 상한(워치독)

한도 대기나 네트워크에서 `claude`가 끝나지 않으면 뮤텍스 때문에 **이후 회차가 전부 '진행 중'으로 건너뛰어 영구 정지**합니다.

- `$MaxRunMinutes = 90`(설정값). `Start-Process -PassThru` + `WaitForExit(ms)`로 기다리고, 넘으면 `Stop-Process -Force`.
- 표준출력·표준오류는 파일(`{task}.out.txt`, `{task}.err.txt`)로 받아 읽습니다. 죽였으면 로그에 `실행 상한 초과로 종료(90분)`을 남기고, `{task}.try`는 **세지 않습니다**(한도와 같은 처리).
- 시험할 때는 상한을 1분으로 낮춰 확인합니다.

## 1-3. 시험 (이 PC에서, 실제 claude 호출 없이)

`%TEMP%\aw_test\bin\claude.cmd` 같은 **가짜 claude(shim)**를 만들어 `$env:PATH` 맨 앞에 걸고 확인합니다. shim은 받은 인자를 `argv.txt`에 남기고 정해진 문구를 출력합니다.

| # | shim 동작 | 통과 기준 |
|---|---|---|
| T1 | `Claude AI usage limit reached. Your limit will reset at 3:00 PM` 출력 후 exit 1 | `{task}.try` 값 **변화 없음** · `RATE_HIT.log` 1줄 · `RATE_HIT.txt` 생성(리셋 파싱) · `BLOCKED.txt` 생성 0 · 결과 파일 미생성 |
| T2 | T1 직후 2회차 실행(리셋 전) | 로그 `한도 대기 중 … 건너뜀` 1줄 · claude 호출 **0회** |
| T3 | `RATE_HIT.txt`의 `resetAt`을 1분 전으로 고친 뒤 3회차 | 로그 `한도 리셋 시각 지남 → 이어서 재시도` · `argv.txt`에 `--resume`/`--continue`/이어서 문구 중 하나가 실제로 들어감 |
| T4 | 리셋 문구 없는 한도 메시지("429 Too Many Requests") 후 exit 1 | `RATE_HIT.txt` 미생성 · try 변화 0 · 다음 회차에 바로 재시도 |
| T5 | 정상 종료(exit 0) + 결과 파일 생성 | `{task}.try` 삭제 · `RATE_HIT.txt` 삭제 · 커밋·푸시 로그 |
| T6 | 30초 대기(상한 1분으로 낮춤) | 1분 뒤 프로세스 종료·로그 1줄·뮤텍스 풀림(다음 회차 정상 진입) |
| T7 | 문법 검사 | `powershell -NoProfile -Command "[void][scriptblock]::Create((Get-Content -Raw .\auto_watch.ps1))"` 오류 0 |
| T8 | 회귀 R1~R8 | 위 표의 확인 방법대로 전부 통과(로그·파일로 증거) |

- 시험은 **`%TEMP%`에 복제한 사본**에서 합니다. 실 저장소의 `auto_watch.ps1`은 T1~T8이 모두 통과한 뒤에 한 번에 교체합니다.
- 시험 스크립트·shim·로그는 `output/핵심이관_패키지_20261120/../` 밖(공개 저장소)에 두지 말고, 공개 저장소에 올릴 필요가 없으면 `output/watchfix_20261120/`에 **텍스트(.ps1/.txt)만** 남깁니다(비밀값·개인정보 0).
- 교체 직후 `setup_autowatch.bat run`으로 **실제 1회** 돌려 회귀가 없는지 확인합니다(그 회차는 큐의 이 지시서를 물 수 있음 → 그 자체가 정상 동작 증거).

## 1-4. 산출물

```
auto_watch.ps1                        ← 보강본(교체). 맨 위 주석에 이번 보강 5줄(S1~S5) 요약
output/watchfix_20261120/
  README.md                           ← 무엇이 바뀌었나 · 왜 · 시험 결과표 · 되돌리기
  before_auto_watch.ps1               ← 교체 전 원본 사본
  test/shim/claude.cmd (또는 .ps1)     ← 가짜 claude
  test/run_T1.ps1 … run_T8.ps1        ← 시험 스크립트
  test/logs/T1.txt … T8.txt           ← 시험 로그 원문
```

되돌리기: `Copy-Item output\watchfix_20261120\before_auto_watch.ps1 auto_watch.ps1 -Force` → 커밋.

---

# 과업 2 — 100선 완료 62종 → **핵심 10종** `oneclick` 이관 패키지

> 근거: NIGHT3 15종 + NIGHT4 19종 + DESIGN 3종 + NIGHT5 25종 = **62종 완료**(각 `CLAUDE_RESULT_20261118_NIGHT3/NIGHT4/DESIGN`, `CLAUDE_RESULT_20261119_NIGHT5.md`).
> 이미 `output/100선_이관_20261120/`(5종: `swapcheck`·`rights1p`·`balju`·`ledger`·`tagmaker`)이 만들어져 있습니다. **이번에는 그 5종을 그대로 포함해 10종으로 넓힌 상위 패키지**를 새 폴더에 만듭니다. 기존 패키지 폴더는 손대지 않습니다.

## 2-1. 선정 10종 (지니 확정 — 이 목록을 바꾸지 말 것)

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

- **추가 5종을 넣은 이유(보고서에 그대로 옮겨 적기)**: 기존 5종은 '한 파일로 바로 파는 도구' 기준을 통과한 5개였습니다. 이번에 10종으로 넓히면 ① 부동산 상담 흐름이 `시세(pricegap) → 권리(rights1p) → 수익(yieldcalc) → 교환판정(swapcheck) → 통지(notice)`로 한 줄로 완결되어, 한 상담에서 도구를 3~5개 쓰게 되고 재방문이 생깁니다. ② `bidcompare`는 대표님 본인 신하리 공사비(1.1억) 검증에 바로 쓰는 도구로, 60만~100만 원대 과다 항목을 잡아내면 그 자체가 즉시 현금 절감입니다. ③ `themenu`는 판매가 아니라 **번개알바 업소 DB에 붙는 유입 상품**입니다(사장님이 QR을 찍어 보는 순간 설득이 끝남). 셋 중 하나라도 대표님이 빼라고 하시면 나머지로 9종·8종 패키지를 그대로 만들 수 있게 `copy_manifest.json`·`products_추가분.js`를 **slug 단위로 잘라 쓸 수 있게** 작성하세요.
- `themenu`의 `price`는 `"무료"`, 나머지는 기존 5종과 같은 `"무료 체험"`으로 합니다.

## 2-2. 만들 위치·파일

```
output/핵심이관_패키지_20261120/
  README.md                 ← 이관 3단계 · 기존 5종 패키지와의 관계(상위 패키지) · 되돌리기 · 대표님 승인 전 실행 금지
  선정_10종.md              ← 위 표 + 항목별 중복 확인(라이브 19종 대비) + 근거 파일 경로
  copy_manifest.json        ← 30줄(html 10 + 아이콘 10 + 상세 캡처 10)
  products_추가분.js        ← 객체 10개(기존 항목과 키 구성 동일)
  catalog_추가분.json       ← products 10개 + count 규칙(하드코딩 금지 설명)
  apply.ps1                 ← 멱등 이관기(-WhatIf 지원)
  390px_검수표.md           ← 10행 전부 채움 · FAIL 0
  390/{slug}.png            ← 이번 회차 재측정 캡처 10장
  390/measure_log.jsonl     ← 측정 원문(ext:[] 포함)
  src/                      ← 측정·검사 스크립트(cap390·check_add 등)
```

파일 원본은 전부 이 저장소의 `oneclick/` 안에 있습니다.

```
oneclick/{slug}.html            (10개)
oneclick/shots/ic_{slug}.png    (10개)
oneclick/shots/{slug}_home.png  (10개)   ← products 의 shot 칸이 가리킴(상세 페이지용)
```

## 2-3. `apply.ps1` 요구사항 (여기가 이번 회차의 핵심)

1. **멱등** — 두 번 실행해도 중복이 붙지 않습니다. 이미 `products.js`에 그 `k`가 있으면 그 종은 건너뜁니다. (대표님이 기존 5종 `apply.ps1`을 먼저 돌린 상태여도 나머지 5종만 들어가야 합니다.)
2. **count 하드코딩 금지** — `catalog.json`의 `count`는 실행 시점의 `products` 배열 길이로 다시 계산해 씁니다(`count = products.Count`). `19 → 24` 같은 고정 값을 쓰지 않습니다.
3. **문의 카드 링크 교체** — 10종 각 1곳, 합계 **10곳**: `../misa-1116/form.html` → `https://autooneclick.com/#reserve`.
4. **그림 복사** — `copy_manifest.json` 30줄 + `products`의 `shot`이 가리키는 `shots/{slug}_home.png` 10장(manifest에 이미 포함). 30/30 `Test-Path` 통과.
5. `-WhatIf`로 **바뀔 것만 출력**하고 쓰지 않습니다. 기본 실행은 실제 적용.
6. 실행 전 `git -C <oneclick> status --short`가 비어 있지 않으면 **멈추고** 안내합니다(다른 작업과 섞이지 않게).
7. 되돌리기 명령을 README에 3줄로 적습니다(`git checkout -- products.js catalog.json` + `git clean -n/-f -- <10 html> shots/`).

## 2-4. 완료 판정 (보고서에 체크로)

- [ ] 10종 html·아이콘·상세 캡처가 저장소에 있고, `copy_manifest.json` 30줄 `Test-Path` **30/30**.
- [ ] `products_추가분.js` 구문 오류 0(크롬에서 `<script src>`로 읽어 `syntax errors: []`), 10개, 기존 `k` 중복 `[]`, 키 구성 기존 항목과 **10/10 동일**.
- [ ] `catalog_추가분.json` 형식이 라이브 `catalog.json` 항목과 동일(키 누락 0).
- [ ] 390px 재측정 10종 **FAIL 0**: 가로 넘침 0 · 겹침 0 · 잘린 글자 0 · JS 오류 0 · 예시→결과 2탭 · 복사 동작 · 외부 참조(`script/link/img`의 http(s)) **0개**.
- [ ] `themenu`는 QR이 실제로 디코드되고(링크 문자열과 일치), A4 1쪽 인쇄가 되며 한·영 2언어가 나온다.
- [ ] `notice`는 자동 발송 코드 0(`sms:`·`mailto:`·`fetch(`·`XMLHttpRequest`·`sendBeacon` 0).
- [ ] `bidcompare`는 단가 빈칸을 추정하지 않고(`NaN`/빈칸 유지), 확인 필요 쌍을 자동 병합하지 않는다.
- [ ] `yieldcalc`·`pricegap` 수치는 화면 값과 손 검산이 일치(보고서에 검산식 1줄).
- [ ] `apply.ps1`을 **`%TEMP%` 시험 사본**(라이브 HEAD clone)에서 실행: 파일 30개 복사 · `products.js` +N/−1(마지막 쉼표만) · `catalog.json` count == products 길이 · 쇼룸 타일 10개 · 깨진 그림 0 · 상세 페이지 정상. **두 번째 실행 시 추가 0건(멱등)**.
- [ ] `oneclick` 저장소 실제 변경 **0** — `git -C oneclick status --short`가 빈 출력(시험은 `%TEMP%`에서만).
- [ ] 라이브 확인: `https://autooneclick.com/swapcheck.html` 등 10종이 아직 **404**임을 적어 둡니다(대표님 승인 전이라는 증거).

## 2-5. 보고서(`CLAUDE_RESULT_20261120_WATCHFIX.md`)에 넣을 것

1. 한 줄 요약표(과업 1 / 과업 2 판정: 완료·부분·실패).
2. 과업 1: 바뀐 함수·줄 수, S1~S5 각각의 구현 위치, T1~T8 시험 결과표(로그 파일 경로), R1~R8 회귀 확인 결과, 교체 전후 파일 경로.
3. 과업 2: `선정_10종.md` 표 그대로 + 390px 실측값 + dry-run 결과(복사 수·diff 줄 수·count·타일 수·2회차 0건).
4. 막힌 것·지시서와 다르게 한 것(원문 오류 메시지 포함).
5. 커밋 표(손대기 전 HEAD / 이번 커밋 / 푸시 결과).
6. 다음 회차 인수인계 3줄.

---

## 마지막 줄

과업 1 → 과업 2 순서로 끝까지. 결과는 `CLAUDE_RESULT_20261120_WATCHFIX.md`에 정리하고 `git add -A → git commit → git push origin main`.

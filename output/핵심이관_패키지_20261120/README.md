# 100선 핵심 10종 → 실서비스 `oneclick` 이관 패키지 (2026-11-20 · 상위 패키지)

> **대표님 시연·승인(관문 6) 전에는 실서비스 저장소에 실행하지 않습니다.** 이 회차에는 만들기와 `%TEMP%` 시험만 했고, 실서비스 `oneclick` 저장소는 한 줄도 바뀌지 않았습니다(`git -C oneclick status --short` 빈 출력 · HEAD `b664d30`). 라이브에서 10종 주소는 아직 모두 404입니다(`src/live404_log.txt`).

1. 기존 5종 패키지(`output/100선_이관_20261120/`: swapcheck·rights1p·balju·ledger·tagmaker)를 **그대로 포함**하고 yieldcalc·pricegap·notice·bidcompare·themenu 5종을 더한 상위 패키지입니다. 기존 패키지 폴더는 손대지 않았습니다.
2. 10종 모두 한 파일짜리 웹앱입니다. 외부 CDN·서버·유료 API 0, 라이브 19종과 키·링크 중복 0(`선정_10종.md`).
3. 390px로 다시 쟀습니다. 10종 모두 FAIL 0(`390px_검수표.md`).
4. `apply.ps1`은 **멱등**입니다. 기존 5종 `apply.ps1`을 먼저 돌린 저장소에서도 나머지 5종만 들어가고, 두 번 돌려도 추가 0건입니다. `catalog.json`의 `count`는 고정 값이 아니라 **실행 시점 products 배열 길이**로 다시 씁니다.

## 이관 3단계 (손으로 할 때)

| 단계 | 할 일 |
|---|---|
| ① 복사 | `copy_manifest.json` 30줄(html 10 + 아이콘 `shots/ic_{slug}.png` 10 + 상세 캡처 `shots/{slug}_home.png` 10)을 `K0612766940K-/oneclick/…`에서 실서비스 `oneclick/`로 복사. html 10개는 문의 링크 1줄씩 교체(아래) |
| ② products.js | `products_추가분.js`의 객체 중 **아직 없는 `k`만** `window.PRODUCTS` 맨 끝(`];` 바로 앞)에 붙입니다. 바로 앞 객체 끝 `]}` 뒤에 쉼표 1개(이 줄이 diff의 −1) |
| ③ catalog.json | `catalog_추가분.json`의 `products` 중 **아직 없는 `k`만** `products` 끝에 붙이고, `count` = 붙인 뒤 `products` 개수(라이브 19 → 29, 기존 5종이 이미 있으면 24 → 29) |

쇼룸 타일·상세 페이지는 `catalog.json`(오프라인일 때는 `products.js`)만 채우면 자동으로 생깁니다. `index.html`·`detail.html`은 손대지 않습니다.

### ★ 문의 카드 링크 — 10종 각 1곳, 합계 10곳

```
../misa-1116/form.html   →   https://autooneclick.com/#reserve
```

`misa-1116` 폴더는 실서비스 저장소에 없어서 그대로 옮기면 404가 납니다. `apply.ps1`이 복사하면서 자동으로 바꿉니다(시험 사본에서 새 주소 10곳 · 옛 주소 0곳 확인).

## 자동으로 (대표님 승인 후)

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-\output\핵심이관_패키지_20261120"
powershell -ExecutionPolicy Bypass -File apply.ps1 -WhatIf     # 바뀔 것만 보기(아무 파일도 안 씀)
powershell -ExecutionPolicy Bypass -File apply.ps1             # 기본 대상: ..\..\..\oneclick (KTS_작업실\oneclick)
powershell -ExecutionPolicy Bypass -File apply.ps1 -Exclude themenu            # 9종만
git -C ..\..\..\oneclick status --short                          # M products.js · M catalog.json · ?? 30개
```

- 대상 저장소에 커밋 안 된 변경이 있으면 `apply.ps1`은 **멈추고**(종료코드 2) 목록을 보여 줍니다.
- 시험(`src/dryrun_apply.ps1`, 라이브 HEAD를 `%TEMP%`에 clone): 복사 30 · `products.js` +101/−1 · `catalog.json` +413/−1 · count 29 = products 29 · 쇼룸 타일 10(전체 29) · 깨진 그림 0 · 상세 10/10 정상 · 2회차 추가 0건. 원문 `src/dryrun_log.txt`.

## 되돌리기

```powershell
git -C <oneclick> checkout -- products.js catalog.json
git -C <oneclick> clean -n -- swapcheck.html rights1p.html yieldcalc.html pricegap.html notice.html bidcompare.html balju.html ledger.html tagmaker.html themenu.html shots/   # 지울 목록 확인
git -C <oneclick> clean -f -- swapcheck.html rights1p.html yieldcalc.html pricegap.html notice.html bidcompare.html balju.html ledger.html tagmaker.html themenu.html shots/   # 새로 들어온 파일만 지움
```

(이미 커밋했다면 `git -C <oneclick> revert <그 커밋>`.)

## 이 폴더

| 파일 | 내용 |
|---|---|
| `선정_10종.md` | 선정표 · 추가 5종 이유 · 라이브 19종 대비 중복 확인 · 근거 파일 경로 |
| `copy_manifest.json` | 30줄(`slug`·`from`·`to`) — slug 단위로 잘라 쓸 수 있음 |
| `products_추가분.js` | 객체 10개(기존 `products.js` 키 구성과 10/10 동일) · 종마다 주석 1줄 |
| `catalog_추가분.json` | products 10개 + `count_rule`(고정 값 금지 설명) |
| `apply.ps1` | 멱등 이관기(`-WhatIf` · `-Exclude` · `-OC`) |
| `390px_검수표.md` · `390/{slug}.png` · `390/measure_log.jsonl` | 이번 회차 재측정 |
| `src/` | `build_package.ps1`(추가분·manifest 생성) · `check_add.ps1`(문법·중복·키·catalog 생성) · `cap390.ps1`(390 측정) · `dryrun_apply.ps1` + `serve.ps1`(시험 사본 적용·쇼룸 확인) · `live404.ps1` · 각 `*_log.txt` |

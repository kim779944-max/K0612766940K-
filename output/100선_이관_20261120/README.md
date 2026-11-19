# 100선 실매출 5종 → 실서비스 `oneclick` 이관 패키지 (2026-11-20)

1. NIGHT3~5에서 만든 62종 중 **실매출 핵심 5종**을 골랐습니다: `swapcheck` 더교환판정 · `rights1p` 더권리 · `balju` 더발주 · `ledger` 더장부 · `tagmaker` 더태그.
2. 5종 모두 한 파일짜리 웹앱입니다. 외부 CDN·서버·유료 API를 쓰지 않고, 지금 실서비스 상품 18종과 기능이 겹치지 않습니다.
3. 이번 회차에 390px로 다시 쟀습니다. 5종 모두 가로 넘침·겹침·잘린 글자·JS 오류가 0입니다. 예시 1탭 + 실행 1탭으로 결과가 나옵니다(`390px_검수표.md`).
4. **아직 쇼룸에 등록하지 않았습니다.** 실서비스 저장소는 이 패키지 때문에 한 줄도 바뀌지 않았습니다. 대표님 시연(관문 6)을 통과하면 아래 3단계를 진행합니다.
5. `apply.ps1`이 3단계를 한 번에 처리합니다. 임시 사본에서 시험 실행한 결과, 쇼룸 타일 5개와 상세 페이지가 정상으로 나왔고 깨진 그림은 0개였습니다. 두 번 실행해도 중복으로 붙지 않습니다.

## 이관 3단계 (손으로 할 때)

| 단계 | 할 일 |
|---|---|
| ① 복사 | `copy_manifest.json`의 10개 파일(html 5 + 아이콘 5)을 `K0612766940K-/oneclick/…`에서 실서비스 `oneclick/` 루트로 복사합니다. 상세 페이지 캡처 `shots/{slug}_home.png` 5장도 함께 복사합니다(`products`의 `shot` 칸이 이 파일을 가리킵니다) |
| ② products.js | `products_추가분.js`의 객체 5개를 `window.PRODUCTS` 배열 맨 끝(`];` 바로 앞)에 붙입니다. 바로 앞 객체 끝 `]}` 뒤에 쉼표 1개를 넣습니다 |
| ③ catalog.json | `catalog_추가분.json`의 `products` 5개를 `catalog.json`의 `products` 배열 끝에 붙이고, `"count": 19` → `"count": 24`로 바꿉니다 |

쇼룸 타일은 `products.js`만 채우면 자동으로 생깁니다(`index.html`이 `window.PRODUCTS`를 읽어 그립니다). `index.html`은 손대지 않습니다.

### ★ 반드시 함께 바꿀 1줄 — 문의 카드 링크

NIGHT 상품 하단의 문의 카드는 `../misa-1116/form.html`을 가리킵니다. 이 폴더는 실서비스 저장소에 **없어서** 그대로 옮기면 404가 납니다.

```
../misa-1116/form.html   →   https://autooneclick.com/#reserve
```

- 바꿀 곳은 5종 각 1곳, 합계 5곳입니다(`#inqLink`).
- 교체 후 링크는 지금 실서비스 `tax.html`·`contract/`·`organizer/`·`sign/`의 사전예약 배너와 같은 주소입니다.
- `apply.ps1`은 복사하면서 이 줄을 자동으로 바꿉니다.

## 자동으로 (대표님 승인 후)

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-\output\100선_이관_20261120"
powershell -ExecutionPolicy Bypass -File apply.ps1            # 기본 대상: 옆 폴더 ..\oneclick
git -C ..\..\..\oneclick status --short                      # M products.js · M catalog.json · ?? 15개
```

## 되돌리기

```powershell
cd <oneclick>
git checkout -- products.js catalog.json
git clean -n -- swapcheck.html rights1p.html balju.html ledger.html tagmaker.html shots/   # 지울 목록 확인
git clean -f -- swapcheck.html rights1p.html balju.html ledger.html tagmaker.html shots/   # 새로 들어온 파일만 지움
```

## 이 폴더

`README.md` · `선별_5종.md` · `copy_manifest.json` · `products_추가분.js` · `catalog_추가분.json` · `390px_검수표.md` · `apply.ps1` · `390/{slug}.png`(이번 캡처) · `390/measure_log.jsonl`(실측 원문) · `src/`(측정·검사 스크립트)

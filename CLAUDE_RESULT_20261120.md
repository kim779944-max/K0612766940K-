# 2026-11-20 지시서 결과 (CLAUDE_TASK_20261120.md)

## ① 한 줄 요약

| 과업 | 판정 |
|---|---|
| 1(a) 교환계약서 7곳 손질 | **완료** (실서비스 `oneclick` 반영·푸시) |
| 1(b) 표시광고 위험 문구 4곳 제거 | **완료** (반영·푸시) |
| 1(c) 더뷰 APK v1.4 | **부분** — 동기화 자산·빌드 노트 완료 / **APK 미완 · (app_viewer 프로젝트 없음, JDK 17 없음, Android SDK build-tools 34 없음)** |
| 2 100선 실매출 5종 이관 패키지 | **완료** (7개 파일 + 390px 재측정, 쇼룸 등록 안 함) |
| 3 상황판 PC팀 정정 | **완료** (반영·푸시) |

도구: 이 PC에는 Python·Node가 없습니다. 그림 처리는 PowerShell + System.Drawing(C#)으로 했습니다. 화면 검수는 기존 헤드리스 크롬 CDP 스크립트(`output/theform_20261118/src/cdp.ps1`)를 그대로 썼습니다.

---

## ② 과업 1(a) — 교환계약서 7곳 손질

바뀐 파일(실서비스): `contract/tpl_exchange.png` · `contract/forms.js` · `contract/index.html`
원본 보관: `output/교환계약서_20261120/before_{tpl_exchange.png,forms.js,index.html}`
그림 손질 스크립트: `output/교환계약서_20261120/src/edit_tpl.ps1`(원본 → 결과를 다시 만들 수 있음) · 실측: `src/verify_tpl.ps1` · 화면 검증: `src/verify_contract.ps1` → `verify_log.txt`

| # | 손질 | 판정 | 실측값 (1489×2105 기준) |
|---|---|---|---|
| ① | 명칭 `(당사자용)` | 완료 | `forms.js` `name:"부동산 교환계약서(당사자용)"`. 양식 고르기 버튼 = `["부동산 교환계약서(당사자용)"]`. **인쇄물 제목**: 인쇄물은 배경 그림 자체라서 그림 제목 뒤에 `(당사자용)`을 넣었습니다(맑은 고딕 보통 46px, 제목+꼬리를 가운데로 다시 맞춤: 제목 x 378~876, 꼬리 x 895~1100) |
| ② | `특약사항 :` 줄 위치 | 완료 | 글자 y **1223~1247**(높이 25px, 원래 1301~1325와 같은 크기), 시작 x **117**(제5조 x 117과 같음). 제5조 밑 1206 → 1223 사이에 다른 줄 없음. 줄 간격 1183→1223 = **40px** |
| ③ | 특약 내용칸 | 완료 (x·w **1곳 조정**) | y **60%** · h **21.57%** · fs **30** · `shrink:1`. x는 지시값 7.857%로 넣었을 때 실측 첫 글자 x가 **126.3**이었습니다. `composite()`가 칸 왼쪽에 안쪽 여백(pad = fs×0.3 = 9px)을 두기 때문입니다. 완료 판정 "117±2"를 맞추려고 **x 7.253% · w 87.034%**(오른쪽 끝 94.287%는 그대로)로 9px 당겼습니다 → 실측 첫 글자 x **117.5**, `특약사항 :` x **116.6** |
| ④ | 하단 문구 + 표 +220px | 완료 | 문구 y **1731~1754** · 표 가로선 **1776~1777 / 1830 / 1883 / 1936~1937** · 프레임 세로선 끝 **1989** · 새 아래 가로선 **1986~1989**(위 테두리 143~146 단면 복사) · 프레임 아래 흰 여백 116px = **16.4mm** · 1990~2104 흰색 외 픽셀 0 |
| ⑤ | `p19`~`p31` y +10.45 | 완료 | 13개 모두 +10.45(예: p19 71.578→82.028, p31 81.603→92.053). x·w·h·label·grp 그대로(⑦ 제외) |
| ⑥ | 갑 서명칸 회색 `자필서명` 제거 | 완료 | 지운 픽셀 797개. 갑 서명칸 x 1115~1290 흰색 외 픽셀 **0**. `(인)`(x 1305~1344)과 검정 테두리는 그대로. ※ 원본의 `(인)`도 회색이었습니다. 지시서의 "x 1115~1408 회색 전부"를 그대로 하면 `(인)`까지 지워지므로 범위를 `자필서명` 글자 열(x 1179~1273)을 덮는 **x 1115~1290**으로 줄였습니다 |
| ⑦ | 을 서명칸 정렬 | 완료 | `p31` x 87.018→**79.038**, w 7.795→**15.707**. `p30` w 11.927→**4.2** + `fit:1`. 서명 그림 왼쪽 x 실측: 갑 **1176.9** / 을 **1176.9** → 차이 **0px** |

완료 판정 실측
- [x] 양식 목록·`curForm().name` = `부동산 교환계약서(당사자용)`, 인쇄물 제목에도 `(당사자용)` (`after_title.png`)
- [x] `특약사항 :` x 116.6 / 특약 첫 줄 x 117.5 (117±2) · 라벨 글자 높이 25px(24±1) · 줄 간격 40px
- [x] 제5조 밑 1206 → `특약사항 :` 위 1223, 사이 빈 줄 없음 (`after_top.png`)
- [x] 문구 1731 · 표 1776/1830/1883/1936 · 프레임 끝 1989 (`after_bottom.png`)
- [x] 갑 `자필서명` 회색 0, `(인)` 유지, 을/갑 서명 왼쪽 x 차이 0px
- [x] 특약 **6줄**: 6줄 모두 표시, 줄 간격 39.6(축소 없음, fs 30). **12줄**: 12줄 모두 표시, 줄 간격 37.0(축소됨), 마지막 줄 밑 1704.5 < 칸 끝 1717 → **잘린 글자 0** (`after_composite_6줄.png`·`after_composite_12줄.png`)
- [x] 인쇄 → PDF **1쪽** (`after_print_12줄.pdf`, `print()` 호출 1회, 인쇄 영역 그림 1장)
- [x] 40줄(fs 11에서도 넘침) → 경고 `특약이 너무 깁니다 — 줄이거나 글자를 줄여 주세요` 표시 (`after_composite_40줄_경고.png`)
- [x] 그 밖의 8종(매매·등기위임장·주택·상가·근로·차용·용역·동업): 같은 값을 채워 합성한 결과를 손질 전/후로 비교 → **8/8 픽셀 해시 동일**. 매매 캡처 2장 `compare_sale_before.png`/`compare_sale_after.png`(바이트도 동일)
- [x] `forms.js`의 교환계약서 항목 밖 43,341바이트는 손질 전과 체크섬 동일. `index.html`은 `composite()` 여러 줄 처리부만(+5줄) 바꿨고, `f.shrink`가 없는 필드는 그대로 동작
- 콘솔 오류: 열 때 `[]` · 끝 `[]`

`composite()` 변경: `f.shrink`가 켜진 필드만 `줄 수 × lh + pad > h`이면 fs를 0.5(원본 px 기준)씩 줄여 다시 감쌉니다. 하한은 fs 11입니다. 그래도 넘치면 토스트 경고 1줄을 띄웁니다. 지시서 식(`줄 수 × lh > h`)에 위쪽 여백 `pad`를 더했습니다. 그대로 두면 마지막 줄이 칸 밑으로 약 2px 나갈 수 있어서입니다.

## ③ 과업 1(b) — 위험 문구 4곳

지운 문자열: `기준가 500,000원 → 지금 <b style="color:#FF6B00;font-weight:900">0원</b> · `

| 파일 | 줄 | 남은 `<i>` 내용 | `500,000` | `지금…0원` | 사전예약 링크 | diff | 390 캡처 |
|---|---|---|---|---|---|---|---|
| `tax.html` | 128 | `업종·연락처 10초` | 0 | 0 | `https://autooneclick.com/#reserve` | 1줄 | `output/교환계약서_20261120/fix_문구_tax.png` |
| `contract/index.html` | 112 | `업종·연락처 10초` | 0 | 0 | 같음 | 이 줄 1줄(+ 1(a)의 composite 부분) | `fix_문구_contract.png` |
| `organizer/index.html` | 79 | `업종·연락처 10초` | 0 | 0 | 같음 | 1줄 | `fix_문구_organizer.png` |
| `sign/index.html` | 115 | `업종·연락처 10초` | 0 | 0 | 같음 | 1줄 | `fix_문구_sign.png` |

- 같은 형태(`기준가 N원 → 지금 0원`, `정가 … → 0원`)를 4개 파일에서 더 찾았지만 **추가 0건**이었습니다.
- 390px 실측(4곳 동일): 배너 폭 12~378 · 높이 51px, `<i>` 1줄(비지 않음), `scrollWidth` 390, 콘솔 오류 `[]`.

## ④ 과업 1(c) — 더뷰 v1.4

**APK 미완 · (app_viewer 프로젝트 없음 · JDK 17 없음 · Android SDK build-tools 34 없음)**
- `C:\Users\A` 아래 깊이 7까지 `app_viewer`가 없습니다. `AndroidManifest.xml`은 `K0612766940K-/app_saycap`(세이캡) 것만 있습니다.
- `java`·`JAVA_HOME`·`ANDROID_HOME`·`%LOCALAPPDATA%\Android`·`Program Files\Java|Eclipse Adoptium|Android`가 모두 없습니다. 지시대로 설치는 시도하지 않았습니다.

남긴 것 → `output/app_viewer_v14/`

| 파일 | 내용 |
|---|---|
| `assets/viewer.html` | 웹 최신 `oneclick/viewer.html`(88,663B, A4 1:1 인화 보기 포함) + ⓐ~ⓓ → 88,662B |
| `viewer_web_vs_app_v14.diff` | 웹 원본과 다른 곳은 **ⓐ~ⓓ 4곳뿐** |
| `build_notes.md` | ⓐ~ⓓ · 버전 2값 · build.sh 수정 4줄 · 빌드 PC 실행 명령 |
| `verify_asset.ps1` · `verify_asset_log.txt` · `check_*.png` | 자산 검수 |

동기화 diff
- ⓐ `<script src="master.js"></script>` 줄 삭제
- ⓑ cdnjs `pdf.min.js`를 `<script src="pdf.worker.min.js">`(먼저) + `<script src="pdf.min.js">`로 바꿈. `workerSrc='pdf.worker.min.js'`. CDN 폴백 줄은 두지 않음
- ⓒ `<script src="hwp.js"></script>` 추가. `.hwp` 분기를 `if (typeof KTS_HWP === 'undefined' || !KTS_HWP.parseHwp) throw …` + `r = await KTS_HWP.parseHwp(await file.arrayBuffer())`로 복원
  - ⚠ v1.3 자산 원본과 `hwp.js`가 이 PC에 없어 **원본과 한 줄씩 대조하지 못했습니다.** 지시서에 적힌 코드 형태로 넣었습니다.
- ⓓ `<title>더뷰 v1.4 — KTS 만능 뷰어 (한글·엑셀·워드·PDF·사진)</title>`

버전: versionCode 15 · versionName 1.4는 **빌드 노트에만 적었습니다**(`app_viewer`가 없어 적용 못 함). APK 경로·크기·SHA256과 `apksigner verify` 원문은 **없음**(빌드 안 됨).

자산 검수(이 PC, 앱 라이브러리 없이)
- 콘솔 오류 3건 = `LOAD hwp.js` · `LOAD pdf.worker.min.js` · `LOAD pdf.min.js`. 세 파일은 앱 assets에만 있고 이 PC에는 없습니다. 이 셋 말고 오류 0건
- 외부 요청 **0건**(resource timing) · http(s) `<script src>` 0개 · 390px 가로 넘침 0
- `.xlsx` 열림(13행×9열) · `.hwpx` 열림(9행×5열) · 사진 열림. 각각 오류 0
- PDF: `pdfjsLib`가 없어 기존 폴백(frame)으로 열림. `.hwp`(더미): "구형 한글(.hwp) 읽기 모듈(hwp.js)을 불러오지 못했습니다" 표시. 실제 pdf.js 렌더·hwp 파싱은 **빌드 PC에서 재확인 필요**
- 참고: 웹 원본에는 [이미지로 저장]을 누를 때만 cdnjs `html2canvas`를 부르는 코드 2곳이 있습니다(열 때 요청 0). ⓐ~ⓓ 밖이라 그대로 뒀습니다.

## ⑤ 과업 2 — 100선 실매출 5종 이관 패키지

위치: `output/100선_이관_20261120/`. 기본안 5종을 그대로 썼고 대체 후보는 쓰지 않았습니다.

| # | slug | 이름 | 중복 확인 | 문의 링크 수 |
|---|---|---|---|---|
| #71 | `swapcheck` | 더교환판정 | `exchange`(매물 포털)와 다름 — 성사 가능성 판정 | 1 |
| #65 | `rights1p` | 더권리 | 등기부 권리분석은 18종에 없음 | 1 |
| #57 | `balju` | 더발주 | `sale`(할인 비교)와 다름 — 재고·안전재고·거래처별 발주 | 1 |
| #76 | `ledger` | 더장부 | `tax`(사전 점검)와 다름 — 거래내역 장부·부가세 집계 | 1 |
| #88 | `tagmaker` | 더태그 | `keyword`(지역×업종 1,700개)와 다름 — 상품 등록 제목·검색어 | 1 |

파일 7개: `README.md` · `선별_5종.md` · `copy_manifest.json` · `products_추가분.js` · `catalog_추가분.json` · `390px_검수표.md` · `apply.ps1`
덧붙인 것: `390/{slug}.png` 5장 · `390/measure_log.jsonl` · `src/`(cap390·check_add 스크립트와 로그)

완료 판정
- [x] 7개 파일이 있고, 5종 캡처 파일도 실제로 있습니다(`390/*.png` 5장)
- [x] `products_추가분.js` 구문 오류 0. node가 없어서 크롬에서 `<script src>`로 읽어 확인했습니다(eval 없음): `syntax errors: []`, 5개, 기존 키 중복 `[]`, 키 구성이 기존 항목과 같음 5/5
- [x] `copy_manifest.json` 10줄, `from` `Test-Path` **10/10**
- [x] 문의 카드 `../misa-1116/form.html` → `https://autooneclick.com/#reserve` 1줄을 `apply.ps1`·`README.md`에 적었습니다. 5종 각 1곳, 합계 5곳
- [x] 검수표 5행 모두 채움, **FAIL 0**: 가로 넘침 0 · 겹침 0 · 잘린 글자 0 · JS 오류 0 · 예시→실행 결과 PASS · 복사 PASS · 문의 폼(교체 후 링크) PASS · 아이콘 192×192 정상
  - 1차 측정에서 `swapcheck` 겹침 2건이 나왔는데, 닫힌 `<details>` 안의 안 보이는 문단이 잡힌 오탐이었습니다. 측정식을 고친 뒤 다시 잰 값이 0입니다.
- [x] `oneclick` 저장소 `git status` — 과업 2 때문에 바뀐 파일 **0개**. 실서비스 커밋 직후 원문: `git -C oneclick status --short` → (빈 출력)
- [x] README만 읽고 3단계로 이관 가능. 추가로 `apply.ps1`을 **임시 사본**(`%TEMP%\apply_dryrun`, 실서비스 HEAD를 clone)에서 시험 실행했습니다:
  - 파일 15개 복사, 문의 링크 5곳 교체
  - `products.js` +51/−1(마지막 객체 뒤 쉼표 1개), `catalog.json` count 24 = products 24
  - 두 번째 실행은 중복으로 건너뜀
  - 쇼룸 `PRODUCTS` 23 · 5종 타일 링크 각 3개 · 깨진 그림 0 · 상세 페이지 정상
- 지시서 밖 1건: `products`의 `shot` 칸(`shots/{slug}_home.png`)을 상세 페이지가 씁니다. 10줄 manifest만 옮기면 상세 캡처가 404가 나므로, `apply.ps1`이 5장을 따로 함께 복사합니다(manifest는 지시대로 10줄 유지).

## ⑥ 과업 3 — 상황판 (`oneclick/ops/status.json`)

- `departments`의 `id:"pc"` 블록만 지시서 문구 그대로 교체했습니다. `blocked` 키는 삭제했습니다. `done`에 `교환계약서 7곳 손질` 포함((a) 완료). `updated` = `2026-11-20T05:58:00+09:00`, `updatedBy` = `PC 클로드 코드팀 (지시서 20261120)`
- diff 범위: 2~3줄(updated·updatedBy)과 pc 블록뿐입니다. `chief`·`notice`·다른 부서 4개(dev·ads·commerce·tax)는 변경 0. `ConvertFrom-Json` 통과(pc doing/todo/done = 1/3/3)
- `/ops/` 390px 캡처: `output/교환계약서_20261120/ops_390.png`
  - 측정: 로컬 HTTP로 열고, 시험 브라우저에서만 PIN 덮개를 숨긴 뒤 페이지의 [새로고침]으로 불러왔습니다(비밀번호는 쓰지도 적지도 않음)
  - 결과: PC 카드 정상(●1 ●3 ●3), 빨간 확인 점 0, '절전' 문구 0, 가로 넘침 0, 오류 0

## ⑦ 커밋

| 저장소 | 손대기 전 HEAD | 이번 커밋 |
|---|---|---|
| `oneclick` | `ca90721d440d92ef30c59ca169aed344bb2bb336` (pull 직후. pull 전 로컬은 `a329c4e`) | `b664d30adca5fe28af3624a63be480d3e17c6c64` — push 완료 (`ca90721..b664d30`) |
| `K0612766940K-` | `b50b7c938fdb17ff4a8a757101c7fef881ff74cc` | 이 보고서가 들어간 커밋 — 해시는 바로 다음 커밋에서 아래 줄에 기록 |

- 되돌리기: `git -C oneclick revert b664d30`
- 이 PC는 git 사용자 정보가 비어 있어서, 저장소 기존 작성자(`KTS 원클릭` / `지니`)를 이번 커밋에만 `-c user.name/-c user.email`로 지정했습니다. `git config`는 바꾸지 않았습니다.

## ⑧ 막힌 것

1. **더뷰 APK 빌드 불가**
   - `find /c/Users/A -maxdepth 7 -type d -name app_viewer` → 결과 없음
   - `which java javac` → `which: no java in (…)` / `which: no javac in (…)`
   - `ls /c/Users/A/AppData/Local/Android` → `No such file or directory`
   - `ls "/c/Program Files/Java" "/c/Program Files/Eclipse Adoptium" "/c/Program Files/Android"` → 모두 `No such file or directory`
   - `JAVA_HOME`·`ANDROID_HOME` 비어 있음
2. **v1.3 자산·`hwp.js` 없음** → ⓒ를 v1.3 원본과 대조하지 못함. 두 저장소 전체와 git 이력에서 `KTS_HWP`·`hwp.js` 검색 0건
3. (작업 중 해결) PowerShell 5.1이 BOM 없는 UTF-8 `.ps1`을 cp949로 읽어 한글 주석 줄이 다음 줄을 삼킴 → `using 지시문은 …` 파싱 오류. 스크립트에 BOM을 넣어 해결
4. (작업 중 해결) 상황판 첫 캡처가 PIN 게이트 화면만 나옴 → 위 ⑥의 방식으로 다시 캡처

## ⑨ 다음 회차 인수인계

1. **남은 상품 8종**: 더블로그·더콘티·더포지션·더전단·더청구·더차계·더이사·더가정. 이번 회차 대상이 아니어서 손대지 않았습니다.
2. **공통 부품 위치**
   - CDP 크롬: `output/theform_20261118/src/{cdp,lib}.ps1`
   - 100선 공통 틀: `output/12차_개발팀_20261119/src/{common.css,common.js,top.html,bottom.html}`
   - 그림 픽셀 도구: `output/교환계약서_20261120/src/px.ps1`
   - 이관 스크립트: `output/100선_이관_20261120/apply.ps1`
3. **남은 이슈**
   - 더뷰 v1.4 APK: JDK 17·SDK가 있는 PC에서 `build_notes.md` 순서로 빌드하고 ⓒ를 v1.3과 대조
   - 100선 5종 쇼룸 등록: 관문 6 통과 후 `apply.ps1`
   - 실서비스 `viewer.html`의 html2canvas CDN 지연 로드(이미지 저장 때만)는 그대로 둠

남은 것: 더뷰 v1.4 APK 빌드·서명 검증(app_viewer·JDK 17·build-tools 34 있는 PC 필요, 동기화본은 output/app_viewer_v14) · 100선 5종 쇼룸 등록(대표님 시연 후 apply.ps1) · K0612766940K- 커밋 해시 기록

# PC 클로드 코드 작업 지시서 — 2026-11-20 (원클릭 수리 3건 · 100선 실매출 5종 이관 패키지 · 상황판 최신화)

> 발령: 2026-11-20 05:5x · 사령관 지니 → PC 클로드 코드(Pro 정액제)
> 앞 회차: NIGHT3·NIGHT4·DESIGN·NIGHT5 결과 보고서 5건 도착(62종 산출물) — **회수 완료. 더 만들지 않습니다.**
> 이번 회차는 **새 상품 양산이 아니라 수리·선별·정리**입니다. 과업 3개, 끝까지 실행하세요.
> 결과 보고서: **`CLAUDE_RESULT_20261120.md`** (작업 후 `git add → commit → push`)
> 저장소 2개를 씁니다 — ① `K0612766940K-`(지시서·결과·패키지) ② `oneclick`(실서비스 사이트 autooneclick.com)

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 이번 회차에 하지 않는 것 (하나라도 어기면 그 항목은 실패로 기록)
1. **제0원칙** — 이 지시서가 지정한 파일·줄 외에는 **틀·색감·기능·문구를 일절 바꾸지 않는다.** 리팩터링·정리·주석 추가·포맷 변경 금지.
2. **새 상품을 만들지 않는다.** 100선 잔기능(더블로그·더콘티·더포지션·더전단·더청구·더차계·더이사·더가정)은 이번 회차 대상이 아니다.
3. **쇼룸 등록을 하지 않는다.** 과업 2는 '선별·패키지'까지다. 실서비스 `products.js`·`catalog.json`에 5종을 넣지 않는다.
4. 외부 발송(문자·메일·SNS)·결제·스토어 업로드·유료 API **0건**.
5. **관문 6** — 대표님 직접 시연 통과 전 대외 판매·광고·문자 발송 금지.
6. **비밀값·상품파일 커밋 금지** — `oneclick` 저장소는 공개다. APK·keystore·토큰·비밀번호를 올리지 않는다.
7. **되돌릴 수 있게** — 손대기 전 각 저장소의 `git rev-parse HEAD` 해시를 적어 두고 보고서 ④에 넣는다.
8. **실패는 그대로 보고** — 어떤 파일·줄에서 어떤 명령이 어떤 오류 메시지로 막혔는지 원문 그대로. 추측으로 넘어가지 않는다.

### 저장소 두 곳

| 저장소 | 이 PC 경로 | 이번에 만지는 것 |
|---|---|---|
| `K0612766940K-` (지시서·결과·패키지) | `$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-` | `CLAUDE_TASK_20261120.md`(이미 있음)·`CLAUDE_QUEUE.txt`·`CLAUDE_RESULT_20261120.md`·`output/100선_이관_20261120/` |
| `oneclick` (실서비스 사이트) | `$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\oneclick` (아래 0단계에서 확인) | `contract/`·`tax.html`·`organizer/index.html`·`sign/index.html`·`ops/status.json` |

> 두 저장소는 **다른 저장소**입니다. `oneclick/` 이라는 폴더가 `K0612766940K-` 안에도 있지만, 그건 쇼룸 목업이고 **실서비스는 따로 있는 `oneclick` 저장소**입니다. 과업 1·3은 실서비스 `oneclick` 저장소에서 합니다.

### 이어서 하기 (재시도 규칙)
자동 실행기가 이 지시서를 여러 번 실행할 수 있습니다. 다시 시작했을 때 **이미 끝난 항목은 건너뛰고** 남은 것만 하세요. 결과 보고서 마지막 줄에 `남은 것: …`을 적어 다음 실행이 이어받게 합니다.

---

## 1. 0단계 — 저장소 두 곳 확인 (10분)

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull
git rev-parse HEAD

Get-ChildItem "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실" -Directory | Select-Object -ExpandProperty Name
```

`oneclick` 저장소를 찾습니다.

```powershell
$base = "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실"
$oc = Get-ChildItem $base -Directory | Where-Object {
  Test-Path (Join-Path $_.FullName '.git\config')
} | Where-Object {
  (Get-Content (Join-Path $_.FullName '.git\config') -Raw) -match 'kim779944-max/oneclick\.git'
} | Select-Object -First 1 -ExpandProperty FullName
if (-not $oc) {
  git clone https://github.com/kim779944-max/oneclick.git (Join-Path $base 'oneclick')
  $oc = Join-Path $base 'oneclick'
}
cd $oc
git pull
git rev-parse HEAD
git status --short
```

**판정표**

| 확인 결과 | 할 일 |
|---|---|
| `oneclick` 폴더가 있고 `git remote -v`에 `kim779944-max/oneclick.git` | 그 폴더에서 과업 1·3 진행 |
| 폴더가 없음 | 위 clone으로 새로 받아 진행 |
| clone이 413·용량 오류로 실패 | `git clone --depth 1 --filter=blob:none https://github.com/kim779944-max/oneclick.git` 로 재시도, 그래도 실패면 **과업 1·3 불가로 보고하고 과업 2만 수행** |

`app_viewer`(안드로이드 프로젝트)도 같은 방식으로 찾습니다.

```powershell
Get-ChildItem $base -Directory -Recurse -Depth 2 -Filter 'app_viewer' -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty FullName
Get-ChildItem "$env:USERPROFILE" -Directory -Recurse -Depth 3 -Filter 'app_viewer' -ErrorAction SilentlyContinue |
  Select-Object -First 3 -ExpandProperty FullName
```

> **옆 저장소에 쓰기가 막히면(권한·도구 제한)**: 실행기는 `K0612766940K-` 폴더에서 돌기 때문에 `oneclick`이 옆 폴더입니다. 그 폴더에 쓰기가 거부되면 추측으로 밀지 말고, 같은 내용을 `K0612766940K-\output\oneclick_patch_20261120\` 에 **패치 파일(`*.patch` 또는 완성된 수정본 + 적용 명령)** 로 만들어 남기고, 막힌 오류 원문을 결과 보고서 ⑧에 적으세요. 그 경우에도 과업 1(b)처럼 **텍스트만 고치는 항목은 패치로 완결**해 둡니다(나중에 지니 쪽에서 적용 1회).

---

## 2. 과업 1 — 실서비스 `oneclick` 저장소 수리 3건 (최우선)

### (a) 교환계약서 7곳 손질 — 적립 97번

대상: `oneclick/contract/tpl_exchange.png`(배경 원본 A4, **1489×2105**, 7.09px/mm) · `oneclick/contract/forms.js` · `oneclick/contract/index.html`

먼저 원본을 보관합니다.

```powershell
$d = "output\교환계약서_20261120"
New-Item -ItemType Directory -Force $d | Out-Null
Copy-Item "$oc\contract\tpl_exchange.png" "$d\before_tpl_exchange.png"
Copy-Item "$oc\contract\forms.js"        "$d\before_forms.js"
Copy-Item "$oc\contract\index.html"      "$d\before_index.html"
```

#### 지금 실측값 (이미 재어 둔 값 — 그대로 씁니다)

| 지점 | 지금 값 (1489×2105 기준) |
|---|---|
| 본문 줄 | 피치 **40px**, 글자 높이 **24px**, 제N조 첫 줄 시작 **x=117**, 이어지는 줄 **x=216** |
| 제5조 | 첫 줄 y **1143~1166**, 둘째 줄 y **1183~1206** (마지막 줄 밑 1206) |
| `특약사항 :` 글자 | y **1301~1325**, 시작 **x=78** (본문 들여쓰기보다 39px 왼쪽) |
| 특약 내용칸 (`special`) | x **5.208%** · y **63.311%** · w **89.538%** · h **7.958%** · fs **23** |
| `이 계약이 성립되었음을 …` 줄 | y **1511~1534** |
| 교환인 표 가로 구분선 | **1556 / 1610 / 1663 / 1716** |
| 인적사항 표 세로 구분선 | **701 · 783 · 1021 · 1111** (갑·을 두 줄 모두 동일) |
| 바깥 프레임 | 세로선 x **73~75** · **1412~1414**, 위 y **144**, 아래 y **1769**(84.0%) |
| 갑 서명칸 안 회색 글씨 | `자필서명 (인)` — 회색(값 150~250) 덩어리, x 대략 1115~1370, y 1615~1658 |

#### 손질 7가지

| # | 무엇 | 목표값 |
|---|---|---|
| ① | **명칭** | `forms.js`의 `name:"부동산 교환계약서"` → **`"부동산 교환계약서(당사자용)"`**, 인쇄물 제목도 뒤에 `(당사자용)` 추가 |
| ② | **`특약사항 :` 줄 위치** | y **1223~1247**(제5조 마지막 줄 1183 + 한 줄 40), 시작 **x=117**(본문 들여쓰기와 동일) |
| ③ | **특약 내용칸** | x **7.857%** · y **60.00%** · w **86.43%** · h **21.57%** · fs **30** · `shrink:1` |
| ④ | **하단 문구 + 인적사항 표** | 아래로 **+220px** 전부 이동: 문구 1511→**1731**, 표 구분선 1556/1610/1663/1716→**1776/1830/1883/1936**, 프레임 아래 끝 1769→**1989**(94.5%) |
| ⑤ | **인적사항·작성일 칸 13개**(`p19`~`p31`) | 각 `y`에 **+10.45** 더한다 (220/2105) |
| ⑥ | **갑 서명칸 회색 `자필서명` 글씨 제거** | 그 글씨 픽셀만 흰색(255)으로. **테두리 선과 `(인)`은 남긴다** |
| ⑦ | **을 서명칸 정렬** | `p31`(을 서명) x **87.018→79.038**, w **7.795→15.707** (갑 `p26`과 동일), `p30`(을 성명) w **11.927→4.2** + `fit:1` |

#### 방법 (그림 손질 ②④⑥⑦)

- ②④⑦은 픽셀 이동이라 **②와 ④는 한 덩어리로 처리**합니다: 아래 블록(하단 문구 1505~프레임 끝 1769)을 **아래로 220px 통째로 이동**하고, 비워진 1505~1769 구간은 흰색으로 지웁니다. 그다음 바깥 프레임 좌우 세로선(x 73~75, 1412~1414)을 y 1769→**1989**까지 연장하고, 새 아래 끝에 가로선 1줄(기존과 같은 굵기·색)을 긋습니다. → 결과: 문구 1731, 표 1776/1830/1883/1936, 프레임 끝 1989.
- `특약사항 :` 글씨(②)는 지금 위치에서 **잘라내어** x 117 · y 1223으로 옮깁니다(크기 그대로, 글꼴 그대로). 옮긴 자리는 흰색.
- ⑥은 x 1115~1408 · y 1610~1662 안에서 **회색(150~250) 픽셀만** 255로 칠합니다. 검정(<120) 테두리·글씨는 건드리지 않습니다. 지운 뒤 그 칸에 남는 것이 `(인)`뿐인지 캡처로 확인합니다.
- ⑦의 칸 위치는 그림의 세로 구분선(1111 다음 칸이 1111~1412) 안에서 갑과 같아지도록 **폼 좌표만** 맞춥니다. 그림에 선을 새로 긋지 않아도 됩니다.
- 그림 도구는 이 PC에 있는 것을 쓰세요(Python+Pillow가 있으면 가장 쉽습니다. 없으면 PowerShell `System.Drawing`). 아래처럼 **결과를 반드시 눈으로 검사**합니다.

```powershell
# 처리 후 확인용 3장 (before / after / 겹쳐보기)
#  - output\교환계약서_20261120\after_tpl_exchange.png
#  - output\교환계약서_20261120\after_bottom.png   (y 1450~2105 잘라 확대)
#  - output\교환계약서_20261120\after_top.png      (y 1000~1350 잘라 확대: 제5조 + 특약사항)
```

#### 방법 (앱 쪽 ③·⑤)

- `forms.js`의 exchange 항목에서 `special` 필드만 위 값으로 바꾸고 `"shrink":1`을 추가합니다. **다른 폼(매매·임대차·근로·차용 등)의 필드는 한 글자도 바꾸지 않습니다.**
- `p19`~`p31` 13개 필드의 `y`만 +10.45 합니다. `x`·`w`·`h`·`label`·`grp`는 그대로.
- `contract/index.html`의 `composite()` **한 곳만** 손봅니다. 지금 여러 줄 처리부는

  ```js
  const lines = wrapText(g, t, w - pad * 2), lh = fs * 1.32;
  ```

  이므로, `f.shrink`가 켜진 필드에서만 **줄 수 × lh 가 h 를 넘으면 fs를 0.5씩 줄여 다시 감싸는 반복**을 넣습니다(하한 fs 11). 넘치는 줄을 잘라 버리지 말고, fs 11에서도 넘치면 화면에 `특약이 너무 깁니다 — 줄이거나 글자를 줄여 주세요` 1줄 경고를 띄웁니다. `f.shrink`가 없는 필드는 지금 동작 그대로여야 합니다.

#### 완료 판정 (실측해서 값으로 적는다)

- [ ] 쇼룸 목록·미리보기 제목이 `부동산 교환계약서(당사자용)`이고, 인쇄물 제목에도 `(당사자용)`이 보인다
- [ ] `특약사항 :` 첫 글자 x = 특약 내용 첫 줄 x = **117±2px**, 글자 높이 **24±1px**, 줄 간격 **40±1px** (제5조 줄과 같은 값)
- [ ] 제5조 마지막 줄 밑(1206) → `특약사항 :` 위(1223) 사이 여백이 **한 줄(≈40px)** 이고, 그 사이에 빈 줄이 없다
- [ ] 하단 문구 y **1731±3**, 표 구분선 **1776/1830/1883/1936±3**, 프레임 아래 끝 **1989±3** — A4 아래 여백 약 16mm
- [ ] 갑 서명칸에 회색 `자필서명` 글씨 **0개**(테두리·`(인)` 유지), 을 서명칸과 갑 서명칸 왼쪽 x 차이 **≤1px**
- [ ] 특약에 **6줄**을 넣으면 축소 없이 전부 보이고, **12줄**을 넣으면 칸 안에서 축소되어 **잘린 글자 0**, 인쇄 **A4 1쪽**
- [ ] 인쇄 미리보기(브라우저 인쇄 → PDF) 1쪽, 아래가 잘리지 않음
- [ ] 그 밖의 계약서 8종(매매·주택·상가·등기위임장·근로·차용·용역·동업) 미리보기·인쇄가 **손질 전과 똑같다**(캡처 2장 비교)

---

### (b) 위험 문구 4곳 제거 — 표시광고 위험

아래 4개 파일에 같은 문구가 **각 1줄씩** 남아 있습니다. (`기준가 500,000원 → 지금 0원`)

| 파일 | 줄 |
|---|---|
| `oneclick/tax.html` | 128 |
| `oneclick/contract/index.html` | 112 |
| `oneclick/organizer/index.html` | 79 |
| `oneclick/sign/index.html` | 115 |

**바꾸는 방법 — 그 문구만 뺀다.**

- 지울 문자열:
  `기준가 500,000원 → 지금 <b style="color:#FF6B00;font-weight:900">0원</b> · `
- 남길 것: `<span style="...">사전예약</span>` 배지, `현재 지역 무료 세팅 사전예약 중`, `업종·연락처 10초`, 그리고 **링크(`href="https://autooneclick.com/#reserve"`)는 그대로**
- 결과적으로 `<i>` 안은 `업종·연락처 10초`만 남습니다.
- 다른 문구는 건드리지 않습니다(`월 4,900원` 같은 **실제 가격**은 손대지 않음). 다만 같은 형태(`기준가 N원 → 지금 0원`, `정가 … → 0원`)가 그 4개 파일에 더 있으면 그것도 같이 빼고, 보고서에 어디였는지 적습니다.

**완료 판정**
- [ ] 4개 파일 모두 `500,000` **0건**, `지금 0원` **0건** (`Select-String -Pattern '500,000','지금\s*<b.*0원'`)
- [ ] 4개 파일의 `사전예약` 링크가 `https://autooneclick.com/#reserve` 그대로 (4/4)
- [ ] 390px 캡처 4장(`output\교환계약서_20261120\fix_문구_{tax,contract,organizer,sign}.png`)에서 줄이 겹치거나 비지 않음, 콘솔 오류 0
- [ ] 4개 파일의 그 줄 **외** diff 0

---

### (c) 더뷰 APK v1.4 동기화

지금 웹 `oneclick/viewer.html`(87KB, A4 1:1 인화 보기 포함)과 앱 자산 `app_viewer/assets/viewer.html`(v1.3, 44KB)이 크게 벌어져 있습니다. 앱을 웹 최신에 맞추고 **v1.4**로 빌드합니다.

**대상**
- 원본: `oneclick\viewer.html` (실서비스 저장소)
- 앱 자산: `<app_viewer>\assets\viewer.html`
- 빌드: `<app_viewer>\build.sh` → `KTS_더뷰_v1.4_debug.apk`

**1) 동기화 + 4곳만 손보기** (단순 복사하면 앱이 깨집니다 — 반드시 아래를 함께)

| # | 웹 원본에 있는 것 | 앱 자산에서 할 일 |
|---|---|---|
| ⓐ | `<script src="master.js"></script>` (2번째 줄) | **줄 삭제** — 앱 자산에 `master.js`가 없어 404가 납니다 |
| ⓑ | pdf.js를 cdnjs에서 받음(`<script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js" …>`, 290줄 / `workerSrc` 293줄) | `<script src="pdf.min.js"></script>` 로 바꾸고, **v1.3 자산 방식 그대로** `pdf.worker.min.js`를 일반 스크립트로 먼저 읽힌 뒤 `GlobalWorkerOptions.workerSrc='pdf.worker.min.js'` 로 설정. 지금 있는 CDN 폴백 1줄은 남겨도 됩니다 |
| ⓒ | 구형 `.hwp`(OLE2) 분기가 없음 | **v1.3의 `.hwp` 분기를 되살립니다** — `<script src="hwp.js"></script>` 를 넣고, 파일 분기에서 `if (typeof KTS_HWP === 'undefined' || !KTS_HWP.parseHwp) throw …` + `r = await KTS_HWP.parseHwp(await file.arrayBuffer())` 를 복원. 이걸 빠뜨리면 **기능 회귀**입니다 |
| ⓓ | `<title>더뷰 — KTS 만능 뷰어 …</title>` | **`더뷰 v1.4 — KTS 만능 뷰어 (한글·엑셀·워드·PDF·사진)`** |

**2) 버전 올리기 — 이 두 값만**

- `app_viewer\AndroidManifest.xml`: `android:versionCode` **14 → 15**, `android:versionName` **1.3 → 1.4**
- `app_viewer\build.sh`: `--version-code 14` → **15**, `--version-name 1.3` → **1.4**, 마지막 출력 파일 이름 `KTS_더뷰_v1.3_debug.apk` → **`KTS_더뷰_v1.4_debug.apk`**
  (`build.sh`는 리눅스 경로(`/workspace/toolchain/...`)를 씁니다. 이 PC에 맞게 `JAVA_HOME`·`BT`·`PLAT` 세 줄만 이 PC의 JDK 17·build-tools 34 경로로 바꿔 실행하거나, 같은 순서의 `build_viewer.ps1`을 새로 만들어 실행합니다. 어느 쪽이든 **소스·res·assets 내용은 바꾸지 않습니다.**)

**3) 자산 검수 (빌드 전에)**

- `assets\viewer.html`을 헤드리스 크롬으로 열어: 콘솔 오류 **0**, 외부 요청(cdnjs) **0건**(폴백 줄은 실행되지 않아야 함), 390px 가로 넘침 **0**
- PDF 1개·xlsx 1개·`.hwp` 1개를 넣어 각각 1쪽 이상 표시되는지 확인(파일이 없으면 `test_assets\`의 것을 사용)

**4) 빌드·확인**

```powershell
cd <app_viewer>
# JDK17·build-tools 34 경로 확인 후 build.sh(또는 build_viewer.ps1) 실행
# 결과: KTS_더뷰_v1.4_debug.apk
& $BT\apksigner verify -v KTS_더뷰_v1.4_debug.apk
Get-FileHash KTS_더뷰_v1.4_debug.apk -Algorithm SHA256
```

**완료 판정**
- [ ] `assets\viewer.html`이 웹 최신 A4 1:1 인화 보기를 포함하고, ⓐ~ⓓ 4곳만 다르다(diff로 확인)
- [ ] 콘솔 오류 0 · 외부 CDN 요청 0 · 390px 가로 넘침 0
- [ ] `.hwp`·`.hwpx`·`.xlsx`·PDF·사진 열림 확인(각 1건)
- [ ] `KTS_더뷰_v1.4_debug.apk` 생성 · `apksigner verify` **v1 true / v2 true / v3 true** · versionCode **15** · versionName **1.4**
- [ ] **APK는 저장소에 올리지 않았다** — 파일 경로·크기·SHA256을 결과에 적는다

**판정표 (안드로이드 프로젝트가 없을 때)**

| 확인 | 할 일 |
|---|---|
| `app_viewer\AndroidManifest.xml` 있음 + JDK·SDK 있음 | 위 1~4 그대로 |
| `app_viewer\` 없음 | 동기화본만 남긴다 → `output\app_viewer_v14\assets\viewer.html` + `output\app_viewer_v14\build_notes.md`(위 ⓐ~ⓓ·버전 2값·build.sh 4줄 수정 내역·실행 명령). **APK는 '미완'으로 정확히 보고** |
| JDK/SDK 없음 | 도구 설치를 시도하지 말고 `미완 · (없는 도구 이름)` 으로 보고하고, 동기화본·빌드 노트는 남긴다 |

---

## 3. 과업 2 — 100선 62종 중 **실매출 핵심 5종** 이관 패키지

만들 위치: `K0612766940K-\output\100선_이관_20261120\`
**이 과업은 파일을 만드는 것까지입니다. 실서비스 `oneclick` 저장소는 이 과업으로 한 줄도 바뀌지 않아야 합니다.**

### 선별 5종 (기본안 — 실측에서 조건이 안 맞으면 아래 '대체 후보'로 바꾸고 이유를 적는다)

| # | slug | 이름 | 왜 이 5종인가 |
|---|---|---|---|
| #71 | `swapcheck` | 더교환판정 | 대표님 본업 그 자체 — A↔B 교환 성사 가능성 6축·등급·막는 요인과 해소 문장 |
| #65 | `rights1p` | 더권리 | 등기부등본 → A4 1장 권리분석. 중개·매물 실무 첫 화면 |
| #57 | `balju` | 더발주 | 입고→부족→발주서. 식자재 쓰는 소상공인이 매일 쓰는 것 |
| #76 | `ledger` | 더장부 | 카드·은행 내역 → 부가세 요약. 세무 보조 축 |
| #88 | `tagmaker` | 더태그 | 쿠팡·스마트스토어 제목·검색어 30종. 위탁판매 본업의 홍보·등록 축 |

**대체 후보**: `settle`(#60 정산표) · `bidcompare`(#70 견적 비교) · `pricegap`(#67 시세·괴리율) · `fieldreport`(#75 임장) · `secondhand`(#91 판매글)
→ "견적서/정산표"가 더 맞다고 판단되면 `tagmaker` 대신 **`settle`** 로 바꿔도 됩니다. 바꿨으면 보고서에 한 줄로 이유를 적습니다.

### 선별 기준 (5종 모두 통과해야 함)

1. 대표님 본업(교환·부동산) 또는 소상공인 매일 업무에 바로 쓰인다
2. 손님이 예시 1탭 + 실행 1탭으로 결과까지 간다(NIGHT 실측 통과분)
3. 한 파일로 끝난다 — 외부 CDN·서버·유료 API 0
4. 실서비스 `oneclick` 저장소의 지금 상품 18종(`sale·photo2doc·theform·contract·viewer·loan·tax·navi·saycap·organizer·tongyeok·realty·keyword·exchange·sign·append·youtube·travel`)과 **기능이 겹치지 않는다**
5. 이번 회차에 다시 캡처해 390px FAIL 0

### 만들 파일 7개

| 파일 | 내용 |
|---|---|
| `README.md` | 5줄 요약 + 이관 3단계(복사 → products.js 추가 → catalog.json 추가) + 되돌리는 방법(`git checkout -- products.js catalog.json`) |
| `선별_5종.md` | 표(순번·#·slug·이름·고객·한 줄 가치·가격 포지션·중복 확인·선별 이유 2줄) + **왜 나머지 57종을 뺐는지 3줄** |
| `copy_manifest.json` | `[{ "from":"oneclick/rights1p.html", "to":"rights1p.html" }, { "from":"oneclick/shots/ic_rights1p.png", "to":"shots/ic_rights1p.png" }, …]` — 소스는 `K0612766940K-/oneclick/`, 대상은 `oneclick` 저장소 루트. **5종 × 2개(html·아이콘) = 10줄** |
| `products_추가분.js` | 5개 객체. 기존 형식 그대로(`k, nm, sub, cat, badge, status:'live', icon, price, price2, line, blurb, link:'{slug}.html', shot, bullets, how, notes`) — 기존 키와 중복 0 |
| `catalog_추가분.json` | 같은 5개(JSON 형식), 그리고 `count` 19→24로 올리는 방법 1줄 |
| `390px_검수표.md` | 아래 표를 **이번에 다시 측정한 값으로** 채운다 |
| `apply.ps1` | manifest대로 복사하고 `products.js`·`catalog.json`에 5개를 붙이는 스크립트. **실행은 하지 않는다**(대표님 승인 후) |

### 390px 검수표 (실측값을 채운다 — 옛 캡처 복사 금지)

| slug | 캡처 경로(회차별로 다름) | 가로 넘침 | 겹침 | 잘린 글자 | JS 오류 | 예시 1탭 결과 | 복사/저장 | 문의 폼 | 아이콘 404 |
|---|---|---|---|---|---|---|---|---|---|
| `swapcheck` | `output/12차_개발팀_20261119/390_swapcheck.png` | | | | | | | | |
| `rights1p` | `output/12차_개발팀_20261119/390_rights1p.png` | | | | | | | | |
| `balju` | `output/11차_개발팀_20261118/390_balju.png` | | | | | | | | |
| `ledger` | `output/12차_개발팀_20261119/390_ledger.png` | | | | | | | | |
| `tagmaker` | `output/12차_개발팀_20261119/390_tagmaker.png` | | | | | | | | |

- 쇼룸 타일은 이 저장소에서 **`products.js`만 채우면 자동으로 생깁니다**(`index.html`이 `window.PRODUCTS`를 읽어 그림). NIGHT 때처럼 `index.html`에 타일 한 줄을 손으로 넣지 마세요.
- 새 캡처는 `output\100선_이관_20261120\390\{slug}.png`에도 1장씩 둡니다.

**이관할 때 반드시 걸리는 것 1가지 — 문의 카드 링크**

NIGHT에서 만든 상품 하단 문의 카드는 `../misa-1116/form.html`을 가리킵니다. 그 폴더는 **`K0612766940K-` 저장소에만 있고 실서비스 `oneclick` 저장소에는 없습니다**(확인 완료). 그대로 옮기면 문의 링크가 404가 됩니다.

→ `apply.ps1`과 `README.md`에 이관 시 함께 바꿀 1줄을 명시하세요: 문의 카드 링크를 실서비스에 있는 경로로 바꾼다(`https://autooneclick.com/#reserve` 사전예약, 또는 `sign/`처럼 기존 상품이 쓰는 방식). 상품 5개 각각에서 그 문자열이 몇 곳 나오는지 세어 `선별_5종.md`에 적고, 검수표 '문의 폼' 칸은 **바꾼 뒤 살아 있는 링크**를 기준으로 판정합니다.

### 완료 판정

- [ ] 7개 파일 존재, 5종 모두 캡처 파일이 실제로 있다
- [ ] `products_추가분.js` 구문 오류 0 (`node --check` 가능하면 그것으로, 없으면 브라우저 콘솔에서 `eval` 없이 문법 검사)
- [ ] `copy_manifest.json`의 10개 `from` 경로가 **전부 실재**(PowerShell `Test-Path` 10/10)
- [ ] 문의 카드 `../misa-1116/form.html` → 실서비스 경로로 바꾸는 1줄이 `apply.ps1`·`README.md`에 적혀 있다(5종 각 몇 곳인지 숫자로)
- [ ] 검수표 5행 모두 값이 채워져 있고 FAIL 0
- [ ] `oneclick` 저장소 `git status` — **이 과업 때문에 바뀐 파일 0개**
- [ ] README만 읽고 사람이 3단계로 이관할 수 있다

---

## 4. 과업 3 — 상황판 최신화 (`oneclick/ops/status.json`)

`departments` 안의 **`id:"pc"`(PC 클로드 코드팀) 항목만** 고칩니다. `chief`·`notice`·다른 부서 4개는 **한 글자도 건드리지 않습니다.**

**지금 상태(잘못된 기록)**: `"blocked": "결과 회수 지연 — PC 절전/자동감시 점검 필요"`, doing `"지시서 63건 푸시 완료 · 밤새 결과 파일 0건 (PC 절전 의심)"` → **사실과 다릅니다. 실제로는 순차 실행·커밋됐습니다(75eda71, 72ed42d, NIGHT5 25종 완료).**

**넣을 값 (문구 그대로)**

```json
{
  "id": "pc",
  "name": "PC 클로드 코드팀",
  "sub": "야간 무인 생산",
  "icon": "monitor",
  "doing": [
    { "t": "원클릭 100선 실매출 5종 이관 패키지", "d": "NIGHT3~5 62종 중 5종 선별 · 파일·products.js 추가분·390px 검수표 완성 (쇼룸 등록은 대표님 검수 후)", "src": "11-20 새벽 · 지시서 20261120" }
  ],
  "todo": [
    { "t": "100선 이관 5종 쇼룸 등록", "d": "대표님 시연 통과 후 products.js·catalog.json에 5개 추가", "src": "관문 6" },
    { "t": "더통역 원본 404 해결", "d": "DESIGN 4앱 중 1앱이 아직 대기 — 원본 주소 확인 후 재빌드", "src": "NIGHT5 인수인계" },
    { "t": "bundle100 PDF 그림 미지원 보완", "d": "넣은 PDF는 안내문만 남음 — 그림으로 넣을지 결정 필요", "src": "NIGHT5 인수인계" }
  ],
  "done": [
    { "t": "야간 큐 5회차 회수 완료", "d": "NIGHT2·3·4·DESIGN·NIGHT5 결과 보고서 5건 도착 · 62종 웹앱·390px 캡처·설명서 완성", "src": "11-19·11-20" },
    { "t": "PC 절전 의심 기록 정정", "d": "결과 파일 0건은 오판 — 11-18 밤부터 순차 실행·커밋됨(75eda71 → 72ed42d)", "src": "11-20 확인" },
    { "t": "교환계약서 7곳 손질", "d": "명칭 (당사자용)·특약 줄맞춤·하단 표 A4 바닥까지 내림·회색 자필서명 제거·을 서명칸 정렬", "src": "적립 97번" }
  ]
}
```

- `blocked` 키는 **삭제**합니다(값이 참일 때만 화면에 표시되므로 지우면 사라집니다).
- `done`의 `교환계약서 7곳 손질`은 **(a)가 실제로 끝났을 때만** 넣습니다. 실패·부분이면 빼고 `todo`에 남깁니다.
- 파일 맨 위 `updated`를 실제 실행 시각으로, `updatedBy`를 **`"PC 클로드 코드팀 (지시서 20261120)"** 으로 바꿉니다.
- `ops/status.json`의 **다른 키는 그대로**. JSON이 유효해야 하며(`ConvertFrom-Json` 통과), `/ops/` 페이지 390px에서 부서 카드가 정상으로 그려지는 캡처 1장(`output\교환계약서_20261120\ops_390.png`)을 남깁니다.

---

## 5. 마무리 — 커밋·푸시 2곳, 결과 보고서

```powershell
# ① 실서비스 oneclick
cd $oc
git add contract/ tax.html organizer/index.html sign/index.html ops/status.json
git status --short        # 위 5개(와 필요한 산출물)만 바뀌었는지 확인
git commit -m "fix(더계약서·문구·상황판): 교환계약서 당사자용·특약 줄맞춤·하단 표 A4 바닥·회색 자필서명 제거·을 서명칸 정렬 / 표시광고 위험 문구 4곳 제거 / PC팀 상황판 정정"
git push

# ② 지시서·결과·패키지
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git add -A
git commit -m "docs: 2026-11-20 수리 3건 + 100선 실매출 5종 이관 패키지 + 결과 보고"
git push
```

- git 사용자 정보가 없어 커밋이 막히면, **저장소 기존 커밋의 작성자 정보를 이번 커밋에만** 지정합니다(`git -c user.name=… -c user.email=… commit`). `git config`는 바꾸지 않습니다.

### `CLAUDE_RESULT_20261120.md` 목차 (그대로 채운다)

1. **한 줄 요약** — 3과업 판정(완료/부분/실패)
2. **과업 1(a)** 표: 7가지 손질 · 각 판정 · 실측값(픽셀·%) · 바뀐 파일 · `before/after` 이미지 경로
3. **과업 1(b)** 표: 4개 파일 · 지운 문자열 · 남은 줄 내용 · `500,000` 잔존 0 확인 · 캡처 경로
4. **과업 1(c)** 동기화 diff(ⓐ~ⓓ) · versionCode/Name · APK 경로·크기·SHA256 · `apksigner verify` 원문
5. **과업 2** 5종 표 · 파일 7개 목록 · 검수표 요약 · 대체 후보를 썼다면 그 이유 · `oneclick` 저장소 무변경 확인(`git status` 원문)
6. **과업 3** `status.json` diff 요약 · `/ops/` 390px 캡처 경로
7. **커밋** — ① before 해시, ② 커밋 해시 2개(oneclick / K)
8. **막힌 것** — 원문 오류 그대로(없으면 `없음`)
9. **다음 회차 인수인계 3줄** — 남은 상품 8종(더블로그·더콘티·더포지션·더전단·더청구·더차계·더이사·더가정) / 공통 부품 위치 / 남은 이슈
10. 마지막 줄: **`남은 것: …`**

---

## 6. 순서 요약 (이대로 하면 됩니다)

1. 0단계 — 두 저장소 pull, `oneclick`·`app_viewer` 위치 확인
2. 과업 1(a) 교환계약서 7곳 → 1(b) 위험 문구 4곳 → 1(c) 더뷰 v1.4
3. 과업 2 — 5종 이관 패키지 + 390px 검수표
4. 과업 3 — `ops/status.json` 정정
5. 커밋·푸시 2곳 → `CLAUDE_RESULT_20261120.md` → 마지막 줄 `남은 것`

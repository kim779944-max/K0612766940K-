# PC 클로드 코드 작업 지시서 — 2026-11-23 · 더스캔 하단 셔터 버튼 고정 (적립 147번)

> 발령: 2026-11-23 18:4x KST · 사령관 지니 → PC 클로드 코드(Pro, `DESKTOP-02`)
> 대표님 지시 원문: **"더스캔도 올려놔"** (2026-11-23 18:4x) — 모바일 크롬·인앱 브라우저에서 **주소창·툴바 때문에 하단 셔터 버튼이 화면 밖으로 밀려 없어지는 문제** 수정.
> 대상: **`kim779944-max/oneclick` 의 `thescan/index.html` 단 한 파일.** `thescan/theeraser.html`·`theform/`·`index.html`(쇼룸)·`products.js`·`catalog.json`·`ux.js`·`helper.js`·`master.js` 는 손대지 않는다(제0원칙).
> 결과 보고서: **`CLAUDE_RESULT_20261123_THESCAN_SHUTTER.md`** (`K0612766940K-` 저장소에 작성·커밋·푸시)
> 기준선(2026-11-23 18:5x KST, 지니가 실제로 확인): `oneclick` **`042af4d`**(= `origin/main`, 뒤처짐 0) · `K0612766940K-` **`8de21ac`**(이 지시서가 올라간 커밋의 바로 앞)

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 0-1. 이번 회차 결과물 (한 문장)
**`autooneclick.com/thescan/` 에서 `[실시간 카메라]` 를 켠 뒤에도, 주소창·인앱 툴바가 화면을 잡아먹은 폰에서도, 카메라 프리뷰가 위아래로 줄어들 뿐 하단 셔터 영역(`flex-shrink:0`)은 스크롤 없이 화면 안에 100% 남아 있어 — `찍기` 를 찾아 스크롤할 일이 없다.**

### 0-2. 하지 않는 것 (하나라도 어기면 그 항목은 실패로 기록)

1. **제0원칙 — 웹 원본 카메라 + 확인창 구조를 그대로 유지한다.**
   - 불변: `detectQuad`·`shoelace`·`solve8`·`homography`·`warpDocument`·`sctx`·`coarseBackground`·`illumNormalize`·`scanFilter`(보정 파이프라인), `processFile`·`handleFiles`·`setProg`·`progDone`, `startAutoCapture`·`captureFromVideo`·`steady` 2프레임 자동촬영, `joinLong`·`joinPDF`·`buildPDF`·`download`·`hardDownload`·`saveToPhone`, 갤러리 `render`·`removeItem`, `openSheet`·`closeSheet`·`showResult`, 분리하기·전체 저장, `window.KTSApp` 브리지, `KTS_UX_CFG={tool:"thescan",wm:["#sheet"],flow:1}`.
   - 이번에 **명시적으로 바꾸는 것은 레이아웃 CSS 와 `body` 클래스 토글뿐**이다: ① 높이 기준 `vh` → `dvh`(+폴백) ② 촬영 중(`body.live`) `#app` 을 flex 열로 만들어 **프리뷰가 줄고 셔터가 고정** ③ 안전영역·도우미 버튼 자리 확보. **마크업·기능·문구는 추가 외 변경 없음.**
2. **외부 라이브러리·새 스크립트·새 도메인 0.** CSS·인라인 JS 만. `helper.js`·`ux.js` 를 수정하지 않는다(둘은 다른 도구가 같이 쓴다).
3. **다른 페이지 금지.** 이번에 바뀌는 파일은 `oneclick/thescan/index.html` **하나**.
4. **"카메라를 없애고 파일 선택만 두는" 식의 회피 금지.** `[찍기]`·`[사진첩에서]`·`[실시간 카메라]` 3개 버튼과 그 순서·문구를 유지한다. 문제를 버튼 삭제로 풀지 않는다.
5. **지어내기 금지.** 실기기에서 못 봤으면 "실기기 미확인"이라고 적는다. 390 캡처와 `getBoundingClientRect` 수치만 근거로 쓴다.
6. **관문 6 유지** — 대표님 직접 시연 전 대외 판매·광고·문자 발송·스토어 업로드 0건. 이번 배포는 `autooneclick.com/thescan/` 반영까지다.
7. **되돌릴 수 있게** — 손대기 전 두 저장소의 `git rev-parse HEAD` 를 적어 두고 보고서 §1에 넣는다.
8. **실패는 원문 그대로** — 어떤 명령이 어떤 오류로 막혔는지 그대로 적는다.

### 0-3. 진행 규칙
- **A → B → C** 순서(§2~§4). 자동 실행기는 한 회차에 90분까지만 돈다 → 커밋하며 진행한다.
- **최소 합격선 = A(촬영 중 셔터 고정) + B(390 실측 3해상도)**. 한 항목이라도 못 하면 정직하게 남은 것을 적고 마지막 줄에 `남은 것: …`.

---

## 1. 0단계 — 저장소·현재 코드·실측 기준선 (25분)

### 1-1. 두 저장소 최신화
```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull --rebase; git rev-parse --short HEAD          # 이 지시서가 보여야 한다

cd ..\oneclick
git pull --rebase; git rev-parse --short HEAD           # 기대: 042af4d 이상
```
> **동시 작업 주의**: 더양식(146번) 지시서가 같은 회차 대기열에 있다. `oneclick` 커밋은 `git add thescan/index.html` 처럼 **이번 파일만** stage 한다(`git add -A` 금지). force-push 금지.

### 1-2. 지금 코드 지도 — `oneclick/thescan/index.html` (`042af4d` 판 · 825줄 · 단일 파일)
줄번호는 이 판 기준이다. CSS 는 한 줄에 몰려 있으니 **셀렉터로** 찾는다.

| 무엇 | 위치 | 지금 상태 |
|---|---|---|
| `#app` | `~12-14` | `width:100%;max-width:430px;min-height:100vh;padding-bottom:34px` — **`100vh`(큰 뷰포트) 기준** |
| `header` | `~15-16` | `position:sticky;top:0;z-index:20;padding:11px 14px` (실측 높이 **47px**) |
| `.cap` (촬영 카드) | `~21` | `margin:12px 14px 0;border-radius:16px;overflow:hidden` |
| `.capbox` | `~22` | `height:196px` · `overflow:hidden` · `transition:height .25s` |
| `.capbox.live` | `~23` | **`height:58vh`** ← 이 값이 셔터를 밀어낸다 |
| `#capnow` (인식 안내 알약) | `~30-31` | `bottom:10px` (프리뷰 안) |
| `.capacts` (셔터 영역) | `~37` | `padding:11px 12px 13px;display:grid;gap:8px` — **flex-shrink 개념 없음** |
| `#btnShoot`·`#btnFile`·`#btnLive` | `~129-132` | `.btn.big`(padding 15px → **높이 실측 54px**) + `.row2` 2버튼 |
| `.foot-hint` | `~45` | `margin:9px 2px 0` 안내 1줄 |
| `#prog` | `~49-55` | 보정 진행 카드(촬영 카드 **아래**) |
| `.gal` (내 스캔) | `~57-70` | 갤러리·`[연결하기]`·`[분리하기]` |
| `#btnLive` 핸들러 | `~761-773` | `getUserMedia` → `v.play()` → `$('#capbox').classList.add('live')` → `$('#btnLive').innerHTML='…실시간 끄기'` → `startAutoCapture()` |
| `stopLive()` | `~774-778` | `clearInterval` → `stream.stop()` → `capbox` 에서 `live` 제거 |
| `startAutoCapture()` | `~779-820` | 260ms 간격 `detectQuad` → `steady===2` 면 자동 촬영 |
| 공통 UX | `~821-825` | `KTS_UX_CFG` + `ux.js` + `helper.js` (**도우미 버튼 주의**: 모바일에서 `position:fixed;left:10px;bottom:calc(10px + env(safe-area-inset-bottom));width:48px;height:48px;z-index:240`) |

### 1-3. 지금 상태 실측 (지니가 2026-11-23 18:4x 에 번들 Chrome 131 헤드리스로 잰 값 — 그대로 재현해 보고 다르면 보고서에 적는다)
뷰포트 폭 390 · `#btnShoot` 의 `getBoundingClientRect()`:

| 뷰포트 | 모드 | 셔터 top | 셔터 bottom | 셔터 높이 | 프리뷰 높이 | 페이지 총높이 | 화면 안 |
|---|---|---|---|---|---|---|---|
| 390×844 | 기본 | 290.5 | 344.5 | 54 | 196 | 844 | ✅ |
| 390×844 | 실시간 | **584** | **638** | 54 | 489.5 | **1022** (스크롤 필요 178px) | ✅ (여유 206px) |
| 390×740 | 실시간 | 523.7 | 577.7 | 54 | 429.2 | 962 | ✅ (여유 162px) |
| 390×640 | 실시간 | 465.7 | 519.7 | 54 | 371.2 | 904 | ✅ (여유 120px) |

**원인(구조)**: 지금 화면은 `고정 px(머리 47 + 촬영카드 여백 12 + 셔터영역 약 197 ≈ 256) + 58vh` 로 셔터 위치가 정해진다. 셔터 하단 ≈ `220 + 0.58 × (레이아웃 높이)`. 그런데 **`vh` 는 주소창이 숨은 "큰 뷰포트" 기준**이고, 실제 보이는 높이는 `레이아웃 높이 − 툴바(크롬 56, 카카오·네이버 인앱 100~140)` 다. 그래서 여유 = `0.42 × H − 220 − 툴바` → **H=844 · 툴바 120 이면 여유 14px, 툴바 140 이면 −6px(밀림)**. 인앱 브라우저일수록, 아래 여백이 큰 폰일수록 셔터가 화면 밖으로 나간다. 또 촬영 중에는 `.gal`·`#prog` 이 뒤에 남아 **페이지가 178px 스크롤**되므로, 한 번 스크롤하면 셔터를 다시 찾아야 한다.
> 이 절의 숫자를 보고서 §2에 **"전"** 값으로 옮겨 적는다.

### 1-4. 고치기 전 캡처
`https://autooneclick.com/thescan/?t=<타임스탬프>` 를 **390×844** 로 열고
1. 기본 상태 1장 → `output/thescan_shutter_20261123/before_390_static.png`
2. `[실시간 카메라]` 를 눌러 프리뷰를 띄운 뒤 1장(카메라가 없으면 콘솔에서 `document.querySelector('#capbox').classList.add('live')`) → `before_390_live.png`
3. **인앱 툴바 재현 컷**: 같은 화면에서 콘솔로 하단에 128px 검은 띠를 덧그려 캡처 →
   ```js
   const tb=document.createElement('div');
   tb.style.cssText='position:fixed;left:0;right:0;bottom:0;height:128px;background:rgba(0,0,0,.85);z-index:999;pointer-events:none';
   document.body.appendChild(tb);
   ```
   → `before_390_live_toolbar128.png` (셔터가 띠에 가려지는 것이 "전" 근거)

---

## 2. A. 촬영 중 셔터 고정 (핵심)

> **원칙**: 셔터가 화면에 있는지를 **`vh` 계산에 맡기지 않는다.** 촬영 중에는 화면을 **한 장의 flex 열**로 만들고, **프리뷰가 남는 높이를 전부 차지하며 줄어들고(`flex:1;min-height:0`), 셔터 영역은 절대 줄지 않는다(`flex-shrink:0`)**. 높이 기준은 **`dvh`(지금 보이는 화면)** 로 바꾼다.

### 2-1. CSS — 이 블록을 그대로 넣는다(셀렉터·값을 바꾸지 말 것)
```css
/* ① 높이 기준을 '지금 보이는 화면'으로 (dvh 미지원 브라우저는 vh 로 폴백) */
html,body{height:100%}
#app{min-height:100vh;min-height:100dvh;padding-bottom:calc(18px + env(safe-area-inset-bottom,0px))}

/* ② 촬영 중(body.live) — 한 화면 고정 */
body.live{overflow:hidden;overscroll-behavior:none}
body.live #app{height:100vh;height:100dvh;min-height:0;max-height:100dvh;
  display:flex;flex-direction:column;overflow:hidden;
  padding-bottom:calc(64px + env(safe-area-inset-bottom,0px))}   /* 64px = 도우미 버튼 자리 */
body.live header{flex:0 0 auto}
body.live .cap{flex:1 1 auto;min-height:0;display:flex;flex-direction:column;margin:10px 14px 0}
body.live .capbox.live{flex:1 1 auto;min-height:120px;height:auto}    /* 프리뷰만 줄어든다 */
body.live .capacts{flex:0 0 auto;margin-top:0}
body.live .foot-hint{flex:0 0 auto;margin-bottom:0}
body.live .gal,body.live #prog{display:none}                           /* 촬영 중엔 스크롤할 것이 없다 */
```
- `.capacts` 에 `flex-shrink:0` 을 **명시**한다. `#btnShoot` 높이 54px·`row2` 44px·`foot-hint` 1줄은 **줄이지 않는다**.
- `.capbox` 의 `transition:height .25s` 는 flex 높이 전환에서 어색하게 튈 수 있다 → `body.live .capbox{transition:none}` 을 추가한다(기본 상태 전환은 유지).
- **`100dvh` 를 지원하지 않는 브라우저**(옛 웹뷰)는 `100vh` 폴백으로 지금과 같게 동작한다 — 기능이 죽지 않는다.
- `.cap` 의 `overflow:hidden`·`border-radius:16px` 는 유지(프리뷰가 둥근 모서리 밖으로 새지 않게).

### 2-2. JS — `body.live` 토글 (3곳만)
1. `#btnLive` 핸들러: `stream` 을 얻고 `await v.play()` **성공한 뒤**
   `document.body.classList.add('live');` 를 `$('#capbox').classList.add('live')` 바로 옆에 넣는다. **카메라 실패 경로(`catch`)에서는 절대 넣지 않는다**(실패하면 지금처럼 토스트 + 셔터 그대로).
2. `stopLive()`: `document.body.classList.remove('live');` 를 맨 앞에 넣는다. `#btnLive` 라벨·`capbox.live` 제거는 그대로.
3. `#btnShoot`(찍기)은 **실시간 중에도 그대로 동작**한다(수동 셔터). `captureFromVideo()` 가 아니라 지금처럼 파일 입력을 연다 — **바꾸지 않는다.**
4. 촬영 중 `[내 스캔]` 으로 가는 길: `body.live` 상태에서 갤러리가 숨겨지므로, `stopLive()` 를 부르는 것은 지금과 동일하게 `[실시간 끄기]` 다. **자동으로 꺼지게 만들지 않는다**(자동 촬영이 계속 돌아야 한다).

### 2-3. 도우미 버튼과 겹치지 않게
- `helper.js` 의 `#kts-helper-btn` 은 **왼쪽 아래 10px·48×48·z-index 240 고정**이다. 셔터가 화면 맨 아래로 내려오면 왼쪽 58px 을 덮어 **찍기가 안 눌린다.**
- 위 CSS 의 `body.live #app{padding-bottom:calc(64px + 안전영역)}` 이 그 자리를 비워 둔다 → 셔터 하단이 항상 도우미 버튼 위에 온다. **이 64px 을 줄이지 말 것**(줄이면 겹침).
- `helper.js` 는 **수정 금지**. 자리만 비켜 준다.

### 2-4. 손대지 않는 것
- 프리뷰 위 인식 안내(`#capnow`) 위치·문구, 자동 촬영 2프레임 규칙, 보정 파이프라인, 갤러리·연결/분리/PDF, 다운로드, 토스트, 시트.
- 기본(비촬영) 상태의 화면 순서: 머리 → 안내 띠(`.kux-free`, ux.js) → 촬영 카드 → 보정 카드 → 내 스캔. **스크롤 가능한 긴 페이지 그대로**(촬영 중에만 잠근다).

---

## 3. B. 검증 — 390×844 실물 + 셔터 사각형 실측

### 3-1. 측정 스크립트 (콘솔에 그대로 붙여 넣고 결과를 보고서에 적는다)
```js
(()=>{ const r=document.querySelector('#btnShoot').getBoundingClientRect();
  const vv=window.visualViewport;
  const H=vv?vv.height:innerHeight;
  const pts=[0.15,0.5,0.85].map(f=>{const x=r.left+r.width*f, y=r.top+r.height/2;
    const el=document.elementFromPoint(x,y); return el? (el.closest('#btnShoot')?'btnShoot':(el.id||el.className)) : 'none';});
  return {mode:document.body.classList.contains('live')?'live':'static',
    vh:innerHeight, vvH:Math.round(H),
    top:+r.top.toFixed(1), bottom:+r.bottom.toFixed(1), h:+r.height.toFixed(1),
    inside:(r.top>=0 && r.bottom<=H+0.5),
    aboveToolbar128: r.bottom <= H-128,
    scrollH:document.documentElement.scrollHeight,
    noScroll: document.documentElement.scrollHeight <= H+1,
    topmost:pts};
})()
```

### 3-2. 합격 기준 (숫자로 적는다)
| 항목 | 조건 | 기대 |
|---|---|---|
| 가로 넘침 | `document.documentElement.scrollWidth` @390 | **390** |
| 실시간 셔터 높이 | `h` | **≥ 48** (지금 54 유지) |
| 실시간 셔터 화면 안 | `inside` | **true** — 390×844 · 390×716 · 390×640 · 390×560 **모두** |
| 인앱 툴바 128px 가정 | `aboveToolbar128` | **true** (셔터 하단이 화면 높이−128 위) |
| 촬영 중 스크롤 없음 | `noScroll` | **true** (지금은 178px 스크롤 필요) |
| 프리뷰 최소 높이 | `.capbox` `rect.height` (live) | **≥ 120px** (390×560 에서도) |
| 셔터 탭 대상 | `topmost` 3점 | **전부 `btnShoot`** (도우미 버튼·툴바 띠에 안 가림) |
| 기본 상태 회귀 없음 | 390×844 static | 셔터 `top ≈ 290` (전후 ±8px) |
| 카메라 실동작 | `[실시간 카메라]` → 3초 | `.capbox.live` + `body.live` · 자동 촬영으로 갤러리 1장 · 콘솔 에러 0 |
| 카메라 실패 경로 | `getUserMedia` 거부(권한 차단) | 토스트 `카메라를 열 수 없습니다 → 찍기 버튼을 써 주세요` · `body.live` 안 붙음 · 레이아웃 그대로 |
| 실시간 끄기 | `[실시간 끄기]` | `body.live` 제거 · 갤러리 다시 보임 · 스크롤 정상 |
| 기존 기능 | 연결하기(2장→긴 이미지 / PDF) · 분리하기 · 전체 저장 각 1회 | 지금과 동일 |
| 넓은 화면 | 1280×800 | `#app` 430 중앙 · 촬영 중 셔터 화면 안 · 좌우 넘침 0 |
| 외부 요청 | Network | 새 도메인 **0건** |

### 3-3. 캡처 (전부 `output/thescan_shutter_20261123/`)
`before_390_static.png` · `before_390_live.png` · `before_390_live_toolbar128.png` · `after_390_static.png` · `after_390_live.png` · `after_390_live_toolbar128.png` · `after_390_live_716.png`(툴바 높이를 흉내낸 716 뷰포트) · `after_390_live_560.png`.
- 각 캡처에서 **셔터가 잘리지 않았는지 눈으로 한 번 더** 확인하고 한 줄로 적는다.
- **실기기 캡처(대표님 Android Chrome·카카오톡 인앱)는 가능하면 넣고, 못 했으면 "실기기 미확인 · 헤드리스 390 실측으로만 검증"이라고 정확히 적는다.**

### 3-4. 게이트(`kts_gate`) — **FAIL 0 필수**
```powershell
copy output\slope_ui_20261123\src\gate_slope.ps1 output\thescan_shutter_20261123\src\gate_thescan.ps1
powershell -ExecutionPolicy Bypass -File output\thescan_shutter_20261123\src\gate_thescan.ps1 -File "..\oneclick\thescan\index.html"
```
- 기대: **FAIL 0** — `G1-1` 파일 존재 · `G1-2` HTML 구조 · `G1-4` 모달/시트 닫기 · `G1-6` 실명 노출 0 · `G1-7` 원가·내부문구 0 · `G1-9` viewport 메타(`viewport-fit=cover` 유지).
- 출력 전문 → `output/thescan_shutter_20261123/gate.txt`, **전/후 FAIL 수** 비교.

### 3-5. 라이브 반영 확인
```powershell
curl.exe -s "https://autooneclick.com/thescan/?t=$(Get-Date -Format s)" | Select-String "body.live"
curl.exe -s "https://autooneclick.com/thescan/?t=$(Get-Date -Format s)" | Select-String "100dvh"
```
- 둘 다 잡히면 반영 완료. 안 잡히면 `?t=` 바꿔 3회 재확인 후 **"안 떴다"** 고 적는다.

---

## 4. 결과 보고서 `CLAUDE_RESULT_20261123_THESCAN_SHUTTER.md` (이 틀 그대로)

```
# 결과 — 2026-11-23 더스캔 하단 셔터 버튼 고정 (147번)
시작 HEAD: oneclick <sha> / K0612766940K- <sha>
끝   HEAD: oneclick <sha> / K0612766940K- <sha>
커밋: <해시·메시지>

## 1. 저장소·기준
- 두 저장소 pull 결과: <sha> · 충돌 <있음/없음>

## 2. 원인과 바꾼 것
- 원인: 고정 px 220 + 58vh(큰 뷰포트) → 실제 보이는 높이(툴바 56~140 차감)와 어긋남 · 촬영 중 페이지 178px 스크롤
- 바꾼 것: #app 100dvh(+vh 폴백) · body.live flex 열 · .capbox.live flex:1/min-height:0 · .capacts flex-shrink:0 · .gal/#prog 숨김 · padding-bottom 64px(도우미 자리)
- 안 바꾼 것: 카메라·보정·자동촬영·PDF·다운로드·시트·ux.js/helper.js

## 3. 실측 (390)
| 뷰포트 | 모드 | top | bottom | h | inside | aboveToolbar128 | noScroll | 프리뷰높이 |
|---|---|---|---|---|---|---|---|---|
| 390×844 | live | | | | | | | |
| 390×716 | live | | | | | | | |
| 390×640 | live | | | | | | | |
| 390×560 | live | | | | | | | |
| 390×844 | static | | | | | | | |
- topmost 3점: <btnShoot/btnShoot/btnShoot>

## 4. 동작
- 실시간 카메라 실동작 <됨/안 됨> · 자동 촬영 <1장> · 끄기 후 복귀 <확인>
- 권한 거부 경로 <확인> · 연결/분리/전체저장 <확인> · 1280×800 <확인>
- 실기기(대표님 Chrome/카톡 인앱): <확인/미확인>

## 5. 캡처
- output/thescan_shutter_20261123/ <n>장 (before 3 / after 5)

## 6. 게이트
- kts_gate: 전 FAIL <n> → 후 FAIL <n> · gate.txt (사용한 게이트: <이름>)

## 7. 라이브
- /thescan/ 'body.live' <뜸/안 뜸> · '100dvh' <뜸/안 뜸>

## 대표님 확인 필요
1) 폰 크롬에서 [실시간 카메라] 켰을 때 찍기 버튼이 바로 보이는지
2) 카카오톡으로 링크 열었을 때도 같은지
3) 프리뷰가 너무 작아지지 않는지(작으면 min-height 120 → 150 으로 한 번만 올린다)
```

보고서도 `K0612766940K-` 에 `git add → commit → push`, 캡처는 `output/thescan_shutter_20261123/` 에 함께 커밋한다.

---

## 5. 한 문장 목표

**`autooneclick.com/thescan/` 에서 `[실시간 카메라]` 를 켠 순간부터, 주소창·인앱 툴바가 화면을 잡아먹은 폰에서도 카메라 프리뷰만 줄어들고 `찍기` 버튼은 스크롤 없이 화면 안에 그대로 남아 있다 — 카메라·보정·자동촬영·PDF 는 한 줄도 바뀌지 않은 채로.**

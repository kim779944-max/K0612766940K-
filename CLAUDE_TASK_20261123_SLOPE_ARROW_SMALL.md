# PC 클로드 코드 작업 지시서 — 2026-11-23 · 경사도 화살표 = 항공사진 위에 작게 (적립 144번)

> 발령: 2026-11-23 18:4x KST · 사령관 지니 → PC 클로드 코드(Pro)
> 대표님 지시 원문(2026-11-23 18:37 KST):
> - **"경사도 화살표를 찍으면 화살표를 제외한 나머지는 항공사진으로 또렷이 보여야 함."**
> - **"화살표도 필요 이상으로 큼."**
> 대상: **`kim779944-max/oneclick` 의 `slope/index.html` 단 한 파일.** 쇼룸·`products.js`·`catalog.json`·`slots.js`·`helper.js`·`viewer.html`·`listing/` 등 **다른 파일 0건**(제0원칙).
> 결과 보고서: **`CLAUDE_RESULT_20261123_SLOPE_ARROW_SMALL.md`** (`K0612766940K-` 저장소에 작성·커밋·푸시)
> 기준선(2026-11-23 18:4x KST, 지니가 실제로 확인): `oneclick` **`042af4d`** · `K0612766940K-` **`53de1f2`**
> 앞 회차: **137번 `CLAUDE_TASK_20261123_SLOPE_UI_PRINT.md` 완료(`631fa3a`)** — 조작부 정돈·A4 인쇄·이미지 저장이 **이미 들어가 있다.** 이 지시서는 **그 판 위에** 얹는다.

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 0-1. 이번 회차 결과물 (한 문장)
**`[화살표]` 를 누르면 지도가 자동으로 항공사진(위성)으로 바뀌고 경사색·픽셀 채색이 꺼져 화살표 말고는 전부 실제 항공사진이 또렷하게 보이며, 화살표는 밑변 4.2px·길이 6.5~7.5px·줄기 1.1px·케이싱 0.8px 로 가늘어져 항공사진을 가리지 않는다 — 계산·색판·Vworld 키·A4 인쇄·조작부 정돈은 한 글자도 바뀌지 않은 채로.**

### 0-2. 하지 않는 것 (하나라도 어기면 그 항목은 실패로 기록)

1. **제0원칙 — 바꾸는 것은 아래 3가지뿐이다.**
   ① 화살표 보기로 들어올 때의 **층 상태 자동 정리**(§2)
   ② `drawSlopeArrows()` 의 **화살표 치수·케이싱**(§3)
   ③ `.arrow-note` **설명문 1문장**과 `AR_LAST` **검수 메타 숫자**(§3-6)
   - **불변(한 글자도 손대지 않는다)**: `sampleGrid()` · `analyze()` · `elevAt()` · `bandOf()` · `verdictOf()` · `buildPx()` · `pxStatData()` · `pxStatHTML()` · `pctOf()` · `dirName()` · `SLOPE10` 10단계 색판과 hex 값 · `RAMP/PX_BANDS` · `ZMIN/ZMAX` · `DEFAULT_VW_KEY` · 하루 3건 무료·이용권 규칙·미리보기 워터마크 · 137번 산출물(`#advBox` 접힘·`#printA4`·`#saveImg`·`#printSheet`·`printSheet()`·`exportPng()`·`@media print`·버튼 44/48px 배치) · **화살표 간격 로직**(`gapMin=16`·`blockPx/k*m`·`cap=900`).
2. **간격·밀도·색·방향 로직 변경 금지.** 화살표가 작아졌다고 **간격을 좁히거나(촘촘하게) 넓히지 않는다.** 방향(내리막 = 촉) 계산식 `ax=-(e1-e0)*mPerV …` 도 그대로 둔다. 이번 변경은 **모양·크기와 진입 시 층 상태**뿐이다.
3. **위성·경사색을 '잠그지' 않는다.** 화살표 진입 때 **한 번** 자동으로 켜고/끄는 것이고, 그 뒤 사용자가 `[위성]`·`[경사색]`을 직접 누르는 것은 **지금처럼 그대로 동작해야 한다**(매 프레임 강제로 되돌리는 감시 코드 금지).
4. **지도·조작부 회귀 금지.** `#mapcv` 높이 392px · 조작부 버튼 44px · 출력 48px · `#advBox` 기본 닫힘 · 상시 노출 버튼 10개 이하 — 137번 실측값 그대로 유지.
5. **지어내기 금지.** 캡처 없이 "작아졌다/또렷하다"고 쓰지 않는다. §4의 캡처·숫자로만 판정한다.
6. **관문 6 유지** — 대표님 직접 시연 전 대외 판매·광고·문자 발송·스토어 업로드 0건. 이번 배포는 `autooneclick.com` 반영까지.
7. **비밀값 커밋 금지** — `oneclick` 은 공개 저장소다. Vworld 키 원문·`C:\Users\...` 경로·PC 이름을 보고서에 쓰지 않는다.
8. **되돌릴 수 있게** — 손대기 전 두 저장소 `git rev-parse HEAD` 를 보고서 §1에 적는다(기대 `042af4d` / `53de1f2`).
9. **실패는 원문 그대로** — 어떤 명령이 어떤 오류로 막혔는지 그대로 적고, 우회했으면 무엇을 어떻게 우회했는지 적는다.

### 0-3. 진행 규칙
- **0(§1) → A(§2) → B(§3) → C(§4)** 순. 자동 실행기는 한 회차 90분까지만 돈다 → **§2·§3 끝날 때마다 커밋**해 다음 회차가 이어받게 한다.
- **최소 합격선 = A(자동 위성) + B(화살표 축소)** 둘 다. 하나만 되면 "반쪽"으로 정직하게 적는다.
- 이미 끝난 항목은 다시 만들지 않는다(재실행 시 이어서).

---

## 1. 0단계 — 저장소·현재 코드 (15분)

### 1-1. 두 저장소 최신화
```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\oneclick"
git pull --rebase; git rev-parse --short HEAD          # 기대: 042af4d 이상
cd ..\K0612766940K-
git pull --rebase; git rev-parse --short HEAD          # 기대: 53de1f2 이상
```
> **동시 작업 주의**: 자동 실행기가 다른 지시서(예: `SNS_UPGRADE`)를 돌리고 있을 수 있다. force-push 금지, 남의 커밋 되돌리기 금지. 원격이 앞서 있으면 `git pull --rebase` 후 **양쪽 변경을 살려서** 푸시한다.

### 1-2. 지금 코드에서 확인할 것 — `slope/index.html` (`042af4d` 판 · 3,022줄)
줄번호는 이 판 기준이다. 값이 다르면 **id·함수 이름으로** 찾는다.

| 부품 | 위치 | 지금 상태(이번에 건드리는 곳) |
|---|---|---|
| 보기 세그먼트 `#pxView` | ~401 | `[화살표(data-v="arrow")]` `[픽셀(data-v="px")]` — **화살표 진입로 ①** |
| 토글 `#togs` | ~405~410 | 등고선·격자·필지·**위성(`data-l="sat"`)** — 위성 버튼이 여기 있다 |
| 출력 줄 `.outrow` | ~411~414 | `#printA4` · `#saveImg`(137번 산출물 · **불변**) |
| 상세 설정 `#advBox` → `#togsAdv` | ~415~421 | **화살표(`data-l="arrow"`)**·경사색(`data-l="slope"`)·용도지역 — **화살표 진입로 ②** |
| `.arrow-note` | ~425 | "…화살촉이 크고 선이 굵어 폰에서도 방향이 한눈에 보입니다." ← **이번에 사실이 아니게 되는 문장** |
| `paintLegend()` | ~1528 | `#cbw`(색판 범례)·`#aleg`(화살표 범례)·`#opRow` 표시 제어 |
| `drawSlopeArrows()` | ~1098~1180 | 화살표 그리기 — **이번 변경의 본체** |
| 치수 상수 | ~1145 | `var len=clamp(9+s*0.12,9,13), hl=len*0.5, hw=3.6, tw=0.9;` |
| 케이싱 | ~1168~1172 | 밝은 테 `rgba(255,255,255,.88)` **4.2px** → 어두운 테 `#101A2B` **2.8px** → 본색 fill |
| 검수 메타 `AR_LAST` | ~1176~1178 | `lenPx:[9,13], headLen:[4.5,6.5], headW:7.2, tailW:1.8, casing:[4.2,2.8]` |
| `pxSetView(v)` | ~2920 | `v==='px'` 면 픽셀, 아니면 화살표. **위성·경사색은 손대지 않는다**(← 원인) |
| 화살표 토글 보조 리스너 | ~2930 | `#togsAdv [data-l="arrow"]` 클릭 시 픽셀만 끈다(위성·경사색 그대로) |
| 일반 토글 리스너 | ~1517 | `#togs button,#togsAdv button` → `S.lay[k]` 반전·`.on` 토글 — **이 리스너는 건드리지 않는다** |
| 타일 | ~606 / ~894 | `getTile(...,S.lay.sat?'sat':'map')` — 캐시 키가 `o/s`·`v/s` 로 분리됨. **위성은 Vworld 키 없이도 뜬다**(`#togs` 위성 버튼에 `.lk` 없음) |

### 1-3. 고치기 전 캡처 (이게 "전" 근거다)
390×844 로 `https://autooneclick.com/slope/?t=<타임스탬프>` 를 열고 ① 예시 칩 `가평 신하리` → 지형 계산 완료까지 대기 ② 상세 설정에서 `[화살표]` 켜기 ③ 화살표가 그려진 지도 카드만 캡처 → `output/slope_arrow_20261123/before_arrow_390.png` ④ 같은 화면을 지도 부분 **200×200 크롭 ×4배 확대** → `before_arrow_zoom.png` ⑤ `S.lay` 를 콘솔에서 출력해 적어 둔다(`{px,arrow,sat,slope}`).

---

## 2. A. `[화살표]` = 항공사진 위의 화살표 (자동 정리)

### 2-1. 만들 함수 (하나로 모은다)
`pxSetView()` 와 화살표 토글 리스너가 **같은 함수**를 부르게 한다. 새 함수 이름은 `arrowView()`.

```js
/* 화살표 보기 — 화살표 말고는 전부 실제 항공사진이 또렷하게 보이도록 층을 한 번 정리한다.
   (이후 사용자가 [위성]·[경사색]을 직접 누르는 것은 그대로 허용 — 감시·강제 복원 없음) */
function arrowView(){
  S.lay.px=0;        /* 픽셀 채색 OFF */
  S.lay.arrow=1;     /* 화살표 ON */
  S.lay.sat=1;       /* 위성(항공사진) ON — Vworld 키 불필요 */
  S.lay.slope=0;     /* 경사색 OFF — 색판이 항공사진을 덮지 않게 */
  /* 버튼 표시를 실제 상태에 맞춘다(4곳) */
  document.querySelectorAll('#pxView button').forEach(function(b){ b.classList.toggle('on', b.getAttribute('data-v')==='arrow') });
  var satB=document.querySelector('#togs button[data-l="sat"]');      if(satB)  satB.classList.toggle('on',true);
  var axB =document.querySelector('#togsAdv button[data-l="arrow"]'); if(axB)   axB.classList.toggle('on',true);
  var slB =document.querySelector('#togsAdv button[data-l="slope"]'); if(slB)   slB.classList.toggle('on',false);
  if(typeof pxShowTip==='function') pxShowTip(null);
  pxPaintNote(); paintLegend(); requestRender(); requestRender();
}
```
- **`#advOn`(상세 설정 "켜짐 n") 표시는 손대지 않는다** — `MutationObserver` 가 클래스 변화를 보고 알아서 다시 센다(137번 구현).
- `#cbw`(색판 범례)는 `paintLegend()` 가 `S.lay.slope` 를 보고 숨긴다. `#opRow`(경사 색 진하기)는 `~2881` 규칙이 `!S.lay.slope` 면 숨긴다. **두 곳 다 손대지 않는다** — 상태만 바꾸면 따라온다.
- 화살표 범례 `#aleg` 는 `S.lay.arrow` 로 켜진다(그대로).

### 2-2. 진입로 2곳을 이 함수로 바꾼다
1. **`pxSetView(v)`**(~2920):
```js
function pxSetView(v){
  if(v!=='px'){ arrowView(); return }        /* 화살표 보기 → 위성 ON·경사색 OFF·픽셀 OFF */
  S.lay.px=1; S.lay.arrow=0;
  document.querySelectorAll('#pxView button').forEach(function(b){ b.classList.toggle('on',b.getAttribute('data-v')==='px') });
  var ab=document.querySelector('#togsAdv button[data-l="arrow"]'); if(ab) ab.classList.toggle('on',false);
  pxShowTip(null); pxPaintNote(); paintLegend(); requestRender();
}
```
   (지금 코드의 `S.lay.px=v==='px'?1:0; S.lay.arrow=v==='px'?0:1;` 를 위 구조로 바꾸는 것 — **동작 결과는 같고 자동 정리만 더해진다**.)
2. **화살표 토글 보조 리스너**(~2930): 지금은 `if(S.lay.arrow&&S.lay.px){S.lay.px=0; …}` 만 한다. 이걸 아래로 바꾼다.
```js
(function(){ var ab=document.querySelector('#togsAdv button[data-l="arrow"]'); if(!ab) return;
  ab.addEventListener('click',function(){
    if(S.lay.arrow){ arrowView(); }                 /* 방금 켜졌다 → 위성 ON·경사색 OFF */
    else { /* 끌 때: 보기 표시만 지금 규칙대로 되돌린다(자동 정리 취소 없음) */
      document.querySelectorAll('#pxView button').forEach(function(b){ b.classList.toggle('on', b.getAttribute('data-v')===(S.lay.px?'px':'arrow')) });
      pxPaintNote(); paintLegend(); requestRender() }
  }) })();
```
   - **주의**: 일반 토글 리스너(~1517)가 먼저 실행돼 `S.lay.arrow` 를 이미 반전시킨 뒤 이 리스너가 돈다(등록 순서). 그래서 위 코드는 **다시 반전시키지 않고 상태를 읽기만** 한다.
   - 화살표를 **끌 때**는 위성·경사색을 **되돌리지 않는다**(사용자가 켜 둔 상태 존중).

### 2-3. 결과 상태(합격 기준)
`[화살표]`(두 진입로 어느 쪽이든) 누른 직후 콘솔에서:
```js
JSON.stringify({px:S.lay.px,arrow:S.lay.arrow,sat:S.lay.sat,slope:S.lay.slope})
// 기대: {"px":0,"arrow":1,"sat":1,"slope":0}
```
그리고 화면에서: ① 지도가 **항공사진**(건물·수목·그림자 보임) ② 경사색 색판·10단계 색칠·픽셀 격자 **없음** ③ `#cbw` 숨김 ④ `#opRow` 숨김 ⑤ `#aleg`(화살표 범례) 보임 ⑥ `[위성]` 버튼 오렌지 켜짐.

### 2-4. 수동 토글이 계속 살아 있는지(필수 확인)
화살표 상태에서 `[위성]` 한 번 → 항공사진이 일반 지도로 바뀐다(그리고 **되돌아오지 않는다**). `[경사색]` 한 번 → 색판이 다시 덮인다(허용). 이 두 가지를 캡처 2장으로 남긴다(`manual_sat_off.png`·`manual_slope_on.png`).

---

## 3. B. 화살표 치수 — 필요 이상으로 큰 것을 날렵하게

### 3-1. 바꿀 숫자 (이 표의 값으로 고정)

| 요소 | 지금 | **바꿀 값** | 코드 |
|---|---|---|---|
| 화살촉 밑변(전체 폭) | 7.2px | **4.2px** | `hw = 2.1` |
| 화살촉 길이 | 4.5~6.5px | **3.5~4.5px** | `head = clamp(3.5 + s*0.025, 3.5, 4.5)` (s=경사°) |
| 줄기 폭 | 1.8px | **1.1px** | `tw = 0.55` |
| 줄기 꼬리 길이 | 4.5~6.5px | **3.0px 고정** | `tail = 3.0` |
| 총 길이(촉 꼭짓점 ~ 줄기 끝) | 9~13px | **6.5~7.5px** | `L = head + tail` |
| 밝은 테(케이싱) | 4.2px | **1.6px** (본색이 안쪽 절반을 덮어 **실제 노출 0.8px**) | `lineWidth=1.6` |
| 어두운 테 | 2.8px | **없앤다** — 단 아래 3-3 규칙 | — |
| 화살표 개수·간격 | gap≥16px · cap 900 | **그대로(바꾸지 않는다)** | — |

### 3-2. 그리기 골격 (지금 코드의 7점 path 를 이 배치로 바꾼다)
지금은 `x,y` 를 중심으로 `len` 을 좌우 대칭 배치한다. 새로는 **촉 꼭짓점(tip)과 꼬리 끝(end)을 먼저 잡고** 그 사이에 밑변을 놓는다.

```js
/* 화살촉 밑변 4.2px · 촉 길이 3.5~4.5px · 줄기 1.1px · 꼬리 3.0px (2026-11-23 144번) */
var head = clamp(3.5 + s*0.025, 3.5, 4.5), tail = 3.0, L = head + tail;
var hw = 2.1, tw = 0.55;
var px2 = -ay, py2 = ax;                       /* 진행방향 수직 단위벡터 */
var tX = x + ax*L*0.5,  tY = y + ay*L*0.5;     /* 촉 꼭짓점 — 내리막 */
var eX = x - ax*L*0.5,  eY = y - ay*L*0.5;     /* 줄기 끝 — 오르막 */
var nX = tX - ax*head,  nY = tY - ay*head;     /* 촉 밑변 중심 */
Q.moveTo(eX + px2*tw, eY + py2*tw);
Q.lineTo(nX + px2*tw, nY + py2*tw);
Q.lineTo(nX + px2*hw, nY + py2*hw);
Q.lineTo(tX, tY);
Q.lineTo(nX - px2*hw, nY - py2*hw);
Q.lineTo(nX - px2*tw, nY - py2*tw);
Q.lineTo(eX - px2*tw, eY - py2*tw);
Q.closePath();
```
- **촉이 전체 길이의 절반 이상**을 차지해야 방향이 읽힌다(밑변 4.2 · 촉 3.5~4.5 · 꼬리 3.0). 이 비율을 깨지 않는다.
- `clamp()` 는 기존 함수 그대로 쓴다(새로 만들지 않는다).

### 3-3. 케이싱 — 얇게, 그러나 10색 전부 보이게
| 경사 단계 | 테 | 이유 |
|---|---|---|
| **0~2단계**(흰·연노랑·노랑) | **어두운 테** `rgba(16,26,43,.92)` `lineWidth=1.6` | 밝은 항공사진 위에서 흰 화살표가 묻히기 때문 |
| **3~9단계** | **밝은 테** `rgba(255,255,255,.92)` `lineWidth=1.6` | 어두운 수목·그림자 위에서도 윤곽이 서게 |

- **2.8px 어두운 테를 전 단계에 두 겹으로 긋던 것을 없앤다**(굵어 보이던 주범).
- 스트로크는 **테 1겹만**, 그 위에 본색 `fill` — 지금 코드처럼 `stroke` → `stroke` → `fill` 3단이 아니라, 단계별로 테 색을 골라 `stroke` 1회 → `fill` 1회.
  기존 구조를 최대한 살리려면 `Path2D` 를 `P[band]`(10개)에서 **`Pw`(밝은 테 7개: 3~9) / `Pd`(어두운 테 3개: 0~2)** 2벌로 나눠 긋는 방식이 가장 적은 수정이다. 어느 쪽이든 **결과 픽셀**이 §4 기준을 만족하면 된다.

### 3-4. 지켜야 할 것
- **방향**: 촉 = 내리막(물이 흘러내리는 쪽). 지금 계산식 그대로.
- **색**: `SLOPE10[band].hex` 10색만. 새 색·그라데이션·불투명도 변경 금지.
- **간격**: `gapMin=16` · `blockPx/k*m` · `cap=900` · 월드 격자 고정 — **한 줄도 바꾸지 않는다.**
- **필지 클립**: `clip(clip,'evenodd')` 유지.
- **검수용 샘플 `AR_SAMP`**: 지금은 `ins(tX+ax*2.5,…)`·`nX±px2*5.7` 로 화살표가 클 때의 바깥 여백을 본다. **작아진 만큼 여백도 줄인다** — 촉 여백 `+ax*1.6`, 꼬리 여백 `-ax*1.6`, 밑변 여백 `±px2*3.2`. (검수 함수가 화살표보다 커서 샘플이 0개가 되면 안 된다.)

### 3-5. `AR_LAST` 메타 갱신 (~1176)
```js
lenPx:[6.5,7.5], headLen:[3.5,4.5], headW:4.2, tailW:1.1, casing:[1.6], cap:900, gapMin:16
```
`window.__KTS_AR` 같은 노출이 이미 있으면 그대로 두고, 없으면 **`window.__KTS_AR=function(){return AR_LAST}`** 한 줄만 추가한다(검증용 · 화면·동작 영향 0). `AR_SAMP` 도 그대로 유지.

### 3-6. `.arrow-note` 문장 1개만 고친다 (~425)
- 지금: `… 화살촉이 크고 선이 굵어 폰에서도 방향이 한눈에 보입니다.`
- 바꿀 문장: `… 화살표는 항공사진을 가리지 않게 가늘게 그립니다. 화살표를 켜면 지도가 항공사진으로 바뀌고 경사색은 함께 꺼집니다.`
- **나머지 문장·`<b>` 강조·10단계 색 설명은 그대로 둔다.**

---

## 4. C. 검증 — 390 실측·캡처·게이트

### 4-1. 390×844 실측 (숫자로 적는다)
| 항목 | 방법 | 기대 |
|---|---|---|
| 층 상태 | `[화살표]` 클릭 후 `S.lay` | `px0 · arrow1 · sat1 · slope0` |
| 위성 버튼 표시 | `#togs [data-l="sat"]` classList | `on` 포함 |
| 경사색 버튼 표시 | `#togsAdv [data-l="slope"]` | `on` 없음 |
| 색판 범례 | `#cbw` computedStyle.display | `none` |
| 진하기 줄 | `#opRow` display | `none` |
| 화살표 범례 | `#aleg` display | `flex` |
| 항공사진 | 타일 요청 URL 중 `arcgisonline`(sat) 비중 | 지도 타일 **전부 sat** (map 타일 0건) — Network 패널로 확인 |
| 화살표 치수 | `__KTS_AR()` | `headW 4.2 · tailW 1.1 · headLen 3.5~4.5 · lenPx 6.5~7.5 · casing [1.6]` |
| 화살표 개수 | `__KTS_AR().n` | 변경 전과 **같은 자릿수**(간격을 안 바꿨으므로 ±10% 이내) |
| 수동 토글 | `[위성]` off → `[경사색]` on | 즉시 반영 · 저절로 되돌아가지 않음(캡처 2장) |
| 가로 넘침 | `document.documentElement.scrollWidth` | **390** |
| 지도 높이 | `#mapcv` rect.height | **392 ± 1** |
| 조작부 버튼 | 지도 아래 상시 노출 버튼 최소 높이 | **≥44px**(출력 ≥48px) · 개수 **10개 이하**(137번과 동일) |
| A4 인쇄 회귀 | `[A4 인쇄]` → PDF 쪽수 | **1쪽** · 화살표 모드에서도 1쪽 |
| 이미지 저장 회귀 | `[이미지 저장]` | **1600×3022** PNG 생성 · 범례 포함 |
| 콘솔 | Chrome 콘솔 | **에러 0건** |
| 외부 요청 | Network | 새 도메인 **0건** |

### 4-2. 캡처 (합격 증거 · `output/slope_arrow_20261123/`)
1. `before_arrow_390.png` / `before_arrow_zoom.png` (§1-3)
2. `after_arrow_390.png` — `[화살표]` 켠 뒤 **지도 카드 전체**(항공사진 + 화살표)
3. `after_arrow_zoom.png` — 같은 자리 **200×200 크롭 ×4배**(화살표 모양·케이싱이 보이게)
4. `after_arrow_px.png` — `[픽셀]` 로 돌아간 화면(회귀 없음 증거)
5. `manual_sat_off.png` · `manual_slope_on.png` (§2-4)
6. `print_arrow_mode_1.png` — 화살표 모드에서 A4 인쇄 PDF 1쪽 렌더
7. **전/후 화살표 픽셀 실측**: 같은 지점 1개의 화살표 바운딩 박스를 잘라 낸 이미지 `arrow_px_before.png` / `arrow_px_after.png` (지도 캡처에서 ±12px 크롭 ×8배) — 대표님이 눈으로 크기 차이를 확인하는 자료다.

### 4-3. 게이트(`kts_gate`) — **FAIL 0 필수**
```powershell
python output/kts_gate.py .\oneclick\slope\index.html     # 없으면 python3 / 이식판(gate_multi.ps1)
```
- 기대: **FAIL 0** (전 회차와 같은 기준: `G1-1` 파일 존재 · `G1-2` HTML 구조 · `G1-4` 모달 닫기 · `G1-6` 실명 노출 0 · `G1-7` 원가·내부문구 0 · `G1-9` viewport).
- 출력 전문을 `output/slope_arrow_20261123/gate.txt` 로 저장하고 **전/후 FAIL 수**를 적는다(전 0 → 후 0).

### 4-4. 라이브 반영
```powershell
curl.exe -s "https://autooneclick.com/slope/?t=$(Get-Date -Format s)" | Select-String "가늘게 그립니다"
```
- 잡히면 반영 완료. 안 잡히면 `?t=` 바꿔 3회까지 재확인, 그래도 안 되면 **"안 떴다"** 고 적는다(추측 금지).

---

## 5. 결과 보고서 `CLAUDE_RESULT_20261123_SLOPE_ARROW_SMALL.md` (이 틀 그대로)

```
# 결과 — 2026-11-23 경사도 화살표 = 항공사진 위에 작게 (144번)
시작 HEAD: oneclick <sha> / K0612766940K- <sha>
끝   HEAD: oneclick <sha> / K0612766940K- <sha>
커밋: <해시·메시지>

## 1. 저장소·기준
- pull 결과 <앞/뒤 sha> · 바뀐 파일: slope/index.html 1개뿐(+n/−n줄) · 되돌리기: git revert <sha>

## 2. A. 화살표 = 항공사진 (자동 정리)
- 진입로 2곳(pxSetView / #togsAdv 화살표) 둘 다 arrowView() 로 통일: 확인/미확인
- 클릭 직후 S.lay: {px:<>,arrow:<>,sat:<>,slope:<>}
- 버튼 표시: #togs 위성 on <> · #togsAdv 화살표 on <> · 경사색 off <> · #cbw <> · #opRow <> · #aleg <>
- 지도 타일: sat <n>건 / map <n>건
- 수동 [위성] off → <결과> · 수동 [경사색] on → <결과> (캡처 경로 2장)
- 감시 코드(매 프레임 강제 복원) 없음: 확인

## 3. B. 화살표 치수
- 실측 __KTS_AR(): headW <> · tailW <> · headLen <> · lenPx <> · casing <>
- 화살표 개수 n: 전 <> → 후 <> (간격 로직 무변경 확인)
- 케이싱 규칙: 0~2단계 어두운 테 / 3~9단계 밝은 테 — 10색 전부 육안 확인: <>
- .arrow-note 문장 교체: 확인 · AR_LAST 갱신: 확인

## 4. 검증 숫자 (390×844)
- scrollWidth <> · #mapcv <> · 최소 버튼높이 <> · 상시 버튼 수 <> · 콘솔 에러 <> · 새 도메인 <>
- 회귀: A4 인쇄 <> 쪽 / 이미지 저장 <가로×세로>px
- 캡처 경로: before 2 / after 3 / manual 2 / print 1 / arrow_px 2

## 5. 게이트
- kts_gate: 전 FAIL <n> → 후 FAIL <n> · 출력 output/slope_arrow_20261123/gate.txt

## 6. 라이브
- /slope/ '가늘게 그립니다' <잡힘/안 잡힘>

## 건드리지 않은 것 (확인함)
- 계산·SLOPE10·Vworld 키·요금·이용권·미리보기 · 137번(조작부·A4 인쇄·이미지 저장) · 지도 392px · 화살표 간격 로직 · 다른 페이지 0건

## 대표님 확인 필요
1) 화살표를 켜면 항공사진이 또렷하게 보이는지
2) 화살표가 항공사진을 가리지 않을 만큼 작아졌는지(방향은 여전히 읽히는지)
3) 위성·경사색을 손으로 다시 켜고 끄는 게 그대로 되는지
```
보고서·캡처는 `K0612766940K-` 에 `git add → commit → push`. 캡처 폴더 `output/slope_arrow_20261123/` 도 함께 커밋.

---

## 6. 한 문장 목표

**`autooneclick.com/slope/` 에서 `[화살표]` 를 누르면 지도가 항공사진으로 바뀌고 경사색·픽셀 채색이 꺼져 화살표 말고는 전부 실제 항공사진이 또렷하며, 화살표는 밑변 4.2px·길이 6.5~7.5px·줄기 1.1px·케이싱 0.8px 로 날렵해져 사진을 가리지 않는다 — 계산·색판·키·간격·137번 산출물은 한 글자도 바뀌지 않은 채로.**

# PC 클로드 코드 작업 지시서 — 2026-11-23 · 더뷰 다중 첨부 30장+ · 보이는 그대로 그림/PDF 저장 (적립 145번)

> 발령: 2026-11-23 18:4x KST · 사령관 지니 → PC 클로드 코드(Pro)
> 대표님 지시 원문(2026-11-23 18:40 KST):
> - **"더뷰 파일을 한 장씩이 아닌 여러 장 30~ 이상이라도 같이 첨부할 수 있게."**
> - **"그리고 보인 것은 저장하기 — 그림이나 피디에프로."**
> 대상: **`kim779944-max/oneclick` 의 `viewer.html` 단 한 파일.** 쇼룸·`products.js`·`catalog.json`·`slots.js`·`helper.js`·`slope/`·`converter.html`·`listing/` 등 **다른 파일 0건**(제0원칙).
> 결과 보고서: **`CLAUDE_RESULT_20261123_VIEWER_MULTI_SAVE.md`** (`K0612766940K-` 저장소에 작성·커밋·푸시)
> 기준선(2026-11-23 18:4x KST, 지니가 실제로 확인): `oneclick` **`042af4d`** · `K0612766940K-` **`53de1f2`**

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 0-1. 이번 회차 결과물 (한 문장)
**더뷰에서 사진·PDF·한글·엑셀을 30장이든 50장이든 한 번에(또는 이어서) 첨부하면 파일별로 순서대로 이어서 넘겨 볼 수 있고(`12 / 34` 처럼 전체 장수·현재 위치 표시, 파일 목록에서 바로 이동·개별 삭제·전체 초기화), 지금 보이는 장을 [그림(PNG)]으로, 전체를 [ZIP]으로, 전체를 [PDF]로 보이는 그대로 저장할 수 있다 — 인화본 1:1 원칙과 두 손가락 확대는 그대로인 채로.**

### 0-2. 하지 않는 것 (하나라도 어기면 그 항목은 실패로 기록)

1. **제0원칙 — 더뷰의 핵심 엔진은 건드리지 않는다.**
   - 불변: **인화본 1:1 원칙**(화면 폭에 맞춰 글자를 재조판하지 않는다 · `fitZoom()`·`applyZoom()`·`layoutPages()` 의 배율·치수 규칙) · **핀치/끌어서 이동** · `ppTrack/ppPageLabel/goPage` 의 페이지 감지 · PDF.js 캔버스 렌더 방식 · **더편집(`#pgEdit`·`kipEdit`)** · `[출력]`(`#vtPrint` → `window.print()`) · 구형 `.hwp` 사무실 PC 변환(`hwpViaPc`) · `?f=IndexedDB` 진입로 · 쇼룸 뒤로가기 안전장치(`SHOP_GUARD`) · `resetView()` · 요금·안내 문구·`ktsRsv` 배너.
   - **추가·수정 범위**: ① 다중 파일 묶음(`MF`) ② 하단 출력 바 두 버튼과 ZIP/PDF ③ 그로 인한 최소 배선(§2-2의 append 대상 5곳).
2. **파일을 서버로 보내지 않는다.** 이번에도 **업로드 0 · 외부 AI 0**. 새로 쓰는 외부 스크립트는 **cdnjs 1곳(이미 pdf.js·html2canvas 가 쓰는 그 호스트)** 의 `jszip`·`jspdf` 뿐이고, **필요할 때만** 불러온다. 그 외 새 도메인 0건.
3. **한 파일만 열 때의 지금 화면·동작이 똑같아야 한다.** 파일 1개 → `1 / 1` 표시·자동 열림·확대·페이지 이동·더편집·그림 저장이 **한 가지도 달라지면 실패**다(회귀 금지).
4. **지어내기 금지.** 30장 테스트셋 없이 "30장 됩니다"라고 쓰지 않는다. §4의 실측·캡처로만 판정한다.
5. **`viewer.html` 밖으로 나가지 않는다** — `converter.html`·`manifest.webmanifest`·`app_viewer` APK·`products.js`·`catalog.json` 무변경.
6. **관문 6 유지** — 대표님 직접 시연 전 대외 판매·광고·문자 발송·스토어 업로드 0건.
7. **비밀값·경로 커밋 금지** — `oneclick` 은 공개 저장소다. `C:\Users\...`·PC 이름·토큰을 보고서에 쓰지 않는다.
8. **되돌릴 수 있게** — 손대기 전 두 저장소 `git rev-parse HEAD` 를 보고서 §1에 적는다(기대 `042af4d` / `53de1f2`).
9. **실패는 원문 그대로** — 막힌 명령·오류·우회한 방법을 그대로 적는다.

### 0-3. 진행 규칙
- **0(§1) → A(§2 다중 첨부·연속 열람) → B(§3 그림/ZIP/PDF) → C(§4 검증)** 순. **§2·§3 끝날 때마다 커밋**.
- **최소 합격선 = A(30장 첨부·연속 열람) + B(PNG·PDF 둘 다)**. 하나만 되면 "반쪽"으로 정직하게 적고 마지막 줄에 `남은 것: …`.
- 자동 실행기는 한 회차 90분까지만 돈다. 이미 끝난 항목은 다시 만들지 않는다.

---

## 1. 0단계 — 저장소·현재 코드 (20분)

### 1-1. 두 저장소 최신화
```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\oneclick"
git pull --rebase; git rev-parse --short HEAD          # 기대: 042af4d 이상
cd ..\K0612766940K-
git pull --rebase; git rev-parse --short HEAD          # 기대: 53de1f2 이상
```
> **동시 작업 주의**: 자동 실행기가 `SNS_UPGRADE`·`SLOPE_ARROW_SMALL` 등 다른 지시서를 돌리고 있을 수 있다. force-push 금지. `viewer.html` 만 건드리므로 충돌은 없어야 하지만, 원격이 앞서 있으면 `git pull --rebase` 후 양쪽을 살려 푸시한다.

### 1-2. 지금 코드 지도 — `viewer.html` (`042af4d` 판 · 1,665줄)
줄번호는 이 판 기준이다. 값이 다르면 **id·함수 이름으로** 찾는다.

| 부품 | 위치 | 지금 상태(이번에 손대는 곳) |
|---|---|---|
| 파일 입력 `#f` | ~250 | `<input type="file" id="f" hidden accept=".hwp,.hwpx,.xlsx,.xlsm,.docx,.csv,.txt,.pdf,image/*">` — **`multiple` 없음** ← 원인 ① |
| 열기 버튼 | ~244·~249 | `.drop .mini` 의 `[다른 파일]` · 큰 `[파일 열기]` — 둘 다 `#f.click()` |
| change 리스너 | ~1182 | `const file = e.target.files[0]; if (!file) return; showFile(file);` — **첫 1장만** ← 원인 ① |
| `showFile(file)` | ~1118 | 1개 파일을 종류별로 판별해 `paintDoc()` 호출 |
| `paintDoc(r,file,nm)` | ~1012 | `ppReset()` → `.ppspace/.ppscale` 생성 → 종류별 빌더 호출 → `applyZoom(fitZoom())` |
| PDF 빌더 `buildPdf(buf)` | ~831 | pdf.js 로 문서 열고 페이지 div 생성, `PP.scale.appendChild(el)` (~840) |
| 사진 빌더 `buildImage(url)` | ~901 | `<img>` 원본 픽셀 그대로, `PP.scale.appendChild(el)` (~913) |
| 표/문서 빌더 `buildSheet(r)` | ~922 | A4 794px 종이 + `ppSheetMeasure()`(1123px 단위 장 표시) |
| iframe 폴백 `buildFrame` | ~955 | pdf.js 없을 때 |
| 안내 카드 `buildNotice` | ~972 | 구형 .hwp |
| 페이지 감지 `ppTrack` | ~790 | 스크롤 → `PP.cur` 갱신 |
| 페이지 표시 `ppPageLabel` | ~798 | `#pgNo` 에 `(cur+1) + ' / ' + PP.tops.length` |
| 페이지 이동 `goPage` | ~806 | `PP.tops[n] * PP.zoom` 으로 스크롤 |
| 확대/축소 | ~698 `applyZoom` · ~719 `zoomBy` · ~876 `ppHiRes` | 핀치·버튼 공통 |
| 하단 바 `#pbar` | ~231~238 | `‹ [1/1] › [더편집] [이미지로 저장]` ← 원인 ② |
| 저장 `saveImage` | ~1073 | **지금 장 1장**만: PDF→`savePdfPage(cur)` · 사진→원본 파일 · 표→`saveSheetPage(cur)`(html2canvas) |
| 저장 헬퍼 | ~1031 `ppDl` · ~1037 `savePdfPage` · ~1053 `ppLoadH2C` · ~1059 `saveSheetPage` | 재사용 대상 |
| 인쇄 `#vtPrint` | ~1262 | `window.print()` + 안내 토스트 |
| 인쇄 CSS | ~121~147 | `@page{size:A4;margin:10mm}` · `.pppage{width:190mm;page-break-after:always}` · `.ppno,.ppmark{display:none}` |
| 초기화 `resetView` | ~1107 | `ppReset()` + `#f.value=''` |

### 1-3. 고치기 전 캡처
390×844 로 `https://autooneclick.com/viewer.html?t=<타임스탬프>` 를 열고 ① 사진 1장 열기 ② 사진 3장을 한 번에 선택 시도(→ **1장만 열리는 것**을 캡처: `before_single_only.png`) ③ 하단 바 캡처(`before_pbar.png`). 저장 위치 `output/viewer_multi_20261123/`.

---

## 2. A. 다중 첨부 — 30~50장을 한 번에, 이어서 추가, 순서대로 연속 열람

### 2-1. 화면·동작 (이대로 만든다)
```
상단 #vtool   ← 뒤로가기 | 파일 3/12 · 계약서.pdf | [변환기 | 더뷰]        (파일 위치 표시 추가)
본문 스크롤   ← 1번 파일 1장 … 1번 파일 n장 │ 2번 파일 1장 … (파일별 얇은 머리줄: "3 · 계약서.pdf · 2장")
하단 #pbar 1줄 ← [‹] [12 / 34] [›] [목록] [＋]
하단 #pbar 2줄 ← [그림 저장 ▾] [PDF 저장] [더편집]
```
- **`[＋]`** = 파일 추가(지금 열려 있는 묶음 **뒤에 이어 붙인다**). `.drop .mini` 의 `[다른 파일]` 라벨도 **`[＋ 파일 추가]`** 로 바꾼다(같은 동작).
- **`[목록]`** = 파일 목록 시트(아래에서 올라오는 패널, `#mfList`)
  - 각 줄: `번호 · 파일명 · 장수 · 형식` + **`[✕]` 개별 삭제**
  - 줄을 누르면 그 파일 첫 장으로 이동
  - 맨 아래 `[모두 닫기]`(기존 `resetView()` 호출)
- **드래그&드롭**: `.drop`(첫 화면)과 **본문 스크롤 영역(`#out`)** 모두에서 `dragover`(preventDefault) / `drop` → `addFiles(e.dataTransfer.files)`. 드롭 중 시각 표시(점선 강조) 1개.
- **`#f`**: `multiple` 추가. `change` 리스너는 `Array.from(e.target.files)` 전체를 `addFiles()` 로 넘긴다(`files[0]` 만 쓰지 않는다). 처리 후 `#f.value=''`(같은 파일 재선택 가능).

### 2-2. 구현 골격 (기존 엔진을 거의 안 건드리는 길 — 이 구조로 간다)
지금 엔진은 "문서 1개 = `PP`" 전제다. **그 전제를 유지한 채**, 문서 여러 개를 **한 스크롤 안에 파일 블록으로 쌓는다.**

```js
var MF = { items:[], pages:[], cur:0, MAX:60, MAXB:200*1024*1024, seq:0 };
/* item = {id, file, name, size, kind, block(el), pages:[{el,pi,w,h}], w, h, pdf, buf, url, built:false} */
```
1. **한 번만 만드는 무대**: 첫 파일을 열 때 지금처럼 `.ppspace`/`.ppscale` 를 만들고, 이후 파일은 **거기에 블록을 덧붙인다**. (`ppReset()` 은 "전체 초기화"(`resetView`)에서만 부른다 — 파일을 추가할 때 부르지 않는다.)
2. **빌더가 붙는 곳만 바꾼다(정확히 5곳)**: `buildPdf`(~840) · `buildImage`(~913) · `buildSheet`(~927) · `buildFrame`(~966) · `buildNotice`(~984) 의 `PP.scale.appendChild(...)` → **`(PP.blk || PP.scale).appendChild(...)`**. `PP.blk` 는 현재 짓고 있는 파일 블록이다. **다른 줄은 손대지 않는다.**
3. **파일 블록**: `<div class="mfblk" data-id="3">` 안에 ① 얇은 머리줄(`.mfhd`: `3 · 계약서.pdf · 2장` + `✕`) ② 페이지들. `PP.blk = block` 로 지정한 뒤 **기존 빌더를 그대로 호출**하면 페이지·캔버스·측정이 지금 코드 그대로 동작한다.
4. **장부(전체 페이지)**: 파일 하나를 다 지으면 `PP.pages`/`PP.tops`/`PP.w` 를 **그 item 에 복사**하고 `MF.pages` 를 다시 만든다.
```js
function mfRelayout(){                       /* 블록 위치·전체 장수 계산 */
  MF.pages = []; var y = 0;
  MF.items.forEach(function(it, fi){
    it.top = y; y += it.hdH || 22;
    (it.pages||[]).forEach(function(p, pi){
      MF.pages.push({it:it, fi:fi, pi:pi, top:y, h:p.h, el:p.el});
      y += p.h + 14;
    });
    y += 10;
  });
  MF.total = MF.pages.length; mfLabel();
}
```
   > `top` 은 `.ppscale` 좌표계(스케일 1 기준 px)로 잡고, 실제 스크롤은 `top * PP.zoom` 으로 계산한다 — `goPage()` 와 같은 방식.
5. **페이지 표시·이동**: 파일이 **1개면 지금 코드 그대로**(`PP.tops` 사용 · `1 / 1`). **2개 이상이면** `#pgNo` = `MF.cur+1 + ' / ' + MF.total`, `[‹][›]` 는 `mfGo(MF.cur±1)`. 스크롤 중 위치는 `ppTrack()` 에서 **`MF` 기준으로 한 번 더** 계산해 `MF.cur` 을 갱신(기존 `PP.cur` 갱신은 그대로 두어도 무해).
6. **상단 표시**: `#vtName` = `파일 3/12 · 계약서.pdf`(1개면 지금처럼 파일명만). `.drop .mini` 의 `#mName`/`#mMeta` 도 `묶음 12개 · 34장` 형태로.
7. **개별 삭제**: `mfRemove(fi)` → 그 블록 DOM 제거 · `it.pdf && it.pdf.destroy()` · `it.url && URL.revokeObjectURL(it.url)` · `it.buf=null` → `mfRelayout()` → 현재 위치를 가까운 장으로 보정 → 남은 게 0개면 `resetView()`.
8. **추가 시 스크롤 유지**: 지금 보던 장의 `top` 을 기억했다가 `mfRelayout()` 후 되돌린다(파일을 뒤에 붙이므로 보통 영향 없음).
9. **한계·안내**: `MAX=60개` · `MAXB=200MB`. 넘으면 **앞에서부터 60개/200MB까지만** 받고 `showToast('한 번에 60개까지 열 수 있습니다')`.

### 2-3. 메모리 규칙 (30~50장에서 죽지 않게 — 이건 합격 조건이다)
| 형식 | 규칙 |
|---|---|
| **PDF** | 페이지 크기는 `getViewport` 로 **즉시** 확정(블록 높이 고정) → 캔버스는 **화면 ±1500px 안에 들어올 때만** 렌더. 벗어나면 `canvas.width=0; canvas.height=0` 후 `.ph` 자리표시로 되돌리고 `p.canvas=null`(다시 들어오면 재렌더). `it.buf` 는 빌드 후 **`null`**(pdf.js 가 이미 들고 있다). |
| **사진** | `<img>` + `objectURL` 유지(원본 픽셀). **canvas 금지.** 삭제 시 `revokeObjectURL`. |
| **한글·엑셀·워드·CSV** | 평소엔 DOM 그대로. **저장할 때만** html2canvas. |
| **공통** | 저장(ZIP/PDF) 중에는 장마다 만든 캔버스/블롭을 **즉시 해제**. 저장이 끝나면 `canvas` 개수가 저장 전 수준으로 돌아와야 한다. |
| 측정 | 30장 로드 후 화면을 위↔아래 3회 왕복해도 `document.querySelectorAll('#out canvas').length` 가 **8개를 넘지 않는다**(§4). |

### 2-4. 지켜야 할 것
- **순서 = 첨부 순서**(파일 선택 대화상자의 순서, 드롭 순서). 정렬·추측 금지.
- **인화본 1:1**: 파일마다 종이 폭·배율은 지금 규칙(`fitZoom`) 그대로. 여러 파일이어도 **각자 자기 폭**을 쓴다(가장 넓은 것에 맞춰 늘리지 않는다). `applyZoom()` 은 공통 배율 1개로 동작해야 핀치가 자연스럽다 → 배율은 `MF.items` 중 **가장 넓은 `w`** 기준 `fitZoom` 을 쓰되, **각 페이지의 표시 폭은 자기 원본 폭**으로 유지(늘리지 않음).
- 실패한 파일(열 수 없음)은 **그 자리에 안내 카드**를 남기고 나머지 파일은 계속 연다(전체 실패 금지).
- 로딩 표시: `#loader` 를 재사용해 `3 / 30 · 계약서.pdf` 진행률.

---

## 3. B. 보이는 그대로 저장 — 그림(PNG) · PDF

### 3-1. 하단 바 (2줄로 바꾼다)
```
1줄: [‹] [12 / 34] [›] [목록] [＋]
2줄: [그림 저장 ▾] [PDF 저장] [더편집]
```
- `[그림 저장 ▾]` → 작은 메뉴 2개: **`[지금 장 PNG]`** · **`[전체 장 PNG(ZIP)]`**
- `[PDF 저장]` → **전체를 PDF 1개로 내려받기**(인쇄 대화상자 없이 파일 저장)
- 기존 `[이미지로 저장]`(`#vtSaveImg`)은 **`[그림 저장]` 으로 이름만 바꿔 그대로 둔다**(id 유지 · 지금 장 PNG 와 같은 동작).
- 버튼 높이·색은 지금 `#pbar` 토큰 그대로, 2줄이어도 `--pb` 높이 계산(`fitStage`)이 자동으로 따라가게 한다(높이 변수는 `offsetHeight` 로 재므로 추가 작업 없음 — **실측으로 확인**).

### 3-2. 지금 장 PNG (기존 함수 재사용)
| 형식 | 방법 |
|---|---|
| PDF | 기존 `savePdfPage(pi)` 그대로 (q≈3.2 · 약 230dpi) |
| 사진 | 기존대로 **원본 파일 그대로** 내려받기(재압축 금지) |
| 한글·엑셀·표 | 기존 `saveSheetPage(pi)` 그대로 (html2canvas ×2) |
- 파일명: `더뷰_<원본이름>_<n>p.png` (지금 규칙 `ppBase()` 유지).
- 여러 파일일 때 `n` 은 **전체 장 번호**(예: 34장 중 12번째 → `_12p`), 원본이름은 그 장의 파일명.

### 3-3. 전체 장 PNG → ZIP
- `JSZip` 을 **필요할 때만** 불러온다: `https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js` (기존 pdf.js·html2canvas 와 같은 호스트). 5초 안에 안 오면 **ZIP 없이 순차 다운로드**로 대체하고 `showToast('한 장씩 저장합니다')`.
- 순서: `MF.pages` 순서대로 장마다 blob 생성(`savePdfPage/saveSheetPage` 의 다운로드 부분을 **blob 반환 함수로 분리**해 재사용 — 함수 2벌 만들지 말 것) → `zip.file('01_계약서_1p.png', blob)` → 캔버스 해제.
- `zip.generateAsync({type:'blob', compression:'STORE'})` (PNG는 이미 압축됨 — STORE가 빠르다) → `ppDl(blob, '더뷰_전체_34장_2026-11-23.zip')`.
- 진행률: `#loader` 재사용 `저장 12 / 34`.
- 60장 초과·300MB 초과 예상이면 **시작 전에** `showToast('30장씩 나눠 저장해 주세요')` 후 중단(메모리 보호). 이 문구·기준을 보고서에 적는다.

### 3-4. 전체 PDF — 보이는 그대로, 원본 비율, A4
- `jsPDF` 를 **필요할 때만** 불러온다: `https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js`.
- **장마다**: ① 그 장을 현재 배율과 무관하게 **원본 비율 그대로** 이미지로 만든다(PDF: `page.render` q=2.0 → `toDataURL('image/jpeg',0.92)` · 사진: 원본 `<img>` 를 canvas 1회 → JPEG · 표: html2canvas ×2 → JPEG) ② **A4 페이지에 비율 유지해 폭 190mm 맞춤**(높이는 비율대로, A4 세로 277mm 를 넘으면 **가로 A4**로 그 장만 눕힌다) ③ `pdf.addImage` ④ 캔버스 해제.
- 페이지 크기 규칙: 기본 **A4 210×297mm**. 원본이 가로로 넓은 장(`w/h > 1.15`)은 **A4 가로 297×210mm** 로 그 장만 전환 — `jsPDF` 의 `addPage([297,210],'landscape')` 사용. 보고서에 장별 방향 표를 적는다.
- 파일명: `더뷰_<첫파일이름>_34장_2026-11-23.pdf`.
- 진행률 `PDF 12 / 34` + 완료 토스트 `PDF를 저장했습니다 · 34쪽`.
- **실패 폴백**: jsPDF 를 못 불러오면 지금 `[출력]`(인쇄 → PDF로 저장) 경로로 안내만 하고, **인쇄용 준비 코드**(모든 장을 q≥1.6 으로 렌더한 뒤 `window.print()`)로 넘어간다. 이때도 인쇄 결과 쪽수 = 총 장수여야 한다(빈 장 0).
- `[출력]`(`#vtPrint`)은 **지금 그대로 둔다**(별도 경로 · 삭제 금지).

### 3-5. "보이는 그대로"의 뜻 (해석 고정)
- 화면에서 **재조판·재줄바꿈 없이** 보이던 그 종이 그대로 나가야 한다. 표를 PDF 저장하려고 폭을 바꾸거나 글자를 다시 흘리지 않는다.
- 사진은 **원본 픽셀**을 유지(업스케일 금지). PDF·표 장은 저장용 해상도만 올린다(q 2.0 · html2canvas scale 2) — **비율·여백·색은 화면과 같다**.

---

## 4. C. 검증 — 30장 실측·캡처·게이트

### 4-1. 테스트셋 (스크립트로 만든다 · 저장소에 커밋)
`output/viewer_multi_20261123/testset/` 에 **34장 분량**:

| 묶음 | 수량 | 장수 합 |
|---|---|---|
| 사진 PNG | 20장(1200×1600 · 큰 번호를 박아 어느 장인지 눈으로 구분) | 20 |
| PDF | 6개 × 각 2쪽 | 12 |
| 엑셀 xlsx | 1개(A4 1장 분량) | 1 |
| 한글 hwpx | 1개(A4 1장 분량) | 1 |
| **합계** | **28개 파일** | **34장** |

> 위 구성으로 **정확히 34장**이 되게 만들고, 만든 구성을 보고서에 적는다. 생성 스크립트도 함께 커밋(`src/make_testset.py`). 파일명은 `01_사진.png` … `28_한글.hwpx` 처럼 **순서를 이름으로 확인**할 수 있게 한다.

### 4-2. 390×844 실측 (숫자로 적는다)
| 항목 | 기대 |
|---|---|
| 한 번에 첨부 | 34개 파일 선택 → `MF.items.length` **34** · `MF.total` **34** |
| 이어서 추가 | `[＋]` 로 3개 더 → `MF.items.length` **37** · 순서 유지(마지막에 붙음) |
| 표시 | 첫 장 `#pgNo` **`1 / 34`** · 마지막 장 **`34 / 34`** |
| 연속 열람 | `[›]` 33회로 마지막 장 도달 · 스크롤로도 같은 위치 감지(오차 ±1장) |
| 파일 이동 | `[목록]` → 3번 파일 → 그 파일 1장으로 이동 · `#vtName` `파일 3/12 …` |
| 개별 삭제 | 3번 파일 `[✕]` → `MF.items.length` **-1** · `MF.total` **-n장** · 나머지 순서 유지 · 그 파일의 objectURL 해제(`URL.revokeObjectURL` 호출 로그) |
| 전체 초기화 | `[모두 닫기]` → 첫 화면 · `#pbar` 숨김 · `MF.items.length` 0 |
| **지금 장 PNG** | 34장 중 12번째에서 저장 → PNG 1개 · 크기 1600px급 · 파일명 `_12p` |
| **ZIP** | `더뷰_전체_34장_*.zip` · 안에 **34개 PNG** · 총 용량 기록 |
| **PDF** | `*.pdf` · **쪽수 34**(pypdf 로 확인) · A4 595×842pt(가로 장은 842×595) · **빈 쪽 0**(각 쪽 픽셀 분산 > 0) |
| 메모리 | 위↔아래 3회 왕복 후 `#out canvas` 개수 **≤ 8** · 콘솔 에러 **0** · 크래시 0 |
| 1개 파일 회귀 | 사진 1장 → `1 / 1` · 핀치 확대 · 더편집 · 출력 정상 |
| 회귀(전 기능) | 구형 `.hwp` 안내 카드 · `?f=` 진입로 · 쇼룸 뒤로가기 · `[변환기]` 링크 · `[출력]` 1회 |
| 가로 넘침 | `document.documentElement.scrollWidth` **390** |
| 외부 요청 | 새 도메인 **0건**(cdnjs 외) · 업로드 요청 **0건** |

### 4-3. 캡처 (`output/viewer_multi_20261123/`)
1. `before_single_only.png` · `before_pbar.png` (§1-3)
2. `after_attach_34.png` — 34장 첨부 직후 첫 화면(파일 위치·`1 / 34`)
3. `after_scroll_mid.png` — 중간(서로 다른 파일 2개가 이어지는 지점 — 파일 머리줄 보이게)
4. `after_list.png` — `[목록]` 패널(개별 ✕·모두 닫기)
5. `after_delete.png` — 3번 파일 삭제 후(장수 감소·순서 유지)
6. `after_save_menu.png` — `[그림 저장 ▾]` 메뉴
7. `after_zip_done.png` · `after_pdf_done.png` — 완료 토스트
8. `pdf_page_1.png` · `pdf_page_12.png` · `pdf_page_34.png` — 저장된 PDF 3쪽 렌더(화면과 같은지 육안 대조)
9. `after_1file.png` — 1개 파일 회귀 확인

### 4-4. 게이트(`kts_gate`) — **FAIL 0 필수**
```powershell
python output/kts_gate.py .\oneclick\viewer.html      # 없으면 python3 / 이식판(gate_multi.ps1)
```
- 기대 **FAIL 0**(`G1-1`·`G1-2`·`G1-4`·`G1-6`·`G1-7`·`G1-9`). 출력 전문 `output/viewer_multi_20261123/gate.txt` · **전/후 FAIL 수** 기록(전 0 → 후 0).

### 4-5. 라이브 반영
```powershell
curl.exe -s "https://autooneclick.com/viewer.html?t=$(Get-Date -Format s)" | Select-String "파일 추가"
```
- 잡히면 반영. 안 잡히면 `?t=` 바꿔 3회 재확인, 그래도 안 되면 **"안 떴다"** 고 적는다.

---

## 5. 결과 보고서 `CLAUDE_RESULT_20261123_VIEWER_MULTI_SAVE.md` (이 틀 그대로)

```
# 결과 — 2026-11-23 더뷰 다중 첨부 30장+ · 그림/PDF 저장 (145번)
시작 HEAD: oneclick <sha> / K0612766940K- <sha>
끝   HEAD: oneclick <sha> / K0612766940K- <sha>
커밋: <해시·메시지>

## 1. 저장소·기준
- pull 결과 <앞/뒤 sha> · 바뀐 파일: viewer.html 1개뿐(+n/−n줄) · 되돌리기: git revert <sha>

## 2. A. 다중 첨부·연속 열람
- #f multiple: <> · change 리스너 files[0]→전체: <> · 드래그&드롭(첫 화면/본문): <> / <>
- 블록 append 대상 5곳 수정: buildPdf/buildImage/buildSheet/buildFrame/buildNotice = <5/5?>
- 34장 첨부: items <> · total <> · #pgNo <> → <> · 마지막 장 도달 <>
- 파일 목록: 이동 <> · 개별 삭제 <> (총 <>장 감소, 순서 유지) · 모두 닫기 <>
- 메모리: 캔버스 최대 <>개 · 해제 규칙(PDF ±1500px) <> · objectURL revoke <>
- 한 파일 회귀: 1/1 <> · 핀치 <> · 더편집 <> · 출력 <>

## 3. B. 저장
- 하단 바 2줄: <> (버튼 높이 <px> · #pb 높이 자동 <px>)
- 지금 장 PNG: <> (예: 12/34 → 파일명) · 1개 파일일 때 <>
- ZIP: <파일명> · 안에 <>개 · <MB> · JSZip 로드 <성공/폴백>
- PDF: <파일명> · 쪽수 <> · 페이지 크기 <> · 가로 장 <>개 전환 · 빈 쪽 <> · jsPDF <성공/폴백>
- 진행률·실패 폴백·60장/300MB 안내: <>

## 4. 검증 숫자 (390×844)
- scrollWidth <> · 콘솔 에러 <> · 새 도메인 <> · 업로드 요청 <>
- 캡처 경로: before 2 / after 6 / pdf 3 / 1file 1
- 테스트셋 구성: 사진 <> / PDF <> / 엑셀 <> / hwpx <> = <>장 (경로)

## 5. 게이트
- kts_gate: 전 FAIL <n> → 후 FAIL <n> · output/viewer_multi_20261123/gate.txt

## 6. 라이브
- /viewer.html '파일 추가' <잡힘/안 잡힘>

## 건드리지 않은 것 (확인함)
- 인화본 1:1·핀치·페이지 감지·더편집·출력·hwp PC 변환·?f= 진입로·쇼룸 가드·요금·문구 · 다른 페이지 0건 · 서버 업로드 0

## 대표님 확인 필요
1) 30~50장을 한 번에 넣고 순서대로 넘겨 보는 게 자연스러운지
2) 저장한 PDF가 화면에서 보던 그대로인지(여백·비율·글자)
3) ZIP으로 전체 받았을 때 장 순서·이름이 맞는지
```
보고서·캡처·테스트셋·검증 스크립트는 `K0612766940K-` 에 커밋·푸시.

---

## 6. 한 문장 목표

**더뷰에서 사진·PDF·한글·엑셀 34장을 한 번에(또는 이어서) 첨부하면 파일별로 순서대로 이어 보며 `12 / 34` 로 위치를 알고, 목록에서 바로 이동·개별 삭제·전체 초기화할 수 있고, 지금 장은 PNG로·전체는 ZIP으로·전체는 원본 비율 A4 PDF로 **보이던 그대로** 저장된다 — 인화본 1:1·핀치 확대·더편집·기존 진입로는 하나도 바뀌지 않은 채로.**

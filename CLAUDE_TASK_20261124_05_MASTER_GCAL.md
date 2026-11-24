# PC 클로드 코드 작업 지시서 — 2026-11-24 · ⑤ 쇼룸 마스터 박스 기본 접힘(182) + 번개알바 사장님 구글 캘린더 1클릭 연결 마법사(181)

> 발령: 2026-11-24 10:3x KST · 사령관 지니 → PC 클로드 코드(Pro, `DESKTOP-02`)
> 적립메모 요지:
> · **182** — 쇼룸(`autooneclick.com`) 첫 화면은 **대표님 폰에서도 손님 화면 그대로**여야 한다. 마스터 PIN이 저장된 기기에서는 `#mst`(대표님 전용 마스터 박스)가 자동으로 펼쳐져 첫 화면을 가린다 → **기본은 접힘**, 화면의 작은 `[마스터]` 버튼을 눌렀을 때만 펼쳐지고 다시 누르면 접힌다.
> · **181** — 번개알바 사장님이 **서버비 0원**으로 자기 구글 캘린더를 AI 예약 비서에 붙이는 **1클릭 연결 마법사** (코드 1클릭 복사 → Apps Script 바로 열기 → 웹 앱 주소 붙여넣고 연결 테스트).
> 대상: **`kim779944-max/oneclick`**
> ① `index.html` (쇼룸 · 과업 1)
> ② `bungee_sample/gcal_connect/` **신규 4개 파일** (과업 2: `index.html` · `gas_kts_calendar.js` · `mock_gas.js` · `README_사장님설치.md`)
> ③ (04가 만든) `bungee_sample/sansugowon/index.html` — 연결 줄 3곳만
> 준비물: 없음. GAS 완성형 코드 전문이 이 문서 §3-4에 있다(그대로 쓴다).
> 결과 보고서: **`CLAUDE_RESULT_20261124_05_MASTER_GCAL.md`** (`K0612766940K-`)

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 0-1. 이번 회차 결과물 (한 문장)
**대표님이 폰으로 `autooneclick.com`을 열면 손님과 똑같은 첫 화면이 그대로 보이고(마스터 박스는 접힘 · 위 `[마스터]` 한 번이면 펼침/접힘), 번개알바 사장님은 우리 페이지에서 ① 코드 복사 ② Apps Script 열기 ③ 웹 앱 주소 붙여넣기 세 번으로 자기 구글 캘린더를 예약 비서에 연결해, 빈 시간 조회와 예약 일정 등록이 실제로 오간다.**

### 0-2. 하지 않는 것 (하나라도 어기면 실패)
1. **제0원칙 — 쇼룸 뼈대 불변**: `products.js` · `catalog.json` · `detail.html` · `helper.js` · `shared/kts-edge.js` · 5대 대문 구조 · 색깔 1·2 토글 · 도우미 버튼 위치. **이번에 건드리는 쇼룸 파일은 `index.html` 하나뿐**이고, 그 안에서도 §2-3의 마스터 블록만 바꾼다.
2. **`oneclick/bungee/` 는 절대 수정 금지.** (`git diff --stat` 로 0줄 확인)
3. **쇼룸 등록 금지** — `gcal_connect` 를 `products.js`·`catalog.json`·`index.html` 상품 목록·`sitemap.xml` 에 넣지 않는다. 대표님 시연 전까지는 **폴더 안에만** 존재.
4. **04의 샘플 무변경** — `bungee_sample/sansugowon/` 은 §3-6의 연결 줄 3곳 외에 디자인·문구·사진·사실표를 건드리지 않는다. 04 결과 파일이 없으면(폴더 없으면) §3-6은 건너뛰고 보고서에 `04 미실행 → 연결 줄 생략` 1줄.
5. **실제 예약 확정·결제·문자·전화 0.** 예약은 사장님 캘린더에 **일정 1건 등록**까지. 화면 어디에도 "예약 완료"라고 쓰지 않는다(`예약 요청 접수 · 사장님 캘린더에 일정이 등록되었습니다`).
6. **새 도메인 0 · 유료 API 0 · OAuth 클라이언트 ID/비밀키 저장 0 · 우리 서버 0.** 손님·사장님 개인정보를 우리 쪽에 저장하지 않는다(이름·연락처는 **사장님 자기 캘린더 일정 설명**에만).
7. **캘린더 내용을 밖으로 내보내지 않는다** — 응답에는 **빈 시간 목록만**. 일정 제목·참석자·메모·다른 사람 이름 반환 금지(§3-7).
8. **되돌릴 수 있게** — 시작 커밋 기록, 과업마다 따로 커밋(182 / 181).
9. **검증 기준은 실측**: 390×844 실기기 폭 캡처, 바꾸기 전/후 캡처, 회귀 0(콘솔 에러 0 · 기존 기능 그대로).

### 0-3. 순서와 시간
**과업 1 (182 · 15분) → 과업 2 (181 · 90분).** 182는 먼저 커밋해 두고 181로 넘어간다. 181이 길어져도 182 커밋을 되돌리지 않는다.

---

## 1. 기준 상태 (2026-11-24 10:3x · `oneclick` main `5395a92` · 01 실행 반영 후)

`index.html` 은 763줄(01 실행 반영 후 · 아래 행 번호도 이 기준). 마스터 관련은 아래 8곳뿐이다(그 외에 마스터 분기 없음 — 확인함).

| 위치 | 지금 코드 | 문제 |
|---|---|---|
| `master.js` | `localStorage['kts_master'] = '2899'` · `KTS.isMaster()/setMaster()/clearMaster()` · `kts:master` 이벤트 | 그대로 쓴다(무변경) |
| 마크업 287행 | `<button class="mkey" id="mKey" …>⚙</button>` | 인증 상태에서 `MASTER` 로 바뀜 |
| 마크업 295행 | `<section class="mst" id="mst" hidden>` … 안에 `#mstOff`(해제) · `#mstN` · `#mstVer` · `#mstGrid` | 인증 상태면 자동 펼침 |
| 마크업 303행~ | `<div class="mscrim">` · `<div class="msheet">`(PIN 입력 `#mPin`, `#mGo`, `#mCancel`, `#mErr`) | 그대로 |
| JS 716~723행 `paint()` | `mst.hidden = !on;` | **이 한 줄이 원인** — 인증=펼침 |
| JS 724~728행 `key.onclick` | 인증 상태에서 누르면 `clearMaster()`(해제) | 펼침/접힘 토글로 바꾼다 |
| JS 734행 `#mstOff` | `clearMaster()` | 그대로(해제는 박스 안 버튼 몫) |
| CSS 37~38행 `.hd .mkey` / `.mkey.on` | 켜지면 폭 자동·9px·`MASTER` 글자 | 켜졌을 때 `마스터` 글자(9px, 더 짧음) → 390px에서도 한 줄 유지 |

**헤더 순서(390px, 좌→우)**: 로고 → `spacer` → `[편집]`(`#editBtn`) → 색깔1·색깔2(`.k-theme2`) → `🔑 0`(`#kBtn`) → `⚙`(`#mKey`).
→ **새 버튼을 추가하지 않는다.** `#mKey` 하나가 손님에게는 "PIN 열기", 마스터에게는 "마스터 박스 펼침/접힘"이 된다(지시문의 `[마스터]` 버튼 = 이 버튼).

---

## 2. 과업 1 — 182 · 쇼룸 첫 화면은 대표님 폰도 손님 화면 그대로

**수정 범위: `oneclick/index.html` 단독.** (`master.js`·`shared/*`·`products.js`·`catalog.json` 무변경)

### 2-1. 문제 재현 (바꾸기 전 캡처 필수)
1. `?master=2899` 로 한 번 들어가 PIN을 저장시킨 뒤 `autooneclick.com` 재접속(또는 그냥 PIN 입력).
2. → 헤더 아래 **주황 테두리 마스터 박스가 첫 화면에 펼쳐진 채**로 뜨고, 히어로·5대 대문이 아래로 밀린다. **손님에게는 안 보이는 화면**이다.

### 2-2. 바꿀 동작 (표 그대로)

| 기기 상태 | 첫 진입 | `[마스터]`(⚙/마스터) 누름 | 다시 누름 | `[해제]`(박스 안) |
|---|---|---|---|---|
| 손님(미인증) | `#mst` 숨김 | **PIN 입력 시트**(기존 그대로) | — | — |
| 손님 · PIN 틀림 | 시트 유지 | `PIN이 맞지 않습니다` + 입력칸 비움 | — | — |
| 대표님 · PIN 저장됨 | **`#mst` 접힘(기본)** · 첫 화면 = 손님 화면 | **박스 펼침**(도구 목록 채워짐) · 스크롤 최소 이동 | **박스 접힘** | 마스터 해제 → `⚙` 복귀 |
| 대표님 · PIN 방금 입력 | (입력 직후 **1회만** 펼침) | 접힘/펼침 토글 | — | 해제 |
| 대표님 · 새로고침 | **다시 접힘** (펼침 상태를 저장하지 않는다) | 토글 | — | 해제 |
| `?master=2899` 링크 | 마스터 켜짐 + **접힘** · 토스트 문구 안내 | 토글 | — | 해제 |

- **박스가 접혀 있어도 마스터 권한은 그대로**다(열쇠·잠금 없이 도구가 열리는 동작 유지). 화면 표시만 접는다.
- 펼침 상태를 `localStorage`/`sessionStorage`에 **저장하지 않는다** — "첫 화면은 언제나 손님 화면"이 요구사항이다.

### 2-3. 코드 (이 블록만 정확히 교체)

**① 마스터 IIFE 전체(`708~737행` · `(function(){ … })();`)를 아래로 교체** — 01 반영 후 행 번호이고, 02~04는 `index.html` 을 건드리지 않는다. 찾기로는 `var mm=(location.search.match(/[?&]master=` 부터 `/* 초대 링크로 들어온 기기 안내 */` 바로 앞까지.

```js
(function(){
  var mst=$('#mst'), key=$('#mKey'), sheet=$('#msheet'), scrim=$('#mscrim'), pin=$('#mPin'), err=$('#mErr');
  var mstOpen=false;   /* 182 — 새로고침·재방문마다 항상 접힘. 저장하지 않는다 */
  try{
    var mm=(location.search.match(/[?&]master=([^&]+)/)||[])[1];
    if (mm && window.KTS && window.KTS.setMaster(decodeURIComponent(mm))) {
      setTimeout(function(){ toastMsg('마스터 모드 켜짐 · 오른쪽 위 [마스터]를 누르면 도구 목록이 열립니다'); }, 60);
    }
  }catch(e){}
  function paint(){
    var on = !!(window.KTS && window.KTS.isMaster());
    if (!on) mstOpen=false;
    mst.hidden = !(on && mstOpen);            /* 182 — 인증만으로는 펼치지 않는다 */
    key.classList.toggle('on', on);
    key.textContent = on ? '마스터' : '⚙';
    key.setAttribute('aria-expanded', (on && mstOpen) ? 'true' : 'false');
    key.setAttribute('aria-label', on ? (mstOpen ? '마스터 박스 접기' : '마스터 박스 펼치기') : '대표님 마스터 모드(PIN) 열기');
    if (on) masterGrid();
  }
  function closeSheet(){ sheet.hidden = true; scrim.hidden = true; }
  key.onclick = function(){
    if (window.KTS && window.KTS.isMaster()){          /* 182 — 해제가 아니라 펼침/접힘 */
      mstOpen = !mstOpen; paint();
      if (mstOpen) { try { mst.scrollIntoView({behavior:'smooth', block:'nearest'}); } catch(e){} }
      return;
    }
    err.hidden = true; pin.value=''; sheet.hidden=false; scrim.hidden=false; setTimeout(function(){ pin.focus(); },60);
  };
  $('#mCancel').onclick = closeSheet; scrim.onclick = closeSheet;
  $('#mGo').onclick = function(){
    if (window.KTS && window.KTS.setMaster(pin.value)){ mstOpen = true; closeSheet(); paint(); toastMsg('마스터 모드 — 열쇠·잠금 없이 전부 열립니다'); }
    else { err.hidden=false; pin.value=''; pin.focus(); }
  };
  pin.addEventListener('keydown', function(e){ if (e.key==='Enter'){ e.preventDefault(); $('#mGo').click(); } });
  $('#mstOff').onclick = function(){ window.KTS.clearMaster(); paint(); toastMsg('마스터 모드를 껐습니다'); };
  document.addEventListener('kts:master', function(e){ try{ if (!(e && e.detail && e.detail.on)) mstOpen=false; paint(); render(); }catch(err2){} });
  paint();
})();
```

**② CSS 1줄 추가**(`.mst{…}` 규칙 근처)
```css
.mst{scroll-margin-top:64px}
```
(헤더가 붙어 있는 화면에서 펼칠 때 박스 윗부분이 헤더에 가리지 않게 — 실제 헤더 높이에 맞춰 값 조정, 390px 실측으로 확인)

**③ 손대지 않는 것**: `masterGrid()` 내용 · `#msheet` 마크업 · `.mkey`/`.mkey.on` CSS(글자만 `마스터`로 짧아짐) · 헤더 버튼 순서.
→ 390px에서 헤더가 **한 줄**인지 반드시 확인(§2-4 3번). 넘치면 `마스터` 대신 `🔓` 로 줄이고 `title`·`aria-label` 은 그대로 둔다(색깔 버튼·편집 버튼을 줄이지 않는다).

### 2-4. 합격 (182) — 실제로 눌러서, 캡처까지
1. **손님**: 시크릿 창(저장값 없음) → 첫 화면에 마스터 박스 **0px** · `⚙` 누름 → PIN 시트 뜸 → `0000` → `PIN이 맞지 않습니다` → `2899` → 박스 펼침 + 열쇠 0 상태에서 유료 도구 열림.
2. **대표님**: PIN 저장된 창 새로고침 → 첫 화면 마스터 박스 **없음** · 헤더 `마스터` 버튼 · 누름 → 펼침(도구 칩 채워짐) · 다시 누름 → 접힘 · **새로고침 → 다시 접힘** · 박스 접힌 채로 상품 상세 진입 → **이용권 창 안 뜸**(마스터 유효) · 박스 안 `[해제]` → `⚙` 복귀 + 이용권 창 다시 뜸.
3. **390×844 헤더 한 줄** · 가로 스크롤 0 · `[편집]`·색깔1·색깔2·`🔑`·`마스터` 모두 눌림 · 도우미 버튼 위치 그대로.
4. **캡처 5장** → `output/master_box_20261124/`: `182_00_before.png`(바꾸기 전 자동 펼침) `182_01_guest.png` `182_02_closed.png` `182_03_open.png` `182_04_cleared.png` + 1440px 1장.
5. 콘솔 에러 0 · `git diff --stat` 에 **`oneclick/index.html` 하나만**.

---

## 3. 과업 2 — 181 · 번개알바 사장님 구글 캘린더 1클릭 연결 마법사

### 3-1. 파일 (신규 · `oneclick/bungee_sample/gcal_connect/`)
```
index.html                 ← 마법사 본체(단일 파일 · CSS/JS 인라인 · 390px 우선)
gas_kts_calendar.js        ← §3-4 코드 그대로(사장님이 파일로도 받을 수 있게 · 페이지 내장 코드와 바이트 동일)
mock_gas.js                ← ?mock=1 검사용 모의 응답(실사용 경로에서는 절대 로드하지 않음)
README_사장님설치.md        ← 사장님용 5단계(인쇄 가능) · 배포 화면 이름까지 그대로
```
- 톤: 딥네이비·오렌지 공통(`shared/kts-ui.css` 의 색 변수 재사용 가능). **쇼룸 카드형 UI를 복사하지 않는다** — 마법사는 "설명서 한 장"처럼 위→아래 3단.
- 외부 요청 0(로드 시). `script.new` 는 **링크 클릭 시**에만 열린다.
- 화면 아래 고정 1줄: `샘플 · 서버비 0원 · 카드 등록 없음 · 사장님 구글 계정 안에서만 실행됩니다`

### 3-2. 화면 (390 위→아래)

```
[머리] 번개알바 · 사장님 도구
H1  사장님 구글 캘린더, 1분이면 연결 끝
부제 예약 시간을 읽고, 손님 예약을 사장님 캘린더에 넣습니다. 서버도, 월 요금도 없습니다.

■ 1단계  ── 코드 복사 (10초)
  [ 코드 1클릭 복사 ]            ← 가장 큰 오렌지 버튼(높이 52px)
  · 예약 시간 계산 + 일정 등록 코드 1장 (아래 [미리보기] 로 내용 확인)
  · 복사되면 버튼이 [ 복사 완료 · 8,2xx자 ] 로 바뀐다

■ 2단계  ── Apps Script 열기 (30초)
  [ Google Apps Script 바로 열기 ]   ← 새 탭(script.new)
  ① 열린 화면의 기존 코드를 모두 지우고 [붙여넣기]
  ② 위쪽 이름을 KTS-예약 으로 → [저장]
  ③ 오른쪽 위 [배포] → [새 배포] → 유형 [웹 앱]
     · 실행: 나    · 액세스: 모든 사용자
     → [배포] → 나오는 주소(…/exec) [복사]

■ 3단계  ── 주소 붙여넣고 연결 테스트 (20초)
  [ https://script.google.com/macros/s/…/exec ]  ← input(type=url, inputmode=url)
  [ 연결 테스트 ]  ← 남색 테두리 버튼
  ┌ 결과 카드(테스트 중에는 줄별로 하나씩 켜짐 · 스피너)
  │ ✅ 주소 확인 · ✅ 사장님 캘린더 연결(캘린더 이름 표시) · ✅ 오늘 빈 시간 3개: 18:00 · 18:30 · 19:00
  │ ✅ 테스트 일정 1건 등록(내일 10:00)  [ 테스트 일정 지우기 ]
  └ 실패하면: 빨간 줄 1개 + 아래 '안 될 때 3가지' 접이식

■ 연결됨 (위 3단계를 통과했을 때만)
  초록 배지  구글 캘린더 연결됨 · 2026-11-24 10:4x
  [ 산수고원 예약 페이지로 ]   [ 연결 해제 ]
```
- **'안 될 때 3가지'**(접힘): ① 액세스가 `모든 사용자`인지(익명 포함) ② 주소 끝이 `/exec` 인지(`/dev` 아님) ③ 회사·학교 계정은 관리자가 막을 수 있음 → 개인 `@gmail.com` 으로.
- 큰 글씨·큰 버튼(최소 44px). 코드 블록은 `[미리보기]` 접이식(`<pre>`, 앞 12줄만, `white-space:pre-wrap; overflow:auto`) — **복사되는 것은 전문**.

### 3-3. 통신 규격 (페이지 ↔ GAS · 이 표가 계약이다)

| # | 방향 | 요청 | 응답(JSON) |
|---|---|---|---|
| 1 | 읽기 | `GET ?action=ping&callback=cb` | `{ok:true, service:'KTS-GCal', version, shop, calendar, tz, now, rule}` |
| 2 | 읽기 | `GET ?action=slots&date=2026-11-24&party=4&days=2&callback=cb` | `{ok:true, shop, party, rule, days:[{date, closed, slots:['18:00','18:30',…]}]}` |
| 3 | 읽기 | `GET ?action=rule&callback=cb` | `{ok:true, text:'11:30~21:30 · 브레이크 …'}` |
| 4 | 쓰기 | `POST` body(JSON) `{action:'book', date, time, party, name, phone, room, memo, client:'sansugowon'}` | `{ok:true, id, when, party, title}` / `{ok:false, code:'TAKEN'/'TOO_SOON'/'CLOSED'/'NEED_NAME'/'BAD_INPUT', message}` |
| 5 | 쓰기 | `POST` `{action:'test', client}` | `{ok:true, id, when}` (내일 10:00 · `KTS 연결 테스트`) |
| 6 | 쓰기 | `POST` `{action:'cancel', id}` | `{ok:true}` / `{ok:false, code:'NOT_OURS'/'NOT_FOUND'}` |

**전송 방식 — 이유까지 지켜서 구현한다**

| 동작 | 방식 | 이유 |
|---|---|---|
| 읽기(1·2·3) | **JSONP**: `script.src = url + (url.indexOf('?')<0?'?':'&') + 'callback=cb_'+n` · `window['cb_'+n]=fn` · 8초 타임아웃 후 `script` 제거·`cb` 삭제 | GAS 웹 앱은 CORS 헤더를 주지 않아 `fetch` 가 막힌다. `<script>` 는 `script.googleusercontent.com` 리다이렉트를 따라가고 CORS 대상이 아니다 |
| 쓰기(4·5·6) | `fetch(url,{method:'POST', mode:'no-cors', headers:{'Content-Type':'text/plain;charset=utf-8'}, body:JSON.stringify(...)})` | preflight 회피. **응답 본문은 읽을 수 없다**(opaque) → 성공 판정은 아래 재조회로 한다 |
| 결과 확인 | POST 1.5초 뒤 `slots` 재조회 → 그 시간이 목록에서 사라졌으면 성공. 최대 3회(1초 간격) | "보냈다"와 "달력에 들어갔다"를 구분한다 |
| mock | `?mock=1` 이면 1·2·3·4·5·6 을 `mock_gas.js` 로 처리 | 구글 계정 없이 전체 흐름을 검사(§3-5) |

- `callback` 이름은 `cb_` + 증가번호(전역 오염 금지), 응답은 `typeof data==='object'` 확인 후 사용.
- 주소 검증: `^https://script\.google\.com/macros/s/[A-Za-z0-9_\-]{20,}/exec$` (앞뒤 공백 제거). 아닐 때 문구: `Apps Script 웹 앱 주소(…/exec)가 아닙니다 · [배포] 화면에서 복사한 주소를 넣어 주세요`.
- 타임아웃 문구: `응답이 없습니다 · 배포 액세스가 '모든 사용자'인지 확인해 주세요`.

### 3-4. GAS 완성형 코드 (그대로 넣는다 · `gas_kts_calendar.js` 와 페이지 내장 코드는 **바이트 동일**)

```javascript
/* ============================================================
   KTS 원클릭 — 사장님 구글 캘린더 예약 연결 (Google Apps Script)
   서버비 0원 · 카드 등록 없음 · 사장님 구글 계정 안에서만 실행
   배포: 배포 → 새 배포 → 유형 [웹 앱] · 실행 [나] · 액세스 [모든 사용자] → 배포 → URL 복사
   ============================================================ */
var CFG = {
  shop: '산수고원',
  calendarId: 'primary',
  tz: 'Asia/Seoul',
  offset: '+09:00',
  open: '11:30',
  close: '21:30',
  breakStart: '16:00',
  breakEnd: '17:00',
  lastOrder: '20:30',
  slotMin: 30,
  leadMin: 60,
  maxDays: 14,
  maxParty: 30,
  closedDays: [],
  blockTitle: '[예약]',
  testTitle: 'KTS 연결 테스트',
  version: '1.0'
};

function doGet(e) {
  var out;
  try { out = onGet(e || {}); } catch (err) { out = { ok: false, code: 'ERROR', message: String(err) }; }
  return reply(out, e || {});
}

function doPost(e) {
  var out;
  try { out = onPost(e || {}); } catch (err) { out = { ok: false, code: 'ERROR', message: String(err) }; }
  return reply(out, e || {});
}

function onGet(e) {
  var p = e.parameter || {};
  var a = String(p.action || 'ping');
  if (a === 'ping') return ping();
  if (a === 'rule') return { ok: true, text: ruleText() };
  if (a === 'slots') return slots(String(p.date || today()), Number(p.party || 2), Number(p.days || 1));
  return { ok: false, code: 'BAD_ACTION', message: '알 수 없는 요청입니다: ' + a };
}

function onPost(e) {
  var p = e.parameter || {};
  var body = {};
  try { body = JSON.parse(String((e.postData || {}).contents || p.data || '{}')); } catch (err) { body = {}; }
  var a = String(p.action || body.action || '');
  if (a === 'book') return book(body);
  if (a === 'test') return makeTest(String(body.client || p.client || ''));
  if (a === 'cancel') return cancel(String(body.id || p.id || ''));
  return { ok: false, code: 'BAD_ACTION', message: '알 수 없는 요청입니다: ' + a };
}

function reply(obj, e) {
  var cb = String((e.parameter || {}).callback || '');
  var json = JSON.stringify(obj);
  if (cb && /^[A-Za-z_$][A-Za-z0-9_$]{0,60}$/.test(cb)) {
    return ContentService.createTextOutput(cb + '(' + json + ');')
      .setMimeType(ContentService.MimeType.JAVASCRIPT);
  }
  return ContentService.createTextOutput(json).setMimeType(ContentService.MimeType.JSON);
}

/* ---------- 공통 ---------- */
function cal() {
  if (CFG.calendarId && CFG.calendarId !== 'primary') {
    var c = CalendarApp.getCalendarById(CFG.calendarId);
    if (c) return c;
  }
  return CalendarApp.getDefaultCalendar();
}
function today() { return Utilities.formatDate(new Date(), CFG.tz, 'yyyy-MM-dd'); }
function two(n) { return (n < 10 ? '0' : '') + n; }
function hhmm(s) { var t = String(s).split(':'); return Number(t[0]) * 60 + Number(t[1] || 0); }
function stamp(min) { return two(Math.floor(min / 60)) + ':' + two(min % 60); }
function dt(dateStr, min) { return new Date(dateStr + 'T' + stamp(min) + ':00' + CFG.offset); }
function weekday(ds) { return new Date(ds + 'T12:00:00' + CFG.offset).getUTCDay(); }
function iso(d) { return Utilities.formatDate(d, CFG.tz, "yyyy-MM-dd'T'HH:mm:ss"); }
function ruleText() {
  return CFG.open + '~' + CFG.close + ' · 브레이크 ' + CFG.breakStart + '~' + CFG.breakEnd +
    ' · 라스트오더 ' + CFG.lastOrder + ' · ' + CFG.slotMin + '분 단위 · 지금부터 ' +
    (CFG.leadMin / 60) + '시간 뒤부터 · ' + CFG.maxDays + '일 앞까지 · 한 번에 ' + CFG.maxParty + '명까지';
}

function ping() {
  var c = cal();
  return {
    ok: true, service: 'KTS-GCal', version: CFG.version, shop: CFG.shop,
    calendar: c.getName(), tz: CFG.tz, now: iso(new Date()), rule: ruleText()
  };
}

function busyMap(dateStr) {
  var start = new Date(dateStr + 'T00:00:00' + CFG.offset);
  var end = new Date(start.getTime() + 24 * 3600 * 1000);
  var evs = cal().getEvents(start, end);
  var out = [];
  for (var i = 0; i < evs.length; i++) {
    var t = String(evs[i].getTitle() || '');
    var ours = (t.indexOf(CFG.blockTitle) === 0 || t.indexOf(CFG.testTitle) === 0);
    if (evs[i].isAllDayEvent() && !ours) continue;
    out.push({ s: evs[i].getStartTime().getTime(), e: evs[i].getEndTime().getTime() });
  }
  return out;
}

function slots(dateStr, party, days) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
    return { ok: false, code: 'BAD_DATE', message: '날짜는 YYYY-MM-DD 형식이어야 합니다' };
  }
  party = Math.max(1, Math.min(CFG.maxParty, party || 2));
  days = Math.max(1, Math.min(CFG.maxDays, days || 1));
  var base = new Date(dateStr + 'T00:00:00' + CFG.offset);
  var notBefore = new Date().getTime() + CFG.leadMin * 60000;
  var res = [];
  for (var d = 0; d < days; d++) {
    var ds = Utilities.formatDate(new Date(base.getTime() + d * 24 * 3600 * 1000), CFG.tz, 'yyyy-MM-dd');
    if (CFG.closedDays.indexOf(weekday(ds)) >= 0) {
      res.push({ date: ds, closed: true, slots: [] });
      continue;
    }
    var busy = busyMap(ds);
    var list = [];
    var from = hhmm(CFG.open);
    var to = Math.min(hhmm(CFG.lastOrder), hhmm(CFG.close));
    for (var m = from; m + CFG.slotMin <= to; m += CFG.slotMin) {
      if (m >= hhmm(CFG.breakStart) && m < hhmm(CFG.breakEnd)) continue;
      var st = dt(ds, m), en = dt(ds, m + CFG.slotMin);
      if (st.getTime() < notBefore) continue;
      var free = true;
      for (var k = 0; k < busy.length; k++) {
        if (st.getTime() < busy[k].e && en.getTime() > busy[k].s) { free = false; break; }
      }
      if (free) list.push(stamp(m));
    }
    res.push({ date: ds, closed: false, slots: list });
  }
  return { ok: true, shop: CFG.shop, party: party, rule: ruleText(), days: res };
}

function book(b) {
  var dateStr = String(b.date || '');
  var time = String(b.time || '');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr) || !/^\d{1,2}:\d{2}$/.test(time)) {
    return { ok: false, code: 'BAD_INPUT', message: '날짜·시간 형식이 맞지 않습니다' };
  }
  var name = String(b.name || '').slice(0, 40);
  if (!name) return { ok: false, code: 'NEED_NAME', message: '예약자 이름이 필요합니다' };
  var party = Math.max(1, Math.min(CFG.maxParty, Number(b.party || 2)));
  var m = hhmm(time);
  var st = dt(dateStr, m), en = dt(dateStr, m + CFG.slotMin);
  if (st.getTime() < new Date().getTime() + CFG.leadMin * 60000) {
    return { ok: false, code: 'TOO_SOON', message: '지금부터 ' + (CFG.leadMin / 60) + '시간 뒤부터 받습니다' };
  }
  if (CFG.closedDays.indexOf(weekday(dateStr)) >= 0) {
    return { ok: false, code: 'CLOSED', message: '쉬는 날입니다' };
  }
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(10000)) return { ok: false, code: 'BUSY', message: '잠시 뒤 다시 시도해 주세요' };
  try {
    var busy = busyMap(dateStr);
    for (var i = 0; i < busy.length; i++) {
      if (st.getTime() < busy[i].e && en.getTime() > busy[i].s) {
        return { ok: false, code: 'TAKEN', message: '방금 마감되었습니다 · 다른 시간을 골라 주세요' };
      }
    }
    var title = CFG.blockTitle + ' ' + name + ' ' + party + '인' +
      (b.room ? ' · ' + String(b.room).slice(0, 20) : '');
    var desc = '예약자: ' + name +
      '\n연락처: ' + String(b.phone || '').slice(0, 20) +
      '\n인원: ' + party +
      (b.room ? '\n자리: ' + String(b.room).slice(0, 20) : '') +
      (b.memo ? '\n메모: ' + String(b.memo).slice(0, 200) : '') +
      '\n접수: KTS 원클릭' + (b.client ? ' · ' + String(b.client).slice(0, 30) : '');
    var ev = cal().createEvent(title, st, en, { description: desc });
    return { ok: true, id: ev.getId(), when: dateStr + ' ' + stamp(m), party: party, title: title };
  } finally {
    lock.releaseLock();
  }
}

function makeTest(client) {
  var ds = Utilities.formatDate(new Date(new Date().getTime() + 24 * 3600 * 1000), CFG.tz, 'yyyy-MM-dd');
  var st = dt(ds, 600), en = dt(ds, 600 + CFG.slotMin);
  var ev = cal().createEvent(CFG.testTitle, st, en, {
    description: 'KTS 원클릭 연결 테스트' + (client ? ' · ' + client : '') + '\n확인 뒤 지우셔도 됩니다.'
  });
  return { ok: true, id: ev.getId(), when: ds + ' 10:00' };
}

function cancel(id) {
  if (!id) return { ok: false, code: 'NEED_ID', message: 'id 가 없습니다' };
  var ev = cal().getEventById(id);
  if (!ev) return { ok: false, code: 'NOT_FOUND', message: '그 일정을 찾을 수 없습니다' };
  var t = String(ev.getTitle() || '');
  if (t.indexOf(CFG.blockTitle) !== 0 && t.indexOf(CFG.testTitle) !== 0) {
    return { ok: false, code: 'NOT_OURS', message: '이 도구가 만든 일정이 아닙니다' };
  }
  ev.deleteEvent();
  return { ok: true, id: id };
}
```

- 페이지에는 `<script type="text/plain" id="gasSrc">…</script>` 로 **전문**을 넣고, 복사 버튼은 `textContent` 를 그대로 `navigator.clipboard.writeText` 로 넘긴다(실패 시 `textarea+execCommand` 폴백). 복사 전후로 **앞 20자·뒤 20자·길이**를 콘솔에 남겨 보고서에 적는다.
- 사장님 매장이 다른 곳이면 `CFG.shop`·영업시간·`blockTitle` 만 바꾸면 된다(README §3에 1줄).
- 코드에 **비밀번호·키·토큰 없음**. `calendarId:'primary'` 대신 예약 전용 캘린더 ID를 넣는 방법도 README에 1줄(권장).

### 3-5. `mock_gas.js` 요구 (검사 모드 · 실사용 경로에서 로드 금지)
- `?mock=1` 로 들어왔을 때만 `<script src="mock_gas.js">` 를 넣는다.
- `window.KTSMock = { get(action, params, cb), post(body, cb) }` — ping·slots(오늘+내일, 내일 10:00 은 비어 있음)·test(내일 10:00 등록 → `kts_gcal_mock_events` 에 저장)·book(중복이면 `TAKEN`)·cancel. 실제 달력 대신 `localStorage['kts_gcal_mock_events']` 를 쓴다.
- 페이지는 mock 모드에서 **입력칸에 `mock`** 을 채우고 `[연결 테스트]` 가 같은 5단계를 돌게 한다. 화면 위에 작은 회색 띠 `검사 모드(모의 응답) — 실제 구글 연결 아님`.
- 목적: 구글 계정 로그인 없이 **복사→테스트→연결→해제→sansugowon 반영**을 끝까지 캡처해 증명하기 위해서다. 실사용 경로(URL 입력)에서는 이 파일을 절대 쓰지 않는다.

### 3-6. 산수고원 샘플 연결 (04 결과가 있을 때만 · 3곳)
1. 캘린더 규칙 패널에 1줄: `사장님 구글 캘린더로 실제 빈 시간 받기 — [1분 연결](../gcal_connect/)`.
2. 로드 시 `var gurl = localStorage.getItem('kts_gcal_webapp_url')`.
   - **있으면**: 예약 시트 상단 배지 `구글 캘린더 연결됨` · 가용 시간은 GAS `action=slots`(오늘·내일) 결과로 채우고, 접수 시 `action=book` 전송 → 성공하면 `예약 요청 접수 · 사장님 캘린더에 일정이 등록되었습니다` + 기존 `.ics`도 함께 제공(백업).
   - **실패·타임아웃(6초)이면**: 조용히 04의 규칙 엔진으로 폴백 + 배지 `규칙 엔진(샘플)` — **예약 흐름이 절대 멈추지 않는다.**
   - **없으면**: 04 그대로(규칙 엔진 + `.ics`).
3. 04의 `샘플 · 실제 예약은 매장 전화` 문구는 **연결 후에도 유지**(매장 확인 없이 확정 아님).

### 3-7. 개인정보·보안·문구 규칙 (GAS 안에서 지킨다)
- `slots` 는 **빈 시간 문자열만** 반환. 일정 제목·참석자·설명·다른 사람 이름·전화번호 반환 금지(`busyMap` 내부에서만 쓰고 버린다).
- 등록은 ① 지금부터 `leadMin` 이후 ② `maxDays` 이내 ③ 영업시간·브레이크 밖 슬롯 ④ `maxParty` 이하 ⑤ 제목에 `[예약]` 고정 — 이 5개를 코드에서 강제(§3-4에 구현됨).
- 삭제는 **이 도구가 만든 일정만**(`[예약]`/`KTS 연결 테스트` 접두).
- 동시 요청은 `LockService` 로 잠그고 겹침을 다시 확인(예약 중복 방지).
- 웹 앱 주소는 손님 페이지에도 들어가는 **공개 주소**로 취급한다 → README 에 "예약 전용 캘린더 권장" 1줄(개인 캘린더를 쓰더라도 제목은 나가지 않음).
- 문구: `예약 요청 접수`(완료 아님) · `개인정보는 사장님 캘린더에만 저장됩니다` · `서버비 0원` 은 **Apps Script 무료 할당량 안에서**라는 조건을 같은 줄에 작게 병기.

### 3-8. 합격 (181)
1. **문법**: `node --check gas_kts_calendar.js` → 0 errors. (node 없으면 `esprima`/GAS 편집기 저장으로 대체하고 어느 방법인지 보고)
2. **바이트 동일**: 페이지 내장 코드와 `gas_kts_calendar.js` `diff` → 0줄.
3. **1클릭 복사 실측**: 클립보드 내용 = 파일 내용 · 길이 일치 · `…`·스마트따옴표(`“”‘’`) 0개 · `CFG`·`doGet`·`doPost` 포함.
4. **mock 전체 흐름**: `?mock=1` → 복사 → 테스트 5줄 전부 ✅ → 연결 배지 → `[연결 해제]` 로 원복 → 다시 연결. 캡처 3장(`181_01_step1.png` `181_02_test_ok.png` `181_03_connected.png`).
5. **실패 3종**: `https://example.com/x` → 주소 형식 오류 · 응답 없는 주소 → 8초 타임아웃 문구 · mock 에서 `TAKEN` → `방금 마감되었습니다` 표시. 콘솔 에러 0.
6. **sansugowon 2상태**: 연결됨(배지·실제 빈 시간 3개·접수 시 캘린더 등록 문구) / 미연결(규칙 엔진 + `.ics`) — 캡처 각 1장. 04 미실행이면 이 항목 대신 `생략` 1줄.
7. **모바일**: 390×844 전 단계 스크롤 최소 · 입력칸 포커스 시 확대 안 됨(`font-size:16px`) · 1440px 1장.
8. **실제 구글 배포 1회**는 대표님 계정 로그인이 필요해 PC가 못 한다 → **숨기지 말고** 보고서 `대표님 확인 필요` 항목으로 남긴다(누가·무엇을: 개인 `@gmail.com` 으로 §3-2 2단계 5줄, 걸리는 시간 2분, 확인 뒤 실제 손님 흐름 1회).

---

## 4. 최종 검증 (두 과업 끝나고 한 번에)
1. `git diff --stat` 로 확인: `oneclick/index.html`, `bungee_sample/gcal_connect/*`(신규 4), `bungee_sample/sansugowon/index.html`(3곳) — **그 외 0**. `oneclick/bungee/` 0줄.
2. `products.js`·`catalog.json`·`detail.html`·`helper.js`·`shared/kts-edge.js` diff 0줄(= 쇼룸 등록 0).
3. 콘솔 에러 0 · 쇼룸 첫 화면 390px 캡처 회귀 0(5대 대문·편집·색깔·도우미·🔑 카운트).
4. 캡처 폴더: `output/master_box_20261124/`(5+1장), `output/gcal_connect_20261124/`(6장 이상).
5. 커밋 2개로 나눠 푸시: `fix(showroom): 182 마스터 박스 기본 접힘 — 첫 화면은 손님 화면 그대로` / `feat(bungee_sample): 181 사장님 구글 캘린더 1클릭 연결 마법사(GAS·서버비 0원)`.

---

## 5. 보고서 형식 (`CLAUDE_RESULT_20261124_05_MASTER_GCAL.md`)
```
# 결과 — 2026-11-24 ⑤ 마스터 박스 기본 접힘(182) + 구글 캘린더 1클릭 연결(181)
0. 기준 커밋 · 바뀐 파일(git diff --stat) · 커밋 2개 SHA
1. 182 — 바꾸기 전/후 캡처 · 6가지 동작표 실측 결과 · 헤더 390px 한 줄 · 회귀 0
2. 181 — 3단 화면 캡처 · 복사 실측(길이·앞뒤 20자·`…` 0) · 내장/파일 diff 0 · node --check 결과
3. 181 — mock 5단계 결과 · 실패 3종 문구 · 실제 요청 수(로드 시 0)
4. 181 — sansugowon 연결됨/미연결 2상태 결과(또는 생략 사유)
5. 개인정보·보안 체크 — slots 응답에 제목·참석자 0 · 삭제는 도구 생성 일정만 · LockService 확인
6. 대표님 확인 필요 — 실제 @gmail.com 배포 1회(2분) · 확인 항목 5줄
7. 오류 원문(있으면)
8. 다음 단계(쇼룸 등록 여부는 대표님 판단 · 착신전환 AI 전화비서 종량제)
```

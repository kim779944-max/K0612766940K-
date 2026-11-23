# PC 클로드 코드 작업 지시서 — 2026-11-23 · 원클릭 공통 틀(디자인 시스템) + 쇼룸 메인 개편 + 검수 2건 수리 (적립 133·138번)

> 발령: 2026-11-23 13:3x KST · 사령관 지니 → PC 클로드 코드(Pro)
> 대표님 지시 원문:
> - **"그런 것들하고 그 틀을 같이 맞출 수 있나?"** (138번) → 도구마다 따로 놀던 헤더·카드·버튼·여백을 **공통 1벌**로 모은다. **다크 기본 / 라이트 토글**(브라우저 기억), **A4 인쇄는 항상 흰 배경** 강제.
> - **"디자인 시안 2페이지처럼"** (133번) → 쇼룸 맨 위 **대표 3종(매물장 뷰어·더싸인·경사도)** 을 크게, 아래는 **4대 업종 묶음**(부동산·중개사 / 쇼핑몰·셀러 / 자영업·매장 / 개인·생활).
> - 어제(11-22) 390px 실물 검수 2건: ① `helper.js` 도우미 버튼이 카드 `[열기]`/`[+]` 를 가림 ② 쇼룸 가계부 카드명 `원클릭 가계부` → **`결제문자 가계부`** 통일 + 부제 중복 제거.
> 대상 저장소: **`kim779944-max/oneclick`** — 신규 `shared/` + `index.html` 개편 + `helper.js` 위치 + `products.js`·`catalog.json`(가계부 이름 1건·매물장 카드 1건) 만.
> 결과 보고서: **`CLAUDE_RESULT_20261123_SHARED_SHOWROOM.md`** (`K0612766940K-` 저장소에 작성·커밋·푸시)
> 기준선(2026-11-23 13:1x KST, 지니가 실제로 확인): `oneclick` **`d6f95a9`**(`catalog.json` v `20261122a` · count **27** / `products.js` 27종) · `K0612766940K-` **`bd2293d`**
> 기준 디자인 원본: `K0612766940K-` 의 **`refs/v0_listing_20261123/`** (v0 성수 어반빌딩 시안 전체) + 디자인 시안 PDF 2페이지(쇼룸)
> **이 지시서는 2순위다.** 1순위(`CLAUDE_TASK_20261123_SLOPE_UI_PRINT.md`)와 3순위(`CLAUDE_TASK_20261123_LISTING_VIEWER.md`)가 같은 `oneclick` 저장소를 건드리므로, **pull --rebase 후 양쪽 변경을 살려서** 푸시한다.

---

## 0. 이 문서 하나만 읽고 끝까지 실행하세요

### 0-1. 이번 회차 결과물 (한 문장)
**`oneclick/shared/` 에 딥네이비·오렌지 고정 + 다크/라이트 두 벌 토큰·헤더·카드·44px 버튼·푸터·인쇄 규칙이 1벌로 생기고, 쇼룸 첫 화면이 "대표 3종 → 4대 업종 묶음" 구조로 바뀌며, 도우미 버튼이 카드 [열기]를 더 이상 가리지 않고, 가계부 이름이 `결제문자 가계부` 하나로 통일된다.**

### 0-2. 하지 않는 것 (하나라도 어기면 그 항목은 실패로 기록)

1. **제0원칙 — 도구 로직·데이터 불변.** `slope/`·`sign/`·`theform/`·`contract/`·`viewer.html`·`realty/`·`redev/`·`gagebu/`·`sale/` 등 **도구의 JS·계산·저장 로직은 한 줄도 바꾸지 않는다.** 이번에 `shared/` 를 **링크하는 것은 쇼룸(`index.html`)과 새로 만드는 매물장뿐**이다(나머지 도구는 3순위 이후 확산 — 이번에 45개 페이지를 건드리지 않는다).
2. **가격을 만들지 않는다.** 시안 2페이지의 `월 [가격]원` 자리는 **비어 있는 자리표시자**다. 확정된 가격은 지금 **10건권 9,000원(부가세 별도)** 뿐이므로, **새 요금표를 신설하지 않는다**. 시안의 `[가격 보기]` 버튼은 **`[도구 전체 보기]`(아래 묶음으로 스크롤)** 로 대체한다.
3. **기존 기능 삭제 금지** — 아래는 전부 그대로 살아 있어야 한다: `[★ 내 단축바]` 탭 · `KTS_KEYS` 열기 관문(1회 무료 시연 → 내 박스) · 마스터 모드(PIN 2899 · `?master=`) · `[해주세요 · Q&A]` 투표 · 무료 이용권 문자 링크(`sms:01020022899`) · `master.js`·`slots.js`·`status.js`·`helper.js` 로드 · `detail.html?k=` 링크 · 맨 위로 버튼.
4. **목록 유실 금지** — `products.js` **28종**(기존 27종 + 이번에 추가하는 `listing`, 준비 중 3종 포함) **+ `LOCAL` 7종 = 35개**가 하나도 빠지지 않고 **묶음 안에 정확히 한 번씩** 나타나야 한다(§5-1 자동 검사). *대표 3종 블록은 강조용 복제라 검사에서 제외한다.*
5. **지어내기 금지** — 실제 390 캡처·인쇄 미리보기 캡처 없이 "됐다"고 쓰지 않는다.
6. **관문 6 유지** — 대외 광고·문자 발송·스토어 업로드 0건.
7. **비밀값·실명 커밋 금지** — 공개 저장소다. 실명(`김태수`는 게이트 G1-6 이 잡는다)·키·PC 경로 금지.
8. **되돌릴 수 있게** — 손대기 전 `oneclick` `git rev-parse HEAD` 를 적어 보고서 §1에 넣는다(기대 `d6f95a9`).

### 0-3. 진행 규칙
- **A → B → C → D** 순서(§2~§5). 덩어리마다 커밋(90분 회차 제한 대비).
- **최소 합격선 = A(공통 틀) + B(쇼룸 개편)**. C(수리 2건)는 짧으니 먼저 해도 되지만 **A의 토큰을 쓰기 전에 색을 손으로 고치지 말 것**.
- 3순위(매물장 뷰어)가 이어서 `listing/` 을 만들고 **`products.js`·`catalog.json` 의 `listing` 항목을 `live` 로 바꾼다.** 이번 회차에서는 **`listing` 카드를 `준비 중`으로만** 깔아 둔다(§4-2) — **없는 페이지로 링크를 걸어 404를 만들지 않는다.**

---

## 1. 0단계 — 저장소·기준 시안 (15분)

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\oneclick"
git pull --rebase; git rev-parse --short HEAD      # 기대: d6f95a9 이상
```
- `refs/v0_listing_20261123/` 는 `K0612766940K-` 저장소에 있다(오늘 발행). 없으면 `git pull` 후 다시 확인한다.

### 1-1. 시안에서 **뽑아 쓸 값** (그대로 토큰이 된다)
| 출처 | 값 |
|---|---|
| `app/globals.css` `:root` | `--bg:#0b132b` · `--panel:#141f38` · `--line:#2a354e` · `--muted:#a5b1c7` · `--accent:#ff6b00` · 글자 `#f4f6fb` |
| `app/globals.css` 기본 | 본문 **15px** · `word-break:keep-all` · `line-height:1.55` · `:focus-visible{outline:2px solid #ff994b;outline-offset:3px}` |
| `app/globals.css` 카드 | `border-radius:12px`(큰 카드 14px) · `padding:21px 23px` · `border:1px solid var(--line)` · 배경 `var(--panel)` |
| `app/globals.css` 제목 | 섹션 제목 **19px · 690** · 큰 제목 `clamp(36px,4vw,56px)` · 본문 보조 12~13px `var(--muted)` |
| `app/globals.css` 표 | `padding:11px 12px` · `font-variant-numeric:tabular-nums` · 머리 `#1d2942` 12px |
| `app/globals.css` 인쇄 | `@media print` — 흰 배경·`#111827` 글씨 강제, `break-inside:avoid`, `.wrap{max-width:none}` |
| 시안 2페이지(쇼룸) | 대표 도구 = **큰 카드**(오렌지 테두리 강조 1개 + 아래 2개), 업종 탭/묶음, 하단 요금 3단(요금표는 **만들지 않는다** — §0-2-2) |
| 시안 3페이지(라이트) | 라이트는 **흰 바탕 + 아이보리 카드 + 오렌지 포인트**. 토큰 라이트 벌의 근거로 쓴다 |
> 보고서 §2에 **"읽은 값 6개(색 5 + 간격/radius/글자)"** 를 숫자로 적는다.

---

## 2. A. `oneclick/shared/` — 공통 틀 1벌 (신규)

### 2-1. 파일 5개 (이름 고정 — 3순위 매물장이 같은 파일을 링크한다)
| 파일 | 내용 |
|---|---|
| **`shared/kts-tokens.css`** | 색·글자·간격·radius·그림자 변수 **2벌**. `:root` = 다크(기본), `html[data-kts-theme="light"]` = 라이트. **오렌지는 두 벌 모두 `#ff6b00` 고정**(브랜드) |
| **`shared/kts-ui.css`** | 헤더 · 상단 공지 띠 · 카드(`.k-card`) · 요금/한도 배지(`.k-badge`) · 버튼 3종(`.k-btn`=`주`, `.k-btn.ghost`=`보조`, `.k-tog`=`토글`) · 표(`.k-tbl`) · 푸터(`.k-foot`) · 테마 토글(`.k-theme`) |
| **`shared/kts-print.css`** | `@media print` 공통: 흰 배경·검은 글씨 강제, `header/footer/.k-noprint` 숨김, `.k-card{break-inside:avoid}`, `print-color-adjust:exact` |
| **`shared/kts-ui.js`** | ① 테마 적용·토글(`localStorage['kts_theme']` = `dark`\|`light`, 없으면 `dark`) ② `beforeprint` → `document.documentElement.classList.add('kts-printing')`, `afterprint` → 해제 ③ `window.KTSUI = {theme(), setTheme(), toggle()}` |
| **`shared/README.md`** | 적용법 3줄: `<link rel="stylesheet" href="shared/kts-tokens.css">` → `kts-ui.css` → 페이지 CSS → `<script src="shared/kts-ui.js" defer></script>` (**페이지 CSS가 항상 마지막** — 기존 도구 색을 덮지 않게) |

### 2-2. 토큰 값 (이 숫자로 시작하고, 화면에서 눈으로 확인한 뒤 미세조정만)
```
[다크 — 기본]
--k-bg:#0b132b; --k-panel:#141f38; --k-panel-2:#1a2745; --k-line:#2a354e; --k-line-2:#36425c;
--k-ink:#f4f6fb; --k-ink-2:#a5b1c7; --k-ink-3:#7d8ba3;
--k-accent:#ff6b00; --k-accent-2:#ff994b; --k-on-accent:#141414;
--k-ok:#22c55e; --k-warn:#f59e0b; --k-danger:#ef4444;

[라이트 — html[data-kts-theme="light"]]
--k-bg:#f6f7f9; --k-panel:#ffffff; --k-panel-2:#faf7f2; --k-line:#e3e7ee; --k-line-2:#cfd6e0;
--k-ink:#111827; --k-ink-2:#5b6878; --k-ink-3:#8794a5;
--k-accent:#ff6b00; --k-accent-2:#ff8a33; --k-on-accent:#ffffff;

[공통]
--k-radius:12px; --k-radius-lg:14px; --k-radius-sm:8px;
--k-sp-1:6px; --k-sp-2:10px; --k-sp-3:14px; --k-sp-4:18px; --k-sp-5:24px; --k-sp-6:32px;
--k-fs-h1:27px; --k-fs-h2:19px; --k-fs-h3:16px; --k-fs:15px; --k-fs-sm:13px; --k-fs-xs:12px; --k-fs-2xs:10.5px;
--k-tap:44px;                    /* 모든 버튼 최소 높이 */
--k-shadow:0 8px 20px rgba(0,0,0,.18);
--k-font:-apple-system,BlinkMacSystemFont,"Apple SD Gothic Neo","Malgun Gothic","Noto Sans KR",Roboto,sans-serif;
```
- **폰트는 시스템 폰트를 쓴다**(Pretendard `2MB`를 새로 내려받게 하면 폰에서 손해 — 시안의 `pretendard.woff2` 는 쓰지 않는다. 이 판단을 보고서 §2에 적는다).
- 글자 크기는 **390px 화면에서 10.5px 미만 금지**.

### 2-3. 컴포넌트 규칙 (숫자로)
| 요소 | 규칙 |
|---|---|
| 헤더 `.k-hd` | 높이 **56px**(390) / 68px(넓은 화면), 좌측 로고(`icon.png` + `KTS 원클릭`), 우측 `[☾/☀ 테마]` 44×44, `sticky top:0`, 배경 `color-mix` 대신 `rgba(11,19,43,.94)` + `backdrop-filter:blur(12px)`(라이트는 `rgba(255,255,255,.9)`) |
| 상단 공지 띠 `.k-nb` | 기존 `#nb` 자리 유지(문구·닫기 버튼 그대로). 높이 자동, 글자 12px |
| 카드 `.k-card` | `background:var(--k-panel); border:1px solid var(--k-line); border-radius:var(--k-radius); padding:var(--k-sp-4)` |
| 카드 제목 `.k-card h2` | 19px · 690 · 왼쪽 오렌지 아이콘 18px(기존 `.secH` 의 번호칸 방식을 그대로 쓴다) |
| 주 버튼 `.k-btn` | `min-height:44px` · `background:linear-gradient(135deg,#ff6b00,#ffa24d)` · 글자 `var(--k-on-accent)` · 900 · `border-radius:10px` |
| 보조 `.k-btn.ghost` | `min-height:44px` · `background:var(--k-panel-2)` · 테두리 `var(--k-line-2)` · 글자 `var(--k-ink)` |
| 토글 `.k-tog` | `min-height:44px` · 꺼짐: 테두리 `var(--k-line-2)`·글자 `var(--k-ink-2)` / 켜짐: 테두리 `var(--k-accent)`·배경 `rgba(255,107,0,.12)`·글자 `#ffd9a6`(라이트는 `#a2410a`) |
| 배지 `.k-badge` | 11px · 800 · `padding:3px 7px` · radius 6px. 종류: `무료`(초록)·`PRO`(오렌지)·`NEW`(파랑)·`준비`(회색) — **기존 `BADGE` 색 규칙과 충돌하지 않게 같은 색값**을 쓴다 |
| 표 `.k-tbl` | `padding:11px 12px`, 숫자열 `tabular-nums`, 머리 배경 `var(--k-panel-2)` |
| 푸터 `.k-foot` | 브랜드명은 **`케이티에스`** 표기(로마자 `KTS`만 쓰지 않는다 — 대표님 표기 규칙), 문의 `010-2002-2899`(`tel:`), `이용약관·개인정보처리방침` 링크, "파일은 서버로 보내지 않습니다" 1줄 |
| 포커스 | `:focus-visible{outline:2px solid var(--k-accent-2);outline-offset:3px}` (시안과 동일) |

### 2-4. 테마 동작 (반드시 이 순서)
1. `<html data-kts-theme="dark">` 를 마크업에 **직접 박아 둔다**(JS 없이도 다크로 뜨게 — 흰 화면 깜빡임 방지).
2. `kts-ui.js` 가 로드되면 `localStorage['kts_theme']` 를 읽어 덮어쓴다(값이 없으면 `dark`).
3. 토글 버튼은 아이콘 `☾`(다크 상태) / `☀`(라이트 상태), `aria-pressed`, `aria-label="밝게 보기"|"어둡게 보기"`.
4. **A4 인쇄는 항상 라이트(흰 배경·검은 글씨)** — `@media print` 에서 변수를 덮어쓴다:
   ```css
   @media print{
     :root,html[data-kts-theme="light"],html[data-kts-theme="dark"]{
       --k-bg:#fff; --k-panel:#fff; --k-panel-2:#fff; --k-line:#9ca3af; --k-ink:#111827; --k-ink-2:#4b5563;
     }
     .k-noprint,.k-hd .k-theme{display:none!important}
   }
   ```
5. 토글 값은 **서버로 보내지 않는다**(`localStorage` 만).

---

## 3. B. 쇼룸 메인 개편 (`oneclick/index.html`)

> **코드 변경을 최소화하는 방법**: 지금 `render()` 가 `GROUPS` 배열을 돌며 `.row` 카드를 그린다. **그 구조를 그대로 두고** ① `GROUPS` 를 **4개 업종 묶음 + 1개 준비 중**으로 교체 ② 그 위에 **대표 3종 전용 블록**을 하나 추가한다. 기존 `.row` CSS·`[열기]` 관문·`limLine()` 을 재사용한다(새 카드 컴포넌트를 새로 만들지 않는다).

### 3-1. 새 순서
```
[헤더 + 공지 띠 + 마스터]                      ← 그대로
[히어로]  제목 = 시안 2페이지 문구
          "반복 업무, 클릭 한 번으로 끝내세요"
          부제 = "설치 없이 바로 쓰는 사업자용 업무 도구. 매물 정리부터 상품 콘텐츠·서명까지."
          버튼 = [무료로 시작하기](→ #sec01 로 스크롤)  [도구 전체 보기](→ #allGroups)
          ※ 시안의 [가격 보기] 는 넣지 않는다(요금표 미확정 — §0-2-2)
[대표 3종]  ① 매물장 뷰어(준비 중) ② 더싸인 ③ 경사도      ← 큰 카드 3개
[내 박스 strip]  ← 그대로 (KTS_KEYS)
[업종 묶음] 01 부동산·중개사 / 02 쇼핑몰·셀러 / 03 자영업·매장 / 04 개인·생활  ← id="allGroups"
[준비 중]  05 혼합 장부 취합기 · 유튜브 1초 최적화 · 여행 패스   ← 그대로 '준비 중' 표시
[쿠폰 · 해주세요 · 안내문 · 푸터]   ← 그대로
```

### 3-2. 대표 3종 카드 (첫 화면 844px 안에 3개가 다 보이게)
- 큰 카드 1개는 **오렌지 1px 테두리 강조**(시안처럼 첫 카드만), 나머지 2개는 기본 테두리. 높이 **카드당 약 92~108px**(390 기준), 제목 16px·900, 한 줄 설명 12.5px, 우측 `한도 배지`(예: `일 3건`) + `[열기]`.
- 내용:
  | 순서 | 카드 | 링크 | 상태 |
  |---|---|---|---|
  | ① | **매물장 뷰어** — "매물 하나가 영업하는 홈페이지가 됩니다" | `listing/` | **준비 중** (`soon`) — 3순위가 끝나면 live 로 바뀐다 |
  | ② | **더싸인** — "사인·도장 → 투명 PNG → 문서 날인" | `sign/` | live |
  | ③ | **토지정보(경사도)** — "지번 하나로 필지 경사도·단면" | `slope/` | live |
- `products.js` 의 `nm` 은 바꾸지 않는다(카드 표시명만 `매물장 뷰어`·`더싸인`·`경사도` 로 짧게 — `String(nm).split(' — ')[0]` 규칙을 그대로 쓰면 자동으로 짧아진다).

### 3-3. 4대 업종 묶음 — **상품 배분표(그대로 구현)**
| 묶음 | 제목 / 부제 | 넣는 키 |
|---|---|---|
| **01** | **부동산·중개사** / 매물·계약·권리·경사도 | `listing` · `realty` · `exchange` · `slope` · `redev` · `contract` · `theform` · `sign` · `viewer` · `thescan` |
| **02** | **쇼핑몰·셀러** / 상품·상세·광고·등록 | `commerce` · `seller` · `thedetail` · `keyword` · `ad_magnet` · `photo2doc` · `theeraser` |
| **03** | **자영업·매장** / 홍보·가계부·외국 손님·자금 | `bungee_home` · `bungee_poster` · `bungee_interior` · `gagebu` · `tongyeok` · `loan` · `tax` · `interior` |
| **04** | **개인·생활** / 장보기·휴대폰·취미·기록 | `sale` · `hogang` · `golf` · `petmind` · `saycap` · `navi` · `organizer` |
| **05** | **준비 중** / 나오면 맨 위에 알려 드립니다 | `append` · `youtube` · `travel` |

- 합계 **10+7+8+7+3 = 35 = products.js 28종 + LOCAL 7**. **중복 0 · 누락 0**(§5-1 검사). (`listing` 은 대표 3종 블록에도 한 번 더 크게 뜨지만, 묶음 계산에는 **01 한 곳에만** 넣는다 — 그래야 검사가 깨끗하다.)
- `interior`(인테리어 견적)는 **03** 에 넣는다(집·매장 인테리어 수요 = 자영업·매장).
- `exchange` 는 `link:''` 라 지금도 `준비 중`으로 뜬다 — **그대로 둔다**(교환포털 주소는 별건).
- 각 묶음 머리는 기존 `.secH`(번호 + 제목 + 부제) 그대로 쓰고, **번호는 01~05 두 자리**로 통일.

### 3-4. 라이트/다크 · 공통 틀 적용 범위
- `index.html` 에 `shared/kts-tokens.css` → `shared/kts-ui.css` → 기존 인라인 `<style>` → `shared/kts-print.css` 순으로 링크하고, `<html data-kts-theme="dark">` + `shared/kts-ui.js` 를 넣는다.
- **기존 인라인 CSS 변수(`--bg`·`--panel`·`--amber` …)를 `--k-*` 로 별칭**한다(`:root{--bg:var(--k-bg); …}`). 이렇게 하면 기존 규칙을 다시 쓰지 않아도 색이 두 벌로 따라온다. **기존 규칙 문장은 지우지 않는다.**
- 헤더 우측 `[☾/☀]` 토글 추가(전화 링크·열쇠·마스터 버튼은 그대로, 토글은 그 왼쪽).

---

## 4. C. 검수 2건 수리 + 등록 2건

### 4-1. `helper.js` 도우미 버튼이 `[열기]`/`[+]` 를 가리지 않게 (133번 ①)
- 지금: `#kts-helper-btn{position:fixed;right:max(12px,calc(50% - 274px));bottom:14px;width:52px;height:52px}` → 390에서 **오른쪽 아래 = 카드 `.act` 의 `[열기]`/`[+]` 자리**와 겹친다. 같은 자리에 `↑ 위로`(`.totop`, `right:…;bottom:18px`)도 있어 **두 개가 같이 가린다.**
- **고칠 것(두 파일)**:
  1. `helper.js` — 390(≤719px)에서 버튼을 **왼쪽 아래**로: `left:10px;right:auto;bottom:calc(10px + env(safe-area-inset-bottom,0px));width:48px;height:48px`(터치 44px 이상 유지). 넓은 화면(≥720px)은 **본문 바깥 왼쪽 여백**: `left:max(10px, calc(50% - 300px))`.
  2. `index.html` `.totop` — **오른쪽 아래에서 왼쪽 위로** 옮겨 도우미와 한 줄로 세운다: `left:10px;right:auto;bottom:calc(66px + env(safe-area-inset-bottom,0px))`.
  3. `#app{padding-bottom:96px}` 로 마지막 카드가 버튼 위로 스크롤되게 한다.
- **금지**: 버튼을 44px 미만으로 줄이거나 `display:none` 으로 숨기는 것으로 해결하지 않는다(129번 기능 유지). `pointer-events:none` 도 금지(버튼을 못 누르게 됨).
- **검증(숫자)**: 390에서 스크롤 위치 3곳(0 / 중간 / 맨 아래)마다 `#kts-helper-btn`·`.totop` 사각형이 `.act .go`·`.act .soonb` 사각형과 **교차 0건**임을 `getBoundingClientRect()` 로 확인하고, `[열기]` 3개를 실제로 클릭해 페이지가 열리는지 확인한다(이동 후 `history.back()`).

### 4-2. 가계부 이름 통일 + 부제 중복 제거 (133번 ②)
- `products.js` `k:'gagebu'` 의 `nm` 을 **`결제문자 가계부`** 로 바꾼다(지금 `원클릭 가계부`). `catalog.json` 의 같은 항목도 같은 값으로. `sub` 는 **`카드 결제 문자를 붙여넣으면 정리`** 유지.
- **부제 중복**: 11-22 검수에서 가계부 카드 부제가 `1개 · 국민카드 · 1개 5,600원` 처럼 **같은 문구가 두 번** 보였다. 원인 후보를 순서대로 확인한다:
  1. `KTS_KEYS.freeText('gagebu')` · `limitOf('gagebu')` 값(지금 `LIMIT` 표에 `gagebu` 없음 → `freeText` 는 `''` 를 돌려줘야 정상)
  2. `boxStrip`(내 박스)에서 마지막 사용 항목을 그리는 문구
  3. `gagebu/index.html` 의 `sub` + `line` 이 카드에 함께 나오는지(`render()` 는 `sub` 만 쓴다 — 확인)
- **결론 규칙**: 카드 한 장에 **같은 문구가 두 번 나오면 안 된다.** 어디서 나오는지 찾아 **한 곳만 남기고**, 못 찾으면 **보고서에 재현 캡처와 함께 "못 찾음"** 이라고 적는다(추측으로 문구를 지우지 않는다).
- `detail.html?k=gagebu` 도 새 이름으로 뜨는지 확인(`catalog.json` 기반).

### 4-3. `listing` 카드 **준비 중**으로 등록 (3순위 연결)
- `products.js` 배열 **맨 끝**에 1개 추가 + `catalog.json` 동일 항목 + `count` **27 → 28** + `v` **`20261122a` → `20261123a`** + `updated` `2026-11-23T13:30:00+09:00`.
```json
{
 "k": "listing", "nm": "매물장 뷰어", "sub": "매물 하나가 영업하는 홈페이지 · 명함·A4",
 "cat": "realty", "badge": "준비", "status": "soon", "icon": "shots/ic_listing.png",
 "price": "무료", "price2": "1호 무료 · 문자·카톡 매물 자동 정리",
 "line": "매물 하나가 중개사 명함과 홈페이지를 달고 다닙니다.",
 "blurb": "매물 정보와 사진 2~4장을 넣으면 세아빌딩형 매물장이 만들어집니다. 감정가 대비·수익률 요약, 제원 2열 표, 층별 임대차, 사업자 명함(연락처 저장·전화·문자), 비공개 매물 구분, A4 210×297mm 한 장 인쇄까지.",
 "link": "", "bullets": [["요약","매매가·보증금·월세·수익률"],["제원","9항목 2열 표"],["명함","vcf 저장·전화·문자"],["인쇄","A4 210×297mm 한 장"]],
 "how": ["매물 정보와 사진 2~4장을 넣습니다.","요약·제원·층별 임대차를 확인합니다.","명함을 붙이고 [A4 인쇄]로 한 장을 뽑습니다."],
 "notes": ["예시 매물입니다. 실제 투자 판단은 계약 조건과 공부(公簿) 확인이 기준입니다.","이 사이트는 결제를 받지 않습니다."],
 "shot": "shots/listing_home.png"
}
```
- **`status:'soon'` + `link:''`** 이므로 `render()` 가 자동으로 `[준비 중]`(비활성)으로 그린다 → **404 없음**. 3순위 지시서가 끝나면 `status:'live'`, `link:'listing/'` 로 바꾼다(그 지시서에 명시돼 있다).
- `shots/ic_listing.png` = **512×512 PNG**(딥네이비 바탕 + 오렌지 건물·명함 라인). 없으면 `refs/v0_listing_20261123/public/seongsu.png` 를 512로 잘라 쓰고 그 사실을 적는다. **깨진 이미지 금지.**
- `sitemap.xml` 에는 **넣지 않는다**(페이지가 아직 없다 — 3순위가 넣는다).

---

## 5. D. 검증 — 390 실측 + A4 인쇄 미리보기 + 게이트

### 5-1. 화면 실측
| 항목 | 방법 | 기대 |
|---|---|---|
| 첫 화면 | 390×844 첫 화면 캡처 | **대표 3종 카드가 y<844 안에 전부** 보임 |
| 가로 넘침 | `document.documentElement.scrollWidth` | **390** |
| 버튼 터치 | 새 버튼(테마·대표열기·묶음 내 열기) 최소 높이 | **≥ 44px** |
| 도우미 겹침 | §4-1 검증 | `.act .go` 와 교차 **0건** · `[열기]` 클릭 3/3 성공 |
| 목록 완전성 | 아래 스크립트 | **누락 0 · 중복 0 · 35개** |
| 카드 클릭 | 4묶음에서 각 2개씩 `[열기]` | 해당 도구 페이지 200 |
| 마스터 | `?master=2899` | 전 도구 목록 뜸(`mstN` = live 수) |
| 테마 | 토글 2회 → 새로고침 | 다크→라이트→유지(라이트) · `localStorage['kts_theme']` 값 확인 |
| 인쇄 | `Ctrl+P` 미리보기 캡처 | **흰 배경·검은 글씨**(라이트 강제) · 테마 버튼 숨김 · `print_a4.png` |
| 콘솔 | Chrome 콘솔 | **에러 0건** |
```js
// 목록 완전성 — 콘솔에 붙여 실행(누락·중복 0 이어야 한다)
(function(){var all=[];(window.PRODUCTS||[]).forEach(function(p){all.push(p.k)});
Object.keys(window.LOCAL||{}).forEach(function(k){all.push(k)});
var seen={},dup=[];GROUPS.forEach(function(g){g.ks.forEach(function(k){if(seen[k])dup.push(k);seen[k]=1})});
var miss=all.filter(function(k){return !seen[k]});console.log('전체',all.length,'묶음',Object.keys(seen).length,'누락',miss,'중복',dup)})()
```
> `LOCAL`·`GROUPS` 는 `index.html` 안 지역 변수라 콘솔에서 안 보일 수 있다. 그때는 `window.__KTS_GROUPS` 로 **읽기 전용 노출**을 한 줄 추가해 검사한다(그 한 줄은 남겨도 된다).

### 5-2. 게이트(`kts_gate`) — **FAIL 0 필수**
```powershell
python output/kts_gate.py .\index.html .\helper.js .\shared\kts-ui.js
```
- 기대 **FAIL 0**. 특히 `G1-2`(구조) · `G1-4`(모달 닫기) · `G1-6`(실명) · `G1-7`(원가·내부문구) · `G1-9`(viewport).
- 출력 전문 → `output/shared_20261123/gate.txt`. `kts_gate.py` 가 없으면 지난 회차 PowerShell 이식판을 복사해 쓰고 그 사실을 적는다.
- `catalog.json` 검사: `python -c "import json;d=json.load(open('catalog.json'));print(d['v'],d['count'],len(d['products']))"` → **`20261123a 28 28`**.

### 5-3. 라이브
```powershell
curl.exe -s "https://autooneclick.com/?t=$(Get-Date -Format s)" | Select-String "결제문자 가계부"
curl.exe -s "https://autooneclick.com/shared/kts-tokens.css?t=$(Get-Date -Format s)" | Select-String "k-accent"
curl.exe -s "https://autooneclick.com/catalog.json?t=$(Get-Date -Format s)" | Select-String "listing"
```

---

## 6. 결과 보고서 `CLAUDE_RESULT_20261123_SHARED_SHOWROOM.md` (이 틀 그대로)

```
# 결과 — 2026-11-23 공통 틀 + 쇼룸 개편 + 검수 2건 (133·138번)
시작 HEAD: oneclick <sha> / K0612766940K- <sha>
끝   HEAD: oneclick <sha> / K0612766940K- <sha>
커밋: <해시·메시지>

## 1. 저장소
- pull 결과 <앞→뒤 sha> · 1순위(slope) 변경과 충돌: 있음/없음(어떻게 살렸는지)

## 2. 시안에서 읽은 값
- 색 5: <...> · radius <px> · 카드 padding <px> · 본문 <px> · 터치 <px>
- 폰트 판단: 시스템 폰트 사용(이유 1줄)

## 3. 공통 틀 (shared/)
- 파일 5개: <용량·줄수> · 토큰 변수 개수 다크 <n>/라이트 <n>
- 테마: 기본 다크 확인 · 토글 후 새로고침 유지 확인 · 인쇄 강제 라이트 캡처 <경로>
- 적용 범위: index.html 만(다른 도구 0건) — 확인

## 4. 쇼룸 개편
- 순서: 히어로 → 대표 3종 → 내 박스 → 01~04 업종 → 05 준비 중 → 쿠폰·해주세요·푸터
- 목록 완전성: 전체 35 · 묶음 35 · 누락 [] · 중복 []
- 대표 3종 y좌표: <1> <2> <3> (첫 화면 844 안: 확인)
- 보존 기능: 단축바<> 마스터<> 열기관문<> 해주세요<> 문자링크<> (전부 확인/미확인)

## 5. 수리 2건
- helper: 390 스크롤 3곳 교차 0건 · [열기] 클릭 3/3 · totop 새 위치 <px>
- 가계부: products.js/catalog.json nm='결제문자 가계부' <> · detail.html 확인 <> · 중복 문구 원인: <찾음/못 찾음 + 근거>

## 6. listing 카드
- status soon · link '' (404 0) · icon <해상도> · catalog v=20261123a count=28
- 3순위에서 live 로 바꿀 자리: products.js <줄> · catalog.json <줄>

## 7. 검증
- scrollWidth 390 · 최소 버튼 <px> · 콘솔 0 · 캡처 <경로 6장>
- 게이트: FAIL <n> → <n> (<경로>)

## 8. 라이브
- '결제문자 가계부' <> · shared/kts-tokens.css <> · catalog listing <>

## 건드리지 않은 것 (확인함)
- 도구 27종의 JS·계산·저장 로직 0건 · 요금표 신설 0건 · 가격 문구 0건

## 대표님 확인 필요
1) 첫 화면에서 대표 3종이 크게 보이고 4묶음이 3초 안에 눈에 들어오는지
2) 다크/라이트 토글이 손에 맞는지(기본 다크)
3) 도우미 버튼이 이제 [열기]를 가리지 않는지
```

보고서·캡처는 `K0612766940K-` 에 `git add → commit → push` (`output/shared_20261123/`).

---

## 7. 한 문장 목표

**`autooneclick.com` 첫 화면이 "대표 3종(매물장 뷰어·더싸인·경사도) → 4대 업종 묶음"으로 정리되고, 딥네이비·오렌지 한 벌 토큰 위에서 다크/라이트가 손가락 한 번에 바뀌며(인쇄는 항상 흰 바탕), 도우미 버튼이 카드 [열기]를 더 이상 가리지 않고, 가계부 이름이 `결제문자 가계부` 하나로 통일된다 — 도구 로직·가격은 한 글자도 바뀌지 않은 채로.**

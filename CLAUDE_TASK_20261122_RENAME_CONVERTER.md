# PC 클로드 코드 작업 지시서 — 2026-11-22 명칭 변경: '원클릭 변환기' → '문서변환기'

> 발령: 2026-11-22 07:2x KST · 사령관 지니 → PC 클로드 코드(Pro)
> 대표님 지시 (원문 그대로):
> - 07:22 **"원크릭 변환기. 문서변환기"**
> - 07:23 (지니 확인 질문에) **"ㅇ"** ← '원클릭 변환기' → '문서변환기' 확정
> 결과 보고서: **`CLAUDE_RESULT_20261122_RENAME_CONVERTER.md`** (작업 후 `git add → commit → push`)
> 저장소 2개: ① `K0612766940K-`(지시서·결과 문서) ② `oneclick`(실서비스 `autooneclick.com` · **코드는 이쪽만**)
> 기준선(2026-11-22 07:2x KST, 지니가 실제 파일을 열어 확인): `oneclick` **`53ff0c3`** · `K0612766940K-` **`d5bed67`**
> **수정 범위: 표시 명칭 `"원클릭 변환기"` 딱 4곳 + 캐시 무효화 2곳. 그 외 한 줄도 건드리지 않는다.**

---

## 0. 금지 경계

> ### ⛔ 절대 금지
> - **파일명 `converter.html` 변경 금지.** URL `converter.html`·`detail.html?k=photo2doc` 그대로.
> - **`photo2doc` 키/ID 변경 0건** — `k`·`link`·`icon`(`shots/ic_photo2doc.png`)·`shot`(`shots/photo2doc_home.png`)·`slots.js`의 `LIMIT.photo2doc`·localStorage 키(`kts_keys_v1` 등) 전부 그대로.
> - **다른 도구 이름·문구·요금·기능·레이아웃·색·여백 변경 0건.** "이왕 고치는 김에" 리팩터링 금지.
> - **`oneclick` 안에서 위 §1의 6곳 외 파일 수정 금지.** 다른 트랙이 같은 저장소에서 동시에 작업 중이다. **force-push 금지, 남의 커밋 되돌리기 금지.**
> - **외부 발송·광고·스토어 업로드 0건.** 이번 배포는 `autooneclick.com` 반영까지다(**관문 6** 유지: 대외 홍보·문자 발송은 대표님 시연 후).
> - **흉내내기 금지** — 확인하지 않은 것을 "됐다"고 쓰지 않는다. grep 출력·콘솔 화면·exit code만 근거로 적는다.
> - **실기기 확인은 대표님 몫.** PC에서 폰 화면을 볼 수 없으므로 "폰에서 잘 보인다"고 단정하지 않는다(§4 체크리스트로 넘긴다).

---

## 1. 바꿀 곳 — 지니가 `53ff0c3` 판에서 직접 확인한 6곳

줄번호는 참고값이다. **줄번호만 믿지 말고 문자열로 찾을 것.**

| # | 파일 | 줄 | 지금 | 바꿀 뒤 |
|---|---|---|---|---|
| 1 | `products.js` | 51 | `"nm": "원클릭 변환기",` | `"nm": "문서변환기",` |
| 2 | `catalog.json` | 51 | `"nm": "원클릭 변환기",` | `"nm": "문서변환기",` |
| 3 | `converter.html` | 4 | `<title>KTS 원클릭 변환기 — 사진 한 장이 원본 그대로 한글·엑셀이 됩니다</title>` | `<title>KTS 문서변환기 — 사진 한 장이 원본 그대로 한글·엑셀이 됩니다</title>` |
| 4 | `converter.html` | 216 | `…</svg></span>KTS <small>원클릭 변환기</small></span>` | `…</svg></span>KTS <small>문서변환기</small></span>` |
| 5 | `index.html` | 237 | `<script src="products.js?v=20261121u"></script>` | `<script src="products.js?v=20261122a"></script>` |
| 6 | `detail.html` | 135 | `<script src="products.js?v=20261121u"></script>` | `<script src="products.js?v=20261122a"></script>` |

- **1·2는 같은 내용의 쌍둥이 파일**이다(쇼룸은 `products.js`를 먼저 그리고 `catalog.json`이 늦게 오면 다시 그린다). **둘 다** 고쳐야 한다.
- **3·4 외의 제목·설명(meta description)은 손대지 않는다.** 브랜드 표기 `KTS ` 접두와 나머지 문장은 그대로.
- **5·6은 이름이 폰에 보이게 하는 최소 조치**다. 이걸 안 하면 폰이 예전 `products.js`를 계속 써서 **이름이 안 바뀐 것처럼 보인다.** `?v=` 값만 바꾸고 나머지 태그·속성은 그대로.
- `detail.html`의 탭 제목은 `document.title = p.nm + ' — KTS 원클릭'`로 자동 반영된다(수정 불필요).

### 그대로 두는 것 (확인했지만 대상 아님 — 결과 보고서에 "무변경"으로 적을 것)
- `converter.html:318`·`383`의 모드 토글 `변환기` / `더뷰` — **상품명이 아니라 화면 모드 이름**이고 폭이 딱 맞춰져 있다. 그대로.
- `viewer.html:220`의 토글 `변환기`, `viewer.html:1150` 주석, `slots.js:286` 주석, `ops/status.json:72`, `status.js:38`, `ad_magnet/index.html`의 `"cta": "답변 → 변환기"` — 내부·기타 화면. 그대로.
- `manifest.webmanifest`(`KTS 만능 뷰어`) — 다른 앱 이름. 그대로.

---

## 2. 작업 순서 (덩어리마다 커밋)

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull --rebase; git rev-parse --short HEAD      # 기대: d5bed67 이상

$base = "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실"
$oc = Get-ChildItem $base -Directory | Where-Object { Test-Path (Join-Path $_.FullName '.git\config') } |
      Where-Object { (Get-Content (Join-Path $_.FullName '.git\config') -Raw) -match 'kim779944-max/oneclick\.git' } |
      Select-Object -First 1 -ExpandProperty FullName
cd $oc; git pull --rebase; git rev-parse --short HEAD   # 기대: 53ff0c3 이상
```

**A. 바꾸기 전 실측(숫자를 보고서에 그대로 적는다)**
```powershell
Select-String -Path products.js,catalog.json,converter.html -Pattern "원클릭 변환기" | Measure-Object | % Count   # 기대 4
```

**B. 6곳 수정** — 위 표 그대로. 문자열 치환은 `원클릭 변환기` **정확히 이 7글자(공백 포함)** 로만 한다. `원클릭`만·`변환기`만 치환하면 쇼룸 제목(`KTS 원클릭 — 폰으로 바로 쓰는 업무 도구`)과 다른 도구가 깨진다.

**C. 고친 뒤 실측**
```powershell
Select-String -Path products.js,catalog.json,converter.html -Pattern "원클릭 변환기" | Measure-Object | % Count   # 기대 0
Select-String -Path products.js,catalog.json,converter.html -Pattern "문서변환기"   | Measure-Object | % Count   # 기대 4
Select-String -Path index.html,detail.html -Pattern "products\.js\?v=20261122a"      | Measure-Object | % Count   # 기대 2
git --no-pager diff --stat    # 기대: 5개 파일, 이름 1~2줄씩
node -e "JSON.parse(require('fs').readFileSync('catalog.json','utf8')); console.log('catalog ok')"
node -e "new Function(require('fs').readFileSync('products.js','utf8')); console.log('products ok')"
```
`git --no-pager diff`에 **이름 6곳 말고 다른 줄이 보이면 되돌리고 다시 한다.**

**D. 커밋·푸시 (oneclick)**
```powershell
git add products.js catalog.json converter.html index.html detail.html
git commit -m "rename: 원클릭 변환기 -> 문서변환기 (표시 명칭만, photo2doc 키·파일명 무변경)"
git push
```

---

## 3. 화면 검증 (PC 크롬 · 390px)

```powershell
python -m http.server 8123      # oneclick 폴더에서
```
크롬에서 (개발자도구 → 기기 툴바 → 390×844):
1. `http://localhost:8123/index.html` — 목록 카드 이름이 **문서변환기**, 부제 `표 사진 → 한글(.hwpx)·엑셀(.xlsx)` 그대로.
2. `http://localhost:8123/converter.html` — **탭 제목** `KTS 문서변환기 — …`, **헤더 브랜드** `KTS 문서변환기`.
3. `http://localhost:8123/detail.html?k=photo2doc` — 탭 제목 `문서변환기 — KTS 원클릭`, 상세 화면 정상.
4. 세 화면 콘솔 **에러 0건 · 빨간 줄 0개**(경고는 세어만 적는다).
5. 390px에서 헤더 브랜드가 **줄바꿈·넘침 없이** 한 줄인지 눈으로 확인(글자 5자→5자, 폭 동일).
6. 캡처 3장을 `_captures/rename_20261122/`에 저장하고 **경로를 보고서에 적는다.**

**E. 라이브 반영 확인(푸시 후 1~2분)**
```powershell
curl.exe -s "https://autooneclick.com/products.js?t=$(Get-Date -Format HHmmss)" | Select-String "문서변환기"
curl.exe -s "https://autooneclick.com/converter.html?t=$(Get-Date -Format HHmmss)" | Select-String "문서변환기"
```
두 줄 다 잡히면 반영 완료. 안 잡히면 Pages 빌드 상태를 확인하고 **"아직 반영 전"이라고 사실대로** 적는다.

---

## 4. 결과 보고서 `CLAUDE_RESULT_20261122_RENAME_CONVERTER.md` (이 틀 그대로)

```
# 결과 — 2026-11-22 명칭 변경: 원클릭 변환기 → 문서변환기
시작 HEAD: oneclick <sha> / K0612766940K- <sha>
끝   HEAD: oneclick <sha> / K0612766940K- <sha>

## 바꾼 곳 (파일:줄 — 전 → 후)
1) products.js:51 …
2) catalog.json:51 …
3) converter.html:4 …
4) converter.html:216 …
5) index.html:237 …
6) detail.html:135 …

## 실측 숫자
- 수정 전 `원클릭 변환기` 매치: 4 / 수정 후: 0
- 수정 후 `문서변환기` 매치: 4
- `products.js?v=20261122a` 매치: 2
- `git diff --stat`: 파일 5 · +6 −6
- JSON/JS 문법 검사: catalog ok / products ok

## 화면 (390×844 · PC 크롬)
- 쇼룸 카드 이름: (캡처 경로)
- converter.html 탭 제목·헤더 브랜드: (캡처 경로)
- detail.html?k=photo2doc 탭 제목: (캡처 경로)
- 콘솔 에러: 0건 (경고 n건)

## 라이브
- https://autooneclick.com/products.js → 문서변환기 확인/미확인
- https://autooneclick.com/converter.html → 확인/미확인

## 건드리지 않은 것 (확인함)
- 파일명 converter.html·URL·photo2doc 키·아이콘/스크린샷 경로·localStorage 키: 무변경
- converter.html 모드 토글 `변환기`/`더뷰`, viewer.html 토글, ops/status.json, status.js, slots.js 주석, ad_magnet cta: 무변경
- 다른 도구 이름·기능·요금·레이아웃·색: 무변경

## 대표님 확인 필요 (1줄)
- 폰에서 새로고침(캐시 비우기) 후 쇼룸 카드와 변환기 화면 상단에 '문서변환기'가 보이는지
```

보고서도 `K0612766940K-`에 `git add → commit → push` 한다.

---

## 5. 한 문장 목표

**`autooneclick.com` 쇼룸 카드·변환기 탭 제목·화면 상단 브랜드 세 곳에서 이름이 '문서변환기'로 보이고, 파일명·URL·`photo2doc` 키·기능·레이아웃은 수정 전과 완전히 같다.**

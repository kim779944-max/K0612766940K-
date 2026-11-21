# PC 클로드 코드 작업 지시서 — 2026-11-22 폰정리 APK 삭제 권한 수리 (v3.0 → v3.2)

> 발령: 2026-11-22 07:2x KST · 사령관 지니 → PC 클로드 코드(Pro)
> 대표님 지시 2건 (원문 그대로):
> - **"폰정리 apk바로받기 설치 안됨"** (2026-11-22 07:03)
> - **"폰정리에서는 삭제가안됨"** (2026-11-22 07:12)
> 결과 보고서: **`CLAUDE_RESULT_20261122_ORGANIZER_APK.md`** (작업 후 `git add → commit → push`)
> 저장소 2개: ① `K0612766940K-`(이 지시서·결과 문서) ② `oneclick`(실서비스 `autooneclick.com` · **APK와 `organizer/index.html`은 이쪽**)
> 기준선(2026-11-22 07:15 KST): `oneclick` **`53ff0c3`** · `K0612766940K-` **`5a35991`**
> **수정 범위: `oneclick/organizer/` 안 + 폰정리 APK 소스(PC 로컬 작업 폴더)뿐이다.** 다른 도구(`hogang/`·`slope/`·`navi2/`·`viewer.html`·`gagebu/`·`petmind/`·`saycap/`·`sign/`·`ad_magnet/`·`redev/`·`golf/`·`thescan/` …)와 `oneclick/index.html`·`products.js`·`catalog.json`은 **한 줄도 건드리지 않는다.**

---

## 0. 최상단 금지 경계

> ### ⛔ 절대 금지
> - **`oneclick/organizer/` 이외의 `oneclick` 파일 수정 0건.** 다른 트랙이 같은 저장소에서 동시에 작업 중이다(`navi2/`가 `53ff0c3`까지 올라와 있다). **force-push 금지, 남의 커밋 되돌리기 금지.**
> - **상품 APK를 `K0612766940K-` 저장소에 올리지 않는다.** 이 저장소는 공개다. APK는 `oneclick/organizer/`에만 둔다(지금도 거기에 있다).
> - **비밀값 커밋 금지** — 키스토어 파일(`*.jks`/`*.keystore`)·스토어 비밀번호·토큰·개인 경로(`C:\Users\...`)·PC 이름을 저장소 어디에도 넣지 않는다. 키스토어는 **PC 안에만** 둔다.
> - **파일을 새로 지우지 않는다.** 구 `KTS_폰정리_v3.0.apk`는 그대로 두고, 새 파일을 **추가**한 뒤 `index.html`의 링크만 새 파일로 바꾼다.
> - "이왕 고치는 김에" 리팩터링·이름 통일·주석 정리·색·여백·글꼴 변경 **금지.** 아래 §4가 이름으로 지정한 곳만 고친다.
> - **외부 발송·결제·스토어 업로드 0건.** 문자/메일/SNS 발송, Play 업로드, 광고 집행 전부 하지 않는다. **관문 6**(대표님 실기기 시연 전 대외 배포) 유지 — 이번 배포는 `autooneclick.com` 안의 APK 교체까지다.
> - **실기기 검증은 대표님 몫이다.** PC에서 폰 화면을 확인할 수 없으므로 "폰에서 삭제 버튼이 잘 된다"고 **단정해서 쓰지 않는다.** §6까지 실측하고, 폰 확인은 체크리스트로 넘긴다(§9).
>
> ### 지킬 것
> 1. **제0원칙** — 지시서가 지정한 것 외에는 틀·색감·문구·기능·요금을 일절 바꾸지 않는다.
> 2. **흉내내기 금지** — 확인하지 않은 것을 "됐다"고 쓰지 않는다. 실측 숫자·명령 출력·exit code만 근거로 적는다.
> 3. **되돌릴 수 있게** — 시작 전 두 저장소 `git rev-parse --short HEAD`를 적어 두고 보고서에 넣는다(기대: `53ff0c3` / `5a35991` 이상).
> 4. **덩어리마다 커밋** — 자동 실행기는 한 회에 90분까지만 돈다. **A[매니페스트+브리지] → B[앱 화면] → C[첫 화면 교체] → D[랜딩 페이지] → E[빌드·서명] → F[검증·푸시]** 순서로, 끝난 덩어리마다 커밋해 다음 실행이 이어받게 한다.

### 이번 회차 결과물 (한 문장)
**`KTS_폰정리_v3.2.apk`(versionCode 32)는 `REQUEST_DELETE_PACKAGES` 권한과 `Native.uninstall(pkg)`(ACTION_DELETE)을 갖고, 앱을 열면 다운로드 안내 페이지가 아니라 등급·폴더 화면(`assets/app.html`)이 뜨며, 그 화면의 [삭제]를 누르면 안드로이드 시스템 삭제 확인창이 뜨고, `autooneclick.com/organizer/`의 받기 링크가 v3.2를 가리키며 설치가 안 될 때의 안내가 붙어 있다.**

---

## 1. 0단계 — 지금 상태 실측 (손대기 전, 15분)

줄번호는 `oneclick 53ff0c3` 판 기준. **줄번호만 믿지 말고 이름으로 찾을 것.**

### 1-1. 저장소 최신화
```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull --rebase; git rev-parse --short HEAD          # 기대: 5a35991 이상
```
`oneclick` 체크아웃을 찾아 최신화한다(지난 회차 지시서와 같은 방식).
```powershell
$base = "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실"
$oc = Get-ChildItem $base -Directory | Where-Object { Test-Path (Join-Path $_.FullName '.git\config') } |
      Where-Object { (Get-Content (Join-Path $_.FullName '.git\config') -Raw) -match 'kim779944-max/oneclick\.git' } |
      Select-Object -First 1 -ExpandProperty FullName
if (-not $oc) { git clone https://github.com/kim779944-max/oneclick.git (Join-Path $base 'oneclick'); $oc = Join-Path $base 'oneclick' }
cd $oc; git pull --rebase; git rev-parse --short HEAD   # 기대: 53ff0c3 이상
```

### 1-2. 지금 있는 것 (내가 2026-11-22 07:15에 실제 파일을 열어 확인한 값)

| # | 확인한 것 | 실측값 |
|---|---|---|
| 1 | `oneclick/organizer/` 파일 | `KTS_폰정리_v3.0.apk`(152,463 bytes · md5 `fbbf3d18dc93afe8358d7c71ecd6aa4b` · zip 무결성 `testzip()=None`) · `index.html`(13,939자) · `icon.png` |
| 2 | APK 매니페스트 | `package com.kts.organizer` · **versionCode `30`** · **versionName `"3.0"`** · minSdk `24` · targetSdk `34` · compileSdk `34` |
| 3 | APK 권한 | **`INTERNET` · `QUERY_ALL_PACKAGES` 딱 2개.** **`REQUEST_DELETE_PACKAGES` 없음** (문자열 풀 42개 전수 확인) |
| 4 | `<queries>` | `MAIN`/`LAUNCHER` 인텐트 1개 |
| 5 | 액티비티 | `.MainActivity` · exported · launchMode `singleTop` · stateNotNeeded · configChanges `orientation\|screenSize\|keyboardHidden` · intent-filter 2개(`MAIN/LAUNCHER`, `MAIN/HOME/DEFAULT` ← 홈 앱 후보) |
| 6 | `classes.dex` | **`android.intent.action.DELETE` 문자열 자체가 없다**(= 삭제 요청 코드가 원래 없다). `UNINSTALL_PACKAGE`도 없다 |
| 7 | 자바 브리지(`Native`)가 제공하는 메서드 | `apps()` · `launch(pkg)` · `open(url)` · `info(pkg)` · `homeSettings()` · `isHome()` — **`uninstall` 없음** |
| 8 | `info(pkg)` 실체 | `android.settings.APPLICATION_DETAILS_SETTINGS` + `package:<pkg>` → **설정의 '앱 정보' 화면을 열 뿐, 삭제창이 아니다** |
| 9 | `onCreate`가 띄우는 첫 화면 | 기기결속(`kts_lock`) 통과 시 **`https://autooneclick.com/organizer/`**(원격), 기기 불일치 시 `assets/lock.html`, 메인 프레임 로드 실패 시에만 `assets/app.html`로 폴백 |
| 10 | 서명 | v1+v2+v3 · alias **KTS** · subject `C=KR, L=Seoul, O=KTS, OU=AutoOneClick, CN=KTS` · 유효 `2026-11-14 ~ 2056-11-06` · **SHA-256 `B9:44:DC:04:CC:92:B2:BF:26:9F:35:E9:74:F8:0D:4C:9A:18:A0:AC:D7:E6:AA:4D:86:61:DE:22:90:FF:84:2D`** |
| 11 | `organizer/index.html` (라이브 `https://autooneclick.com/organizer/` 와 **같은 파일**) | 받기 링크 `href="KTS_폰정리_v3.0.apk"` · 라벨 `v3.0 · 4~12 맞춤 폴더 · 홈 화면 모드` · **삭제 버튼 없음 · `Native.info` 호출 없음** (폴더형 웹 화면 + 다운로드 배너) |
| 12 | APK 안 `assets/app.html`(40,735자) | 제목·배지 `폰정리 v3.0` · **등급 화면(등급으로 보기/분류/폴더) + 폴더 4~12 + 홈 화면(런처) 모드** · 상세 시트에 **`[앱 정보 · 삭제]` 버튼 → `appInfo()` → `Native.info(pkg)`** · 안내문 `"삭제는 폰 설정의 앱 정보 화면에서 직접 합니다. 이 앱은 목록과 등급만 보여 주고, 대신 지우지 않습니다."` |

### 1-3. PC 로컬에서 확인할 것 (내가 볼 수 없는 부분 — **추측 금지, 있는 그대로 보고**)

```powershell
# ① 폰정리 APK 소스 폴더가 PC에 있는가 (MainActivity.java + AndroidManifest.xml + assets/app.html)
Get-ChildItem "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실" -Recurse -Depth 4 -Filter "MainActivity.java" -ErrorAction SilentlyContinue |
  Where-Object { (Select-String -Path $_.FullName -Pattern "com\.kts\.organizer" -Quiet) } | Select-Object -ExpandProperty FullName

# ② 그 폴더에 빌드 스크립트가 있는가 (있으면 서명 명령·키 경로가 거기 들어 있다)
Get-ChildItem "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실" -Recurse -Depth 4 -Include "build_*.ps1","*.ps1" -ErrorAction SilentlyContinue |
  Select-String -Pattern "organizer" -List | Select-Object -ExpandProperty Path

# ③ 키스토어가 어디 있는가 (지문이 위 10번과 같은 것을 찾는다)
Get-ChildItem -Path $env:USERPROFILE -Recurse -Include *.jks,*.keystore -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -gt 1000 } | Select-Object FullName,Length,LastWriteTime

# ④ 키스토어 비밀번호가 적혀 있는 곳 (지난 빌드 흔적)
Get-ChildItem "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실" -Recurse -Depth 4 -Include *.ps1,*.txt,*.md -ErrorAction SilentlyContinue |
  Select-String -Pattern "ks-pass|keystore|KS_PASS" -List | Select-Object Path,Line
```

**판정표**

| 확인 결과 | 할 일 |
|---|---|
| 소스 폴더 있음 | 그 폴더에서 §4를 **최소 수정**으로 적용(원본 Java는 `uninstall()` 한 개만 추가). **새로 쓰지 않는다** |
| 소스 폴더 없음 | v3.0 APK에서 `assets/*`·`res/*`를 풀어 작업 폴더를 만들고, **부록 A의 Java 전문**으로 `src/com/kts/organizer/MainActivity.java`를 새로 만든다 |
| 키스토어 있고 지문 일치 | **그 키로 서명**(§5-3). 기존 앱 위에 덮어 설치 가능해진다 |
| 키스토어 없거나 지문 불일치 | **추측으로 다른 키를 쓰지 않는다.** §5-4의 새 키로 서명하고, 보고서 맨 앞에 **"같은 키가 없어 덮어 설치 불가 → 폰에서 구버전 삭제 후 설치"** 를 굵게 적는다 |

---

## 2. 1단계 — 원인 확정 (근거 포함)

대표님이 겪은 두 증상은 **서로 다른 원인 3개**에서 나온다.

1. **삭제가 안 되는 진짜 이유 — 삭제 요청 자체가 구현돼 있지 않다.**
   v3.0 `classes.dex`에 `android.intent.action.DELETE`(또는 `UNINSTALL_PACKAGE`) 문자열이 **없다.** 브리지에도 `uninstall`이 없다. 즉 [앱 정보 · 삭제] 버튼은 `APPLICATION_DETAILS_SETTINGS`만 열 뿐이고, **안드로이드 시스템 삭제창은 애초에 호출되지 않는다.** 게다가 매니페스트에 `REQUEST_DELETE_PACKAGES`가 없어, 나중에 `ACTION_DELETE`를 넣어도 안드로이드 9(P, API 28)+ 에서는 **권한이 없으면 삭제 요청이 막힌다**(공식 문서: 이 권한은 "Allows an application to request deleting packages", `ACTION_UNINSTALL_PACKAGE`는 API 28부터 **Requires `Manifest.permission.REQUEST_DELETE_PACKAGES`**).
2. **앱이 다운로드 안내 페이지를 띄운다.**
   v3.0 `onCreate`는 기기결속이 통과되면 `https://autooneclick.com/organizer/`를 연다. 그 페이지(`organizer/index.html`)는 **"폰정리 앱(APK) 바로 받기" 배너가 붙은 웹 소개/미리보기 페이지**이고, **삭제 버튼이 아예 없다.** 실제 앱 화면(등급·폴더·삭제 버튼)은 APK 안 `assets/app.html`에만 있는데, 그건 **인터넷이 실패할 때만** 뜬다. → 앱을 열어도 삭제 버튼이 있는 화면이 나오지 않는다.
3. **설치가 안 되는 이유 — 서명이 다른 구버전이 폰에 남아 있다.**
   v3.0은 위 10번 지문의 **KTS 키**로 서명돼 있다. 폰에 깔린 구버전이 다른 키(예전 debug 키 등)로 서명돼 있으면 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`이 뜨고 **아무리 다시 받아도 설치되지 않는다.** 이때는 ① 구버전 삭제 → ② 설치 순서뿐이다. 다만 폰정리는 `CATEGORY_HOME`을 달고 있어 **'기본 홈 앱'으로 잡혀 있으면 삭제 버튼이 비활성**이 된다 → 설정 → 앱 → 기본 앱 → 홈 앱을 기본 런처로 되돌린 뒤 삭제해야 한다.

> **따라서 수리 4덩어리:** ① 권한 + `uninstall()` 신설 ② 앱 화면(`app.html`)의 버튼을 한 번에 삭제창이 뜨게 ③ **앱 첫 화면을 `assets/app.html`로 교체**(다운로드 배너 페이지가 앱 안에 뜨는 것도 함께 고친다) ④ 랜딩 페이지 링크·설치 안내.

---

## 3. 2단계 — 수리 A · 매니페스트 + 브리지

### 3-1. `AndroidManifest.xml` — 권한 한 줄만 추가
`<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />` **바로 아래**에 넣는다.

```xml
    <!-- ★ v3.2: 앱 삭제 요청 권한 (이게 없으면 안드로이드 9+ 에서 ACTION_DELETE 가 막힌다) -->
    <uses-permission android:name="android.permission.REQUEST_DELETE_PACKAGES" />
```

`android:versionCode="30"` → `32`, `android:versionName="3.0"` → `3.2` (이 두 값만).

### 3-2. `MainActivity.java` — 브리지에 `uninstall()` 신설

`Bridge` 클래스 안, `info()` **바로 아래**에 추가한다(원본 소스가 있으면 이 블록만 붙인다).

```java
    /** ★ v3.2 — 안드로이드 시스템 삭제 확인창을 띄운다. (REQUEST_DELETE_PACKAGES 필요) */
    @JavascriptInterface
    public boolean uninstall(String pkg) {
        if (pkg == null) return false;
        pkg = pkg.trim();
        if (!pkg.matches("[A-Za-z0-9_.]+")) return false;      // 이상한 문자열 차단
        if (pkg.equals(ctx.getPackageName())) return false;    // 자기 자신은 삭제 요청 금지
        try {
            Intent i = new Intent(Intent.ACTION_DELETE, Uri.parse("package:" + pkg));
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            ctx.startActivity(i);
            return true;
        } catch (Exception e) {
            return false;                                      // 실패하면 화면이 info()로 넘어간다
        }
    }
```

기존 `info(pkg)`는 **그대로 둔다**(삭제창이 안 뜨는 기기·시스템 앱에서 폴백으로 쓴다).

### 3-3. 첫 화면 교체 (`onCreate`)
```java
// 지금:  if (!locked) loadUrl("https://autooneclick.com/organizer/") else loadUrl("file:///android_asset/lock.html")
// v3.2:
this.wv.loadUrl(locked ? "file:///android_asset/lock.html" : "file:///android_asset/app.html");
```
> **이유(보고서에 그대로 적을 것):** 원격 `organizer/index.html`은 **받기 배너가 붙은 웹 소개 페이지**라 앱 안에 띄우면 ① 손님용 다운로드 배너가 앱 화면에 뜨고 ② **삭제 버튼이 있는 앱 화면이 영영 안 보인다.** 앱 화면은 `assets/app.html`이며, 이 파일이 등급·폴더·홈 런처 모드를 모두 갖고 있다. 인터넷 실패 시 `app.html`로 넘기는 기존 폴백 로직은 그대로 둔다(이제 첫 화면과 같은 파일이라 무해하다).

---

## 4. 2단계 계속 — 수리 B · 앱 화면(`assets/app.html`)

`app.html` 안에서 **아래 4곳만** 고친다. 색·여백·다른 문구는 손대지 않는다.

### 4-1. 버전 표기
| 찾을 문자열 | 바꿀 값 |
|---|---|
| `<title>폰정리 v3.0</title>` | `<title>폰정리 v3.2</title>` |
| `<b>폰정리<i>v3.0</i></b>` | `<b>폰정리<i>v3.2</i></b>` |

### 4-2. `appInfo(p)` 아래에 삭제 함수 추가
```js
function del(p){
  if (window.Native && Native.uninstall) {
    try { if (Native.uninstall(p)) { closeSheet(); toast('안드로이드 확인창에서 [확인]을 누르면 삭제됩니다'); return; } } catch(e){}
  }
  if (window.Native && Native.info) { Native.info(p); closeSheet(); return; }   // 구버전 폴백
  toast('설치형 앱(APK)에서만 삭제할 수 있습니다');
}
```

### 4-3. 상세 시트의 버튼 (지금 `appInfo('${a.p}')` 를 호출하는 `<button ...>앱 정보 · 삭제</button>`)
- **등급이 `keep`(절대 삭제 금지)인 앱**은 지금 그대로 **`appInfo`만** (삭제 원터치 금지 — 인증·금융 앱을 실수로 지우면 안 된다).
- **그 외 등급**은 `del('${a.p}')` 를 호출하고 라벨을 **`삭제`** 로 바꾼다. 버튼은 기존 `class="pri"`/`class` 구조·2칸 그리드를 그대로 쓴다(새 CSS 금지).

예시(구조 유지, JS 호출만 분기):
```js
${gr.g === 'keep'
  ? `<button onclick="appInfo('${a.p}')">앱 정보</button>`
  : `<button onclick="del('${a.p}')">삭제</button>`}
```

### 4-4. 안내 문구 1줄 (지금 문구가 실제 동작과 어긋나게 된다)
- 지금: `삭제는 폰 설정의 앱 정보 화면에서 직접 합니다. 이 앱은 목록과 등급만 보여 주고, 대신 지우지 않습니다.`
- v3.2: `삭제는 안드로이드 확인창에서 대표님이 직접 누릅니다. 이 앱이 대신 지우지 않습니다. (지워지지 않는 앱은 [앱 정보]로 안내합니다)`
- 맨 위 `rule` 박스의 문장 `실제 삭제는 각 앱의 <b>앱 정보</b> 화면에서 직접 하세요.` → `실제 삭제는 [삭제]를 누르면 뜨는 안드로이드 확인창에서 직접 하세요.` (앞의 `은행·인증서·메신저·계정 앱은 '손대지 마'로 잠갔습니다.` 는 그대로 둔다)

> ⚠️ `Native.uninstall`이 없는 **구버전 앱**에서 이 `app.html`이 돌면 §4-2가 자동으로 `Native.info`로 넘어간다(그래서 구버전에서도 최소 '앱 정보'는 열린다). 이 폴백을 **지우지 말 것.**

---

## 5. 2단계 계속 — 수리 C · 랜딩 페이지(`oneclick/organizer/index.html`)

**딱 3곳**만 고친다. 이 파일은 웹 미리보기·받기 페이지로 계속 쓴다(레이아웃·색·다른 문구 무변경).

### 5-1. 받기 링크를 v3.2로
| 지금 | 바꿀 값 |
|---|---|
| `<a class="dl" href="KTS_폰정리_v3.0.apk" download>` | `<a class="dl" href="KTS_폰정리_v3.2.apk" download>` |
| `<i>v3.0 · 4~12 맞춤 폴더 · 홈 화면 모드</i>` | `<i>v3.2 · 앱 삭제 원터치 · 4~12 맞춤 폴더</i>` |

### 5-2. 설치 안 되는 경우 안내 (지금 `<div class="dnote">웹은 미리보기 · 설치형 앱에서 …</div>` **바로 아래**에 한 줄 추가, 기존 `dnote` 클래스만 사용)
```html
<div class="dnote" style="border-color:rgba(255,107,0,.35)">설치가 안 되면 — ① 폰에 있는 <b>기존 폰정리 앱을 먼저 삭제</b>한 뒤 다시 받으세요. ② 폰정리가 <b>기본 홈 앱</b>으로 잡혀 있어 삭제가 안 되면 설정 → 앱 → 기본 앱 → 홈 앱을 기본 런처로 바꾼 뒤 삭제하세요. ③ Play 프로텍트가 막으면 <b>[무시하고 설치]</b>를 누르세요.</div>
```

### 5-3. 손님이 웹에서 앱 삭제를 누를 때 (브리지 없음 → 안내만)
지금 `appBtn(a)`는 앱을 누르면 실행, 길게 누르면 고정이다. **여기는 손대지 않는다.** 삭제는 설치형 앱 안에서만 되므로, 위 5-2 안내문 끝에 아래 한 문장을 덧붙인다:
`삭제 기능은 설치형 앱에서만 됩니다.`

---

## 6. 3단계 — 빌드 + 서명

### 6-1. 환경 (이미 지난 회차에 설치돼 있다. 없으면 지난 지시서 `CLAUDE_TASK_APK_20261117.md` §2~3 그대로)
```powershell
javac -version          # 17.x
Test-Path "$env:ANDROID_HOME\build-tools\34.0.0\aapt2.exe"     # True
Test-Path "$env:ANDROID_HOME\platforms\android-34\android.jar" # True
```

### 6-2. 작업 폴더 (경로에 한글·공백이 있어 도구가 죽으면 `C:\kts_build`로 복사해 작업)
```powershell
# 소스가 있으면 그 폴더를 그대로 쓴다. 없으면 v3.0 APK에서 자산을 풀어 만든다:
$proj = "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\organizer_apk"
New-Item -ItemType Directory -Force "$proj\assets","$proj\res\drawable","$proj\res\values","$proj\src\com\kts\organizer" | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$oc\organizer\KTS_폰정리_v3.0.apk", "$proj\_extract")
Copy-Item "$proj\_extract\assets\*" "$proj\assets\" -Recurse -Force          # app.html · lock.html · icon.png · k_*.png
Copy-Item "$proj\_extract\res\drawable\ic_launcher.png" "$proj\res\drawable\" -Force
'<?xml version="1.0" encoding="utf-8"?><resources><string name="app_name">폰정리</string></resources>' |
  Set-Content "$proj\res\values\strings.xml" -Encoding UTF8
```
- `assets/app.html`에 §4를 적용한다.
- `src\com\kts\organizer\MainActivity.java` — 원본이 없으면 **부록 A 전문**을 넣는다.
- `AndroidManifest.xml` — **부록 B 전문**(권한 1줄 + versionCode 32 / versionName 3.2 포함).

### 6-3. 빌드 (aapt2 → javac → d8 → dex 넣기 → zipalign)
```powershell
cd $proj
$J=$env:JAVA_HOME; $S=$env:ANDROID_HOME; $BT="$S\build-tools\34.0.0"; $PLAT="$S\platforms\android-34\android.jar"
Remove-Item build -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force build\gen,build\classes,build\dex | Out-Null
& "$BT\aapt2.exe" compile --dir res -o build\res.zip
& "$BT\aapt2.exe" link -o build\base.apk -I $PLAT --manifest AndroidManifest.xml -A assets build\res.zip --java build\gen --min-sdk-version 24 --target-sdk-version 34 --version-code 32 --version-name 3.2
& "$J\bin\javac.exe" -source 8 -target 8 -encoding UTF-8 -classpath $PLAT -d build\classes (Get-ChildItem src -Recurse -Filter *.java).FullName (Get-ChildItem build\gen -Recurse -Filter *.java).FullName
& "$BT\d8.bat" --release --lib $PLAT --min-api 24 --output build\dex (Get-ChildItem build\classes -Recurse -Filter *.class).FullName
Copy-Item build\base.apk build\unsigned.apk -Force
$z=[System.IO.Compression.ZipFile]::Open((Resolve-Path build\unsigned.apk).Path,'Update')
$e=$z.CreateEntry('classes.dex',[System.IO.Compression.CompressionLevel]::Optimal); $es=$e.Open()
$ds=[System.IO.File]::OpenRead((Resolve-Path build\dex\classes.dex).Path); $ds.CopyTo($es); $ds.Close(); $es.Close(); $z.Dispose()
& "$BT\zipalign.exe" -f -p 4 build\unsigned.apk build\aligned.apk
```

### 6-4. 서명
```powershell
# ① 찾은 키스토어로 (지문이 B9:44:DC:04:…:84:2D 인 것)
& "$BT\apksigner.bat" sign --ks "<찾은 키스토어 경로>" --ks-pass pass:<비번> --ks-key-alias KTS --key-pass pass:<비번> `
  --min-sdk-version 24 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true `
  --out "$oc\organizer\KTS_폰정리_v3.2.apk" build\aligned.apk

# ② 같은 키가 없을 때만 — 새 키(이름만 같게). 이 경우 덮어 설치 불가 → 보고서에 명시
& "$J\bin\keytool.exe" -genkeypair -keystore "$env:USERPROFILE\kts_organizer_v32.jks" -storepass <정한비번> -keypass <정한비번> `
  -alias KTS -keyalg RSA -keysize 2048 -validity 10000 -dname "C=KR, L=Seoul, O=KTS, OU=AutoOneClick, CN=KTS"
```
- **키스토어·비밀번호는 저장소에 절대 넣지 않는다.** 비밀번호는 보고서에도 쓰지 말고 `PC에 보관` 이라고만 적는다.
- 산출물 경로는 반드시 **`$oc\organizer\KTS_폰정리_v3.2.apk`** (그래야 `index.html`의 상대 링크가 바로 맞는다).

---

## 7. 4단계 — 검증 (7종, 전부 실측)

```powershell
$apk = "$oc\organizer\KTS_폰정리_v3.2.apk"
# 1) zip 무결성
python -c "import zipfile;print('testzip =', zipfile.ZipFile(r'$apk').testzip())"      # 기대: None
# 2) 서명
& "$BT\apksigner.bat" verify -v --print-certs $apk                                     # 기대: v1/v2/v3 = true, 지문 일치(같은 키일 때)
# 3) 버전·권한 (badging)
& "$BT\aapt2.exe" dump badging $apk | Select-String "versionCode|versionName|uses-permission"   # 기대: 32 / 3.2 / REQUEST_DELETE_PACKAGES
# 4) 매니페스트 원문
& "$BT\aapt2.exe" dump xmltree --file AndroidManifest.xml $apk | Select-String "REQUEST_DELETE_PACKAGES"   # 기대: 1줄 이상
# 5) dex에 삭제 인텐트가 실제로 들어갔는가
python -c "d=open(r'build\dex\classes.dex','rb').read();print('ACTION_DELETE =', b'android.intent.action.DELETE' in d, '| uninstall =', b'uninstall' in d)"   # 기대: True True
# 6) APK 안 app.html이 고쳐졌는가
python -c "import zipfile;h=zipfile.ZipFile(r'$apk').read('assets/app.html').decode('utf-8');print('Native.uninstall =', 'Native.uninstall' in h, '| v3.2 =', 'v3.2' in h, '| v3.0 =', '폰정리 v3.0' in h)"   # 기대: True True False
# 7) 푸시 후 라이브 파일
Invoke-WebRequest "https://autooneclick.com/organizer/KTS_%ED%8F%B0%EC%A0%95%EB%A6%AC_v3.2.apk" -Method Head | Select-Object StatusCode,Headers
```

**판정**
- 1~6 중 하나라도 기대와 다르면 **푸시하지 말고** 원인을 고친다.
- 7번이 404면 푸시가 안 된 것이거나 파일명 인코딩 문제다 → `git status`로 실제 파일명 확인(한글 파일명 그대로여야 한다: `KTS_폰정리_v3.2.apk`).
- **폰에서 실제로 되는지는 PC가 확인할 수 없다.** §9 체크리스트로 넘기고, 보고서에 "실기기 미검증"이라고 분명히 적는다.

---

## 8. 5단계 — 커밋·푸시

```powershell
# ① oneclick (APK + 랜딩)
cd $oc
git add "organizer/KTS_폰정리_v3.2.apk" "organizer/index.html"
git commit -m "fix(organizer): v3.2 APK - REQUEST_DELETE_PACKAGES + Native.uninstall(ACTION_DELETE) + 앱 첫 화면을 asset app.html로 · 받기 링크/설치 안내"
git push origin main
git log --oneline -1

# ② K0612766940K- (결과 문서만)
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git add CLAUDE_RESULT_20261122_ORGANIZER_APK.md
git commit -m "result: 폰정리 APK v3.2 삭제 권한 수리 (REQUEST_DELETE_PACKAGES + ACTION_DELETE)"
git push origin main
```
- `git add -A` 금지. 위 목록만.
- 구 `KTS_폰정리_v3.0.apk`는 **삭제하지 않는다**(커밋에 포함되지도 않는다).

---

## 9. 6단계 — 결과 보고서 (`CLAUDE_RESULT_20261122_ORGANIZER_APK.md`)

아래 8개 항목을 **실측값으로** 적는다.

1. 시작/끝 커밋 해시(두 저장소) · 소스 폴더를 찾았는지(경로) · 키스토어를 찾았는지(**경로는 쓰지 말고 "발견/미발견"과 지문 일치 여부만**)
2. 변경 파일 목록과 `git diff --stat` (기대: 매니페스트 · MainActivity.java · assets/app.html · organizer/index.html + 새 APK 1개)
3. APK: 파일명 · 바이트 크기 · SHA256 · 서명 결과(v1/v2/v3 · 서명자 지문) · `versionCode/versionName` · `aapt2 dump badging` 출력 3줄
4. 검증 7종 각각의 **명령과 실제 출력**
5. 첫 화면 교체(원격 → `assets/app.html`)를 했다는 사실과 그 이유(§3-3 문단)
6. 폰 화면 미검증 사실 + 대표님 실기기 체크리스트(아래)
7. 막힌 점·경고(오류 원문 그대로) — 없으면 "없음"
8. **대표님께 그대로 전할 안내 3줄** (아래)

**대표님 실기기 체크리스트 (결과 문서에 그대로)**
- [ ] 폰에서 기존 폰정리 앱 삭제 (안 되면 설정 → 앱 → 기본 앱 → 홈 앱을 기본 런처로 바꾼 뒤 삭제)
- [ ] `autooneclick.com/organizer/` → **[폰정리 앱(APK) 바로 받기 v3.2]** → 설치
- [ ] 앱을 열면 **등급·폴더 화면**이 뜨는지 (받기 배너 페이지가 아니라)
- [ ] 등급 '지워도 됨' 앱 → 상세 → **[삭제]** → **안드로이드 삭제 확인창**이 뜨고 [확인]을 누르면 지워지는지
- [ ] 은행·인증 앱은 **[앱 정보]** 만 뜨고 삭제 버튼이 없는지

**대표님께 전할 3줄(초안)**
> 폰정리 v3.2 올렸습니다. 삭제 권한이 빠져 있어서 삭제 버튼이 안 먹던 것이라, 권한을 넣고 삭제창이 바로 뜨게 새로 빌드했습니다.
> 앱을 열면 이제 받기 페이지가 아니라 등급·폴더 화면이 뜹니다. 지워도 되는 앱에서 [삭제] → 안드로이드 확인창에서 [확인]을 누르면 지워집니다.
> 설치는 기존 폰정리를 먼저 지우고 받아 주세요. 폰정리가 기본 홈 앱으로 잡혀 있으면 설정 → 기본 앱 → 홈 앱을 기본 런처로 바꾼 뒤 지우면 됩니다.

---

## 10. 완료 체크리스트

- [ ] 매니페스트에 `REQUEST_DELETE_PACKAGES` 1줄 · versionCode `32` · versionName `3.2`
- [ ] `MainActivity` 브리지에 `uninstall(String)` — `ACTION_DELETE` + `package:` URI + `FLAG_ACTIVITY_NEW_TASK`
- [ ] 첫 화면이 `file:///android_asset/app.html` (lock 분기는 유지)
- [ ] `assets/app.html`: `del()` + keep 등급은 `앱 정보`만 + 안내문 2곳 + 배지 v3.2
- [ ] `organizer/index.html`: 링크 `KTS_폰정리_v3.2.apk` · 라벨 `v3.2 · 앱 삭제 원터치 · …` · 설치 안내 1줄
- [ ] `oneclick/organizer/` 밖 변경 **0건** (`git status --short`로 증명)
- [ ] 검증 7종 전부 기대값
- [ ] 두 저장소 push 완료 · 해시 기록
- [ ] 실기기 미검증 명시 + 체크리스트·안내 3줄 포함

## 11. 실패 시 보고 형식 (이대로)
```
## 어디서 막혔나
- 단계: (1 소스확인 / 2 매니페스트 / 3 Java / 4 app.html / 5 index.html / 6 빌드 / 7 서명 / 8 검증 / 9 푸시)
- 실행한 명령: ...
- 오류 원문:
  <붙여넣기>
- 내가 확인한 것: (파일 존재, 버전 출력, exit code 등)
- 추정 원인: (확실한 것과 아닌 것을 구분)
- 이미 성공한 부분: (되돌리지 말 것)
```

---

## 부록 A — `src/com/kts/organizer/MainActivity.java` (원본 소스가 없을 때만 사용)

> v3.0 APK를 역컴파일해 **동작을 그대로** 옮기고 `uninstall()`·첫 화면만 바꾼 판이다. 원본 소스가 PC에 있으면 **원본에 §3-2 블록 하나만** 붙이고 이 파일은 쓰지 않는다.

```java
package com.kts.organizer;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Base64;
import android.view.KeyEvent;
import android.webkit.JavascriptInterface;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.io.ByteArrayOutputStream;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class MainActivity extends Activity {

    private WebView wv;
    private boolean fallbackDone = false;

    private String deviceId() {
        String id = Settings.Secure.getString(getContentResolver(), "android_id");
        if (id == null) id = "unknown";
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] h = md.digest((id + "|com.kts.organizer").getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < 8; i++) sb.append(String.format("%02x", h[i]));
            return sb.toString().toUpperCase();
        } catch (Exception e) {
            return Integer.toHexString(id.hashCode()).toUpperCase();
        }
    }

    private boolean deviceOk() {
        SharedPreferences sp = getSharedPreferences("kts_lock", 0);
        String dev = sp.getString("dev", null);
        String now = deviceId();
        if (dev != null) return dev.equals(now);
        sp.edit().putString("dev", now).apply();
        return true;
    }

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        wv = new WebView(this);
        WebSettings s = wv.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setBuiltInZoomControls(false);
        wv.setBackgroundColor(0xFF0A1128);
        final boolean locked = !deviceOk();
        wv.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, String url) {
                if (!url.startsWith("tel:") && !url.startsWith("sms:") && !url.startsWith("mailto:")) {
                    if ((!url.startsWith("http://") && !url.startsWith("https://")) || url.contains("kim779944-max.github.io")) return false;
                }
                try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); } catch (Exception e) {}
                return true;
            }
            @Override
            public void onReceivedError(WebView v, WebResourceRequest req, WebResourceError err) {
                if (req.isForMainFrame() && !fallbackDone && !locked) {
                    fallbackDone = true;
                    v.loadUrl("file:///android_asset/app.html");
                }
            }
        });
        wv.addJavascriptInterface(new Bridge(this), "Native");
        // ★ v3.2 — 앱 첫 화면은 앱 화면(app.html). 원격 organizer/index.html 은 받기 배너가 붙은 웹 소개 페이지다.
        wv.loadUrl(locked ? "file:///android_asset/lock.html" : "file:///android_asset/app.html");
        setContentView(wv);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (wv != null) wv.postDelayed(new Runnable() {
            public void run() {
                try { wv.evaluateJavascript("window.__phonesRefresh&&window.__phonesRefresh()", null); } catch (Throwable t) {}
            }
        }, 300);
    }

    @Override
    public boolean onKeyDown(int code, KeyEvent e) {
        if (code == KeyEvent.KEYCODE_BACK && wv != null && wv.canGoBack()) { wv.goBack(); return true; }
        return super.onKeyDown(code, e);
    }

    public static class Bridge {
        private final Context ctx;
        Bridge(Context c) { this.ctx = c; }

        private int categoryOf(PackageManager pm, String pkg) {
            try {
                if (android.os.Build.VERSION.SDK_INT >= 26) return pm.getApplicationInfo(pkg, 0).category;
                return -1;
            } catch (Exception e) { return -1; }
        }

        private String iconB64(Drawable d, int size) {
            try {
                Bitmap bm = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
                Canvas cv = new Canvas(bm);
                d.setBounds(0, 0, size, size);
                d.draw(cv);
                ByteArrayOutputStream bo = new ByteArrayOutputStream();
                bm.compress(Bitmap.CompressFormat.PNG, 88, bo);
                return "data:image/png;base64," + Base64.encodeToString(bo.toByteArray(), 2);
            } catch (Exception e) { return ""; }
        }

        private String q(String s) {
            if (s == null) return "\"\"";
            StringBuilder sb = new StringBuilder("\"");
            for (int i = 0; i < s.length(); i++) {
                char c = s.charAt(i);
                if (c == '\t') sb.append("\\t");
                else if (c == '\n') sb.append("\\n");
                else if (c == '\r') sb.append("\\r");
                else if (c == '"') sb.append("\\\"");
                else if (c == '\\') sb.append("\\\\");
                else if (c >= 32) sb.append(c);
                else sb.append(String.format("\\u%04x", (int) c));
            }
            sb.append('"');
            return sb.toString();
        }

        @JavascriptInterface
        public String apps() {
            StringBuilder out = new StringBuilder("[");
            try {
                PackageManager pm = ctx.getPackageManager();
                Intent it = new Intent(Intent.ACTION_MAIN);
                it.addCategory(Intent.CATEGORY_LAUNCHER);
                List<ResolveInfo> raw = pm.queryIntentActivities(it, 0);
                List<ResolveInfo> list = new ArrayList<ResolveInfo>();
                List<String> seen = new ArrayList<String>();
                for (ResolveInfo r : raw) {
                    String p = r.activityInfo.packageName;
                    if (!seen.contains(p) && !p.equals(ctx.getPackageName())) { seen.add(p); list.add(r); }
                }
                Collections.sort(list, new Comparator<ResolveInfo>() {
                    public int compare(ResolveInfo a, ResolveInfo b) {
                        return String.valueOf(a.loadLabel(ctx.getPackageManager())).compareToIgnoreCase(String.valueOf(b.loadLabel(ctx.getPackageManager())));
                    }
                });
                boolean first = true;
                for (ResolveInfo r : list) {
                    String p = r.activityInfo.packageName;
                    String n = String.valueOf(r.loadLabel(pm));
                    String ic = "";
                    try { ic = iconB64(pm.getApplicationIcon(p), 72); } catch (Exception e) {}
                    if (!first) out.append(',');
                    out.append("{\"p\":").append(q(p)).append(",\"n\":").append(q(n))
                       .append(",\"i\":").append(q(ic)).append(",\"c\":").append(categoryOf(pm, p)).append('}');
                    first = false;
                }
            } catch (Exception e) { return "[]"; }
            out.append(']');
            return out.toString();
        }

        @JavascriptInterface
        public boolean launch(String pkg) {
            try {
                Intent i = ctx.getPackageManager().getLaunchIntentForPackage(pkg);
                if (i == null) return false;
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                ctx.startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public void open(String url) {
            try {
                Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                ctx.startActivity(i);
            } catch (Exception e) {}
        }

        @JavascriptInterface
        public void homeSettings() {
            try {
                Intent i = new Intent("android.settings.HOME_SETTINGS");
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                ctx.startActivity(i);
            } catch (Exception e) {}
        }

        @JavascriptInterface
        public boolean info(String pkg) {
            try {
                Intent i = new Intent("android.settings.APPLICATION_DETAILS_SETTINGS");
                i.setData(Uri.parse("package:" + pkg));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                ctx.startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        /** ★ v3.2 — 안드로이드 시스템 삭제 확인창 (REQUEST_DELETE_PACKAGES 필요) */
        @JavascriptInterface
        public boolean uninstall(String pkg) {
            if (pkg == null) return false;
            pkg = pkg.trim();
            if (!pkg.matches("[A-Za-z0-9_.]+")) return false;
            if (pkg.equals(ctx.getPackageName())) return false;
            try {
                Intent i = new Intent(Intent.ACTION_DELETE, Uri.parse("package:" + pkg));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                ctx.startActivity(i);
                return true;
            } catch (Exception e) { return false; }
        }

        @JavascriptInterface
        public boolean isHome() {
            try {
                Intent i = new Intent(Intent.ACTION_MAIN);
                i.addCategory(Intent.CATEGORY_HOME);
                ResolveInfo r = ctx.getPackageManager().resolveActivity(i, 65536);
                return r != null && r.activityInfo != null && ctx.getPackageName().equals(r.activityInfo.packageName);
            } catch (Exception e) { return false; }
        }
    }
}
```

## 부록 B — `AndroidManifest.xml` 전문 (versionCode 32)

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.kts.organizer"
    android:versionCode="32"
    android:versionName="3.2">

    <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34" />

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
    <!-- ★ v3.2: 앱 삭제 요청 권한 (없으면 안드로이드 9+ 에서 ACTION_DELETE 가 막힌다) -->
    <uses-permission android:name="android.permission.REQUEST_DELETE_PACKAGES" />

    <queries>
        <intent>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent>
    </queries>

    <application
        android:label="@string/app_name"
        android:icon="@drawable/ic_launcher"
        android:allowBackup="false"
        android:hardwareAccelerated="true"
        android:usesCleartextTraffic="true"
        android:theme="@android:style/Theme.Material.NoActionBar">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:stateNotNeeded="true"
            android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.HOME" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

> 원본 소스의 매니페스트가 있으면 **그 파일에서 권한 1줄 + 버전 2값만** 바꾼다. `theme`·`label` 값은 원본 값을 그대로 두는 것이 우선이다(위 부록 값은 원본이 없을 때의 재현판).

## 부록 C — 지니가 확인했지만 PC가 확인해야 하는 것
| 항목 | 지니 확인(2026-11-22 07:15) | PC가 확인할 것 |
|---|---|---|
| v3.0 APK 무결성 | `testzip()=None`, 14개 엔트리 | 새 APK도 같은지 |
| 권한 문자열 풀 | 42개 전수, `REQUEST_DELETE_PACKAGES` 없음 | 새 APK에 있는지 |
| 삭제 인텐트 | dex에 `ACTION_DELETE` 없음 | 새 dex에 있는지(§7-5) |
| 서명 지문 | `B9:44:DC:04:…:84:2D` | 새 서명 지문과 비교 |
| 라이브 페이지 | `organizer/index.html`과 **완전히 동일**(13,939자) | 푸시 후 링크가 v3.2인지 |
| 라이브 APK URL | `KTS_%ED%8F%B0%EC%A0%95%EB%A6%AC_v3.0.apk` → HTTP 200 · 152,463 bytes | v3.2 URL 200인지 |

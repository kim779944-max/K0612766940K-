# PC 클로드 코드 작업 지시서 — 세이캡 APK 빌드 (2026-11-17)

> **이 문서 하나만 읽고 끝까지 실행하세요. 마지막에 `git push`까지 하면 끝입니다.**
> 대상: 이 저장소의 `app_saycap/` (KTS 세이캡 Android 앱 소스, 현재 **v1.4 / versionCode 14**)
> 목표: ① 이 PC에 JDK·Android SDK를 설치해 **앞으로 PC에서 APK를 직접 빌드할 수 있게** 만들고 ② 그걸 증명하는 **세이캡 v1.4 debug APK**를 실제로 뽑는다.
> APK는 PC에만 둡니다(이 저장소는 공개라 상품 APK는 올리지 않습니다). 저장소에는 **빌드 결과 문서**만 올립니다.
> 소요 예상: 15~30분(대부분 다운로드). 필요 디스크: 약 1GB.

---

## 0. 절대 규칙 (하나라도 어기면 작업 중단)

1. **제0원칙 — 앱 소스·UI·기능 무변경.** 이 작업에서 바꿔도 되는 것은 **딱 두 값**입니다:
   `app_saycap/AndroidManifest.xml`의 `android:versionCode`(→ 14), `android:versionName`(→ 1.4).
   `src/`, `res/`, `assets/`는 **읽기만** 합니다. 리팩터링·정리·주석 추가·포맷 변경 금지.
2. **외부 발송·결제·과금·스토어 업로드 0건.** 문자/메일/SNS 발송, 유료 API 호출, Google Play 업로드, 광고 집행 전부 하지 않습니다.
3. **웹 자산 무변경**: `index.html`, `saycap/`, `oneclick/`, `misa-1116/`, `navi/`, `organizer/`, `output/shorts_20261117/` 은 건드리지 않습니다.
4. **비밀값 커밋 금지**: `*.keystore`, `*.jks`, 비밀번호, 토큰을 저장소에 넣지 않습니다. debug 키는 `%USERPROFILE%\.android\debug.keystore`에만 생기게 둡니다.
5. **없으면 만들지 말 것**: 저장소에 Android 프로젝트(`AndroidManifest.xml`)가 없으면 **새 프로젝트를 새로 만들지 말고** "없음"으로 보고하고 빌드를 중단합니다.
6. **실패는 그대로 보고**: 추측으로 넘어가지 말고, 어느 단계에서 어떤 명령이 어떤 오류 메시지로 막혔는지 원문 그대로 적습니다.

---

## 1. 0단계 — 저장소와 현재 상태 확인

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git pull
git log --oneline -3
Get-ChildItem -Recurse -Depth 3 -Filter AndroidManifest.xml | Select-Object -ExpandProperty FullName
Get-ChildItem -Directory | Select-Object -ExpandProperty Name
```

**판정표**

| 확인 결과 | 할 일 |
|---|---|
| `app_saycap\AndroidManifest.xml` 있음(기본 대상) | 그대로 2단계로 진행 |
| `app_saycap`은 없고 `saycap\android\`, `oneclick\android\`, `app_viewer\`, `app_sms\` 등 다른 Android 프로젝트가 있음 | 그 폴더를 대상으로 2~6단계를 같게 진행(경로만 바꿈) |
| `*/build.gradle` + `*/gradlew.bat` 가 있는 표준 프로젝트 | 그 프로젝트는 `.\gradlew.bat assembleDebug`로 빌드해도 됩니다(단, 소스 무변경·versionCode/versionName만) |
| **Android 프로젝트가 어디에도 없음** | **새로 만들지 마세요.** 2·3단계(도구 설치)만 끝내고 "Android 프로젝트 없음"으로 보고 후 중단 |

---

## 2. 1단계 — JDK 17 설치 (재부팅 없이)

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-source-agreements --accept-package-agreements
```

설치 위치를 찾아 이 창에 즉시 적용하고(재부팅 불필요), 다음 창부터도 유지되게 등록합니다:

```powershell
$j = (Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "jdk-17*" } | Sort-Object Name -Descending | Select-Object -First 1).FullName
if (-not $j) { $j = (Get-ChildItem "$env:LOCALAPPDATA\Android\jdk" -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "jdk-17*" } | Sort-Object Name -Descending | Select-Object -First 1).FullName }
$env:JAVA_HOME = $j
$env:PATH = "$j\bin;$env:PATH"
setx JAVA_HOME "$j" | Out-Null
javac -version    # javac 17.x 가 나와야 정상
```

**winget이 관리자 권한(UAC) 승인 창을 띄워 멈추는 경우** — 지금 실행은 비대화형이라 승인을 누를 수 없습니다. 그때는 zip으로 대체하세요(권한 불필요):

```powershell
$zip = "$env:TEMP\jdk17.zip"
Invoke-WebRequest "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse" -OutFile $zip
Expand-Archive $zip -DestinationPath "$env:LOCALAPPDATA\Android\jdk" -Force
$j = (Get-ChildItem "$env:LOCALAPPDATA\Android\jdk" -Directory | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1).FullName
$env:JAVA_HOME = $j; $env:PATH = "$j\bin;$env:PATH"; setx JAVA_HOME "$j" | Out-Null
javac -version
```

---

## 3. 2단계 — Android SDK 설치 (cmdline-tools만, Android Studio 불필요)

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
New-Item -ItemType Directory -Force "$sdk\cmdline-tools" | Out-Null
$clt = "$env:TEMP\cmdline-tools.zip"
Invoke-WebRequest "https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip" -OutFile $clt
Expand-Archive $clt -DestinationPath "$env:TEMP\clt" -Force
if (Test-Path "$sdk\cmdline-tools\latest") { Remove-Item "$sdk\cmdline-tools\latest" -Recurse -Force }
Move-Item "$env:TEMP\clt\cmdline-tools" "$sdk\cmdline-tools\latest"
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
setx ANDROID_HOME "$sdk" | Out-Null
setx ANDROID_SDK_ROOT "$sdk" | Out-Null
```

라이선스 자동 수락 후 필요한 패키지만 설치합니다:

```powershell
$sm = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
("y`n" * 30) | & $sm --sdk_root=$sdk --licenses
& $sm --sdk_root=$sdk "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

설치 확인(둘 다 `True`가 나와야 함):

```powershell
Test-Path "$sdk\build-tools\34.0.0\aapt2.exe"
Test-Path "$sdk\platforms\android-34\android.jar"
```

> 다운로드 주소가 404면 https://developer.android.com/studio#command-tools 에서 Windows용 최신 zip 주소를 확인해 같은 방식으로 넣으면 됩니다.

---

## 4. 3단계 — versionCode / versionName 확인 (이미 14 / 1.4)

`app_saycap/AndroidManifest.xml` 상단의 **이 두 속성 값만** 봅니다. 저장소에는 이미 `14` / `1.4`로 맞춰져 있으니, 그대로면 **아무것도 바꾸지 말고** 4단계로 넘어갑니다. 혹시 `13` / `1.3`이면 그 두 값만 `14` / `1.4`로 바꿉니다(15 이상으로 올리지 말 것).

```xml
    android:versionCode="14"
    android:versionName="1.4"
```

> 아래 4단계 스크립트가 이 두 값을 자동으로 맞춰 줍니다(정규식으로 그 두 곳만 치환). 손으로 미리 바꿔도 결과는 같습니다.

확인:

```powershell
Select-String -Path .\app_saycap\AndroidManifest.xml -Pattern "versionCode|versionName"
```

---

## 5. 4단계 — APK 빌드

```powershell
cd .\app_saycap
powershell -NoProfile -ExecutionPolicy Bypass -File .\build_apk_debug.ps1 -VersionCode 14 -VersionName 1.4
```

이 스크립트가 하는 일(전부 이 PC 안에서, 외부 전송 없음):
`aapt2 compile` → `aapt2 link`(res+assets 포함) → `javac` → `d8`(classes.dex) → APK에 dex 넣기 → `zipalign` → **debug 키 생성·서명** → `apksigner verify` → `output\apk_20261117\`로 복사

정상이면 마지막에 이렇게 나옵니다:

```
APK    : ...\output\apk_20261117\KTS_saycap_v1.4_debug.apk
SIZE   : ... bytes
SHA256 : ...
BUILD OK
```

### 스크립트가 실패하면 — 수동으로 같은 순서 실행

```powershell
cd .\app_saycap
$J = $env:JAVA_HOME; $S = $env:ANDROID_HOME
$BT = "$S\build-tools\34.0.0"; $PLAT = "$S\platforms\android-34\android.jar"
Remove-Item build -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force build\gen,build\classes,build\dex | Out-Null

& "$BT\aapt2.exe" compile --dir res -o build\res.zip
& "$BT\aapt2.exe" link -o build\base.apk -I $PLAT --manifest AndroidManifest.xml -A assets build\res.zip --java build\gen --min-sdk-version 24 --target-sdk-version 34 --version-code 14 --version-name 1.4
& "$J\bin\javac.exe" -source 8 -target 8 -encoding UTF-8 -classpath $PLAT -d build\classes (Get-ChildItem src -Recurse -Filter *.java).FullName (Get-ChildItem build\gen -Recurse -Filter *.java).FullName
& "$BT\d8.bat" --release --lib $PLAT --min-api 24 --output build\dex (Get-ChildItem build\classes -Recurse -Filter *.class).FullName

# APK 안에 classes.dex 넣기
Copy-Item build\base.apk build\unsigned.apk -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::Open((Resolve-Path build\unsigned.apk).Path,'Update')
$e = $z.CreateEntry('classes.dex',[System.IO.Compression.CompressionLevel]::Optimal)
$es = $e.Open(); $ds = [System.IO.File]::OpenRead((Resolve-Path build\dex\classes.dex).Path); $ds.CopyTo($es); $ds.Close(); $es.Close(); $z.Dispose()

& "$BT\zipalign.exe" -f -p 4 build\unsigned.apk build\aligned.apk
if (-not (Test-Path "$env:USERPROFILE\.android\debug.keystore")) {
  New-Item -ItemType Directory -Force "$env:USERPROFILE\.android" | Out-Null
  & "$J\bin\keytool.exe" -genkeypair -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
}
New-Item -ItemType Directory -Force ..\output\apk_20261117 | Out-Null
& "$BT\apksigner.bat" sign --ks "$env:USERPROFILE\.android\debug.keystore" --ks-pass pass:android --key-pass pass:android --min-sdk-version 24 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true --out ..\output\apk_20261117\KTS_saycap_v1.4_debug.apk build\aligned.apk
& "$BT\apksigner.bat" verify -v ..\output\apk_20261117\KTS_saycap_v1.4_debug.apk
```

> 경로 때문에 도구가 죽으면(바탕 화면의 한글·공백, OneDrive 동기화 잠금 등) 저장소를 `C:\kts_build`로 복사해 `C:\kts_build\app_saycap`에서 빌드해도 됩니다. 단 **결과 APK는 반드시 `output\apk_20261117\`에 두고**, 원인은 결과 문서에 적습니다.

---

## 6. 5단계 — 산출물 검증

```powershell
$apk = ".\output\apk_20261117\KTS_saycap_v1.4_debug.apk"
& "$env:ANDROID_HOME\build-tools\34.0.0\apksigner.bat" verify -v $apk
& "$env:ANDROID_HOME\build-tools\34.0.0\aapt2.exe" dump badging $apk | Select-Object -First 3
Get-Item $apk | Select-Object Name,Length
(Get-FileHash $apk -Algorithm SHA256).Hash
```

기대값: `versionCode='14' versionName='1.4'`, 서명 `v2`·`v3` true, 파일 크기 약 15만~20만 바이트.

---

## 7. 6단계 — 결과 문서 작성 후 push

`CLAUDE_RESULT_APK_20261117.md`(저장소 루트, 새 파일)에 아래를 **실측값으로** 적습니다:

1. 환경: `javac -version`, `JAVA_HOME`, `ANDROID_HOME`, build-tools/platforms 버전, 설치 방식(winget/zip)
2. 빌드: 실행한 명령, 총 소요 시간
3. 산출물: 파일명·바이트 크기·SHA256·서명 검증 결과(v1/v2/v3)·`versionCode`/`versionName`
4. 변경 파일: `git status --short` / `git diff --stat` 결과 (저장소 매니페스트가 이미 14/1.4라서 **문서 외 변경 0건이면 정상**입니다. 그 경우 매니페스트는 건드리지 않았음을 적어 주세요)
5. 막힌 점·경고: 있으면 오류 원문 그대로, 없으면 "없음"
6. 대표님 안내 한 줄: **이 APK는 debug 서명이라 기존 v1.3(정식 키) 위에 덮어 설치되지 않습니다 → 폰에서 기존 세이캡을 지우고 설치해야 합니다.**

```powershell
cd "$env:USERPROFILE\OneDrive\바탕 화면\KTS_작업실\K0612766940K-"
git status --short
git add app_saycap/AndroidManifest.xml app_saycap/build_apk_debug.ps1 app_saycap/README_BUILD.md app_saycap/.gitignore CLAUDE_RESULT_APK_20261117.md
git commit -m "build: 세이캡 v1.4 debug APK + PC 빌드 환경(JDK17/SDK) 구축"
git push origin main
git log --oneline -1
```

> `git add -A`는 쓰지 마세요(관계없는 파일이 섞입니다). 위 목록만 올립니다.
> **APK 파일(`output\apk_20261117\*.apk`)은 커밋하지 않습니다.** 이 저장소는 공개라서, 상품 APK를 공개 주소에 두면 누구나 내려받게 됩니다. 빌드 결과물은 PC에 그대로 두고, 대표님께 전달합니다.

---

## 8. 완료 체크리스트

- [ ] `javac -version` 이 17.x
- [ ] `build-tools\34.0.0\aapt2.exe`, `platforms\android-34\android.jar` 존재
- [ ] `AndroidManifest.xml` 변경은 versionCode=14 / versionName=1.4 **두 줄뿐**
- [ ] `output\apk_20261117\KTS_saycap_v1.4_debug.apk` 존재
- [ ] `apksigner verify` 통과(v2·v3 true)
- [ ] `CLAUDE_RESULT_APK_20261117.md` 에 크기·SHA256·서명·소요시간 기록
- [ ] `git push` 완료(커밋 해시를 결과 문서에 기재)

## 9. 실패 시 보고 형식 (이대로 적기)

```
## 어디서 막혔나
- 단계: (1 JDK / 2 SDK / 3 version / 4 빌드 / 5 검증 / 6 push)
- 실행한 명령: ...
- 오류 원문:
  <붙여넣기>
- 내가 확인한 것: (파일 존재 여부, 버전 출력 등)
- 추정 원인: (확실한 것과 아닌 것을 구분해서)
```

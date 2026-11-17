# KTS 세이캡 — Android 앱 소스 (APK 빌드용)

세이캡 2026 웹앱(`assets/app.html`)을 WebView로 감싼 네이티브 앱입니다.
`com.kts.saycap` · minSdk 24 · targetSdk 36 · 현재 v1.3(versionCode 13).

## 폴더

| 경로 | 내용 |
|---|---|
| `AndroidManifest.xml` | 패키지·권한·액티비티 정의. 빌드 시 `versionCode`/`versionName`만 바뀝니다. |
| `src/com/kts/saycap/MainActivity.java` | WebView + 카메라·음성인식·공유 브릿지 |
| `res/` | 앱 이름·런처 아이콘 |
| `assets/app.html` | 앱에 내장된 세이캡 화면 |
| `assets/lock.html` | 기기 재인증 안내 화면 |
| `build_apk_debug.ps1` | Gradle 없이 APK를 만드는 빌드 스크립트(Windows) |

## 빌드 (Windows, Gradle·Android Studio 불필요)

필요한 것: JDK 17(`JAVA_HOME`), Android SDK(`ANDROID_HOME`, build-tools + platforms)

```powershell
cd app_saycap
powershell -NoProfile -ExecutionPolicy Bypass -File .\build_apk_debug.ps1 -VersionCode 14 -VersionName 1.4
```

결과: `output\apk_20261117\KTS_saycap_v1.4_debug.apk` (debug 키 서명)

파이프라인: `aapt2 compile` → `aapt2 link`(res+assets) → `javac` → `d8` → zip에 `classes.dex` → `zipalign` → `apksigner`

## 지켜야 할 것

- `src/`·`res/`·`assets/`는 손대지 않습니다. 빌드는 `versionCode`/`versionName`만 바꿉니다.
- `*.keystore`·`*.jks`·비밀번호는 이 저장소에 올리지 않습니다(debug 키는 `%USERPROFILE%\.android\debug.keystore`에 자동 생성).
- 정식 배포용 서명 키는 이 저장소에 없습니다. 이 스크립트가 만드는 APK는 **debug 서명**이라, 정식 키로 서명한 기존 설치본 위에 덮어 설치되지 않습니다(설치 전 기존 앱 삭제 필요).

## v1.5 브리지 (2026-11-17) — '내 폰 사진' 목록

`MainActivity.java`의 `SayCapApp` 브리지에 추가된 것 (웹 `saycap/index.html`·`assets/app.html`이 자동 감지, 없으면 파일 선택창으로 동작):

| 이름 | 내용 |
|---|---|
| `SayCapApp.version()` | `"1.5"` |
| `SayCapApp.listPhotos(offset, limit)` | `MediaStore.Images` 최신순 목록 JSON `{perm,total,offset,items:[{id,uri(content://),name,date(ms),w,h,mime}]}`. 권한이 없으면 `{"perm":false}`를 돌려주고 권한을 요청, 결과는 `window.__devPhotosReady(true/false)` |
| `SayCapApp.openPhoto(id)` | 고른 사진 1장을 기존 조각 전달(`__npBegin`…`__npAllDone`)로 넘김(예비 경로) |
| `<페이지 폴더>/__saycap_thumb?id=…&s=320` | `shouldInterceptRequest`가 썸네일 JPEG로 응답(LRU 12MB 캐시) |
| `<페이지 폴더>/__saycap_media?id=…` | 원본 바이트 그대로 응답(웹에서 `fetch` → 편집 화면) |
| `window.__saycapRms(dB)` | 음성인식 소리 크기(약 14fps) → 자막 아래 이퀄라이저 |

권한: API 33+ `READ_MEDIA_IMAGES`(34+는 `READ_MEDIA_VISUAL_USER_SELECTED` '일부 사진만 허용' 포함), 32 이하 `READ_EXTERNAL_STORAGE` — `AndroidManifest.xml`에 선언되어 있습니다.

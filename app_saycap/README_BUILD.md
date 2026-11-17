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

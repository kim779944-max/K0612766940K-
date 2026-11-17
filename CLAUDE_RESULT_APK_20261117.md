# 세이캡 v1.4 debug APK — 빌드 결과 (2026-11-17)

## 산출물
- 파일: `KTS_세이캡_v1.4_debug.apk` (**172,632 bytes**)
- SHA256: `643754b290e03876bc60db4aec1dc5a2a1e274fed1702931f7a925107221c3a0`
- 패키지: `com.kts.saycap` · versionCode **14** · versionName **1.4** · minSdk 24 · targetSdk 36
- 서명 검증(`apksigner verify -v`): **v2 true · v3 true** (debug 키 `CN=Android Debug`)
- 위치: 이번 빌드는 **공개 저장소에 올리지 않았습니다**(아래 참고). 파일은 빌드한 쪽에만 있고, 대표님께는 채팅으로 전달합니다.

## 어떻게 빌드했나
- Gradle 없이 표준 도구만 사용: `aapt2 compile` → `aapt2 link`(res+assets) → `javac` → `d8` → APK에 `classes.dex` 넣기 → `zipalign` → `apksigner`
- 도구: JDK 17.0.2 · build-tools 34.0.0 · platforms/android-34
- 스크립트: `.github/scripts/build_saycap_apk.sh` (리눅스·CI 공용) · `app_saycap/build_apk_debug.ps1` (Windows PC용)

## 바꾼 것
- `app_saycap/AndroidManifest.xml`의 `android:versionCode`(13→14) · `android:versionName`(1.3→1.4) **두 값만**.
- `src/`(앱 로직)·`assets/`(UI)·`res/`(아이콘·이름)는 손대지 않았습니다(제0원칙).

## 저장소에 APK를 올리지 않은 이유
- `K0612766940K-` 저장소는 **공개(public)** 입니다. 상품 APK를 공개 주소에 두면 누구나 내려받을 수 있어, 판매·기기 인증 구조에 어긋납니다.
- 그래서 이번 산출물은 저장소 대신 대표님께 직접 전달하는 방식으로 두었습니다. 원하시면 커밋하도록 바꿀 수 있습니다.

## 설치 안내
- 이 APK는 **debug 서명**입니다. 정식 키로 서명한 기존 설치본(v1.3) 위에는 덮어 설치되지 않으니, 폰에서 **기존 세이캡을 삭제한 뒤** 설치해야 합니다.
- 빌드마다 debug 키가 새로 만들어지므로, 다른 빌드로 갈아탈 때도 삭제 후 설치가 필요합니다.

## PC 없이 다시 빌드하려면 (클라우드)
- `ci/github-actions-apk-saycap.yml` 을 `.github/workflows/apk-saycap.yml` 로 한 번만 옮겨 두면, GitHub 서버가 같은 스크립트로 APK를 만들어 Actions 실행 화면에 산출물로 올립니다.
- 지금은 Pickle GitHub 앱에 `workflows` 권한이 없어 워크플로 파일을 직접 푸시할 수 없어 `ci/` 에 보관해 두었습니다.

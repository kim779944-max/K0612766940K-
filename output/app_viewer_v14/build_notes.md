# 더뷰 v1.4 — 동기화본 · 빌드 노트 (2026-11-20)

**APK: 미완** — 이 PC에 `app_viewer` 프로젝트 폴더가 없고, JDK 17·Android SDK(build-tools 34)도 없습니다.
(지시서 판정표: "app_viewer 없음 → 동기화본만 남긴다", "JDK/SDK 없음 → 도구 설치 시도하지 말고 미완 보고")

## 이 폴더

| 파일 | 내용 |
|---|---|
| `assets/viewer.html` | 웹 최신 `oneclick/viewer.html`(88,663B, A4 1:1 인화 보기 포함) + 아래 ⓐ~ⓓ 4곳만 바꾼 앱 자산 |
| `viewer_web_vs_app_v14.diff` | 웹 원본 대비 diff (4곳뿐) |
| `verify_asset.ps1` · `verify_asset_log.txt` · `check_*.png` | 헤드리스 크롬 390px 자산 검수 |

## ⓐ~ⓓ (웹 원본 → 앱 자산)

| # | 바꾼 것 |
|---|---|
| ⓐ | 2번째 줄 `<script src="master.js"></script>` 삭제 |
| ⓑ | cdnjs `pdf.min.js` → `<script src="pdf.worker.min.js"></script>` 먼저, 그다음 `<script src="pdf.min.js"></script>`. `workerSrc = 'pdf.worker.min.js'`. CDN 폴백 줄은 두지 않음(외부 요청 0) |
| ⓒ | `<script src="hwp.js"></script>` 추가, `.hwp` 분기를 안내카드(`kind:'notice'`)에서 `if (typeof KTS_HWP === 'undefined' \|\| !KTS_HWP.parseHwp) throw …` + `r = await KTS_HWP.parseHwp(await file.arrayBuffer())` 로 복원 |
| ⓓ | `<title>더뷰 v1.4 — KTS 만능 뷰어 (한글·엑셀·워드·PDF·사진)</title>` |

> ⚠ ⓒ는 지시서에 적힌 v1.3 코드 형태 그대로 넣었습니다. v1.3 자산 원본(`app_viewer/assets/viewer.html`)·`hwp.js`가 이 PC에 없어 **원본과 한 줄씩 대조하지 못했습니다.** `parseHwp`가 돌려주는 값이 `{kind:'html', html, note}` 형태여야 `paintDoc()`이 그립니다 — 빌드 PC에서 v1.3 분기와 대조하세요.

## 버전 2값 (app_viewer 쪽에서 바꿀 것)

- `AndroidManifest.xml`: `android:versionCode="14"` → `"15"`, `android:versionName="1.3"` → `"1.4"`
- `build.sh`: `--version-code 14` → `15`, `--version-name 1.3` → `1.4`, 출력 `KTS_더뷰_v1.3_debug.apk` → `KTS_더뷰_v1.4_debug.apk`
- `build.sh` 경로 3줄(`JAVA_HOME`·`BT`·`PLAT`)만 빌드 PC의 JDK 17 · build-tools 34 · android-34 `android.jar` 경로로

## 빌드 PC에서 실행 순서

```powershell
cd <app_viewer>
git rev-parse HEAD                                   # 되돌림용
Copy-Item <K0612766940K->\output\app_viewer_v14\assets\viewer.html assets\viewer.html -Force
git diff --stat                                      # assets/viewer.html 만
# AndroidManifest.xml · build.sh 위 값 수정 후
bash build.sh                                        # → KTS_더뷰_v1.4_debug.apk
& $BT\apksigner verify -v KTS_더뷰_v1.4_debug.apk     # v1/v2/v3 true
& $BT\aapt dump badging KTS_더뷰_v1.4_debug.apk | Select-String versionCode   # 15 / 1.4
Get-FileHash KTS_더뷰_v1.4_debug.apk -Algorithm SHA256
```

APK는 저장소에 올리지 않습니다.

## 자산 검수 결과 (이 PC, 앱 라이브러리 없이)

- 제목 `더뷰 v1.4 — …` 확인 · 외부 요청 0건(resource timing) · `<script src>` 중 http(s) 0개 · 390px 가로 넘침 0
- 로드 오류 3건 = `hwp.js`·`pdf.worker.min.js`·`pdf.min.js` (앱 assets에만 있는 파일. 이 PC에는 없음 — 예상된 것)
- xlsx 열림(13행×9열) · hwpx 열림(9행×5열) · 사진 열림 · 오류 0
- PDF: `pdfjsLib` 없음 → 기존 폴백(frame)으로 열림. 앱 assets에서는 pdf.js로 그려야 함 — **빌드 PC 재확인 필요**
- `.hwp`(더미): `hwp.js` 없음 → "구형 한글(.hwp) 읽기 모듈(hwp.js)을 불러오지 못했습니다" 안내. 실제 파싱은 **빌드 PC 재확인 필요**
- 참고: [이미지로 저장] 누를 때만 cdnjs `html2canvas`를 불러오는 코드가 웹 원본에 2곳 있음(열 때는 요청 0). 지시서 ⓐ~ⓓ 밖이라 그대로 둠

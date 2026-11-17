# PC 클로드 코드 정밀 작업 지시서 (CLAUDE_TASK_20261118_SET.md)

> 발령: 2026-11-18 08:42 · 사령관 지니 → PC 클로드 코드(Pro 정액제)
> 제0원칙: 기존 정상 동작 파일(특히 `thescan`, `theeraser`, `theview`) 틀·색감·기능 일절 무변경.
> 결과 보고서: 완료 후 반드시 `CLAUDE_RESULT_20261118_SET.md`를 생성해 `git commit && git push` 한다.

---

## 작업 1. `세이캡 v1.5 APK` 빌드 및 모델 배너 반영
- **대상**: `app_saycap/`, `saycap/index.html`, `saycap/model_friends_23_final.png`
- **배경**: `saycap/model_friends_23_final.png`와 `assets/model_friends_23_final.png`가 저장소에 추가되었음.
- **실행**:
  1. `saycap/index.html` 및 `app_saycap/assets/app.html`이 `model_friends_23_final.png`를 입구 화보 배너에 정상 표시하는지 확인.
  2. `app_saycap/build_apk_debug.ps1`(또는 Gradle/빌드 스크립트)로 **`KTS_세이캡_v1.5_debug.apk`** 빌드.
  3. 빌드된 APK를 `output/KTS_세이캡_v1.5_debug.apk`에 저장해 커밋·푸시 (기존 `v1.3`/`v1.4` 대비 `내 폰 사진` MediaStore 브리지 + UX 6원칙 포함 확인).

## 작업 2. 전 상품 1세트 규격 — 모델 실사 클립 활용 시연 숏츠 리메이크
- **절대 금지**: 일러스트 캐릭터(`drawHost`) 대체 금지, 2.5배 과한 확대 금지.
- **활용 소스**: 저장소 `assets/model_clips/` 폴더에 올려 둔 공식 모델 실사 Talking Head 클립(`short1_converter_00.mp4`, `short2_theview_00.mp4`, `short3_saycap_00.mp4`)과 `assets/model_friends_23_final.png`를 사용한다.
- **실행**:
  1. **세이캡 숏츠 리메이크 (`short_saycap_v15_9x16.mp4`)**:
     - 기존 '사진 검색 방법만 단편 설명' 금지!
     - 8년 전 원본 흐름(**수천 장 사진 뒤지는 답답함 → 찍고 말하면 자막·단어 검색 한 방**) + **방금 개편된 새 세이캡 화면(1탭 입구·오렌지 이퀄라이저·저장 후 수정)** 실사용 녹화 + 공식 모델 실사 클립을 자연스럽게 교차 편집한다.
  2. **더스캔 시연 숏츠 신규 제작 (`short_thescan_9x16.mp4`)**:
     - `thescan/index.html`(초점 대기 0초 자동 스캔 → 연결하기/분리하기 → PDF) 실제 390px 시연 화면과 공식 모델 클립 결합.
  3. 산출물은 `output/shorts_set_20261118/`에 저장하고 390px·9:16 Verify 프레임 캡처 1장씩 남긴다.

## 작업 3. `더스캔` 확인 없이 바로 직행 개편 (`thescan/index.html` & `KTS_더스캔_v1.0.apk`)
- **대표님 실사용 피드백**: `"참 확인없이 바로가 더스캔"`
- **현재 불편 원인**: `<input type="file" capture="environment">` 방식이라 안드로이드 기본 카메라 촬영 후 매번 `[재시도 / 확인]` 화면을 눌러야 하고, 첫 화면에서도 버튼을 다시 눌러야 함.
- **수정 목표**:
  1. 웹(`thescan/index.html` 또는 앱 내 페이지)에서 가능한 경우 `getUserMedia({ video: { facingMode: 'environment' } })` 실시간 카메라 뷰를 **확인창 없이 바로 띄워** 찍는 즉시(또는 자동 감지 즉시) 스캔·보정·저장 직행(단, `getUserMedia` 미지원/거부 시 기존 파일 입력 폴백 유지).
  2. 이미 찍어 온 사진도 추가 확인 팝업 없이 **선택 즉시 자동 스캔→결과 목록**에 바로 들어가게 처리.

## 작업 4. (미완료 시) 쿠팡 11종 점검 병행 마무리
- `CLAUDE_RESULT_COUPANG_11_CHECK.md`가 아직 없으면 `CLAUDE_TASK_COUPANG_11_CHECK.md`도 함께 처리해 푸시한다.

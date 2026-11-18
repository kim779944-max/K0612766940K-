# 1세트 규격 숏츠 — 모델 실사 클립 교차 편집 (2026-11-18 작업 2)

| 파일 | 길이 | 크기 | 형식 |
|---|---|---|---|
| `short_saycap_v15_9x16.mp4` (세이캡 리메이크) | 43.2초 | 27.5MB | MP4 H.264 + AAC, 1080×1920, 30fps |
| `short_thescan_9x16.mp4` (더스캔 신규) | 38.3초 | 30.1MB | 같음 |

- Verify 프레임(390×693 = 9:16, 2배 해상도). 완성된 mp4를 크롬에서 다시 열어 해당 시각을 캡처했습니다.
  - `verify/VERIFY_saycap_v15_390x693.png` (22.5초: 말하는 중 주황 이퀄라이저)
  - `verify/VERIFY_thescan_390x693.png` (26.5초: 연결하기 → PDF 한 권 → 합치기)
  - 확인용 추가 캡처: `verify/*_390_*.png`
- **모델**: 공식 모델 실사 클립 `assets/model_clips/*.mp4`와 공식 모델 사진 `assets/model_friends_23_final.png`만 썼습니다. 일러스트 캐릭터(`drawHost`)는 코드에서 지웠습니다.
- **확대**: 모델 장면은 클립 원본 그대로(1.00배)입니다. 앱 장면은 폰 화면 전체를 보여 주고, 누르는 순간에만 최대 1.10배까지 다가갑니다. 녹화 기록의 `maxZoom`은 두 편 모두 1.1입니다. 2.5배 같은 큰 확대는 없습니다.

## 구성

### 세이캡 (`cuesheet_saycap.json`)
| 시작 | 장면 | 나레이션 |
|---|---|---|
| 0.35 | 모델 실사 `short3_saycap_00` | 세이캡 카메라, 알고 계신가요? |
| 3.34 | 일반 폰 사진첩(3,482장)을 끝없이 넘기기, "그 사진 어디 있지?" | 폰 속 수천 장 사진, 그 한 장 찾으려고 아직도 손가락으로 뒤지시나요? |
| 8.77 | 모델 실사 `short2_theview_00` (웃으며 폰 보기) | 2016년 특허 그대로, 찍고 말하면 끝입니다. |
| 12.77 | 실제 새 입구(모델 화보 배너) + **[내 사진 불러오기]** 탭 | 새 세이캡은 내 사진 불러오기, 한 번이면 됩니다. |
| 16.85 | 편집 화면 **[마이크]** 탭 | 사진이 열리면 마이크를 누르고 말하세요. |
| 19.86 | 말하는 중: **주황 이퀄라이저** + 자막이 3단계로 늘어남(`y_talk1→2→3`), 하단 도크 숨김 | 말하는 동안 주황 이퀄라이저가 움직이고, 자막이 바로 새겨집니다. |
| 24.66 | **[저장]** 탭 | 저장을 누르면, |
| 26.26 | 저장 완료 시트 **[수정]** 탭 | 저장한 뒤에도 수정 버튼으로 언제든 고칠 수 있어요. |
| 30.00 | 갤러리 **[검색창]** 탭 | 몇 달 뒤엔 검색창에 단어 하나, 큰방. |
| 33.49 | "큰방" 검색 결과 1장 | 수천 장 중에서 그 사진만 한 방에 찾아 줍니다. |
| 37.13 | 끝맺음: 공식 모델 사진 + autooneclick.com/saycap | 찍고 말하면 자막, 단어 하나로 검색. 세이캡. |

### 더스캔 (`cuesheet_thescan.json`)
| 시작 | 장면 | 나레이션 |
|---|---|---|
| 0.35 | 모델 실사 `short1_converter_00` | 종이 서류, 아직도 스캐너 찾으세요? |
| 3.6 | 더스캔 첫 화면 **[찍기 (0초 자동 보정)]** 탭 | 더스캔은 모서리 맞추기도, 초점 기다리기도 없습니다. 찍기만 누르세요. |
| 9.38 | 실제 '자동 보정 중' 진행 창 | 찍는 즉시 반듯하게 펴고, 그림자까지 지웁니다. |
| 13.4 | 내 스캔 3장 **[분리하기]** 탭 | 세 장이 바로 쌓였죠. 필요한 장만 쓰려면 분리하기. |
| 17.89 | 분리하기 시트(2번 장 선택) **[선택한 페이지 저장]** 탭 | 원하는 페이지만 골라 따로 저장합니다. |
| 20.88 | **[연결하기]** 탭 | 여러 장을 한 문서로 묶을 땐 연결하기. |
| 23.97 | 연결하기 시트 'PDF 한 권' + **[합치기]** 탭 | PDF 한 권을 고르고 합치기를 누르면, |
| 27.06 | 실제 결과 "연결 완료 · PDF 3페이지" | 세 쪽짜리 PDF가 바로 완성됩니다. |
| 30.13 | 모델 실사 `short2_theview_00` | 종이 한 장도, 백 장도 폰 하나로 끝. |
| 33.54 | 끝맺음: 공식 모델 사진 + autooneclick.com/thescan | 설치 없이 지금 무료로, 더스캔. |

(정확한 초 단위는 cuesheet json의 `start`/`tapAt`/`cut` 값에 있습니다.)

## 만든 방법 (python·node·ffmpeg 없이 PowerShell과 크롬만 사용)
- 앱 화면은 실제 페이지를 헤드리스 크롬(390×844, 2배)에서 직접 눌러 가며 캡처했습니다.
  - 세이캡: 저장소의 `saycap/index.html`. 사진은 앱에 들어 있는 샘플(`work/sample2.jpg` = `saycap/samples/sample2.jpg`)입니다.
  - 더스캔: `thescan/index.html`이 이 저장소에 없습니다(`oneclick` 저장소에 있음). 그래서 **배포된 실제 페이지 `https://autooneclick.com/thescan/`**를 열어 캡처했습니다. 문서 사진 3장(`work/scan_docs/doc1~3.jpg`)은 회의록·견적서·안내문 **예시 문서를 직접 그려 만든 것**이라 실명·연락처가 없습니다. 실제 자동 보정 엔진이 이 사진들을 펴서 결과를 냈습니다.
- 모델 클립에는 원래 문구가 화면에 박혀 있습니다(예: "폰에서 한글 파일 안 열리죠?"). 하단 자막 상자가 그 문구를 덮고, 지금 나레이션 문장을 보여 줍니다.
- 앱 장면 왼쪽 아래 원형 창에서는 모델 실사 클립이 계속 재생됩니다.
- 나레이션은 Windows TTS(Microsoft Heami, 속도 +2)입니다. 컷 경계는 각 WAV 길이로 정하고, 탭 시각은 SSML 북마크로 맞췄습니다(지난 숏츠와 같은 방식). 북마크가 문장 끝을 넘어가는 경우에는 끝 0.7초 전으로 당겼습니다.

```
cd src
powershell -ExecutionPolicy Bypass -File capture.ps1 -steps steps_saycap.json  -outDir ..\frames\saycap
powershell -ExecutionPolicy Bypass -File capture.ps1 -steps steps_thescan.json -outDir ..\frames\thescan
powershell -ExecutionPolicy Bypass -File tts.ps1 -rate 2
powershell -ExecutionPolicy Bypass -File build_data.ps1 -short saycap      # thescan도 같은 방식
powershell -ExecutionPolicy Bypass -File preview.ps1 -short saycap -times "1.5,10,22" -outPrefix ..\work\prev\y   # 녹화 없이 장면 확인
powershell -ExecutionPolicy Bypass -File record.ps1 -short saycap -outName short_saycap_v15_9x16
powershell -ExecutionPolicy Bypass -File verify.ps1 -file short_saycap_v15_9x16.mp4 -times "22.5" -outPrefix ..\verify\saycap_390
```

## 한계
- 앱 화면은 상태별 정지 캡처입니다. 이퀄라이저는 실제 앱 화면 3장(자막이 늘어나는 순서)을 차례로 보여 줘서 움직임을 냅니다.
- 사진첩 장면(3,482장)은 '일반 폰 갤러리'를 표현한 연출 화면입니다. 세이캡 화면이 아니고, 썸네일은 세이캡 샘플 사진 4장을 잘라 색을 바꿔 반복했습니다.
- 모델 클립에는 소리가 없습니다. 목소리는 TTS 나레이션 하나뿐입니다.
- 더스캔 캡처는 현재 배포본 기준입니다. 이 배포본은 `찍기` = 파일 입력(capture) 방식입니다. 작업 3의 '확인 없이 바로' 개편은 아직 반영되지 않았습니다.

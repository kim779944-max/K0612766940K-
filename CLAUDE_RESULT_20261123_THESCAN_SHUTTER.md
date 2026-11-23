# 결과 — 2026-11-23 더스캔 하단 셔터 버튼 고정 (147번)
시작 HEAD: oneclick 725ee1a / K0612766940K- 00f5fee
끝   HEAD: oneclick fc16cda / K0612766940K- (이 보고서 커밋 — `git log -1` 참조)
커밋: oneclick `fc16cda` fix(thescan): 실시간 카메라 중 하단 셔터 고정 — 100dvh(vh 폴백) · body.live flex 열 · 프리뷰만 줄고 셔터 flex-shrink:0 · 도우미 자리 64px (147번)

## 1. 저장소·기준
- 두 저장소 pull 결과: 둘 다 `Already up to date` · 충돌 없음
  - oneclick `725ee1a` — 지시서 기준선 `042af4d` 이후 4커밋(144·145·146번) 앞섬. `thescan/index.html` 은 그 사이 변경 없음(마지막 변경 `9878404`). 그래서 지시서 줄번호보다 약 +15줄 밀림(셀렉터로 찾음).
  - K0612766940K- `00f5fee` — 지시서에 적힌 `8de21ac` 는 이 지시서가 올라간 `3a71b8d` 의 앞 커밋. 그 뒤 146번 결과 커밋들이 더 올라와 있었음.
- 되돌리기: `git -C oneclick revert fc16cda` 한 번이면 원상태.
- oneclick 은 `git add thescan/index.html` 만 stage(`-A` 안 씀) · force-push 안 함. 푸시는 `725ee1a..fc16cda` fast-forward.

## 2. 원인과 바꾼 것
- 원인: 셔터 위치 = 고정 px 약 220 + `58vh`(큰 뷰포트). 실제로 보이는 높이는 툴바(56~140)를 뺀 값이라 어긋남. 촬영 중에도 `.gal` 이 뒤에 남아 페이지가 스크롤됨(이 PC 실측 171px. 지시서 값은 178).
- 바꾼 것 (`thescan/index.html` 1파일 · +17/−1줄)
  - CSS: 지시서 §2-1 블록을 셀렉터·값 그대로 `/* 보정 중 */` 앞에 추가함. `#app` 100dvh(+vh 폴백)·padding-bottom `18px+안전영역`, `body.live` overflow 잠금, `body.live #app` flex 열·100dvh·padding-bottom `64px+안전영역`(도우미 자리), `.cap` flex:1, `.capbox.live` flex:1·min-height:120px·height:auto, `.capacts` flex-shrink:0(명시), `.foot-hint` flex 0, `.gal`·`#prog` 숨김. 추가로 `body.live .capbox{transition:none}`(§2-1 지시).
  - JS 2곳: `#btnLive` 의 `await v.play()` 성공 뒤 `$('#capbox').classList.add('live')` 옆에 `document.body.classList.add('live')`(catch 경로에는 넣지 않음). `stopLive()` 첫 줄에 `document.body.classList.remove('live')`.
- 안 바꾼 것: 카메라·보정 파이프라인·자동촬영(steady 2프레임)·`#btnShoot`(여전히 파일 입력을 엶)·PDF·다운로드·시트·갤러리·`KTS_UX_CFG`·ux.js/helper.js·마크업·문구. 버튼 3개는 순서·문구 그대로 둠.

## 3. 실측 (390) — 라이브 `autooneclick.com/thescan/` (fc16cda 반영 후), 헤드리스 Chrome 157.0.8103.79 · DPR 2 · is_mobile · `--use-fake-device-for-media-stream` 으로 실제 `getUserMedia` → `[실시간 카메라]` 클릭
| 뷰포트 | 모드 | top | bottom | h | inside | aboveToolbar128 | noScroll | 프리뷰높이 |
|---|---|---|---|---|---|---|---|---|
| 390×844 | live | 637.2 | 688.2 | 51 | true | true | true (scrollH 844) | 544.7 |
| 390×740 | live | 533.2 | 584.2 | 51 | true | true | true | 440.7 |
| 390×716 | live | 509.2 | 560.2 | 51 | true | true | true | 416.7 |
| 390×640 | live | 433.2 | 484.2 | 51 | true | true | true | 340.7 |
| 390×560 | live | 353.2 | 404.2 | 51 | true | true | true | 260.7 |
| 390×844 | static | 290.5 | 341.5 | 51 | true | true | true | 196 |
| 1280×800 | live | 593.2 | 644.2 | 51 | true | true | true | 500.7 (#app 430 · left 425) |
- topmost 3점: btnShoot/btnShoot/btnShoot (모든 뷰포트, 툴바 128 띠를 덮은 컷 포함)
- 가로 넘침: scrollWidth 390 (1280 에서는 1280. 넘침 0)
- **"전" 값 (같은 방법, 수정 전 라이브)**: 844 live top 584 / bottom 635 / scrollH 1015(스크롤 171px) · 740 live 523.7/574.7 scrollH 955 · 716 live 509.8/560.8 · 640 live 465.7/516.7 **aboveToolbar128 false** · 560 live 419.3/470.3 **aboveToolbar128 false** · 모든 live 에서 noScroll false · 844 static top 290.5. 지시서 §1-3 값과 top 위치는 같다. 다만 셔터 높이가 이 PC에서는 54가 아니라 **51**(전·후 모두. 글꼴 렌더 차이로 보이며 이번 변경과는 무관). 원자료: `output/thescan_shutter_20261123/measure_before.txt`
- 기본 상태 회귀: static top 290.5 → 290.5 (±0)
- 원자료: `measure_after_live.txt`(라이브) · `measure_after_local.txt`(배포 전 로컬 서버, 같은 값)

## 4. 동작 (`functest_live.txt`, 라이브)
- 실시간 카메라 실동작: 됨. 합성 '종이' 스트림을 `getUserMedia` 에 주입하고 3초 뒤 `body.live`+`.capbox.live`, 갤러리 숨김, scrollH 844, 자동 촬영으로 **5장**(7초 13장. 같은 종이가 계속 비치면 계속 찍히는 기존 동작 그대로) · 콘솔 에러 0
- 끄기 후 복귀 확인: `body.live` 제거 · `.gal` block · scrollH 1394 · 스크롤 550 내려감(정상)
- 권한 거부 경로 확인: 토스트 `카메라를 열 수 없습니다 → 찍기 버튼을 써 주세요` · `body.live` 안 붙음 · 셔터 top 290.5(그대로)
- 연결/분리/전체저장 확인: 사진첩 2장 → 연결 긴 이미지 `KTS_연결_2장.jpg` · 연결 PDF `KTS_더스캔_2p.pdf` · 분리 `KTS_한장_scan_01.jpg` · 전체 저장 `KTS_더스캔_scan_01.jpg` 다운로드 발생 · 에러 0. 분리·전체저장은 첫 파일만 받아 확인함.
- 1280×800 확인: #app 430 중앙(left 425) · 촬영 중 셔터 화면 안 · 넘침 0
- 외부 요청: `autooneclick.com` 한 도메인뿐. 새 도메인 0
- 참고: 콘솔에 `404` 1건이 수정 전에도 똑같이 있었음(기존 것. 페이지 요청 목록에는 안 잡혀 favicon 추정, 미확인)
- 실기기(대표님 Chrome/카톡 인앱): **미확인 · 헤드리스 390 실측으로만 검증**

### 한계 (정직하게)
- 헤드리스에는 주소창이 없어 `vh ≠ dvh` 상황 자체는 재현하지 못한다. 대신 (a) 뷰포트 높이를 716/640/560 으로 줄여 dvh 가 줄어든 상황을 재현했고, (b) 844 화면에 128px 띠를 덮어 봤다.
- (b) 띠 컷에서 수정 전 셔터(bottom 635)는 844 기준으로는 띠(716~) 위에 있어서 "가려지는 전 근거"가 844 에서는 나오지 않았다. 수정 전 aboveToolbar128 false 는 640·560 에서 나왔다.
- (b) 수정 후 844+띠 컷에서 `찍기` 는 띠 위에 있지만 그 아래 `사진첩에서 / 실시간 끄기` 줄은 띠에 일부 덮인다. 실제 폰에서는 dvh 가 툴바를 빼고 계산되므로 (a) 716 컷처럼 전부 화면 안에 든다. 실기기로 확인할 항목.

## 5. 캡처
- output/thescan_shutter_20261123/ 11장 (before 3 / after 8)
  - before_390_static · before_390_live · before_390_live_toolbar128
  - after_390_static · after_390_live · after_390_live_toolbar128 · after_390_live_716 · after_390_live_560 · after_1280_live · after_390_live_autocapture
  - 눈 확인: after 전부 `찍기` 잘림 없음. 560 에서도 프리뷰 260px + 셔터·두 버튼·안내 1줄이 모두 보이고 도우미 버튼은 셔터 카드 아래 빈자리에 있음. before_live 는 `내 스캔` 이 아래로 이어져 스크롤이 생김.

## 6. 게이트
- kts_gate: 전 FAIL 0 → 후 FAIL 0 · `gate.txt` (사용한 게이트: `src/gate_thescan.ps1` = `slope_ui_20261123/src/gate_slope.ps1` 복사본에서 대상 파일만 `thescan/index.html` 로 바꿈. exit 0 · 새로 생긴 FAIL 0)
- 지시서 명령과 다른 점: 이 게이트는 `-File` 인자가 없고 `<oneclick 경로> <기준 커밋>` 을 받는다. 처음 `-File` 로 실행했더니 원문 오류 `Join-Path : 'Path' 매개 변수가 빈 문자열이므로 인수를 해당 매개 변수에 바인딩할 수 없습니다.` 가 나서 `gate_thescan.ps1 <oneclick> 725ee1a` 로 실행함.
- 검사 항목은 G1-2 태그 짝 · G1-3 Base64 · G1-5 API키 · G1-6 연락처·주민번호 · G1-8 내부 링크 · G1-9 viewport · 개인경로. 지시서의 G1-1 / G1-4 / G1-7 은 이 게이트에 없음. 대신 파일 존재·시트 닫기(`closeSheet`/✕)는 functest 에서 실제로 돌려 확인함.
- 주의: gate.txt 의 "전" 열 G1-2 가 `FAIL div 20/18…` 로 찍히는데, PS 5.1 이 `git show` 출력을 한글 코드페이지로 읽어 생긴 가짜 FAIL 이다. 원본 파일을 디스크에서 직접 읽어 검사하면 PASS 로 나온다(`gate_before_worktree.txt` 의 "후" 열 = 수정 전 파일 PASS). 실제 전 FAIL 은 0.
- `viewport-fit=cover` 유지됨.

## 7. 라이브
- /thescan/ 'body.live' 뜸 (9건) · '100dvh' 뜸 (2건). 푸시 후 두 번째 확인(약 20초 뒤)에 반영됨.

## 대표님 확인 필요
1) 폰 크롬에서 [실시간 카메라] 켰을 때 찍기 버튼이 바로 보이는지
2) 카카오톡으로 링크 열었을 때도 같은지(사진첩에서/실시간 끄기 줄까지 보이는지 포함)
3) 프리뷰가 너무 작아지지 않는지(작으면 min-height 120 → 150 으로 한 번만 올린다)

남은 것: 실기기(Android Chrome·카카오톡 인앱) 확인 — 대표님 시연 필요

# 결과 — 2026-11-23 경사도 화살표 = 항공사진 위에 작게 (144번)
시작 HEAD: oneclick `042af4d` / K0612766940K- `cca13be`
끝   HEAD: oneclick `cd698b2` / K0612766940K- (이 보고서 커밋)
커밋: oneclick `cd698b2` feat(slope): 화살표 = 항공사진 위에 작게 (144번)

## 1. 저장소·기준
- pull 결과: oneclick `042af4d` → 변화 없음(기대값과 일치) · K0612766940K- `cca13be`(기대 `53de1f2`보다 앞섬 — 그 뒤 SNS·지시서 발행 커밋들이 쌓인 상태, 충돌 없음)
- 바뀐 파일: **`slope/index.html` 1개뿐(+54/−32줄)** · 되돌리기: `git revert cd698b2`
- 바꾼 곳: ① `arrowView()` 신설 + `pxSetView()`·`#togsAdv` 화살표 보조 리스너가 이를 호출 ② `drawSlopeArrows()` 치수·케이싱·`AR_SAMP` 여백·`AR_LAST` 메타 ③ `.arrow-note` 마지막 문장 1개 · `window.__KTS_AR` 1줄(검증용)

## 2. A. 화살표 = 항공사진 (자동 정리)
- 진입로 2곳(`pxSetView` / `#togsAdv` 화살표) 둘 다 `arrowView()` 로 통일: **확인**(두 경로 모두 실측)
- 클릭 직후 층 상태: `{px:0, arrow:1, sat:1, slope:0}`
  - `S` 는 IIFE 내부라 콘솔에서 직접 못 읽음 → `__KTS_PX().on`(=S.lay.px) · `__KTS_AR().n`(화살표 그려짐) · 위성 타일 요청 · 버튼 `.on` 으로 판정
- 버튼 표시: `#togs` 위성 on **true** · `#togsAdv` 화살표 on **true** · 경사색 on **false** · `#opRow` **none** · `#cbw` **block** · `#aleg` **요소 없음**
  - `#cbw`: 지시서 기대는 `none` 이지만, 기존(픽셀 회차) `paintLegend` 덮어쓰기가 "10색 범례 한 벌 — 보기와 무관"으로 **항상 block** 이다. 이 범례가 화살표 10색의 뜻이기도 해 §2-1 "두 곳 다 손대지 않는다"에 따라 그대로 둠. 지도 아래 범례 띠로만 나오고 지도 위 색칠은 없음.
  - `#aleg`: 현재 판에 해당 id 요소가 없음(범례는 `#cbw` 제목 "화살표 = 물이 흐르는 방향"으로 겸함). 변경 안 함.
- 지도 타일(상세 설정 [화살표] 클릭 후 5초): **sat(arcgisonline) 9건 / map(OSM·Vworld Base) 0건** (로컬·라이브 동일)
- 픽셀 상태에서 사용자가 위성 끄고 경사색 켠 뒤 `#pxView [화살표]` → 다시 위성 on·경사색 off 로 정리됨(확인)
- 수동 [위성] off → 일반 지도로 바뀌고 2초 뒤에도 off 유지(되돌아오지 않음) — `output/slope_arrow_20261123/manual_sat_off.png`
- 수동 [경사색] on → 색판이 덮이고 `#opRow` flex, 2초 뒤에도 on 유지 — `manual_slope_on.png`
- 화살표 끌 때 위성 on 그대로(되돌리지 않음) 확인
- 감시 코드(매 프레임 강제 복원) 없음: **확인**(`arrowView()` 는 클릭 시 1회 호출뿐)

## 3. B. 화살표 치수
- 실측 `__KTS_AR()`: headW **4.2** · tailW **1.1** · headLen **[3.5,4.5]** · lenPx **[6.5,7.5]** · casing **[1.6]** · cap 900 · gapMin 16
- 화살표 개수 n: 전 **224** → 후 **224** (gap 16.07 · k1 · m4 동일 — 간격 로직 무변경)
- 같은 지점(밴드1, 6.55°) 표본: 길이 9.79px → **6.66px**, 촉 4.89 → **3.66px** — `arrow_px_before.png` / `arrow_px_after.png`(±12px ×8)
- 케이싱 규칙: 0~2단계 어두운 테 / 3~9단계 밝은 테 — 가평 신하리는 0~5단계만 존재(30° 이상 0%) → **육안 확인은 0~5단계(흰·연노랑·노랑·주황 계열)까지**, 6~9단계는 이 지점에 없어 미확인. 코드상 3~9가 같은 루프라 동일 규칙 적용.
- 표본 `AR_SAMP` 여백 축소(1.6/3.2) 후 표본 28개(전 28개) — 0개 아님
- `.arrow-note` 문장 교체: 확인(라이브 문자열 포함) · `AR_LAST` 갱신: 확인

## 4. 검증 숫자 (390×844, 로컬 + 라이브 동일)
- scrollWidth **390** · `#mapcv` **392** · 최소 버튼높이 **44** · 출력 **48/48** · 상시 버튼 수 **10**(상세 설정 닫힘) · 콘솔 에러 **0** · 새 도메인 **0**(arcgisonline 은 기존 [위성] 타일 도메인 — 137번 검증 때와 같은 목록)
- 회귀: A4 인쇄(화살표 모드) **1쪽** / 이미지 저장 **1600×3022** px
- 참고: 테스트 하네스에서 `#printA4` 클릭 시 `window.print` 호출 카운트가 2로 잡힘(모바일 터치 에뮬레이션 클릭). `printSheet()` 는 무변경이며 137번 검증에서도 JS 클릭 시 2로 기록된 동일 현상.
- 캡처 경로(`output/slope_arrow_20261123/`):
  - before: `before_arrow_390.png`, `before_arrow_zoom.png`
  - after: `after_arrow_390.png`, `after_arrow_zoom.png`, `after_arrow_px.png`
  - manual: `manual_sat_off.png`, `manual_slope_on.png`
  - print: `print_arrow_mode_1.png`(+ `print_arrow_mode.pdf`), 저장 이미지 `save_arrow_mode.png`
  - arrow_px: `arrow_px_before.png`, `arrow_px_after.png`
  - 라이브 재실측 한 벌: `live/` · 수치 원본: `before_result.json`, `after_result.json`, `live/after_result.json`
  - 스크립트: `src/cap.py`(캡처·실측), `src/gate_slope.ps1`(게이트 이식판)

## 5. 게이트
- `output/kts_gate.py` 가 저장소에 없음 → 137번에서 쓴 PowerShell 이식판(`gate_slope.ps1`, 기준 `042af4d`)으로 대체
- kts_gate: 전 FAIL **1항목**(G1-6 연락처 2건) → 후 FAIL **1항목**(G1-6 2건, 동일) · **새로 생긴 FAIL 0** · 출력 `output/slope_arrow_20261123/gate.txt`
  - G1-6 은 137번 보고 때부터 있던 기존 항목(이번 변경과 무관)

## 6. 라이브
- `/slope/` '가늘게 그립니다' **잡힘**(푸시 후 2번째 확인, 약 30초)
- 라이브에서 같은 시나리오 재실측: sat 9 / map 0 · 위성 on · 경사색 off · headW 4.2 · n 224 · 에러 0 · A4 1쪽 · 1600×3022

## 건드리지 않은 것 (확인함)
- 계산(`sampleGrid`·`analyze`·`elevAt`·`bandOf` 등)·`SLOPE10`·Vworld 키·요금·이용권·미리보기 · 137번(조작부·A4 인쇄·이미지 저장) · 지도 392px · 화살표 간격 로직(`gapMin`·`blockPx/k*m`·`cap`)·방향식 · 일반 토글 리스너 · 다른 페이지 0건

## 그대로 둔 기존 사항 (참고)
- 화살표 모드에서도 **등고선(기본 켜짐)** 은 항공사진 위에 남는다 — 지시서 정리 대상(픽셀·경사색)이 아니라 손대지 않음. 더 또렷하게 원하시면 다음 회차에 등고선도 함께 끌지 정해 주세요.
- 위성 상태에서도 지도 우하단 출처 표기가 "© Vworld · DEM" 으로 나온다(기존 동작).

## 대표님 확인 필요
1) 화살표를 켜면 항공사진이 또렷하게 보이는지
2) 화살표가 항공사진을 가리지 않을 만큼 작아졌는지(방향은 여전히 읽히는지)
3) 위성·경사색을 손으로 다시 켜고 끄는 게 그대로 되는지

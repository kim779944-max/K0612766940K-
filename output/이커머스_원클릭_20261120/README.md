# 이커머스 원클릭 5종 (2026-11-20 COMMERCE)

더셀(쿠팡·네이버 스토어·역직구) · 더글(블로그) · 더그램(인스타) — 사장님용 작성·계산·파일 생성 도구.
외부 라이브러리 0 · CDN/웹폰트 0 · AI 열쇠 없이 100% 동작(규칙 엔진) · 외부 요청은 열쇠가 있을 때 `generativelanguage.googleapis.com`만.

| 파일 | 내용 |
|---|---|
| `index.html` | 허브(5개 카드 + 3분 사용법) |
| `coupang.html` | 상품명 3안 · 태그 20 · 상세 HTML/PNG(780px) · 마진표(적자 잠금) · Wing 엑셀/CSV · 오픈 API 본문·HMAC 서명·업로드 스크립트 |
| `naver.html` | SEO 상품명 3안 · 메인3+세부10 · SEO 100점 · 속성10·태그10 · 상세 스토리 7블록 · 엑셀/CSV |
| `global.html` | 미국·일본·쇼피 현지어 문구(템플릿/AI/붙여넣기) · 관세·환율 역산 마진표 · 제도 안내 · 엑셀 3종 |
| `blog.html` | 상위 글 5편 뼈대 추출(6어절 표절 검사) · [완전 자동]/[직접 넣기 (추천)] 투트랙 · 서식 그대로 복사 |
| `insta.html` | 첫 줄 3안 · 본문 · 해시태그 25 · 첫 댓글 · 전체 복사 (발행은 사람이) |
| `assets/` | 공통 틀(app.css·app.js·xlsx.js·ai.js·freekey.js) + `data/*.json`(대표님이 직접 고치는 값) + `bundle.js`(file:// 용 묶음) |
| `src/` | `gate.ps1`(G1 9항목) · `verify.ps1`(완료 판정 66항목) · `cap.ps1`(390 캡처) · `smoke.ps1` · `peek.ps1` · `build_data.ps1` · `upload_coupang.ps1` · `cdp.ps1`·`lib.ps1`·`measure.ps1` |
| `shots/` | 390×844 캡처 · 상세 PNG 예시 · `files/`(검수 때 받은 엑셀 5종) |

## 다시 돌리기 (PowerShell 5.1, Python/Node 불필요)
```powershell
cd output\이커머스_원클릭_20261120
powershell -ExecutionPolicy Bypass -File src\build_data.ps1   # data/*.json 고친 뒤
powershell -ExecutionPolicy Bypass -File src\gate.ps1         # G1 → 측정.txt
powershell -ExecutionPolicy Bypass -File src\verify.ps1       # 완료 판정 → 측정.txt
powershell -ExecutionPolicy Bypass -File src\cap.ps1          # shots\390_*.png
```
검수 전용 주소: `도구.html?sample=1&auto=1` (샘플 자동 입력 + 자동 생성). `&s=0|1|2` 샘플 선택, `&nophoto=1`, `&notop=1`(블로그), `&jpy=16670`(역직구 일본 경계 시험).

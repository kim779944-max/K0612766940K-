# hwp-server — 구형 .hwp → PDF 변환 서버 (사무실 PC 전용)

폰 더뷰(`autooneclick.com/viewer.html`)에서 구형 `.hwp`를 열면 → 이 PC의 한컴오피스가 PDF로 바꿔 돌려주고 → 더뷰가 종이 1:1로 그립니다.
PC가 꺼져 있으면 더뷰는 기존 안내 카드를 그대로 띄웁니다.

| 하는 일 | 방법 |
|---|---|
| 켜기 | `start-hwp-server.ps1` 우클릭 → PowerShell에서 실행 (서버 → /health → 터널 → `oneclick/hwp-host.json` 갱신·push) |
| 끄기 | `stop-hwp-server.ps1` |
| 즉시 차단 | 이 폴더에 `OFF` 라는 빈 파일 만들기 → 모든 요청 503 (지우면 다시 동작) |
| 로그 | `logs\hwp-server.log` — 이름은 해시, 바이트 수·쪽수·소요시간만 |

규칙: `127.0.0.1:8799` 만 바인딩 · `.hwp/.hwpx` 만(확장자+매직바이트) · 20MB · 45초 · 동시 1건(429) · IP당 10초 1건 · CORS `https://autooneclick.com` 만.
`bin\cloudflared.exe`(공식 서명 exe, 관리자 권한 불필요)는 없으면 시작 스크립트가 자동으로 받습니다. `bin/ logs/ run/ OFF` 는 커밋하지 않습니다.

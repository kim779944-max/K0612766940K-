# 더계약서(oneclick/contract)에 '부동산 컨설팅 전속 거래 약정서'(2쪽) 넣기 — ※ 대표님 시연·승인 뒤에만 실행 (관문 6)
# 실행:  powershell -NoProfile -ExecutionPolicy Bypass -File apply.ps1
# 되돌리기: revert.ps1 (또는 연동_노트.md 3단계)
$ErrorActionPreference = 'Stop'
$HERE = $PSScriptRoot
$PKG = (Resolve-Path "$HERE\..").Path
$OC = (Resolve-Path "$HERE\..\..\..\..\oneclick").Path
$C = Join-Path $OC 'contract'
if ((& git -C $OC status --short) -ne $null) { throw "oneclick 에 커밋 안 된 변경이 있습니다. 먼저 정리하세요: git -C `"$OC`" status" }
# 1) 지금 index.html 이 이 수정본을 만들 때의 원본(blob c6e5501)과 같은지 확인 — 다르면 덮어쓰지 않음
$cur = (& git -C $OC hash-object contract/index.html)
if (-not $cur.StartsWith('c6e5501')) { throw "contract/index.html 이 수정본의 바탕(c6e5501)과 다릅니다(지금 $cur). patch/index.diff 를 보고 손으로 반영하세요." }
Copy-Item (Join-Path $HERE 'index.html') (Join-Path $C 'index.html') -Force
# 2) 양식 객체 + 배경 PNG(기본 2장 + 테마 8장)
Copy-Item (Join-Path $PKG 'forms_consult.js') $C -Force
Get-ChildItem $PKG -Filter 'tpl_consult_p*.png' | ForEach-Object { Copy-Item $_.FullName $C -Force }
& git -C $OC status --short
"적용 끝 — contract/index.html 을 열어 [부동산 컨설팅 전속 거래 약정서]를 고르고 4단계 미리보기가 2쪽인지 확인하세요. 괜찮으면 commit·push, 아니면 revert.ps1"

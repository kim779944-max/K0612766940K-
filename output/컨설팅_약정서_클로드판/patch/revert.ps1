# apply.ps1 되돌리기 — 커밋 전이면 이것만으로 원래대로. (커밋·푸시 뒤라면: git -C oneclick revert <그 커밋>)
$ErrorActionPreference = 'Stop'
$OC = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
& git -C $OC checkout -- contract/index.html
Remove-Item (Join-Path $OC 'contract\forms_consult.js') -ErrorAction SilentlyContinue
Get-ChildItem (Join-Path $OC 'contract') -Filter 'tpl_consult_p*.png' | Remove-Item
& git -C $OC status --short
"되돌림 끝 — 위 status 가 비어 있으면 원래 상태입니다."

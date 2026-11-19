#!/bin/sh
# 묶음 마무리: 상세 캡처 복사 → 아이콘 → 설명서 → 쇼룸 등록(전 회차 공용) → 쇼룸 검증
# 사용: sh close_bundle.sh pdf1p,refstyle,...
cd "$(dirname "$0")"
A="$1"; R=../../..
for a in $(echo $A | tr ',' ' '); do cp ../390_$a.png $R/oneclick/shots/${a}_home.png; done
sh addbom.sh >/dev/null
powershell -NoProfile -ExecutionPolicy Bypass -File make_icons.ps1 -apps "$A"
powershell -NoProfile -ExecutionPolicy Bypass -File make_manual.ps1 -apps "$A"
sh assemble.sh; sh ../../register_all.sh $REGISTER_ROUNDS
powershell -NoProfile -ExecutionPolicy Bypass -File verify_showroom.ps1 -apps "$A"

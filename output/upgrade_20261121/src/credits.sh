#!/bin/bash
# credits.sh <tsv> <title> > CREDITS.md
T=$1; echo "# 사진 출처 — $2"; echo; echo "모든 사진은 위키미디어 공용(Wikimedia Commons)에서 내려받아 이 저장소에 넣은 사본입니다(핫링크 없음). 라이선스는 CC0 · 퍼블릭도메인 · CC BY · CC BY-SA 만 썼습니다. 크기 조정·잘라내기·WebP 변환을 했습니다(CC BY-SA 사진의 변경본은 같은 CC BY-SA 조건을 따릅니다)."; echo; echo "확인일: 2026-11-21"; echo; echo "| 파일 | 원본 | 저자 | 라이선스 |"; echo "|---|---|---|---|"
sort -u -t$'\t' -k1,1 "$T" | while IFS=$'\t' read -r f t c lic land sz; do t=${t#File:}; c=${c//|//}; echo "| \`$f\` | [$t]($land) | $c | $lic |"; done

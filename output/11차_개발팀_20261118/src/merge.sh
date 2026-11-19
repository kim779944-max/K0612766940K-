#!/bin/sh
# 추가분 파일을 products_add.js / index_add.html 의 @@MORE@@ 자리에 끼움 (사용: sh merge.sh p3.part.js i3.part.html)
cd "$(dirname "$0")"
awk 'FNR==NR{b=b $0 "\n"; next} /^\/\*@@MORE@@\*\/$/{printf "%s", b; next} {print}' "$1" products_add.js > /tmp/pa.js && mv /tmp/pa.js products_add.js
awk 'FNR==NR{b=b $0 "\n"; next} /^<!--@@MORE@@-->$/{printf "%s", b; next} {print}' "$2" index_add.html > /tmp/ia.html && mv /tmp/ia.html index_add.html
echo "products=$(grep -c "{k:'" products_add.js) tiles=$(grep -c qcard index_add.html)"

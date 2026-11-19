#!/bin/sh
# 쇼룸 등록(멱등, 여러 회차 공용): git HEAD 원본 + 회차별 추가분만 이어 붙임 → 기존 줄 수정·삭제 0, CRLF 유지
# 사용: sh output/register_all.sh 10차_개발팀_20261118 11차_개발팀_20261118 12차_개발팀_20261119
cd "$(dirname "$0")"; R=..
crlf() { awk '{sub(/\r$/,""); printf "%s\r\n", $0}'; }
git -C $R show HEAD:oneclick/products.js | crlf > /tmp/p_head.js
git -C $R show HEAD:oneclick/index.html | crlf > /tmp/i_head.html
cp /tmp/p_head.js /tmp/p_new.js; : > /tmp/i_add.html
for d in "$@"; do
  [ -f "$d/src/products_add.js" ] && grep -v '@@MORE@@' "$d/src/products_add.js" | crlf >> /tmp/p_new.js
  [ -f "$d/src/index_add.html" ] && grep -v '@@MORE@@' "$d/src/index_add.html" | crlf >> /tmp/i_add.html
done
cp /tmp/p_new.js $R/oneclick/products.js
awk 'FNR==NR{a[++n]=$0; next} /<div class="tabs" id="tabs">/ && !done {for(i=1;i<=n;i++) print a[i]; done=1} {print}' /tmp/i_add.html /tmp/i_head.html | crlf > $R/oneclick/index.html
git -C $R diff --numstat -- oneclick/products.js oneclick/index.html

#!/bin/sh
# 쇼룸 등록(멱등): git HEAD 원본 + 추가분만 이어 붙임 → 기존 줄 수정·삭제 0, 작업 폴더 CRLF 유지
#  - oneclick/products.js = HEAD 원본 그대로 + products_add.js
#  - oneclick/index.html  = HEAD 원본에서 '<div class="tabs" id="tabs">' 줄 바로 앞에 index_add.html 끼움
#  (저장소 blob 은 LF, 작업 폴더는 autocrlf=true 로 CRLF → 모든 줄을 CRLF 로 맞춰 씀)
cd "$(dirname "$0")"
R=../../..
crlf() { awk '{sub(/\r$/,""); printf "%s\r\n", $0}'; }
git -C $R show HEAD:oneclick/products.js | crlf > /tmp/p_head.js
git -C $R show HEAD:oneclick/index.html | crlf > /tmp/i_head.html
{ cat /tmp/p_head.js; grep -v '@@MORE@@' products_add.js | crlf; } > $R/oneclick/products.js
grep -v '@@MORE@@' index_add.html | crlf > /tmp/i_add.html
awk 'FNR==NR{a[++n]=$0; next} /<div class="tabs" id="tabs">/ && !done {for(i=1;i<=n;i++) print a[i]; done=1} {print}' /tmp/i_add.html /tmp/i_head.html | crlf > $R/oneclick/index.html
git -C $R diff --numstat -- oneclick/products.js oneclick/index.html

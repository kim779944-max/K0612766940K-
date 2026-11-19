#!/bin/sh
# src/<앱>.src.html + 공통 부품 → oneclick/<앱>.html (단일 파일, 외부 의존 0)
# 사용: sh build.sh [앱이름 ...]  (없으면 전부)
cd "$(dirname "$0")"
OUT=../../../oneclick
LIST="$*"; [ -z "$LIST" ] && LIST=$(ls *.src.html | sed 's/\.src\.html$//')
for app in $LIST; do
  f=$app.src.html
  awk '
    /^\/\*@@CSS@@\*\/$/ {while((getline l < "common.css")>0) print l; close("common.css"); next}
    /^\/\*@@JS@@\*\/$/  {while((getline l < "common.js")>0) print l; close("common.js"); next}
    /^\/\*@@DATA .*@@\*\/$/ {fn=$0; sub(/^\/\*@@DATA /,"",fn); sub(/@@\*\/$/,"",fn); while((getline l < fn)>0) print l; close(fn); next}
    /^<!--@@TOP .*@@-->$/ {nm=$0; sub(/^<!--@@TOP /,"",nm); sub(/@@-->$/,"",nm);
       while((getline l < "top.html")>0){ gsub(/@@NAME@@/,nm,l); print l } close("top.html"); next}
    /^<!--@@TOPEN .*@@-->$/ {nm=$0; sub(/^<!--@@TOPEN /,"",nm); sub(/@@-->$/,"",nm);
       while((getline l < "top_en.html")>0){ gsub(/@@NAME@@/,nm,l); print l } close("top_en.html"); next}
    /^<!--@@BOTTOM@@-->$/ {while((getline l < "bottom.html")>0) print l; close("bottom.html"); next}
    /^<!--@@BOTTOMEN@@-->$/ {while((getline l < "bottom_en.html")>0) print l; close("bottom_en.html"); next}
    {print}' "$f" > "$OUT/$app.html"
  echo "built $app.html $(wc -c < "$OUT/$app.html") bytes"
done

#!/bin/sh
# src/<앱>.src.html + 공통 부품 → oneclick/<앱>.html (단일 파일, 외부 의존 0)
cd "$(dirname "$0")"
OUT=../../../oneclick
for f in *.src.html; do
  app=${f%.src.html}
  awk '
    /^\/\*@@CSS@@\*\/$/ {while((getline l < "common.css")>0) print l; close("common.css"); next}
    /^\/\*@@JS@@\*\/$/  {while((getline l < "common.js")>0) print l; close("common.js"); next}
    /^<!--@@TOP .*@@-->$/ {nm=$0; sub(/^<!--@@TOP /,"",nm); sub(/@@-->$/,"",nm);
       while((getline l < "top.html")>0){ gsub(/@@NAME@@/,nm,l); print l } close("top.html"); next}
    /^<!--@@BOTTOM@@-->$/ {while((getline l < "bottom.html")>0) print l; close("bottom.html"); next}
    {print}' "$f" > "$OUT/$app.html"
  echo "built $app.html $(wc -c < "$OUT/$app.html") bytes"
done

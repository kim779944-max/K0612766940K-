#!/bin/sh
# 앱 소스(src/<앱>.src.html)에 공통 부품을 끼워 oneclick/<앱>.html 단일 파일로 만든다
cd "$(dirname "$0")"
OUT=../../../oneclick
for app in riskcheck expense quote letter; do
  [ -f "$app.src.html" ] || continue
  awk '
    /^\/\*@@CSS@@\*\/$/   {while((getline l < "common.css")>0) print l; close("common.css"); next}
    /^\/\*@@ENGINE@@\*\/$/{while((getline l < "engine.js")>0) print l; close("engine.js"); next}
    /^\/\*@@COMMON@@\*\/$/{while((getline l < "common.js")>0) print l; close("common.js"); next}
    /^<!--@@INQ@@-->$/    {while((getline l < "common_body.html")>0) print l; close("common_body.html"); next}
    /^<!--@@MODAL@@-->$/  {while((getline l < "common_modal.html")>0) print l; close("common_modal.html"); next}
    {print}' "$app.src.html" > "$OUT/$app.html"
  echo "built $app.html $(wc -c < "$OUT/$app.html") bytes"
done

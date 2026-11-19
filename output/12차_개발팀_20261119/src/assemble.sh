#!/bin/sh
# products_add.js / index_add.html = 머리 + 묶음별 p*.part.js / i*.part.html (이름순) + 꼬리
cd "$(dirname "$0")"
T="$(cat title.txt)"
{ printf '\n/* ===== %s (기존 목록은 그대로 두고 뒤에만 붙임) ===== */\nwindow.PRODUCTS.push(\n' "$T"; cat $(ls p*.part.js | sort); printf ');\n'; } > products_add.js
{ printf '  <!-- %s 바로가기 (타일 1줄 = 상품 1개) -->\n  <div class="quick" style="margin-top:9px">\n' "$T"; cat $(ls i*.part.html | sort); printf '  </div>\n'; } > index_add.html
echo "products=$(grep -c "{k:'" products_add.js) tiles=$(grep -c qcard index_add.html)"

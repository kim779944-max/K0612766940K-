#!/bin/sh
# design_review/in/{앱}.html + src/{앱}.css → out/{앱}_design.html (원본의 첫 </head> 바로 앞에 <style> 1개만 끼움)
cd "$(dirname "$0")/.."
for a in "$@"; do
  perl -0777 -pe 'BEGIN{local $/; open F,"<","src/'$a'.css"; $c=<F>; close F} s{</head>}{<style id="kts-design-52">\n$c</style>\n</head>}' in/$a.html > out/${a}_design.html
  echo "out/${a}_design.html $(wc -c < out/${a}_design.html) bytes (in $(wc -c < in/$a.html))"
done

#!/bin/sh
# PowerShell 5.1이 한글을 읽도록 .ps1 에 UTF-8 BOM 붙이기(이미 있으면 그대로)
cd "$(dirname "$0")"
for f in *.ps1; do head -c3 "$f" | od -An -tx1 | grep -q "ef bb bf" || { printf '\357\273\277' | cat - "$f" > "$f.tmp" && mv "$f.tmp" "$f"; echo "bom $f"; }; done

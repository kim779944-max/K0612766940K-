#!/bin/sh
# PowerShell 5.1이 한글 스크립트를 바로 읽도록 UTF-8 BOM을 붙인다(이미 있으면 그대로)
for f in "$@"; do head -c3 "$f" | od -An -tx1 | grep -q "ef bb bf" || { printf '\357\273\277' | cat - "$f" > "$f.tmp" && cat "$f.tmp" > "$f" && rm -f "$f.tmp"; }; done

#!/bin/bash
# pick.sh <rawdir> <key_i> <outfile.webp> <w> <h> <maxKB> <creditsTsv> [cropfilter]
R=$1; KI=$2; OUT=$3; W=$4; H=$5; MAX=$6; CR=$7; PRE=${8:-}
key=${KI%_*}; i=${KI##*_}
line=$(sed -n "${i}p" "$R/$key.tsv")
[ -z "$line" ] && { echo "NO META $KI"; exit 1; }
mkdir -p "$(dirname "$OUT")"
if [[ "$PRE" == FIT* ]]; then P2=${PRE#FIT}; vf="${P2:+$P2,}scale=$W:$H:force_original_aspect_ratio=decrease,pad=$W:$H:-1:-1:0xF2F4F7"; else vf="${PRE:+$PRE,}scale=$W:$H:force_original_aspect_ratio=increase,crop=$W:$H"; fi
for q in 82 75 68 60 52 45 38; do
  ffmpeg -loglevel error -y -i "$R/${KI}.jpg" -vf "$vf" -c:v libwebp -quality $q -compression_level 6 "$OUT"
  sz=$(( $(stat -c %s "$OUT") / 1024 ))
  [ $sz -le $MAX ] && break
done
IFS=$'\t' read -r t c lic land url thumb src <<< "$line"
printf '%s\t%s\t%s\t%s\t%s\t%sKB\n' "$(basename "$OUT")" "$t" "$c" "$lic" "$land" "$sz" >> "$CR"
echo "$(basename "$OUT") ${sz}KB q$q $lic"

#!/bin/bash
# batch.sh listfile outdir  (list: key|query) -> outdir/<key>_<i>.jpg + meta.tsv + sheet_<key>.jpg
L=$1; O=$2; mkdir -p "$O"
while IFS='|' read -r key q; do
  [ -z "$key" ] && continue
  perl "$(dirname "$0")/cs.pl" "$q" 8 > "$O/$key.lst"
  i=0
  while IFS='|' read -r idx title lic art wh thumb desc; do
    case "$lic" in *NC*|*ND*|"?"|*"Fair use"*) continue;; esac
    i=$((i+1)); [ $i -gt 6 ] && break
    curl -s -A "KTS-photo-fetch/1.0" -o "$O/${key}_$i.jpg" "$thumb"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${key}_$i" "$title" "$lic" "$art" "$wh" "$thumb" "$desc" >> "$O/meta.tsv"
  done < "$O/$key.lst"
  n=$(ls "$O/${key}_"*.jpg 2>/dev/null | wc -l)
  [ $n -gt 0 ] && ffmpeg -loglevel error -y $(for f in $(ls "$O/${key}_"*.jpg | sort -V); do echo -i $f; done) -filter_complex "$(for j in $(seq 0 $((n-1))); do printf "[$j]scale=300:225:force_original_aspect_ratio=decrease,pad=300:225:(ow-iw)/2:(oh-ih)/2[s$j];"; done)$(for j in $(seq 0 $((n-1))); do printf "[s$j]"; done)xstack=inputs=$n:layout=$(for j in $(seq 0 $((n-1))); do printf "%d_%d|" $(( (j%3)*300 )) $(( (j/3)*225 )); done | sed 's/|$//'):fill=black" "$O/../sheets/$key.jpg" 2>&1 | head -2
done < "$L"

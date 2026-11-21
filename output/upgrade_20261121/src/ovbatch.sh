#!/bin/bash
# ovbatch.sh list outdir sheetdir
L=$1; O=$2; S=$3; mkdir -p "$O" "$S"; D=$(dirname "$0")
while IFS='|' read -r key q extra; do
  [ -z "$key" ] && continue
  rm -f "$O/${key}"_*.jpg
  perl "$D/${SRCPL:-cm.pl}" "$q" 9 "$extra" > "$O/$key.tsv" || continue
  i=0
  while IFS=$'\t' read -r t c lic land url thumb src; do
    i=$((i+1)); curl -s -L -A "KTS-photo-fetch/1.0 (https://autooneclick.com)" -o "$O/${key}_$i.jpg" "$thumb"; sleep 1.2
  done < "$O/$key.tsv"; sleep 2
  n=$i; [ $n -eq 0 ] && continue
  ins=""; f=""; lay=""
  for j in $(seq 1 $n); do ins="$ins -i $O/${key}_$j.jpg"; k=$((j-1)); f="$f[$k]scale=300:225:force_original_aspect_ratio=increase,crop=300:225,drawtext=fontfile='C\:/Windows/Fonts/arial.ttf':text='$j':x=6:y=4:fontsize=28:fontcolor=yellow:borderw=2[s$k];"; lay="$lay$(( (k%3)*300 ))_$(( (k/3)*225 ))|"; done
  for j in $(seq 0 $((n-1))); do f="$f[s$j]"; done
  ffmpeg -loglevel error -y $ins -filter_complex "${f}xstack=inputs=$n:layout=${lay%|}:fill=black" "$S/$key.jpg"
done < "$L"

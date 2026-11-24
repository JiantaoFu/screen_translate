#!/usr/bin/env bash
# Usage: cyrcheck.sh
# Russian -> English: ML Kit has no Cyrillic recognizer, so each line ML
# Kit finds is read again by the downloaded East Slavic model
# (LineRereader). Restarts the session with that language pair, shows two
# Russian pages and requires English translations of both.
# OCR_MODEL_DIR=<dir with rec.onnx, dict.txt> installs the model directly
# instead of letting the app download it.
# Screenshots: $OUT/cyr_p{0,1}.png
source "$(dirname "$0")/common.sh"
if [ -n "${OCR_MODEL_DIR:-}" ]; then
  for f in rec.onnx dict.txt; do $A push "$OCR_MODEL_DIR/$f" /data/local/tmp/$f >/dev/null 2>&1; done
  $A shell run-as $PKG sh -c "'mkdir -p files/ocr_models/eslav && cp /data/local/tmp/rec.onnx /data/local/tmp/dict.txt files/ocr_models/eslav/'"
fi
SOURCE_LANG=ru TARGET_LANG=en SKIP_INSTALL=1 bash "$(dirname "$0")/start.sh" | tail -1 || exit 1

page() { # page <n> <keywords...>: shows Russian page n; prints "<found>/<wanted> <boxes> <re-read time>"
  local n=$1; shift
  $A logcat -c
  harness static --es lang ru --ei page "$n"
  local L found=0 shown
  for _ in $(seq 1 30); do  # first time includes downloading the model
    sleep 2
    L=$($A logcat -d)
    shown=$(echo "$L" | grep -c 'onStartCommand show: text')
    [ "$shown" -ge 1 ] && break
  done
  sleep 3
  L=$($A logcat -d)
  $A exec-out screencap -p > "$OUT/cyr_p$n.png"
  local text
  # The overlay log cuts the text short; the translation log has all of it.
  text=$(echo "$L" | grep 'Translation: Translated text:' | tr 'A-Z' 'a-z')
  for k in "$@"; do echo "$text" | grep -q "$k" && found=$((found + 1)); done
  echo "$found/$# $(echo "$L" | grep -c 'onStartCommand show: text') $(echo "$L" | grep -o 're-read [0-9]* lines in [0-9]*ms' | tail -1 | tr ' ' '_')"
}

r0=$(page 0 weather market brother camera window house)
r1=$(page 1 train station teacher library dinner recipe)
crashes=$($A logcat -d | grep -c 'FATAL EXCEPTION')
detail="page0 words/boxes: ${r0} page1: ${r1} crashes=$crashes"
ok() { local f=${1%%/*}; [ "$f" -ge 3 ]; }
if ok "$r0" && ok "$r1" && [ "$crashes" -eq 0 ]; then
  echo "PASS cyrillic: $detail"
else
  echo "FAIL cyrillic: $detail"; exit 1
fi

#!/usr/bin/env bash
# Usage: switch.sh <mode> [harness extras...]
# Shows page 0, then page 1 of the same layout (only the text changes, i.e.
# the text under our boxes). The change must be detected under the boxes
# and the new text translated. Screenshots: $OUT/switch_<mode>_p{0,1}.png
source "$(dirname "$0")/common.sh"
mode=$1; shift
harness "$mode" --ei page 0 "$@"
sleep 14
$A exec-out screencap -p > "$OUT/switch_${mode}_p0.png"
$A logcat -c
harness "$mode" --ei page 1 "$@"
sleep 12
$A exec-out screencap -p > "$OUT/switch_${mode}_p1.png"
L=$($A logcat -d)
under=$(echo "$L" | grep -c 'Content change (under our boxes)')
shown=$(echo "$L" | grep -c 'onStartCommand show: text')
crashes=$(echo "$L" | grep -c 'FATAL EXCEPTION')
detail="under-box changes=$under new boxes=$shown crashes=$crashes"
if [ "$under" -lt 1 ] || [ "$shown" -lt 1 ] || [ "$crashes" -gt 0 ]; then
  echo "FAIL switch $mode: $detail"; exit 1
fi
echo "PASS switch $mode: $detail"

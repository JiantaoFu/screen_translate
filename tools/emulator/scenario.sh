#!/usr/bin/env bash
# Usage: scenario.sh <mode> [seconds] [harness extras...]
# Shows a harness screen (video|feed|game|typewriter|static) while live
# translation runs and checks that translated boxes stay on screen for the
# last 6 seconds (they blinked or vanished over video/animation before)
# with no crash. Saves a screenshot to $OUT/scenario_<mode>.png.
source "$(dirname "$0")/common.sh"
mode=$1; secs=${2:-20}; shift; [ $# -gt 0 ] && shift
$A logcat -c
harness "$mode" "$@"
sleep $((secs - 6))
live=""
for i in 1 2 3 4 5 6; do live="$live $(overlay_windows | wc -l | tr -d ' ')"; sleep 1; done
L=$($A logcat -d)
c() { echo "$L" | grep -cE "$1"; }
crashes=$(c 'FATAL EXCEPTION')
$A exec-out screencap -p > "$OUT/scenario_$mode.png"
detail="boxes last 6s:[$live ] translations=$(c 'Translations complete') content_changes=$(c 'Content change') crashes=$crashes"
if [[ " $live " == *" 0 "* ]] || [ "$crashes" -gt 0 ]; then
  echo "FAIL scenario $mode: $detail"; exit 1
fi
echo "PASS scenario $mode: $detail"

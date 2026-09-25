#!/usr/bin/env bash
# Usage: rotcheck.sh [cycles]   (default 4)
# Each cycle another process goes landscape (game harness) and back to
# portrait (static harness). Guards the Android 14+ landscape capture fixes:
# rotation must be detected, no stale-orientation boxes drawn, and boxes
# must land on the text. See rotcheck.py for the exact checks.
source "$(dirname "$0")/common.sh"
cycles=${1:-4}; ok=0; bad=0
check() {
  $A logcat -d > "$OUT/rot_log.txt"
  overlay_windows > "$OUT/rot_win.txt"
  $PY "$ROOT/tools/emulator/rotcheck.py" "$1" "$OUT/rot_log.txt" "$OUT/rot_win.txt" 2>&1 | tail -1
}
for i in $(seq 1 "$cycles"); do
  for side in landscape portrait; do
    $A logcat -c
    if [ $side = landscape ]; then
      harness game --ez landscape true --ei page $((i % 2))
    else
      harness static --ei page $((i % 2))
    fi
    sleep 9
    r=$(check $side)
    echo "  cycle $i $side: $r"
    case "$r" in OK*) ok=$((ok + 1));; *) bad=$((bad + 1));; esac
  done
done
if [ $bad -gt 0 ]; then echo "FAIL rotation: ok=$ok bad=$bad"; exit 1; fi
echo "PASS rotation: $ok/$ok checks"

#!/usr/bin/env bash
# Usage: hidecheck.sh
# "Hide all" (long-press on the floating mode button) on the static screen:
#   1. idle: every box goes, and none come back while the page is unchanged;
#   2. right after a page change, while that pass is still running: the
#      pass is dropped and must not ask for a fresh frame, which redrew the
#      same boxes about a second later;
#   3. the next page change brings boxes back (Hide all isn't sticky).
# Screenshots: $OUT/hide_{idle,inflight,back}.png
source "$(dirname "$0")/common.sh"

# The mode button is the right-hand of the two 126x126 control windows
# (the manual Translate button sits 48dp to its left).
button_center() {
  $A shell dumpsys window windows | grep 'ty=APPLICATION_OVERLAY' | grep '(126x126)' \
    | grep -oE '\(-?[0-9]+,-?[0-9]+\)\(126x126\)' | tr '(),x' '    ' \
    | awk '{ if ($1 > bx) { bx = $1; by = $2 } } END { if (bx != "") print bx + 63, by + 63 }'
}
long_press() { read -r x y <<<"$(button_center)"; $A shell input swipe "$x" "$y" "$x" "$y" 1000; }
boxes() { overlay_windows | wc -l | tr -d ' '; }
watch_boxes() { local s=""; for i in 1 2 3 4 5 6 7 8; do s="$s $(boxes)"; sleep 1; done; echo "$s"; }
fail() { echo "FAIL hide all: $*"; exit 1; }

[ -n "$(button_center)" ] || fail "no floating button (is live translation running?)"
harness static --ei page 0
sleep 14
[ "$(boxes)" -gt 0 ] || fail "no boxes before Hide all"

# 1. Idle.
$A logcat -c
long_press
sleep 2
idle=$(watch_boxes)
$A exec-out screencap -p > "$OUT/hide_idle.png"
$A logcat -d | grep -q 'Hide all requested' || fail "long-press not handled"
[[ "$idle " =~ ^(\ 0)+\ $ ]] || fail "idle: boxes came back [$idle ]"

# 2. During the pass a page change starts.
$A logcat -c
harness static --ei page 1
for i in $(seq 1 40); do
  $A logcat -d | grep -q 'Content change' && break
  sleep 0.25
done
long_press
sleep 3
inflight=$(watch_boxes)
$A exec-out screencap -p > "$OUT/hide_inflight.png"
L=$($A logcat -d)
dropped=$(echo "$L" | grep -c 'Cancelled during capture/OCR, dropping frame')
[[ "$inflight " =~ ^(\ 0)+\ $ ]] || fail "in flight: boxes came back [$inflight ] dropped=$dropped"

# 3. A new page brings boxes back.
harness static --ei page 0
sleep 12
back=$(boxes)
$A exec-out screencap -p > "$OUT/hide_back.png"
crashes=$($A logcat -d | grep -c 'FATAL EXCEPTION')
detail="idle:[$idle ] in-flight:[$inflight ] dropped_passes=$dropped boxes_after_page_change=$back crashes=$crashes"
if [ "$back" -lt 1 ] || [ "$crashes" -gt 0 ]; then fail "$detail"; fi
echo "PASS hide all: $detail"

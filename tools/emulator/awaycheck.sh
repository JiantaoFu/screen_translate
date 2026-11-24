#!/usr/bin/env bash
# Usage: awaycheck.sh   (run after start.sh with CAPTURE=app)
# Sharing one app, the user leaves it (home screen) and comes back:
#   1. away: the shared app is not on screen, so no box may stay drawn over
#      whatever is there instead, and the capture loop must keep running
#      without crashing (it gets no frames while the app is hidden);
#   2. back: the boxes return on their own, without restarting the session.
# Screenshots: $OUT/away_{gone,back}.png
source "$(dirname "$0")/common.sh"
boxes() { overlay_windows | wc -l | tr -d ' '; }
watch_boxes() { local s=""; for _ in $(seq 1 "$1"); do s="$s $(boxes)"; sleep 1; done; echo "$s"; }
fail() { echo "FAIL away and back: $*"; exit 1; }

[ "$CAPTURE" = app ] || fail "needs CAPTURE=app (sharing one app)"
harness static --ei page 0
sleep 12
[ "$(boxes)" -gt 0 ] || fail "no boxes on the shared app before leaving it"

$A logcat -c
$A shell input keyevent KEYCODE_HOME
sleep 2
away=$(watch_boxes 6)
$A exec-out screencap -p > "$OUT/away_gone.png"
[[ "$away " =~ ^(\ 0)+\ $ ]] || fail "boxes left over the home screen [$away ]"

harness static --ei page 0
sleep 2
back=$(watch_boxes 10)
$A exec-out screencap -p > "$OUT/away_back.png"
crashes=$($A logcat -d | grep -c 'FATAL EXCEPTION')
detail="away:[$away ] back:[$back ] crashes=$crashes"
[ "$crashes" -eq 0 ] || fail "$detail"
# The last few samples must all have boxes: they came back and stayed.
[[ "$back " =~ (\ [1-9][0-9]*){3}\ $ ]] || fail "boxes did not come back: $detail"
echo "PASS away and back: $detail"

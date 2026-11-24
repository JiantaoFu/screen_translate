#!/usr/bin/env bash
# Full emulator regression for live translation. Run it after changing the
# capture/overlay pipeline (ScreenCaptureService, FrameStabilizer,
# MotionClassifier, OverlayService, OverlayRegions, TranslationProvider's
# box logic) and before every release. Takes ~17 minutes.
#
# Two passes: sharing the entire screen, then sharing one app (Android
# 14+'s default, so what most users run). The one-app pass shares the
# harness from the other flavor's debug install, so build both:
#
#   python tools/build.py emulator && python tools/build.py emulator --flavor lite
#   tools/emulator/run_all.sh
#   SKIP_INSTALL=1 tools/emulator/run_all.sh
#
# Prerequisites and how to build the APK: tools/emulator/README.md
source "$(dirname "$0")/common.sh"
D="$(dirname "$0")"
failed=()
run() { # run <name> <script> [args...]
  local name=$1; shift
  bash "$D/$@" 2>&1 | tee -a "$LOG" | grep -E '^(PASS|FAIL|INFO)|^  '
  [ "${PIPESTATUS[0]}" -eq 0 ] || failed+=("$name")
}
LOG="$OUT/run_all.log"; ALL_OUT=$OUT
: > "$LOG"
$A get-state >/dev/null 2>&1 || { echo "FAIL: no device $SERIAL (start the emulator first)"; exit 1; }

check_pid() { # check_pid <pass>
  if [ "$(app_pid)" != "$pid" ]; then failed+=("$1: app restarted (pid $pid -> $(app_pid)): crash?"); fi
}

echo "Sharing the entire screen:"
export CAPTURE=screen
run start start.sh || true
[ ${#failed[@]} -eq 0 ] || { echo "Could not start live translation; stopping."; exit 1; }
pid=$(cat "$OUT/pid")
for mode in static feed video game typewriter; do run "scenario $mode" scenario.sh $mode 20; done
for mode in static game video; do run "switch $mode" switch.sh $mode; done
run typewriter typecheck.sh 2
run rotation rotcheck.sh 4
run "hide all" hidecheck.sh
run fdprobe fdprobe.sh video
check_pid "entire screen"
# Restarts the session with Russian -> English, so after the pid check.
run cyrillic cyrcheck.sh

echo
echo "Sharing one app:"
export CAPTURE=app
export OUT="$ALL_OUT/one-app"   # its screenshots, beside the first pass's
mkdir -p "$OUT"
$A shell am force-stop $PKG
before=${#failed[@]}
run "one app: start" start.sh || true
if [ ${#failed[@]} -eq "$before" ]; then
  pid=$(cat "$OUT/pid")
  for mode in static feed video game; do run "one app: scenario $mode" scenario.sh $mode 20; done
  for mode in static game video; do run "one app: switch $mode" switch.sh $mode; done
  run "one app: typewriter" typecheck.sh 2
  run "one app: rotation" rotcheck.sh 2
  run "one app: away and back" awaycheck.sh
  check_pid "one app"
fi
echo
echo "Screenshots and logs: $ALL_OUT (one-app pass: $ALL_OUT/one-app)"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'REGRESSION FAILED: %s\n' "${failed[@]}"; exit 1
fi
echo "ALL EMULATOR CHECKS PASSED"

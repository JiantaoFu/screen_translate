#!/usr/bin/env bash
# Full emulator regression for live translation. Run it after changing the
# capture/overlay pipeline (ScreenCaptureService, FrameStabilizer,
# MotionClassifier, OverlayService, OverlayRegions, TranslationProvider's
# box logic) and before every release. Takes ~10 minutes.
#
#   tools/emulator/run_all.sh            # install build/…/app-x86_64-debug.apk, then run
#   SKIP_INSTALL=1 tools/emulator/run_all.sh
#
# Prerequisites and how to build the APK: tools/emulator/README.md
source "$(dirname "$0")/common.sh"
D="$(dirname "$0")"
failed=()
run() { # run <name> <script> [args...]
  local name=$1; shift
  bash "$D/$@" 2>&1 | tee -a "$OUT/run_all.log" | grep -E '^(PASS|FAIL|INFO)|^  '
  [ "${PIPESTATUS[0]}" -eq 0 ] || failed+=("$name")
}
: > "$OUT/run_all.log"
$A get-state >/dev/null 2>&1 || { echo "FAIL: no device $SERIAL (start the emulator first)"; exit 1; }

run start start.sh || true
[ ${#failed[@]} -eq 0 ] || { echo "Could not start live translation; stopping."; exit 1; }
pid=$(cat "$OUT/pid")
for mode in static feed video game typewriter; do run "scenario $mode" scenario.sh $mode 20; done
for mode in static game video; do run "switch $mode" switch.sh $mode; done
run typewriter typecheck.sh 2
run rotation rotcheck.sh 4
run fdprobe fdprobe.sh video

if [ "$(app_pid)" != "$pid" ]; then failed+=("app restarted (pid $pid -> $(app_pid)): crash?"); fi
echo
echo "Screenshots and logs: $OUT"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'REGRESSION FAILED: %s\n' "${failed[@]}"; exit 1
fi
echo "ALL EMULATOR CHECKS PASSED"

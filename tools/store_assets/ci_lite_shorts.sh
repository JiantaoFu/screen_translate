#!/usr/bin/env bash
# CI driver for the Lite short-video recordings (.github/workflows/lite-shorts.yml).
# Same emulator setup as ci_lite_screenshots.sh; each content scene from
# capture.sh is run while `adb shell screenrecord` records the whole screen
# (app launch, the Translate Screen tap, the artwork before and after).
# Output in $OUT_DIR: rec/<scene>.mp4 (1080x2400), raw/en-US/<scene>.png,
# capture-<scene>.txt (timestamps of each step), logcat.
set -uo pipefail
export PKG=com.lomoware.screen_translate.lite
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR=${OUT_DIR:-$ROOT/build/lite-shorts}
mkdir -p "$OUT_DIR/rec"
SERIAL=${ANDROID_SERIAL:-emulator-5554}
A="adb -s $SERIAL"
APK="$ROOT/build/app/outputs/apk/lite/debug/app-lite-debug.apk"

$A wait-for-device
$A shell wm size 1080x2400
$A shell wm density 420
sleep 5
$A shell settings put global window_animation_scale 0
$A shell settings put global transition_animation_scale 0
$A shell settings put global animator_duration_scale 0
$A install -r "$APK" | tail -1
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 20
$A shell am force-stop $PKG
bash "$ROOT/tools/emulator/push_ai_pack.sh" opus-mt-ja-en
bash "$ROOT/tools/emulator/push_ai_pack.sh" opus-mt-ko-en fp16
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow

reset_quota() { $A shell am force-stop $PKG; python3 "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" lite_quota_day=1970-01-01 >/dev/null; }
for s in ${SCENES:-webtoon manga game}; do
  reset_quota
  $A shell rm -f /sdcard/rec.mp4
  # 4 Mbps keeps the swiftshader emulator responsive; 170 s < the 180 s cap.
  $A shell screenrecord --bit-rate 4000000 --time-limit 170 /sdcard/rec.mp4 &
  rec=$!
  sleep 1
  t0=$(date +%s)
  bash "$ROOT/tools/store_assets/capture.sh" en-US $s 2>&1 |
    while IFS= read -r l; do echo "[+$(( $(date +%s) - t0 ))s] $l"; done | tee "$OUT_DIR/capture-$s.txt"
  sleep 4   # hold the translated frame a bit (capture.sh force-stops at the end)
  $A shell pkill -INT screenrecord || true
  wait $rec; sleep 3
  $A pull /sdcard/rec.mp4 "$OUT_DIR/rec/$s.mp4"
done
cp -r "$ROOT/tools/store_assets/raw" "$OUT_DIR/" 2>/dev/null
$A logcat -d > "$OUT_DIR/logcat-final.txt"
ls -l "$OUT_DIR/rec"
exit 0

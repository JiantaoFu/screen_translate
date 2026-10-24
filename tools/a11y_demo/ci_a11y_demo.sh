#!/usr/bin/env bash
# CI driver for the Lite accessibility-disclosure demo video
# (.github/workflows/lite-a11y-demo.yml). Runs inside
# reactivecircus/android-emulator-runner with the lite debug APK built.
# Records (adb screenrecord) on a fresh install:
#   app opens -> Translate Screen -> screen-capture consent -> the
#   Accessibility disclosure dialog -> "Agree" -> Android Accessibility
#   settings -> the service is turned on -> back to the app -> a Japanese
#   page in another app is translated -> scrolling it re-translates.
# Everything goes to $OUT_DIR: a11y_demo.mp4, step screenshots, steps.txt
# (what happened at each step), logcat.
set -uo pipefail
export PKG=com.lomoware.screen_translate.lite
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR=${OUT_DIR:-$ROOT/build/a11y-demo}
mkdir -p "$OUT_DIR/steps"
SERIAL=${ANDROID_SERIAL:-emulator-5554}
A="adb -s $SERIAL"
UI="python3 $ROOT/tools/a11y_demo/ui.py $SERIAL"
APK="$ROOT/build/app/outputs/apk/lite/debug/app-lite-debug.apk"
LOG="$OUT_DIR/steps.txt"; : > "$LOG"
step() { echo "[$(date +%T)] $*" | tee -a "$LOG"; }
shot() { $A exec-out screencap -p > "$OUT_DIR/steps/$1.png"; }
# Phone AVD taps (same as tools/store_assets/capture.sh).
T_SCREEN="540 1508"; T_MODE="540 1128"; T_ENTIRE="360 1318"; T_START="894 1610"

$A wait-for-device
$A shell wm size 1080x2400; $A shell wm density 420; sleep 5
for s in window_animation_scale transition_animation_scale animator_duration_scale; do
  $A shell settings put global $s 0; done
$A shell settings put secure immersive_mode_confirmations confirmed
$A install -r "$APK" | tail -1
# Service off, as on a fresh phone.
$A shell settings delete secure enabled_accessibility_services
$A shell settings put secure accessibility_enabled 0
# First launch creates prefs/files dir, then the ja-en AI pack and prefs.
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 20
$A shell am force-stop $PKG
bash "$ROOT/tools/emulator/push_ai_pack.sh" opus-mt-ja-en
$A shell am force-stop $PKG
python3 "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=ja targetLanguage=en translationMode=onnx >/dev/null
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
$A shell cmd locale set-app-locales $PKG --locales en-US
# The Japanese page used for the scroll part.
(cd "$ROOT/tools/a11y_demo" && python3 -m http.server 8765 >/dev/null 2>&1 &)
$A reverse tcp:8765 tcp:8765
URL=http://localhost:8765/demo.html
$A shell 'echo "_ --disable-fre --no-default-browser-check --no-first-run" > /data/local/tmp/chrome-command-line'
$A shell am set-debug-app --persistent com.android.chrome
# The setup launch above already showed (and marked as shown) the
# disclosure dialog; forget that so it appears again on camera.
$A shell run-as $PKG rm -f shared_prefs/AccessibilityPrefs.xml
$A shell pm list packages | tr -d '\r' | sed 's/package://' | grep -E 'chrome|htmlviewer|webview|photos' | tee -a "$LOG"

# --- recording: back-to-back 170 s segments until /sdcard/rec_stop exists
$A shell rm -f /sdcard/rec_stop /sdcard/a11y_*.mp4
$A shell 'i=0; while [ ! -f /sdcard/rec_stop ]; do i=$((i+1)); screenrecord --bit-rate 6000000 --time-limit 170 /sdcard/a11y_$i.mp4; done' &
REC=$!
sleep 2
$A logcat -c

step "1. open the app (the disclosure dialog appears on first launch)"
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 3; shot 01_open

step "3. disclosure dialog"
if $UI find 'Accessibility Service \(Optional\)' --timeout 25 | tee -a "$LOG"; then
  sleep 8; shot 03_dialog            # hold so the text is readable
  step "4. tap Agree"
  $UI tap '^Agree$' --timeout 5 | tee -a "$LOG"; sleep 4
else
  step "FAILED: dialog not shown"; shot 03_no_dialog
  $A shell am start -a android.settings.ACCESSIBILITY_SETTINGS >/dev/null; sleep 4
fi
shot 04_settings

step "5. find and turn on the service in Accessibility settings"
found=""
for _ in 1 2 3 4 5; do
  if $UI tap 'Scroll Detection' --timeout 3 | tee -a "$LOG"; then found=yes; break; fi
  $A shell input swipe 540 1900 540 900 400; sleep 1
done
if [ -n "$found" ]; then
  sleep 3; shot 05_service_page
  $UI tap '^Use .*Scroll Detection' --timeout 6 | tee -a "$LOG" || $UI tap 'Scroll Detection' --timeout 3 | tee -a "$LOG"
  sleep 2; shot 05_allow_prompt
  $UI tap '^Allow$' --timeout 6 | tee -a "$LOG" || step "no Allow prompt"
  sleep 3; shot 05_enabled
else
  step "FAILED: service not found in settings; enabling via settings put"
fi
enabled=$($A shell settings get secure enabled_accessibility_services | tr -d '\r')
step "enabled_accessibility_services=$enabled"
if ! echo "$enabled" | grep -q ScrollDetection; then
  step "FALLBACK: enabling via settings put (not shown on screen)"
  $A shell settings put secure enabled_accessibility_services $PKG/com.lomoware.screen_translate.ScrollDetectionAccessibilityService
  $A shell settings put secure accessibility_enabled 1
fi

step "6. back to the app"
$A shell input keyevent BACK; sleep 1; $A shell input keyevent BACK; sleep 1
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 5; shot 06_back_in_app

step "6b. Translate Screen + screen-capture consent"
$A shell input tap $T_SCREEN; sleep 3
$A shell input tap $T_MODE; sleep 1.5
$A shell input tap $T_ENTIRE; sleep 1.5
$A shell input tap $T_START; sleep 4; shot 06_translating

step "7. Japanese page in another app"
$A logcat -c
opened=""
$A shell am start -a android.intent.action.VIEW -d $URL -n com.android.chrome/com.google.android.apps.chrome.Main >/dev/null 2>&1
sleep 8
top=$($A shell dumpsys activity activities | grep -m1 topResumedActivity | tr -d '\r')
step "viewer: $top"
echo "$top" | grep -q 'chrome.*Main\|ChromeTabbedActivity' && opened=yes
[ -n "$opened" ] || step "FAILED: no viewer opened the page"
# Chrome first-run screens, if any.
$UI tap '^(Accept & continue|Use without an account|No thanks|Got it)$' --timeout 3 >/dev/null && sleep 3
$UI tap '^(No thanks|Got it)$' --timeout 3 >/dev/null && sleep 3
wait_done() { for _ in $(seq 1 30); do sleep 2
  [ "$($A logcat -d -s flutter:I | grep -c 'Translations complete')" -gt "$1" ] && return 0; done; return 1; }
wait_done 0 && step "first translation complete" || step "WARNING: no 'Translations complete' within 60 s"
sleep 4; shot 07_translated

step "8. scroll -> re-translation"
for i in 1 2; do
  before=$($A logcat -d -s flutter:I | grep -c 'Translations complete')
  $A shell input swipe 540 1900 540 800 700
  sleep 1
  if wait_done "$before"; then step "scroll $i: re-translated"; else step "WARNING scroll $i: no new translation"; fi
  sleep 4; shot 08_scroll_$i
done
$A logcat -d | grep -E 'Scroll event received|Significant Scroll|Foreground window changed' | tail -20 | tee -a "$LOG"

# --- stop recording and fetch
$A shell touch /sdcard/rec_stop
$A shell pkill -INT screenrecord; sleep 3; kill $REC 2>/dev/null; wait $REC 2>/dev/null
for f in $($A shell ls /sdcard/ | tr -d '\r' | grep -E '^a11y_[0-9]+\.mp4$' | sort -V); do
  $A pull /sdcard/$f "$OUT_DIR/$f" >/dev/null; echo "file '$OUT_DIR/$f'" >> "$OUT_DIR/list.txt"; done
if [ -s "$OUT_DIR/list.txt" ]; then
  ffmpeg -loglevel error -y -f concat -safe 0 -i "$OUT_DIR/list.txt" -c copy "$OUT_DIR/a11y_demo.mp4" ||
    cp "$(ls "$OUT_DIR"/a11y_1.mp4)" "$OUT_DIR/a11y_demo.mp4"
fi
ls -l "$OUT_DIR"
$A logcat -d > "$OUT_DIR/logcat.txt"
exit 0

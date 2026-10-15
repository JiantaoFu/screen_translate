#!/usr/bin/env bash
# Usage: [MODE=onnx|onDevice] [TARGET=en] check_lines.sh <source-lang> <runs> <image.png> [<image.png> ...]
# Shows each image full-screen in Google Photos on the emulator with live
# translation (<source-lang> → en, AI mode unless MODE=onDevice for Quick) running, <runs> times, and prints
# what OCR read and what came back. Keep only lines that are right every run.
# Needs the debug app and the AI pack installed (tools/emulator/push_ai_pack.sh).
source "$(dirname "$0")/../emulator/common.sh"
LANG_SRC=$1; RUNS=$2; shift 2
PH=com.google.android.apps.photos

image_id() {
  $A shell content query --uri content://media/external/images/media --projection _id \
    --where "_display_name=\'$1\'" | grep -oE "_id=[0-9]+" | tail -1 | cut -d= -f2
}
for f in "$@"; do
  n=$(basename "$f")
  $A push "$f" /sdcard/Pictures/$n >/dev/null
  $A shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/$n >/dev/null
done
sleep 2

$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
$A shell settings put secure enabled_accessibility_services $PKG/.ScrollDetectionAccessibilityService
$A shell settings put secure accessibility_enabled 1
$A shell am force-stop $PKG
$PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=$LANG_SRC targetLanguage=${TARGET:-en} translationMode=${MODE:-onnx} >/dev/null
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12
$A shell input tap 540 1508; sleep 3    # Translate Screen
$A shell input tap 540 1128; sleep 1.5  # capture-mode dropdown
$A shell input tap 360 1318; sleep 1.5  # "Share entire screen"
$A shell input tap 894 1610; sleep 4    # Share screen

for r in $(seq 1 "$RUNS"); do
  for f in "$@"; do
    n=$(basename "$f")
    $A logcat -c
    $A shell am force-stop $PH
    $A shell am start -a android.intent.action.VIEW -d content://media/external/images/media/$(image_id $n) \
      -t image/png -p $PH >/dev/null 2>&1
    sleep 2.5; $A shell input tap 540 1700; sleep ${WAIT:-14}   # hide Photos' toolbars, let translation settle
    echo "== run $r: $n"
    $A logcat -d -s flutter:I | grep -E "\[ONNX\] (Translating|Done)|Translation: (Original|Translated) text" | grep -v Step |
      sed 's/.*\[ONNX\] //; s/.*Translation: //'
  done
done
$A shell am force-stop $PH
$A shell am force-stop $PKG

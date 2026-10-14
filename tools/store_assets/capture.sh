#!/usr/bin/env bash
# Usage: capture.sh <locale> [scene ...]      e.g. capture.sh en-US manga webtoon game
# Captures raw 1080x2400 screenshots of the real app translating the store
# artwork on the emulator, into tools/store_assets/raw/<locale>/<scene>.png.
# compose.py turns them into the store screenshots.
#
# Each scene: set the language pair and mode, start live translation, show
# the image full-screen in Google Photos, wait for "Translations complete",
# let it settle, screencap. Check the result: OCR is not deterministic, and
# check_lines.sh is how lines were chosen.
# Needs: the debug app, AI packs (tools/emulator/push_ai_pack.sh), and the
# assets from make_assets.py.
source "$(dirname "$0")/../emulator/common.sh"
HERE="$ROOT/tools/store_assets"
LOCALE=${1:-en-US}; shift
SCENES=${*:-manga webtoon game}
OUTDIR="$HERE/raw/$LOCALE"
mkdir -p "$OUTDIR"
PH=com.google.android.apps.photos

# scene → image, source language, target language, mode (per locale target).
target() { case $LOCALE in zh-CN) echo zh;; ja-JP) echo ja;; *) echo en;; esac; }
mode() { [ "$(target)" = en ] && echo onnx || echo onDevice; }   # AI packs translate into English only
scene_image() { case $1 in manga) echo manga.png;; webtoon) echo webtoon_screen.png;; game) echo tavern.png;; esac; }
scene_lang() { case $1 in webtoon) echo ko;; *) echo ja;; esac; }

image_id() {
  $A shell content query --uri content://media/external/images/media --projection _id \
    --where "_display_name=\'$1\'" | grep -oE "_id=[0-9]+" | tail -1 | cut -d= -f2
}

# Clean status bar (only visible on app screens; Photos hides it full-screen).
$A shell settings put global sysui_demo_allowed 1
$A shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
for c in "clock -e hhmm 1000" "battery -e level 100 -e plugged false" \
         "network -e wifi show -e level 4 -e mobile show -e datatype none -e level 4" \
         "notifications -e visible false"; do
  $A shell am broadcast -a com.android.systemui.demo -e command $c >/dev/null
done
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
$A shell settings put secure enabled_accessibility_services $PKG/.ScrollDetectionAccessibilityService
$A shell settings put secure accessibility_enabled 1

for scene in $SCENES; do
  img=$(scene_image $scene); src=$(scene_lang $scene)
  [ -n "$img" ] || { echo "unknown scene $scene"; continue; }
  $A push "$HERE/assets/$img" /sdcard/Pictures/$img >/dev/null
  $A shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/$img >/dev/null
  sleep 2

  $A shell am force-stop $PH
  $A shell am force-stop $PKG
  $PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=$src targetLanguage=$(target) \
    translationMode=$(mode) >/dev/null
  $A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12
  $A shell input tap 540 1508; sleep 3    # Translate Screen
  $A shell input tap 540 1128; sleep 1.5  # capture-mode dropdown
  $A shell input tap 360 1318; sleep 1.5  # "Share entire screen"
  $A shell input tap 894 1610; sleep 4    # Share screen

  $A logcat -c
  $A shell am force-stop $PH   # otherwise Photos can keep showing the previous image
  sleep 1
  $A shell am start -a android.intent.action.VIEW -d content://media/external/images/media/$(image_id $img) \
    -t image/png -p $PH >/dev/null 2>&1
  sleep 2.5; $A shell input tap 540 1700   # hide Photos' toolbars
  done_at=""
  for _ in $(seq 1 30); do
    sleep 2
    if $A logcat -d -s flutter:I | grep -q "Translations complete"; then done_at=yes; break; fi
  done
  [ -n "$done_at" ] || echo "WARNING $scene: no 'Translations complete' within 60 s"
  sleep 4   # later cycles may still refine boxes
  $A exec-out screencap -p > "$OUTDIR/$scene.png"
  echo "$scene: $OUTDIR/$scene.png"
  $A logcat -d -s flutter:I | grep -E "\[ONNX\] Done|Translated text" | sed 's/.*\] //; s/.*Translation: //' | sort -u | sed 's/^/  /'
done

$A shell am force-stop $PH
$A shell am force-stop $PKG
$A shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null

#!/usr/bin/env bash
# Records the demo clips on the emulator: real app, AI mode, JA→EN.
#   portrait_manga.mp4  - start translation in the app, then manga 1 and 2 in Google Photos
#   landscape_game.mp4  - game dialogue in landscape
# Output: build/demo_video/recordings/. Check them with contact_sheet.py,
# update the cut points in edit.py, then copy them into
# tools/demo_video/recordings/ (that is what edit.py reads).
#
# Needs: the AVD from tools/emulator/README.md with hw.ramSize=4096 (at 2 GB
# the low-memory killer kills the app in AI mode once screenrecord runs),
# and the debug APK installed (python tools/build.py emulator --install emulator-5554).
# Taps are for the 1080x2400 Medium_Phone AVD.
source "$(dirname "$0")/../emulator/common.sh"
HERE="$ROOT/tools/demo_video"
REC_OUT="$ROOT/build/demo_video/recordings"
MODEL_DIR="$ROOT/build/demo_video/opus-mt-ja-en"
PHOTOS=com.google.android.apps.photos
mkdir -p "$REC_OUT"

ram_kb=$($A shell grep MemTotal /proc/meminfo | tr -s ' ' | cut -d' ' -f2)
if [ "${ram_kb:-0}" -lt 3500000 ]; then
  echo "Emulator has $((ram_kb / 1024)) MB RAM; set hw.ramSize=4096 in the AVD's config.ini and cold-boot it."; exit 1
fi

# Current orientation of the default display, from its size ("cur=1080x2400").
# (The first mDisplayRotation in `dumpsys window` can be another window's stale config.)
orientation() {
  $A shell dumpsys window displays | grep -m1 -oE "cur=[0-9]+x[0-9]+" |
    awk -Fx '{ sub("cur=", "", $1); print ($1 < $2) ? "portrait" : "landscape" }'
}

# Rotate the virtual sensor until the display matches. Locking with
# user_rotation didn't hold on this AVD, so auto-rotate stays on. Rotate
# while our app is in front: the launcher is portrait-only.
rotate_to() { # rotate_to portrait|landscape
  $A shell settings put system accelerometer_rotation 1
  sleep 2
  for _ in 1 2 3 4 5; do
    [ "$(orientation)" = "$1" ] && return 0
    $A emu rotate >/dev/null; sleep 3
  done
  echo "could not rotate to $1"; exit 1
}
portrait() { rotate_to portrait; }
landscape() { rotate_to landscape; }

# 1. AI language pack. The in-app download times out on the emulator's slow
#    network (see the open issue in README), so fetch it on the host and push
#    it into the app's files dir.
if ! $A shell run-as $PKG ls files/onnx_models/opus-mt-ja-en/vocab.json >/dev/null 2>&1; then
  mkdir -p "$MODEL_DIR"
  base=https://huggingface.co/onnx-community/opus-mt-ja-en/resolve/main
  for pair in "onnx/encoder_model_quantized.onnx encoder_model.onnx" \
              "onnx/decoder_model_quantized.onnx decoder_model.onnx" \
              "onnx/decoder_with_past_model_quantized.onnx decoder_with_past_model.onnx" \
              "source.spm source.spm" "vocab.json vocab.json"; do
    set -- $pair
    [ -f "$MODEL_DIR/$2" ] || curl -sSLf -o "$MODEL_DIR/$2" "$base/$1" || { echo "download failed: $1"; exit 1; }
  done
  $A shell am force-stop $PKG
  $A shell run-as $PKG mkdir -p files/onnx_models/opus-mt-ja-en
  for f in encoder_model.onnx decoder_model.onnx decoder_with_past_model.onnx source.spm vocab.json; do
    $A push "$MODEL_DIR/$f" /data/local/tmp/$f >/dev/null &&
      $A shell "run-as $PKG sh -c 'cat /data/local/tmp/$f > files/onnx_models/opus-mt-ja-en/$f'" &&
      $A shell rm /data/local/tmp/$f || { echo "push failed: $f (emulator /data full?)"; exit 1; }
  done
  echo "AI pack opus-mt-ja-en installed"
fi

# 2. Demo images in the gallery; look up their MediaStore ids.
image_id() {
  $A shell content query --uri content://media/external/images/media --projection _id \
    --where "_display_name=\'$1\'" | grep -oE "_id=[0-9]+" | tail -1 | cut -d= -f2
}
for f in manga-1-jp manga-2-jp game-dialogue-jp; do
  if [ -z "$(image_id $f.png)" ]; then
    $A push "$HERE/assets/$f.png" /sdcard/Pictures/$f.png >/dev/null
    $A shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/$f.png >/dev/null
  fi
done
sleep 2
M1=$(image_id manga-1-jp.png); M2=$(image_id manga-2-jp.png); GAME=$(image_id game-dialogue-jp.png)
[ -n "$M1" ] && [ -n "$M2" ] && [ -n "$GAME" ] || { echo "images not in MediaStore"; exit 1; }
show() { # show <id>: open in Photos, then tap to hide its toolbars
  $A shell am force-stop $PHOTOS   # otherwise Photos keeps showing the previous image
  $A shell am start -a android.intent.action.VIEW -d content://media/external/images/media/$1 \
    -t image/png -p $PHOTOS >/dev/null 2>&1
  sleep 2.5; $A shell input tap "$2" "$3"
}

# 3. Clean status bar (10:00, full battery and signal, no notifications).
$A shell settings put global sysui_demo_allowed 1
$A shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
for c in "clock -e hhmm 1000" "battery -e level 100 -e plugged false" \
         "network -e wifi show -e level 4 -e mobile show -e datatype none -e level 4" \
         "notifications -e visible false"; do
  $A shell am broadcast -a com.android.systemui.demo -e command $c >/dev/null
done

# 4. Permissions; Japanese → English in AI mode.
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
$A shell settings put secure enabled_accessibility_services $PKG/.ScrollDetectionAccessibilityService
$A shell settings put secure accessibility_enabled 1
portrait
$A shell am force-stop $PKG
$PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=ja targetLanguage=en translationMode=onnx
$A shell am force-stop $PHOTOS
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12

record() { # record <name> <limit-seconds>
  $A shell rm -f /sdcard/$1.mp4
  ($A shell screenrecord --bit-rate 12000000 --time-limit "$2" /sdcard/$1.mp4 &)
  sleep 2
}
stop_record() {
  $A shell pkill -INT screenrecord; sleep 3
  $A pull /sdcard/$1.mp4 "$REC_OUT/$1.mp4" >/dev/null && echo "recorded $REC_OUT/$1.mp4"
}

# 5. Portrait: start translation through the consent dialog, then two manga pages.
record portrait_manga 120
sleep 2
$A shell input tap 540 1508; sleep 3    # Translate Screen
$A shell input tap 540 1128; sleep 1.5  # capture-mode dropdown
$A shell input tap 360 1318; sleep 1.5  # "Share entire screen"
$A shell input tap 894 1610; sleep 4    # Share screen
pid=$(app_pid)
[ -n "$pid" ] || { echo "app not running after start"; exit 1; }
show "$M1" 540 1700; sleep 17
show "$M2" 540 1700; sleep 17
stop_record portrait_manga

# 6. Landscape: game dialogue.
$A shell am force-stop $PHOTOS
landscape
record landscape_game 60
show "$GAME" 1200 250; sleep 20
stop_record landscape_game
[ "$(app_pid)" = "$pid" ] || echo "WARNING: the app restarted during recording (low memory?); check the clips"

# 7. Restore portrait and the real status bar. (start.sh sets its own
#    language pair and mode, so the regression doesn't depend on this run.)
portrait
$A shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null
$A shell am force-stop $PKG
echo "Done. Next: python tools/demo_video/contact_sheet.py $REC_OUT/portrait_manga.mp4"

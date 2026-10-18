#!/usr/bin/env bash
# Usage: capture.sh <locale> [scene ...]      e.g. capture.sh zh-CN manga chat
# Captures raw 1080x2400 screenshots of the real app on the emulator into
# tools/store_assets/raw/<locale>/<scene>.png; compose.py lays them out.
#
# Content scenes (manga, game, webtoon, chat): start live translation, show
# the artwork full-screen in Google Photos, wait for "Translations complete",
# let it settle, screencap. The text is translated into the listing's
# language: English via the AI packs, Chinese and Japanese via Quick mode
# (AI packs only translate into English). OCR is not deterministic: check
# every capture; check_lines.sh is how the lines were chosen.
# App scenes (home, settings, languages): the app's own screens, with its UI
# in the listing's language (per-app locale, Android 13+).
#
# Needs: the debug app, the ja-en and ko-en AI packs
# (tools/emulator/push_ai_pack.sh), and the assets from make_assets.py.
source "$(dirname "$0")/../emulator/common.sh"
HERE="$ROOT/tools/store_assets"
LOCALE=${1:-en-US}; shift
RAW="${RAW:-$HERE/raw}"   # lite: RAW=<elsewhere>, keeps the paid raws
OUTDIR="$RAW/$LOCALE"
mkdir -p "$OUTDIR"
PH=com.google.android.apps.photos

target() { case $LOCALE in zh-CN) echo zh;; ja-JP) echo ja;; *) echo en;; esac; }
mode() { [ "$(target)" = en ] && echo onnx || echo onDevice; }
default_scenes() {
  case $LOCALE in
    # Japanese artwork translated into Japanese makes no sense: the Japanese
    # listing's manga and game use English lines (manga_en, tavern_en_lines).
    ja-JP) echo "manga game webtoon chat home settings languages";;
    *) echo "manga game webtoon chat home settings languages";;
  esac
}
SCENES=${*:-$(default_scenes)}

# Content scene → image and source language.
scene_image() {
  case $1 in
    manga) case $(target) in en) echo manga.png;; ja) echo manga_en.png;; *) echo manga_cjk.png;; esac;;
    game) case $(target) in en) echo tavern_en.png;; ja) echo tavern_en_lines.png;; *) echo tavern.png;; esac;;
    webtoon) [ "$(target)" = en ] && echo webtoon_screen.png || echo webtoon_screen_cjk.png;;
    chat) case $(target) in en) echo chat_ja.png;; ja) echo chat_en_ja.png;; *) echo chat_en.png;; esac;;
  esac
}
scene_lang() {
  case $1 in
    webtoon) echo ko;;
    manga|game) [ "$(target)" = ja ] && echo en || echo ja;;
    chat) [ "$(target)" = en ] && echo ja || echo en;;
    *) echo ja;;
  esac
}
# Language pair shown on the app's own screens.
home_source() { [ "$(target)" = ja ] && echo en || echo ja; }

image_id() {
  $A shell content query --uri content://media/external/images/media --projection _id \
    --where "_display_name=\'$1\'" | grep -oE "_id=[0-9]+" | tail -1 | cut -d= -f2
}
# Tap positions: the 1080x2400 phone AVD, or the Pixel Tablet AVD in
# portrait (1600x2560, Android 15: different consent dialog).
SIZE=$($A shell wm size | grep -oE "[0-9]+x[0-9]+" | tail -1)
case $SIZE in
  1600x2560|2560x1600)
    DEVICE=tablet
    T_SCREEN="800 1517"; T_MODE="800 1218"; T_ENTIRE="740 1361"; T_START="1162 1584"
    T_GEAR="1510 2406"; T_SRC="400 1021"; T_PHOTOS="800 1900"
    OUTDIR="$RAW/tablet/$LOCALE"; mkdir -p "$OUTDIR";;
  *)
    DEVICE=phone
    T_SCREEN="540 1508"; T_MODE="540 1128"; T_ENTIRE="360 1318"; T_START="894 1610"
    T_GEAR="963 2220"; T_SRC="250 855"; T_PHOTOS="540 1700";;
esac
if [ $DEVICE = tablet ]; then
  eval "$(sed -n '/^orientation()/,/^landscape()/p' "$ROOT/tools/demo_video/record.sh")"
fi

enable_a11y() {
  # Android 15 drops the app's accessibility service when it is force-stopped.
  $A shell settings put secure enabled_accessibility_services $PKG/.ScrollDetectionAccessibilityService
  $A shell settings put secure accessibility_enabled 1
}
launch() { # launch <source> <target> <mode>
  $A shell am force-stop $PH
  $A shell am force-stop $PKG
  enable_a11y
  $PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=$1 targetLanguage=$2 translationMode=$3 >/dev/null
  $A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12
  [ $DEVICE = tablet ] && portrait
}
start_translation() {
  [ $DEVICE = tablet ] && portrait
  $A shell input tap $T_SCREEN; sleep 3   # Translate Screen
  $A shell input tap $T_MODE; sleep 1.5   # capture-mode dropdown
  $A shell input tap $T_ENTIRE; sleep 1.5 # "Entire screen"
  $A shell input tap $T_START; sleep 4    # Share / Start
}
shot() { $A exec-out screencap -p > "$OUTDIR/$1.png"; echo "$1: $OUTDIR/$1.png"; }

# Clean status bar, permissions, app UI language.
$A shell settings put global sysui_demo_allowed 1
$A shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
for c in "clock -e hhmm 1000" "battery -e level 100 -e plugged false" \
         "network -e wifi show -e level 4 -e mobile show -e datatype none -e level 4" \
         "notifications -e visible false"; do
  $A shell am broadcast -a com.android.systemui.demo -e command $c >/dev/null
done
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
# No "Viewing full screen" tip over the first full-screen image.
$A shell settings put secure immersive_mode_confirmations confirmed
$A shell settings put secure enabled_accessibility_services $PKG/.ScrollDetectionAccessibilityService
$A shell settings put secure accessibility_enabled 1
$A shell cmd locale set-app-locales $PKG --locales $LOCALE

for scene in $SCENES; do
  case $scene in
    home)
      launch $(home_source) $(target) $(mode)
      start_translation; sleep 2
      shot home;;
    settings)
      launch ja en onnx   # AI selected: the pack list with sizes and "Ready" packs
      $A shell input tap $T_GEAR; sleep 4   # settings gear
      shot settings;;
    languages)
      launch $(home_source) $(target) onDevice   # Quick: the full language list
      $A shell input tap $T_SRC; sleep 3      # source-language dropdown
      shot languages;;
    *)
      # "file=<image>,src=<lang>" captures any image in assets/ (for trying lines).
      case $scene in
        file=*) spec=${scene#file=}; img=${spec%%,src=*}; src=${spec##*,src=}; scene=${img%.png};;
        *) img=$(scene_image $scene); src=$(scene_lang $scene);;
      esac
      [ -n "$img" ] || { echo "unknown scene $scene"; continue; }
      $A push "$HERE/assets/$img" /sdcard/Pictures/$img >/dev/null
      $A shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/$img >/dev/null
      sleep 2
      uri=content://media/external/images/media/$(image_id $img)
      # Open the image and hide Photos' toolbars BEFORE translation starts,
      # then start translation and bring the same Photos screen back. If
      # the toolbars are on screen when translation starts, their labels
      # are translated and those boxes can stay after the toolbars hide.
      $A shell am force-stop $PH
      $A shell am force-stop $PKG
      enable_a11y
      $PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=$src targetLanguage=$(target)         translationMode=$(mode) >/dev/null
      $A shell am start -a android.intent.action.VIEW -d $uri -t image/png -p $PH >/dev/null 2>&1
      sleep 3; $A shell input tap $T_PHOTOS; sleep 2   # hide Photos' toolbars
      $A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12
      start_translation
      $A logcat -c
      $A shell am start -a android.intent.action.VIEW -d $uri -t image/png -p $PH >/dev/null 2>&1
      done_at=""
      for _ in $(seq 1 45); do
        sleep 2
        if $A logcat -d -s flutter:I | grep -q "Translations complete"; then done_at=yes; break; fi
      done
      [ -n "$done_at" ] || echo "WARNING $scene: no 'Translations complete' within 90 s"
      sleep 5   # later cycles may still refine boxes
      shot $scene
      $A logcat -d -s flutter:I | grep -E "\[ONNX\] Done|Translated text" | sed 's/.*\] //; s/.*Translation: //' |
        sort -u | sed 's/^/  /';;
  esac
done

$A shell am force-stop $PH
$A shell am force-stop $PKG
$A shell cmd locale set-app-locales $PKG --locales ""
$A shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null

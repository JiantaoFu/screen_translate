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
OUTDIR="$HERE/raw/$LOCALE"
mkdir -p "$OUTDIR"
PH=com.google.android.apps.photos

target() { case $LOCALE in zh-CN) echo zh;; ja-JP) echo ja;; *) echo en;; esac; }
mode() { [ "$(target)" = en ] && echo onnx || echo onDevice; }
default_scenes() {
  case $LOCALE in
    # Japanese artwork translated into Japanese makes no sense: the Japanese
    # listing shows Korean and English sources only.
    ja-JP) echo "webtoon chat home settings languages";;
    *) echo "manga game webtoon chat home settings languages";;
  esac
}
SCENES=${*:-$(default_scenes)}

# Content scene → image and source language.
scene_image() {
  case $1 in
    manga) echo manga.png;; game) echo tavern.png;;
    webtoon) [ "$(target)" = en ] && echo webtoon_screen.png || echo webtoon_screen_cjk.png;;
    chat) [ "$(target)" = en ] && echo chat_ja.png || echo chat_en.png;;
  esac
}
scene_lang() {
  case $1 in
    webtoon) echo ko;;
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
launch() { # launch <source> <target> <mode>
  $A shell am force-stop $PH
  $A shell am force-stop $PKG
  $PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=$1 targetLanguage=$2 translationMode=$3 >/dev/null
  $A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12
}
start_translation() {
  $A shell input tap 540 1508; sleep 3    # Translate Screen
  $A shell input tap 540 1128; sleep 1.5  # capture-mode dropdown
  $A shell input tap 360 1318; sleep 1.5  # "Share entire screen"
  $A shell input tap 894 1610; sleep 4    # Share screen
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
      $A shell input tap 963 2220; sleep 4   # settings gear
      shot settings;;
    languages)
      launch $(home_source) $(target) onDevice   # Quick: the full language list
      $A shell input tap 250 855; sleep 3      # source-language dropdown
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
      $PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=$src targetLanguage=$(target)         translationMode=$(mode) >/dev/null
      $A shell am start -a android.intent.action.VIEW -d $uri -t image/png -p $PH >/dev/null 2>&1
      sleep 3; $A shell input tap 540 1700; sleep 2   # hide Photos' toolbars
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

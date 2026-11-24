# Shared setup for the emulator regression scripts; sourced, not run.
# Targets $ANDROID_SERIAL (default emulator-5554) so an attached phone is
# never touched. Screenshots and logs go to $OUT (default build/emulator-regression).
export MSYS_NO_PATHCONV=1   # Git Bash: keep /data/... paths intact for adb
# pwd -W gives C:/... in Git Bash: with path conversion off, Windows Python
# can't open /c/... paths.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && (pwd -W 2>/dev/null || pwd))"
SERIAL="${ANDROID_SERIAL:-emulator-5554}"
A="adb -s $SERIAL"
# python tools/build.py emulator writes the flavored path below; the
# unflavored apk/debug/app-debug.apk from before the paid/lite flavors is
# deliberately NOT accepted as a fallback, so a stale copy of it can't be
# installed in place of the build you meant to test.
# Override with FLAVOR=lite, or APK=<path> for an APK from anywhere.
FLAVOR=${FLAVOR:-paid}
if [ "$FLAVOR" = lite ]; then
  export PKG=${PKG:-com.lomoware.screen_translate.lite}
else
  export PKG=${PKG:-com.lomoware.screen_translate}
fi
APK="${APK:-$ROOT/build/app/outputs/apk/$FLAVOR/debug/app-$FLAVOR-debug.apk}"
# CAPTURE=screen (default) shares the entire screen; CAPTURE=app keeps
# Android 14+'s default, "Share one app", which is what most users get.
# Android's "Choose app to share" list never offers the app that asked to
# capture (none of its tasks), so in app mode the harness screens come
# from the other flavor's debug install: the same MotionTestActivity in
# its own package, shared like the manga or game app a user picks.
# HARNESS_LABEL is that app's name in the list.
CAPTURE=${CAPTURE:-screen}
if [ "$CAPTURE" = app ]; then
  if [ "$FLAVOR" = lite ]; then
    HARNESS_FLAVOR=paid; HARNESS_PKG=com.lomoware.screen_translate; HARNESS_LABEL='Screen Translate'
  else
    HARNESS_FLAVOR=lite; HARNESS_PKG=com.lomoware.screen_translate.lite; HARNESS_LABEL='Screen Translator Lite'
  fi
  HARNESS_APK="${HARNESS_APK:-$ROOT/build/app/outputs/apk/$HARNESS_FLAVOR/debug/app-$HARNESS_FLAVOR-debug.apk}"
else
  HARNESS_PKG=$PKG
fi
OUT="${OUT:-$ROOT/build/emulator-regression}"
mkdir -p "$OUT"
PY=$(command -v python3 || command -v python)

harness() { # harness <mode> [extras...] — shows a MotionTestActivity screen
  local mode=$1; shift
  $A shell am start -n "$HARNESS_PKG/com.lomoware.screen_translate.MotionTestActivity" --es mode "$mode" "$@" >/dev/null 2>&1
}

# Our translation windows as "(x,y)(wxh)", minus the two 126x126 control
# buttons and the system's full-screen ShellDropTarget.
overlay_windows() {
  $A shell dumpsys window windows | grep 'ty=APPLICATION_OVERLAY' \
    | grep -v '(126x126)\|fillxfill' | grep -oE '\(-?[0-9]+,-?[0-9]+\)\([0-9]+x[0-9]+\)'
}

app_pid() { $A shell pidof $PKG | tr -d '\r'; }

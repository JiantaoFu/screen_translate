# Shared setup for the emulator regression scripts; sourced, not run.
# Targets $ANDROID_SERIAL (default emulator-5554) so an attached phone is
# never touched. Screenshots and logs go to $OUT (default build/emulator-regression).
export MSYS_NO_PATHCONV=1   # Git Bash: keep /data/... paths intact for adb
# pwd -W gives C:/... in Git Bash: with path conversion off, Windows Python
# can't open /c/... paths.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && (pwd -W 2>/dev/null || pwd))"
SERIAL="${ANDROID_SERIAL:-emulator-5554}"
A="adb -s $SERIAL"
PKG=com.lomoware.screen_translate
APK="$ROOT/build/app/outputs/apk/debug/app-debug.apk"   # python tools/build.py emulator
OUT="${OUT:-$ROOT/build/emulator-regression}"
mkdir -p "$OUT"
PY=$(command -v python3 || command -v python)

harness() { # harness <mode> [extras...] — shows a MotionTestActivity screen
  local mode=$1; shift
  $A shell am start -n $PKG/.MotionTestActivity --es mode "$mode" "$@" >/dev/null 2>&1
}

# Our translation windows as "(x,y)(wxh)", minus the two 126x126 control
# buttons and the system's full-screen ShellDropTarget.
overlay_windows() {
  $A shell dumpsys window windows | grep 'ty=APPLICATION_OVERLAY' \
    | grep -v '(126x126)\|fillxfill' | grep -oE '\(-?[0-9]+,-?[0-9]+\)\([0-9]+x[0-9]+\)'
}

app_pid() { $A shell pidof $PKG | tr -d '\r'; }

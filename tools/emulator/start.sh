#!/usr/bin/env bash
# Installs the x86_64 debug APK (SKIP_INSTALL=1 to reuse the installed one),
# grants overlay/accessibility without the settings UIs, and starts a live
# translation session through the screen-capture consent dialog.
# Taps are for the 1080x2400 Medium_Phone AVD.
source "$(dirname "$0")/common.sh"
if [ "$SKIP_INSTALL" != 1 ]; then
  [ -f "$APK" ] || { echo "FAIL start: $APK missing (see tools/emulator/README.md)"; exit 1; }
  if ! install_output=$($A install -r "$APK" 2>&1); then
    printf '%s\n' "$install_output"
    echo "FAIL start: APK installation failed; refusing to test an older install"
    exit 1
  fi
  printf '%s\n' "$install_output" | tail -1
fi
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
$A shell settings put secure enabled_accessibility_services "$PKG/com.lomoware.screen_translate.ScrollDetectionAccessibilityService"
$A shell settings put secure accessibility_enabled 1
$A shell settings put system accelerometer_rotation 0
$A shell settings put system user_rotation 0
$A shell am force-stop $PKG
# The harness text is English. Only text in the source language's script is
# translated, so pin the pair (and Quick mode) instead of using whatever the
# app last saved.
$PY "$ROOT/tools/emulator/set_prefs.py" "$SERIAL" sourceLanguage=en targetLanguage=zh translationMode=onDevice >/dev/null
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 14
$A logcat -c
# By text: lite adds a free-allowance row and an Unlock Pro button to the
# home screen, which moves this button. The fixed tap this replaced was
# tuned to paid and in lite landed on Translate Image, opening the photo
# picker.
$PY "$ROOT/tools/emulator/tap_text.py" "$SERIAL" 'Translate Screen' --timeout 10 || {
  echo "FAIL start: Translate Screen button not found"
  exit 1
}
sleep 3
# On a fresh install Start now explains why the app needs the screen
# before Android's consent dialog. Optional: a reused install (or one
# that already granted once) goes straight to the system dialog. Tapped
# by text, because this one is our own layout and would drift.
$PY "$ROOT/tools/emulator/tap_text.py" "$SERIAL" 'Grant Permission' --optional --timeout 6
sleep 2
# Pick full-screen capture, by text. The system dialog's height moves with
# the app name - "Share your screen with Screen Translator Lite?" wraps to
# two lines where the paid name does not - so the old fixed taps selected
# the mode correctly for paid only. In lite they left it on "Share one app"
# pointed at nothing, and capture then ran with a VirtualDisplay nothing
# ever rendered into: every check failed with "No frame available in queue"
# and no crash, which looks exactly like a broken pipeline.
# Android 14+ defaults to "Share one app"; if a device defaults to the whole
# screen there is no dropdown to open, so that tap decides whether to select.
if $PY "$ROOT/tools/emulator/tap_text.py" "$SERIAL" 'Share one app' --timeout 6 >/dev/null 2>&1; then
  sleep 1.5
  $PY "$ROOT/tools/emulator/tap_text.py" "$SERIAL" 'Share entire screen' --timeout 6 || {
    echo "FAIL start: could not select full-screen capture"
    exit 1
  }
  sleep 1.5
fi
# The confirm button is labelled for what it does next: "Share screen" for
# the whole screen, "Next" for one app (it leads to the app picker). Same
# position either way, which is why the old coordinate tap hid the
# difference.
if ! $PY "$ROOT/tools/emulator/tap_text.py" "$SERIAL" 'Share screen' --timeout 8 >/dev/null 2>&1; then
  $PY "$ROOT/tools/emulator/tap_text.py" "$SERIAL" 'Next' --timeout 4 || {
    echo "FAIL start: could not confirm the capture dialog"
    exit 1
  }
fi
sleep 4
if $A logcat -d | grep -q 'Service started, reset stopped flag'; then
  app_pid > "$OUT/pid"
  echo "PASS start: live translation running (pid $(cat "$OUT/pid"))"
else
  echo "FAIL start: capture service did not start"; exit 1
fi

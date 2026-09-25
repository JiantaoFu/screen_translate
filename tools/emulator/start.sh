#!/usr/bin/env bash
# Installs the x86_64 debug APK (SKIP_INSTALL=1 to reuse the installed one),
# grants overlay/accessibility without the settings UIs, and starts a live
# translation session through the screen-capture consent dialog.
# Taps are for the 1080x2400 Medium_Phone AVD.
source "$(dirname "$0")/common.sh"
if [ "$SKIP_INSTALL" != 1 ]; then
  [ -f "$APK" ] || { echo "FAIL start: $APK missing (see tools/emulator/README.md)"; exit 1; }
  $A install -r "$APK" 2>&1 | tail -1
fi
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
$A shell settings put secure enabled_accessibility_services $PKG/.ScrollDetectionAccessibilityService
$A shell settings put secure accessibility_enabled 1
$A shell settings put system accelerometer_rotation 0
$A shell settings put system user_rotation 0
$A shell am force-stop $PKG
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 14
$A logcat -c
$A shell input tap 540 1508; sleep 3    # Translate Screen
$A shell input tap 540 1128; sleep 1.5  # capture-mode dropdown
$A shell input tap 360 1318; sleep 1.5  # "Share entire screen"
$A shell input tap 894 1610; sleep 4    # Next
if $A logcat -d | grep -q 'Service started, reset stopped flag'; then
  app_pid > "$OUT/pid"
  echo "PASS start: live translation running (pid $(cat "$OUT/pid"))"
else
  echo "FAIL start: capture service did not start"; exit 1
fi

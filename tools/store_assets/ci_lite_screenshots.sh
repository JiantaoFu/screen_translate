#!/usr/bin/env bash
# CI driver for the Lite listing screenshots (.github/workflows/lite-screenshots.yml).
# Runs inside reactivecircus/android-emulator-runner with the lite debug APK
# built. Everything goes to $OUT_DIR (uploaded as artifacts):
#   raw/en-US/*.png      1080x2400 captures (capture.sh)
#   quota.txt            the quota text the home screen showed + the number
#   manga_vertical_jp.txt OCR'd and translated lines of the vertical manga bubble
#   logcat-*.txt         logs
set -uo pipefail
export PKG=com.lomoware.screen_translate.lite
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR=${OUT_DIR:-$ROOT/build/lite-screenshots}
export RAW="$OUT_DIR/raw"
mkdir -p "$RAW"
A="adb -s ${ANDROID_SERIAL:-emulator-5554}"
APK="$ROOT/build/app/outputs/apk/lite/debug/app-lite-debug.apk"

$A wait-for-device
$A shell settings put global window_animation_scale 0
$A shell settings put global transition_animation_scale 0
$A shell settings put global animator_duration_scale 0
$A install -r "$APK" | tail -1
$A shell pm list packages | grep -q com.google.android.apps.photos || echo "WARNING: no Google Photos on this image"
# First launch creates the app's files dir and prefs (push_ai_pack/set_prefs need them).
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 20
$A shell am force-stop $PKG

# AI packs used by the en-US scenes (manga/game/chat: ja-en, webtoon: ko-en fp16).
bash "$ROOT/tools/emulator/push_ai_pack.sh" opus-mt-ja-en
bash "$ROOT/tools/emulator/push_ai_pack.sh" opus-mt-ko-en fp16

# (a) Home first, while the whole daily quota is unused: read the quota off
# the real UI (uiautomator), then the capture.sh home shot.
$A shell appops set $PKG SYSTEM_ALERT_WINDOW allow
$A shell cmd locale set-app-locales $PKG --locales en-US
$A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 15
$A exec-out screencap -p > "$OUT_DIR/home_before_start.png"
$A shell uiautomator dump /sdcard/ui.xml >/dev/null && $A exec-out cat /sdcard/ui.xml > "$OUT_DIR/home_ui.xml"
grep -oE '(text|content-desc)="[^"]*"' "$OUT_DIR/home_ui.xml" | sed 's/^[a-z-]*="//; s/"$//' | grep -v '^$' > "$OUT_DIR/home_texts.txt"
quota_line=$(grep -iE '[0-9]+.*(free|left|today|translation)|(free|left).*[0-9]+' "$OUT_DIR/home_texts.txt" | head -1)
quota=$(echo "$quota_line" | grep -oE '[0-9]+' | tail -1)
pro_line=$(grep -iE 'pro|unlock|upgrade' "$OUT_DIR/home_texts.txt" | head -3 | tr '\n' '|')
{ echo "quota_line=$quota_line"; echo "quota=$quota"; echo "pro_entry=$pro_line"; } | tee "$OUT_DIR/quota.txt"
echo "quota=$quota" >> "${GITHUB_OUTPUT:-/dev/null}"
bash "$ROOT/tools/store_assets/capture.sh" en-US home 2>&1 | tee "$OUT_DIR/capture-home.txt"

# (b) Vertical-Japanese check: the manga bubble is vertical Japanese
# (ロボットは / 街を壊してる！). 3 runs, OCR text and translation as logged.
{
  echo "Expected source: ロボットは街を壊してる！ (vertical, one bubble)"
  bash "$ROOT/tools/store_assets/check_lines.sh" ja 3 "$ROOT/tools/store_assets/assets/manga.png"
} 2>&1 | tee "$OUT_DIR/manga_vertical_jp.txt"
$A logcat -d > "$OUT_DIR/logcat-manga-check.txt"

# (c) Content scenes.
# Each session that draws a translation uses one free translation; the check
# above used one. Moving the stored quota day back resets "used today" (a new
# day) so no scene runs into the paywall. App must be stopped (capture.sh
# force-stops it at the end of each scene).
reset_quota() { $A shell am force-stop $PKG; python3 "$ROOT/tools/emulator/set_prefs.py" "${ANDROID_SERIAL:-emulator-5554}" lite_quota_day=1970-01-01 >/dev/null; }
for s in manga game webtoon chat; do
  reset_quota
  bash "$ROOT/tools/store_assets/capture.sh" en-US $s 2>&1 | tee "$OUT_DIR/capture-$s.txt"
done
$A logcat -d > "$OUT_DIR/logcat-final.txt"
ls -l "$RAW/en-US"
exit 0

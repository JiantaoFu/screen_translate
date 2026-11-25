# Emulator regression for live translation

These scripts drive the real capture → OCR → translate → overlay loop on an
Android emulator. They use the debug-only `MotionTestActivity` harness, which
shows video, feed, game, typewriter or static screens in its own process.

Run `run_all.sh` after changing the capture/overlay pipeline and before every
release. It takes about 17 minutes. Every check prints `PASS`/`FAIL`, and the
run ends with `ALL EMULATOR CHECKS PASSED` or a list of the failures.
Screenshots and logs go to `build/emulator-regression/`.

It runs twice over: first sharing the entire screen, then sharing one app.
"Share one app" is Android 14+'s default in the capture dialog, so it is what
most users run. Android's "Choose app to share" list never offers the app
that asked to capture, so the one-app pass shares the harness from the other
flavor's debug install (the paid app captures Lite's `MotionTestActivity`),
the way a user shares a manga or game app. Any script runs in that mode with
`CAPTURE=app` once `CAPTURE=app start.sh` has started the session.

The runner stops if installing the requested APK fails, so an older installed
app cannot accidentally produce a passing regression. Test this guard without
a device using `python tools/emulator/test_start.py`.
Set `FLAVOR=lite` to select the Lite APK, package and preference storage; native
component class names keep their shared `com.lomoware.screen_translate` namespace.
The app's Translate Screen button is located by its accessibility label so the
paid and Lite home layouts can differ without opening the image picker by mistake.

## Setup (Windows, Git Bash)

1. Use the AVD `Medium_Phone_API_36.1` (1080x2400; the taps in `start.sh`
   assume this size). Start it with:
   ```
   "$LOCALAPPDATA/Android/Sdk/emulator/emulator.exe" -avd Medium_Phone_API_36.1 \
       -no-snapshot-load -no-boot-anim -no-audio -gpu swiftshader_indirect
   ```
   Its files are in `~/.android/avd/Medium_Phone.avd/`. For AI mode, as in
   the store demo video (`tools/demo_video/`), set `hw.ramSize=4096` in its
   `config.ini`: at 2 GB the low-memory killer kills the app.
2. Build the x86_64 debug APKs of both flavors with the project's build script:
   ```
   python tools/build.py emulator
   python tools/build.py emulator --flavor lite
   ```
   The outputs are `build/app/outputs/apk/{paid,lite}/debug/app-{paid,lite}-debug.apk`,
   which have only the x86_64 ABI, so they fit on the emulator. The scripts
   pick them up automatically: the paid APK is the app under test and the
   lite one hosts the harness for the one-app pass. Use `FLAVOR=lite` to test
   the lite app instead (the paid install then hosts the harness), or
   `APK=<path>` / `HARNESS_APK=<path>` for APKs from anywhere.
3. Run `tools/emulator/run_all.sh`. The scripts target `emulator-5554`, or
   `$ANDROID_SERIAL` if set, so a connected phone is never touched.

## Scripts

| Script | Checks |
|---|---|
| `start.sh` | installs the APK, grants overlay and accessibility access, and starts live translation through the consent dialog: sharing the entire screen, or with `CAPTURE=app` one app (also installs the other flavor and picks its harness in "Choose app to share") |
| `scenario.sh <mode>` | translated boxes stay on screen over video, feed, game, typewriter and static screens, with no crash |
| `switch.sh <mode>` | when the text under our boxes changes, the change is detected and the new text is translated |
| `typecheck.sh` | typed-out game dialogue ends up fully translated, not as stacked fragments |
| `hidecheck.sh` | Hide all (long-press on the floating button) clears every box and keeps them off an unchanged page, also when pressed during a page change; the next page change brings boxes back |
| `rotcheck.sh` | another app rotating to landscape and back: the rotation is detected, no stale boxes are drawn, and the boxes stay on the text |
| `rereadcheck.sh ru\|th` | Russian or Thai -> English (restarts the session with that pair): ML Kit can't read Cyrillic or Thai, so each line it finds is re-read by a downloaded line model (`DownloadedLineRecognizer`); both pages must come out as English. `OCR_MODEL_DIR=<dir>` installs `rec.onnx`/`dict.txt` instead of downloading |
| `awaycheck.sh` | one app only (`CAPTURE=app`): leaving the shared app clears its boxes from the screen and keeps the session running; coming back brings the boxes back without a restart |
| `set_prefs.py` | sets the app's saved preferences (language pair, mode); `start.sh` pins en→zh in Quick mode with it, because only text in the source language's script is translated |
| `fdprobe.sh` | report only: file descriptor growth, to track the emulator `getPlanes()` sync_file leak |

## Troubleshooting

- The emulator's `/data` fills up (~6 GB), and the run needs room for both
  debug APKs. Free space with `adb shell pm uninstall-system-updates <google app>`.
- The emulator can crash, or be killed when the host is low on memory,
  during long capture runs. Stop Gradle daemons (`./gradlew --stop`) before
  a run, then restart the emulator and rerun.

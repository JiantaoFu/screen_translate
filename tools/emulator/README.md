# Emulator regression for live translation

These scripts drive the real capture → OCR → translate → overlay loop on an
Android emulator. They use the debug-only `MotionTestActivity` harness, which
shows video, feed, game, typewriter or static screens in its own process.

Run `run_all.sh` after changing the capture/overlay pipeline and before every
release. It takes about 10 minutes. Every check prints `PASS`/`FAIL`, and the
run ends with `ALL EMULATOR CHECKS PASSED` or a list of the failures.
Screenshots and logs go to `build/emulator-regression/`.

## Setup (Windows, Git Bash)

1. Use the AVD `Medium_Phone_API_36.1` (1080x2400; the taps in `start.sh`
   assume this size). Start it with:
   ```
   "$LOCALAPPDATA/Android/Sdk/emulator/emulator.exe" -avd Medium_Phone_API_36.1 \
       -no-snapshot-load -no-boot-anim -no-audio -gpu swiftshader_indirect
   ```
2. Build the x86_64 debug APK with the project's build script:
   ```
   python tools/build.py emulator
   ```
   The output is `build/app/outputs/apk/debug/app-debug.apk`, which has only
   the x86_64 ABI, so it fits on the emulator.
3. Run `tools/emulator/run_all.sh`. The scripts target `emulator-5554`, or
   `$ANDROID_SERIAL` if set, so a connected phone is never touched.

## Scripts

| Script | Checks |
|---|---|
| `start.sh` | installs the APK, grants overlay and accessibility access, and starts live translation through the consent dialog |
| `scenario.sh <mode>` | translated boxes stay on screen over video, feed, game, typewriter and static screens, with no crash |
| `switch.sh <mode>` | when the text under our boxes changes, the change is detected and the new text is translated |
| `typecheck.sh` | typed-out game dialogue ends up fully translated, not as stacked fragments |
| `rotcheck.sh` | another app rotating to landscape and back: the rotation is detected, no stale boxes are drawn, and the boxes stay on the text |
| `fdprobe.sh` | report only: file descriptor growth, to track the emulator `getPlanes()` sync_file leak |

## Troubleshooting

- The emulator's `/data` fills up (~6 GB). Free space with
  `adb shell pm uninstall-system-updates <google app>`.
- The emulator can crash, or be killed when the host is low on memory,
  during long capture runs. Stop Gradle daemons (`./gradlew --stop`) before
  a run, then restart the emulator and rerun.

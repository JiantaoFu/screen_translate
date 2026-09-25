# ScreenTranslate: working notes for Claude

Flutter app (`lib/`) with Kotlin native services (`android/app/src/main/kotlin/`):
screen capture (MediaProjection), frame change detection (FrameStabilizer and
MotionClassifier), and overlay windows. Package: `com.lomoware.screen_translate`.

## Tests: run after every change

Run all of these before saying a change is done, and report the results:

| What | Command | When |
|---|---|---|
| Flutter tests | `flutter test` | every change |
| Android unit tests | `cd android && JAVA_HOME="C:/Program Files/Microsoft/jdk-17.0.19.10-hotspot" ./gradlew :app:testDebugUnitTest` | every change |
| Release tool tests | `python tools/test_release.py` | when `tools/release.py` changes |
| Emulator regression | `tools/emulator/run_all.sh` (setup: `tools/emulator/README.md`) | changes that can alter capture/overlay behaviour (see below), and before every release |

The emulator regression takes about 10 minutes, so decide from what the
change can affect rather than which file it touches:
- **Run it all** when a change can alter frame capture, change detection,
  or how boxes are placed, updated or removed: logic in ScreenCaptureService,
  FrameStabilizer, MotionClassifier, OverlayService, OverlayRegions, or
  TranslationProvider's box logic. Always run it all before a release.
- **Run only the matching script** when the change is narrow, e.g.
  `rotcheck.sh` for rotation handling or `typecheck.sh` for typewriter
  text. The table in `tools/emulator/README.md` says what each script checks.
- **Skip it** when the change can't reach that behaviour, even inside those
  files: text/resources, logging, comments, renames, or code outside the
  pipeline. Say that you skipped it, and why, when reporting.

- Add or update tests with each behaviour change. Unit tests go in `test/`
  (Dart) or `android/app/src/test/kotlin/` (Kotlin).
- New live-translation scenarios go in the debug harness
  `android/app/src/debug/.../MotionTestActivity.kt`, with a check in `tools/emulator/`.
- A failing test is a finding. Say so, with the output. Never skip a test or
  weaken it just to make it pass.
- After Gradle builds, run `./gradlew --stop`. The host has 16 GB of RAM, and
  a Gradle daemon plus the emulator can get the emulator killed.
- Only drive the emulator (`emulator-5554`). Never use the user's phone
  (`57241FDCR0074L`) without asking.

## Building: always `tools/build.py`

Every build, for any purpose, goes through `tools/build.py`. Don't run
`flutter build` or `gradlew assemble*/bundle*` by hand.

| Need | Command |
|---|---|
| Install on the user's phone (only when asked) | `python tools/build.py apk --install <serial>` (release-signed, arm64) |
| Emulator / `tools/emulator/` | `python tools/build.py emulator [--install emulator-5554]` (debug, x86_64) |
| Google Play bundle | `python tools/build.py aab`, or `tools/release.py` to publish |

What the script does:
- syncs the version from `pubspec.yaml` into `android/local.properties`,
  which is where Gradle reads it;
- builds with JDK 17. `flutter build` fails here because it runs on Android
  Studio's JBR 25;
- keeps each APK to a single ABI through `-Pabi`, instead of Flutter's
  split-per-abi. Split-per-abi adds 1000×ABI to versionCode: a sideloaded
  1.2.1+11 became 2011, which put the phone above Play's versions so Play
  stopped updating it;
- checks every output: the version must match pubspec, release builds must
  not be debug-signed, and Gradle daemons are stopped afterwards.

If a build needs something the script doesn't do, extend `tools/build.py`
(and `tools/test_release.py`) instead of working around it.

## Releasing

Always use `tools/release.py`. README → developer guide section 3 has the
full process: internal track → real-device check → promote to production.
Commit/push and anything published to Play need the user's go-ahead.

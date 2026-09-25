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
| Emulator regression | `tools/emulator/run_all.sh` (setup: `tools/emulator/README.md`) | any change to the capture/overlay pipeline (ScreenCaptureService, FrameStabilizer, MotionClassifier, OverlayService, OverlayRegions, TranslationProvider's box logic), and before every release |

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

## Build gotchas

- `flutter build` fails: Flutter uses Android Studio's JBR 25, which Gradle
  8.11 can't run. Build with `android/gradlew` and JDK 17 (see the commands above).
- Gradle reads the app version from `android/local.properties`
  (`flutter.versionName` / `flutter.versionCode`), not from `pubspec.yaml`.
  `tools/release.py` syncs it.

## Releasing

Always use `tools/release.py`. README → developer guide section 3 has the
full process: internal track → real-device check → promote to production.
Commit/push and anything published to Play need the user's go-ahead.

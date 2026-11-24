"""Checks the regression runner without a connected Android device."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class StartTests(unittest.TestCase):
    def run_start(self, *, flavor="paid", install_success=False, missing_button=False,
                  capture="screen", harness_apk=True):
        git_bash = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
        bash = str(git_bash) if git_bash.exists() else shutil.which("bash")
        self.assertIsNotNone(bash, "Bash is required to test the emulator runner")
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="start-test-", dir=build) as directory:
            temporary = Path(directory)
            apk = temporary / "test.apk"
            apk.touch()
            other = temporary / "harness.apk"
            if harness_apk:
                other.touch()
            calls = temporary / "adb-calls.txt"
            scripts = {
                "adb": (
                    '#!/usr/bin/env bash\n'
                    'printf "%s\\n" "$*" >> "$ADB_CALLS_LOG"\n'
                    'case "$*" in\n'
                    '  *" install -r "*)\n'
                    '    if [ "$INSTALL_SUCCESS" = 1 ]; then echo Success; else\n'
                    '      echo INSTALL_FAILED_INSUFFICIENT_STORAGE; exit 1; fi;;\n'
                    '  *) echo "Service started, reset stopped flag";;\n'
                    'esac\n'
                ),
                "sleep": "#!/usr/bin/env bash\nexit 0\n",
                "python3": ('#!/usr/bin/env bash\n'
                            'printf "prefs:%s\\n" "$PKG" >> "$ADB_CALLS_LOG"\n'
                            'printf "python:%s\\n" "$*" >> "$ADB_CALLS_LOG"\n'
                            'case "$*" in *"Translate Screen"*)\n'
                            '  [ "$MISSING_BUTTON" != 1 ] || exit 1;; esac\n'),
            }
            for name, content in scripts.items():
                script = temporary / name
                script.write_text(content, encoding="utf-8", newline="\n")
                script.chmod(0o755)
            environment = {
                    **os.environ,
                    "PATH": str(temporary) + os.pathsep + os.environ["PATH"],
                    "ANDROID_SERIAL": "emulator-5554",
                    "APK": apk.as_posix(),
                    "OUT": (temporary / "output").as_posix(),
                    "ADB_CALLS_LOG": calls.as_posix(),
                    "SKIP_INSTALL": "0",
                    "FLAVOR": flavor,
                    "CAPTURE": capture,
                    "HARNESS_APK": other.as_posix(),
                    "INSTALL_SUCCESS": "1" if install_success else "0",
                    "MISSING_BUTTON": "1" if missing_button else "0",
                }
            environment.pop("PKG", None)
            result = subprocess.run(
                [bash, "-c", 'sleep() { :; }; export -f sleep; source "$1/tools/emulator/common.sh"; harness static; bash "$1/tools/emulator/start.sh"', "test", ROOT.as_posix()]
                if install_success else [bash, str(ROOT / "tools/emulator/start.sh")],
                env=environment,
                capture_output=True, text=True, timeout=30,
            )
            return result, calls.read_text().splitlines()

    def test_failed_install_stops_before_using_the_existing_app(self):
        result, commands = self.run_start()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("INSTALL_FAILED_INSUFFICIENT_STORAGE", result.stdout)
        self.assertIn("FAIL start: APK installation failed", result.stdout)
        self.assertEqual(len(commands), 1, commands)
        self.assertIn("install -r", commands[0])

    def test_both_flavors_target_the_declared_native_classes_and_preferences(self):
        for flavor, package in (("paid", "com.lomoware.screen_translate"),
                                ("lite", "com.lomoware.screen_translate.lite")):
            with self.subTest(flavor=flavor):
                result, commands = self.run_start(flavor=flavor, install_success=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("shell am start -n " + package +
                              "/com.lomoware.screen_translate.MotionTestActivity --es mode static",
                              "\n".join(commands))
                self.assertIn("shell settings put secure enabled_accessibility_services " + package +
                              "/com.lomoware.screen_translate.ScrollDetectionAccessibilityService",
                              "\n".join(commands))
                self.assertIn("prefs:" + package, commands)
                self.assertIn("tap_text.py emulator-5554 Translate Screen --timeout 10",
                              "\n".join(commands))

    def test_one_app_capture_shares_the_other_flavors_harness(self):
        for flavor, harness, label in (
                ("paid", "com.lomoware.screen_translate.lite", "Screen Translator Lite"),
                ("lite", "com.lomoware.screen_translate", "Screen Translate")):
            with self.subTest(flavor=flavor):
                result, commands = self.run_start(flavor=flavor, install_success=True, capture="app")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                joined = "\n".join(commands)
                installs = [c for c in commands if " install -r " in c]
                self.assertEqual(len(installs), 2, installs)
                self.assertIn("test.apk", installs[0])
                self.assertIn("harness.apk", installs[1])
                # The shared app is opened (so it is in recents) before the
                # app under test, and from its own package.
                harness_start = ("shell am start -n " + harness +
                                 "/com.lomoware.screen_translate.MotionTestActivity --es mode static")
                self.assertIn(harness_start, joined)
                self.assertLess(joined.rindex(harness_start), joined.index("shell monkey"))
                # Android's default stays selected: no switch to the entire
                # screen, then the harness app is picked by name.
                self.assertNotIn("Share entire screen", joined)
                self.assertNotIn("Share one app", joined)
                self.assertLess(joined.index("tap_text.py emulator-5554 Next"),
                                joined.index("tap_text.py emulator-5554 " + label + " "))
                self.assertIn("sharing one app: " + label, result.stdout)

    def test_one_app_capture_without_the_other_flavor_stops_before_testing(self):
        result, commands = self.run_start(install_success=True, capture="app", harness_apk=False)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("harness.apk missing", result.stdout)
        self.assertFalse(any("settings put" in command for command in commands), commands)

    def test_entire_screen_capture_is_still_the_default(self):
        result, commands = self.run_start(install_success=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        joined = "\n".join(commands)
        self.assertIn("Share entire screen", joined)
        self.assertEqual(len([c for c in commands if " install -r " in c]), 1)
        self.assertIn("sharing entire screen", result.stdout)

    def test_missing_translate_button_stops_before_blind_system_dialog_taps(self):
        result, commands = self.run_start(install_success=True, missing_button=True)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("FAIL start: Translate Screen button not found", result.stdout)
        self.assertFalse(any("shell input tap" in command for command in commands))


if __name__ == "__main__":
    unittest.main()

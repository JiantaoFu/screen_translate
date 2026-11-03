"""Checks the regression runner without a connected Android device."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class StartTests(unittest.TestCase):
    def test_failed_install_stops_before_using_the_existing_app(self):
        git_bash = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
        bash = str(git_bash) if git_bash.exists() else shutil.which("bash")
        self.assertIsNotNone(bash, "Bash is required to test the emulator runner")
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="start-test-", dir=build) as directory:
            temporary = Path(directory)
            apk = temporary / "test.apk"
            apk.touch()
            calls = temporary / "adb-calls.txt"
            scripts = {
                "adb": (
                    '#!/usr/bin/env bash\n'
                    'printf "%s\\n" "$*" >> "$ADB_CALLS_LOG"\n'
                    'case "$*" in\n'
                    '  *" install -r "*) echo INSTALL_FAILED_INSUFFICIENT_STORAGE; exit 1;;\n'
                    '  *) echo "Service started, reset stopped flag";;\n'
                    'esac\n'
                ),
                "sleep": "#!/usr/bin/env bash\nexit 0\n",
                "python3": "#!/usr/bin/env bash\nexit 0\n",
            }
            for name, content in scripts.items():
                script = temporary / name
                script.write_text(content, encoding="utf-8", newline="\n")
                script.chmod(0o755)
            result = subprocess.run(
                [bash, str(ROOT / "tools/emulator/start.sh")],
                env={
                    **os.environ,
                    "PATH": str(temporary) + os.pathsep + os.environ["PATH"],
                    "ANDROID_SERIAL": "emulator-5554",
                    "APK": apk.as_posix(),
                    "OUT": (temporary / "output").as_posix(),
                    "ADB_CALLS_LOG": calls.as_posix(),
                    "SKIP_INSTALL": "0",
                },
                capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("INSTALL_FAILED_INSUFFICIENT_STORAGE", result.stdout)
            self.assertIn("FAIL start: APK installation failed", result.stdout)
            commands = calls.read_text().splitlines()
            self.assertEqual(len(commands), 1, commands)
            self.assertIn("install -r", commands[0])


if __name__ == "__main__":
    unittest.main()

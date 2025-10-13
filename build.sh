#!/bin/bash
set -xe
python3 scripts/convert_arb_to_json.py
flutter gen-l10n
#flutter build apk --verbose
#flutter build apk --release
#flutter build appbundle --release
#adb logcat AndroidRuntime:E *:S

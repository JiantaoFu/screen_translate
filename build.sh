#!/bin/bash
python3 scripts/convert_arb_to_json.py
flutter gen-l10n
flutter build apk --verbose

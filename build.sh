#!/bin/bash
set -e

print_usage() {
    echo "Usage: ./build.sh [OPTIONS]"
    echo "Options:"
    echo "  --bump [type]   Bump version (major, minor, patch, build)"
    echo "  --release       Build release APK and AppBundle"
    echo "  --help          Show this help message"
}

BUMP_TYPE=""
BUILD_RELEASE=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --bump)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                BUMP_TYPE=$2
                shift 2
            else
                BUMP_TYPE="build"
                shift 1
            fi
            ;;
        --release)
            BUILD_RELEASE=1
            shift 1
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            print_usage
            exit 1
            ;;
    esac
done

if [ -n "$BUMP_TYPE" ]; then
    echo "======================================"
    echo " Bumping Version ($BUMP_TYPE)..."
    echo "======================================"
    python3 scripts/bump_version.py "$BUMP_TYPE"
fi

echo "======================================"
echo " Preparing Localizations..."
echo "======================================"
python3 scripts/convert_arb_to_json.py
flutter gen-l10n

if [ $BUILD_RELEASE -eq 1 ]; then
    echo "======================================"
    echo " Building Release APK & AppBundle..."
    echo "======================================"
    flutter build apk --release
    flutter build appbundle --release
    echo "Release build completed successfully!"
fi

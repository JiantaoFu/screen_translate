#!/bin/bash
set -e

print_usage() {
    echo "Usage: ./build.sh [OPTIONS]"
    echo "Options:"
    echo "  --bump [type]   Bump version (major, minor, patch, build)"
    echo "  --release       Build release APK and AppBundle"
    echo "  --publish [track]  Test, build and upload to Google Play (default: internal;"
    echo "                  see python3 tools/release.py --help)"
    echo "  --help          Show this help message"
}

BUMP_TYPE=""
BUILD_RELEASE=0
PUBLISH_TRACK=""

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
        --publish)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                PUBLISH_TRACK=$2
                shift 2
            else
                PUBLISH_TRACK="internal"
                shift 1
            fi
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

if [ -n "$PUBLISH_TRACK" ]; then
    # release.py bumps, tests, builds, uploads and tags on its own, and
    # reverts the bump if nothing gets published.
    exec python3 tools/release.py --track "$PUBLISH_TRACK" ${BUMP_TYPE:+--bump "$BUMP_TYPE"}
fi

if [ -n "$BUMP_TYPE" ]; then
    echo "======================================"
    echo " Bumping Version ($BUMP_TYPE)..."
    echo "======================================"
    python3 scripts/bump_version.py "$BUMP_TYPE"
fi

echo "======================================"
echo " Preparing Localizations..."
echo "======================================"
flutter gen-l10n

if [ $BUILD_RELEASE -eq 1 ]; then
    echo "======================================"
    echo " Building Release APK & AppBundle..."
    echo "======================================"
    python3 tools/build.py apk
    python3 tools/build.py aab
    echo "Release build completed successfully!"
fi

# Screen Translate Release Notes

## Version 1.1.0

### Core Optimizations
- **Streaming Overlay Translation**: Introduced a waterfall rendering technique for translation results. Translated text is now rendered progressively on the screen as it is processed by the ML Kit translator, significantly reducing perceived latency.
- **Smart OCR Alignment Merging**: Upgraded the spatial merging algorithm in OCR processing. The system now uses true edge-to-edge (AABB) distance measurement and intelligent layout detection. It heavily penalizes diagonal gaps, effectively resolving issues where adjacent but distinct manga speech bubbles were incorrectly merged.

### UI / UX Enhancements
- **Double-Tap to Enlarge**: Added a "Double-Click to Enlarge" feature to translation overlays. Users can now double-tap any translation bubble to open a high-clarity, large-text floating popup, solving the readability issue for extremely long translated sentences without disrupting the original manga layout.
- **Strict Bounding Box Constraints**: Reverted the overlay height wrapper to `exactHeight` and reduced minimum auto-size constraints. This ensures translation text strictly conforms to the original text layout bounds without overlapping adjacent UI elements or images.
- **Advanced Settings**: Introduced a new "Advanced Settings" UI that allows users to manually tune the "OCR Merge Aggressiveness" multiplier (default 1.5x) via a slider, with settings persisted locally.

### Bug Fixes
- **ML Kit Crash Fix**: Resolved a fatal `IllegalStateException: Translator has been closed` issue. Background translation cancellations no longer forcibly close the native model instance, completely eliminating crashes during high-frequency scrolling or text changes.
- **Encoding Fix**: Fixed a Python conversion script error (`convert_arb_to_json.py`) on Windows environments by enforcing `utf-8` decoding for multi-language ARB files.

### Developer & Build Automation
- **Version Bumping Script**: Created `scripts/bump_version.py` for automated major, minor, patch, and build version increments.
- **Build Scripts**: Upgraded `build.bat` (Windows) and `build.sh` (Mac/Linux) with interactive menus for one-click localization generation, version bumping, APK, and AppBundle release compilation.


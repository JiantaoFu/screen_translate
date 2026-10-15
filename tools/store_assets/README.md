# Google Play screenshots

Real emulator captures of the app translating, laid out as store images.

| Step | Command | Output |
|---|---|---|
| 1. Letter the artwork | `python tools/store_assets/make_assets.py` | `assets/` |
| 2. Try lines (optional) | `[MODE=onDevice] [TARGET=zh] bash tools/store_assets/check_lines.sh <src> <runs> <img>` | logcat OCR → translation |
| 3. Capture | `bash tools/store_assets/capture.sh <en-US\|zh-CN\|ja-JP> [scene ...]` | `raw/<locale>/<scene>.png` |
| 4. Phone screenshots | `python tools/store_assets/compose.py --locale <locale>` | `build/play_store_assets/screens/<locale>/` (1080x1920) |
| 5. Feature graphic | `cd tools/store_assets && python feature.py --locale <locale>` | `build/play_store_assets/feature/<locale>.png` (1024x500) |

Scenes: manga, game, webtoon, chat (artwork shown in Google Photos with live
translation running) and home, settings, languages (the app's own screens,
UI in the listing's language via per-app locale). The Japanese listing has no
manga/game scene: that artwork is Japanese.

Setup: the phone AVD (4 GB RAM, see tools/emulator/README.md), the debug app,
and the ja-en and ko-en AI packs (`bash tools/emulator/push_ai_pack.sh opus-mt-ja-en`,
`... opus-mt-ko-en fp16`). The English listing uses AI mode; Chinese and
Japanese use Quick mode (AI packs only translate into English).

What goes wrong, and how the scripts avoid it:
- OCR/translation is not deterministic. Every line was tried several times;
  check every capture. One line per bubble (two-line bubbles get split).
  Quick mode into Chinese/Japanese needed simpler lines than AI mode into
  English, so the webtoon has a second lettering (`webtoon_screen_cjk.png`).
- Photos' toolbar labels get translated if they are on screen when
  translation starts, and those boxes can stay. capture.sh hides the toolbar
  first, then starts translation, then brings the same Photos screen back.
- Names and lone letters are "translated" (ゆき → "Mizuru"): the chat uses a
  Latin name and an avatar without an initial.
- The first Quick-mode translation into a new language downloads its model
  (can take minutes); rerun a scene that timed out.

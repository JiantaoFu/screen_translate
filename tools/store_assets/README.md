# Google Play screenshots

Real emulator captures of the app translating, laid out as store images.

| Step | Command | Output |
|---|---|---|
| 1. Letter the artwork | `python tools/store_assets/make_assets.py` | `assets/` |
| 2. Try lines (optional) | `[MODE=onDevice] [TARGET=zh] bash tools/store_assets/check_lines.sh <src> <runs> <img>` | logcat OCR → translation |
| 3. Capture | `bash tools/store_assets/capture.sh <en-US\|zh-CN\|ja-JP> [scene ...]` | `raw/<locale>/<scene>.png` |
| 4. Phone screenshots | `python tools/store_assets/compose.py --locale <locale>` | `build/play_store_assets/screens/<locale>/` (1080x1920) |
| 4b. Tablet screenshots | same capture.sh on the Pixel_Tablet AVD in portrait, then `compose.py --device tablet` | `raw/tablet/<locale>/` → `build/play_store_assets/tablet/<locale>/` (1440x2560) |
| 5. Feature graphic | `cd tools/store_assets && python feature.py --locale <locale>` | `build/play_store_assets/feature/<locale>.png` (1024x500) |
| 6. Upload | `python tools/store_assets/upload.py [--commit]` | dry run by default; needs the service account's store-listing permission |

Scenes: manga, game, webtoon, chat (artwork shown in Google Photos with live
translation running) and home, settings, languages (the app's own screens,
UI in the listing's language via per-app locale). The manga and game artwork
is Japanese, so the Japanese listing shows English lettering of it
(`manga_en.png`, `tavern_en_lines.png`) translated into Japanese.

Common changes:
- Captions only: edit `SHOTS` in compose.py (feature graphic: `TEXT` in feature.py),
  rerun step 4/4b/5, then upload. No emulator needed.
- One scene: rerun step 3 for that scene only (`capture.sh ja-JP manga`),
  check the capture, then `compose.py --locale ja-JP --only manga` (and the
  tablet), then upload.
- A new listing language: add it to `FONTS` and every `SHOTS` entry in
  compose.py, `TEXT` in feature.py, the scene list and target in capture.sh,
  and the locale list in upload.py.
- The raw captures are committed, so steps 4-6 can always be rerun alone.
  upload.py replaces all images of each listed locale and device type.

Setup: the phone AVD (4 GB RAM, see tools/emulator/README.md) or the
Pixel_Tablet AVD (2 GB; raise hw.ramSize in its config.ini if AI mode gets
killed, and put it back afterwards), the debug app,
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
- Tablet only: the tavern's menu icon (three bars) read as the kanji 三
  ("(M)"), a lone capital I as "|", a vertical ！ as I ("…城市我"), and the
  name tag merged with the first line; the artwork/lines were adjusted
  (icon as dots, manga_cjk.png, "Let me buy", dialogue moved down).
- Android 15 (tablet AVD) drops the app's accessibility service on
  force-stop, and shows a "Viewing full screen" tip once; capture.sh
  re-enables the service and pre-confirms the tip.
- The first Quick-mode translation into a new language downloads its model
  (can take minutes); rerun a scene that timed out.

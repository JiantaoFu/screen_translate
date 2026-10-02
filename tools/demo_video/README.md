# Store demo video

Two cuts of the same real screen recording of the app on the Android
emulator (AI mode, Japanese → English), about 24 s each:
- `demo_video_30s.mp4`: 16:9 (1920x1080) for Google Play and YouTube;
- `demo_video_30s_vertical.mp4`: 9:16 (1080x1920) for Shorts, Reels and
  TikTok (a 16:9 video is shown there as a thin strip).

The editing adds only captions, an intro and an outro, and cuts dead time.
Every page still shows the original text and the "…" placeholder before
its translation. The system screen-sharing dialog is played at 3x (about
2 s). The brand is written "Screen Translate" (the app's label).

| Path | What |
|---|---|
| `assets/original/` | The artwork as supplied, with its original lines |
| `make_assets.py` | Re-letters the artwork into `assets/` with short lines that OCR and translate correctly |
| `assets/` | The images used in the recording, and `translations.txt` (what each says) |
| `recordings/portrait_manga.mp4` | Raw screenrecord (1080x2400): starting translation in the app, then manga 1 and manga 2 in Google Photos |
| `recordings/landscape_game.mp4` | Raw screenrecord (2400x1080): the game dialogue in landscape |
| `record.sh` | Makes new recordings on the emulator |
| `contact_sheet.py` | Timestamped frame grid of a recording, used to pick cut points |
| `edit.py` | Turns the recordings into the videos: default 16:9 30 s cut, `--vertical` 9:16, `--full` the longer real-speed cut |

## Re-render from the committed recordings

To change captions, order or timing, edit `CARDS` or `CUTS_30` in `edit.py`,
then run:

```
python tools/demo_video/edit.py              # → build/play_store_assets/demo_video_30s.mp4
python tools/demo_video/edit.py --vertical   # → build/play_store_assets/demo_video_30s_vertical.mp4
python tools/demo_video/edit.py --full       # → build/play_store_assets/demo_video.mp4
```

This needs ffmpeg and Pillow, plus the Segoe UI fonts from Windows. When the
new videos are approved, copy them over the ones in this folder.

## Choosing the text in the images

The first demo used the supplied lines and showed wrong translations:
ML Kit read 「ロボットが」 as 「ロボットか」 (か = "or"), so the robot and the
city swapped roles, and 勇者/魔王 became "The bravest man"/"Witch King".
`make_assets.py` keeps the artwork and draws new lines in a clean bold
Gothic face. Each line was tried on the emulator several times in AI mode,
and only lines that came back right every time were kept:
- が/か (dakuten) is unreliable: manga 1 uses は instead.
- Lines with 助けて lost "Help" in translation.
- Some kanji were misread at smaller sizes (闇 → 商, 倒 → 料); bigger text
  fixed 倒. Vertical hiragana (たおす) read worse than kanji.
- The game text must start below the name tag and right of the box border,
  or OCR merges them ("村長上北の塔…" → "the tower in Xinjinoh").

To try new lines, render variants into the artwork (see `make_assets.py`),
show each in Photos on the emulator with live translation running, and read
the `[ONNX] Translating` / `Done` lines in logcat.

## Record again (new app version or new images)

1. Set up the emulator as described in `tools/emulator/README.md`.
   **Set `hw.ramSize=4096`** in `~/.android/avd/Medium_Phone.avd/config.ini`
   and cold-boot it. At 2 GB, AI mode plus screenrecord gets the app killed
   by the low-memory killer.
2. Build and install: `python tools/build.py emulator --install emulator-5554`.
3. Run `bash tools/demo_video/record.sh` (about 2.5 minutes). It:
   - downloads the ja→en AI pack on the host and pushes it into the app, if
     it is missing. The in-app download times out on the emulator's network;
   - pushes `assets/*.png` into the gallery (always, so a re-lettered image
     with the same name replaces the old one);
   - switches the status bar to demo mode (10:00, full battery);
   - sets Japanese → English in AI mode (`tools/emulator/set_prefs.py`),
     records the portrait clip and then the landscape clip;
   - restores portrait and the real status bar. (`tools/emulator/start.sh`
     pins its own language pair, so the regression doesn't depend on this.)

   The clips go to `build/demo_video/recordings/`.
4. Find the new cut points:
   ```
   python tools/demo_video/contact_sheet.py build/demo_video/recordings/portrait_manga.mp4 15 45 4
   python tools/demo_video/contact_sheet.py build/demo_video/recordings/landscape_game.mp4 0 12 4
   ```
   For each page, note when it goes fullscreen, when "…" appears, and when
   the translation appears. Update `CUTS_30` and `CUTS_FULL`.
5. Copy the clips into `recordings/`, run `edit.py` (with and without
   `--vertical`), and check frames from every segment before replacing the
   videos in this folder.

Things to know:
- screenrecord writes a frame only when the screen changes, so a clip ends
  on its last change (the translation appearing). `edit.py` holds that last
  frame. A 1 frame/s contact sheet can miss the last change, so use 4–8
  frames/s near the end.
- Photos keeps showing the previous image unless it is force-stopped first.
  Swiping moves to unrelated photos in the gallery.
- On this AVD, locking rotation with `user_rotation` didn't hold. The script
  keeps auto-rotate on and turns the virtual sensor with `adb emu rotate`,
  while our app is in front (the launcher is portrait-only). It reads the
  orientation from `dumpsys window displays` (`cur=WxH`): the first
  `mDisplayRotation` in `dumpsys window` can be another window's stale value.

## Problems found while making it (2026-10-01, 1.2.2+12)

Fixed in 1.2.3:
- Vertical manga bubbles were translated column by column (the merge step's
  background sample reached outside the bubble).
- A one-block vertical bubble had its columns ordered left to right.
- JA/ZH line breaks reached the translator as separate fragments.
- Box text split words across lines ("des / troyed").
- The translation mode reset to Quick on every launch.
- The status bar clock and sharing timer were OCR'd in portrait.
- Text already in the target language was translated (our own UI, "Trash"
  → "Tash", Photos' "Oct 1"). Now only text in the source language's script
  is translated, and nothing is captured while our own app is in front. A
  frame of our own screen was also the source of the "status bar" box seen
  after rotating into landscape.
- AI pack downloads failed on slow networks (a fixed 3-minute cap per file,
  no resume). They now resume with HTTP Range requests and fail only on a
  30 s stall; the 413 MB ja→en pack downloaded in the app on the emulator in
  about 15 minutes. Settings showed "~50 MB each"; it now shows each pack's
  real size (230–553 MB).

Still open:
- AI mode uses about 0.9 GB PSS with ja→en loaded (encoder, decoder and
  decoder_with_past are all resident) and was killed on a 2 GB emulator.
  Turning off the ORT arena made no difference; a real fix needs a merged
  decoder export.
- ML Kit sometimes drops dakuten (が → か), which makes the manga 1
  translation slightly off.

# Store demo video

`demo_video_30s.mp4` is the store demo approved on 2026-10-01 (26.7 s,
1920x1080). It is a **real screen recording** of the app on the Android
emulator in AI mode, translating Japanese into English. The editing adds
only captions, an intro and an outro, and cuts dead time. Every page still
shows the original text and the "…" placeholder before its translation.

| Path | What |
|---|---|
| `assets/` | The three Japanese source images and `translations.txt` (the reference English) |
| `recordings/portrait_manga.mp4` | Raw screenrecord (1080x2400): starting translation in the app, then manga 1 and manga 2 in Google Photos |
| `recordings/landscape_game.mp4` | Raw screenrecord (2400x1080): the game dialogue in landscape |
| `record.sh` | Makes new recordings on the emulator |
| `contact_sheet.py` | Timestamped frame grid of a recording, used to pick cut points |
| `edit.py` | Turns the recordings into the video. The default is the 30 s cut; `--full` gives the 56 s real-speed cut |
| `demo_video_30s.mp4` | The approved output |

## Re-render from the committed recordings

To change captions, order or timing, edit `CARDS` or `CUTS_30` in `edit.py`,
then run:

```
python tools/demo_video/edit.py          # → build/play_store_assets/demo_video_30s.mp4
python tools/demo_video/edit.py --full   # → build/play_store_assets/demo_video.mp4
```

This needs ffmpeg and Pillow, plus the Segoe UI fonts from Windows. When the
new video is approved, copy it over `demo_video_30s.mp4`.

## Record again (new app version or new images)

1. Set up the emulator as described in `tools/emulator/README.md`.
   **Set `hw.ramSize=4096`** in `~/.android/avd/Medium_Phone.avd/config.ini`
   and cold-boot it. At 2 GB, AI mode plus screenrecord gets the app killed
   by the low-memory killer.
2. Build and install: `python tools/build.py emulator --install emulator-5554`.
3. Run `bash tools/demo_video/record.sh` (about 2.5 minutes). It:
   - downloads the ja→en AI pack on the host and pushes it into the app, if
     it is missing. The in-app download times out on the emulator's network;
   - pushes the images into the gallery;
   - switches the status bar to demo mode (10:00, full battery);
   - selects AI mode, records the portrait clip and then the landscape clip;
   - restores portrait, the real status bar, and the previous translation
     mode (the regression scripts expect Quick).

   The clips go to `build/demo_video/recordings/`.
4. Find the new cut points:
   ```
   python tools/demo_video/contact_sheet.py build/demo_video/recordings/portrait_manga.mp4 15 45 4
   python tools/demo_video/contact_sheet.py build/demo_video/recordings/landscape_game.mp4 0 12 4
   ```
   For each page, note when it goes fullscreen, when "…" appears, and when
   the translation appears. Update `CUTS_30` and `CUTS_FULL`.
5. Copy the clips into `recordings/`, run `edit.py`, and check frames from
   every segment before replacing `demo_video_30s.mp4`.

Things to know:
- screenrecord writes a frame only when the screen changes, so a clip ends
  on its last change (the translation appearing). `edit.py` holds that last
  frame. A 1 frame/s contact sheet can miss the last change, so use 4–8
  frames/s near the end.
- Photos keeps showing the previous image unless it is force-stopped first.
  Swiping moves to unrelated photos in the gallery.
- On this AVD, locking rotation with `user_rotation` didn't hold. The script
  keeps auto-rotate on and turns the virtual sensor with `adb emu rotate`.

## Problems found while making it (2026-10-01, 1.2.2+12)

Fixed in ae826fc:
- Vertical manga bubbles were translated column by column (the merge step's
  background sample reached outside the bubble).
- A one-block vertical bubble had its columns ordered left to right.
- JA/ZH line breaks reached the translator as separate fragments.
- Box text split words across lines ("des / troyed").
- The translation mode reset to Quick on every launch.
- The status bar clock and sharing timer were OCR'd in portrait.

Still open:
- The AI pack download times out on slow networks, and Settings says
  "~50 MB each" when ja→en is 413 MB.
- AI mode uses about 1.2 GB (762 MB RSS plus 497 MB swap) and gets killed on
  2 GB devices.
- Text already in English is translated too, including our own UI ("Trash"
  → "Tash"). The 30 s cut skips the moment where our home screen gets boxed.
- In landscape the status bar can still be OCR'd: a later run translated the
  signal icons into "- Command 36il.".
- A tiny stale box from the Photos toolbar ("Oct 1") stays after the toolbar
  hides. It is visible top-left in the game shot.
- ML Kit sometimes drops dakuten (が → か), which makes the manga 1
  translation slightly off.

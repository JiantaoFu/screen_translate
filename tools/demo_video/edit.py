"""Edit the emulator screen recordings into the store demo video.

Usage:
  python tools/demo_video/edit.py              # 30s cut, 16:9 (Play / YouTube)
  python tools/demo_video/edit.py --vertical   # 30s cut, 9:16 (Shorts / Reels / TikTok)
  python tools/demo_video/edit.py --full       # longer cut at real speed (16:9)

Inputs are the recordings in tools/demo_video/recordings/ (made by
record.sh). The cut points below are seconds in THOSE files: after a new
recording, find the new ones with contact_sheet.py and update CUTS_*.
Output goes to build/play_store_assets/.

Only dead time is cut (Photos loading, toolbars, waiting); each page still
shows the original text and the "…" placeholder before its translation, so
the video doesn't pretend translation is instant. The system consent dialog
is played fast: viewers don't need to read it.
"""
import argparse
import os
import subprocess
from dataclasses import dataclass

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
REC = os.path.join(HERE, 'recordings')
PORTRAIT = os.path.join(REC, 'portrait_manga.mp4')    # 1080x2400: start + manga 1 + manga 2
LANDSCAPE = os.path.join(REC, 'landscape_game.mp4')   # 2400x1080: game dialogue
TMP = os.path.join(REPO, 'build', 'demo_video')
OUT_DIR = os.path.join(REPO, 'build', 'play_store_assets')
ICON = os.path.join(REPO, 'android', 'app', 'src', 'main', 'res', 'playstore-icon.png')

BRAND = 'Screen Translate'   # the app's name (android:label); two words

# (start, end, speed) pieces of a recording, joined back to back; then the
# last frame is held for `hold` seconds. screenrecord writes frames only when
# the screen changes, so a clip ends on its last change (the translation).
# Timings for the 2026-10-01 recordings (re-lettered assets):
#   portrait: Translate Screen tap 4.0, consent dialog 4.5-10.2, floating
#   button 11.0; manga 1 fullscreen 17.5, "…" 20.5, translation 23.5;
#   manga 2 fullscreen 37.0, "…" 39.6, translation 40.1 (clip ends 40.30)
#   landscape: game fullscreen, first translation 8.25 is re-read (original
#   shows 8.5-9.5), "…" 9.75, final translation 10.5 (clip ends 10.81)
CUTS_30 = [
    # card, recording, pieces, hold
    ('manga', PORTRAIT, [(17.5, 19.0, 1), (22.5, 26.0, 1)], 0.5),
    ('setup', PORTRAIT, [(3.2, 4.4, 1), (4.4, 10.2, 3.0), (10.2, 12.5, 1)], 0.3),
    ('next', PORTRAIT, [(37.0, 38.0, 1), (39.5, 40.30, 1)], 2.8),
    ('game', LANDSCAPE, [(8.5, 10.81, 1)], 3.0),
]
CUTS_FULL = [
    ('setup', PORTRAIT, [(0.0, 4.4, 1), (4.4, 10.2, 3.0), (10.2, 14.0, 1)], 0.3),
    ('manga_full', PORTRAIT, [(15.0, 40.30, 1)], 4.0),
    ('game', LANDSCAPE, [(8.5, 10.81, 1)], 5.0),
]

BOLD, SEMI, REG = 'C:/Windows/Fonts/segoeuib.ttf', 'C:/Windows/Fonts/seguisb.ttf', 'C:/Windows/Fonts/segoeui.ttf'
WHITE, SUB, ACCENT = (255, 255, 255), (203, 213, 225), (59, 130, 246)
FOOT = 'Real screen recording · Android emulator · AI mode (on-device)'

CARDS = {
    # name: (recording orientation, pill, title, body)
    'manga': ('portrait', 'Manga', 'Translated right on the page',
              'Japanese → English over the speech bubbles, even vertical text.'),
    'setup': ('portrait', 'One tap', 'Start live translation',
              'Tap Translate Screen and allow screen sharing. A floating button stays on top.'),
    'next': ('portrait', 'Any app', 'Keeps up as you read', 'Open the next page and it is translated too.'),
    'manga_full': ('portrait', 'Manga', 'Read manga in any app',
                   'Translations appear right over the speech bubbles, even for vertical text.'),
    'game': ('landscape', 'Games', 'Works in full-screen landscape games too', None),
}


@dataclass
class Layout:
    """Frame size and where each kind of recording sits in it."""
    w: int
    h: int
    portrait_box: tuple    # x, y, w, h of a 1080x2400 recording
    landscape_box: tuple   # x, y, w, h of a 2400x1080 recording
    vertical: bool


WIDE = Layout(1920, 1080, (1240, 30, 450, 1000), (120, 200, 1680, 756), vertical=False)
# 9:16: caption block on top, the recording as large as fits below it.
TALL = Layout(1080, 1920, (231, 450, 617, 1370), (40, 700, 1000, 450), vertical=True)


def font(path, size):
    return ImageFont.truetype(path, size)


def background(lay):
    im = Image.new('RGB', (lay.w, lay.h))
    d = ImageDraw.Draw(im)
    for y in range(lay.h):
        k = y / lay.h
        d.line([(0, y), (lay.w, y)], fill=(int(10 + 18 * k), int(17 + 20 * k), int(40 + 25 * k)))
    glow = Image.new('RGBA', (lay.w, lay.h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([lay.w * 0.45, -300, lay.w * 1.2, 700], fill=(59, 130, 246, 50))
    return Image.alpha_composite(im.convert('RGBA'), glow.filter(ImageFilter.GaussianBlur(160))).convert('RGB')


def wrap(d, text, f, maxw):
    lines, cur = [], ''
    for w in text.split():
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=f) <= maxw or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = w
    return lines + [cur]


def pill(d, x, y, text, size=28):
    f = font(BOLD, size)
    tw = d.textlength(text, font=f)
    h = int(size * 1.8)
    d.rounded_rectangle([x, y, x + tw + 44, y + h], radius=h // 2, fill=ACCENT)
    d.text((x + 22, y + (h - size * 1.35) / 2), text, font=f, fill=WHITE)
    return tw + 44


def centered(d, lay, y, text, f, fill):
    d.text(((lay.w - d.textlength(text, font=f)) / 2, y), text, font=f, fill=fill)


def footer(d, lay):
    f = font(REG, 24)
    centered(d, lay, lay.h - 46, FOOT, f, (148, 163, 184))


def bezel(d, box):
    x, y, w, h = box
    d.rounded_rectangle([x - 16, y - 16, x + w + 16, y + h + 16], radius=40,
                        fill=(22, 24, 30), outline=(70, 76, 90), width=3)


def card(lay, name, path):
    orient, tag, title, body = CARDS[name]
    box = lay.portrait_box if orient == 'portrait' else lay.landscape_box
    im = background(lay)
    d = ImageDraw.Draw(im)
    bezel(d, box)
    if lay.vertical:
        # Caption block centred above the recording.
        f_tag, f_title, f_body = 34, font(BOLD, 62), font(SEMI, 36)
        y = 60 if orient == 'portrait' else 300
        tw = d.textlength(tag, font=font(BOLD, f_tag)) + 44
        pill(d, (lay.w - tw) / 2, y, tag, f_tag)
        y += 85
        for line in wrap(d, title, f_title, lay.w - 120):
            centered(d, lay, y, line, f_title, WHITE)
            y += 78
        if body:
            y += 10
            for line in wrap(d, body, f_body, lay.w - 140):
                centered(d, lay, y, line, f_body, SUB)
                y += 50
    elif orient == 'portrait':
        pill(d, 170, 300, tag)
        y = 390
        for line in wrap(d, title, font(BOLD, 58), 900):
            d.text((170, y), line, font=font(BOLD, 58), fill=WHITE)
            y += 74
        y += 20
        for line in wrap(d, body, font(SEMI, 34), 880):
            d.text((170, y), line, font=font(SEMI, 34), fill=SUB)
            y += 48
    else:
        pw = pill(d, 120, 60, tag)
        d.text((120 + pw + 26, 58), title, font=font(BOLD, 44), fill=WHITE)
    footer(d, lay)
    im.save(path)


def title_card(lay, sub, button, path):
    im = background(lay).convert('RGBA')
    d = ImageDraw.Draw(im)
    top = (lay.h - 640) // 2
    icon = Image.open(ICON).convert('RGBA').resize((220, 220), Image.LANCZOS)
    mask = Image.new('L', icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, 219, 219], radius=44, fill=255)
    im.paste(icon, ((lay.w - 220) // 2, top), mask)
    title_size = 92 if not lay.vertical else 96
    centered(d, lay, top + 270, BRAND, font(BOLD, title_size), WHITE)
    f_sub = font(SEMI, 44 if not lay.vertical else 40)
    y = top + 400
    for line in wrap(d, sub, f_sub, lay.w - 120):
        centered(d, lay, y, line, f_sub, SUB)
        y += 58
    if button:
        f = font(BOLD, 36)
        tw = d.textlength(button, font=f)
        x0 = (lay.w - tw) / 2 - 40
        by = y + 70
        d.rounded_rectangle([x0, by, x0 + tw + 80, by + 80], radius=40, fill=ACCENT)
        d.text((x0 + 40, by + 14), button, font=f, fill=WHITE)
    im.convert('RGB').save(path)


def ffmpeg(args):
    subprocess.run(['ffmpeg', '-v', 'error', '-y'] + args, check=True)


ENC = ['-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-r', '30', '-an']


def still(png, dur, out):
    ffmpeg(['-loop', '1', '-t', str(dur), '-i', png, '-vf',
            f'fade=t=in:st=0:d=0.4,fade=t=out:st={dur - 0.4}:d=0.4'] + ENC + [out])


def segment(card_png, clip, pieces, hold, box, out):
    x, y, w, h = box
    parts, labels = [], []
    for i, (a, b, speed) in enumerate(pieces):
        parts.append(f'[1:v]trim={a}:{b},setpts=(PTS-STARTPTS)/{speed},fps=30,scale={w}:{h},setsar=1[p{i}]')
        labels.append(f'[p{i}]')
    dur = sum((b - a) / s for a, b, s in pieces) + hold
    vf = (';'.join(parts) + ';' + ''.join(labels) + f'concat=n={len(pieces)}:v=1:a=0,'
          f'tpad=stop_mode=clone:stop_duration={hold}[v];'
          f'[0:v][v]overlay={x}:{y}:shortest=1,fade=t=in:st=0:d=0.3,fade=t=out:st={dur - 0.3}:d=0.3')
    ffmpeg(['-loop', '1', '-t', f'{dur:.3f}', '-i', card_png, '-i', clip, '-filter_complex', vf] + ENC + [out])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--full', action='store_true', help='longer cut at real speed instead of the 30s cut')
    ap.add_argument('--vertical', action='store_true', help='9:16 (1080x1920) for Shorts / Reels / TikTok')
    args = ap.parse_args()
    lay = TALL if args.vertical else WIDE
    tag = ('full' if args.full else '30s') + ('_vertical' if args.vertical else '')
    work = os.path.join(TMP, tag)
    os.makedirs(work, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    t = lambda n: os.path.join(work, n)

    cuts = CUTS_FULL if args.full else CUTS_30
    intro, outro = (3.0, 3.5) if args.full else (1.5, 3.0)
    title_card(lay, 'Translate anything on your screen, instantly', None, t('intro.png'))
    title_card(lay, 'Manga · Webtoons · Games · Any app', 'Get it on Google Play', t('outro.png'))

    segs = [t('seg0.mp4')]
    still(t('intro.png'), intro, segs[0])
    for i, (name, clip, pieces, hold) in enumerate(cuts, 1):
        card(lay, name, t(f'card_{name}.png'))
        box = lay.portrait_box if CARDS[name][0] == 'portrait' else lay.landscape_box
        segs.append(t(f'seg{i}.mp4'))
        segment(t(f'card_{name}.png'), clip, pieces, hold, box, segs[-1])
    segs.append(t(f'seg{len(segs)}.mp4'))
    still(t('outro.png'), outro, segs[-1])

    name = 'demo_video' if args.full else 'demo_video_30s'
    out = os.path.join(OUT_DIR, name + ('_vertical' if args.vertical else '') + '.mp4')
    with open(t('concat.txt'), 'w') as fh:
        fh.writelines(f"file '{s}'\n" for s in segs)
    ffmpeg(['-f', 'concat', '-safe', '0', '-i', t('concat.txt'), '-c', 'copy', '-movflags', '+faststart', out])
    print(out)


if __name__ == '__main__':
    main()

"""Edit the emulator screen recordings into the store demo video.

Usage:
  python tools/demo_video/edit.py            # 30s cut (the one we ship)
  python tools/demo_video/edit.py --full     # 56s cut, every step at real speed

Inputs are the recordings in tools/demo_video/recordings/ (made by
record.sh). The cut points below are seconds in THOSE files: after a new
recording, find the new ones with contact_sheet.py and update CUTS_*.
Output goes to build/play_store_assets/.

Only dead time is cut (Photos loading, toolbar, waiting). Each page still
shows the original text and the "…" placeholder before its translation,
so the video doesn't pretend translation is instant.
"""
import argparse
import os
import subprocess

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
REC = os.path.join(HERE, 'recordings')
PORTRAIT = os.path.join(REC, 'portrait_manga.mp4')    # 1080x2400: start + manga 1 + manga 2
LANDSCAPE = os.path.join(REC, 'landscape_game.mp4')   # 2400x1080: game dialogue
TMP = os.path.join(REPO, 'build', 'demo_video')
OUT_DIR = os.path.join(REPO, 'build', 'play_store_assets')
ICON = os.path.join(REPO, 'android', 'app', 'src', 'main', 'res', 'playstore-icon.png')

# (start, end, speed) pieces of a recording, joined back to back; then the
# last frame is held for `hold` seconds. screenrecord writes frames only when
# the screen changes, so a clip ends on its last change (the translation).
CUTS_30 = [
    # card, recording, pieces, hold
    ('manga', PORTRAIT, [(17.75, 19.25, 1), (22.5, 26.5, 1)], 0.5),      # manga 1: original, "…" 22.75, translation 23.5
    ('setup', PORTRAIT, [(2.0, 13.6, 2.0)], 0.6),                         # Translate Screen → consent → floating button
    ('next', PORTRAIT, [(37.75, 39.0, 1), (39.5, 40.51, 1)], 2.8),        # manga 2: "…" 39.75, translation 40.25
    ('game', LANDSCAPE, [(5.25, 6.5, 1), (6.9, 8.69, 1)], 3.0),           # game: "…" 7.0, translation 8.5
]
CUTS_FULL = [
    ('setup', PORTRAIT, [(0.0, 13.6, 1.4)], 0.6),
    ('manga_full', PORTRAIT, [(15.75, 40.51, 1)], 4.0),                   # 13.75-15.5 skipped: our own UI got boxed (open issue)
    ('game', LANDSCAPE, [(2.9, 8.69, 1)], 5.0),
]

W, H = 1920, 1080
BOLD, SEMI, REG = 'C:/Windows/Fonts/segoeuib.ttf', 'C:/Windows/Fonts/seguisb.ttf', 'C:/Windows/Fonts/segoeui.ttf'
WHITE, SUB, ACCENT = (255, 255, 255), (203, 213, 225), (59, 130, 246)
FOOT = 'Real screen recording · Android emulator · AI mode (on-device)'

# Where the recordings sit on the 1920x1080 frame.
PORTRAIT_BOX = (1240, 30, 450, 1000)     # x, y, w, h (1080x2400 scaled)
LANDSCAPE_BOX = (120, 200, 1680, 756)    # (2400x1080 scaled)

CARDS = {
    # name: (layout, pill, title, body)
    'manga': ('portrait', 'Manga', 'Translated right on the page',
              'Japanese → English over the speech bubbles, even vertical text.'),
    'setup': ('portrait', 'One tap', 'Start live translation',
              'Tap Translate Screen and allow screen sharing. A floating button stays on top.'),
    'next': ('portrait', 'Any app', 'Keeps up as you read', 'Open the next page and it is translated too.'),
    'manga_full': ('portrait', 'Manga', 'Read manga in any app',
                   'Translations appear right over the speech bubbles, even for vertical text.'),
    'game': ('landscape', 'Games', 'Works in full-screen landscape games too', None),
}


def font(path, size):
    return ImageFont.truetype(path, size)


def background():
    im = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(im)
    for y in range(H):
        k = y / H
        d.line([(0, y), (W, y)], fill=(int(10 + 18 * k), int(17 + 20 * k), int(40 + 25 * k)))
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([W * 0.45, -300, W * 1.2, 700], fill=(59, 130, 246, 50))
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


def pill(d, x, y, text):
    f = font(BOLD, 28)
    tw = d.textlength(text, font=f)
    d.rounded_rectangle([x, y, x + tw + 44, y + 50], radius=25, fill=ACCENT)
    d.text((x + 22, y + 6), text, font=f, fill=WHITE)
    return tw + 44


def footer(d):
    f = font(REG, 24)
    d.text(((W - d.textlength(FOOT, font=f)) / 2, H - 46), FOOT, font=f, fill=(148, 163, 184))


def bezel(d, box):
    x, y, w, h = box
    d.rounded_rectangle([x - 16, y - 16, x + w + 16, y + h + 16], radius=40,
                        fill=(22, 24, 30), outline=(70, 76, 90), width=3)


def card(name, path):
    layout, tag, title, body = CARDS[name]
    im = background()
    d = ImageDraw.Draw(im)
    if layout == 'portrait':
        bezel(d, PORTRAIT_BOX)
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
        bezel(d, LANDSCAPE_BOX)
        pw = pill(d, 120, 60, tag)
        d.text((120 + pw + 26, 58), title, font=font(BOLD, 44), fill=WHITE)
    footer(d)
    im.save(path)


def title_card(title, sub, button, path):
    im = background().convert('RGBA')
    d = ImageDraw.Draw(im)
    icon = Image.open(ICON).convert('RGBA').resize((220, 220), Image.LANCZOS)
    mask = Image.new('L', icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, 219, 219], radius=44, fill=255)
    im.paste(icon, ((W - 220) // 2, 210), mask)
    for text, f, y, col in [(title, font(BOLD, 92), 480, WHITE), (sub, font(SEMI, 44), 610, SUB)]:
        d.text(((W - d.textlength(text, font=f)) / 2, y), text, font=f, fill=col)
    if button:
        f = font(BOLD, 36)
        tw = d.textlength(button, font=f)
        x0 = (W - tw) / 2 - 40
        d.rounded_rectangle([x0, 740, x0 + tw + 80, 820], radius=40, fill=ACCENT)
        d.text((x0 + 40, 754), button, font=f, fill=WHITE)
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
    ap.add_argument('--full', action='store_true', help='56s cut at real speed instead of the 30s cut')
    args = ap.parse_args()
    os.makedirs(TMP, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    t = lambda n: os.path.join(TMP, n)

    cuts = CUTS_FULL if args.full else CUTS_30
    intro, outro = (3.0, 3.5) if args.full else (1.5, 3.0)
    title_card('ScreenTranslate', 'Translate anything on your screen, instantly', None, t('intro.png'))
    title_card('ScreenTranslate', 'Manga · Webtoons · Games · Any app', 'Get it on Google Play', t('outro.png'))

    segs = [t('seg0.mp4')]
    still(t('intro.png'), intro, segs[0])
    for i, (name, clip, pieces, hold) in enumerate(cuts, 1):
        card(name, t(f'card_{name}.png'))
        box = PORTRAIT_BOX if CARDS[name][0] == 'portrait' else LANDSCAPE_BOX
        segs.append(t(f'seg{i}.mp4'))
        segment(t(f'card_{name}.png'), clip, pieces, hold, box, segs[-1])
    segs.append(t(f'seg{len(segs)}.mp4'))
    still(t('outro.png'), outro, segs[-1])

    out = os.path.join(OUT_DIR, 'demo_video.mp4' if args.full else 'demo_video_30s.mp4')
    with open(t('concat.txt'), 'w') as fh:
        fh.writelines(f"file '{s}'\n" for s in segs)
    ffmpeg(['-f', 'concat', '-safe', '0', '-i', t('concat.txt'), '-c', 'copy', '-movflags', '+faststart', out])
    print(out)


if __name__ == '__main__':
    main()

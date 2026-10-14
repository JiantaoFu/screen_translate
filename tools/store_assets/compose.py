"""Compose Google Play screenshots from raw emulator captures.

Usage: python tools/store_assets/compose.py [--locale en-US] [--only 1,3]

Inputs: raw 1080x2400 captures in tools/store_assets/raw/<locale>/<shot>.png
(made by capture.sh). Output: build/play_store_assets/screens/<locale>/NN_<shot>.png
at 1080x1920 (9:16, Play's size for promotable phone screenshots).

Each shot: a headline and a subline on top, the real capture in a phone
bezel, and optionally a magnified callout of the translated text (in a
store thumbnail the overlay text itself is too small to read).
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
RAW = os.path.join(HERE, 'raw')
OUT = os.path.join(REPO, 'build', 'play_store_assets', 'screens')

W, H = 1080, 1920
WHITE, SUB, ACCENT = (255, 255, 255), (203, 213, 225), (59, 130, 246)
FONTS = {
    'en-US': ('C:/Windows/Fonts/segoeuib.ttf', 'C:/Windows/Fonts/seguisb.ttf'),
    'zh-CN': ('C:/Windows/Fonts/msyhbd.ttc', 'C:/Windows/Fonts/msyh.ttc'),
    'ja-JP': ('C:/Windows/Fonts/YuGothB.ttc', 'C:/Windows/Fonts/YuGothM.ttc'),
}

# Phone screen (1080x2400 capture) placement inside the 1080x1920 canvas.
PHONE = (231, 450, 617, 1370)   # x, y, w, h

# shot id → captions per locale and an optional callout: the region of the
# raw capture (x0, y0, x1, y1) to magnify, and where on the canvas to put it.
SHOTS = {
    'manga': dict(
        callout=dict(crop=(700, 120, 1080, 560), at='right', y=760),
        text={'en-US': ('Translate manga right on the page', 'Even vertical speech bubbles'),
              'zh-CN': ('漫画对白，原地翻译', '竖排气泡也能读懂'),
              'ja-JP': ('マンガのセリフをその場で翻訳', '縦書きの吹き出しにも対応')}),
    'game': dict(
        callout=dict(crop=(20, 1730, 1060, 2080), at='center', y=1060, width=860),
        text={'en-US': ('Play games in any language', 'Dialogue translated as you play'),
              'zh-CN': ('外语游戏，边玩边懂', '对话实时翻译'),
              'ja-JP': ('海外ゲームもそのまま遊べる', 'セリフをリアルタイムで翻訳')}),
    'webtoon': dict(
        callout=dict(crop=(20, 110, 520, 390), at='left', y=820),
        text={'en-US': ('Read webtoons as you scroll', 'Korean, Japanese, Chinese and more'),
              'zh-CN': ('条漫边滑边翻译', '韩语、日语等多种语言'),
              'ja-JP': ('Webtoonもスクロールしながら翻訳', '韓国語・英語など多言語対応')}),
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
    ImageDraw.Draw(glow).ellipse([W * 0.35, -400, W * 1.4, 700], fill=(59, 130, 246, 60))
    return Image.alpha_composite(im.convert('RGBA'), glow.filter(ImageFilter.GaussianBlur(170))).convert('RGB')


def wrap(d, text, f, maxw):
    """Word wrap for spaced scripts; character wrap for CJK."""
    if ' ' not in text:
        lines, cur = [], ''
        for ch in text:
            if d.textlength(cur + ch, font=f) > maxw and cur:
                lines.append(cur)
                cur = ch
            else:
                cur += ch
        return lines + [cur]
    lines, cur = [], ''
    for w in text.split():
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=f) <= maxw or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = w
    return lines + [cur]


def centered(d, y, text, f, fill):
    d.text(((W - d.textlength(text, font=f)) / 2, y), text, font=f, fill=fill)


def rounded(im, r):
    m = Image.new('L', im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, im.width - 1, im.height - 1], radius=r, fill=255)
    return m


def compose(locale, shot, raw_path, out_path):
    spec = SHOTS[shot]
    bold, semi = FONTS[locale]
    head, sub = spec['text'][locale]
    im = background()
    d = ImageDraw.Draw(im)

    # Captions.
    # Headline on one line if it fits at >= 58 px, else wrap at 72 px.
    size = 72
    while size > 58 and d.textlength(head, font=font(bold, size)) > W - 100:
        size -= 2
    f_head, f_sub = font(bold, size), font(semi, 40)
    y = 90
    for line in wrap(d, head, f_head, W - 100):
        centered(d, y, line, f_head, WHITE)
        y += 92
    y += 14
    for line in wrap(d, sub, f_sub, W - 160):
        centered(d, y, line, f_sub, SUB)
        y += 54

    # Phone with the real capture.
    x, py, w, h = PHONE
    py = max(py, y + 40)
    h = min(h, H - py - 40)
    w = int(h * 1080 / 2400)
    x = (W - w) // 2
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x - 18, py - 10, x + w + 18, py + h + 34], radius=56, fill=(0, 0, 0, 150))
    im = Image.alpha_composite(im.convert('RGBA'), shadow.filter(ImageFilter.GaussianBlur(24))).convert('RGB')
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([x - 16, py - 16, x + w + 16, py + h + 16], radius=52, fill=(22, 24, 30), outline=(70, 76, 90), width=3)
    screen = Image.open(raw_path).convert('RGB').resize((w, h), Image.LANCZOS)
    im.paste(screen, (x, py), rounded(screen, 38))

    # Magnified callout of the translated text.
    co = spec.get('callout') or {}
    crop = co.get('crop')
    if crop:
        raw = Image.open(raw_path).convert('RGB')
        zoom = raw.crop(crop)
        zw = co.get('width', 520)
        zh = int(zoom.height * zw / zoom.width)
        zoom = zoom.resize((zw, zh), Image.LANCZOS)
        cx = {'left': 40, 'right': W - zw - 40}.get(co.get('at'), (W - zw) // 2)
        cy = co.get('y', py + h // 2 - zh // 2)
        card = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(card).rounded_rectangle([cx - 8, cy - 8, cx + zw + 8, cy + zh + 22], radius=30, fill=(0, 0, 0, 140))
        im = Image.alpha_composite(im.convert('RGBA'), card.filter(ImageFilter.GaussianBlur(16))).convert('RGB')
        d = ImageDraw.Draw(im)
        d.rounded_rectangle([cx - 6, cy - 6, cx + zw + 6, cy + zh + 6], radius=26, fill=WHITE)
        im.paste(zoom, (cx, cy), rounded(zoom, 22))

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    im.save(out_path)
    return out_path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--locale', default='en-US', choices=sorted(FONTS))
    ap.add_argument('--only', help='comma-separated shot ids')
    args = ap.parse_args()
    shots = args.only.split(',') if args.only else list(SHOTS)
    for i, shot in enumerate(SHOTS, 1):
        if shot not in shots:
            continue
        raw = os.path.join(RAW, args.locale, shot + '.png')
        if not os.path.exists(raw):
            print(f'skip {shot}: no {raw}')
            continue
        print(compose(args.locale, shot, raw, os.path.join(OUT, args.locale, f'{i:02d}_{shot}.png')))


if __name__ == '__main__':
    main()

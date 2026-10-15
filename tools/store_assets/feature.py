"""Google Play feature graphic (1024x500) from a real capture.

Usage: python tools/store_assets/feature.py [--locale en-US]
Output: build/play_store_assets/feature/<locale>.png
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter

import compose as c

W, H = 1024, 500
TEXT = {
    'en-US': ('Screen Translate', 'Manga, webtoons & games,\ntranslated right on screen'),
    'zh-CN': ('屏幕翻译', '漫画、条漫、游戏\n在屏幕上直接翻译'),
    'ja-JP': ('画面翻訳', 'マンガ・Webtoon・ゲームを\n画面上でそのまま翻訳'),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--locale', default='en-US', choices=sorted(TEXT))
    args = ap.parse_args()
    bold, semi = c.FONTS[args.locale]
    title, sub = TEXT[args.locale]

    im = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(im)
    for y in range(H):
        k = y / H
        d.line([(0, y), (W, y)], fill=(int(10 + 18 * k), int(17 + 20 * k), int(40 + 25 * k)))
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([560, -260, 1200, 420], fill=(59, 130, 246, 70))
    im = Image.alpha_composite(im.convert('RGBA'), glow.filter(ImageFilter.GaussianBlur(110))).convert('RGB')
    d = ImageDraw.Draw(im)

    # Icon, title, subline on the left.
    icon = Image.open(os.path.join(c.REPO, 'android', 'app', 'src', 'main', 'res', 'playstore-icon.png')).convert('RGBA')
    icon = icon.resize((110, 110), Image.LANCZOS)
    im.paste(icon, (60, 90), c.rounded(icon, 24))
    d.text((60, 225), title, font=c.font(bold, 62), fill=c.WHITE)
    y = 315
    for line in sub.split('\n'):
        d.text((62, y), line, font=c.font(semi, 30), fill=c.SUB)
        y += 44

    # Right: the top of the translated manga page in a phone, tilted slightly.
    # The listing's own capture: the Japanese listing has no manga shot
    # (Japanese artwork translated into Japanese), so it uses the webtoon.
    scene = 'webtoon' if args.locale == 'ja-JP' else 'manga'
    raw = os.path.join(c.RAW, args.locale, scene + '.png')
    shot = Image.open(raw).convert('RGB').crop((0, 0, 1080, 1500)).resize((324, 450), Image.LANCZOS)
    phone = Image.new('RGBA', (324 + 28, 450 + 28), (0, 0, 0, 0))
    ImageDraw.Draw(phone).rounded_rectangle([0, 0, phone.width - 1, phone.height + 60], radius=40,
                                            fill=(22, 24, 30), outline=(70, 76, 90), width=3)
    phone.paste(shot, (14, 14), c.rounded(shot, 28))
    phone = phone.rotate(-6, resample=Image.BICUBIC, expand=True)
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sx, sy = 640, 40
    shadow.paste((0, 0, 0, 150), (sx + 12, sy + 18), phone.getchannel('A'))
    im = Image.alpha_composite(im.convert('RGBA'), shadow.filter(ImageFilter.GaussianBlur(18)))
    im.alpha_composite(phone, (sx, sy))

    out = os.path.join(c.REPO, 'build', 'play_store_assets', 'feature', args.locale + '.png')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im.convert('RGB').save(out)
    print(out)


if __name__ == '__main__':
    main()

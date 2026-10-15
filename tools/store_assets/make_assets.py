"""Letter the store-screenshot artwork with short lines that OCR and translate reliably.

Usage: python tools/store_assets/make_assets.py [out_dir]   (default: tools/store_assets/assets)

The artwork in assets/original/ was generated with EMPTY speech bubbles and
dialogue boxes (generated text is garbage, and baked-in lines OCR badly).
This draws the lines in a clean bold face. LINES is what each image says;
every line must be checked on the emulator (check_lines.sh, several runs)
before use. One line per bubble: two-line bubbles sometimes OCR as two
blocks and get translated in halves ("The cat." / "It's flying!") - see
tools/demo_video/README.md for what tends to go wrong (dakuten, merged
name tags, words dropped in translation).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ORIG = os.path.join(HERE, 'assets', 'original')
FONTS = {'ko': 'C:/Windows/Fonts/malgunbd.ttf', 'ja': 'C:/Windows/Fonts/YuGothB.ttc'}

# box: area the text is centred in (inside the bubble/box, tail excluded).
LINES = {
    # screen_crop: panels 1-2 with both bubbles whole, ending above bubble 3.
    'webtoon.png': dict(lang='ko', ink=(0, 0, 0), en='Korean webtoon, three panels',
                        screen_crop=(0, 0, 713, 1520),
                        alt={'webtoon_screen_cjk.png': [['고양이다!'], ['같이 가자!']]}, items=[
        dict(box=(56, 40, 356, 190), lines=['고양이가 떠 있어!'], size=34),
        dict(box=(26, 936, 278, 1060), lines=['나랑 같이 가자!'], size=31),
        dict(box=(436, 1540, 680, 1660), lines=['좋아, 가자!'], size=34),
    ]),
    # The English listing keeps いらっしゃいませ (AI: "Welcome! Today's suggestion
    # is stew."); Quick mode into Chinese turned it into "这不好！", so the
    # default lettering (Chinese listing) says ようこそ instead.
    'tavern.png': dict(lang='ja', ink=(255, 255, 255), en='Mobile RPG dialogue',
                       alt={'tavern_en.png': [['マーサ'], ['いらっしゃいませ！', '今日のおすすめはシチューです。']]},
                       items=[
        dict(box=(62, 1400, 336, 1455), lines=['マーサ'], size=34, align='left'),
        dict(box=(70, 1470, 790, 1660), lines=['ようこそ！', '今日のおすすめはシチューです。'], size=40,
             align='left', valign='top'),
    ]),
}


def draw_lines(d, box, lines, font_path, size, ink, align='center', valign='middle'):
    f = ImageFont.truetype(font_path, size)
    x0, y0, x1, y1 = box
    lh = int(size * 1.35)
    total = lh * len(lines)
    y = y0 if valign == 'top' else (y0 + y1) / 2 - total / 2
    for line in lines:
        w = d.textlength(line, font=f)
        x = x0 if align == 'left' else (x0 + x1) / 2 - w / 2
        d.text((x, y), line, font=f, fill=ink)
        y += lh


# A messaging-app screen (drawn here, so no third-party UI or content), at
# the emulator's exact 1080x2400 so Photos shows it full-screen. Messages
# in the source language: Japanese for the English listing, English for
# the Chinese and Japanese listings.
CHATS = {
    'ja': dict(name='Yuki', messages=[  # Latin name: not Japanese script, so not "translated" (ゆき became "Mizuru")
        ('them', '明日の映画、何時にする？'),
        ('me', '7時はどう？'),
        ('them', 'いいね！駅で会おう。'),
        ('me', 'チケットは買っておくね。'),
        ('them', 'ありがとう！楽しみ！'),
    ]),
    'en': dict(name='Emma', messages=[
        ('them', 'What time is the movie tomorrow?'),
        ('me', 'How about seven?'),
        ('them', 'Sounds good! See you there.'),
        ('me', 'I will buy the tickets.'),
        ('them', 'Thank you! See you tomorrow.'),
    ]),
    # English lines for the Japanese listing: Quick mode into Japanese broke
    # "Thank you!" ("youう！") and "seven" ("7つ").
    'en_ja': dict(name='Emma', messages=[
        ('them', 'What time is the movie tomorrow?'),
        ('me', 'How about 7 p.m.?'),
        ('them', 'Sounds good!'),
        ('me', 'I will buy the tickets.'),
        ('them', 'See you at the station.'),
    ]),
}
CHAT_FONTS = {'ja': 'C:/Windows/Fonts/YuGothM.ttc', 'en': 'C:/Windows/Fonts/segoeui.ttf',
              'en_ja': 'C:/Windows/Fonts/segoeui.ttf'}


def draw_chat(lang):
    spec = CHATS[lang]
    W, H = 1080, 2400
    im = Image.new('RGB', (W, H), (236, 239, 244))
    d = ImageDraw.Draw(im)
    f_msg = ImageFont.truetype(CHAT_FONTS[lang], 46)
    f_name = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf' if lang.startswith('en') else FONTS['ja'], 50)
    # Header.
    d.rectangle([0, 0, W, 260], fill=(48, 92, 222))
    # Avatar without an initial: a lone letter got OCR'd and "translated".
    d.ellipse([60, 120, 160, 220], fill=(255, 196, 120))
    d.ellipse([92, 140, 128, 176], fill=(255, 255, 255))
    d.pieslice([74, 170, 146, 240], 180, 360, fill=(255, 255, 255))
    d.text((190, 140), spec['name'], font=f_name, fill=(255, 255, 255))
    # Messages. (No date chip: "Today" came back as "今天，".)
    y = 450
    for who, text in spec['messages']:
        tw = d.textlength(text, font=f_msg)
        bw, bh = tw + 80, 120
        x = 60 if who == 'them' else W - 60 - bw
        fill, ink = ((255, 255, 255), (20, 24, 32)) if who == 'them' else ((48, 92, 222), (255, 255, 255))
        d.rounded_rectangle([x, y, x + bw, y + bh], radius=44, fill=fill)
        d.text((x + 40, y + bh / 2), text, font=f_msg, fill=ink, anchor='lm')
        y += bh + 70
    # Input bar.
    d.rectangle([0, H - 220, W, H], fill=(255, 255, 255))
    d.rounded_rectangle([50, H - 180, W - 190, H - 70], radius=55, fill=(236, 239, 244))
    d.ellipse([W - 160, H - 180, W - 50, H - 70], fill=(48, 92, 222))
    d.polygon([(W - 125, H - 150), (W - 125, H - 100), (W - 80, H - 125)], fill=(255, 255, 255))
    return im


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'assets')
    os.makedirs(out, exist_ok=True)
    notes = []
    for lang, spec in CHATS.items():
        draw_chat(lang).save(os.path.join(out, f'chat_{lang}.png'))
        notes.append(f"chat_{lang}.png ({lang}): " + ' / '.join(t for _, t in spec['messages']))
    for name, spec in LINES.items():
        im = Image.open(os.path.join(ORIG, name)).convert('RGB')
        d = ImageDraw.Draw(im)
        for item in spec['items']:
            draw_lines(d, item['box'], item['lines'], FONTS[spec['lang']], item['size'], spec['ink'],
                       item.get('align', 'center'), item.get('valign', 'middle'))
        im.save(os.path.join(out, name))
        for alt_name, alt_lines in spec.get('alt', {}).items():
            # Same artwork with other lines (Quick mode into Chinese/Japanese
            # handled the default ones badly: "猫浮动！").
            alt = Image.open(os.path.join(ORIG, name)).convert('RGB')
            ad = ImageDraw.Draw(alt)
            for item, lines in zip(spec['items'], alt_lines):
                draw_lines(ad, item['box'], lines, FONTS[spec['lang']], item['size'], spec['ink'],
                           item.get('align', 'center'), item.get('valign', 'middle'))
            alt.crop(spec.get('screen_crop', (0, 0) + alt.size)).save(os.path.join(out, alt_name))
        if 'screen_crop' in spec:
            # One phone screen of the strip, as a webtoon reader shows it
            # (full width); the whole strip shown in Photos is too small.
            im.crop(spec['screen_crop']).save(os.path.join(out, name.replace('.png', '_screen.png')))
        notes.append(f"{name} ({spec['lang']}): " + ' / '.join(' '.join(i['lines']) for i in spec['items']))
    with open(os.path.join(out, 'lines.txt'), 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(notes) + '\n')
    print(out)


if __name__ == '__main__':
    main()

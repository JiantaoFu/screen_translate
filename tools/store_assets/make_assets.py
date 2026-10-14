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
                        screen_crop=(0, 0, 713, 1520), items=[
        dict(box=(56, 40, 356, 190), lines=['고양이가 떠 있어!'], size=34),
        dict(box=(26, 936, 278, 1060), lines=['나랑 같이 가자!'], size=31),
        dict(box=(436, 1540, 680, 1660), lines=['좋아, 가자!'], size=34),
    ]),
    'tavern.png': dict(lang='ja', ink=(255, 255, 255), en='Mobile RPG dialogue', items=[
        dict(box=(62, 1400, 336, 1455), lines=['マーサ'], size=34, align='left'),
        dict(box=(70, 1470, 790, 1660), lines=['いらっしゃいませ！', '今日のおすすめはシチューです。'], size=40,
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


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'assets')
    os.makedirs(out, exist_ok=True)
    notes = []
    for name, spec in LINES.items():
        im = Image.open(os.path.join(ORIG, name)).convert('RGB')
        d = ImageDraw.Draw(im)
        for item in spec['items']:
            draw_lines(d, item['box'], item['lines'], FONTS[spec['lang']], item['size'], spec['ink'],
                       item.get('align', 'center'), item.get('valign', 'middle'))
        im.save(os.path.join(out, name))
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

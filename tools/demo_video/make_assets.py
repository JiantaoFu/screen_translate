"""Re-letter the demo images with short, clear sentences.

Usage: python tools/demo_video/make_assets.py [out_dir]   (default: tools/demo_video/assets)

The artwork in assets/original/ came with longer lines that went wrong in
the first demo: ML Kit read 「ロボットが」 as 「ロボットか」 (か = "or"), so
manga 1 came out as "destroying that robot or the city", and 勇者/魔王
became "The bravest man" / "Witch King". This keeps the artwork, clears the
text area and draws new lines in a clean bold Gothic face, which OCRs
reliably. LINES is what each image says. Every line was checked on the
emulator in AI mode (2026-10-01): が was still read as か now and then
("destroying robots or cities"), so manga 1 uses は; any line with 助けて
lost "Help" in translation; 闇 was read as 商 and 倒 sometimes as 料 (larger text fixed
it); vertical hiragana (たおす) read worse than kanji; the game text must
start ~60 px below the name tag and right of the box border, or OCR merges
them ("村長上北の塔…" → "the tower in Xinjinoh"). Check new text the same way first.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ORIG = os.path.join(HERE, 'assets', 'original')
FONT = 'C:/Windows/Fonts/YuGothB.ttc'

# Each entry: text area to clear (x0, y0, x1, y1), its fill colour, and the
# lines to draw. Vertical bubbles: one string per column, read right to left.
LINES = {
    'manga-1-jp.png': dict(box=(805, 115, 1042, 570), fill=(255, 255, 255), ink=(0, 0, 0),
                           vertical=['ロボットは', '街を壊してる！'], size=62,
                           en='Robots are destroying cities!'),
    'manga-2-jp.png': dict(box=(112, 1378, 358, 1860), fill=(255, 255, 255), ink=(0, 0, 0),
                           vertical=['この剣で', 'おまえを倒す！'], size=72,
                           en='I will take you down with my sword!'),
    'game-dialogue-jp.png': dict(box=(100, 915, 1300, 1105), fill=(8, 12, 38), ink=(255, 255, 255),
                                 horizontal=['北の塔へ行きなさい。', '気をつけてな！'], size=68, top=60, left=60,
                                 en='Chief: Go to the north tower. Be careful!'),
}


def clear_bubble(im, box, fill):
    """Paint the inside of the speech bubble around `box` with `fill`.

    A plain rectangle spilled past the bubble's outline into the artwork.
    Speech bubbles are convex, so: flood-fill the bubble's white area from
    inside the box and paint the convex hull of it, shrunk a few pixels.
    That covers the old glyphs (holes in the white area) but stays inside
    the outline.
    """
    m = 60
    x0, y0, x1, y1 = box
    crop = (max(0, x0 - m), max(0, y0 - m), min(im.width, x1 + m), min(im.height, y1 + m))
    region = im.crop(crop).convert('L').point(lambda v: 255 if v > 200 else 0)
    # Seed: a white pixel near the box centre (the centre itself may be ink).
    cx, cy = (x0 + x1) // 2 - crop[0], (y0 + y1) // 2 - crop[1]
    seed = next((cx + dx, cy + dy) for dy in range(0, 120, 2) for dx in (0, 6, -6, 12, -12)
                if region.getpixel((cx + dx, cy + dy)) == 255)
    ImageDraw.floodfill(region, seed, 128)
    px = region.load()
    pts = [(x, y) for y in range(0, region.height, 3) for x in range(0, region.width, 3) if px[x, y] == 128]
    hull = _convex_hull(pts)
    # Shrink towards the centroid so antialiased outline pixels stay.
    gx = sum(p[0] for p in hull) / len(hull)
    gy = sum(p[1] for p in hull) / len(hull)
    shrunk = [(gx + (x - gx) * 0.97, gy + (y - gy) * 0.97) for x, y in hull]
    mask = Image.new('L', region.size, 0)
    ImageDraw.Draw(mask).polygon(shrunk, fill=255)
    im.paste(Image.new('RGB', region.size, fill), crop[:2], mask)


def _convex_hull(points):
    pts = sorted(set(points))

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def draw_vertical(d, box, columns, size, ink):
    f = ImageFont.truetype(FONT, size)
    x0, y0, x1, y1 = box
    pitch = int(size * 1.25)                     # column spacing
    width = pitch * len(columns)
    right = (x0 + x1) / 2 + width / 2            # columns centred in the box
    for i, col in enumerate(columns):
        cx = right - pitch * i - pitch / 2
        height = len(col) * size * 1.05
        y = (y0 + y1) / 2 - height / 2
        for ch in col:
            w = d.textlength(ch, font=f)
            d.text((cx - w / 2, y), ch, font=f, fill=ink)
            y += size * 1.05


def draw_horizontal(d, box, lines, size, ink, top=10, left=10):
    f = ImageFont.truetype(FONT, size)
    x0, y0, _, _ = box
    y = y0 + top
    for line in lines:
        d.text((x0 + left, y), line, font=f, fill=ink)
        y += int(size * 1.4)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'assets')
    os.makedirs(out, exist_ok=True)
    notes = []
    for name, spec in LINES.items():
        im = Image.open(os.path.join(ORIG, name)).convert('RGB')
        if 'vertical' in spec:
            clear_bubble(im, spec['box'], spec['fill'])
        else:
            ImageDraw.Draw(im).rectangle(spec['box'], fill=spec['fill'])
        d = ImageDraw.Draw(im)
        if 'vertical' in spec:
            draw_vertical(d, spec['box'], spec['vertical'], spec['size'], spec['ink'])
            jp = ''.join(spec['vertical'])
        else:
            draw_horizontal(d, spec['box'], spec['horizontal'], spec['size'], spec['ink'],
                            spec.get('top', 10), spec.get('left', 10))
            jp = '村長: ' + ''.join(spec['horizontal'])
        im.save(os.path.join(out, name))
        notes.append(f"{name}: {jp}\n  EN: {spec['en']}\n")
    with open(os.path.join(out, 'translations.txt'), 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(notes))
    print(out)


if __name__ == '__main__':
    main()

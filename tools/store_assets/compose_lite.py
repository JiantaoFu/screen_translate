"""Compose the Lite listing's phone screenshots (1080x1920) with Linux fonts.

Usage: python tools/store_assets/compose_lite.py --raw <dir> --out <dir> [--quota N]

Reuses compose.py's layout. Captions come from lite_captions.md (LITE_SHOTS_EN,
written by marketing); order: 1 manga, 2 game, 3 webtoon, 4 chat, 5 home.
--quota replaces the number in the home headline with the quota the app
actually showed. --placeholder manga,... draws "[caption TBD]" instead.
Needs fonts-noto-cjk (Ubuntu) or NOTO_BOLD / NOTO_REGULAR set.
"""
import argparse
import ast
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import compose  # noqa: E402

ORDER = ['manga', 'game', 'webtoon', 'chat', 'home']
LOCALE = 'en-US'


def load_captions(path):
    text = open(path, encoding='utf-8').read()
    block = re.search(r'LITE_SHOTS_EN\s*=\s*(\{.*?\n\})', text, re.S).group(1)
    return ast.literal_eval(block)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument('--raw', required=True, help='dir with manga.png, game.png, ... (1080x2400)')
    ap.add_argument('--out', required=True)
    ap.add_argument('--captions', default=os.path.join(here, 'lite_captions.md'))
    ap.add_argument('--quota', type=int, help='daily quota shown in the app (home headline)')
    ap.add_argument('--placeholder', default='', help='comma-separated shots to caption "[caption TBD]"')
    a = ap.parse_args()

    bold = os.environ.get('NOTO_BOLD', '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc')
    regular = os.environ.get('NOTO_REGULAR', '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
    compose.FONTS[LOCALE] = (bold, regular)
    caps = load_captions(a.captions)
    if a.quota is not None:
        head, sub = caps['home']
        caps['home'] = (re.sub(r'^\d+', str(a.quota), head), sub)
    tbd = set(filter(None, a.placeholder.split(',')))
    for shot in ORDER:
        compose.SHOTS[shot] = dict(text={LOCALE: ('[caption TBD]', '') if shot in tbd else caps[shot]})

    missing = []
    for i, shot in enumerate(ORDER, 1):
        raw = os.path.join(a.raw, f'{shot}.png')
        if not os.path.exists(raw):
            missing.append(shot)
            continue
        out = compose.compose(LOCALE, shot, raw, os.path.join(a.out, f'{i}_{shot}.png'))
        print(out, compose.SHOTS[shot]['text'][LOCALE])
    if missing:
        sys.exit(f'missing raw captures: {", ".join(missing)}')


if __name__ == '__main__':
    main()

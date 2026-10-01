"""Grid of timestamped frames from a recording, to pick cut points for edit.py.

Usage: python tools/demo_video/contact_sheet.py <video> [start] [end] [fps]
Defaults: whole video at 4 frames/s. Writes build/demo_video/<video name>.sheet.png.
"""
import glob
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    video = sys.argv[1]
    start = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0
    end = float(sys.argv[3]) if len(sys.argv) > 3 else None
    fps = float(sys.argv[4]) if len(sys.argv) > 4 else 4.0
    tmp = tempfile.mkdtemp(prefix='sheet_')
    args = ['ffmpeg', '-v', 'error', '-y', '-ss', str(start)]
    if end is not None:
        args += ['-to', str(end)]
    # Long side 160px: portrait tiles 72x160, landscape 160x72.
    args += ['-i', video, '-vf', f'fps={fps},scale=160:160:force_original_aspect_ratio=decrease',
             os.path.join(tmp, 'f_%04d.png')]
    subprocess.run(args, check=True)
    frames = sorted(glob.glob(os.path.join(tmp, 'f_*.png')))
    if not frames:
        sys.exit('no frames in that range')
    tw, th = Image.open(frames[0]).size
    cols = max(1, 1440 // tw)
    sheet = Image.new('RGB', (tw * cols, th * ((len(frames) + cols - 1) // cols)))
    for i, f in enumerate(frames):
        im = Image.open(f)
        d = ImageDraw.Draw(im)
        d.rectangle([0, 0, 34, 11], fill=(0, 0, 0))
        d.text((1, 0), f'{start + i / fps:.2f}', fill=(255, 80, 80))
        sheet.paste(im, ((i % cols) * tw, (i // cols) * th))
    out_dir = os.path.join(REPO, 'build', 'demo_video')
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, os.path.basename(video) + '.sheet.png')
    sheet.save(out)
    print(out)


if __name__ == '__main__':
    main()

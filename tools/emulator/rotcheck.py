"""Checker for rotcheck.sh: python rotcheck.py <landscape|portrait> <logcat file> <windows file>

After another app rotates the screen, nothing may be drawn from a frame of
the old orientation, and the boxes left on screen must sit where the harness
text is (dialogue along the bottom in landscape, paragraphs top-left in
portrait). Prints OK/BAD and a one-line summary.
"""
import re
import sys

exp, log_file, win_file = sys.argv[1:4]
log = open(log_file, encoding="utf-8", errors="replace").read().splitlines()
want = (2400.0, 1080.0) if exp == "landscape" else (1080.0, 2400.0)
seen_rot, stale, drawn = False, 0, 0
for line in log:
    if "Screen rotation detected" in line:
        seen_rot = True
    m = re.search(r"Original box .* on image \(([\d.]+) x ([\d.]+)\)", line)
    if m and seen_rot:
        drawn += 1
        if (float(m.group(1)), float(m.group(2))) != want:
            stale += 1
wins = [tuple(map(int, m.groups())) for m in
        (re.search(r"\((-?\d+),(-?\d+)\)\((\d+)x(\d+)\)", w) for w in open(win_file))
        if m]
if exp == "landscape":
    misplaced = [w for w in wins if not (w[1] >= 700 and w[1] + w[3] <= 1100)]
else:
    misplaced = [w for w in wins if not (w[1] < 900 and w[0] < 300)]
ok = seen_rot and stale == 0 and wins and not misplaced
print(f"{'OK ' if ok else 'BAD'} rotation_seen={seen_rot} drawn_after={drawn} "
      f"stale={stale} boxes={len(wins)} misplaced={misplaced}")

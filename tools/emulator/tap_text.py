#!/usr/bin/env python3
"""Tap the on-screen node whose text matches, via the view hierarchy.

The rest of the harness taps fixed coordinates, which is fine for the system
screen-capture dialog (its layout is Android's, not ours) but not for our own
dialogs: those move with text length, font scale and locale, and a coordinate
tap that misses one does not fail — it taps whatever is behind it and the
check further down reports something unrelated.

Usage:
    tap_text.py <serial> <text> [--optional] [--timeout SECONDS]

Exit 0 when tapped. Without --optional, exit 1 if the text never appears;
with it, exit 0 and say so, for a dialog that is only shown on a fresh
install.
"""
import argparse
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

DUMP = "/sdcard/window_dump.xml"


def dump(serial):
    """The current view hierarchy, or None if uiautomator could not dump it."""
    out = subprocess.run(
        ["adb", "-s", serial, "shell", "uiautomator", "dump", DUMP],
        capture_output=True, text=True,
    )
    if "dumped to" not in (out.stdout + out.stderr):
        return None
    xml = subprocess.run(
        ["adb", "-s", serial, "shell", "cat", DUMP],
        capture_output=True, text=True,
    ).stdout
    start = xml.find("<?xml")
    return xml[start:] if start >= 0 else None


def centre_of(xml, want):
    """Centre of the first node labelled `want`, ignoring case.

    Flutter draws to a canvas and publishes its labels as accessibility
    semantics, so every widget in this app arrives with an empty `text` and
    the label in `content-desc`. Matching `text` alone finds nothing here —
    which is a silent "not on screen", not an error.
    """
    try:
        root = ET.fromstring(xml)
    except ET.ParseError:
        return None
    want = want.strip().lower()
    for node in root.iter("node"):
        labels = (node.get("text", ""), node.get("content-desc", ""))
        if not any(l.strip().lower() == want for l in labels):
            continue
        m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.get("bounds", ""))
        if not m:
            continue
        x1, y1, x2, y2 = (int(g) for g in m.groups())
        return (x1 + x2) // 2, (y1 + y2) // 2
    return None


def main():
    p = argparse.ArgumentParser()
    p.add_argument("serial")
    p.add_argument("text")
    p.add_argument("--optional", action="store_true")
    p.add_argument("--timeout", type=float, default=10.0)
    a = p.parse_args()

    deadline = time.monotonic() + a.timeout
    while True:
        xml = dump(a.serial)
        spot = centre_of(xml, a.text) if xml else None
        if spot:
            subprocess.run(
                ["adb", "-s", a.serial, "shell", "input", "tap", str(spot[0]), str(spot[1])],
                check=True,
            )
            print("tapped %r at %d,%d" % (a.text, *spot))
            return 0
        if time.monotonic() >= deadline:
            break
        time.sleep(0.5)

    if a.optional:
        print("%r not on screen, skipping" % a.text)
        return 0
    print("FAIL: %r never appeared within %gs" % (a.text, a.timeout), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())

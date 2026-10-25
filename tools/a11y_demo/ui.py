"""uiautomator helper: ui.py <serial> tap|find <regex> [--timeout S]
Dumps the UI, finds the first node whose text or content-desc matches
<regex> (case-insensitive), and taps its center (tap) or just reports it
(find). Exit 0 when found, 1 when not found within the timeout."""
import re, subprocess, sys, time

serial, action, pattern = sys.argv[1:4]
timeout = float(sys.argv[5]) if len(sys.argv) > 5 and sys.argv[4] == '--timeout' else 10
rx = re.compile(pattern, re.I)
adb = ['adb', '-s', serial]
end = time.time() + timeout
while True:
    subprocess.run(adb + ['shell', 'uiautomator', 'dump', '/sdcard/ui.xml'], capture_output=True)
    xml = subprocess.run(adb + ['exec-out', 'cat', '/sdcard/ui.xml'], capture_output=True).stdout.decode('utf-8', 'replace')
    for node in re.finditer(r'<node [^>]*>', xml):
        n = node.group(0)
        t = re.search(r' text="([^"]*)"', n); d = re.search(r'content-desc="([^"]*)"', n)
        label = (t.group(1) if t else '') or (d.group(1) if d else '')
        if label and rx.search(label):
            b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
            x1, y1, x2, y2 = map(int, b.groups())
            x, y = (x1 + x2) // 2, (y1 + y2) // 2
            print(f'{action} "{label}" at {x},{y}')
            if action == 'tap':
                subprocess.run(adb + ['shell', 'input', 'tap', str(x), str(y)])
            sys.exit(0)
    if time.time() > end:
        print(f'not found: {pattern}'); sys.exit(1)
    time.sleep(1)

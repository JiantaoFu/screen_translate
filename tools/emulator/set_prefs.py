"""Set the app's saved Flutter preferences on the emulator (debug build).

Usage: python tools/emulator/set_prefs.py <serial> key=value [key=value ...]
Keys are without the "flutter." prefix, values are strings, e.g.
  sourceLanguage=en targetLanguage=zh translationMode=onDevice

The app must be stopped, or it overwrites the file. The regression and demo
scripts set their language pair and mode this way instead of relying on
whatever the app last saved: the pair decides which text is translated at
all (only text in the source language's script is).
"""
import os
import re
import subprocess
import sys
import tempfile
from xml.sax.saxutils import escape

PKG = 'com.lomoware.screen_translate'
PREFS = 'shared_prefs/FlutterSharedPreferences.xml'
EMPTY = "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n</map>\n"


def adb(serial, *args, **kw):
    return subprocess.run(['adb', '-s', serial, *args], capture_output=True, **kw)


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    serial, pairs = sys.argv[1], [a.split('=', 1) for a in sys.argv[2:]]
    r = adb(serial, 'exec-out', 'run-as', PKG, 'cat', PREFS)
    xml = r.stdout.decode('utf-8') if r.returncode == 0 and b'<map' in r.stdout else EMPTY
    for key, value in pairs:
        line = f'<string name="flutter.{key}">{escape(value)}</string>'
        pattern = re.compile(rf'<string name="flutter\.{re.escape(key)}">[^<]*</string>')
        xml = pattern.sub(line, xml) if pattern.search(xml) else xml.replace('</map>', f'    {line}\n</map>')
    tmp = '/data/local/tmp/st_prefs.xml'
    fd, local = tempfile.mkstemp(suffix='.xml')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(xml)
        adb(serial, 'push', local, tmp, check=True)
    finally:
        os.remove(local)
    adb(serial, 'shell', 'run-as', PKG, 'mkdir', '-p', 'shared_prefs', check=True)
    adb(serial, 'shell', f"run-as {PKG} sh -c 'cat {tmp} > {PREFS}'", check=True)
    adb(serial, 'shell', 'rm', tmp)
    print('set ' + ' '.join(f'{k}={v}' for k, v in pairs))


if __name__ == '__main__':
    main()

"""Upload the store screenshots and feature graphics to Google Play.

Usage:
  python tools/store_assets/upload.py            # dry run: upload into an edit, validate, discard
  python tools/store_assets/upload.py --commit   # commit (store listing changes go to review)
  python tools/store_assets/upload.py vi id      # only these listings; all others untouched

For en-US, zh-CN, ja-JP, vi and id it replaces: phone screenshots, 7- and
10-inch tablet screenshots (the same 1440x2560 set; vi and id have none yet,
so theirs are removed and fall back to en-US) and the feature graphic, from
build/play_store_assets/{screens,tablet,feature}/<locale>/. Every other
listing language gets its own screenshots deleted, so it falls back to the
en-US set instead of showing the old mock-ups. Uses the service account of
tools/release.py ($PLAY_SERVICE_ACCOUNT_JSON).
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(REPO, 'tools'))
sys.path.insert(0, HERE)
import release  # noqa: E402
from compose import MANIFEST  # noqa: E402

ASSETS = os.path.join(REPO, 'build', 'play_store_assets')
LOCALES = ['en-US', 'zh-CN', 'ja-JP', 'vi', 'id']
# Locales without their own tablet captures yet: their tablet screenshots
# are removed, so Play shows the en-US tablet set.
TABLET_OPTIONAL = {'vi', 'id'}
SCREENSHOT_TYPES = ['phoneScreenshots', 'sevenInchScreenshots', 'tenInchScreenshots']


def composed(kind, locale):
    """The images compose.py's last finished run wrote for kind/locale.

    Only those, never every PNG in the folder: a shot skipped in that run, or
    a run that stopped half-way, must not send an older image to Play. No
    list means no finished run (empty, and the caller decides).
    """
    folder = os.path.join(ASSETS, kind, locale)
    manifest = os.path.join(folder, MANIFEST)   # paths relative to folder: <set>/<image>
    if not os.path.exists(manifest):
        return []
    with open(manifest, encoding='utf-8') as f:
        names = [n for n in f.read().split() if n]
    missing = [n for n in names if not os.path.exists(os.path.join(folder, n))]
    if missing:
        sys.exit(f'{manifest} lists missing files: {", ".join(missing)}; rerun compose.py')
    return [os.path.join(folder, n) for n in sorted(names)]


def files_for(locale):
    phone = composed('screens', locale)
    tablet = composed('tablet', locale)
    feature = os.path.join(ASSETS, 'feature', locale + '.png')
    return {
        'phoneScreenshots': phone,
        'sevenInchScreenshots': tablet,
        'tenInchScreenshots': tablet,
        'featureGraphic': [feature] if os.path.exists(feature) else [],
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--commit', action='store_true', help='commit the edit instead of discarding it')
    ap.add_argument('locales', nargs='*', metavar='locale',
                    help=f'only these listings ({", ".join(LOCALES)}); other languages are then left alone. '
                         'Use it while a store listing experiment runs on a listing you are not changing.')
    args = ap.parse_args()
    unknown = sorted(set(args.locales) - set(LOCALES))
    if unknown:
        ap.error(f'unknown locale {", ".join(unknown)}; choose from {", ".join(LOCALES)}')
    from googleapiclient.http import MediaFileUpload

    plan = {loc: files_for(loc) for loc in (args.locales or LOCALES)}
    for loc, kinds in plan.items():
        for kind, files in kinds.items():
            if not files and loc in TABLET_OPTIONAL and kind in ('sevenInchScreenshots', 'tenInchScreenshots'):
                continue
            if not files:
                sys.exit(f'missing {kind} for {loc}: run compose.py / feature.py first')
            if kind != 'featureGraphic' and not 2 <= len(files) <= 8:
                sys.exit(f'{loc} {kind}: {len(files)} images, Play needs 2-8')

    svc = release.play_service(os.environ.get('PLAY_SERVICE_ACCOUNT_JSON', 'C:/Users/fuji2/keys/play-publisher.json'))
    pkg = release.PACKAGE
    edits = svc.edits()
    edit = edits.insert(packageName=pkg, body={}).execute()['id']
    try:
        languages = [l['language'] for l in edits.listings().list(packageName=pkg, editId=edit).execute()['listings']]
        for loc, kinds in plan.items():
            for kind, files in kinds.items():
                edits.images().deleteall(packageName=pkg, editId=edit, language=loc, imageType=kind).execute()
                for f in files:
                    edits.images().upload(packageName=pkg, editId=edit, language=loc, imageType=kind,
                                          media_body=MediaFileUpload(f, mimetype='image/png')).execute()
                print(f'{loc:6} {kind:22} ' + (f'{len(files)} uploaded' if files else 'removed (falls back to en-US)'))
        for lang in languages:
            if lang in plan or args.locales:
                continue
            for kind in SCREENSHOT_TYPES:
                edits.images().deleteall(packageName=pkg, editId=edit, language=lang, imageType=kind).execute()
            print(f'{lang:6} own screenshots removed (falls back to en-US)')
        edits.validate(packageName=pkg, editId=edit).execute()
        print('Play validated the edit')
        if args.commit:
            edits.commit(packageName=pkg, editId=edit).execute()
            print('committed: the store listing changes are sent for review')
            edit = None
        else:
            print('dry run: nothing published (rerun with --commit)')
    finally:
        if edit:
            edits.delete(packageName=pkg, editId=edit).execute()


if __name__ == '__main__':
    main()

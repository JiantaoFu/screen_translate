"""Upload the store screenshots and feature graphics to Google Play.

Usage:
  python tools/store_assets/upload.py            # dry run: upload into an edit, validate, discard
  python tools/store_assets/upload.py --commit   # commit (store listing changes go to review)

For en-US, zh-CN and ja-JP it replaces: phone screenshots, 7- and 10-inch
tablet screenshots (the same 1440x2560 set) and the feature graphic, from
build/play_store_assets/{screens,tablet,feature}/<locale>/. Every other
listing language gets its own screenshots deleted, so it falls back to the
en-US set instead of showing the old mock-ups. Uses the service account of
tools/release.py ($PLAY_SERVICE_ACCOUNT_JSON).
"""
import argparse
import glob
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(REPO, 'tools'))
import release  # noqa: E402

ASSETS = os.path.join(REPO, 'build', 'play_store_assets')
LOCALES = ['en-US', 'zh-CN', 'ja-JP']
SCREENSHOT_TYPES = ['phoneScreenshots', 'sevenInchScreenshots', 'tenInchScreenshots']


def files_for(locale):
    phone = sorted(glob.glob(os.path.join(ASSETS, 'screens', locale, '*.png')))
    tablet = sorted(glob.glob(os.path.join(ASSETS, 'tablet', locale, '*.png')))
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
    args = ap.parse_args()
    from googleapiclient.http import MediaFileUpload

    plan = {loc: files_for(loc) for loc in LOCALES}
    for loc, kinds in plan.items():
        for kind, files in kinds.items():
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
                print(f'{loc:6} {kind:22} {len(files)} uploaded')
        for lang in languages:
            if lang in plan:
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

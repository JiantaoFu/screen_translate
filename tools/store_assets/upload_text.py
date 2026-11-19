"""Upload store listing text (title, short and full description) to Google Play.

Usage:
  python tools/store_assets/upload_text.py                  # dry run: write into an edit, validate, discard
  python tools/store_assets/upload_text.py --commit         # commit (listing changes go to review)
  python tools/store_assets/upload_text.py --app lite vi    # only some apps / languages

Reads store_listing/<app>/<language>/{title,short_description,full_description}.txt,
where <app> is paid or lite. A language the app has no listing for yet is
created. Only the three text fields are sent: the video, screenshots and
other languages are left as they are. Uses the service account of
tools/release.py ($PLAY_SERVICE_ACCOUNT_JSON).
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(REPO, 'tools'))
import release  # noqa: E402

ROOT = os.path.join(REPO, 'store_listing')
PACKAGES = {'paid': 'com.lomoware.screen_translate', 'lite': 'com.lomoware.screen_translate.lite'}
LIMITS = {'title': 30, 'short_description': 80, 'full_description': 4000}
FIELDS = {'title': 'title', 'short_description': 'shortDescription', 'full_description': 'fullDescription'}


def load(app, lang):
    """The listing text of one app and language, checked against Play's limits."""
    out = {}
    for name, limit in LIMITS.items():
        path = os.path.join(ROOT, app, lang, name + '.txt')
        with open(path, encoding='utf-8') as f:
            text = f.read().strip()
        if not text or len(text) > limit:
            raise ValueError(f'{app}/{lang}/{name}.txt: {len(text)} characters, Play allows 1-{limit}')
        out[FIELDS[name]] = text
    return out


def planned(apps, langs):
    plan = {}
    for app in apps:
        d = os.path.join(ROOT, app)
        found = sorted(os.listdir(d)) if os.path.isdir(d) else []
        chosen = [l for l in found if not langs or l in langs]
        if chosen:
            plan[app] = {lang: load(app, lang) for lang in chosen}
    return plan


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--commit', action='store_true', help='commit the edit instead of discarding it')
    ap.add_argument('--app', choices=sorted(PACKAGES), action='append', help='paid and/or lite (default: both)')
    ap.add_argument('languages', nargs='*', help='listing languages, e.g. vi id (default: all in store_listing/)')
    args = ap.parse_args()
    try:
        plan = planned(args.app or sorted(PACKAGES), set(args.languages))
    except ValueError as e:
        sys.exit(str(e))
    if not plan:
        sys.exit('nothing to upload')

    svc = release.play_service(os.environ.get('PLAY_SERVICE_ACCOUNT_JSON', 'C:/Users/fuji2/keys/play-publisher.json'))
    edits = svc.edits()
    for app, listings in plan.items():
        pkg = PACKAGES[app]
        edit = edits.insert(packageName=pkg, body={}).execute()['id']
        try:
            existing = {l['language'] for l in edits.listings().list(packageName=pkg, editId=edit).execute().get('listings', [])}
            for lang, body in listings.items():
                edits.listings().patch(packageName=pkg, editId=edit, language=lang, body=body).execute() \
                    if lang in existing else \
                    edits.listings().update(packageName=pkg, editId=edit, language=lang, body=body).execute()
                print(f'{app:4} {lang:6} {"updated" if lang in existing else "created"}: {body["title"]}')
            edits.validate(packageName=pkg, editId=edit).execute()
            print(f'{app:4} Play validated the edit')
            if args.commit:
                edits.commit(packageName=pkg, editId=edit).execute()
                print(f'{app:4} committed: the listing changes are sent for review')
                edit = None
            else:
                print(f'{app:4} dry run: nothing published (rerun with --commit)')
        finally:
            if edit:
                edits.delete(packageName=pkg, editId=edit).execute()


if __name__ == '__main__':
    main()

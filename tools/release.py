#!/usr/bin/env python3
"""Build and publish ScreenTranslate to Google Play in one go.

    python tools/release.py --track internal
    python tools/release.py --bump patch --track production --rollout 0.2 \\
        --notes-dir release_notes/1.2.2
    python tools/release.py --build-only        # signed AAB only, no upload
    python tools/release.py --dry-run           # everything, but Play discards the edit

Steps (each stops the release on failure):
  1. Preflight: no uncommitted changes (nor new files under lib/ or
     android/, which would ship without being in the tag), release keystore
     configured (otherwise the Gradle build silently falls back to DEBUG
     signing), a JDK Gradle can run (17-23; Android Studio's bundled JBR 25
     can't, which is also why this builds with Gradle rather than
     `flutter build`), Play credentials, and a versionCode higher than
     anything already on Play — checked before spending ~10 min building.
  2. Tests: flutter test + Android unit tests (--skip-tests to skip).
  3. Optional version bump (scripts/bump_version.py), localizations, and a
     signed release App Bundle. A debug-signed bundle is refused.
  4. Upload the bundle and the R8 mapping (so Play Console shows readable
     stack traces), assign it to the track with release notes, have Play
     validate the edit, and commit it after a confirmation (--yes skips).
  5. Commit the version bump and tag v<name>+<code>; --push pushes both.

Play credentials: a service-account JSON key with release permissions for
this app (Play Console > Users and permissions), passed via --credentials or
the PLAY_SERVICE_ACCOUNT_JSON environment variable. Keep it out of the repo.

Requires: pip install -r tools/requirements-release.txt
"""

import argparse
import contextlib
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"
PUBSPEC = ROOT / "pubspec.yaml"
PACKAGE = "com.lomoware.screen_translate"
AAB = ROOT / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
MAPPING = ROOT / "build" / "app" / "outputs" / "mapping" / "release" / "mapping.txt"
TRACKS = ("internal", "alpha", "beta", "production")
NOTES_LIMIT = 500  # characters per language, enforced by Play
IS_WINDOWS = os.name == "nt"


class ReleaseError(Exception):
    pass


def step(msg):
    print(f"\n==> {msg}", flush=True)


def run(cmd, cwd=ROOT, env=None, capture=False):
    """Runs cmd, raising ReleaseError on failure. Output streams unless captured."""
    exe = shutil.which(str(cmd[0])) or str(cmd[0])
    args = [exe, *map(str, cmd[1:])]
    # flutter and gradlew are .bat files on Windows and must go through cmd.exe.
    shell = IS_WINDOWS and exe.lower().endswith((".bat", ".cmd"))
    res = subprocess.run(
        subprocess.list2cmdline(args) if shell else args,
        cwd=cwd, env=env, shell=shell, capture_output=capture,
        text=True, encoding="utf-8", errors="replace",
    )
    if res.returncode != 0:
        if capture:
            sys.stderr.write((res.stdout or "") + (res.stderr or ""))
        raise ReleaseError(f"command failed ({res.returncode}): {' '.join(map(str, cmd))}")
    return res.stdout if capture else ""


def git(*args):
    return run(["git", *args], capture=True).strip()


# --------------------------------------------------------------------------
# Version


def read_version():
    m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$",
                  PUBSPEC.read_text(encoding="utf-8"), re.M)
    if not m:
        raise ReleaseError('pubspec.yaml has no "version: x.y.z+n" line')
    return m.group(1), int(m.group(2))


def write_local_versions(name, code):
    """The Gradle build reads the version from android/local.properties,
    which only `flutter build` would otherwise refresh from pubspec.yaml."""
    path = ANDROID / "local.properties"
    lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    wanted = {"flutter.versionName": name, "flutter.versionCode": str(code)}
    out, seen = [], set()
    for line in lines:
        key = line.split("=", 1)[0].strip()
        if key in wanted:
            out.append(f"{key}={wanted[key]}")
            seen.add(key)
        else:
            out.append(line)
    out += [f"{k}={v}" for k, v in wanted.items() if k not in seen]
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


# --------------------------------------------------------------------------
# Preflight


def java_major(java):
    out = subprocess.run([str(java), "-version"], capture_output=True, text=True).stderr
    m = re.search(r'version "(\d+)(?:\.(\d+))?', out)
    if not m:
        return 0
    major = int(m.group(1))
    return int(m.group(2) or 0) if major == 1 else major


def find_java_home(explicit):
    for home in filter(None, [explicit, os.environ.get("RELEASE_JAVA_HOME"),
                              os.environ.get("JAVA_HOME")]):
        java = Path(home) / "bin" / ("java.exe" if IS_WINDOWS else "java")
        if not java.exists():
            continue
        major = java_major(java)
        if 17 <= major <= 23:
            return Path(home)
        print(f"  skipping {home}: Java {major} (this Gradle version runs on 17-23)")
    raise ReleaseError("no usable JDK 17-23 found; pass --java-home or set RELEASE_JAVA_HOME")


def check_keystore():
    """Mirrors android/app/build.gradle, which silently signs with the DEBUG
    key when the keystore file is missing."""
    props = ANDROID / "key.properties"
    values = {}
    if props.exists():
        for line in props.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.lstrip().startswith(("#", "!")):
                key, value = line.split("=", 1)
                # Java properties escaping: "C\:\\keys\\x.jks" is C:\keys\x.jks.
                values[key.strip()] = re.sub(r"\\(.)", r"\1", value.strip())
    # Same default and relative base as android/app/build.gradle.
    store = (ANDROID / "app" / values.get("storeFile", "../screen-trans-key.keystore")).resolve()
    if not store.exists():
        raise ReleaseError(f"release keystore not found: {store} (the build would fall "
                           "back to DEBUG signing, which Play rejects)")
    for key, env in (("storePassword", "KEYSTORE_PASSWORD"), ("keyPassword", "KEY_PASSWORD")):
        if not values.get(key) and not os.environ.get(env):
            raise ReleaseError(f"{key} is not set in android/key.properties or ${env}")


def check_git_clean(allow_dirty):
    # Tracked changes anywhere, plus new source files the build would pick up
    # but the release tag wouldn't contain. Other untracked files don't matter.
    tracked = run(["git", "status", "--porcelain", "--untracked-files=no"], capture=True)
    sources = run(["git", "status", "--porcelain", "--untracked-files=all", "--",
                   "lib", "android"], capture=True)
    dirty = tracked.splitlines() + [l for l in sources.splitlines() if l.startswith("??")]
    if dirty and not allow_dirty:
        raise ReleaseError("uncommitted changes (commit them, or pass --allow-dirty):\n"
                           + "\n".join(dirty))


# --------------------------------------------------------------------------
# Build


def gradle(tasks, java_home):
    wrapper = ANDROID / ("gradlew.bat" if IS_WINDOWS else "gradlew")
    run([wrapper, *tasks], cwd=ANDROID, env=dict(os.environ, JAVA_HOME=str(java_home)))


def check_signature(java_home):
    keytool = java_home / "bin" / ("keytool.exe" if IS_WINDOWS else "keytool")
    out = run([keytool, "-J-Duser.language=en", "-printcert", "-jarfile", AAB], capture=True)
    owner = re.search(r"^Owner:\s*(.+)$", out, re.M)
    if not owner:
        raise ReleaseError("could not read the bundle's signing certificate:\n" + out)
    if "CN=Android Debug" in owner.group(1):
        raise ReleaseError("the bundle is DEBUG-signed; check android/key.properties")
    sha = re.search(r"SHA256:\s*(\S+)", out)
    print(f"  signed by {owner.group(1)}\n  SHA-256 {sha.group(1) if sha else '?'}")


# --------------------------------------------------------------------------
# Play


def load_notes(notes, notes_dir):
    """Release notes per Play language code (en-US, zh-CN, ja-JP, ...)."""
    result = {}
    if notes_dir:
        files = sorted(Path(notes_dir).glob("*.txt"))
        if not files:
            raise ReleaseError(f"no <language>.txt files in {notes_dir}")
        for f in files:
            result[f.stem] = f.read_text(encoding="utf-8").strip()
    if notes:
        result["en-US"] = notes.strip()
    for lang, text in result.items():
        if len(text) > NOTES_LIMIT:
            raise ReleaseError(f"release notes for {lang} have {len(text)} characters; "
                               f"Play allows {NOTES_LIMIT}")
    return result


def play_service(credentials):
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
    except ImportError:
        raise ReleaseError("Google API client missing: pip install -r tools/requirements-release.txt")
    try:
        creds = service_account.Credentials.from_service_account_file(
            credentials, scopes=["https://www.googleapis.com/auth/androidpublisher"])
    except (OSError, ValueError) as e:
        raise ReleaseError(f"can't use Play credentials {credentials}: {e}") from e
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


@contextlib.contextmanager
def play_api(action):
    """Reports Play API, auth and network failures as a ReleaseError with
    Play's own message (e.g. missing permissions) instead of a traceback."""
    from google.auth.exceptions import GoogleAuthError
    from googleapiclient.errors import HttpError
    try:
        yield
    except (HttpError, GoogleAuthError, OSError) as e:
        raise ReleaseError(f"{action} failed: {e}") from e


def highest_version_code(svc):
    edit_id = svc.edits().insert(packageName=PACKAGE, body={}).execute()["id"]
    try:
        tracks = svc.edits().tracks().list(packageName=PACKAGE, editId=edit_id).execute()
        return max((int(code) for track in tracks.get("tracks", [])
                    for release in track.get("releases", [])
                    for code in release.get("versionCodes", [])), default=0)
    finally:
        svc.edits().delete(packageName=PACKAGE, editId=edit_id).execute()


def upload(request, what):
    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"  {what}: {int(status.progress() * 100)}%", end="\r", flush=True)
    print(f"  {what}: done      ")
    return response


def confirm(question):
    if not sys.stdin.isatty():
        raise ReleaseError("not interactive: pass --yes to publish without confirmation")
    return input(f"\n{question} [y/N] ").strip().lower() in ("y", "yes")


def publish(svc, name, code, args, notes):
    """Returns True once the release is committed on Play."""
    from googleapiclient.http import MediaFileUpload

    edits = svc.edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]
    committed = False
    try:
        bundle = upload(edits.bundles().upload(
            packageName=PACKAGE, editId=edit_id,
            # The bundle is large (on-device OCR/translation models); without
            # this Play refuses it over the install-size warning.
            ackBundleInstallationWarning=True,
            media_body=MediaFileUpload(str(AAB), mimetype="application/octet-stream",
                                       chunksize=8 * 1024 * 1024, resumable=True)),
            "bundle")
        if int(bundle["versionCode"]) != code:
            raise ReleaseError(f"Play read versionCode {bundle['versionCode']} from the "
                               f"bundle, expected {code}")
        if MAPPING.exists():
            upload(edits.deobfuscationfiles().upload(
                packageName=PACKAGE, editId=edit_id, apkVersionCode=code,
                deobfuscationFileType="proguard",
                media_body=MediaFileUpload(str(MAPPING), mimetype="application/octet-stream",
                                           chunksize=8 * 1024 * 1024, resumable=True)),
                "R8 mapping")

        release = {"name": f"{name} ({code})", "versionCodes": [str(code)], "status": "completed"}
        if args.draft:
            release["status"] = "draft"
        elif args.rollout < 1:
            release.update(status="inProgress", userFraction=args.rollout)
        if notes:
            release["releaseNotes"] = [{"language": lang, "text": text}
                                       for lang, text in notes.items()]
        edits.tracks().update(packageName=PACKAGE, editId=edit_id, track=args.track,
                              body={"track": args.track, "releases": [release]}).execute()
        edits.validate(packageName=PACKAGE, editId=edit_id).execute()
        print("  Play validated the edit")

        if args.dry_run:
            print("  dry run: discarding the edit")
            return False
        rollout = "draft" if args.draft else (
            f"{args.rollout:.0%} staged rollout" if args.rollout < 1 else "full rollout")
        if not args.yes and not confirm(
                f"Publish {name} ({code}) to '{args.track}' ({rollout})?"):
            print("  not published")
            return False
        commit = {"packageName": PACKAGE, "editId": edit_id}
        if args.changes_not_sent_for_review:
            commit["changesNotSentForReview"] = True
        edits.commit(**commit).execute()
        committed = True
        return True
    finally:
        if not committed:
            try:
                edits.delete(packageName=PACKAGE, editId=edit_id).execute()
            except Exception:
                pass


# --------------------------------------------------------------------------


def parse_args():
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--track", choices=TRACKS, default="internal")
    p.add_argument("--rollout", type=float, default=1.0,
                   help="fraction of users for a staged rollout, e.g. 0.2 (default: all)")
    p.add_argument("--draft", action="store_true",
                   help="create the release as a draft to finish in Play Console")
    p.add_argument("--bump", choices=("build", "patch", "minor", "major"),
                   help="bump pubspec.yaml's version first")
    p.add_argument("--notes", help="release notes (en-US)")
    p.add_argument("--notes-dir", help="directory of <language>.txt release notes, e.g. zh-CN.txt")
    p.add_argument("--credentials", default=os.environ.get("PLAY_SERVICE_ACCOUNT_JSON"),
                   help="service-account JSON key (default: $PLAY_SERVICE_ACCOUNT_JSON)")
    p.add_argument("--java-home", help="JDK 17-23 for Gradle (default: $RELEASE_JAVA_HOME, $JAVA_HOME)")
    p.add_argument("--build-only", action="store_true", help="stop after building the signed bundle")
    p.add_argument("--dry-run", action="store_true",
                   help="upload and have Play validate everything, then discard the edit")
    p.add_argument("--yes", action="store_true", help="publish without asking for confirmation")
    p.add_argument("--changes-not-sent-for-review", action="store_true",
                   help="commit without sending for review (for apps where Play requires "
                        "sending changes for review manually)")
    p.add_argument("--skip-tests", action="store_true")
    p.add_argument("--allow-dirty", action="store_true",
                   help="allow uncommitted changes (the tag won't match the build)")
    p.add_argument("--push", action="store_true", help="push the version commit and tag")
    args = p.parse_args()
    if not 0 < args.rollout <= 1:
        p.error("--rollout must be in (0, 1]")
    if args.draft and args.rollout < 1:
        p.error("--draft and --rollout are mutually exclusive")
    return args


def main():
    # Keep log lines in order with errors when output is piped (CI, tee).
    sys.stdout.reconfigure(line_buffering=True)
    args = parse_args()
    started = time.time()
    uploading = not args.build_only
    original_pubspec = PUBSPEC.read_bytes()
    bumped = built = published = used_gradle = False
    try:
        step("Preflight")
        check_git_clean(args.allow_dirty)
        check_keystore()
        java_home = find_java_home(args.java_home)
        print(f"  JDK: {java_home}")
        branch = git("rev-parse", "--abbrev-ref", "HEAD")
        print(f"  branch: {branch}")
        if branch != "main" and args.track == "production" and uploading:
            print("  WARNING: publishing to production from a branch other than main")
        notes = load_notes(args.notes, args.notes_dir)
        svc = None
        if uploading:
            if not args.credentials or not Path(args.credentials).exists():
                raise ReleaseError("Play credentials not found: pass --credentials or set "
                                   "PLAY_SERVICE_ACCOUNT_JSON")
            key = Path(args.credentials).resolve()
            if key.is_relative_to(ROOT) and subprocess.run(
                    ["git", "check-ignore", "-q", str(key)], cwd=ROOT).returncode != 0:
                print(f"  WARNING: {key} is inside the repo and not git-ignored; move it out "
                      "so it can't be committed")
            svc = play_service(args.credentials)

        if args.bump:
            step(f"Bumping version ({args.bump})")
            run([sys.executable, ROOT / "scripts" / "bump_version.py", args.bump])
            bumped = True
        name, code = read_version()
        print(f"  version {name} ({code})")
        if svc:
            with play_api("Reading versions from Google Play"):
                on_play = highest_version_code(svc)
            print(f"  highest versionCode on Play: {on_play}")
            if code <= on_play:
                raise ReleaseError(f"versionCode {code} must be higher than {on_play} "
                                   "(use --bump)")

        if not args.skip_tests:
            step("Tests")
            run(["flutter", "test"])
            used_gradle = True
            gradle([":app:testDebugUnitTest"], java_home)

        step("Building the signed release App Bundle")
        run([sys.executable, ROOT / "scripts" / "convert_arb_to_json.py"])
        run(["flutter", "pub", "get"])
        run(["flutter", "gen-l10n"])
        write_local_versions(name, code)
        # When nothing changed Gradle skips repackaging and leaves the old
        # file in place; removing it guarantees the bundle is from this build.
        AAB.unlink(missing_ok=True)
        used_gradle = True
        gradle(["bundleRelease"], java_home)
        if not AAB.exists():
            raise ReleaseError(f"the build produced no bundle at {AAB}")
        print(f"  {AAB.relative_to(ROOT)} ({AAB.stat().st_size / 2**20:.1f} MB)")
        check_signature(java_home)
        built = True

        if uploading:
            step(f"Publishing to Google Play ({args.track})")
            with play_api("Publishing"):
                published = publish(svc, name, code, args, notes)

        if published:
            step("Tagging")
            try:
                if bumped:
                    git("add", "pubspec.yaml")
                    git("commit", "-m", f"Release {name} ({code})")
                tag = f"v{name}+{code}"
                git("tag", "-a", tag, "-m", f"{name} ({code}) on {args.track}")
                print(f"  tagged {tag}")
                if args.push:
                    run(["git", "push"])
                    run(["git", "push", "origin", tag])
            except ReleaseError as e:
                # The release is already live; only the bookkeeping is missing.
                print(f"\n{name} ({code}) is published to '{args.track}', but {e}.\n"
                      "Finish the version commit / tag / push by hand.", file=sys.stderr)
                return 1
    except ReleaseError as e:
        print(f"\nRelease stopped: {e}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nRelease interrupted", file=sys.stderr)
        return 130
    finally:
        if bumped and not published and not (args.build_only and built):
            # Nothing was released or built for keeps: don't leave the bump behind.
            PUBSPEC.write_bytes(original_pubspec)
            print("  version bump reverted (nothing was published)")
        if used_gradle:
            # Gradle daemons hold ~2 GB each long after a one-off build.
            try:
                gradle(["--stop"], find_java_home(args.java_home))
            except ReleaseError:
                pass

    minutes = (time.time() - started) / 60
    if published:
        print(f"\nPublished {name} ({code}) to '{args.track}' in {minutes:.1f} min.")
    elif args.build_only:
        print(f"\nBuilt {name} ({code}) in {minutes:.1f} min: {AAB}")
    else:
        print(f"\nDone in {minutes:.1f} min; nothing was published.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

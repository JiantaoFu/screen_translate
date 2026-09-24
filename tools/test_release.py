"""Tests for tools/release.py with the build, git and Google Play stubbed out.

    pip install -r tools/requirements-release.txt
    python tools/test_release.py
"""
import contextlib
import io
import os
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import release  # noqa: E402


class FakeRequest:
    def __init__(self, log, name, result):
        self.log, self.name, self.result = log, name, result

    def execute(self):
        self.log.append(self.name)
        return self.result

    def next_chunk(self):  # resumable upload: one chunk then done
        self.log.append(self.name)
        return None, self.result


class FakeEdits:
    def __init__(self, log, version_code):
        self.log, self.version_code, self.calls = log, version_code, {}

    def _req(self, name, result=None, **kw):
        self.calls[name] = kw
        return FakeRequest(self.log, name, result or {})

    def insert(self, **kw): return self._req("insert", {"id": "E1"}, **kw)
    def delete(self, **kw): return self._req("delete", **kw)
    def validate(self, **kw): return self._req("validate", **kw)
    def commit(self, **kw): return self._req("commit", **kw)

    def bundles(self):
        return types.SimpleNamespace(upload=lambda **kw: self._req(
            "bundles.upload", {"versionCode": self.version_code}, **kw))

    def deobfuscationfiles(self):
        return types.SimpleNamespace(upload=lambda **kw: self._req("mapping.upload", **kw))

    def tracks(self):
        return types.SimpleNamespace(
            update=lambda **kw: self._req("tracks.update", **kw),
            list=lambda **kw: self._req("tracks.list", {"tracks": [
                {"track": "production", "releases": [{"versionCodes": ["10"]}]},
                {"track": "internal", "releases": [{"versionCodes": ["9"]}]}]}, **kw))


class FakeService:
    def __init__(self, version_code=11):
        self.log = []
        self.e = FakeEdits(self.log, version_code)

    def edits(self):
        return self.e


def args(**kw):
    base = dict(track="internal", rollout=1.0, draft=False, dry_run=False, yes=True,
                changes_not_sent_for_review=False)
    base.update(kw)
    return types.SimpleNamespace(**base)


class PublishTest(unittest.TestCase):
    def setUp(self):
        # Real files are needed for MediaFileUpload; point at small stand-ins.
        tmp = Path(tempfile.mkdtemp())
        (tmp / "app.aab").write_bytes(b"aab")
        (tmp / "mapping.txt").write_text("map")
        self.patches = [mock.patch.object(release, "AAB", tmp / "app.aab"),
                        mock.patch.object(release, "MAPPING", tmp / "mapping.txt")]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in self.patches:
            p.stop()

    def test_full_release_commits(self):
        svc = FakeService()
        notes = {"en-US": "Fixes", "zh-CN": "修复"}
        self.assertTrue(release.publish(svc, "1.2.1", 11, args(), notes))
        self.assertEqual(svc.log, ["insert", "bundles.upload", "mapping.upload",
                                   "tracks.update", "validate", "commit"])
        self.assertTrue(svc.e.calls["bundles.upload"]["ackBundleInstallationWarning"])
        self.assertEqual(svc.e.calls["mapping.upload"]["apkVersionCode"], 11)
        body = svc.e.calls["tracks.update"]["body"]
        self.assertEqual(body["track"], "internal")
        rel = body["releases"][0]
        self.assertEqual(rel["versionCodes"], ["11"])
        self.assertEqual(rel["status"], "completed")
        self.assertEqual({n["language"] for n in rel["releaseNotes"]}, {"en-US", "zh-CN"})
        self.assertNotIn("changesNotSentForReview", svc.e.calls["commit"])

    def test_staged_rollout(self):
        svc = FakeService()
        release.publish(svc, "1.2.1", 11, args(track="production", rollout=0.2), {})
        rel = svc.e.calls["tracks.update"]["body"]["releases"][0]
        self.assertEqual((rel["status"], rel["userFraction"]), ("inProgress", 0.2))

    def test_dry_run_discards(self):
        svc = FakeService()
        self.assertFalse(release.publish(svc, "1.2.1", 11, args(dry_run=True), {}))
        self.assertIn("validate", svc.log)
        self.assertNotIn("commit", svc.log)
        self.assertEqual(svc.log[-1], "delete")

    def test_declined_confirmation_discards(self):
        svc = FakeService()
        with mock.patch.object(release, "confirm", return_value=False):
            self.assertFalse(release.publish(svc, "1.2.1", 11, args(yes=False), {}))
        self.assertNotIn("commit", svc.log)
        self.assertEqual(svc.log[-1], "delete")

    def test_version_mismatch_aborts_and_discards(self):
        svc = FakeService(version_code=12)
        with self.assertRaises(release.ReleaseError):
            release.publish(svc, "1.2.1", 11, args(), {})
        self.assertNotIn("commit", svc.log)
        self.assertEqual(svc.log[-1], "delete")

    def test_highest_version_code_and_cleanup(self):
        svc = FakeService()
        self.assertEqual(release.highest_version_code(svc), 10)
        self.assertEqual(svc.log, ["insert", "tracks.list", "delete"])

    def test_notes_limit(self):
        with self.assertRaises(release.ReleaseError):
            release.load_notes("x" * 501, None)


class KeystoreTest(unittest.TestCase):
    """check_keystore against a throwaway android/ tree (never the real one)."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        (self.tmp / "app").mkdir()
        self.patch = mock.patch.object(release, "ANDROID", self.tmp)
        self.patch.start()
        self.env = mock.patch.dict(os.environ, {}, clear=False)
        self.env.start()
        os.environ.pop("KEYSTORE_PASSWORD", None)
        os.environ.pop("KEY_PASSWORD", None)

    def tearDown(self):
        self.env.stop()
        self.patch.stop()

    def test_missing_keystore_is_refused(self):
        (self.tmp / "key.properties").write_text("storePassword=a\nkeyPassword=b\n")
        with self.assertRaisesRegex(release.ReleaseError, "DEBUG"):
            release.check_keystore()

    def test_default_keystore_with_env_passwords(self):
        # No key.properties at all, like CI: build.gradle's defaults + env vars.
        (self.tmp / "screen-trans-key.keystore").write_bytes(b"k")
        with self.assertRaisesRegex(release.ReleaseError, "storePassword"):
            release.check_keystore()
        os.environ.update(KEYSTORE_PASSWORD="a", KEY_PASSWORD="b")
        release.check_keystore()

    def test_escaped_absolute_path(self):
        store = self.tmp / "keys" / "up.jks"
        store.parent.mkdir()
        store.write_bytes(b"k")
        escaped = str(store).replace("\\", "\\\\").replace(":", "\\:")
        (self.tmp / "key.properties").write_text(
            f"# comment\nstoreFile={escaped}\nstorePassword=a\nkeyPassword=b\n")
        release.check_keystore()


def http_error(status, message):
    import httplib2
    from googleapiclient.errors import HttpError
    resp = httplib2.Response({"status": str(status)})
    resp.reason = "Forbidden"
    body = ('{"error": {"code": %d, "message": "%s"}}' % (status, message)).encode()
    return HttpError(resp, body)


class PlayApiTest(unittest.TestCase):
    def test_api_and_auth_errors_become_release_errors(self):
        from google.auth.exceptions import RefreshError
        for err in (http_error(403, "The caller does not have permission"),
                    RefreshError("invalid_grant: Invalid JWT Signature."),
                    TimeoutError("timed out")):
            with self.assertRaises(release.ReleaseError) as cm:
                with release.play_api("Publishing"):
                    raise err
            self.assertTrue(str(cm.exception).startswith("Publishing failed: "))

    def test_programming_errors_are_not_swallowed(self):
        with self.assertRaises(KeyError):
            with release.play_api("Publishing"):
                raise KeyError("versionCode")


class GitCleanTest(unittest.TestCase):
    """check_git_clean against a throwaway repository."""

    def setUp(self):
        self.repo = Path(tempfile.mkdtemp())
        def sh(*cmd):
            subprocess.run(cmd, cwd=self.repo, check=True, capture_output=True)
        self.sh = sh
        (self.repo / "lib").mkdir()
        (self.repo / "android").mkdir()
        (self.repo / "lib" / "a.dart").write_text("x")
        (self.repo / "android" / ".gitignore").write_text("local.properties\n")
        sh("git", "init", "-q")
        sh("git", "add", ".")
        sh("git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "init")
        orig = release.run
        self.patch = mock.patch.object(
            release, "run", lambda cmd, cwd=None, env=None, capture=False:
            orig(cmd, cwd=self.repo, env=env, capture=capture))
        self.patch.start()

    def tearDown(self):
        self.patch.stop()

    def test_clean_and_irrelevant_files_pass(self):
        (self.repo / "captured_home.png").write_bytes(b"png")        # untracked, outside sources
        (self.repo / "android" / "local.properties").write_text("x")  # ignored
        release.check_git_clean(False)

    def test_new_source_file_is_refused(self):
        (self.repo / "lib" / "new.dart").write_text("y")
        with self.assertRaisesRegex(release.ReleaseError, r"\?\? lib/new.dart"):
            release.check_git_clean(False)
        release.check_git_clean(True)

    def test_modified_tracked_file_is_refused_with_status_intact(self):
        (self.repo / "lib" / "a.dart").write_text("changed")
        with self.assertRaisesRegex(release.ReleaseError, r"\n M lib/a.dart"):
            release.check_git_clean(False)


class MainTest(unittest.TestCase):
    """main()'s orchestration with the build, git and Play stubbed out."""

    ORIGINAL = b"name: x\r\nversion: 1.2.1+11\r\n"

    def setUp(self):
        root = Path(tempfile.mkdtemp())
        self.pubspec = root / "pubspec.yaml"
        self.pubspec.write_bytes(self.ORIGINAL)
        self.aab = root / "out" / "app-release.aab"
        self.aab.parent.mkdir()
        self.aab.write_bytes(b"stale bundle from an earlier build")
        self.creds = Path(tempfile.mkdtemp()) / "play.json"
        self.creds.write_text("{}")
        self.calls, self.tag_fails, self.gradle_writes_aab = [], False, True
        self.publish_result = True
        self.aab_existed_at_build = None

        def fake_run(cmd, cwd=None, env=None, capture=False):
            cmd = [str(c) for c in cmd]
            self.calls.append(cmd)
            if len(cmd) > 1 and cmd[1].endswith("bump_version.py"):
                self.pubspec.write_bytes(b"name: x\r\nversion: 1.2.2+12\r\n")
            return ""

        def fake_gradle(tasks, java_home):
            self.calls.append(["gradle", *tasks])
            if tasks == ["bundleRelease"]:
                self.aab_existed_at_build = self.aab.exists()
                if self.gradle_writes_aab:
                    self.aab.write_bytes(b"fresh bundle")

        def fake_git(*args):
            self.calls.append(["git", *args])
            if args[0] == "rev-parse":
                return "release-branch"
            if args[0] == "tag" and self.tag_fails:
                raise release.ReleaseError("command failed (128): git tag")
            return ""

        def fake_publish(svc, name, code, args, notes):
            self.calls.append(["publish", name, str(code)])
            if isinstance(self.publish_result, Exception):
                raise self.publish_result
            return self.publish_result

        self.patches = [mock.patch.object(release, k, v) for k, v in {
            "ROOT": root, "PUBSPEC": self.pubspec, "AAB": self.aab,
            "run": fake_run, "gradle": fake_gradle, "git": fake_git,
            "check_git_clean": lambda allow: None, "check_keystore": lambda: None,
            "find_java_home": lambda explicit: Path("jdk"),
            "write_local_versions": lambda n, c: None, "check_signature": lambda jh: None,
            "play_service": lambda c: object(), "highest_version_code": lambda svc: 11,
            "publish": fake_publish,
        }.items()]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in self.patches:
            p.stop()

    def main(self, *argv):
        err = io.StringIO()
        with mock.patch.object(sys, "argv", ["release.py", *argv]), \
                contextlib.redirect_stderr(err):
            code = release.main()
        return code, err.getvalue()

    def publish_args(self, *extra):
        return ("--credentials", str(self.creds), "--yes", "--skip-tests", *extra)

    def test_successful_publish_commits_bump_and_tags(self):
        code, err = self.main(*self.publish_args("--bump", "patch"))
        self.assertEqual((code, err), (0, ""))
        self.assertIn(["git", "commit", "-m", "Release 1.2.2 (12)"], self.calls)
        self.assertIn(["git", "tag", "-a", "v1.2.2+12", "-m", "1.2.2 (12) on internal"], self.calls)
        self.assertNotIn(["git", "push"], self.calls)
        self.assertIn(b"1.2.2+12", self.pubspec.read_bytes())

    def test_tag_failure_after_publish_says_it_is_published(self):
        self.tag_fails = True
        code, err = self.main(*self.publish_args("--bump", "patch"))
        self.assertEqual(code, 1)
        self.assertIn("1.2.2 (12) is published to 'internal'", err)
        self.assertNotIn("Release stopped", err)
        self.assertIn(b"1.2.2+12", self.pubspec.read_bytes())  # bump kept: it's live

    def test_play_rejection_reverts_bump_byte_for_byte(self):
        self.publish_result = http_error(403, "The caller does not have permission")
        code, err = self.main(*self.publish_args("--bump", "patch"))
        self.assertEqual(code, 1)
        self.assertIn("Release stopped: Publishing failed", err)
        self.assertIn("does not have permission", err)
        self.assertEqual(self.pubspec.read_bytes(), self.ORIGINAL)
        self.assertFalse(any(c[:2] == ["git", "tag"] for c in self.calls))

    def test_declined_publish_reverts_bump_and_does_not_tag(self):
        self.publish_result = False
        code, _ = self.main(*self.publish_args("--bump", "build"))
        self.assertEqual(code, 0)
        self.assertEqual(self.pubspec.read_bytes(), self.ORIGINAL)
        self.assertFalse(any(c[:2] == ["git", "tag"] for c in self.calls))

    def test_version_not_above_play_stops_before_building(self):
        code, err = self.main(*self.publish_args())
        self.assertEqual(code, 1)
        self.assertIn("versionCode 11 must be higher than 11", err)
        self.assertNotIn(["gradle", "bundleRelease"], self.calls)

    def test_stale_bundle_is_removed_before_building(self):
        code, _ = self.main("--build-only", "--skip-tests")
        self.assertEqual(code, 0)
        self.assertIs(self.aab_existed_at_build, False)
        self.assertEqual(self.aab.read_bytes(), b"fresh bundle")
        self.assertIn(["gradle", "--stop"], self.calls)

    def test_build_without_bundle_fails(self):
        self.gradle_writes_aab = False
        code, err = self.main("--build-only", "--skip-tests")
        self.assertEqual(code, 1)
        self.assertIn("the build produced no bundle", err)

    def test_build_only_keeps_bump(self):
        code, _ = self.main("--build-only", "--skip-tests", "--bump", "patch")
        self.assertEqual(code, 0)
        self.assertIn(b"1.2.2+12", self.pubspec.read_bytes())
        self.assertFalse(any(c[0] == "publish" for c in self.calls))


if __name__ == "__main__":
    unittest.main(verbosity=2)

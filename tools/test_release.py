"""Tests for tools/release.py and tools/build.py with the build, git and Google Play stubbed out.

    pip install -r tools/requirements-release.txt
    python tools/test_release.py
"""
import contextlib
import io
import os
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build  # noqa: E402
import release  # noqa: E402


class FakeRequest:
    def __init__(self, log, name, result):
        self.log, self.name, self.result = log, name, result

    def execute(self):
        self.log.append(self.name)
        return self.result

    def next_chunk(self, num_retries=0):  # resumable upload: one chunk then done
        self.log.append(self.name)
        self.retries = num_retries
        return None, self.result


class FakeEdits:
    def __init__(self, log, version_code):
        self.log, self.version_code, self.calls, self.requests = log, version_code, {}, {}

    def _req(self, name, result=None, **kw):
        self.calls[name] = kw
        self.requests[name] = FakeRequest(self.log, name, result or {})
        return self.requests[name]

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
        # A dropped connection mid-upload is retried, not a failed release.
        self.assertEqual(svc.e.requests["bundles.upload"].retries, release.CHUNK_RETRIES)
        self.assertEqual(svc.e.calls["mapping.upload"]["apkVersionCode"], 11)
        body = svc.e.calls["tracks.update"]["body"]
        self.assertEqual(body["track"], "internal")
        rel = body["releases"][0]
        self.assertEqual(rel["versionCodes"], ["11"])
        self.assertEqual(rel["status"], "completed")
        self.assertEqual({n["language"] for n in rel["releaseNotes"]}, {"en-US", "zh-CN"})
        self.assertNotIn("changesNotSentForReview", svc.e.calls["commit"])

    def test_lite_publishes_to_the_lite_package_with_lite_artifacts(self):
        svc = FakeService()
        lite_aab = Path(tempfile.mkdtemp()) / "lite.aab"
        lite_aab.write_bytes(b"lite")
        with mock.patch.object(release, "artifacts",
                               lambda flavor: (lite_aab, lite_aab.with_suffix(".txt"))):
            self.assertTrue(release.publish(svc, "1.2.1", 11, args(flavor="lite"), {}))
        self.assertEqual(svc.e.calls["bundles.upload"]["packageName"],
                         "com.lomoware.screen_translate.lite")
        self.assertEqual(svc.e.calls["commit"]["packageName"], "com.lomoware.screen_translate.lite")
        self.assertNotIn("mapping.upload", svc.log)

    def test_play_http_keeps_resumable_uploads_working(self):
        http = release.play_http()
        # 308 = "resume incomplete" during a resumable upload, not a redirect.
        self.assertNotIn(308, http.redirect_codes)
        self.assertEqual(http.timeout, release.UPLOAD_TIMEOUT_S)

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
        self.patch = mock.patch.object(build, "ANDROID", self.tmp)
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
            build.check_keystore()

    def test_default_keystore_with_env_passwords(self):
        # No key.properties at all, like CI: build.gradle's defaults + env vars.
        (self.tmp / "screen-trans-key.keystore").write_bytes(b"k")
        with self.assertRaisesRegex(release.ReleaseError, "storePassword"):
            build.check_keystore()
        os.environ.update(KEYSTORE_PASSWORD="a", KEY_PASSWORD="b")
        build.check_keystore()

    def test_escaped_absolute_path(self):
        store = self.tmp / "keys" / "up.jks"
        store.parent.mkdir()
        store.write_bytes(b"k")
        escaped = str(store).replace("\\", "\\\\").replace(":", "\\:")
        (self.tmp / "key.properties").write_text(
            f"# comment\nstoreFile={escaped}\nstorePassword=a\nkeyPassword=b\n")
        build.check_keystore()


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

    # Both flavors' build numbers, because a release reads the one
    # belonging to --flavor.
    ORIGINAL = (b"name: x\r\nversion: 1.2.1+11\r\n"
                b"flavor_version_codes:\r\n  lite: 11\r\n")

    def setUp(self):
        root = Path(tempfile.mkdtemp())
        self.pubspec = root / "pubspec.yaml"
        self.pubspec.write_bytes(self.ORIGINAL)
        self.aab = root / "out" / "app-release.aab"
        self.aab.parent.mkdir()
        self.aab.write_bytes(b"stale bundle from an earlier build")
        self.creds = Path(tempfile.mkdtemp()) / "play.json"
        self.creds.write_text("{}")
        self.calls, self.tag_fails, self.build_ok = [], False, True
        self.publish_result = True

        def fake_run(cmd, cwd=None, env=None, capture=False):
            cmd = [str(c) for c in cmd]
            self.calls.append(cmd)
            if len(cmd) > 1 and cmd[1].endswith("bump_version.py"):
                # Mirror the real script: the x.y.z name is shared, but only
                # the --flavor's build number moves.
                if "lite" in cmd:
                    self.pubspec.write_bytes(
                        b"name: x\r\nversion: 1.2.2+11\r\n"
                        b"flavor_version_codes:\r\n  lite: 12\r\n")
                else:
                    self.pubspec.write_bytes(
                        b"name: x\r\nversion: 1.2.2+12\r\n"
                        b"flavor_version_codes:\r\n  lite: 11\r\n")
            return ""

        def fake_gradle(tasks, java_home):
            self.calls.append(["gradle", *tasks])

        def fake_build(target, java_home, name, code, flavor="paid"):
            self.calls.append(["build", target, name, str(code), flavor])
            if not self.build_ok:
                raise release.ReleaseError("the build produced nothing")
            return self.aab

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
            "build": fake_build,
            "stop_gradle": lambda jh: self.calls.append(["gradle", "--stop"]),
            "play_service": lambda c: object(), "highest_version_code": lambda svc, package=build.PACKAGE: (
                self.calls.append(["versions", package]) or 11),
            "check_lite_firebase": lambda: self.calls.append(["lite firebase"]),
            "publish": fake_publish,
        }.items()]
        # read_version() lives in build.py and reads build.PUBSPEC.
        self.patches.append(mock.patch.object(build, "PUBSPEC", self.pubspec))
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
        self.assertFalse(any(c[0] == "build" for c in self.calls))

    def test_build_only_builds_the_aab_through_build_py(self):
        code, _ = self.main("--build-only", "--skip-tests")
        self.assertEqual(code, 0)
        self.assertIn(["build", "aab", "1.2.1", "11", "paid"], self.calls)
        self.assertNotIn(["lite firebase"], self.calls)
        self.assertIn(["gradle", "--stop"], self.calls)

    def test_lite_release_uses_lite_package_firebase_check_and_tag(self):
        code, err = self.main(*self.publish_args("--bump", "patch", "--flavor", "lite"))
        self.assertEqual((code, err), (0, ""))
        self.assertIn(["lite firebase"], self.calls)
        self.assertIn(["versions", "com.lomoware.screen_translate.lite"], self.calls)
        self.assertIn(["build", "aab", "1.2.2", "12", "lite"], self.calls)
        self.assertIn(["git", "tag", "-a", "v1.2.2+12-lite", "-m", "1.2.2 (12) on internal"], self.calls)

    def test_default_release_checks_paid_package(self):
        self.main(*self.publish_args("--bump", "patch"))
        self.assertIn(["versions", "com.lomoware.screen_translate"], self.calls)

    def test_build_failure_stops_the_release(self):
        self.build_ok = False
        code, err = self.main(*self.publish_args("--bump", "patch"))
        self.assertEqual(code, 1)
        self.assertIn("the build produced nothing", err)
        self.assertEqual(self.pubspec.read_bytes(), self.ORIGINAL)
        self.assertFalse(any(c[0] == "publish" for c in self.calls))

    def test_build_only_keeps_bump(self):
        code, _ = self.main("--build-only", "--skip-tests", "--bump", "patch")
        self.assertEqual(code, 0)
        self.assertIn(b"1.2.2+12", self.pubspec.read_bytes())
        self.assertFalse(any(c[0] == "publish" for c in self.calls))


PAID_DEFINES = "-Pdart-defines=QVBQX0ZMQVZPUj1wYWlk"  # APP_FLAVOR=paid
LITE_DEFINES = "-Pdart-defines=QVBQX0ZMQVZPUj1saXRl"  # APP_FLAVOR=lite


class BuildTest(unittest.TestCase):
    """tools/build.py's build() with Gradle and the output checks stubbed out."""

    def setUp(self):
        root = Path(tempfile.mkdtemp())
        self.out = root / "out"
        self.out.write_bytes(b"stale output from an earlier build")
        self.gradle_args, self.existed, self.writes, self.checks = None, None, True, []

        def fake_gradle(tasks, java_home):
            self.gradle_args = tasks
            self.existed = self.out.exists()
            if self.writes:
                self.out.write_bytes(b"fresh")

        self.outputs = []

        def fake_output_path(target, flavor="paid"):
            self.outputs.append((target, flavor))
            return self.out

        self.patches = [mock.patch.object(build, k, v) for k, v in {
            "ROOT": root, "output_path": fake_output_path, "gradle": fake_gradle,
            "check_lite_firebase": lambda: self.checks.append("lite firebase"),
            "prepare": lambda name, code: self.checks.append("prepare"),
            "check_keystore": lambda: self.checks.append("keystore"),
            "check_signature": lambda jh, path: self.checks.append("jar signature"),
            "check_apk": lambda path, name, code, release, package: self.checks.append(
                ("apk", release, package)),
        }.items()]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in self.patches:
            p.stop()

    def test_stale_output_is_removed_before_building(self):
        self.assertEqual(build.build("aab", Path("jdk"), "1.2.1", 11), self.out)
        self.assertIs(self.existed, False)
        self.assertEqual(self.out.read_bytes(), b"fresh")

    def test_no_output_fails(self):
        self.writes = False
        with self.assertRaisesRegex(build.BuildError, "produced nothing"):
            build.build("apk", Path("jdk"), "1.2.1", 11)

    def test_release_apk_is_single_abi_without_split_per_abi(self):
        build.build("apk", Path("jdk"), "1.2.1", 11)
        self.assertEqual(self.gradle_args, ["assemblePaidRelease", PAID_DEFINES,
                                            "-Ptarget-platform=android-arm64",
                                            "-Pabi=arm64-v8a", "-Pdisable-abi-filtering=true"])
        self.assertEqual(self.checks, ["keystore", "prepare", ("apk", True, build.PACKAGE)])
        self.assertEqual(self.outputs, [("apk", "paid")])

    def test_emulator_apk_is_debug_x86_64(self):
        build.build("emulator", Path("jdk"), "1.2.1", 11)
        self.assertEqual(self.gradle_args, ["assemblePaidDebug", PAID_DEFINES,
                                            "-Ptarget-platform=android-x64",
                                            "-Pabi=x86_64", "-Pdisable-abi-filtering=true"])
        self.assertEqual(self.checks, ["prepare", ("apk", False, build.PACKAGE)])

    def test_aab_has_all_abis_and_a_jar_signature_check(self):
        build.build("aab", Path("jdk"), "1.2.1", 11)
        self.assertEqual(self.gradle_args, ["bundlePaidRelease", PAID_DEFINES])
        self.assertEqual(self.checks, ["keystore", "prepare", "jar signature"])

    def test_lite_debug_apk_uses_lite_task_package_and_dart_define(self):
        build.build("emulator", Path("jdk"), "1.2.1", 11, "lite")
        self.assertEqual(self.gradle_args[:2], ["assembleLiteDebug", LITE_DEFINES])
        self.assertEqual(self.checks, ["prepare", ("apk", False, "com.lomoware.screen_translate.lite")])
        self.assertEqual(self.outputs, [("emulator", "lite")])

    def test_lite_release_requires_lite_firebase_config(self):
        build.build("aab", Path("jdk"), "1.2.1", 11, "lite")
        self.assertEqual(self.gradle_args, ["bundleLiteRelease", LITE_DEFINES])
        self.assertEqual(self.checks, ["keystore", "lite firebase", "prepare", "jar signature"])

    def test_unknown_flavor_is_refused(self):
        with self.assertRaisesRegex(build.BuildError, "unknown flavor"):
            build.build("apk", Path("jdk"), "1.2.1", 11, "pro")


class FlavorPathTest(unittest.TestCase):
    def test_default_paths_are_the_paid_flavor(self):
        self.assertEqual(build.AAB, build.OUTPUTS / "bundle" / "paidRelease" / "app-paid-release.aab")
        self.assertEqual(build.MAPPING, build.OUTPUTS / "mapping" / "paidRelease" / "mapping.txt")
        self.assertEqual(build.output_path("apk", "lite"),
                         build.OUTPUTS / "apk" / "lite" / "release" / "app-lite-release.apk")
        self.assertEqual(build.output_path("emulator"),
                         build.OUTPUTS / "apk" / "paid" / "debug" / "app-paid-debug.apk")

    def test_dart_defines_are_base64(self):
        import base64
        self.assertEqual(base64.b64decode(build.dart_defines("lite")), b"APP_FLAVOR=lite")

    def test_flavored_task(self):
        self.assertEqual(build.flavored_task("bundleRelease", "lite"), "bundleLiteRelease")


class FlavorVersionTest(unittest.TestCase):
    """versionCode is per flavor; the x.y.z name is shared."""

    PUBSPEC = """name: screen_translate
version: 1.2.7+21

# comment about the scheme
flavor_version_codes:
  lite: 4

environment:
  sdk: '>=3.1.3 <4.0.0'
"""

    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.dir, ignore_errors=True)
        self.pubspec = self.dir / "pubspec.yaml"
        self.pubspec.write_text(self.PUBSPEC, encoding="utf-8")
        patch = mock.patch.object(build, "PUBSPEC", self.pubspec)
        patch.start()
        self.addCleanup(patch.stop)

    def test_each_flavor_reads_its_own_build_number(self):
        self.assertEqual(build.read_version(), ("1.2.7", 21))
        self.assertEqual(build.read_version("paid"), ("1.2.7", 21))
        self.assertEqual(build.read_version("lite"), ("1.2.7", 4))

    def test_unknown_flavor_is_refused(self):
        with self.assertRaisesRegex(build.BuildError, "unknown flavor"):
            build.read_version("deluxe")

    def test_missing_flavor_number_names_the_block(self):
        self.pubspec.write_text("""version: 1.2.7+21
""", encoding="utf-8")
        with self.assertRaisesRegex(build.BuildError, "flavor_version_codes"):
            build.read_version("lite")

    def test_the_codes_block_stops_at_the_next_top_level_key(self):
        # environment: must not be swallowed into the block.
        self.assertEqual(build.flavor_version_codes(self.PUBSPEC), {"lite": 4})

    def test_local_properties_gets_every_flavors_number(self):
        android = self.dir / "android"
        android.mkdir()
        with mock.patch.object(build, "ANDROID", android):
            build.write_local_versions("1.2.7", 4)
        text = (android / "local.properties").read_text(encoding="utf-8")
        props = dict(line.split("=", 1) for line in text.splitlines() if "=" in line)
        # the flavor being built, plus one key per flavor so a Gradle run for
        # the other flavor still gets its own number
        self.assertEqual(props["flutter.versionCode"], "4")
        self.assertEqual(props["flutter.versionCode.paid"], "21")
        self.assertEqual(props["flutter.versionCode.lite"], "4")
        self.assertEqual(props["flutter.versionName"], "1.2.7")

    def bump(self, *args):
        done = subprocess.run(
            [sys.executable, "-I", str(build.ROOT / "scripts" / "bump_version.py"), *args],
            cwd=self.dir, capture_output=True, text=True)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)
        return self.pubspec.read_text(encoding="utf-8")

    def test_paid_bump_leaves_lites_number_alone(self):
        out = self.bump("build")
        self.assertIn("version: 1.2.7+22", out)
        self.assertIn("lite: 4", out)

    def test_lite_bump_leaves_the_paid_build_number_alone(self):
        out = self.bump("build", "--flavor", "lite")
        self.assertIn("version: 1.2.7+21", out)
        self.assertIn("lite: 5", out)

    def test_lite_patch_bump_moves_the_shared_name_but_only_lites_number(self):
        out = self.bump("patch", "--flavor", "lite")
        self.assertIn("version: 1.2.8+21", out)
        self.assertIn("lite: 5", out)

class LiteFirebaseTest(unittest.TestCase):
    def write(self, data):
        path = Path(tempfile.mkdtemp()) / "google-services.json"
        path.write_text(data if isinstance(data, str) else __import__("json").dumps(data))
        return path

    def client(self, pkg):
        return {"client_info": {"android_client_info": {"package_name": pkg}}}

    def test_missing_file_is_refused(self):
        with self.assertRaisesRegex(build.BuildError, "missing"):
            build.check_lite_firebase(Path(tempfile.mkdtemp()) / "nope.json")

    def test_paid_only_config_is_refused(self):
        path = self.write({"client": [self.client("com.lomoware.screen_translate")]})
        with self.assertRaisesRegex(build.BuildError, "no Android app com.lomoware.screen_translate.lite"):
            build.check_lite_firebase(path)

    def test_lite_config_passes(self):
        build.check_lite_firebase(self.write({"client": [self.client("com.lomoware.screen_translate.lite")]}))


class InstallTest(unittest.TestCase):
    """install() against canned adb results."""

    def install(self, returncode, output):
        result = subprocess.CompletedProcess([], returncode, stdout=output, stderr="")
        with mock.patch.object(build.subprocess, "run", return_value=result):
            build.install(Path("app.apk"), "PHONE1")

    def test_success(self):
        self.install(0, "Performing Streamed Install\nSuccess\n")

    def test_downgrade_explains_the_uninstall_tradeoff(self):
        with self.assertRaisesRegex(build.BuildError, "higher versionCode.*clears its data"):
            self.install(1, "Failure [INSTALL_FAILED_VERSION_DOWNGRADE: 11 < 2011]\n")

    def test_signature_mismatch_is_explained(self):
        with self.assertRaisesRegex(build.BuildError, "different key"):
            self.install(1, "Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: ...]\n")

    def test_other_failures_show_adb_output(self):
        with self.assertRaisesRegex(build.BuildError, "INSTALL_FAILED_INSUFFICIENT_STORAGE"):
            self.install(1, "Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE]\n")


class CheckApkTest(unittest.TestCase):
    """check_apk against canned aapt2/apksigner output."""

    RELEASE_CERT = "Signer #1 certificate DN: CN=Jeromy Fu, O=Lomoware\n"

    def check(self, badging, certs):
        outputs = iter([badging, certs])
        with mock.patch.object(build, "build_tools", lambda: Path("bt")), \
                mock.patch.object(build, "run", lambda cmd, capture=False: next(outputs)):
            build.check_apk(Path("app.apk"), "1.2.1", 11, release=True)

    def test_matching_release_apk_passes(self):
        self.check("package: name='com.lomoware.screen_translate' versionCode='11' versionName='1.2.1' x\n"
                   "native-code: 'arm64-v8a'\n", self.RELEASE_CERT)

    def test_abi_offset_version_code_is_refused(self):
        # What Flutter's split-per-abi did to 1.2.1+11 on arm64.
        with self.assertRaisesRegex(build.BuildError, "2011"):
            self.check("package: name='com.lomoware.screen_translate' versionCode='2011' versionName='1.2.1' x\n",
                       self.RELEASE_CERT)

    def test_debug_signed_release_apk_is_refused(self):
        with self.assertRaisesRegex(build.BuildError, "DEBUG"):
            self.check("package: name='com.lomoware.screen_translate' versionCode='11' versionName='1.2.1' x\n",
                       "Signer #1 certificate DN: C=US, O=Android, CN=Android Debug\n")

if __name__ == "__main__":
    unittest.main(verbosity=2)

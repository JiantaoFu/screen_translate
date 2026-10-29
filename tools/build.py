#!/usr/bin/env python3
"""The one way to build ScreenTranslate for Android.

    python tools/build.py aab                   # release-signed App Bundle (what Play gets)
    python tools/build.py apk                   # release-signed arm64 APK for a phone
    python tools/build.py apk --install SERIAL  # ...and install it over the current app (keeps data)
    python tools/build.py emulator              # debug x86_64 APK for tools/emulator/
    python tools/build.py emulator --install emulator-5554
    python tools/build.py aab --flavor lite     # any target, for the Lite app

Flavors (android/app/build.gradle): `paid` (default, com.lomoware.screen_translate,
what every command above builds when --flavor is left out) and `lite`
(com.lomoware.screen_translate.lite, daily free limit + Pro unlock). The
flavor is also passed to Dart as --dart-define APP_FLAVOR=<flavor>.

Every build syncs the version from pubspec.yaml, regenerates localizations,
runs Gradle on JDK 17-23 (Android Studio's bundled JBR 25 can't run this
Gradle, which is why `flutter build` fails here), then checks the output:
versionCode/versionName must equal pubspec.yaml's, and release builds must
not be DEBUG-signed. Gradle daemons are stopped afterwards (~2 GB each).

APKs are single-ABI via -Pabi (see android/app/build.gradle), not Flutter's
split-per-abi, which adds 1000*ABI to versionCode (1.2.1+11 became 2011 on
arm64) and would put a sideloaded build above Play's versions.

tools/release.py builds through this module.
"""

import argparse
import base64
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"
PUBSPEC = ROOT / "pubspec.yaml"
PACKAGE = "com.lomoware.screen_translate"
# Gradle product flavor -> applicationId. "paid" is the default everywhere.
FLAVORS = {"paid": PACKAGE, "lite": PACKAGE + ".lite"}
DEFAULT_FLAVOR = "paid"
OUTPUTS = ROOT / "build" / "app" / "outputs"
LITE_GOOGLE_SERVICES = ANDROID / "app" / "src" / "lite" / "google-services.json"
IS_WINDOWS = os.name == "nt"


def output_path(target, flavor=DEFAULT_FLAVOR):
    """Where Gradle writes `target` for `flavor` (AGP's flavored layout)."""
    kind = {"aab": "bundle", "apk": "release", "emulator": "debug"}[target]
    if kind == "bundle":
        return OUTPUTS / "bundle" / f"{flavor}Release" / f"app-{flavor}-release.aab"
    return OUTPUTS / "apk" / flavor / kind / f"app-{flavor}-{kind}.apk"


def mapping_path(flavor=DEFAULT_FLAVOR):
    return OUTPUTS / "mapping" / f"{flavor}Release" / "mapping.txt"


AAB = output_path("aab")
MAPPING = mapping_path()
RELEASE_APK = output_path("apk")
DEBUG_APK = output_path("emulator")

# target: (gradle task, flutter target-platform, ABI, release-signed). The
# task gets the flavor inserted: assembleRelease -> assemblePaidRelease.
TARGETS = {
    "aab": ("bundleRelease", None, None, True),
    "apk": ("assembleRelease", "android-arm64", "arm64-v8a", True),
    "emulator": ("assembleDebug", "android-x64", "x86_64", False),
}


def flavored_task(task, flavor):
    m = re.fullmatch(r"(assemble|bundle)(Debug|Release)", task)
    if not m:
        raise BuildError(f"unknown Gradle task {task}")
    return f"{m.group(1)}{flavor.capitalize()}{m.group(2)}"


def dart_defines(flavor):
    """Flutter's Gradle plugin takes dart-defines as comma-separated base64."""
    return base64.b64encode(f"APP_FLAVOR={flavor}".encode()).decode()


def check_lite_firebase(path=None):
    """Lite release builds need the lite app's own Firebase config; without
    it build.gradle skips google-services and the app ships without Firebase."""
    path = path or LITE_GOOGLE_SERVICES
    if not path.exists():
        raise BuildError(f"{path} is missing: download it from the Firebase console "
                         "(android/app/src/lite/README.md) before a lite release build")
    try:
        clients = json.loads(path.read_text(encoding="utf-8")).get("client", [])
    except ValueError as e:
        raise BuildError(f"{path} is not valid JSON: {e}")
    names = {c.get("client_info", {}).get("android_client_info", {}).get("package_name")
             for c in clients}
    if FLAVORS["lite"] not in names:
        raise BuildError(f"{path} has no Android app {FLAVORS['lite']} (found: "
                         f"{', '.join(sorted(filter(None, names))) or 'none'})")


class BuildError(Exception):
    pass


def run(cmd, cwd=ROOT, env=None, capture=False):
    """Runs cmd, raising BuildError on failure. Output streams unless captured."""
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
        raise BuildError(f"command failed ({res.returncode}): {' '.join(map(str, cmd))}")
    return res.stdout if capture else ""


# --------------------------------------------------------------------------
# Version


def read_version(flavor=DEFAULT_FLAVOR):
    """(versionName, versionCode) for one flavor, both from pubspec.yaml.

    Each flavor carries its own name and build number: the flavors are
    separate Play listings, so neither should have to move because the other
    released. `version:` is the paid app's, because that is the line Flutter
    itself reads; the rest live under flavor_versions.
    """
    text = PUBSPEC.read_text(encoding="utf-8")
    if flavor == DEFAULT_FLAVOR:
        m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", text, re.M)
        if not m:
            raise BuildError('pubspec.yaml has no "version: x.y.z+n" line')
        return m.group(1), int(m.group(2))
    if flavor not in FLAVORS:
        raise BuildError(f"unknown flavor {flavor} (one of {', '.join(FLAVORS)})")
    version = flavor_versions(text).get(flavor)
    if version is None:
        raise BuildError(f'pubspec.yaml has no "{flavor}: x.y.z+n" line under '
                         "flavor_versions")
    return version


def flavor_versions(text):
    """The flavor_versions block as {flavor: (name, code)}.

    Parsed rather than loaded with a YAML library: build.py has no
    third-party dependencies, and the block is one "name: x.y.z+n" per line.
    The lookahead stops at the next top-level key, so `environment:` below it
    is not swallowed.
    """
    block = re.search(r"^flavor_versions:\s*$(.*?)(?=^\S|\Z)", text, re.M | re.S)
    if not block:
        return {}
    return {f: (name, int(code)) for f, name, code in re.findall(
        r"^\s+(\w+):\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", block.group(1), re.M)}


def write_local_versions(name, code):
    """The Gradle build reads the version from android/local.properties,
    which only `flutter build` would otherwise refresh from pubspec.yaml.

    flutter.versionName/versionCode are the flavor being built, for the
    Flutter tooling and for defaultConfig. Every flavor's own pair is written
    too, as flutter.version{Name,Code}.<flavor>, so a flavor's build gets its
    own version even when Gradle is invoked for a different one than was last
    synced.
    """
    path = ANDROID / "local.properties"
    lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    wanted = {"flutter.versionName": name, "flutter.versionCode": str(code)}
    for f in FLAVORS:
        try:
            f_name, f_code = read_version(f)
        except BuildError:
            continue   # no version for that flavor; its block falls back
        wanted[f"flutter.versionName.{f}"] = f_name
        wanted[f"flutter.versionCode.{f}"] = str(f_code)
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
# Toolchain


def java_major(java):
    out = subprocess.run([str(java), "-version"], capture_output=True, text=True).stderr
    m = re.search(r'version "(\d+)(?:\.(\d+))?', out)
    if not m:
        return 0
    major = int(m.group(1))
    return int(m.group(2) or 0) if major == 1 else major


def find_java_home(explicit=None):
    for home in filter(None, [explicit, os.environ.get("RELEASE_JAVA_HOME"),
                              os.environ.get("JAVA_HOME")]):
        java = Path(home) / "bin" / ("java.exe" if IS_WINDOWS else "java")
        if not java.exists():
            continue
        major = java_major(java)
        if 17 <= major <= 23:
            return Path(home)
        print(f"  skipping {home}: Java {major} (this Gradle version runs on 17-23)")
    raise BuildError("no usable JDK 17-23 found; pass --java-home or set RELEASE_JAVA_HOME")


def build_tools():
    """Newest Android SDK build-tools dir (for aapt2 and apksigner)."""
    sdk = None
    props = ANDROID / "local.properties"
    if props.exists():
        m = re.search(r"^sdk\.dir=(.+)$", props.read_text(encoding="utf-8"), re.M)
        if m:
            sdk = Path(re.sub(r"\\(.)", r"\1", m.group(1).strip()))
    sdk = sdk or Path(os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT", ""))
    versions = sorted((sdk / "build-tools").glob("*"),
                      key=lambda p: [int(x) for x in re.findall(r"\d+", p.name)])
    if not versions:
        raise BuildError(f"no Android build-tools under {sdk}; set sdk.dir or ANDROID_HOME")
    return versions[-1]


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
        raise BuildError(f"release keystore not found: {store} (the build would fall "
                         "back to DEBUG signing, which Play rejects)")
    for key, env in (("storePassword", "KEYSTORE_PASSWORD"), ("keyPassword", "KEY_PASSWORD")):
        if not values.get(key) and not os.environ.get(env):
            raise BuildError(f"{key} is not set in android/key.properties or ${env}")


def gradle(tasks, java_home):
    wrapper = ANDROID / ("gradlew.bat" if IS_WINDOWS else "gradlew")
    run([wrapper, *tasks], cwd=ANDROID, env=dict(os.environ, JAVA_HOME=str(java_home)))


def stop_gradle(java_home):
    """Gradle daemons hold ~2 GB each long after a one-off build."""
    try:
        gradle(["--stop"], java_home)
    except BuildError:
        pass


# --------------------------------------------------------------------------
# Output checks


def check_signature(java_home, path=AAB):
    """App Bundles are jar-signed; keytool reads the certificate."""
    keytool = java_home / "bin" / ("keytool.exe" if IS_WINDOWS else "keytool")
    out = run([keytool, "-J-Duser.language=en", "-printcert", "-jarfile", path], capture=True)
    owner = re.search(r"^Owner:\s*(.+)$", out, re.M)
    if not owner:
        raise BuildError("could not read the bundle's signing certificate:\n" + out)
    if "CN=Android Debug" in owner.group(1):
        raise BuildError("the bundle is DEBUG-signed; check android/key.properties")
    sha = re.search(r"SHA256:\s*(\S+)", out)
    print(f"  signed by {owner.group(1)}\n  SHA-256 {sha.group(1) if sha else '?'}")


def check_apk(path, name, code, release, package=PACKAGE):
    """APK version must match pubspec.yaml, its package the flavor's, and
    release APKs must not be debug-signed."""
    tools = build_tools()
    aapt2 = tools / ("aapt2.exe" if IS_WINDOWS else "aapt2")
    badging = run([aapt2, "dump", "badging", path], capture=True)
    pkg = re.search(r"package: name='([^']+)'", badging)
    if not pkg or pkg.group(1) != package:
        raise BuildError(f"{path.name} is package {pkg.group(1) if pkg else '?'}, "
                         f"expected {package}")
    m = re.search(r"versionCode='(\d+)' versionName='([^']*)'", badging)
    if not m or (int(m.group(1)), m.group(2)) != (code, name):
        raise BuildError(f"{path.name} has version {m.groups() if m else '?'}, "
                         f"expected ({code}, {name}) from pubspec.yaml")
    abis = re.search(r"^native-code: (.+)$", badging, re.M)
    print(f"  version {name} ({code}), ABIs {abis.group(1) if abis else '?'}")
    signer = tools / ("apksigner.bat" if IS_WINDOWS else "apksigner")
    certs = run([signer, "verify", "--print-certs", path], capture=True)
    dn = re.search(r"certificate DN: (.+)", certs)
    dn = dn.group(1).strip() if dn else "?"
    if release and "CN=Android Debug" in dn:
        raise BuildError(f"{path.name} is DEBUG-signed; check android/key.properties")
    print(f"  signed by {dn}")


# --------------------------------------------------------------------------
# Build


def prepare(name, code):
    """Everything `flutter build` would do before invoking Gradle."""
    run(["flutter", "pub", "get"])
    run(["flutter", "gen-l10n"])
    write_local_versions(name, code)


def build(target, java_home, name, code, flavor=DEFAULT_FLAVOR):
    """Builds and checks one target of one flavor; returns the output path."""
    if flavor not in FLAVORS:
        raise BuildError(f"unknown flavor {flavor} (one of {', '.join(FLAVORS)})")
    task, platform, abi, release = TARGETS[target]
    out = output_path(target, flavor)
    if release:
        check_keystore()
        if flavor == "lite":
            check_lite_firebase()
    prepare(name, code)
    # When nothing changed Gradle skips repackaging and leaves the old file
    # in place; removing it guarantees the output is from this build.
    out.unlink(missing_ok=True)
    args = [flavored_task(task, flavor), f"-Pdart-defines={dart_defines(flavor)}"]
    if platform:
        # disable-abi-filtering stops the Flutter plugin from replacing our
        # abiFilters with all ABIs (FlutterPlugin.configureAbiWithoutSplits).
        args += [f"-Ptarget-platform={platform}", f"-Pabi={abi}",
                 "-Pdisable-abi-filtering=true"]
    gradle(args, java_home)
    if not out.exists():
        raise BuildError(f"the build produced nothing at {out}")
    print(f"  {out.relative_to(ROOT)} ({out.stat().st_size / 2**20:.1f} MB)")
    if target == "aab":
        check_signature(java_home, out)
    else:
        check_apk(out, name, code, release, FLAVORS[flavor])
    return out


INSTALL_HINTS = {
    "INSTALL_FAILED_VERSION_DOWNGRADE":
        "the installed app has a higher versionCode (e.g. an old split-per-abi build)",
    "INSTALL_FAILED_UPDATE_INCOMPATIBLE":
        "the installed app is signed with a different key (debug vs release, or Play's key)",
}


def install(apk, serial, package=PACKAGE):
    """Installs over the current app, keeping its data. adb refuses, and
    changes nothing, if the installed app is newer or signed differently."""
    print(f"  installing on {serial}")
    res = subprocess.run(["adb", "-s", serial, "install", "-r", str(apk)],
                         capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = (res.stdout or "") + (res.stderr or "")
    if res.returncode == 0 and "Success" in out:
        print("  installed")
        return
    for code, why in INSTALL_HINTS.items():
        if code in out:
            raise BuildError(f"{serial} refused the install: {why}. Uninstalling the app "
                             f"first would fix it, but that clears its data "
                             f"(adb -s {serial} uninstall {package})")
    raise BuildError(f"adb install on {serial} failed:\n{out.strip()}")


def main():
    sys.stdout.reconfigure(line_buffering=True)
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("target", choices=TARGETS)
    p.add_argument("--flavor", choices=FLAVORS, default=DEFAULT_FLAVOR,
                   help="paid (default, com.lomoware.screen_translate) or lite "
                        "(com.lomoware.screen_translate.lite)")
    p.add_argument("--install", metavar="SERIAL",
                   help="adb serial to install the APK on (adb devices)")
    p.add_argument("--java-home", help="JDK 17-23 (default: $RELEASE_JAVA_HOME, $JAVA_HOME)")
    args = p.parse_args()
    if args.install and args.target == "aab":
        p.error("--install needs an APK target (apk or emulator)")

    java_home = None
    try:
        java_home = find_java_home(args.java_home)
        name, code = read_version(args.flavor)
        print(f"==> Building {args.target} ({args.flavor}) {name} ({code}) with {java_home}")
        out = build(args.target, java_home, name, code, args.flavor)
        if args.install:
            install(out, args.install, FLAVORS[args.flavor])
    except BuildError as e:
        print(f"\nBuild failed: {e}", file=sys.stderr)
        return 1
    finally:
        if java_home:
            stop_gradle(java_home)
    print(f"\nBuilt {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

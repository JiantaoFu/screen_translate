import sys
import re
import os

DEFAULT_FLAVOR = "paid"


def bump_flavor_code(content, flavor):
    """Raise one flavor's build number under flavor_version_codes."""
    m = re.search(rf'^(\s+{re.escape(flavor)}:\s*)(\d+)\s*$', content, re.MULTILINE)
    if not m:
        print(f'Could not find "{flavor}:" under flavor_version_codes in pubspec.yaml')
        sys.exit(1)
    old = int(m.group(2))
    content = content[:m.start()] + f"{m.group(1)}{old + 1}" + content[m.end():]
    return content, old, old + 1


def main():
    if len(sys.argv) < 2:
        print("Usage: python bump_version.py [major|minor|patch|build] [--flavor paid|lite]")
        sys.exit(1)

    bump_type = sys.argv[1].lower()
    # versionCode is per flavor (see pubspec.yaml), so a bump has to say which
    # app it is for. The x.y.z name stays shared: one codebase, one marketing
    # version, and both listings show it.
    flavor = DEFAULT_FLAVOR
    if "--flavor" in sys.argv:
        i = sys.argv.index("--flavor")
        if i + 1 >= len(sys.argv):
            print("--flavor needs a value (paid or lite)")
            sys.exit(1)
        flavor = sys.argv[i + 1].lower()
    
    pubspec_path = "pubspec.yaml"
    if not os.path.exists(pubspec_path):
        pubspec_path = "../pubspec.yaml"
        if not os.path.exists(pubspec_path):
            print("Could not find pubspec.yaml")
            sys.exit(1)
        
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    match = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)$', content, re.MULTILINE)
    if not match:
        print("Could not find version string in format x.y.z+n in pubspec.yaml")
        sys.exit(1)
        
    major, minor, patch, build = map(int, match.groups())
    old_version = f"{major}.{minor}.{patch}+{build}"

    if bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    elif bump_type == 'patch':
        patch += 1
    elif bump_type != 'build':
        print(f"Unknown bump type: {bump_type}")
        sys.exit(1)

    if flavor == DEFAULT_FLAVOR:
        build += 1
        new_version = f"{major}.{minor}.{patch}+{build}"
        content = content[:match.start()] + f"version: {new_version}" + content[match.end():]
        bumped = f"{old_version} -> {new_version}"
    else:
        # Rewrite the name in place (shared), and raise only this flavor's
        # build number, leaving the paid app's where it is.
        new_version = f"{major}.{minor}.{patch}+{build}"
        content = content[:match.start()] + f"version: {new_version}" + content[match.end():]
        content, old_code, new_code = bump_flavor_code(content, flavor)
        bumped = (f"{old_version} -> {new_version} (paid build number untouched), "
                  f"{flavor} build number {old_code} -> {new_code}")

    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Bumped version ({flavor}): {bumped}")

if __name__ == "__main__":
    main()

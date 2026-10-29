import sys
import re
import os

DEFAULT_FLAVOR = "paid"

# Each flavor has its own "x.y.z+n" in pubspec.yaml: `version:` for paid,
# and one line per other flavor under flavor_versions. A bump moves exactly
# one of them, so releasing one app never shifts the other's version.
VERSION_RE = r"(\d+)\.(\d+)\.(\d+)\+(\d+)"


def bumped(old, bump_type):
    major, minor, patch, build = old
    if bump_type == 'major':
        major, minor, patch = major + 1, 0, 0
    elif bump_type == 'minor':
        minor, patch = minor + 1, 0
    elif bump_type == 'patch':
        patch += 1
    elif bump_type != 'build':
        print(f"Unknown bump type: {bump_type}")
        sys.exit(1)
    return major, minor, patch, build + 1


def main():
    if len(sys.argv) < 2:
        print("Usage: python bump_version.py [major|minor|patch|build] "
              "[--flavor paid|lite]")
        sys.exit(1)

    bump_type = sys.argv[1].lower()
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

    if flavor == DEFAULT_FLAVOR:
        # paid owns the `version:` line, the one Flutter itself reads.
        pattern = rf"^(version:\s*){VERSION_RE}\s*$"
        where = "pubspec.yaml's version: line"
    else:
        # Only this flavor's line under flavor_versions.
        pattern = rf"^(\s+{re.escape(flavor)}:\s*){VERSION_RE}\s*$"
        where = f"the {flavor}: line under flavor_versions"

    match = re.search(pattern, content, re.MULTILINE)
    if not match:
        print(f"Could not find an x.y.z+n version in {where} in pubspec.yaml")
        sys.exit(1)

    old = tuple(map(int, match.groups()[1:]))
    new = bumped(old, bump_type)
    old_version = "{}.{}.{}+{}".format(*old)
    new_version = "{}.{}.{}+{}".format(*new)
    content = (content[:match.start()] + match.group(1) + new_version
               + content[match.end():])

    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Bumped {flavor} version: {old_version} -> {new_version}")

if __name__ == "__main__":
    main()

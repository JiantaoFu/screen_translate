import sys
import re
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python bump_version.py [major|minor|patch|build]")
        sys.exit(1)
        
    bump_type = sys.argv[1].lower()
    
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
        build += 1
    elif bump_type == 'minor':
        minor += 1
        patch = 0
        build += 1
    elif bump_type == 'patch':
        patch += 1
        build += 1
    elif bump_type == 'build':
        build += 1
    else:
        print(f"Unknown bump type: {bump_type}")
        sys.exit(1)
        
    new_version = f"{major}.{minor}.{patch}+{build}"
    
    content = content[:match.start()] + f"version: {new_version}" + content[match.end():]
    
    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Bumped version: {old_version} -> {new_version}")

if __name__ == "__main__":
    main()

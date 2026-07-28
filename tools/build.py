"""Package the mod for Vortex/Nexus as dist/mod_AC_<version>.zip

    python tools/build.py

The version is read from the single source of truth -- ::AC.Version in
scripts/!mods_preload/mod_AC.nut -- so the archive name can never drift from
what the mod reports to Hooks/MSU at runtime.

Uses zipfile rather than PowerShell's Compress-Archive on purpose: Compress-Archive
writes entry names with backslash separators, which the ZIP spec does not allow
(4.4.17.1 requires forward slashes). Battle Brothers happens to tolerate it, but
other tooling does not, so we write conforming archives.
"""

import os
import re
import sys
import zipfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRY = os.path.join(REPO, "scripts", "!mods_preload", "mod_AC.nut")
SHIPPED = ("scripts", "gfx", "ui", "mod_AC")   # docs/, tools/, .refs/, .git/ stay out


def read_version():
    with open(ENTRY, encoding="utf-8") as fh:
        m = re.search(r'Version\s*=\s*"([^"]+)"', fh.read())
    if not m:
        sys.exit(f"could not read Version from {ENTRY}")
    return m.group(1)


def main():
    version = read_version()
    dist = os.path.join(REPO, "dist")
    os.makedirs(dist, exist_ok=True)

    # Drop previous builds so dist/ never offers two candidate archives.
    for stale in os.listdir(dist):
        if stale.startswith("mod_AC") and stale.endswith(".zip"):
            os.remove(os.path.join(dist, stale))

    target = os.path.join(dist, f"mod_AC_{version}.zip")
    count = 0

    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
        for folder in SHIPPED:
            root = os.path.join(REPO, folder)
            if not os.path.isdir(root):
                sys.exit(f"missing content folder: {root}")
            for dirpath, dirnames, filenames in os.walk(root):
                dirnames[:] = [d for d in dirnames if d != "__pycache__"]
                for name in sorted(filenames):
                    full = os.path.join(dirpath, name)
                    arc = os.path.relpath(full, REPO).replace(os.sep, "/")
                    zf.write(full, arc)
                    count += 1

    size = os.path.getsize(target) / (1024 * 1024)
    print(f"built dist/mod_AC_{version}.zip  ({count} files, {size:.2f} MB)")


if __name__ == "__main__":
    main()

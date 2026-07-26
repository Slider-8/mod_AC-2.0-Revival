#!/usr/bin/env bash
# Rebuild the reference trees that tools/check_mod.py resolves script paths against.
#
# These are large and derived, so they are not committed. Run this once per
# machine (or once per fresh session, if you point it at a temp dir).
#
#   bash tools/setup_refs.sh [target-dir]
#
# Default target is ./.refs inside the repo, which .gitignore excludes.
# Then run the checker against it:
#   python tools/check_mod.py --refs .refs

set -euo pipefail

TARGET="${1:-$(cd "$(dirname "$0")/.." && pwd)/.refs}"
GAME_DATA="C:/Games/Steam/steamapps/common/Battle Brothers/data"

mkdir -p "$TARGET"

# 1. Vanilla script reference.
#    Community decompile. Code structure and identifiers are accurate; string
#    literals are Chinese-localised, so never use this for English text matching.
if [ ! -d "$TARGET/vanilla" ]; then
    echo "cloning vanilla script reference..."
    git clone --depth 1 -q https://github.com/ninkjin/Battle-Brothers-Scripts.git "$TARGET/vanilla"
fi
echo "vanilla: $(find "$TARGET/vanilla" -name '*.nut' | wc -l) .nut files"

# 2. Framework mods, taken from the live game install so versions match what
#    actually runs. Adjust the archive names if the installed versions change.
mkdir -p "$TARGET/refs"
for pattern in mod_reforged_core mod_msu-479 mod_modern_hooks stdlib_ mod_modular_vanilla; do
    archive=$(ls "$GAME_DATA"/${pattern}*.zip 2>/dev/null | grep -v '\.bak$' | head -1 || true)
    if [ -z "$archive" ]; then
        echo "  WARNING: no archive matching '${pattern}*' in $GAME_DATA"
        continue
    fi
    name=$(basename "$archive" .zip)
    if [ ! -d "$TARGET/refs/$name" ]; then
        unzip -q -o "$archive" -d "$TARGET/refs/$name"
    fi
    echo "  $name: $(find "$TARGET/refs/$name" -name '*.nut' | wc -l) .nut files"
done

echo
echo "done. verify with:  python tools/check_mod.py --refs \"$TARGET\""

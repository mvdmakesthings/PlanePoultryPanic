#!/usr/bin/env bash
# Exports the Web build and publishes it to the public play repo, which
# serves it with GitHub Pages at
# https://mvdmakesthings.github.io/plane-poultry-panic-play/
#
# Run from the repo root after setting the version in game/project.godot:
#   tools/publish_web.sh
#
# The play repo only holds the exported files plus its own README.md and
# .nojekyll; this script replaces the exported files and leaves those two.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PLAY_REPO="git@github.com:mvdmakesthings/plane-poultry-panic-play.git"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

version="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' "$ROOT/game/project.godot")"
if [ -z "$version" ]; then
	echo "No config/version in game/project.godot" >&2
	exit 1
fi

echo "Exporting the Web build for v$version..."
mkdir -p "$ROOT/build/web"
"$GODOT" --headless --path "$ROOT/game" --export-release "Web"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git clone --quiet "$PLAY_REPO" "$work/play"

# Mirror the export into the play repo, keeping its README and .nojekyll.
rsync -a --delete --exclude .git --exclude README.md --exclude .nojekyll \
	"$ROOT/build/web/" "$work/play/"
sed -i '' "s/^Current version: v[^,]*,/Current version: v$version,/" "$work/play/README.md"

cd "$work/play"
git add -A
if git diff --cached --quiet; then
	echo "The play repo already has this build; nothing to publish."
	exit 0
fi
git commit --quiet -m "Publish the v$version web build"
git push --quiet origin main
echo "Published v$version. GitHub Pages updates in a minute or two:"
echo "https://mvdmakesthings.github.io/plane-poultry-panic-play/"

#!/usr/bin/env bash
# Exports the Web build and publishes it in two places:
#   - the public play repo, served with GitHub Pages at
#     https://planepoultrypanic.mvdmakesthings.com/
#   - the itch.io page, mvdmakesthings.itch.io/plane-poultry-panic
#     (html5 channel), using butler
#
# Run from the repo root after setting the version in game/project.godot:
#   tools/publish_web.sh
# Set SKIP_ITCH=1 to publish only to GitHub Pages.
#
# The play repo holds the exported files plus its own README.md, .nojekyll
# and CNAME (the custom domain); this script replaces the exported files and
# leaves those three alone.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
BUTLER="${BUTLER:-$HOME/.local/share/butler/butler}"
PLAY_REPO="git@github.com:mvdmakesthings/plane-poultry-panic-play.git"
ITCH_TARGET="mvdmakesthings/plane-poultry-panic:html5"
SITE_URL="https://planepoultrypanic.mvdmakesthings.com/"
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

# Mirror the export into the play repo, keeping its README, .nojekyll and CNAME.
rsync -a --delete --exclude .git --exclude README.md --exclude .nojekyll --exclude CNAME \
	"$ROOT/build/web/" "$work/play/"
sed -i '' "s/^Current version: v[^,]*,/Current version: v$version,/" "$work/play/README.md"

(
	cd "$work/play"
	git add -A
	if git diff --cached --quiet; then
		echo "GitHub Pages already has this build; nothing to publish there."
	else
		git commit --quiet -m "Publish the v$version web build"
		git push --quiet origin main
		echo "Published v$version to GitHub Pages; it updates in a minute or two:"
		echo "$SITE_URL"
	fi
)

if [ "${SKIP_ITCH:-0}" = "1" ]; then
	echo "Skipping itch.io (SKIP_ITCH=1)."
elif [ ! -x "$BUTLER" ]; then
	echo "butler not found at $BUTLER; skipping itch.io. See the README to install it." >&2
else
	echo "Pushing v$version to itch.io ($ITCH_TARGET)..."
	"$BUTLER" push "$ROOT/build/web" "$ITCH_TARGET" --userversion "$version"
fi

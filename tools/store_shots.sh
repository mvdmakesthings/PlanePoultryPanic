#!/usr/bin/env bash
# Captures the store-page screenshots: game/tests/store_shots.tscn stages
# five moments (one per level) and saves each screen at 1280x720 (the
# 320x180 game scaled 4x) to docs/images/screenshot_N.png. Opens a game
# window briefly for each. Run from the repo root.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

for shot in 1 2 3 4 5; do
	"$GODOT" --path "$ROOT/game" res://tests/store_shots.tscn -- \
		--shot="$shot" --out="$ROOT/docs/images/screenshot_$shot.png" > "$log" 2>&1
	if grep -qiE "error|warning" "$log"; then
		echo "shot $shot: Godot reported problems:" >&2
		grep -iE "error|warning" "$log" >&2
	fi
	echo "saved docs/images/screenshot_$shot.png"
done

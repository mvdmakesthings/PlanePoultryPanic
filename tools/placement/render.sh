#!/usr/bin/env bash
# Renders whole levels for checking furniture and decor placement, then
# slices each into 2x-scale panels about 1000px wide that are easy to
# inspect. Opens a game window briefly per level. Run from the repo root:
#   tools/placement/render.sh OUT_DIR [--mark] [level_01_arrivals ...]
# With no level names it renders all five. --mark outlines collision bases
# and labels every entity (see game/tests/placement_render.gd). Writes
# OUT_DIR/<level>.png plus OUT_DIR/<level>_<n>.png panels.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
out="$1"
shift
mark=""
if [ "${1:-}" = "--mark" ]; then
	mark="--mark"
	shift
fi
levels=("$@")
if [ ${#levels[@]} -eq 0 ]; then
	levels=(level_01_arrivals level_02_security level_03_food_court level_04_gates level_05_final_gate)
fi
mkdir -p "$out"

for level in "${levels[@]}"; do
	"$GODOT" --path "$ROOT/game" res://tests/placement_render.tscn -- \
		--level="res://scenes/levels/$level.tscn" --out="$out/$level.png" $mark > /dev/null 2>&1
	python3 - "$out/$level.png" <<'PY'
import sys
from PIL import Image
path = sys.argv[1]
image = Image.open(path)
image = image.resize((image.width * 2, image.height * 2), Image.NEAREST)
panels = max(1, round(image.width / 1000))
for n in range(panels):
    left, right = n * image.width // panels, (n + 1) * image.width // panels
    image.crop((left, 0, right, image.height)).save(path.replace(".png", f"_{n}.png"))
print(f"{path}: {panels} panel(s), each covering {image.width // panels // 2}px of the level")
PY
done

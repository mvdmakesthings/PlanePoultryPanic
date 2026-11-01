"""Moves, removes and restyles props in level scenes from a JSON spec, so a
whole placement pass is one reviewable file instead of hand edits:

    cd game && python3 ../tools/placement/edit_scene.py spec.json

The spec maps a level (file name without .tscn) to any of:
    "move":   {"PlantA": [60, 414]}           new position, in world pixels
    "remove": ["KioskC"]                      delete the node
    "set":    {"SecurityGantry": {"z_index": 1}}   add or replace properties
    "unset":  {"TotemA": ["frame"]}           drop properties
    "frame":  {"TotemA": 3}                   pick a frame on an instanced prop's
                                              Sprite2D (setting frame on the prop's
                                              root does nothing: it's a StaticBody2D)
Nodes are matched by name. Every name must exist, or nothing is written.
ext_resources nothing uses any more are dropped.
"""
import json
import re
import sys


def edit(path, move=(), remove=(), set=(), unset=(), frame=()):
    move, remove, set, unset, frame = dict(move), list(remove), dict(set), dict(unset), dict(frame)
    text = open(path).read()
    blocks = re.split(r"(?=^\[)", text, flags=re.M)
    out = []
    for block in blocks:
        head = re.match(r'\[node name="([^"]+)"(?: type="[^"]+")? parent="([^"]+)"', block)
        name = head.group(1) if head else None
        if name in remove:
            remove.remove(name)
            continue
        # A frame override from an earlier pass gets rewritten below.
        if head and name == "Sprite2D" and head.group(2).removeprefix("Entities/") in frame:
            continue
        if name in move:
            x, y = move.pop(name)
            block, count = re.subn(r"^position = Vector2\([^)]*\)", f"position = Vector2({x}, {y})", block, flags=re.M)
            if count != 1:
                sys.exit(f"{path}: {name} has no position to move")
        for prop in unset.pop(name, []):
            block = re.sub(rf"^{prop} = .*\n", "", block, flags=re.M)
        for prop, value in set.pop(name, {}).items():
            if re.search(rf"^{prop} = ", block, flags=re.M):
                block = re.sub(rf"^{prop} = .*$", f"{prop} = {value}", block, flags=re.M)
            else:
                block = block.rstrip("\n") + f"\n{prop} = {value}\n\n"
        out.append(block)
    missing = [*move, *remove, *set, *unset]
    if missing:
        sys.exit(f"{path}: no node named {', '.join(missing)}; nothing written")
    text = "".join(out).rstrip("\n") + "\n"
    for name, value in frame.items():
        if f'[node name="{name}" parent="Entities"' not in text:
            sys.exit(f"{path}: no Entities/{name} to set a frame on; nothing written")
        text += f'\n[node name="Sprite2D" parent="Entities/{name}" index="0"]\nframe = {value}\n'
    for rid in re.findall(r'^\[ext_resource [^\n]*id="([^"]+)"\]$', text, flags=re.M):
        if text.count(f'"{rid}"') == 1:
            text = re.sub(rf'^\[ext_resource [^\n]*id="{re.escape(rid)}"\]\n', "", text, flags=re.M)
    open(path, "w").write(text)


if __name__ == "__main__":
    for level, changes in json.load(open(sys.argv[1])).items():
        edit(f"scenes/levels/{level}.tscn", **changes)
        print(f"edited {level}")

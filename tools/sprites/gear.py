"""Usable gear and the maintenance-key variants.

- item_skates.png: a 12x10 roller skate, HUD icon and pickup.
- item_energy_drink.png: a 7x12 can of energy drink, HUD icon and pickup.
- item_umbrella.png: a 12x12 open umbrella, HUD icon and pickup.
- item_fuse.png: a 10x6 glass fuse with brass caps, a key item.
- item_lever_handle.png: a 12x8 lever handle with a red knob, a key item.
- item_staff_badge.png: a 10x12 staff badge on a clip, a key item.
- player_umbrella.png: the open umbrella held in front of Amanda, 20x16
  frames, one per direction (down, up, right, left).
- player_skates.png: skates on Amanda's feet, 12x5 frames, one per
  direction (down, up, right, left).
- fuse_box.png: a 12x14 wall fuse box, 2 frames (empty, fuse fitted).
- lever_socket.png: a 12x14 wall socket for the lever handle, 3 frames
  (empty, lever up, lever down).
- staff_door.png: a 16x32 STAFF ONLY door for the wall face, 2 frames
  (badge reader red, green).
"""
from set_dressing import _blank, _outline, _rect, _strip
from palette import put, to_image


def _icon(grid):
    return to_image(_outline(grid))


# --- Usable items ---------------------------------------------------------

def skates():
    """A red high-top roller skate side on, white toe, two white wheels."""
    g = _blank(12, 10)
    _rect(g, 2, 1, 5, 6, "R")
    _rect(g, 6, 4, 9, 6, "R")
    _rect(g, 9, 5, 10, 6, "C")
    _rect(g, 2, 1, 2, 6, "r")
    put(g, 2, 4, "C")
    put(g, 3, 4, "C")
    put(g, 4, 5, "CC")
    _rect(g, 1, 7, 10, 7, "w")
    for x in (2, 8):
        _rect(g, x, 8, x + 1, 8, "C")
    return _icon(g)


def energy_drink():
    """A tall green can with a yellow lightning bolt and a silver top."""
    g = _blank(7, 12)
    _rect(g, 1, 1, 5, 10, "g")
    _rect(g, 1, 1, 5, 1, "W")
    _rect(g, 1, 10, 5, 10, "w")
    _rect(g, 5, 2, 5, 9, "j")
    _rect(g, 1, 2, 1, 9, "l")
    for x, y in ((4, 3), (3, 4), (2, 5), (3, 5), (4, 5), (3, 6), (2, 7)):
        put(g, y, x, "F")
    return _icon(g)


def umbrella():
    """An open umbrella: red and white panels and a hooked handle."""
    g = _blank(12, 12)
    for y in range(1, 6):
        half = (2, 4, 5, 5, 5)[y - 1]
        for x in range(6 - half, 6 + half):
            put(g, y, x, "R" if (x // 2) % 2 == 0 else "C")
    put(g, 0, 5, "w")
    _rect(g, 5, 6, 5, 9, "w")
    put(g, 10, 5, "w")
    put(g, 10, 4, "w")
    put(g, 9, 3, "w")
    return _icon(g)


# --- Key items ------------------------------------------------------------

def fuse():
    """A glass cartridge fuse with brass end caps and a wire inside."""
    g = _blank(10, 6)
    _rect(g, 1, 1, 2, 4, "Y")
    _rect(g, 7, 1, 8, 4, "Y")
    _rect(g, 3, 1, 6, 4, "W")
    _rect(g, 3, 1, 6, 1, "C")
    _rect(g, 3, 3, 6, 3, "y")
    put(g, 4, 1, "y")
    put(g, 4, 8, "y")
    return _icon(g)


def lever_handle():
    """A steel lever handle with a square end and a red ball knob."""
    g = _blank(12, 8)
    _rect(g, 1, 3, 2, 5, "w")
    _rect(g, 3, 4, 8, 4, "W")
    _rect(g, 3, 5, 8, 5, "w")
    _rect(g, 8, 2, 10, 5, "R")
    put(g, 2, 8, "C")
    put(g, 5, 10, "r")
    return _icon(g)


def staff_badge():
    """A white ID card on a clip: a photo, a name line and a blue stripe."""
    g = _blank(10, 12)
    _rect(g, 4, 1, 5, 2, "w")
    _rect(g, 1, 3, 8, 10, "C")
    _rect(g, 1, 3, 8, 4, "B")
    _rect(g, 2, 6, 4, 8, "S")
    put(g, 6, 2, "HHH")
    _rect(g, 5, 6, 7, 6, "w")
    _rect(g, 5, 8, 7, 8, "w")
    _rect(g, 1, 10, 8, 10, "c")
    return _icon(g)


# --- Worn and held overlays -----------------------------------------------

UMBRELLA_W, UMBRELLA_H = 20, 16


def _canopy_front(g, cx, top, half, rows):
    """A dome of alternating red and white panels, seen from the front."""
    for i in range(rows):
        w = half if i > 1 else half - (2 - i) * 3
        for x in range(cx - w, cx + w):
            put(g, top + i, x, "R" if ((x - cx + 20) // 3) % 2 == 0 else "C")
    # Scalloped rim between the rib tips.
    for x in range(cx - half, cx + half):
        if ((x - cx + 20) % 3) == 1:
            put(g, top + rows, x, "r")


def player_umbrella(direction):
    g = _blank(UMBRELLA_W, UMBRELLA_H)
    if direction == "down":
        # Facing us: the dome hides her chest and the handle drops below it.
        _canopy_front(g, 10, 1, 9, 7)
        put(g, 0, 10, "w")
        _rect(g, 10, 9, 10, 13, "w")
        put(g, 14, 9, "w")
    elif direction == "up":
        # Facing away: the dome is beyond her, seen from inside, darker.
        _canopy_front(g, 10, 1, 9, 6)
        for y in range(2, 7):
            for x in range(UMBRELLA_W):
                if g[y][x] == "C":
                    put(g, y, x, "c")
        _rect(g, 10, 7, 10, 9, "w")
    else:
        # Side on: a tall dome bulging out ahead of her, its rim facing her
        # and the handle running back to her hand.
        for y in range(1, 15):
            d = abs(y - 7.5) / 7.5
            depth = int(round((1 - d * d) * 5))
            put(g, y, 11, "r")
            for x in range(12, 13 + depth):
                put(g, y, x, "R" if (y // 3) % 2 == 0 else "C")
        _rect(g, 7, 8, 10, 8, "w")
        put(g, 9, 7, "w")
        if direction == "left":
            g = [row[::-1] for row in g]
    return _outline(g)


def player_umbrella_sheet():
    return _strip([player_umbrella(d) for d in ("down", "up", "right", "left")], UMBRELLA_W, UMBRELLA_H)


SKATES_W, SKATES_H = 12, 5


def player_skates(direction):
    g = _blank(SKATES_W, SKATES_H)
    if direction in ("down", "up"):
        # Both skates side by side under her feet, wheels showing below.
        for x0 in (2, 7):
            _rect(g, x0, 1, x0 + 2, 2, "R")
            _rect(g, x0, 3, x0 + 2, 3, "w")
        if direction == "down":
            put(g, 1, 3, "C")
            put(g, 1, 8, "C")
    else:
        # Side on: one skate covers the other, three wheels on its plate.
        _rect(g, 3, 1, 8, 2, "R")
        _rect(g, 8, 1, 9, 2, "C")
        _rect(g, 2, 3, 9, 3, "w")
        if direction == "left":
            g = [row[::-1] for row in g]
    return _outline(g)


def player_skates_sheet():
    return _strip([player_skates(d) for d in ("down", "up", "right", "left")], SKATES_W, SKATES_H)


# --- Wall fittings --------------------------------------------------------

def _wall_box(g):
    """A gray wall box like the speed panel, lit on top, shaded right."""
    _rect(g, 1, 1, 10, 12, "w")
    _rect(g, 1, 1, 10, 1, "W")
    _rect(g, 10, 2, 10, 12, "T")


def fuse_box(fitted):
    """A fuse box with a hazard stripe and an empty clip, or a lit fuse."""
    g = _blank(12, 14)
    _wall_box(g)
    _rect(g, 2, 2, 9, 2, "Y")
    for x in range(2, 10, 2):
        put(g, 2, x, "k")
    _rect(g, 3, 5, 8, 9, "k")
    _rect(g, 4, 6, 4, 8, "w")
    _rect(g, 7, 6, 7, 8, "w")
    if fitted:
        _rect(g, 4, 7, 7, 7, "C")
        put(g, 7, 4, "Y")
        put(g, 7, 7, "Y")
        _rect(g, 4, 11, 7, 11, "l")
    else:
        _rect(g, 4, 11, 7, 11, "r")
    return _outline(g)


def fuse_box_sheet():
    return _strip([fuse_box(False), fuse_box(True)], 12, 14)


def lever_socket(state):
    """A wall plate with a square socket; state 1 and 2 have the lever in
    it, pointing up or down."""
    g = _blank(12, 14)
    _wall_box(g)
    _rect(g, 4, 6, 7, 9, "k")
    put(g, 3, 4, "Y")
    put(g, 3, 7, "Y")
    put(g, 12, 4, "Y")
    put(g, 12, 7, "Y")
    if state:
        y0, y1 = (2, 7) if state == 1 else (8, 11)
        _rect(g, 5, y0, 6, y1, "W")
        knob = 2 if state == 1 else 11
        _rect(g, 4, knob - (1 if state == 1 else 0), 7, knob + (0 if state == 1 else 1), "R")
    return _outline(g)


def lever_socket_sheet():
    return _strip([lever_socket(s) for s in range(3)], 12, 14)


def staff_door(green):
    """A slate STAFF ONLY door with a straight red sign and a badge reader."""
    g = _blank(16, 32)
    _rect(g, 1, 2, 14, 31, "O")
    _rect(g, 2, 3, 13, 31, "p")
    _rect(g, 2, 3, 13, 3, "i")
    _rect(g, 3, 7, 12, 11, "R")
    _rect(g, 4, 9, 11, 9, "C")
    _rect(g, 3, 11, 12, 11, "r")
    put(g, 18, 11, "F")
    put(g, 19, 11, "y")
    # Badge reader on the frame, beside the handle.
    _rect(g, 12, 15, 13, 18, "k")
    put(g, 16, 12, "l" if green else "R")
    return g


def staff_door_sheet():
    return _strip([staff_door(False), staff_door(True)], 16, 32)


def preview():
    """Everything on one gray card, for checking at a glance."""
    from PIL import Image
    card = Image.new("RGBA", (140, 60), (139, 155, 180, 255))
    x = 2
    for img in (skates(), energy_drink(), umbrella(), fuse(), lever_handle(), staff_badge()):
        card.alpha_composite(img, (x, 2))
        x += img.width + 4
    card.alpha_composite(player_umbrella_sheet(), (2, 18))
    card.alpha_composite(player_skates_sheet(), (84, 20))
    card.alpha_composite(fuse_box_sheet(), (2, 36))
    card.alpha_composite(lever_socket_sheet(), (30, 36))
    card.alpha_composite(staff_door_sheet(), (70, 26))
    return card

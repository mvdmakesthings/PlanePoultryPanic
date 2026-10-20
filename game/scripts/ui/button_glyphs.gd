class_name ButtonGlyphs
extends RefCounted
## Draws text with button icons in it. Write an action in braces, like
## "{interact} push", and it's drawn as the button for the device the
## player is using (see InputLabels): a keycap for the keyboard, a colored
## round button for a gamepad's A, B, X and Y, and a small dark pill for
## anything else (bumpers, Start, the stick).

const FONT_SIZE := 8
## Glyphs sit on the text's baseline, this tall, from 7px above it.
const HEIGHT := 9.0
const GAP := 2.0
const OUTLINE := Color("181425")
const KEYCAP := Color("c0cbdc")
const KEYCAP_SHADE := Color("8b9bb4")
const PILL := Color("3a4466")
const PILL_TEXT := Color("ffffff")
## Xbox colors, which Steam Deck's buttons share.
const FACE_COLORS := {
	"A": Color("63c74d"), "B": Color("e43b44"), "X": Color("0099db"), "Y": Color("feae34"),
}

static var _token := RegEx.create_from_string("\\{(\\w+)\\}")


## How wide text will be when drawn, glyphs included.
static func width(font: Font, text: String) -> float:
	var total := 0.0
	for part in _parts(text):
		if part["glyph"]:
			total += _glyph_width(font, part["text"]) + GAP * 2.0
		else:
			total += font.get_string_size(part["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	return total


## Draws text starting at pos (the left end of its baseline). outline, if
## not transparent, rings the plain text for readability over the game.
static func draw(canvas: CanvasItem, font: Font, pos: Vector2, text: String, color: Color,
		outline := Color.TRANSPARENT) -> void:
	var x := pos.x
	for part in _parts(text):
		if part["glyph"]:
			x += GAP
			x += _draw_glyph(canvas, font, Vector2(x, pos.y), part["text"])
			x += GAP
		else:
			if outline.a > 0.0:
				canvas.draw_string_outline(font, Vector2(x, pos.y), part["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 2, outline)
			canvas.draw_string(font, Vector2(x, pos.y), part["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
			x += font.get_string_size(part["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


## Draws text centered on center_x.
static func draw_centered(canvas: CanvasItem, font: Font, center_x: float, baseline: float, text: String,
		color: Color, outline := Color.TRANSPARENT) -> void:
	var left := roundf(center_x - width(font, text) / 2.0)
	draw(canvas, font, Vector2(left, baseline), text, color, outline)


## Splits text into plain runs and glyphs: [{"glyph": bool, "text": label}].
static func _parts(text: String) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	var at := 0
	for found in _token.search_all(text):
		if found.get_start() > at:
			parts.append({"glyph": false, "text": text.substr(at, found.get_start() - at)})
		parts.append({"glyph": true, "text": InputLabels.label(found.get_string(1))})
		at = found.get_end()
	if at < text.length():
		parts.append({"glyph": false, "text": text.substr(at)})
	return parts


static func _glyph_width(font: Font, label: String) -> float:
	if InputLabels.gamepad and FACE_COLORS.has(label):
		return HEIGHT
	return font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + 5.0


## Draws one glyph with its left edge at pos.x on the baseline pos.y;
## returns its width.
static func _draw_glyph(canvas: CanvasItem, font: Font, pos: Vector2, label: String) -> float:
	var w := _glyph_width(font, label)
	var box := Rect2(pos.x, pos.y - 7.0, w, HEIGHT)
	var text_x := box.position.x + 3.0
	if InputLabels.gamepad and FACE_COLORS.has(label):
		# A round face button: a square with its corners cut, outlined.
		_rounded(canvas, box.grow(1.0), OUTLINE)
		_rounded(canvas, box, FACE_COLORS[label])
		var text_color := OUTLINE if label == "Y" else PILL_TEXT
		canvas.draw_string(font, Vector2(box.position.x, pos.y), label, HORIZONTAL_ALIGNMENT_CENTER, w, FONT_SIZE, text_color)
		return w
	if InputLabels.gamepad:
		_rounded(canvas, box.grow(1.0), OUTLINE)
		_rounded(canvas, box, PILL)
		canvas.draw_string(font, Vector2(text_x, pos.y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, PILL_TEXT)
		return w
	# A keycap: light top, a darker bottom edge where the key's side shows.
	canvas.draw_rect(box.grow(1.0), OUTLINE)
	canvas.draw_rect(box, KEYCAP_SHADE)
	canvas.draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y - 2.0)), KEYCAP)
	canvas.draw_string(font, Vector2(text_x, pos.y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, OUTLINE)
	return w


## A rectangle with its four corner pixels cut off, so it reads as round.
static func _rounded(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2(rect.position + Vector2(1, 0), rect.size - Vector2(2, 0)), color)
	canvas.draw_rect(Rect2(rect.position + Vector2(0, 1), rect.size - Vector2(0, 2)), color)

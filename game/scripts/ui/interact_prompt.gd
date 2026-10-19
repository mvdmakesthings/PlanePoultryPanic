class_name InteractPrompt
extends RefCounted
## Draws the small "F push" style prompt above things the player can use.

const COLOR := Color("ffffff")
const OUTLINE := Color("181425")
const FONT_SIZE := 8
## Wide enough for any short prompt, so text is never clipped.
const WIDTH := 56.0


## Draws text centered on center_x, with its baseline at y, onto any canvas item.
static func draw(canvas: CanvasItem, center_x: float, y: float, text: String) -> void:
	var font := ThemeDB.fallback_font
	var pos := Vector2(center_x - WIDTH / 2.0, y)
	canvas.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, WIDTH, FONT_SIZE, 2, OUTLINE)
	canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, WIDTH, FONT_SIZE, COLOR)

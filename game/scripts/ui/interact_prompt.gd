class_name InteractPrompt
extends RefCounted
## Draws the small "[F] push" style prompt above things the player can use.
## Write the button as an action in braces, like "{interact} push"; it's
## drawn as the right button for the keyboard or gamepad (ButtonGlyphs).

const COLOR := Color("ffffff")
const OUTLINE := Color("181425")


## Draws text centered on center_x, with its baseline at y, onto any canvas item.
static func draw(canvas: CanvasItem, center_x: float, y: float, text: String) -> void:
	ButtonGlyphs.draw_centered(canvas, ThemeDB.fallback_font, center_x, y, text, COLOR, OUTLINE)

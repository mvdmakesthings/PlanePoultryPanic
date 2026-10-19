class_name FloatText
extends Node2D
## A short message that floats up from a spot and fades, like "Full!".

const COLOR := Color("ffffff")
const OUTLINE := Color("181425")
const WIDTH := 56.0

@export var lifetime := 0.8
@export var rise := 10.0

var text := ""

var _time := 0.0


## Shows text above a node's position, in that node's parent.
static func spawn(near: Node2D, message: String) -> FloatText:
	var label := FloatText.new()
	label.text = message
	label.position = near.position + Vector2(0, -34)
	near.get_parent().add_child(label)
	return label


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _time / lifetime
	var y := -roundf(rise * t)
	var alpha := 1.0 - maxf(t - 0.5, 0.0) * 2.0
	var font := ThemeDB.fallback_font
	var pos := Vector2(-WIDTH / 2.0, y)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, WIDTH, 8, 2, Color(OUTLINE, alpha))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, WIDTH, 8, Color(COLOR, alpha))

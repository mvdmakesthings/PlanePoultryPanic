class_name Hud
extends Control
## Prototype HUD: luggage health icons and a stamina bar at the top left,
## snack count at the bottom left, controls hint at the bottom right, and a
## centered message for winning or losing.

const LUGGAGE := preload("res://assets/sprites/hud_luggage.png")
const SNACK := preload("res://assets/sprites/item_snack.png")
const EXTINGUISHER := preload("res://assets/sprites/item_extinguisher.png")
const LUGGAGE_SIZE := Vector2(12, 10)
const TEXT := Color("ffffff")
const TEXT_OUTLINE := Color("181425")
const STAMINA_BACK := Color("262b44")
const STAMINA_FILL := Color("63c74d")
const STAMINA_TIRED := Color("f77622")
const FONT_SIZE := 8
const CONTROLS_HINT := "SHIFT run  SPACE throw  E eat  F use  Q spray"

var _health := 0
var _max_health := 0
var _stamina_ratio := 1.0
var _snacks := 0
var _extinguisher_charges := 0
var _message := ""


func bind_player(player: Player) -> void:
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.snacks_changed.connect(_on_snacks_changed)
	player.extinguisher_changed.connect(_on_extinguisher_changed)


func show_message(text: String) -> void:
	_message = text
	queue_redraw()


func _on_health_changed(current: int, maximum: int) -> void:
	_health = current
	_max_health = maximum
	queue_redraw()


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_ratio = current / maximum
	queue_redraw()


func _on_snacks_changed(count: int) -> void:
	_snacks = count
	queue_redraw()


func _on_extinguisher_changed(charges: int) -> void:
	_extinguisher_charges = charges
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()

	for i in _max_health:
		var frame := 0 if i < _health else 1
		var source := Rect2(Vector2(frame * LUGGAGE_SIZE.x, 0), LUGGAGE_SIZE)
		draw_texture_rect_region(LUGGAGE, Rect2(Vector2(4 + i * 14, 4), LUGGAGE_SIZE), source)

	var bar := Rect2(4, 16, 40, 3)
	draw_rect(bar.grow(1), TEXT_OUTLINE)
	draw_rect(bar, STAMINA_BACK)
	var fill_color := STAMINA_FILL if _stamina_ratio > 0.3 else STAMINA_TIRED
	draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * _stamina_ratio), bar.size.y)), fill_color)

	draw_texture(SNACK, Vector2(4, size.y - 14))
	_draw_text(font, Vector2(17, size.y - 5), "x%d" % _snacks, HORIZONTAL_ALIGNMENT_LEFT, -1)
	if _extinguisher_charges > 0:
		draw_texture(EXTINGUISHER, Vector2(34, size.y - 14))
		_draw_text(font, Vector2(45, size.y - 5), "x%d" % _extinguisher_charges, HORIZONTAL_ALIGNMENT_LEFT, -1)
	_draw_text(font, Vector2(0, size.y - 5), CONTROLS_HINT, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 4)

	if _message != "":
		draw_rect(Rect2(Vector2.ZERO, size), Color(TEXT_OUTLINE, 0.6))
		var lines := _message.split("\n")
		var y := size.y / 2.0 - (lines.size() - 1) * 6.0
		for line in lines:
			_draw_text(font, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_CENTER, size.x)
			y += 12.0


func _draw_text(font: Font, pos: Vector2, text: String, align: HorizontalAlignment, width: float) -> void:
	draw_string_outline(font, pos, text, align, width, FONT_SIZE, 2, TEXT_OUTLINE)
	draw_string(font, pos, text, align, width, FONT_SIZE, TEXT)

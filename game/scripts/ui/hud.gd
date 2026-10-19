class_name Hud
extends Control
## Prototype HUD: luggage health icons and a stamina bar at the top left,
## the six inventory slots and key items at the bottom left, a controls
## hint at the bottom right, and a message for winning or losing, above the player.

const LUGGAGE := preload("res://assets/sprites/hud_luggage.png")
const LUGGAGE_SIZE := Vector2(12, 10)
const TEXT := Color("ffffff")
const TEXT_OUTLINE := Color("181425")
const STAMINA_BACK := Color("262b44")
const STAMINA_FILL := Color("63c74d")
const STAMINA_TIRED := Color("f77622")
const SLOT_BACK := Color("262b44")
const SLOT_OUTLINE := Color("181425")
const SLOT_SELECTED := Color("feae34")
const SLOT_SIZE := 14.0
const SLOT_GAP := 1.0
const FONT_SIZE := 8
const CONTROLS_HINT := "SPACE use  Q/R switch  E eat  F act  G drop"

var _health := 0
var _max_health := 0
var _stamina_ratio := 1.0
var _player: Player
var _message := ""
var _icons := {}


func _ready() -> void:
	for item: String in Inventory.ITEMS:
		_icons[item] = load(Inventory.ITEMS[item]["icon"])
	for item: String in Inventory.KEY_ITEMS:
		_icons[item] = load(Inventory.KEY_ITEMS[item]["icon"])


func bind_player(player: Player) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.inventory_changed.connect(queue_redraw)


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


func _draw() -> void:
	var font := get_theme_default_font()
	_draw_health()

	var bar := Rect2(4, 16, 40, 3)
	draw_rect(bar.grow(1), TEXT_OUTLINE)
	draw_rect(bar, STAMINA_BACK)
	var fill_color := STAMINA_FILL if _stamina_ratio > 0.3 else STAMINA_TIRED
	draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * _stamina_ratio), bar.size.y)), fill_color)

	if _player:
		_draw_inventory(font)
	_draw_text(font, Vector2(0, size.y - 5), CONTROLS_HINT, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 4)

	if _message != "":
		draw_rect(Rect2(Vector2.ZERO, size), Color(TEXT_OUTLINE, 0.6))
		var lines := _message.split("\n")
		# Above center, so it doesn't cover the player the camera is centered on.
		var y := size.y / 3.0 - (lines.size() - 1) * 6.0
		for line in lines:
			_draw_text(font, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_CENTER, size.x)
			y += 12.0


## One suitcase per Player.SUITCASE health units; partly lost suitcases are
## drawn partly filled, emptying from the right.
func _draw_health() -> void:
	for i in _max_health / Player.SUITCASE:
		var pos := Vector2(4 + i * 14, 4)
		var fill := clampi(_health - i * Player.SUITCASE, 0, Player.SUITCASE)
		var empty := Rect2(Vector2(LUGGAGE_SIZE.x, 0), LUGGAGE_SIZE)
		draw_texture_rect_region(LUGGAGE, Rect2(pos, LUGGAGE_SIZE), empty)
		if fill > 0:
			var width := roundf(LUGGAGE_SIZE.x * fill / Player.SUITCASE)
			var full := Rect2(Vector2.ZERO, Vector2(width, LUGGAGE_SIZE.y))
			draw_texture_rect_region(LUGGAGE, Rect2(pos, full.size), full)


## Six slots along the bottom: the selected one outlined in yellow, each
## showing its item and how many (or how many charges). Key items follow.
func _draw_inventory(font: Font) -> void:
	var inventory := _player.inventory
	var origin := Vector2(4, size.y - SLOT_SIZE - 3)
	for i in Inventory.SLOT_COUNT:
		var rect := Rect2(origin + Vector2(i * (SLOT_SIZE + SLOT_GAP), 0), Vector2(SLOT_SIZE, SLOT_SIZE))
		draw_rect(rect, SLOT_BACK)
		draw_rect(rect, SLOT_OUTLINE, false, 1.0)
		var slot := inventory.slots[i]
		if not slot.is_empty():
			var icon: Texture2D = _icons[slot["item"]]
			var icon_pos := (rect.position + (rect.size - icon.get_size()) / 2.0).round()
			draw_texture(icon, icon_pos)
			if slot["count"] > 1:
				_draw_text(font, rect.end + Vector2(-6, 1), str(slot["count"]), HORIZONTAL_ALIGNMENT_LEFT, -1)
		if i == inventory.selected:
			draw_rect(rect.grow(1), SLOT_SELECTED, false, 1.0)

	# Key items sit to the right of the slots and never take one up.
	var x := origin.x + Inventory.SLOT_COUNT * (SLOT_SIZE + SLOT_GAP) + 4
	for item: String in inventory.key_items:
		var icon: Texture2D = _icons[item]
		draw_texture(icon, Vector2(x, origin.y + roundf((SLOT_SIZE - icon.get_height()) / 2.0)))
		var count: int = inventory.key_items[item]
		if count > 1:
			_draw_text(font, Vector2(x + icon.get_width() - 2, size.y - 2), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1)
		x += icon.get_width() + 4


func _draw_text(font: Font, pos: Vector2, text: String, align: HorizontalAlignment, width: float) -> void:
	draw_string_outline(font, pos, text, align, width, FONT_SIZE, 2, TEXT_OUTLINE)
	draw_string(font, pos, text, align, width, FONT_SIZE, TEXT)

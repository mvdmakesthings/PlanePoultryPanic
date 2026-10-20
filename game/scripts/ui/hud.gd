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
const CONTROLS_HINT := "{use_item}use {prev_item}{next_item}switch {eat_snack}eat {interact}act {drop_item}drop"
## Tutorial hints use the departure-board look: dark panel, yellow text.
const HINT_BACK := Color("181425")
const HINT_EDGE := Color("3a4466")
const HINT_TEXT := Color("fee761")

## The controls reminder in the bottom right; levels with tutorial hints
## clear it.
var controls_hint := CONTROLS_HINT

var _health := 0
var _max_health := 0
var _stamina_ratio := 1.0
var _player: Player
var _message := ""
var _hint := ""
var _icons := {}
## Seconds left on the escape countdown, or negative when there isn't one.
var _countdown := -1.0
## The boss's hits left and total, or 0 total when there's no boss.
var _boss_hits := 0
var _boss_max := 0


func _ready() -> void:
	for item: String in Inventory.ITEMS:
		_icons[item] = load(Inventory.ITEMS[item]["icon"])
	for item: String in Inventory.KEY_ITEMS:
		_icons[item] = load(Inventory.KEY_ITEMS[item]["icon"])


func _enter_tree() -> void:
	InputSetup.device_changed.connect(_on_device_changed)


func _exit_tree() -> void:
	InputSetup.device_changed.disconnect(_on_device_changed)


func _on_device_changed(_gamepad: bool) -> void:
	queue_redraw()


func bind_player(player: Player) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.inventory_changed.connect(queue_redraw)


func show_message(text: String) -> void:
	_message = text
	queue_redraw()


## Shows a tutorial hint at the top of the screen ("" hides it). Action
## names in braces are drawn as their buttons, like "{run}" -> [SHIFT].
## Shows the escape countdown at the top right; negative hides it.
func show_countdown(seconds: float) -> void:
	if ceilf(seconds) != ceilf(_countdown):
		queue_redraw()
	_countdown = seconds


## Shows the boss's hits left as pips at the top right; maximum 0 hides it.
func show_boss(hits_left: int, maximum: int) -> void:
	_boss_hits = hits_left
	_boss_max = maximum
	queue_redraw()


func show_hint(text: String) -> void:
	if text != _hint:
		_hint = text
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
	if controls_hint != "":
		var hint_x := size.x - 4 - ButtonGlyphs.width(font, controls_hint)
		ButtonGlyphs.draw(self, font, Vector2(hint_x, size.y - 5), controls_hint, TEXT, TEXT_OUTLINE)
	if _hint != "":
		_draw_hint(font)
	if _boss_max > 0:
		_draw_board_box(font, "SUPREME TOTEM", "")
		for i in _boss_max:
			var pip := Rect2(size.x - 10 - (_boss_max - i) * 8, 15, 6, 4)
			draw_rect(pip.grow(1), TEXT_OUTLINE)
			draw_rect(pip, Color("e43b44") if i < _boss_hits else STAMINA_BACK)
	if _countdown >= 0.0:
		var secs := int(ceilf(_countdown))
		_draw_board_box(font, "DOORS CLOSE", "0:%02d" % secs, secs <= 10 and secs % 2 == 0)

	if _message != "":
		draw_rect(Rect2(Vector2.ZERO, size), Color(TEXT_OUTLINE, 0.6))
		var lines := _message.split("\n")
		# Above center, so it doesn't cover the player the camera is centered on.
		var y := size.y / 3.0 - (lines.size() - 1) * 6.0
		for line in lines:
			_draw_text(font, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_CENTER, size.x)
			y += 12.0


## A dark panel centered at the top, one line of yellow text per hint line,
## with buttons drawn as glyphs.
func _draw_hint(font: Font) -> void:
	var lines := _hint.split("\n")
	var width := 0.0
	for line in lines:
		width = maxf(width, ButtonGlyphs.width(font, line))
	# Lines are a little taller than the text so button glyphs fit.
	var panel := Rect2(roundf((size.x - width) / 2.0) - 4, 3, width + 8, lines.size() * 11 + 3)
	draw_rect(panel.grow(1), HINT_EDGE)
	draw_rect(panel, HINT_BACK)
	var y := panel.position.y + 10
	for line in lines:
		ButtonGlyphs.draw_centered(self, font, panel.get_center().x, y, line, HINT_TEXT)
		y += 11


## A small departure-board box at the top right: a label and a value.
func _draw_board_box(font: Font, label: String, value: String, flash := false) -> void:
	var text := label + ("  " + value if value != "" else "")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var box := Rect2(size.x - width - 12, 3, width + 8, 10)
	draw_rect(box.grow(1), HINT_EDGE)
	draw_rect(box, HINT_BACK)
	draw_string(font, box.position + Vector2(4, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE,
		Color("e43b44") if flash else Color("f77622"))


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

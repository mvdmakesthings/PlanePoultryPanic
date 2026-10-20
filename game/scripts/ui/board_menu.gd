class_name BoardMenu
extends Control
## A menu drawn like a departure board: a dark panel with a yellow title
## and one row per item, each with a label and a status on the right, like
## a flight and its status. Statuses flicker now and then like split-flap
## letters. Every menu in the game (main, pause, settings, retry) is one.
##
## Works with keyboard, gamepad (the ui_* actions) and mouse. Item kinds:
##   button  - accept chooses it (emits chosen)
##   slider  - left and right change its value, 0-10 (emits changed)
##   toggle  - accept or left/right flips it (emits changed)
## An item can be "disabled": it's shown dimmed and can't be chosen.

signal chosen(id: String)
signal changed(id: String, value: Variant)
## Cancel (Esc, B) was pressed.
signal cancelled

const BACK := Color("181425")
const BEZEL := Color("3a4466")
const BEZEL_LIGHT := Color("5a6988")
const DIVIDER := Color("262b44")
const TITLE := Color("fee761")
const LABEL := Color("feae34")
const SELECTED := Color("fee761")
const HIGHLIGHT := Color("262b44")
const STATUS := Color("f77622")
const DIMMED := Color("5a6988")
const CANCELLED := Color("e43b44")
const FOOTER := Color("8b9bb4")
const FONT_SIZE := 8
const TITLE_HEIGHT := 16.0
const PAD := 6.0
const SLIDER_STEPS := 10
const FLAP_CHARS := "#?*%&"

@export var title := ""
@export var panel_width := 216.0
@export var row_height := 11.0
## Where the panel's top edge sits, in pixels from the top of the screen.
@export var panel_top := 40.0
## A line under the panel, like "ENTER select  ESC back". Action names in
## braces become their buttons.
@export var footer := "{ui_accept} SELECT   {ui_cancel} BACK"
## Statuses flicker like split-flap letters. Off for menus whose statuses
## are information, like key bindings.
@export var flicker := true

## Each item: {"id", "label", "kind", "value", "status", "disabled"}.
var items: Array[Dictionary] = []
var selected := 0
## Only the active menu reads input, so a submenu can sit on top of another.
var active := true

var _flicker_row := -1
var _flicker_left := 0.0
var _flicker_wait := 0.0
var _row_rects: Array[Rect2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visibility_changed.connect(queue_redraw)


## Replaces the items. Keeps the selection on the same id if it's still there.
func set_items(new_items: Array[Dictionary]) -> void:
	var keep: String = items[selected]["id"] if selected < items.size() else ""
	items = new_items
	selected = 0
	for i in items.size():
		if items[i]["id"] == keep:
			selected = i
	_skip_disabled(1)
	queue_redraw()


func item(id: String) -> Dictionary:
	for entry in items:
		if entry["id"] == id:
			return entry
	return {}


## Opens the menu: visible, active, with the first usable item selected.
func open() -> void:
	show()
	active = true
	selected = 0
	_skip_disabled(1)
	queue_redraw()


func close() -> void:
	hide()
	active = false


func _process(delta: float) -> void:
	if not visible:
		return
	# Now and then one status flips through random letters, like a split-flap.
	_flicker_left -= delta
	_flicker_wait -= delta
	if _flicker_wait <= 0.0 and items.size() > 0:
		_flicker_wait = randf_range(0.8, 2.5)
		_flicker_row = randi() % items.size()
		_flicker_left = 0.15
	if _flicker_left > -0.05:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not active or items.is_empty():
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_handle_mouse(event)
		return
	if event.is_action_pressed("ui_down", true):
		_move(1)
	elif event.is_action_pressed("ui_up", true):
		_move(-1)
	elif event.is_action_pressed("ui_left", true):
		_adjust(-1)
	elif event.is_action_pressed("ui_right", true):
		_adjust(1)
	elif event.is_action_pressed("ui_accept"):
		_accept()
	elif event.is_action_pressed("ui_cancel"):
		AudioManager.play("ui_back")
		get_viewport().set_input_as_handled()
		cancelled.emit()
		return
	else:
		return
	get_viewport().set_input_as_handled()


func _handle_mouse(event: InputEvent) -> void:
	var pos: Vector2 = event.position
	for i in _row_rects.size():
		if not _row_rects[i].has_point(pos) or items[i].get("disabled", false):
			continue
		if i != selected:
			selected = i
			AudioManager.play("ui_move")
			queue_redraw()
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			if items[i]["kind"] == "slider":
				var half := _row_rects[i].position.x + _row_rects[i].size.x * 0.75
				_adjust(1 if pos.x > half else -1)
			else:
				_accept()
			get_viewport().set_input_as_handled()
		return


func _move(step: int) -> void:
	var before := selected
	selected = posmod(selected + step, items.size())
	_skip_disabled(step)
	if selected != before:
		AudioManager.play("ui_move")
	queue_redraw()


func _skip_disabled(step: int) -> void:
	for i in items.size():
		if not items[selected].get("disabled", false):
			return
		selected = posmod(selected + step, items.size())


func _adjust(step: int) -> void:
	var entry := items[selected]
	match entry["kind"]:
		"slider":
			var value := clampi(int(entry["value"]) + step, 0, SLIDER_STEPS)
			if value != entry["value"]:
				entry["value"] = value
				AudioManager.play("ui_move")
				changed.emit(entry["id"], value)
		"toggle":
			_flip(entry)
	queue_redraw()


func _accept() -> void:
	var entry := items[selected]
	if entry.get("disabled", false):
		return
	match entry["kind"]:
		"toggle":
			_flip(entry)
		"slider":
			pass
		_:
			AudioManager.play("ui_confirm")
			chosen.emit(entry["id"])
	queue_redraw()


func _flip(entry: Dictionary) -> void:
	entry["value"] = not entry["value"]
	AudioManager.play("ui_confirm")
	changed.emit(entry["id"], entry["value"])


func _status_text(entry: Dictionary) -> String:
	match entry["kind"]:
		"slider":
			var filled := int(entry["value"])
			return "#".repeat(filled) + "-".repeat(SLIDER_STEPS - filled)
		"toggle":
			return "ON" if entry["value"] else "OFF"
	return str(entry.get("status", ""))


func _draw() -> void:
	var font := get_theme_default_font()
	var height := TITLE_HEIGHT + items.size() * row_height + PAD
	var panel := Rect2(roundf((size.x - panel_width) / 2.0), panel_top, panel_width, height)
	# Casing: a slate bezel, lit on its top edge, around the dark board.
	draw_rect(panel.grow(3), BACK)
	draw_rect(panel.grow(2), BEZEL)
	draw_rect(Rect2(panel.position - Vector2(2, 2), Vector2(panel.size.x + 4, 1)), BEZEL_LIGHT)
	draw_rect(panel, BACK)
	draw_string(font, panel.position + Vector2(0, 11), InputLabels.format(title), HORIZONTAL_ALIGNMENT_CENTER,
		panel.size.x, FONT_SIZE, TITLE)
	draw_rect(Rect2(panel.position + Vector2(PAD, TITLE_HEIGHT - 3), Vector2(panel.size.x - PAD * 2, 1)), DIVIDER)

	_row_rects.clear()
	for i in items.size():
		var entry := items[i]
		var row := Rect2(panel.position + Vector2(2, TITLE_HEIGHT + i * row_height), Vector2(panel.size.x - 4, row_height))
		_row_rects.append(row)
		var disabled: bool = entry.get("disabled", false)
		var is_selected := i == selected and active
		if is_selected:
			draw_rect(row, HIGHLIGHT)
			draw_string(font, row.position + Vector2(2, row_height - 3), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, SELECTED)
		var color := DIMMED if disabled else SELECTED if is_selected else LABEL
		draw_string(font, row.position + Vector2(PAD + 4, row_height - 3), entry["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		var status := _status_text(entry)
		if flicker and i == _flicker_row and _flicker_left > 0.0 and entry["kind"] == "button":
			status = _scramble(status)
		var status_color := CANCELLED if disabled else STATUS
		if entry["kind"] != "button":
			status_color = SELECTED if is_selected else LABEL
		draw_string(font, Vector2(row.position.x, row.position.y + row_height - 3), status, HORIZONTAL_ALIGNMENT_RIGHT,
			row.size.x - PAD, FONT_SIZE, status_color)

	if footer != "":
		var text := InputLabels.format(footer)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		draw_rect(Rect2(roundf(panel.get_center().x - width / 2.0) - 3, panel.end.y + 5, width + 6, 11), BACK)
		draw_string(font, Vector2(panel.position.x, panel.end.y + 13), text,
			HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, FONT_SIZE, FOOTER)


func _scramble(text: String) -> String:
	var out := ""
	for c in text:
		out += FLAP_CHARS[randi() % FLAP_CHARS.length()] if c != " " and randf() < 0.6 else c
	return out

class_name GameMenus
extends Control
## The menus inside a level, over a dimmed screen:
##   Pause (Esc / Start): Resume, Settings, Quit to Menu
##   Retry, after a knockout: a hint about what went wrong, Retry, Main Menu
##   Level clear: whatever the level offers, plus Main Menu
## Add one to a level's UI layer. The game is paused while any is open.

## Emitted for level-clear items other than Main Menu.
signal chosen(id: String)

const DIM := Color(0.094, 0.078, 0.145, 0.7)
const HINT := Color("ffffff")
const HINT_OUTLINE := Color("181425")

## Levels turn this off once the round is over (won or lost).
var can_pause := true

var _board: BoardMenu
var _settings: SettingsMenu
var _mode := ""
var _hint := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board = BoardMenu.new()
	add_child(_board)
	_board.chosen.connect(_on_chosen)
	_board.cancelled.connect(_on_cancelled)
	_board.close()
	_settings = SettingsMenu.new()
	add_child(_settings)
	_settings.closed.connect(_on_settings_closed)
	InputSetup.device_changed.connect(func(_gamepad: bool) -> void: queue_redraw())
	hide()


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if can_pause and not visible:
		get_viewport().set_input_as_handled()
		open_pause()
	elif _mode == "pause" and not _settings.visible:
		# Start (or Esc) again resumes.
		get_viewport().set_input_as_handled()
		AudioManager.play("ui_back")
		close()


func open_pause() -> void:
	_open("pause", "PAUSED", [
		{"id": "resume", "label": "RESUME", "kind": "button", "status": "BOARDING"},
		{"id": "settings", "label": "SETTINGS", "kind": "button", "status": ">"},
		{"id": "menu", "label": "QUIT TO MENU", "kind": "button", "status": "DEPARTED"},
	])
	AudioManager.play("ui_confirm")


## The knockout screen. hint says what went wrong and how to avoid it.
func open_retry(hint: String) -> void:
	_hint = hint
	_open("retry", "GROUNDED", [
		{"id": "retry", "label": "RETRY FROM CHECKPOINT", "kind": "button", "status": "REBOOKED"},
		{"id": "menu", "label": "MAIN MENU", "kind": "button", "status": ""},
	])


## The end-of-level screen. extra_items go above Main Menu; choosing one
## emits it through chosen.
func open_level_clear(title: String, extra_items: Array[Dictionary]) -> void:
	var rows := extra_items.duplicate()
	rows.append({"id": "menu", "label": "MAIN MENU", "kind": "button", "status": ""})
	_open("clear", title, rows)


func _open(mode: String, title: String, rows: Array) -> void:
	_mode = mode
	if mode != "retry":
		_hint = ""
	var typed: Array[Dictionary] = []
	typed.assign(rows)
	_board.title = title
	_board.panel_top = 70.0 if _hint != "" else 48.0
	_board.footer = "{ui_accept} SELECT" if mode != "pause" else "{ui_accept} SELECT   {ui_cancel} RESUME"
	_board.set_items(typed)
	_board.open()
	show()
	get_tree().paused = true
	queue_redraw()


func close() -> void:
	_board.close()
	_settings.close()
	hide()
	_mode = ""
	get_tree().paused = false


func _on_chosen(id: String) -> void:
	match id:
		"resume":
			close()
		"settings":
			_board.close()
			_settings.open()
		"retry":
			# The level this menu belongs to is the scene that owns it.
			GameManager.retry(owner.scene_file_path)
		"menu":
			GameManager.quit_to_menu()
		_:
			chosen.emit(id)


func _on_cancelled() -> void:
	# Only the pause menu can be backed out of.
	if _mode == "pause":
		close()


func _on_settings_closed() -> void:
	if _mode == "pause":
		_board.open()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DIM)
	if _hint == "":
		return
	var font := get_theme_default_font()
	var y := 34.0
	for line in _hint.split("\n"):
		ButtonGlyphs.draw_centered(self, font, size.x / 2.0, y, line, HINT, HINT_OUTLINE)
		y += 11.0

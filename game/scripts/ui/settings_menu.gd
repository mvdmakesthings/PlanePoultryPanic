class_name SettingsMenu
extends Control
## Settings, shared by the main menu and the pause menu: music, effects and
## ambience volume, fullscreen, and a Controls page for remapping. Changes
## apply right away and are saved by SaveSystem.
##
## On the Controls page, choosing an action waits for the next key or
## gamepad button and binds it (Esc cancels). A key rebinds the keyboard,
## a button rebinds the gamepad.

signal closed

const VOLUME_ROWS := {"music": "Music", "effects": "Effects", "ambience": "Ambience"}
const ACTION_NAMES := {
	"move_up": "MOVE UP", "move_down": "MOVE DOWN", "move_left": "MOVE LEFT",
	"move_right": "MOVE RIGHT", "run": "RUN", "use_item": "USE ITEM",
	"interact": "INTERACT", "eat_snack": "EAT SNACK", "prev_item": "PREV SLOT",
	"next_item": "NEXT SLOT", "drop_item": "DROP ITEM", "pause": "PAUSE",
}

## The action waiting for a new key or button, or "".
var capturing := ""

var _settings: BoardMenu
var _controls: BoardMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings = BoardMenu.new()
	_settings.title = "SETTINGS"
	_settings.panel_top = 34.0
	_settings.flicker = false
	_settings.footer = "{ui_accept} SELECT  {ui_left}{ui_right} ADJUST  {ui_cancel} BACK"
	add_child(_settings)
	_settings.chosen.connect(_on_settings_chosen)
	_settings.changed.connect(_on_settings_changed)
	_settings.cancelled.connect(close)

	_controls = BoardMenu.new()
	_controls.title = "CONTROLS: {ui_accept}, THEN PRESS A KEY OR BUTTON"
	_controls.panel_width = 240.0
	_controls.panel_top = 6.0
	_controls.row_height = 10.0
	_controls.footer = ""
	_controls.flicker = false
	add_child(_controls)
	_controls.chosen.connect(_on_controls_chosen)
	_controls.cancelled.connect(_back_to_settings)
	hide()
	_settings.close()
	_controls.close()


func open() -> void:
	show()
	_refresh_settings()
	_settings.open()
	_controls.close()


func close() -> void:
	capturing = ""
	_settings.close()
	_controls.close()
	hide()
	closed.emit()


func _refresh_settings() -> void:
	var rows: Array[Dictionary] = []
	for id: String in VOLUME_ROWS:
		rows.append({"id": id, "label": id.to_upper(), "kind": "slider",
			"value": int(roundf(AudioManager.get_volume(VOLUME_ROWS[id]) * BoardMenu.SLIDER_STEPS))})
	rows.append({"id": "fullscreen", "label": "FULLSCREEN", "kind": "toggle", "value": SaveSystem.fullscreen})
	rows.append({"id": "controls", "label": "CONTROLS", "kind": "button", "status": ">"})
	rows.append({"id": "reset", "label": "RESET TO DEFAULTS", "kind": "button", "status": ""})
	rows.append({"id": "back", "label": "BACK", "kind": "button", "status": ""})
	_settings.set_items(rows)


func _refresh_controls() -> void:
	var rows: Array[Dictionary] = []
	for action in SaveSystem.REMAPPABLE:
		var status := "%s / %s" % [InputLabels.key_name(SaveSystem.primary_key(action)),
			InputLabels.button_name(SaveSystem.primary_button(action))]
		if action == capturing:
			status = "PRESS A KEY OR BUTTON"
		rows.append({"id": action, "label": ACTION_NAMES[action], "kind": "button", "status": status})
	rows.append({"id": "reset", "label": "RESET CONTROLS", "kind": "button", "status": ""})
	rows.append({"id": "back", "label": "BACK", "kind": "button", "status": ""})
	_controls.set_items(rows)


func _on_settings_changed(id: String, value: Variant) -> void:
	if VOLUME_ROWS.has(id):
		SaveSystem.set_volume(VOLUME_ROWS[id], float(value) / BoardMenu.SLIDER_STEPS)
		if id == "effects":
			AudioManager.play("pickup")
	elif id == "fullscreen":
		SaveSystem.set_fullscreen(value)


func _on_settings_chosen(id: String) -> void:
	match id:
		"controls":
			_settings.close()
			_refresh_controls()
			_controls.open()
		"reset":
			SaveSystem.reset_audio_and_video()
			_refresh_settings()
		"back":
			close()


func _on_controls_chosen(id: String) -> void:
	match id:
		"reset":
			SaveSystem.reset_controls()
			_refresh_controls()
		"back":
			_back_to_settings()
		_:
			capturing = id
			_controls.active = false
			_refresh_controls()
			_controls.queue_redraw()


func _back_to_settings() -> void:
	_controls.close()
	_refresh_settings()
	_settings.open()


func _input(event: InputEvent) -> void:
	if capturing == "" or not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	var button := event as InputEventJoypadButton
	if key:
		if key.physical_keycode != KEY_ESCAPE:
			SaveSystem.remap_key(capturing, key.physical_keycode)
	elif button:
		SaveSystem.remap_button(capturing, button.button_index)
	else:
		return
	get_viewport().set_input_as_handled()
	AudioManager.play("ui_confirm")
	capturing = ""
	_refresh_controls()
	# Wait a frame so the press that bound the key doesn't also act in the menu.
	await get_tree().process_frame
	_controls.active = true
	_controls.queue_redraw()

extends Node
## Saves and loads the game and the player's settings (autoload: SaveSystem).
##
## The game autosaves at every checkpoint; there's no manual save. The save
## is one JSON file holding the latest checkpoint (see LevelState). Settings
## (volumes, fullscreen, remapped controls) live in their own file and are
## applied at startup.

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.cfg"
## Actions the player can remap in Settings, in the order they're listed.
const REMAPPABLE: Array[String] = [
	"move_up", "move_down", "move_left", "move_right", "run", "use_item",
	"interact", "eat_snack", "prev_item", "next_item", "drop_item", "pause",
]

## Tests point these somewhere else so they never touch the player's files.
var save_path := SAVE_PATH
var settings_path := SETTINGS_PATH

## Volumes (0-1) by bus name, and whether the window is fullscreen.
var volumes := {}
var fullscreen := false


func _ready() -> void:
	load_settings()


# ---------- the game ----------

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game(data: Dictionary) -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write the save file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))


## The saved checkpoint, or {} if there's no save (or it can't be read).
func load_game() -> Dictionary:
	if not has_save():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	return data if data is Dictionary else {}


func delete_game() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


# ---------- settings ----------

func load_settings() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	for bus: String in AudioManager.DEFAULT_VOLUMES:
		volumes[bus] = float(config.get_value("audio", bus, AudioManager.DEFAULT_VOLUMES[bus]))
		AudioManager.set_volume(bus, volumes[bus])
	fullscreen = bool(config.get_value("video", "fullscreen", false))
	_apply_fullscreen()
	for action in REMAPPABLE:
		var key: int = config.get_value("keys", action, KEY_NONE)
		if key != KEY_NONE:
			_replace_key(action, key)
		var button: int = config.get_value("pad", action, JOY_BUTTON_INVALID)
		if button != JOY_BUTTON_INVALID:
			_replace_button(action, button)


func save_settings() -> void:
	var config := ConfigFile.new()
	for bus: String in volumes:
		config.set_value("audio", bus, volumes[bus])
	config.set_value("video", "fullscreen", fullscreen)
	for action in REMAPPABLE:
		var key := primary_key(action)
		if key != InputSetup.default_key(action):
			config.set_value("keys", action, key)
		var button := primary_button(action)
		if button != InputSetup.default_button(action):
			config.set_value("pad", action, button)
	config.save(settings_path)


func set_volume(bus: String, linear: float) -> void:
	volumes[bus] = linear
	AudioManager.set_volume(bus, linear)
	save_settings()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	save_settings()


## Binds an action's main key (the one shown in prompts) to a new key. If
## another action had that key, the two swap, so nothing is left unbound.
func remap_key(action: String, key: int) -> void:
	var old := primary_key(action)
	for other in REMAPPABLE:
		if other != action and primary_key(other) == key:
			_replace_key(other, old)
	_replace_key(action, key)
	save_settings()


## Binds an action's main gamepad button, swapping with any action that had it.
func remap_button(action: String, button: int) -> void:
	var old := primary_button(action)
	for other in REMAPPABLE:
		if other != action and primary_button(other) == button:
			_replace_button(other, old)
	_replace_button(action, button)
	save_settings()


## Puts every control back to its default binding.
func reset_controls() -> void:
	for action in REMAPPABLE:
		_replace_key(action, InputSetup.default_key(action))
		_replace_button(action, InputSetup.default_button(action))
	save_settings()


func reset_audio_and_video() -> void:
	for bus: String in AudioManager.DEFAULT_VOLUMES:
		volumes[bus] = AudioManager.DEFAULT_VOLUMES[bus]
		AudioManager.set_volume(bus, volumes[bus])
	fullscreen = false
	_apply_fullscreen()
	save_settings()


## The action's first keyboard key (its main one), or KEY_NONE.
func primary_key(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).physical_keycode
	return KEY_NONE


## The action's first gamepad button, or JOY_BUTTON_INVALID.
func primary_button(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return (event as InputEventJoypadButton).button_index
	return JOY_BUTTON_INVALID


func _apply_fullscreen() -> void:
	# Headless runs (tests) have no window to resize.
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


## Makes key the action's main key (its first, shown in prompts). Other
## keys it had, like the arrow keys, stay as extras.
func _replace_key(action: String, key: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key as Key
	_replace_first(action, event, func(e: InputEvent) -> bool:
		return e is InputEventKey and (e as InputEventKey).physical_keycode == key)


func _replace_button(action: String, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button as JoyButton
	_replace_first(action, event, func(e: InputEvent) -> bool:
		return e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button)


## Drops the action's first event of the same kind (and any duplicate of
## the new one), then puts the new event first.
func _replace_first(action: String, event: InputEvent, is_duplicate: Callable) -> void:
	var events := InputMap.action_get_events(action)
	var first := -1
	for i in events.size():
		if events[i].get_class() == event.get_class():
			first = i
			break
	if first >= 0:
		events.remove_at(first)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	for old in events:
		if not is_duplicate.call(old):
			InputMap.action_add_event(action, old)

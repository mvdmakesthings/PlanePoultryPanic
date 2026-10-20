extends Node
## Smoke test for the menus, saving and settings: Continue and New Game in
## the main menu, settings that apply and save, and remapping controls.
## Uses its own save and settings files, never the player's. Run with:
##   godot --headless --path game res://tests/menus_smoke.tscn

const MAIN_MENU := preload("res://scenes/ui/main_menu.tscn")

var _failures: Array[String] = []
var _requested := ""


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	SaveSystem.reset_audio_and_video()
	GameManager.dry_run = true
	GameManager.scene_change_requested.connect(func(path: String) -> void: _requested = path)

	await _main_menu_tests()
	await _settings_tests()
	await _remap_tests()
	await _device_tests()

	SaveSystem.reset_controls()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))
	await AudioManager.silence()
	if _failures.is_empty():
		print("MENUS SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _main_menu_tests() -> void:
	var menu := await _fresh_menu()
	var board: BoardMenu = menu._board
	_check(board.item("continue").get("disabled", false), "Continue is unavailable with no save")
	_tap("ui_down")
	_check(board.items[board.selected]["id"] == "settings", "moving down skips the unavailable Continue")
	menu.queue_free()

	var save := {"level": GameManager.FIRST_LEVEL, "checkpoint": "baggage_claim", "reached": ["baggage_claim"],
		"inventory": {}, "collected": [], "unlocked": []}
	SaveSystem.save_game(save)
	menu = await _fresh_menu()
	board = menu._board
	_check(not board.item("continue").get("disabled", false), "Continue is available once there's a save")
	_tap("ui_down")
	_tap("ui_accept")
	_check(_requested == GameManager.FIRST_LEVEL and GameManager.pending.get("checkpoint") == "baggage_claim",
		"Continue loads the saved checkpoint")
	GameManager.pending = {}
	menu.queue_free()

	menu = await _fresh_menu()
	board = menu._board
	_requested = ""
	_tap("ui_accept")
	_check(_requested == "" and board.item("new_game")["status"] == "OVERWRITE SAVE?",
		"New Game asks before replacing a save")
	_tap("ui_accept")
	_check(_requested == GameManager.OPENING and not SaveSystem.has_save(), "New Game starts over with the opening")
	menu.queue_free()


func _settings_tests() -> void:
	var menu := await _fresh_menu()
	var settings: SettingsMenu = menu._settings
	menu._board.close()
	settings.open()
	var board: BoardMenu = settings._settings
	var before := AudioManager.get_volume("Effects")
	_tap("ui_down")
	_tap("ui_left")
	_tap("ui_left")
	var after := AudioManager.get_volume("Effects")
	print("effects volume %.2f -> %.2f" % [before, after])
	_check(after < before - 0.15, "the Effects slider turns the effects down")
	var config := ConfigFile.new()
	config.load(SaveSystem.settings_path)
	_check(is_equal_approx(float(config.get_value("audio", "Effects", -1.0)), after), "volume changes are saved")
	SaveSystem.load_settings()
	_check(is_equal_approx(AudioManager.get_volume("Effects"), after), "saved volumes come back on the next start")
	_tap("ui_down")
	_tap("ui_down")
	_tap("ui_accept")
	_check(board.item("fullscreen")["value"] == true and SaveSystem.fullscreen, "Fullscreen toggles")
	_tap("ui_accept")
	_tap("ui_cancel")
	_check(not settings.visible and menu._board.visible, "backing out of Settings returns to the main menu")
	SaveSystem.reset_audio_and_video()
	_check(is_equal_approx(AudioManager.get_volume("Effects"), AudioManager.DEFAULT_VOLUMES["Effects"]),
		"Reset to Defaults restores the volumes")
	menu.queue_free()


func _remap_tests() -> void:
	SaveSystem.remap_key("interact", KEY_E)
	_check(InputLabels.label("interact") == "E", "remapping Interact to E shows E in prompts")
	_check(InputLabels.label("eat_snack") == "F", "the action that had E swaps to Interact's old key")
	SaveSystem.reset_controls()
	_check(InputLabels.label("interact") == "F" and InputLabels.label("eat_snack") == "E", "Reset Controls restores the defaults")

	# Rebinding through the Controls page: choose Move Up, then press I.
	var menu := await _fresh_menu()
	var settings: SettingsMenu = menu._settings
	menu._board.close()
	settings.open()
	for i in 4:
		_tap("ui_down")
	_tap("ui_accept")
	_check(settings._controls.visible, "Controls opens from Settings")
	_tap("ui_accept")
	_check(settings.capturing == "move_up", "choosing an action waits for a key")
	var press := InputEventKey.new()
	press.physical_keycode = KEY_I
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(SaveSystem.primary_key("move_up") == KEY_I, "pressing a key binds it")
	var up := InputEventKey.new()
	up.physical_keycode = KEY_UP
	_check(InputMap.action_has_event("move_up", up), "the arrow key still works alongside the new key")
	var config := ConfigFile.new()
	config.load(SaveSystem.settings_path)
	_check(int(config.get_value("keys", "move_up", KEY_NONE)) == KEY_I, "remapped keys are saved")
	SaveSystem.reset_controls()
	menu.queue_free()


## Prompts follow the device: a gamepad press switches them to gamepad
## buttons, a key press switches them back.
func _device_tests() -> void:
	var switches := [0]
	var count := func(_gamepad: bool) -> void: switches[0] += 1
	InputSetup.device_changed.connect(count)
	var keyboard_width := ButtonGlyphs.width(ThemeDB.fallback_font, "{interact} push")
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	await get_tree().process_frame
	_check(InputLabels.gamepad, "pressing a gamepad button switches prompts to the gamepad")
	_check(InputLabels.label("interact") == "B" and InputLabels.label("eat_snack") == "X",
		"gamepad prompts name the gamepad buttons")
	_check(InputLabels.label("move") == "L-STICK", "the gamepad's move prompt is the left stick")
	var pad_width := ButtonGlyphs.width(ThemeDB.fallback_font, "{interact} push")
	_check(pad_width != keyboard_width, "prompts are drawn with gamepad glyphs")
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = 0.2
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await get_tree().process_frame
	_check(not InputLabels.gamepad and InputLabels.label("interact") == "F", "a key press switches prompts back to the keyboard")
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	await get_tree().process_frame
	_check(not InputLabels.gamepad, "a slightly drifting stick doesn't switch to the gamepad")
	_check(switches[0] == 2, "each switch is announced once")
	InputSetup.device_changed.disconnect(count)
	var release := InputEventKey.new()
	release.physical_keycode = KEY_D
	Input.parse_input_event(release)


func _fresh_menu() -> Node:
	await get_tree().process_frame
	var menu := MAIN_MENU.instantiate()
	add_child(menu)
	await get_tree().process_frame
	return menu


func _check(condition: bool, description: String) -> void:
	print(("ok    " if condition else "FAIL  ") + description)
	if not condition:
		_failures.append(description)


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

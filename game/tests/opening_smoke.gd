extends Node
## Smoke test for the opening cutscene: it plays through its beats and
## hands off to Level 1, it can be skipped with the keyboard and the
## gamepad, and it really lands in Level 1. Run with:
##   godot --headless --path game res://tests/opening_smoke.tscn

const OPENING := preload("res://scenes/cutscenes/opening.tscn")
## The scene plays this many times faster than normal while it's tested.
const SPEED := 8.0

var _failures: Array[String] = []
var _requested := ""


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	GameManager.scene_change_requested.connect(func(path: String) -> void: _requested = path)
	GameManager.dry_run = true
	Engine.time_scale = SPEED
	# The root is busy adding this test until the first frame.
	await get_tree().process_frame

	await _plays_through()
	await _skips_with(_action_event("ui_accept"), "Confirm")
	await _skips_with(_key_event(KEY_ESCAPE), "Esc")
	await _skips_with(_button_event(JOY_BUTTON_B), "the gamepad's B")
	await _skips_with(_button_event(JOY_BUTTON_START), "the gamepad's Start")
	await _lands_in_level_1()

	Engine.time_scale = 1.0
	SaveSystem.delete_game()
	await AudioManager.silence()
	if _failures.is_empty():
		print("OPENING SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _plays_through() -> void:
	var opening := _fresh_opening()
	var saw := {"cancelled": false, "expired": false, "last_flight": false, "c13": false, "bawk": false}
	var deadline := Time.get_ticks_msec() + 15000
	while _requested == "" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if opening.row_status(0) == "CANCELLED":
			saw["cancelled"] = true
		if opening.pass_expired:
			saw["expired"] = true
		if opening.panel_visible and "LAST FLIGHT" in opening.typed_text():
			saw["last_flight"] = true
		if opening.row_status(4) == "GATE C13":
			saw["c13"] = true
		if opening.panel_visible and "BAWK" in opening.typed_text():
			saw["bawk"] = true
	var length: float = opening._time
	print("opening ran %.1f s of scene time" % length)
	_check(_requested == GameManager.FIRST_LEVEL, "the opening hands off to Level 1 when it ends")
	_check(not opening.skipped, "playing through doesn't count as skipping")
	_check(length >= 20.0 and length <= 40.0, "the opening lasts 20-40 seconds")
	_check(saw["cancelled"], "Amanda's flight flips to CANCELLED")
	_check(saw["expired"], "her boarding pass is stamped EXPIRED")
	_check(saw["last_flight"], "the PA announces the last flight")
	_check(saw["c13"], "the board shows the last flight at Gate C13")
	_check(saw["bawk"], "the PA ends with a bawk")
	_check(opening._amanda.position.x > 320.0, "Amanda runs off the screen")
	await _free(opening)


func _skips_with(event: InputEvent, what: String) -> void:
	var opening := _fresh_opening()
	await get_tree().create_timer(1.0).timeout
	_check(_requested == "", "nothing happens before %s is pressed" % what)
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await get_tree().process_frame
	_check(opening.skipped and _requested == GameManager.FIRST_LEVEL, "%s skips to Level 1" % what)
	Input.parse_input_event(_released(event))
	Input.flush_buffered_events()
	await _free(opening)


## A real (not dry-run) skip: the opening goes away and Level 1 loads.
func _lands_in_level_1() -> void:
	GameManager.dry_run = false
	var opening := _fresh_opening()
	await get_tree().process_frame
	opening.skip()
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		var scene := get_tree().current_scene
		if scene and scene.scene_file_path == GameManager.FIRST_LEVEL:
			break
	var scene := get_tree().current_scene
	_check(scene != null and scene.scene_file_path == GameManager.FIRST_LEVEL, "the game is in Level 1 after the opening")
	_check(scene != null and scene.find_child("Player", true, false) != null, "Level 1 has Amanda in it")
	await get_tree().create_timer(1.0).timeout
	GameManager.dry_run = true


## An opening made the current scene, so a real scene change replaces it
## and not this test.
func _fresh_opening() -> Node:
	_requested = ""
	var opening := OPENING.instantiate()
	get_tree().root.add_child(opening)
	get_tree().current_scene = opening
	return opening


func _free(opening: Node) -> void:
	get_tree().current_scene = self
	opening.queue_free()
	await get_tree().process_frame


func _action_event(action: String) -> InputEvent:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _key_event(key: Key) -> InputEvent:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	return event


func _button_event(button: JoyButton) -> InputEvent:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _released(event: InputEvent) -> InputEvent:
	var up: InputEvent = event.duplicate()
	up.set("pressed", false)
	return up


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		_failures.append(what)

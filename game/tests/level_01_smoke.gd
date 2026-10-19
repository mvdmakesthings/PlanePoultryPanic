extends Node
## Smoke test for Level 1 (Arrivals): checks the layout, the tutorial
## hints, and the critical path (key, locked door, exit). Quits with a
## non-zero exit code on failure. Run from the repo root:
##   godot --headless --path game res://tests/level_01_smoke.tscn

const LEVEL := preload("res://scenes/levels/level_01_arrivals.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	await _layout_tests()
	await _hair_test()
	await _critical_path_test()
	await _chicken_path_test()

	if _failures.is_empty():
		print("LEVEL 1 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _layout_tests() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var hud: Hud = level.get_node("UI/HUD")
	_check(player.snacks == 0, "the player arrives with no snacks")
	await get_tree().physics_frame
	_check(hud._hint.contains("WASD"), "the first hint teaches moving")

	# The north wall stops the player below its face.
	await _hold(["move_up"], 1.0)
	print("player against the lounge's north wall at %s" % player.global_position)
	_check(player.global_position.y >= 64.0 and player.global_position.y < 76.0,
		"the lounge's north wall is solid")

	# Walk east through the doorway into the hall, picking up both snacks.
	player.global_position = Vector2(120, 140)
	await _hold(["move_right"], 1.6)
	print("player after walking east from the lounge at %s" % player.global_position)
	_check(player.global_position.x > 272.0, "the lounge opens into the hallway")

	# The locked door blocks its doorway.
	_kill_chickens()
	player.global_position = Vector2(712, 270)
	await _hold(["move_up"], 0.8)
	_check(player.global_position.y > 256.0, "the locked Security door blocks the doorway")
	_tap("interact")
	await get_tree().physics_frame
	var door: LockedDoor = level.get_node("SecurityDoor")
	_check(door.is_locked, "the door stays locked without the key")
	await get_tree().physics_frame
	_check(hud._hint.contains("staff room"), "trying the locked door hints where the key is")
	level.queue_free()


## Her hair gets messier as she loses health, and tidies up as she heals.
func _hair_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	await get_tree().physics_frame
	_check(player.hair_mess_level() == 0 and not player._hair.visible, "hair is tidy at full health")
	var levels: Array[int] = []
	for i in 4:
		player._invincible_timer = 0.0
		player.take_damage(Player.SUITCASE, player.global_position + Vector2.LEFT)
		levels.append(player.hair_mess_level())
	print("hair mess after losing 1-4 suitcases: %s" % [levels])
	_check(levels == [0, 1, 2, 3], "hair gets messier with each suitcase lost below 75%")
	await get_tree().physics_frame
	_check(player._hair.visible and player._hair.frame % Player.HAIR_LEVELS == 2, "wild hair is drawn")
	player.add_snack()
	player.eat_snack()
	_check(player.hair_mess_level() == 2, "eating tidies her hair a little")
	level.queue_free()


func _critical_path_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var door: LockedDoor = level.get_node("SecurityDoor")
	_kill_chickens()

	# Through the staff room's doorway and over the key.
	player.global_position = Vector2(240, 488)
	await _hold(["move_left"], 2.2)
	print("player after walking into the staff room at %s" % player.global_position)
	_check(player.inventory.has_key_item("maintenance_key"), "the maintenance key is in the staff room")

	player.global_position = door.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.interact_target == door, "the door can be used from below")
	_tap("interact")
	await get_tree().physics_frame
	_check(not door.is_locked, "the maintenance key unlocks the Security door")
	_check(not player.inventory.has_key_item("maintenance_key"), "unlocking uses up the key")

	var entered := [false]
	door.player_entered.connect(func() -> void: entered[0] = true)
	await _wait(0.5)
	await _hold(["move_up"], 1.0)
	_check(entered[0], "walking into the open doorway leaves for Security")
	_check(level._level_over, "going through the door ends the level")
	level.queue_free()


## A chicken outside the staff room finds its way in to a snack.
func _chicken_path_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var chickens := get_tree().get_nodes_in_group("chickens")
	for i in range(1, chickens.size()):
		chickens[i].queue_free()
	var runner: Chicken = chickens[0]
	runner.global_position = Vector2(300, 400)
	runner.snack_notice_range = 300.0  # this test is about routing, not senses
	player.global_position = Vector2(860, 500)
	var bait: ThrownSnack = preload("res://scenes/objects/thrown_snack.tscn").instantiate()
	bait.direction = Vector2.ZERO
	bait.position = Vector2(120, 520)
	level.get_node("Entities").add_child(bait)
	await _wait(7.0)
	if is_instance_valid(runner):
		print("staff-room chicken at %s, state %d" % [runner.global_position, runner.state])
	_check(not is_instance_valid(bait), "a chicken paths through the staff room door to a snack")
	level.queue_free()


func _fresh_level() -> Node:
	await get_tree().process_frame
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	return level


func _kill_chickens() -> void:
	for chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.queue_free()


func _check(condition: bool, description: String) -> void:
	print(("ok    " if condition else "FAIL  ") + description)
	if not condition:
		_failures.append(description)


func _hold(actions: Array, seconds: float) -> void:
	for action: String in actions:
		Input.action_press(action)
	await _wait(seconds)
	for action: String in actions:
		Input.action_release(action)


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout

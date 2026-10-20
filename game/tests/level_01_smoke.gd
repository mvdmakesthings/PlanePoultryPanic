extends Node
## Smoke test for Level 1 (Arrivals): checks the layout, the tutorial
## hints, and the critical path (key, locked door, exit). Quits with a
## non-zero exit code on failure. Run from the repo root:
##   godot --headless --path game res://tests/level_01_smoke.tscn

const LEVEL := preload("res://scenes/levels/level_01_arrivals.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	# Never touch the player's own save or settings, and don't really
	# change scenes (that would replace this test).
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	await _layout_tests()
	await _hair_test()
	await _critical_path_test()
	await _chicken_path_test()
	await _chicken_animation_test()
	await _pause_test()
	await _checkpoint_tests()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
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
	for bus in AudioManager.BUSES:
		_check(AudioServer.get_bus_index(bus) >= 0, "the %s audio bus exists" % bus)
	_check(AudioManager.music_playing() == "arrivals", "Level 1 plays the Arrivals music")
	var hums := AudioManager.playing_loops()
	_check(hums.size() == 1 and hums[0].bus == "Ambience", "the carousel hums on the Ambience bus")
	for sound in ["step", "pickup", "key", "throw", "eat", "hurt", "peck", "splat", "poof",
			"cluck", "spray", "shove", "locked", "unlock", "door", "closet", "death",
			"checkpoint", "level_clear", "ui_move", "ui_confirm", "ui_back"]:
		_check(ResourceLoader.exists(AudioManager.SFX_DIR + sound + ".wav"), "the %s sound exists" % sound)
	await get_tree().physics_frame
	_check(hud._hint.contains("{move}"), "the first hint teaches moving")

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
	await get_tree().physics_frame
	_check(player._sprite.animation == "eat_down", "eating plays the eat animation")
	await _wait(0.6)
	_check(player._sprite.animation.begins_with("idle"), "after eating she goes back to idling")
	player._invincible_timer = 0.0
	player.take_damage(1, player.global_position + Vector2.LEFT)
	await get_tree().physics_frame
	_check(player._sprite.animation.begins_with("hurt_"), "a hit plays the hurt flinch")
	player.facing = Vector2.RIGHT
	player._action_left = 0.0
	player.add_snack()
	player.throw_snack()
	await get_tree().physics_frame
	_check(player._sprite.animation == "throw_right", "throwing plays the throw animation the way she faces")
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
	var menus: GameMenus = level.get_node("UI/GameMenus")
	_check(menus.is_open() and menus._mode == "clear", "the level-clear screen comes up")
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


## Chasing chickens flap and squawk; eating chickens peck and chomp.
func _chicken_animation_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	player._invincible_timer = 1.0e9
	var chickens := get_tree().get_nodes_in_group("chickens")
	for i in range(1, chickens.size()):
		chickens[i].queue_free()
	var chicken: Chicken = chickens[0]
	player.global_position = Vector2(620, 300)
	chicken.global_position = Vector2(560, 300)
	chicken.alert()
	await _wait(0.3)
	var sprite: AnimatedSprite2D = chicken.get_node("AnimatedSprite2D")
	_check(sprite.animation.begins_with("chase_"), "a chasing chicken plays the chase cycle")
	var bait: ThrownSnack = preload("res://scenes/objects/thrown_snack.tscn").instantiate()
	bait.direction = Vector2.ZERO
	bait.position = chicken.global_position + Vector2(-12, 0)
	level.get_node("Entities").add_child(bait)
	player.global_position = Vector2(860, 500)
	var ate := false
	for i in 60:
		await get_tree().physics_frame
		if chicken.state == Chicken.State.EATING:
			await get_tree().physics_frame
			ate = sprite.animation == "eat_down"
			break
	_check(ate, "an eating chicken plays the eat cycle")
	level.queue_free()


## Esc pauses the game behind the pause menu; Esc again resumes.
func _pause_test() -> void:
	var level := await _fresh_level()
	var menus: GameMenus = level.get_node("UI/GameMenus")
	_tap("pause")
	await get_tree().process_frame
	_check(menus.is_open() and get_tree().paused, "Esc pauses the game and opens the pause menu")
	_tap("pause")
	await get_tree().process_frame
	_check(not menus.is_open() and not get_tree().paused, "Esc again resumes")
	level.queue_free()


## Checkpoints autosave; a knockout offers a retry that restores the run
## as it was at the latest checkpoint.
func _checkpoint_tests() -> void:
	SaveSystem.delete_game()
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var save := SaveSystem.load_game()
	_check(save.get("checkpoint") == "start", "starting the level autosaves at its start")

	var baggage: Checkpoint = level.get_node("Entities/CheckpointBaggageClaim")
	player.global_position = baggage.spawn_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(baggage.is_active and SaveSystem.load_game().get("checkpoint") == "baggage_claim",
		"reaching the Baggage Claim map stand autosaves there")

	# Take the key, then reach the staff room's checkpoint.
	player.global_position = Vector2(40, 482)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var staff_spawn: Vector2 = level.get_node("Entities/CheckpointStaffRoom").spawn_point()
	player.global_position = staff_spawn
	await get_tree().physics_frame
	await get_tree().physics_frame
	save = SaveSystem.load_game()
	_check(save.get("checkpoint") == "staff_room", "the staff room checkpoint autosaves")
	_check("Entities/MaintenanceKey" in save.get("collected", []), "the save knows the key was picked up")
	_check(save.get("inventory", {}).get("key_items", {}).has("maintenance_key"), "the save holds the key")

	# Knocked out: the retry screen comes up with a hint.
	player.global_position = Vector2(300, 300)
	while not player.is_dead:
		player._invincible_timer = 0.0
		player.take_damage(Player.PECK, player.global_position + Vector2.LEFT)
	await _wait(1.8)
	var menus: GameMenus = level.get_node("UI/GameMenus")
	_check(menus.is_open() and menus._mode == "retry" and menus._hint != "", "a knockout shows the retry screen with a hint")
	_check(player._sprite.animation == "ko", "the defeat fall ends in the knocked-out pose")
	var requested := [""]
	var on_change := func(path: String) -> void: requested[0] = path
	GameManager.scene_change_requested.connect(on_change)
	_tap("ui_accept")
	await get_tree().process_frame
	GameManager.scene_change_requested.disconnect(on_change)
	_check(requested[0] == level.scene_file_path, "Retry reloads the level")
	_check(GameManager.pending.get("checkpoint") == "staff_room", "Retry starts from the latest checkpoint")
	level.queue_free()

	# The reloaded level puts everything back as it was at the checkpoint.
	level = await _fresh_level()
	player = level.get_node("Entities/Player")
	await get_tree().physics_frame
	print("restored player at %s" % player.global_position)
	_check(player.global_position.distance_to(staff_spawn) < 2.0, "the retry starts at the checkpoint")
	_check(player.inventory.has_key_item("maintenance_key"), "the retry keeps the key")
	_check(not level.has_node("Entities/MaintenanceKey"), "the key isn't lying in the staff room again")
	_check(player.health == player.max_health, "the retry starts with full health")
	_check(level.get_node("Entities/CheckpointBaggageClaim").is_active, "checkpoints already reached stay lit")
	level.queue_free()


func _fresh_level() -> Node:
	get_tree().paused = false
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

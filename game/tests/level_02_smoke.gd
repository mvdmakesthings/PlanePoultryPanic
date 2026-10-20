extends Node
## Smoke test for Level 2 (Security Checkpoint): the layout, arriving from
## Level 1 with the inventory carried over, the extinguisher and mushroom
## patch, the scanner lanes, the shutter, hiding, the boarding pass and the
## gate it opens, and checkpoints. Quits with a non-zero exit code on
## failure. Run from the repo root:
##   godot --headless --path game res://tests/level_02_smoke.tscn

const LEVEL := preload("res://scenes/levels/level_02_security.tscn")
const LEVEL_PATH := "res://scenes/levels/level_02_security.tscn"

var _failures: Array[String] = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	await _arrival_test()
	await _layout_tests()
	await _extinguisher_test()
	await _lane_test()
	await _shutter_test()
	await _hiding_test()
	await _pass_gate_test()
	await _checkpoint_test()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("LEVEL 2 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


## Leaving Arrivals autosaves at the start of Security with the inventory,
## and Security picks it up from there.
func _arrival_test() -> void:
	var inventory := Inventory.new()
	inventory.add_stackable("snack", 4)
	GameManager.level_cleared(LEVEL_PATH, LevelState.capture_inventory(inventory))
	var save := SaveSystem.load_game()
	_check(save.get("level") == LEVEL_PATH and save.get("checkpoint") == "start",
		"clearing Arrivals autosaves at the start of Security")
	var requested := [""]
	var on_change := func(path: String) -> void: requested[0] = path
	GameManager.scene_change_requested.connect(on_change)
	GameManager.continue_run()
	GameManager.scene_change_requested.disconnect(on_change)
	_check(requested[0] == LEVEL_PATH, "going on loads Security")
	var level := await _fresh_level(false)
	var player: Player = level.get_node("Entities/Player")
	var start: Vector2 = level.get_node("Entities/Player").global_position
	_check(player.snacks == 4, "the snacks from Arrivals come along")
	_check(start.distance_to(Vector2(56, 560)) < 1.0, "Amanda starts at the queue hall's entrance")
	level.queue_free()


func _layout_tests() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var hud: Hud = level.get_node("UI/HUD")
	for sound in ["beep", "switch", "shutter"]:
		_check(ResourceLoader.exists(AudioManager.SFX_DIR + sound + ".wav"), "the %s sound exists" % sound)
	_check(AudioManager.music_playing() != "", "Security plays music")
	await get_tree().physics_frame
	_check(hud._hint.contains("boarding pass"), "the first hint says what to look for")
	_check(get_tree().get_nodes_in_group("mushroom_patches").size() == 3, "Security has three mushroom patches")
	# The queue hall's north wall is solid except at the queue's exit.
	_kill_chickens()
	player.global_position = Vector2(400, 470)
	await _hold(["move_up"], 0.8)
	_check(player.global_position.y > 440.0, "the queue hall's north wall is solid")
	player.global_position = Vector2(912, 470)
	await _hold(["move_up"], 1.2)
	print("player after walking up out of the queue at %s" % player.global_position)
	_check(player.global_position.y < 380.0, "the queue's exit opens into the scanner hall")
	level.queue_free()


## The cabinet by the entrance holds an extinguisher; spraying the rage
## patch kills it for good.
func _extinguisher_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var cabinet: ExtinguisherCabinet = level.get_node("QueueCabinet")
	player.global_position = cabinet.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_tap("interact")
	await get_tree().physics_frame
	_check(player.inventory.count_of("extinguisher") == 3, "the queue cabinet holds a 3-charge extinguisher")
	var patch: MushroomPatch = level.get_node("Entities/RagePatch")
	player.global_position = patch.global_position + Vector2(0, 24)
	player.facing = Vector2.UP
	player.spray()
	await _wait(0.8)
	_check(not is_instance_valid(patch), "spraying the rage patch destroys it")
	level.queue_free()

	# A chicken left near the patch powers up from it.
	level = await _fresh_level()
	player = level.get_node("Entities/Player")
	player.global_position = Vector2(80, 560)
	var chicken: Chicken = level.get_node("Entities/QueueChicken")
	for other in get_tree().get_nodes_in_group("chickens"):
		if other != chicken:
			other.queue_free()
	chicken.global_position = level.get_node("Entities/RagePatch").global_position + Vector2(30, 10)
	var powered := false
	for i in 8 * 60:
		await get_tree().physics_frame
		if chicken.power == "rage":
			powered = true
			break
	_check(powered, "a chicken that eats from the rage patch powers up")
	level.queue_free()


## Walking up a scanner lane: the arch beeps and the lane leads into
## screening. Chickens can path through the lanes too.
func _lane_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var detector: MetalDetector = level.get_node("Entities/Detector1")
	player.global_position = Vector2(336, 320)
	var beeped := false
	Input.action_press("move_up")
	for i in 120:
		await get_tree().physics_frame
		if detector._beep_left > 0.0:
			beeped = true
	Input.action_release("move_up")
	print("player after walking up lane 1 at %s" % player.global_position)
	_check(beeped, "walking through the arch makes it beep")
	_check(player.global_position.y < 190.0, "lane 1 leads into the screening area")
	level.queue_free()


## Dropping the shutter flattens a chicken under it and blocks the lane;
## chickens then path around it; raising it opens the lane again.
func _shutter_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var shutter: SecurityShutter = level.get_node("Entities/Lane3Shutter")
	var switch: ShutterSwitch = level.get_node("ShutterSwitch")
	var victim: Chicken = level.get_node("Entities/ShutterChicken")
	for chicken in get_tree().get_nodes_in_group("chickens"):
		if chicken != victim:
			chicken.queue_free()
	await _wait(0.2)
	var map_rid: RID = (level as GameLevel).navigation.get_navigation_map()
	var from := Vector2(656, 320)
	var to := Vector2(656, 150)
	var open_path := _path_length(map_rid, from, to)
	_check(open_path > 0.0 and open_path < 200.0, "chickens can path straight up lane 3")

	victim.global_position = shutter.global_position + Vector2(16, 2)
	victim.set_physics_process(false)
	player.global_position = switch.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.interact_target == switch, "the shutter switch can be used from below")
	_tap("interact")
	await _wait(0.6)
	_check(shutter.is_closed, "the switch drops the shutter")
	_check(not is_instance_valid(victim), "a chicken under the shutter is flattened")
	await _wait(0.5)
	var closed_path := _path_length(map_rid, from, to)
	print("path through lane 3: %.0f px open, %.0f px shut" % [open_path, closed_path])
	_check(closed_path > open_path + 100.0, "chickens path around the closed shutter")

	player.global_position = Vector2(656, 300)
	await _hold(["move_up"], 0.8)
	_check(player.global_position.y > 256.0, "the closed shutter blocks the lane")
	player.global_position = switch.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_tap("interact")
	await _wait(0.5)
	_check(not shutter.is_closed, "the switch raises it again")
	player.global_position = Vector2(656, 300)
	await _hold(["move_up"], 1.2)
	_check(player.global_position.y < 200.0, "the raised shutter lets her through")
	level.queue_free()


func _hiding_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var stall: HidingSpot = level.get_node("Stall2")
	player.global_position = stall.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_tap("interact")
	await get_tree().physics_frame
	_check(player.is_hidden, "a restroom stall is a hiding spot")
	level.queue_free()


## The gate to the Food Court reads the boarding pass, which isn't used up.
func _pass_gate_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var hud: Hud = level.get_node("UI/HUD")
	var gate: LockedDoor = level.get_node("PassGate")
	_kill_chickens()
	player.global_position = gate.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_tap("interact")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(gate.is_locked, "the gate stays shut without a boarding pass")
	_check(hud._hint.contains("boarding pass"), "the gate says it wants a boarding pass")

	var pass_pickup: Node2D = level.get_node("Entities/BoardingPass")
	player.global_position = pass_pickup.global_position
	await _wait(0.1)
	_check(player.inventory.has_key_item("boarding_pass"), "the boarding pass is in the screening bins")
	await get_tree().physics_frame
	_check(hud._hint.contains("FOOD"), "finding the pass points to the Food Court gate")

	player.global_position = gate.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_tap("interact")
	await get_tree().physics_frame
	_check(not gate.is_locked, "the boarding pass opens the gate")
	_check(player.inventory.has_key_item("boarding_pass"), "she keeps the boarding pass")
	await _wait(0.5)
	await _hold(["move_up"], 1.0)
	var menus: GameMenus = level.get_node("UI/GameMenus")
	_check(level._level_over and menus.is_open() and menus._mode == "clear",
		"walking through the gate clears the level")
	_check(SaveSystem.load_game().get("level") == "res://scenes/levels/level_03_food_court.tscn",
		"clearing Security autosaves at the start of the Food Court")
	level.queue_free()


func _checkpoint_test() -> void:
	SaveSystem.delete_game()
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	player.global_position = level.get_node("Entities/BoardingPass").global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	var stand: Checkpoint = level.get_node("Entities/CheckpointCorridor")
	var spawn := stand.spawn_point()
	player.global_position = spawn
	await get_tree().physics_frame
	await get_tree().physics_frame
	var save := SaveSystem.load_game()
	_check(save.get("checkpoint") == "corridor", "the corridor map stand autosaves")
	_check(save.get("inventory", {}).get("key_items", {}).has("boarding_pass"), "the save holds the boarding pass")
	level.queue_free()

	GameManager.retry(LEVEL_PATH)
	level = await _fresh_level(false)
	player = level.get_node("Entities/Player")
	await get_tree().physics_frame
	_check(player.global_position.distance_to(spawn) < 2.0, "a retry starts at the corridor")
	_check(player.inventory.has_key_item("boarding_pass"), "a retry keeps the boarding pass")
	_check(not level.has_node("Entities/BoardingPass"), "the pass isn't lying in the bins again")
	level.queue_free()


func _path_length(map_rid: RID, from: Vector2, to: Vector2) -> float:
	var path := NavigationServer2D.map_get_path(map_rid, from, to, true)
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	return length


## A new copy of the level. fresh=false keeps any pending snapshot.
func _fresh_level(fresh := true) -> Node:
	get_tree().paused = false
	if fresh:
		GameManager.pending = {}
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

extends Node
## Smoke test for Level 4 (the Gate Areas): arriving from the Food Court,
## the layout, moving walkways (carrying, the speed panel, flinging), Gate
## B's roost and shutter, the exit, and the checkpoints between lounges.
## Quits with a non-zero exit code on failure. Run from the repo root:
##   godot --headless --path game res://tests/level_04_smoke.tscn

const LEVEL := preload("res://scenes/levels/level_04_gates.tscn")
const LEVEL_PATH := "res://scenes/levels/level_04_gates.tscn"

var _failures: Array[String] = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	await _arrival_test()
	await _layout_tests()
	await _walkway_test()
	await _fling_test()
	await _gate_b_test()
	await _exit_test()
	await _checkpoint_test()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("LEVEL 4 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _arrival_test() -> void:
	var inventory := Inventory.new()
	inventory.add_stackable("snack", 3)
	inventory.add_key_item("boarding_pass")
	GameManager.level_cleared(LEVEL_PATH, LevelState.capture_inventory(inventory))
	GameManager.continue_run()
	var level := await _fresh_level(false)
	var player: Player = level.get_node("Entities/Player")
	_check(player.inventory.has_key_item("boarding_pass") and player.snacks == 3,
		"the boarding pass and snacks come along from the Food Court")
	level.queue_free()


func _layout_tests() -> void:
	var level := await _fresh_level()
	var hud: Hud = level.get_node("UI/HUD")
	var stuck: Array[String] = level.things_in_walls()
	_check(stuck.is_empty(), "nothing stands inside a wall %s" % [stuck])
	for sound in ["walkway_hum", "whoosh"]:
		_check(ResourceLoader.exists(AudioManager.SFX_DIR + sound + ".wav"), "the %s sound exists" % sound)
	_check(AudioManager.music_playing() != "", "the gate areas play music")
	await get_tree().physics_frame
	_check(hud._hint.contains("Gate C"), "the first hint says where the last flight leaves from")
	_check(get_tree().get_nodes_in_group("walkways").size() == 4, "two corridors of two walkways each")
	_check(not (level.get_node("FinalGateDoor") as LockedDoor).is_locked, "the door on to C13 needs no key")
	level.queue_free()


## Walkways carry her faster with them and slower against them, and the
## speed panel changes how fast.
func _walkway_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var east: Walkway = level.get_node("WalkwayABEast")
	var west: Walkway = level.get_node("WalkwayABWest")
	# Walking east on the floor between the belts, then on the eastbound belt.
	player.global_position = Vector2(540, 216)
	var floor_distance := await _walk_distance(player, "move_right", 0.5)
	player.global_position = Vector2(540, 194)
	var with_distance := await _walk_distance(player, "move_right", 0.5)
	player.global_position = Vector2(760, 258)
	var against_distance := await _walk_distance(player, "move_right", 0.3)
	print("east in 0.5 s: floor %.0f px, with the belt %.0f px; against for 0.3 s: %.0f px" % [
		floor_distance, with_distance, against_distance])
	_check(with_distance > floor_distance + 15.0, "walking with a walkway is faster")
	_check(against_distance < floor_distance * 0.6 * 0.6, "walking against one is slower")

	var panel: SpeedPanel = level.get_node("SpeedPanelAB")
	player.global_position = panel.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.interact_target == panel, "the speed panel can be used from below")
	_tap("interact")
	await get_tree().physics_frame
	_check(east.speed == Walkway.Speed.FULL and west.speed == Walkway.Speed.FULL,
		"the panel turns both walkways up to full")
	_tap("interact")
	await get_tree().physics_frame
	_check(east.speed == Walkway.Speed.SLOW, "and round again to slow")
	level.queue_free()


## At full speed a chicken riding off the end is flung into the wall stub.
func _fling_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var east: Walkway = level.get_node("WalkwayABEast")
	var rider: Chicken = level.get_node("Entities/BeltChickenAB1")
	for chicken in get_tree().get_nodes_in_group("chickens"):
		if chicken != rider:
			chicken.queue_free()
	player.global_position = Vector2(80, 380)
	# At normal speed it rides off the end and lives.
	rider.global_position = east.belt_rect().end - Vector2(20, 14)
	await _wait(1.0)
	_check(is_instance_valid(rider) and not rider.is_flung(), "at normal speed a chicken just rides off the end")
	east.speed = Walkway.Speed.FULL
	rider.global_position = east.belt_rect().end - Vector2(40, 14)
	rider.set_physics_process(true)
	var flung := false
	for i in 90:
		await get_tree().physics_frame
		if not is_instance_valid(rider):
			break
		flung = flung or rider.is_flung()
	_check(flung or not is_instance_valid(rider), "at full speed it's flung off the end")
	_check(not is_instance_valid(rider), "a flung chicken that hits the wall is knocked out")
	level.queue_free()


## Gate B: the roost stacks a totem; the switch works the south room's shutter.
func _gate_b_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	player._invincible_timer = 1.0e9
	for chicken in get_tree().get_nodes_in_group("chickens"):
		if not str(chicken.name).begins_with("RoostChickenB"):
			chicken.queue_free()
	var formed := false
	for i in 12 * 60:
		await get_tree().physics_frame
		if not get_tree().get_nodes_in_group("totems").is_empty():
			formed = true
			break
	_check(formed, "Gate B's roost chickens stack into a totem")
	var switch: ShutterSwitch = level.get_node("ShutterSwitch")
	_check(switch.shutter == level.get_node("Entities/SouthRoomShutter"), "the switch works the south room's shutter")
	level.queue_free()


func _exit_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var door: LockedDoor = level.get_node("FinalGateDoor")
	_kill_chickens()
	player.global_position = door.base_point() + Vector2(0, 20)
	await _hold(["move_up"], 1.2)
	var menus: GameMenus = level.get_node("UI/GameMenus")
	_check(level._level_over and menus.is_open() and menus._mode == "clear",
		"walking through to C13 clears the level")
	level.queue_free()


func _checkpoint_test() -> void:
	SaveSystem.delete_game()
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	for id in ["B", "C"]:
		var stand: Checkpoint = level.get_node("Entities/Checkpoint" + id)
		player.global_position = stand.spawn_point()
		await get_tree().physics_frame
		await get_tree().physics_frame
		_check(SaveSystem.load_game().get("checkpoint") == "gate_" + id.to_lower(),
			"Gate %s's map stand autosaves" % id)
	var spawn: Vector2 = level.get_node("Entities/CheckpointC").spawn_point()
	level.queue_free()
	GameManager.retry(LEVEL_PATH)
	level = await _fresh_level(false)
	await get_tree().physics_frame
	player = level.get_node("Entities/Player")
	_check(player.global_position.distance_to(spawn) < 2.0, "a retry in Gate C starts in Gate C")
	level.queue_free()


func _walk_distance(player: Player, action: String, seconds: float) -> float:
	await get_tree().physics_frame
	var start := player.global_position
	await _hold([action], seconds)
	return player.global_position.x - start.x


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

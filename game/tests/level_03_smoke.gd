extends Node
## Smoke test for Level 3 (Food Court): arriving from Security with the
## boarding pass, the layout, the kitchen key, vending machines, the totem
## forming at the roost, the way out to the gates, and checkpoints. Quits
## with a non-zero exit code on failure. Run from the repo root:
##   godot --headless --path game res://tests/level_03_smoke.tscn

const LEVEL := preload("res://scenes/levels/level_03_food_court.tscn")
const LEVEL_PATH := "res://scenes/levels/level_03_food_court.tscn"

var _failures: Array[String] = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	await _arrival_test()
	await _layout_tests()
	await _vending_test()
	await _totem_test()
	await _exit_test()
	await _checkpoint_test()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("LEVEL 3 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _arrival_test() -> void:
	var inventory := Inventory.new()
	inventory.add_stackable("snack", 2)
	inventory.add_key_item("boarding_pass")
	GameManager.level_cleared(LEVEL_PATH, LevelState.capture_inventory(inventory))
	GameManager.continue_run()
	var level := await _fresh_level(false)
	var player: Player = level.get_node("Entities/Player")
	_check(player.inventory.has_key_item("boarding_pass"), "the boarding pass comes along from Security")
	_check(player.snacks == 2, "so do the snacks")
	level.queue_free()


func _layout_tests() -> void:
	var level := await _fresh_level()
	var stuck: Array[String] = level.things_in_walls()
	_check(stuck.is_empty(), "nothing stands inside a wall %s" % [stuck])
	var player: Player = level.get_node("Entities/Player")
	var hud: Hud = level.get_node("UI/HUD")
	_check(ResourceLoader.exists(AudioManager.SFX_DIR + "vend.wav"), "the vend sound exists")
	_check(AudioManager.music_playing() == "security", "the Food Court shares Security's music")
	await get_tree().physics_frame
	_check(hud._hint.contains("Food Court"), "the first hint welcomes her to the Food Court")
	_check(not (level.get_node("GatesDoor") as LockedDoor).is_locked, "the way to the gates needs no key")
	_kill_chickens()
	# Up through the kitchen door to the key by the janitor's cart.
	player.global_position = Vector2(112, 300)
	await _hold(["move_up"], 1.4)
	print("player after walking into the kitchen at %s" % player.global_position)
	_check(player.global_position.y < 200.0, "the kitchen door is open")
	player.global_position = level.get_node("Entities/KitchenKey").global_position
	await _wait(0.1)
	_check(player.inventory.has_key_item("maintenance_key"), "a maintenance key is in the kitchen")
	await get_tree().physics_frame
	_check(hud._hint.contains("vending"), "finding a key points to the vending machines")
	level.queue_free()


func _vending_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var machine: VendingMachine = level.get_node("Entities/Vending2")
	player.global_position = machine.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.interact_target == machine, "a vending machine can be used from the front")
	_tap("interact")
	await get_tree().physics_frame
	_check(machine.is_locked, "it stays shut without a key")
	player.inventory.add_key_item("maintenance_key")
	var before := player.snacks
	_tap("interact")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not machine.is_locked and not player.inventory.has_key_item("maintenance_key"),
		"a maintenance key opens it and is used up")
	await _hold(["move_down"], 0.4)
	await _hold(["move_left"], 0.3)
	await _hold(["move_right"], 0.6)
	print("snacks before %d, after walking over the drop %d" % [before, player.snacks])
	_check(player.snacks >= before + 2, "it drops snacks to pick up")
	level.queue_free()


## Chickens left alone at the roost stack into a totem, with a hint.
func _totem_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var hud: Hud = level.get_node("UI/HUD")
	player.global_position = Vector2(512, 600)
	player._invincible_timer = 1.0e9
	for chicken in get_tree().get_nodes_in_group("chickens"):
		if not str(chicken.name).begins_with("RoostChicken"):
			chicken.queue_free()
	var formed := false
	for i in 12 * 60:
		await get_tree().physics_frame
		if not get_tree().get_nodes_in_group("totems").is_empty():
			formed = true
			break
	_check(formed, "the roost chickens stack into a totem")
	await get_tree().physics_frame
	_check(hud._hint.contains("TOTEM"), "a hint says how to beat the totem")
	level.queue_free()


func _exit_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var door: LockedDoor = level.get_node("GatesDoor")
	_kill_chickens()
	player.global_position = door.base_point() + Vector2(0, 20)
	await _hold(["move_up"], 1.2)
	var menus: GameMenus = level.get_node("UI/GameMenus")
	_check(level._level_over and menus.is_open() and menus._mode == "clear",
		"walking through the door to the gates clears the level")
	level.queue_free()


## A machine opened before a checkpoint stays open (and empty) on a retry.
func _checkpoint_test() -> void:
	SaveSystem.delete_game()
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	(level.get_node("Entities/Vending1") as VendingMachine).unlock()
	var stand: Checkpoint = level.get_node("Entities/CheckpointPlaza")
	var spawn := stand.spawn_point()
	player.global_position = spawn
	await get_tree().physics_frame
	await get_tree().physics_frame
	var save := SaveSystem.load_game()
	_check(save.get("checkpoint") == "plaza", "the plaza map stand autosaves")
	_check("Entities/Vending1" in save.get("unlocked", []), "the save knows which machine was opened")
	level.queue_free()

	GameManager.retry(LEVEL_PATH)
	level = await _fresh_level(false)
	await get_tree().physics_frame
	player = level.get_node("Entities/Player")
	_check(player.global_position.distance_to(spawn) < 2.0, "a retry starts at the plaza")
	_check(not (level.get_node("Entities/Vending1") as VendingMachine).is_locked, "the opened machine stays open")
	_check((level.get_node("Entities/Vending2") as VendingMachine).is_locked, "the others stay shut")
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

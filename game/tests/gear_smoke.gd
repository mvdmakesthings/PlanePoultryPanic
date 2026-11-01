extends Node
## Smoke test for the gear and maintenance-key variants: the energy drink
## (and its music),
## umbrella and roller skates, the fuse box, lever socket and staff doors
## in the Gate Areas, vending machines dropping a drink, and where each
## pickup is placed. Quits with a non-zero exit code on failure. Run from
## the repo root:
##   godot --headless --path game res://tests/gear_smoke.tscn

const LEVEL := preload("res://scenes/levels/level_04_gates.tscn")
const EGG_SCENE := preload("res://scenes/objects/egg_projectile.tscn")
## Open lounge floor in Gate A, clear of furniture for a few tiles east.
const OPEN_FLOOR := Vector2(60, 380)

var _failures: Array[String] = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	_placement_tests()
	await _energy_drink_test()
	await _umbrella_test()
	await _skates_test()
	await _fuse_test()
	await _lever_test()
	await _staff_door_test()
	await _vending_test()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("GEAR SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


## Every new pickup is in its level, holding the right item.
func _placement_tests() -> void:
	var expected := {
		"res://scenes/levels/level_01_arrivals.tscn": {"LostFoundSkates": "skates"},
		"res://scenes/levels/level_02_security.tscn": {"ScreeningUmbrella": "umbrella", "HallEnergyDrink": "energy_drink"},
		"res://scenes/levels/level_04_gates.tscn": {"SkatesA": "skates", "UmbrellaB": "umbrella",
			"LeverHandle": "lever_handle", "SouthRoomFuse": "fuse", "StaffBadge": "staff_badge"},
	}
	for path: String in expected:
		var state := (load(path) as PackedScene).get_state()
		var found := {}
		for i in state.get_node_count():
			for p in state.get_node_property_count(i):
				if state.get_node_property_name(i, p) == "item":
					found[str(state.get_node_name(i))] = state.get_node_property_value(i, p)
		for node_name: String in expected[path]:
			_check(found.get(node_name) == expected[path][node_name],
				"%s has %s (%s)" % [path.get_file(), node_name, expected[path][node_name]])


func _energy_drink_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	player.global_position = OPEN_FLOOR
	player.pick_up("energy_drink", 2)
	_check(player.inventory.count_of("energy_drink") == 2, "energy drinks stack in one slot")
	player.inventory.select_item("energy_drink")
	_tap("use_item")
	await get_tree().physics_frame
	_check(player.is_buzzing and player.inventory.count_of("energy_drink") == 1, "Use drinks one")
	_check(AudioManager.music_playing() == "buzz", "fast buzz music plays while she's buzzing")
	await _hold(["run", "move_right"], 3.0)
	_check(player.stamina == player.max_stamina, "running while buzzing never drains stamina")
	_tap("use_item")
	await get_tree().physics_frame
	_check(player.inventory.count_of("energy_drink") == 1, "another can't be drunk while still buzzing")
	player._buzz_left = 0.01
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not player.is_buzzing and player.stamina < 5.0 and player._exhausted,
		"when it wears off she crashes with no stamina")
	_check(AudioManager.music_playing() != "buzz", "the buzz music stops when she crashes")
	level.queue_free()


func _umbrella_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	player.global_position = OPEN_FLOOR
	player.facing = Vector2.RIGHT
	player.pick_up("umbrella", 1)
	player.inventory.select_item("umbrella")
	Input.action_press("use_item")
	await get_tree().physics_frame
	_check(player.umbrella_open, "holding Use opens the umbrella")
	var start := player.global_position
	await _hold(["move_left"], 0.5)
	var moved := start.x - player.global_position.x
	_check(moved > 20.0 and moved < 40.0 and player.facing == Vector2.RIGHT,
		"with it open she walks slowly and keeps facing the same way (%.0f px)" % moved)
	# Back out in the open, so the eggs don't start inside a wall.
	player.global_position = OPEN_FLOOR + Vector2(60, 0)
	var health := player.health
	_fire_egg(level, player, Vector2.LEFT)
	await _wait(0.6)
	_check(player.health == health, "an egg from the front pops off the canopy")
	_fire_egg(level, player, Vector2.RIGHT)
	await _wait(0.6)
	_check(player.health < health, "an egg from behind still stings")
	Input.action_release("use_item")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not player.umbrella_open and player.inventory.count_of("umbrella") == 1,
		"letting go closes it, and it isn't used up")
	level.queue_free()


func _skates_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	await get_tree().physics_frame
	player.global_position = OPEN_FLOOR
	player.pick_up("skates", 1)
	player.inventory.select_item("skates")
	_tap("use_item")
	await get_tree().physics_frame
	_check(player.is_skating and player.inventory.count_of("skates") == 0, "Use puts the skates on, used up")
	var start := player.global_position
	await _hold(["move_right"], 1.2)
	var skated := player.global_position.x - start.x
	_check(skated > player.walk_speed * 1.2, "skating goes further than walking (%.0f px in 1.2 s)" % skated)
	var let_go := player.global_position.x
	await _wait(0.3)
	_check(player.global_position.x - let_go > 10.0, "she coasts on after letting go")
	# Skate fast into a chicken: it's knocked flying.
	player.global_position = OPEN_FLOOR
	player._skate_velocity = Vector2.RIGHT * player.skate_speed
	var chicken: Chicken = (load("res://scenes/characters/chicken.tscn") as PackedScene).instantiate()
	chicken.position = OPEN_FLOOR + Vector2(30, 0)
	level.get_node("Entities").add_child(chicken)
	var flung := false
	Input.action_press("move_right")
	for i in 40:
		await get_tree().physics_frame
		if not is_instance_valid(chicken):
			flung = true
			break
		flung = flung or chicken.is_flung()
	Input.action_release("move_right")
	_check(flung, "skating into a chicken knocks it flying")
	player._skate_left = 0.01
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not player.is_skating, "the skates wear out")
	level.queue_free()


func _fuse_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var box: FuseBox = level.get_node("FuseBoxBC")
	var east: Walkway = level.get_node("WalkwayBCEast")
	_check(not east.powered and east.push_at(east.belt_rect().get_center()) == Vector2.ZERO,
		"the Gate B-C walkways start with no power")
	player.global_position = box.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.interact_target == box, "the fuse box can be used from below")
	_tap("interact")
	await get_tree().physics_frame
	_check(box.is_locked, "it needs a fuse")
	player.pick_up("fuse", 1)
	_tap("interact")
	await get_tree().physics_frame
	_check(not box.is_locked and east.powered and not player.inventory.has_key_item("fuse"),
		"fitting the fuse powers the walkways and uses it up")
	level.queue_free()


func _lever_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var socket: LeverSocket = level.get_node("LeverSocketAB")
	var east: Walkway = level.get_node("WalkwayABEast")
	var west: Walkway = level.get_node("WalkwayABWest")
	player.global_position = socket.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.interact_target == socket, "the lever socket can be used from below")
	_tap("interact")
	await get_tree().physics_frame
	_check(socket.is_locked and east.east, "it does nothing without the handle")
	player.pick_up("lever_handle", 1)
	_tap("interact")
	await get_tree().physics_frame
	_check(not socket.is_locked and east.east, "the handle fits and stays in the socket")
	_tap("interact")
	await get_tree().physics_frame
	_check(not east.east and west.east, "pulling the lever turns both walkways around")
	level.queue_free()


func _staff_door_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var door_b: StaffDoor = level.get_node("StaffDoorB")
	var door_c: StaffDoor = level.get_node("StaffDoorC")
	player.global_position = door_b.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(player.interact_target == door_b, "the staff door can be used from below")
	_tap("interact")
	await _wait(1.0)
	_check(player.global_position.distance_to(door_c.base_point()) > 100.0, "it's staff only without a badge")
	player.pick_up("staff_badge", 1)
	_tap("interact")
	await _wait(1.5)
	_check(player.global_position.distance_to(door_c.base_point()) < 4.0, "with the badge it leads to Gate C")
	_check(player.inventory.has_key_item("staff_badge"), "the badge isn't used up")
	level.queue_free()


func _vending_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var machine: VendingMachine = level.get_node("Entities/VendingB")
	player.global_position = machine.base_point()
	player.pick_up("maintenance_key", 1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_tap("interact")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var drinks := level.get_node("Entities").get_children().filter(func(node: Node) -> bool:
		return node is ItemPickup and node.item == "energy_drink")
	_check(not machine.is_locked and drinks.size() == 1, "a vending machine drops an energy drink with its snacks")
	level.queue_free()


func _fire_egg(level: Node, player: Player, direction: Vector2) -> void:
	player._invincible_timer = 0.0
	var egg := EGG_SCENE.instantiate() as EggProjectile
	egg.direction = direction
	egg.position = player.global_position - direction * 40.0
	level.get_node("Entities").add_child(egg)


func _fresh_level() -> Node:
	get_tree().paused = false
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

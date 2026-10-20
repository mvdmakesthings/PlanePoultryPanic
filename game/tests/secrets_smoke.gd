extends Node
## Smoke test for the secrets (GDD: Secrets): the secret_found hook and its
## save, every level's secret room (opening the door finds it, going in,
## coming back out), the stashes, the FRAGILE suitcase, the Pilot Caps, the
## gags, secrets staying found after a retry, and the ending's captain.
## Quits with a non-zero exit code on failure. Run from the repo root:
##   godot --headless --path game res://tests/secrets_smoke.tscn

const LEVELS := {
	1: "res://scenes/levels/level_01_arrivals.tscn",
	2: "res://scenes/levels/level_02_security.tscn",
	3: "res://scenes/levels/level_03_food_court.tscn",
	4: "res://scenes/levels/level_04_gates.tscn",
	5: "res://scenes/levels/level_05_final_gate.tscn",
}
const ENDING := preload("res://scenes/ui/ending.tscn")

var _failures: Array[String] = []
var _signalled: Array[String] = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	GameManager.secret_found.connect(func(id: String) -> void: _signalled.append(id))
	await _hook_test()
	await _rooms_test()
	await _arrivals_test()
	await _security_test()
	await _food_court_test()
	await _gates_test()
	await _final_test()
	await _retry_test()
	await _ending_test()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("SECRETS SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _hook_test() -> void:
	GameManager.new_game()
	_check(GameManager.SECRETS.size() == GameManager.SECRETS_TOTAL, "SECRETS_TOTAL matches the list (%d)" % GameManager.SECRETS.size())
	_check(GameManager.SECRETS_TOTAL == 11, "there are 11 secrets, as in the GDD")
	_check(GameManager.find_secret("arrivals_bag"), "finding a secret the first time counts")
	_check(not GameManager.find_secret("arrivals_bag"), "finding it again doesn't")
	_check(_signalled == ["arrivals_bag"], "secret_found fires once per secret %s" % [_signalled])
	GameManager.checkpoint_reached({"level": LEVELS[1], "checkpoint": "start"})
	var save := SaveSystem.load_game()
	_check("arrivals_bag" in save.get("secrets", []), "checkpoints save the secrets found")
	GameManager.secrets_found.clear()
	GameManager.continue_game()
	_check(GameManager.has_secret("arrivals_bag"), "Continue brings them back")
	GameManager.new_game()
	_check(GameManager.secrets_found.is_empty(), "a new game starts with none found")
	_signalled.clear()


## Every level's secret room: open the door (finds it), go in, come out.
func _rooms_test() -> void:
	var doors := {1: "LostFoundPanel", 2: "StaffOnlyDoor", 3: "FreezerPanel", 4: "EmergencyExit", 5: "PeckedVent"}
	for n: int in doors:
		var level := await _fresh_level(n)
		var player: Player = level.get_node("Entities/Player")
		_kill_chickens()
		var stuck: Array[String] = level.things_in_walls()
		_check(stuck.is_empty(), "L%d: nothing stands inside a wall %s" % [n, stuck])
		var door: SecretDoor = level.get_node(doors[n])
		var room: SecretRoom = door.room
		_check(room != null, "L%d: the %s leads to a room" % [n, door.name])
		var rows := PackedStringArray(level.map)
		var tile := Vector2i(door.base_point() / LevelBuilder.TILE)
		_check(not LevelBuilder.is_map_wall(rows, tile.x, tile.y), "L%d: the floor in front of the door is open" % n)
		_check(LevelBuilder.is_map_wall(rows, tile.x, tile.y - 1), "L%d: the door is set in a wall" % n)
		player.global_position = door.base_point()
		await _frames(2)
		_check(player.interact_target == door, "L%d: the door can be used from below" % n)
		_tap("interact")
		await _frames(2)
		_check(door.is_open and GameManager.has_secret(door.secret_id), "L%d: opening it finds %s" % [n, door.secret_id])
		_tap("interact")
		await _wait(0.8)
		_check(room.exit_rect().position.y > room.entry_point().y, "L%d: the way out is below the way in" % n)
		_check(player.global_position.distance_to(room.entry_point()) < 4.0, "L%d: going in puts her in the room" % n)
		var camera: Camera2D = player.get_node("Camera2D")
		_check(camera.limit_left >= int(level.map[0].length() * LevelBuilder.TILE), "L%d: the camera frames the room, away from the level" % n)
		var mural: Sprite2D = room.get_node("Mural")
		_check(mural.frame == n - 1, "L%d: mural panel %d is on the wall" % [n, n])
		var pickups := room.find_children("*", "ItemPickup", true, false)
		_check(pickups.size() >= 2, "L%d: the room holds a stash (%d pickups)" % [n, pickups.size()])
		# Walk out through the gap in the bottom wall.
		await _hold(["move_down"], 0.6)
		await _wait(0.8)
		# She keeps walking while the screen fades, so she comes out just below it.
		var out := player.global_position - door.base_point()
		_check(absf(out.x) < 4.0 and out.y >= 0.0 and out.y < 48.0,
			"L%d: walking out of the gap comes back to the door (%s)" % [n, out])
		_check(camera.limit_right == int(level.map[0].length() * LevelBuilder.TILE), "L%d: and the camera is back on the level" % n)
		level.queue_free()
	_check(_signalled.size() == 5, "each room was signalled once %s" % [_signalled])


func _arrivals_test() -> void:
	var level := await _fresh_level(1)
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var bag: SecretStash = level.get_node("Entities/AmandasBag")
	var start := bag.global_position
	await _wait(0.5)
	_check(bag.global_position.distance_to(start) > 5.0, "Amanda's bag rides the carousel")
	player.global_position = bag.global_position + Vector2(0, 4)
	await _frames(2)
	_check(player.interact_target == bag, "she can reach her bag on the belt")
	var snacks := player.snacks
	_tap("interact")
	await _frames(3)
	_check(GameManager.has_secret("arrivals_bag"), "grabbing it finds the secret")
	_check(player.snacks > snacks, "and there are snacks in it")
	var moved := bag.global_position
	await _wait(0.3)
	_check(bag.global_position == moved, "a searched bag stops riding")
	_check(level.get_node_or_null("Entities/FuelDrum") != null, "the staff room has its glowing fuel drum")
	_check(level.pa_lines.any(func(line: String) -> bool: return line.contains("not usually doors")), "a meta PA line plays in Arrivals")
	level.queue_free()


func _security_test() -> void:
	var level := await _fresh_level(2)
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var bin: SecretStash = level.get_node("Entities/ConfiscatedBin")
	player.global_position = bin.global_position + Vector2(0, 10)
	await _frames(2)
	_check(player.interact_target == bin, "the CONFISCATED bin can be searched from below its table")
	_tap("interact")
	await _frames(2)
	_check(GameManager.has_secret("security_bin") and bin.searched, "searching it finds the secret")
	# Lane 1's arch plays the tune on the fifth pass in a row.
	var arch: MetalDetector = level.get_node("Entities/Detector1")
	_check(arch.tune_after == 5, "lane 1's arch plays the tune after five passes")
	for i in 4:
		arch._on_body_entered(player)
	_check(arch._beep_left <= MetalDetector.BEEP_TIME, "four passes just beep")
	arch._on_body_entered(player)
	_check(arch._beep_left > MetalDetector.BEEP_TIME, "the fifth plays the cluck tune")
	_check(ResourceLoader.exists(AudioManager.SFX_DIR + "cluck_tune.wav"), "the cluck tune exists")
	# Hide in stall 3 long enough and the PA notices.
	var stall: HidingSpot = level.get_node("Stall3")
	player.global_position = stall.base_point()
	await _frames(2)
	stall.interact(player)
	level._stall_time = level.STALL_GAG_TIME - 0.1
	await _wait(0.3)
	_check((level.get_node("UI/HUD") as Hud)._pa.contains("Stall 3"), "hiding in stall 3 gets a PA line")
	stall.interact(player)
	level.queue_free()


func _food_court_test() -> void:
	var level := await _fresh_level(3)
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	var hoard: SecretStash = level.get_node("Entities/SnackHoard")
	_check(level.get_node_or_null("FloorLitter/Crumbs1") != null, "a crumb trail leads to the hoard")
	player.global_position = hoard.global_position + Vector2(0, 8)
	await _frames(2)
	_check(player.interact_target == hoard, "the snack hoard can be searched")
	_tap("interact")
	await _frames(3)
	_check(GameManager.has_secret("food_court_hoard"), "searching it finds the secret")
	level.queue_free()


func _gates_test() -> void:
	var level := await _fresh_level(4)
	var player: Player = level.get_node("Entities/Player")
	_kill_chickens()
	# The FRAGILE suitcase bursts into snacks when thrown.
	var fragile: Suitcase = level.get_node("Entities/FragileSuitcase")
	player.global_position = fragile.global_position + Vector2(0, 6)
	await _frames(2)
	_check(player.interact_target == fragile, "the FRAGILE suitcase can be lifted")
	_tap("interact")
	await _frames(2)
	player.facing = Vector2.RIGHT
	_tap("use_item")
	await _wait(1.6)
	_check(GameManager.has_secret("gates_fragile"), "throwing it finds the secret")
	_check(not is_instance_valid(fragile), "and it's gone")
	var spilled := 0
	for node in level.get_node("Entities").get_children():
		if node is ItemPickup and node.global_position.distance_to(player.global_position) < 120.0:
			spilled += 1
	_check(spilled >= 3, "it spills snacks (%d)" % spilled)
	# The Pilot Cap: chickens ignore it, the extinguisher grounds it.
	var lounge: SecretRoom = level.get_node("PlatinumLounge")
	var cap: PilotCap = lounge.get_node("PilotCap")
	_check(not cap.is_in_group("mushroom_patches"), "chickens don't count the Pilot Cap as food")
	player.give_extinguisher(3)
	player.global_position = cap.global_position + Vector2(-30, 0)
	player.facing = Vector2.RIGHT
	await _frames(2)
	player.spray()
	await _wait(0.6)
	_check(GameManager.has_secret("gates_pilot_cap"), "spraying the Pilot Cap finds the secret")
	_check(not is_instance_valid(cap), "and it's gone")
	# Flip a speed panel five times quickly: WHEEE.
	var panel: SpeedPanel = level.get_node("SpeedPanelAB")
	for i in 5:
		panel.interact(player)
	_check(panel._flips.is_empty(), "five quick flips set off the WHEEE gag")
	var board: Sprite2D = level.get_node("WallDecor/BoardB")
	_check(board.texture.resource_path.ends_with("departure_board_gates_b.png"), "Gate B's board lists the HOME flight")
	_check(level.get_node_or_null("Entities/CaptainChicken") != null, "a chicken in a pilot's cap sits at Gate C")
	level.queue_free()


func _final_test() -> void:
	var level := await _fresh_level(5)
	_kill_chickens()
	var cap: PilotCap = level.get_node("CrewRoom/PilotCap")
	cap.destroy()
	await _frames(2)
	_check(GameManager.has_secret("final_pilot_cap"), "the crew room's Pilot Cap counts too")
	level.queue_free()


## Secrets stay found: a level loaded again shows them found.
func _retry_test() -> void:
	var level := await _fresh_level(4)
	_check((level.get_node("EmergencyExit") as SecretDoor).is_open, "a found room's door stays open")
	_check(level.get_node_or_null("PlatinumLounge/PilotCap") == null, "a sprayed Pilot Cap stays gone")
	_check(level.get_node_or_null("Entities/FragileSuitcase") == null, "a burst FRAGILE suitcase stays gone")
	level.queue_free()
	level = await _fresh_level(2)
	_check((level.get_node("Entities/ConfiscatedBin") as SecretStash).searched, "a searched stash stays searched")
	level.queue_free()


func _ending_test() -> void:
	var missing: Array[String] = []
	for id in GameManager.SECRETS:
		if not GameManager.has_secret(id):
			missing.append(id)
	_check(missing.is_empty(), "every secret was found in this test %s" % [missing])
	_check(GameManager.found_every_secret(), "found_every_secret() agrees")
	var ending: Ending = ENDING.instantiate()
	add_child(ending)
	await _frames(2)
	_check(ending.captain, "the ending knows every secret was found")
	_check(ending._window.texture.resource_path.ends_with("stowaway_captain.png"), "the stowaway wears the captain's hat")
	ending.queue_free()
	GameManager.secrets_found.erase("arrivals_bag")
	ending = ENDING.instantiate()
	add_child(ending)
	await _frames(2)
	_check(not ending.captain, "missing one secret keeps the plain stowaway")
	ending.queue_free()


# ---------- helpers ----------

func _fresh_level(n: int) -> GameLevel:
	get_tree().paused = false
	GameManager.pending = {}
	await get_tree().process_frame
	var level := (load(LEVELS[n]) as PackedScene).instantiate() as GameLevel
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	return level


func _kill_chickens() -> void:
	for chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.queue_free()


func _check(condition: bool, description: String) -> void:
	print(("ok    " if condition else "FAIL  ") + description)
	if not condition:
		_failures.append(description)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


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

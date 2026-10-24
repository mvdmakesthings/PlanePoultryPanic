extends Node
## Smoke test for Level 5 (the Final Departure Gate): arriving with the
## boarding pass, the Supreme Totem forming, taking three hits (and
## ignoring snacks), the escape (countdown, vents, the boarding door, the
## jet bridge, the plane door), running out of time, and the checkpoint
## after the boss. Quits with a non-zero exit code on failure. Run from the
## repo root:
##   godot --headless --path game res://tests/level_05_smoke.tscn

const LEVEL := preload("res://scenes/levels/level_05_final_gate.tscn")
const LEVEL_PATH := "res://scenes/levels/level_05_final_gate.tscn"

var _failures: Array[String] = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	await _arrival_test()
	await _layout_tests()
	await _totem_walkway_test()
	await _boss_and_escape_test()
	await _time_out_test()
	await _ending_test()
	SaveSystem.delete_game()
	SaveSystem.delete_best()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("LEVEL 5 SMOKE TEST PASSED")
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
		"the boarding pass and snacks come along from the gate areas")
	level.queue_free()


func _layout_tests() -> void:
	var level := await _fresh_level()
	var stuck: Array[String] = level.things_in_walls()
	_check(stuck.is_empty(), "nothing stands inside a wall %s" % [stuck])
	_check(ResourceLoader.exists("res://assets/sprites/departure_board_final.png"), "the final gate has its own departure board")
	for sound in ["boss_hit", "crown_burst", "tick", "pa_chime", "vent"]:
		_check(ResourceLoader.exists(AudioManager.SFX_DIR + sound + ".wav"), "the %s sound exists" % sound)
	_check(ResourceLoader.exists(AudioManager.MUSIC_DIR + "boss.wav"), "the boss music exists")
	_check((level.get_node("BoardingDoor") as LockedDoor).sealed, "the boarding door is sealed at first")
	var still := true
	for chicken in level._boss_chickens():
		still = still and not chicken.is_physics_processing()
	_check(still, "the boss's chickens wait until she steps into the boarding area")
	level.queue_free()


## A totem across a walkway from her sees over the rails, walks around
## the end (out of its sight range on the way) and reaches her; a flight
## that lands where she stands right under a rail settles beside it.
func _totem_walkway_test() -> void:
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	player._invincible_timer = 1.0e9
	player.set_physics_process(false)
	for chicken in level._boss_chickens():
		chicken.queue_free()
	player.global_position = Vector2(640, 170)
	var totem: Totem = preload("res://scenes/characters/totem.tscn").instantiate()
	totem.position = Vector2(640, 92)
	totem.flight_interval = 1.0e9
	totem.barrage_cooldown = 1.0e9
	totem.stomp_trigger = -1.0
	level.get_node("Entities").add_child(totem)
	totem._flight_ready_in = 1.0e9
	# Around the end and back is about 460 px at 45 px/s.
	await _wait(13.0)
	_check(totem.global_position.distance_to(player.global_position) < 20.0,
		"a totem goes around a walkway to reach her (at %s)" % totem.global_position)
	player.global_position = Vector2(640, 148)
	totem._take_off()
	await _wait(4.0)
	_check(totem.state != Totem.State.FLYING, "a totem landing by a walkway rail touches down")
	level.queue_free()


func _boss_and_escape_test() -> void:
	SaveSystem.delete_game()
	var level := await _fresh_level()
	var player: Player = level.get_node("Entities/Player")
	var hud: Hud = level.get_node("UI/HUD")
	player._invincible_timer = 1.0e9
	for name in ["LoungeChicken1", "LoungeChicken2"]:
		level.get_node("Entities/" + name).queue_free()
	# Stepping into the boarding area: the chickens stack into the boss.
	player.global_position = Vector2(380, 380)
	await get_tree().physics_frame
	_check(AudioManager.music_playing() == "boss", "the boss music starts")
	for i in 12 * 60:
		await get_tree().physics_frame
		if is_instance_valid(level.boss):
			break
	var boss: Totem = level.boss
	_check(is_instance_valid(boss), "eight chickens stack into the Supreme Totem")
	if not is_instance_valid(boss):
		level.queue_free()
		return
	_check(boss.members == 8 and boss.crowned and boss.hits_left() == 3, "it's eight tall, crowned, and takes three hits")
	_check(hud._boss_max == 3 and hud._boss_hits == 3, "the HUD shows its three hits")
	await get_tree().physics_frame
	_check(hud._hint.contains("SUPREME"), "a hint says how to beat it")

	# Snacks don't break it up.
	for k in 3:
		var bait: ThrownSnack = preload("res://scenes/objects/thrown_snack.tscn").instantiate()
		bait.direction = Vector2.ZERO
		bait.position = boss.global_position + Vector2(20, 0).rotated(k * 2.0)
		level.get_node("Entities").add_child(bait)
	await _wait(0.3)
	_check(is_instance_valid(boss), "three snacks beside it don't break it up")

	# Hit one: lured onto a walkway.
	boss.global_position = Vector2(700, 340)
	await _wait(0.3)
	_check(is_instance_valid(boss) and boss.hits_left() == 2 and boss.members < 8,
		"a walkway under it is a hit: it sheds chickens")
	_check(hud._boss_hits == 2, "the HUD counts the hit")
	boss.global_position = Vector2(640, 232)
	await _wait(2.2)
	boss.topple(Vector2.RIGHT)
	await get_tree().physics_frame
	_check(boss.hits_left() == 1, "a second hit")
	boss.topple(Vector2.RIGHT)
	_check(boss.hits_left() == 1, "it can't be hit again while it reels")
	await _wait(2.2)
	boss.topple(Vector2.LEFT)
	await _wait(1.0)
	_check(not is_instance_valid(boss) and level.boss_beaten, "the third hit brings it down for good")
	_check(level.escape_left > 25.0, "the escape countdown starts")
	_check(hud._pa.contains("FINAL CALL"), "the PA makes the final call")
	_check(not (level.get_node("BoardingDoor") as LockedDoor).sealed, "the boarding door unseals")
	var save := SaveSystem.load_game()
	_check(save.get("checkpoint") == "escape" and save.get("extra", {}).get("boss_beaten") == true,
		"beating the boss autosaves")

	# Vents drop chickens during the escape.
	var before := get_tree().get_nodes_in_group("chickens").size()
	await _wait(2.6)
	_check(get_tree().get_nodes_in_group("chickens").size() > before, "chickens drop out of the vents")

	# Through the boarding door to the jet bridge, and up the walkway.
	var door: LockedDoor = level.get_node("BoardingDoor")
	player.global_position = door.base_point()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_tap("interact")
	await get_tree().physics_frame
	_check(not door.is_locked, "the boarding pass opens the boarding door")
	await _wait(0.4)
	await _hold(["move_up"], 0.8)
	await _wait(0.8)
	print("player after the boarding door at %s" % player.global_position)
	_check(player.global_position.y > 26 * 16, "the boarding door leads into the jet bridge")
	_kill_chickens()
	player.global_position = Vector2(110, 496)
	await _hold(["move_right"], 0.3)
	_kill_chickens()
	await _hold(["move_right"], 4.6)
	print("player along the jet bridge at %s" % player.global_position)
	_check(player.global_position.x > 1000.0, "the jet bridge walkway rushes her toward the plane")
	var plane: LockedDoor = level.get_node("PlaneDoor")
	var requested := [""]
	var on_change := func(path: String) -> void: requested[0] = path
	GameManager.scene_change_requested.connect(on_change)
	player.global_position = plane.base_point() + Vector2(0, 6)
	await _hold(["move_up"], 1.0)
	_check(level._level_over and level.escape_left < 0.0, "the plane door ends the level and the countdown")
	await _wait(1.4)
	GameManager.scene_change_requested.disconnect(on_change)
	_check(requested[0] == "res://scenes/ui/ending.tscn", "boarding the plane plays the ending")
	level.queue_free()


## Retrying from the boss checkpoint restarts the escape, and running out
## of time is a knockout with a hint about it.
func _time_out_test() -> void:
	GameManager.retry(LEVEL_PATH)
	var level := await _fresh_level(false)
	await get_tree().physics_frame
	var player: Player = level.get_node("Entities/Player")
	_check(level.boss_beaten and level.escape_left > 25.0, "a retry after the boss starts the escape again")
	_check(level._boss_chickens().is_empty(), "the boss doesn't come back")
	_check(not (level.get_node("BoardingDoor") as LockedDoor).sealed, "the boarding door stays unsealed")
	level.escape_left = 0.3
	await _wait(2.2)
	var menus: GameMenus = level.get_node("UI/GameMenus")
	_check(player.is_dead and player.last_hit == "time", "running out of time is a knockout")
	_check(menus.is_open() and (menus._hint.contains("doors") or menus._hint.contains("time")),
		"the retry screen says the doors closed")
	level.queue_free()


## The ending plays through to THE END (skippable), and from there goes
## on to the score screen with the finished run's save cleared.
func _ending_test() -> void:
	get_tree().paused = false
	SaveSystem.save_game({"level": LEVEL_PATH, "checkpoint": "escape"})
	var ending: Ending = preload("res://scenes/ui/ending.tscn").instantiate()
	add_child(ending)
	await get_tree().process_frame
	_check(AudioManager.music_playing() == "victory", "the ending plays the victory music")
	_check(ending.shot == "boarding", "it opens on Amanda boarding")
	_tap("ui_accept")
	await _wait(1.6)
	_check(ending.shot == "end", "a press skips ahead to THE END")
	var requested := [""]
	var on_change := func(path: String) -> void: requested[0] = path
	GameManager.scene_change_requested.connect(on_change)
	_tap("ui_accept")
	await get_tree().process_frame
	GameManager.scene_change_requested.disconnect(on_change)
	_check(requested[0] == GameManager.SCORE_SCREEN and not SaveSystem.has_save(),
		"THE END goes on to the score screen, and the finished run's save is cleared")
	ending.queue_free()


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

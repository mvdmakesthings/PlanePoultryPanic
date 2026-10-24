extends Node
## Smoke test for spreading mushrooms: ripe patches grow sprouts nearby,
## sprouts can't be eaten, ripen into patches, get stomped or sprayed,
## stay off belts and away from Amanda, stop at the level's cap, and are
## gone after a retry. Quits with a non-zero exit code on failure. Run from
## the repo root:
##   godot --headless --path game res://tests/mushroom_spread_smoke.tscn

const FOOD_COURT := preload("res://scenes/levels/level_03_food_court.tscn")
const FOOD_COURT_PATH := "res://scenes/levels/level_03_food_court.tscn"
const ARRIVALS := preload("res://scenes/levels/level_01_arrivals.tscn")
const SECURITY := preload("res://scenes/levels/level_02_security.tscn")
const GATES := preload("res://scenes/levels/level_04_gates.tscn")
const TILE := LevelBuilder.TILE

var _failures: Array[String] = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	SaveSystem.settings_path = "user://test_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	await _cap_tests()
	await _sprout_tests()
	await _stomp_and_spray_tests()
	await _placement_tests()
	await _full_level_test()
	await _retry_test()
	SaveSystem.delete_game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("MUSHROOM SPREAD SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _cap_tests() -> void:
	var level: GameLevel = await _fresh_level(ARRIVALS)
	_check(level.mushroom_cap == 0, "Arrivals has no patches, so nothing spreads")
	level.queue_free()
	level = await _fresh_level(SECURITY)
	_check(level.mushroom_cap == 9, "Security's 3 patches allow 9 in all (got %d)" % level.mushroom_cap)
	var patch: MushroomPatch = level.get_node("Entities/RagePatch")
	_check(patch.spread_time == 21.0, "Security's patches spread slower, for teaching")
	level.queue_free()


func _sprout_tests() -> void:
	var level: GameLevel = await _fresh_level(FOOD_COURT)
	var hud: Hud = level.get_node("UI/HUD")
	_park_player(level)
	var patch: MushroomPatch = level.get_node("Entities/RagePatch")
	_check(patch.spread_time == 13.0, "patches spread every 13 seconds by default")

	# An eaten patch doesn't spread until it regrows.
	patch.eat()
	patch._spread_timer = 0.0
	await _frames(3)
	_check(_sprouts(level).is_empty(), "an eaten patch doesn't spread")
	patch._regrow_timer = 0.0
	await _frames(2)
	_check(patch.is_ripe and patch._spread_timer > 12.0, "it regrows with its spread timer started over")

	patch._spread_timer = 0.0
	await _frames(3)
	var sprouts := _sprouts(level)
	_check(sprouts.size() == 1, "a ripe patch grows a sprout when its timer runs out")
	if sprouts.is_empty():
		level.queue_free()
		return
	var sprout: MushroomPatch = sprouts[0]
	var distance := sprout.global_position.distance_to(patch.global_position)
	print("sprout landed %.1f px from its parent" % distance)
	_check(distance >= 2.0 * TILE - 1.0 and distance <= 4.0 * TILE + 1.0, "it lands 2-4 tiles away")
	_check(sprout.variety == patch.variety, "it's the parent's kind")
	_check(sprout.owner == level, "it belongs to the level")
	_check(not sprout.is_ripe and not sprout.eat(), "a sprout can't be eaten")
	_check(sprout.get_node("Sprite2D").texture == MushroomPatch.SPROUT_SHEET, "it's drawn as a bud")
	await get_tree().physics_frame
	_check(hud._hint.contains("spreading"), "the first sprout comes with a hint")

	# A chicken right next to a sprout doesn't go for it.
	var chicken: Chicken = get_tree().get_nodes_in_group("chickens")[0]
	chicken.global_position = sprout.global_position + Vector2(10, 0)
	chicken._try_seek_mushroom()
	_check(chicken._target_patch != sprout, "chickens ignore sprouts")
	_kill_chickens()

	sprout._sprout_timer = 1.0
	await _frames(3)
	_check(absf(sprout.rotation) > 0.0 or sprout._sprout_timer < 1.0, "a sprout about to ripen wobbles")
	sprout._sprout_timer = 0.0
	await _frames(2)
	_check(sprout.is_ripe and not sprout.is_sprout, "a sprout ripens into a full patch")
	_check(sprout.get_node("Sprite2D").texture == MushroomPatch.PATCH_SHEET, "and looks like one")
	_check(sprout.eat(), "which chickens can eat")
	sprout._regrow_timer = 0.0
	await _frames(2)
	var before := level.patch_count()
	sprout._spread_timer = 0.0
	await _frames(3)
	_check(level.patch_count() == before + 1, "a ripe sprout spreads too")
	level.queue_free()


func _stomp_and_spray_tests() -> void:
	var level: GameLevel = await _fresh_level(FOOD_COURT)
	var player := _park_player(level)
	_kill_chickens()
	var patch: MushroomPatch = level.get_node("Entities/FlightPatch")
	patch._spread_timer = 0.0
	await _frames(3)
	var sprout: MushroomPatch = _sprouts(level)[0] if not _sprouts(level).is_empty() else null
	_check(sprout != null, "the flight patch sprouts")
	if sprout == null:
		level.queue_free()
		return
	player.global_position = sprout.global_position + Vector2(0, 3)
	await _frames(2)
	_check(not sprout.is_in_group("mushroom_patches"), "walking over a sprout stomps it")
	await _wait(0.5)
	_check(not is_instance_valid(sprout), "the stomped sprout is gone")

	# A ripe patch can't be stomped.
	player.global_position = patch.global_position
	await _frames(2)
	_check(is_instance_valid(patch) and patch.is_in_group("mushroom_patches"), "stomping doesn't hurt a full patch")

	_park_player(level)
	patch._spread_timer = 0.0
	await _frames(3)
	sprout = _sprouts(level)[0] if not _sprouts(level).is_empty() else null
	if sprout:
		player.give_extinguisher(1)
		player.global_position = sprout.global_position + Vector2(-20, 0)
		player.facing = Vector2.RIGHT
		player.spray()
		await _wait(0.6)
		_check(not is_instance_valid(sprout), "spraying kills a sprout")
	else:
		_check(false, "the flight patch sprouts again")
	level.queue_free()


func _placement_tests() -> void:
	var level: GameLevel = await _fresh_level(FOOD_COURT)
	var player := _park_player(level)
	var patch: MushroomPatch = level.get_node("Entities/EggPatch")
	var open := patch.global_position + Vector2(3 * TILE, 0)
	if not patch.can_sprout_at(open):
		open = patch.global_position + Vector2(-3 * TILE, 0)
	_check(patch.can_sprout_at(open), "a sprout can grow on open floor near its patch")
	player.global_position = open + Vector2(TILE, 0)
	_check(not patch.can_sprout_at(open), "but not within 2 tiles of Amanda")
	_park_player(level)
	_check(not patch.can_sprout_at(patch.global_position + Vector2(4, 0)), "nor on top of another patch")
	_check(not patch.can_sprout_at(level.start_point), "nor at the level's start")
	var stand: Checkpoint = level.get_node("Entities/CheckpointPlaza")
	_check(not patch.can_sprout_at(stand.global_position + Vector2(0, 20)), "nor by a checkpoint")
	_check(not patch.can_sprout_at(Vector2(-200, -200)), "nor off the floor")
	level.queue_free()

	level = await _fresh_level(GATES)
	patch = get_tree().get_nodes_in_group("mushroom_patches").filter(level.is_ancestor_of)[0]
	var belt := (level.get_node("WalkwayABEast") as Walkway).belt_rect()
	_check(not patch.can_sprout_at(belt.get_center()), "nor on a moving walkway")
	level.queue_free()


func _full_level_test() -> void:
	var level: GameLevel = await _fresh_level(FOOD_COURT)
	_park_player(level)
	_kill_chickens()
	# Spread over and over: the level never goes past its cap.
	for i in 30:
		for node in get_tree().get_nodes_in_group("mushroom_patches"):
			var patch := node as MushroomPatch
			if level.is_ancestor_of(patch):
				if patch.is_sprout:
					patch._sprout_timer = 0.0
				else:
					patch._spread_timer = 0.0
		await _frames(2)
	print("patches after 30 rounds of spreading: %d (cap %d)" % [level.patch_count(), level.mushroom_cap])
	_check(level.patch_count() == level.mushroom_cap, "spreading fills the level up to its cap")
	var stuck: Array[String] = level.things_in_walls()
	_check(stuck.is_empty(), "no sprout grows inside a wall %s" % [stuck])
	level.queue_free()


func _retry_test() -> void:
	SaveSystem.delete_game()
	var level: GameLevel = await _fresh_level(FOOD_COURT)
	_park_player(level)
	var patch: MushroomPatch = level.get_node("Entities/RagePatch")
	patch._spread_timer = 0.0
	await _frames(3)
	_check(level.patch_count() == 4, "a sprout joins the 3 placed patches")
	level.queue_free()
	GameManager.retry(FOOD_COURT_PATH)
	level = await _fresh_level(FOOD_COURT, false)
	_check(level.patch_count() == 3, "a retry puts the level back to its placed patches")
	level.queue_free()


## Moves Amanda out of the way, to the level's start.
func _park_player(level: GameLevel) -> Player:
	var player: Player = level.get_node("Entities/Player")
	player.global_position = level.start_point
	player._invincible_timer = 1.0e9
	return player


func _sprouts(level: Node) -> Array:
	return get_tree().get_nodes_in_group("mushroom_patches").filter(
		func(p: MushroomPatch) -> bool: return level.is_ancestor_of(p) and p.is_sprout)


func _kill_chickens() -> void:
	for chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.remove_from_group("chickens")
		chicken.queue_free()


## A new copy of a level. fresh=false keeps any pending snapshot.
func _fresh_level(scene: PackedScene, fresh := true) -> GameLevel:
	get_tree().paused = false
	if fresh:
		GameManager.pending = {}
	await get_tree().process_frame
	var level := scene.instantiate() as GameLevel
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Wait for the floor's navigation to be baked and synced.
	var nav_map := level.get_world_2d().navigation_map
	while NavigationServer2D.map_get_iteration_id(nav_map) == 0 \
			or not NavigationServer2D.map_get_closest_point_owner(nav_map, level.start_point).is_valid():
		await get_tree().physics_frame
	return level


func _check(condition: bool, description: String) -> void:
	print(("ok    " if condition else "FAIL  ") + description)
	if not condition:
		_failures.append(description)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

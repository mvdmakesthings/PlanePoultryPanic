extends Node
## Smoke test for the prototype room: drives the player with simulated
## input, checks that the basics work, and quits with a non-zero exit code
## on failure. Run from the repo root:
##   godot --path game res://tests/prototype_smoke.tscn
## Add --write-movie /tmp/frames.png --fixed-fps 30 to record frames.

const ROOM := preload("res://scenes/levels/prototype_room.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	var room := ROOM.instantiate()
	add_child(room)
	var player: Player = room.get_node("Entities/Player")
	await get_tree().physics_frame

	var start := player.global_position
	await _hold(["move_right"], 1.0)
	_check(player.global_position.x - start.x > 60.0, "player walks right")

	var stamina_before := player.stamina
	await _hold(["move_up", "run"], 0.8)
	_check(player.stamina < stamina_before, "running spends stamina")

	var snacks_before := player.snacks
	_tap("throw_snack")
	await _wait(0.6)
	_check(player.snacks == snacks_before - 1, "throwing uses a snack")
	_check(get_tree().get_nodes_in_group("snack_lures").size() == 1, "thrown snack lands as a lure")

	await _wait(2.5)
	var interested := 0
	for chicken: Chicken in get_tree().get_nodes_in_group("chickens"):
		if chicken.state in [Chicken.State.INVESTIGATE, Chicken.State.EATING]:
			interested += 1
	print("chickens investigating or eating the snack: %d" % interested)

	# Pause the chickens so the health checks are deterministic, then wait
	# out any invincibility from earlier pecks.
	for chicken: Chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.set_physics_process(false)
	await _wait(1.2)
	var health_before := player.health
	print("health before the damage check: %d/%d" % [health_before, player.max_health])
	player.take_damage(1, player.global_position + Vector2.LEFT)
	_check(player.health == maxi(health_before - 1, 0), "taking damage costs 1 health")

	if not player.is_dead:
		player.add_snack()
		var hurt_health := player.health
		_tap("eat_snack")
		await get_tree().physics_frame
		_check(player.health == hurt_health + 1, "eating a snack heals 1")

	# A snack thrown into the carousel must land outside it, or chickens
	# would push against the carousel forever trying to reach it.
	for lure in get_tree().get_nodes_in_group("snack_lures"):
		lure.queue_free()
	player.global_position = Vector2(140, 214)
	player.facing = Vector2.UP
	await get_tree().physics_frame
	player.add_snack()
	player.throw_snack()
	await _wait(0.6)
	var lures := get_tree().get_nodes_in_group("snack_lures")
	_check(lures.size() == 1, "snack thrown at the carousel lands")
	if lures.size() == 1:
		var landed: Vector2 = lures[0].global_position
		print("snack thrown at the carousel landed at %s" % landed)
		_check(landed.y >= 208.0, "snack thrown at the carousel stays outside it")

	# Pathfinding: a chicken north of the carousel must walk around it to
	# reach a snack directly south of it.
	for lure in get_tree().get_nodes_in_group("snack_lures"):
		lure.queue_free()
	var chickens := get_tree().get_nodes_in_group("chickens")
	for i in range(1, chickens.size()):
		chickens[i].queue_free()
	var runner: Chicken = chickens[0]
	runner.global_position = Vector2(112, 136)
	runner.state = Chicken.State.WANDER
	runner.set_physics_process(true)
	player.global_position = Vector2(440, 290)
	var bait: ThrownSnack = preload("res://scenes/objects/thrown_snack.tscn").instantiate()
	bait.direction = Vector2.ZERO
	bait.position = Vector2(112, 230)
	room.get_node("Entities").add_child(bait)
	await _wait(4.0)
	_check(runner.state == Chicken.State.EATING, "chicken paths around the carousel to a snack")

	room.queue_free()
	await _power_tests()

	if _failures.is_empty():
		print("SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


## Mushroom power-ups, each in a fresh room with a single chicken.
func _power_tests() -> void:
	# Eating a patch powers the chicken up in the patch's mode.
	var setup := await _fresh_room(Vector2(232, 120), Vector2(40, 296))
	var chicken: Chicken = setup[1]
	chicken.state = Chicken.State.WANDER
	await _wait(4.0)
	_check(chicken.power == "rage", "chicken eats a rage patch and powers up")
	setup[0].queue_free()

	# Rage chickens chase faster than the player walks.
	setup = await _fresh_room(Vector2(200, 260), Vector2(250, 260))
	chicken = setup[1]
	chicken.power_up("rage")
	await _wait(0.3)
	print("rage chase speed: %.0f" % chicken.velocity.length())
	_check(chicken.velocity.length() > 100.0, "rage chickens outpace a walking player")
	setup[0].queue_free()

	# Egg shooters hit the player from range.
	setup = await _fresh_room(Vector2(200, 260), Vector2(280, 260))
	chicken = setup[1]
	var player: Player = setup[2]
	chicken.power_up("egg")
	await _wait(2.5)
	print("egg shooter distance: %.0f, player health %d" % [
		chicken.global_position.distance_to(player.global_position), player.health])
	_check(player.health < player.max_health, "egg shooter hits the player from range")
	setup[0].queue_free()

	# Flight chickens hop over the carousel instead of walking around it.
	setup = await _fresh_room(Vector2(112, 136), Vector2(112, 236))
	chicken = setup[1]
	chicken.power_up("flight")
	await _wait(2.0)
	print("flight chicken ended at %s" % chicken.global_position)
	_check(chicken.global_position.y > 208.0 and chicken.global_position.x < 180.0,
		"flight chicken hops straight over the carousel")
	setup[0].queue_free()


## Returns [room, the one chicken left, player]. Patches other than the rage
## patch are removed, and the chicken is set chasing if it can see the player.
func _fresh_room(chicken_at: Vector2, player_at: Vector2) -> Array:
	# Let the previous room finish freeing, or new chickens would find its player.
	await get_tree().process_frame
	var room := ROOM.instantiate()
	add_child(room)
	await get_tree().physics_frame
	var player: Player = room.get_node("Entities/Player")
	player.global_position = player_at
	var chickens := get_tree().get_nodes_in_group("chickens").filter(
		func(c: Node) -> bool: return room.is_ancestor_of(c))
	for i in range(1, chickens.size()):
		chickens[i].queue_free()
	for patch in get_tree().get_nodes_in_group("mushroom_patches"):
		if room.is_ancestor_of(patch) and patch.variety != "rage":
			patch.queue_free()
	var chicken: Chicken = chickens[0]
	chicken.global_position = chicken_at
	chicken.state = Chicken.State.PURSUE
	await get_tree().physics_frame
	return [room, chicken, player]


func _check(condition: bool, label: String) -> void:
	print(("ok   " if condition else "FAIL ") + label)
	if not condition:
		_failures.append(label)


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


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout

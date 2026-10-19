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

	if _failures.is_empty():
		print("SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


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

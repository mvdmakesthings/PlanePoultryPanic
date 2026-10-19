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
	_tap("use_item")
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
	_check(player.health == maxi(health_before - 1, 0), "taking damage costs that much health")

	if not player.is_dead:
		player.add_snack()
		var hurt_health := player.health
		_tap("eat_snack")
		await get_tree().physics_frame
		_check(player.health == mini(hurt_health + Player.SUITCASE, player.max_health),
			"eating a snack heals a whole suitcase")

	# A snack thrown at the carousel must not land on the solid island, or
	# chickens would push against it forever trying to reach the snack.
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
		_check(landed.y >= 197.0, "snack thrown at the carousel stops short of the island")

	# Pathfinding: a chicken west of the carousel must route around the
	# solid island to reach a snack directly east of it.
	for lure in get_tree().get_nodes_in_group("snack_lures"):
		lure.queue_free()
	var chickens := get_tree().get_nodes_in_group("chickens")
	for i in range(1, chickens.size()):
		chickens[i].queue_free()
	var runner: Chicken = chickens[0]
	runner.global_position = Vector2(28, 176)
	runner.snack_notice_range = 200.0  # this test is about routing, not senses
	runner.state = Chicken.State.WANDER
	runner.set_physics_process(true)
	player.global_position = Vector2(440, 290)
	var bait: ThrownSnack = preload("res://scenes/objects/thrown_snack.tscn").instantiate()
	bait.direction = Vector2.ZERO
	bait.position = Vector2(196, 176)
	room.get_node("Entities").add_child(bait)
	await _wait(6.0)
	if is_instance_valid(runner):
		print("pathfinding chicken at %s, state %d" % [runner.global_position, runner.state])
	_check(is_instance_valid(runner) and not is_instance_valid(bait),
		"chicken paths around the carousel island and eats the snack")

	room.queue_free()
	await _power_tests()
	await _carousel_tests()
	await _cart_tests()
	await _cornered_cart_test()
	await _gate_test()
	await _extinguisher_tests()
	await _recoil_test()
	await _inventory_tests()

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
	_check(player.health >= player.max_health - 2, "an egg costs only a quarter suitcase")
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


## The carousel belt and its chute. The chute is on the back belt at x 114-126.
func _carousel_tests() -> void:
	# A chicken busy eating on the back belt rides it into the chute.
	var setup := await _fresh_room(Vector2(84, 151), Vector2(400, 290))
	var chicken: Chicken = setup[1]
	var defeated := [false]
	chicken.defeated.connect(func() -> void: defeated[0] = true)
	chicken.state = Chicken.State.EATING
	chicken._timer = 5.0
	await _wait(2.0)
	_check(defeated[0] and not is_instance_valid(chicken), "belt carries a chicken into the chute")
	setup[0].queue_free()

	# The player rides the belt but is stopped at the chute.
	setup = await _fresh_room(Vector2(400, 290), Vector2(96, 151))
	setup[1].queue_free()
	var player: Player = setup[2]
	await _wait(1.5)
	print("player on the belt ended at %s" % player.global_position)
	_check(player.global_position.x < 114.0 and player.global_position.x > 100.0,
		"belt carries the player but the chute stops them")
	setup[0].queue_free()

	# A snack lying on the belt rides into the chute and is gone.
	setup = await _fresh_room(Vector2(400, 290), Vector2(400, 260))
	setup[1].queue_free()
	var bait: ThrownSnack = preload("res://scenes/objects/thrown_snack.tscn").instantiate()
	bait.direction = Vector2.ZERO
	bait.position = Vector2(100, 151)
	setup[0].get_node("Entities").add_child(bait)
	await _wait(1.0)
	_check(not is_instance_valid(bait), "snack on the belt goes down the chute")
	setup[0].queue_free()

	# A snack on the front belt rides the whole loop (left, up, right) to the
	# chute instead of falling off at a corner.
	setup = await _fresh_room(Vector2(400, 290), Vector2(400, 260))
	setup[1].queue_free()
	bait = preload("res://scenes/objects/thrown_snack.tscn").instantiate()
	bait.direction = Vector2.ZERO
	bait.lifetime = 30.0
	bait.position = Vector2(150, 202)
	setup[0].get_node("Entities").add_child(bait)
	await _wait(7.0)
	if is_instance_valid(bait):
		print("looping snack stuck at %s" % bait.global_position)
	_check(not is_instance_valid(bait), "snack rides the full belt loop around the corners")
	setup[0].queue_free()


## Luggage carts: shove one with Interact and it flattens a chicken.
func _cart_tests() -> void:
	var setup := await _fresh_room(Vector2(230, 262), Vector2(150, 260))
	var chicken: Chicken = setup[1]
	var player: Player = setup[2]
	chicken.state = Chicken.State.EATING
	chicken._timer = 5.0
	var defeated := [false]
	chicken.defeated.connect(func() -> void: defeated[0] = true)
	var cart: LuggageCart = preload("res://scenes/objects/luggage_cart.tscn").instantiate()
	cart.position = Vector2(168, 262)
	setup[0].get_node("Entities").add_child(cart)
	await get_tree().physics_frame
	player.facing = Vector2.RIGHT
	_tap("interact")
	await _wait(1.0)
	print("cart rolled to %s" % cart.global_position)
	_check(cart.global_position.x > 200.0, "Interact shoves a nearby cart")
	_check(defeated[0], "a rolling cart defeats the chicken it hits")
	setup[0].queue_free()

	# Hiding: an egg shooter firing at a player crouched behind a cart hits
	# the cart instead. Shots come in at a slight angle, as in real play.
	setup = await _fresh_room(Vector2(214, 290), Vector2(200, 212))
	chicken = setup[1]
	player = setup[2]
	cart = preload("res://scenes/objects/luggage_cart.tscn").instantiate()
	cart.position = Vector2(203, 226)
	setup[0].get_node("Entities").add_child(cart)
	chicken.power_up("egg")
	# Pin the shooter in place, so it can't walk around the cart for a clear
	# shot; this test is about the cart blocking eggs.
	chicken.pursue_speed = 0.0
	await _wait(4.0)
	print("player behind the cart has %d/%d health" % [player.health, player.max_health])
	_check(player.health == player.max_health, "eggs splat on a cart the player hides behind")
	setup[0].queue_free()

	# Thrown snacks can be picked back up, but not the instant they land.
	setup = await _fresh_room(Vector2(400, 290), Vector2(200, 260))
	setup[1].queue_free()
	player = setup[2]
	var count := player.snacks
	player.facing = Vector2.RIGHT
	player.throw_snack()
	await _wait(0.6)
	_check(player.snacks == count - 1, "throwing a snack takes it out of the bag")
	var lure: ThrownSnack = get_tree().get_nodes_in_group("snack_lures")[0]
	player.global_position = lure.global_position
	await _wait(0.2)
	_check(player.snacks == count and not is_instance_valid(lure), "walking over a thrown snack picks it back up")
	setup[0].queue_free()


## A cart jammed into a corner slides out along the wall when shoved
## into it, instead of being stuck for good.
func _cornered_cart_test() -> void:
	var setup := await _fresh_room(Vector2(300, 120), Vector2(32, 290))
	setup[1].queue_free()
	var player: Player = setup[2]
	var cart: LuggageCart = preload("res://scenes/objects/luggage_cart.tscn").instantiate()
	cart.position = Vector2(29, 303)
	setup[0].get_node("Entities").add_child(cart)
	await get_tree().physics_frame
	var start := cart.global_position
	player.facing = Vector2.DOWN
	_tap("interact")
	await _wait(1.0)
	print("cornered cart moved from %s to %s" % [start, cart.global_position])
	_check(cart.global_position.distance_to(start) > 20.0, "a cart shoved into a corner slides out along the wall")
	setup[0].queue_free()


## Fire extinguisher: take it from the wall cabinet, freeze chickens, and
## kill mushroom patches.
func _extinguisher_tests() -> void:
	var setup := await _fresh_room(Vector2(192, 110), Vector2(192, 68))
	var room: Node = setup[0]
	var chicken: Chicken = setup[1]
	var player: Player = setup[2]
	var cabinet: ExtinguisherCabinet = room.get_node("ExtinguisherCabinet")
	_tap("interact")
	await get_tree().physics_frame
	_check(player.extinguisher_charges == 3 and cabinet.is_empty, "Interact takes the extinguisher from its cabinet")

	player.facing = Vector2.DOWN
	_tap("use_item")  # the extinguisher is selected once picked up
	await get_tree().physics_frame
	_check(chicken.state == Chicken.State.FROZEN, "spraying a chicken freezes it")
	_check(player.extinguisher_charges == 2, "each spray uses a charge")
	var health := player.health
	chicken.global_position = player.global_position
	await _wait(1.0)
	_check(player.health == health, "frozen chickens can't peck")
	chicken.global_position = Vector2(192, 110)
	await _wait(3.5)
	_check(chicken.state != Chicken.State.FROZEN, "frozen chickens thaw after a few seconds")
	room.queue_free()

	# Spraying a mushroom patch kills it for good.
	setup = await _fresh_room(Vector2(40, 290), Vector2(232, 72))
	room = setup[0]
	setup[1].queue_free()
	player = setup[2]
	player.give_extinguisher(1)
	var patch: MushroomPatch = room.get_node("Entities/RagePatch")
	player.facing = Vector2.DOWN
	player.spray()
	await _wait(0.8)
	_check(not is_instance_valid(patch), "spraying a mushroom patch destroys it")
	player.spray()
	_check(player.extinguisher_charges == 0, "an empty extinguisher does nothing")
	room.queue_free()

	# Point blank: chickens pecking at the player's feet or from the side
	# freeze too, whichever way the player faces.
	for offset: Vector2 in [Vector2.ZERO, Vector2(-8, 0), Vector2(0, 7), Vector2(9, -4)]:
		setup = await _fresh_room(Vector2(232, 200) + offset, Vector2(232, 200))
		chicken = setup[1]
		player = setup[2]
		player.give_extinguisher(1)
		player.facing = Vector2.UP
		player.spray()
		await get_tree().physics_frame
		_check(chicken.state == Chicken.State.FROZEN,
			"spraying freezes a chicken right next to the player (offset %s)" % offset)
		setup[0].queue_free()

	# Holding the extinguisher shows it in the player's hand.
	setup = await _fresh_room(Vector2(40, 290), Vector2(232, 200))
	setup[1].queue_free()
	player = setup[2]
	player.give_extinguisher(1)
	await get_tree().physics_frame
	_check(player._sprite.animation.contains("_ext"), "the player is drawn holding the extinguisher")
	player.spray()
	await get_tree().physics_frame
	_check(not player._sprite.animation.contains("_ext"), "an empty extinguisher is put away")
	setup[0].queue_free()

	# A frozen chicken is a block of ice the player can shove into others.
	setup = await _fresh_room(Vector2(200, 262), Vector2(186, 262))
	room = setup[0]
	var ice: Chicken = setup[1]
	player = setup[2]
	var victim: Chicken = preload("res://scenes/characters/chicken.tscn").instantiate()
	victim.position = Vector2(290, 262)
	room.get_node("Entities").add_child(victim)
	await get_tree().physics_frame
	victim.state = Chicken.State.EATING
	victim._timer = 5.0
	var flattened := [false]
	victim.defeated.connect(func() -> void: flattened[0] = true)
	ice.freeze(4.0)
	player.facing = Vector2.RIGHT
	_tap("interact")
	await _wait(1.5)
	_check(flattened[0], "a shoved frozen chicken flattens the chicken it slides into")
	_check(is_instance_valid(ice) and ice.state == Chicken.State.FROZEN, "the shoved ice block survives")
	room.queue_free()

	# A frozen chicken on the belt rides into the chute.
	setup = await _fresh_room(Vector2(84, 151), Vector2(400, 290))
	chicken = setup[1]
	var defeated := [false]
	chicken.defeated.connect(func() -> void: defeated[0] = true)
	chicken.freeze(4.0)
	await _wait(2.0)
	_check(defeated[0], "a frozen chicken on the belt rides into the chute")
	setup[0].queue_free()


## A chicken that lands a peck bounces back and is dazed for a moment.
func _recoil_test() -> void:
	var setup := await _fresh_room(Vector2(244, 200), Vector2(232, 200))
	var chicken: Chicken = setup[1]
	var player: Player = setup[2]
	await _wait(0.5)
	var distance := chicken.global_position.distance_to(player.global_position)
	print("chicken bounced back to %.0f px after pecking" % distance)
	_check(player.health == player.max_health - Player.SUITCASE, "the chicken lands one peck")
	_check(distance >= 24.0, "a chicken bounces back after pecking")
	await _wait(0.8)
	_check(chicken.state == Chicken.State.PURSUE, "a dazed chicken resumes the chase")
	setup[0].queue_free()


## The six-slot inventory: stacking, cycling, dropping, and full bags.
func _inventory_tests() -> void:
	var setup := await _fresh_room(Vector2(40, 290), Vector2(232, 220))
	var room: Node = setup[0]
	setup[1].queue_free()
	var player: Player = setup[2]
	var inventory := player.inventory
	_check(inventory.slots[0] == {"item": "snack", "count": 2}, "the player starts with 2 snacks in the first slot")

	player.pick_up("snack", 5)
	_check(inventory.slots[0]["count"] == 3 and inventory.slots[1]["count"] == 3 and inventory.slots[2]["count"] == 1,
		"snacks stack 3 per slot")

	_tap("next_item")
	await get_tree().physics_frame
	_check(inventory.selected == 1, "R selects the next slot")
	_tap("prev_item")
	_tap("prev_item")
	await get_tree().physics_frame
	_check(inventory.selected == Inventory.SLOT_COUNT - 1, "Q selects the previous slot, wrapping around")

	# Drop the third slot's snack, then step away and back to pick it up.
	inventory.selected = 2
	player.facing = Vector2.RIGHT
	_tap("drop_item")
	await get_tree().physics_frame
	var drops := room.get_node("Entities").get_children().filter(func(n: Node) -> bool: return n is ItemPickup and n.dropped)
	_check(drops.size() == 1 and player.snacks == 6, "G drops the selected slot on the floor")
	await _wait(0.3)
	_check(player.snacks == 6, "a dropped item isn't picked straight back up")
	player.global_position += Vector2(-40, 0)
	await _wait(0.2)
	player.global_position = drops[0].global_position
	await _wait(0.2)
	_check(player.snacks == 7, "a dropped item can be picked up again after stepping away")

	# Fill every slot: no more snacks fit, and the cabinet can't be used.
	player.pick_up("snack", 18)
	_check(not player.add_snack(), "a full inventory refuses more snacks")
	player.global_position = room.get_node("ExtinguisherCabinet").base_point() + Vector2(0, 4)
	await get_tree().physics_frame
	_check(not room.get_node("ExtinguisherCabinet").can_interact(player), "a full inventory can't take an extinguisher")
	room.queue_free()


## Walking up through the gate's open doors wins the round.
func _gate_test() -> void:
	# Park the spare chicken well away from the player's start, so its
	# hitbox can't overlap the player for a frame before it's removed.
	var setup := await _fresh_room(Vector2(200, 120), Vector2(424, 96))
	setup[1].queue_free()
	var room: Node = setup[0]
	await _hold(["move_up"], 1.0)
	_check(room._round_over, "walking into the gate doorway wins")
	room.queue_free()


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

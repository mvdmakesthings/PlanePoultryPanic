extends Node
## Stages a lively moment in a level for a store-page screenshot, saves the
## screen as a 1280x720 PNG (the 320x180 game scaled 4x), then quits:
##   godot --path game res://tests/store_shots.tscn -- --shot=3 --out=/tmp/shot.png
## tools/store_shots.sh runs all five and saves them to docs/images/.

const CHICKEN := preload("res://scenes/characters/chicken.tscn")
const TOTEM := preload("res://scenes/characters/totem.tscn")

var _level: Node
var _player: Player


func _ready() -> void:
	SaveSystem.save_path = "user://shots_save.json"
	SaveSystem.settings_path = "user://shots_settings.cfg"
	GameManager.dry_run = true
	GameManager.pending = {}
	var shot := "1"
	var out := "user://store_shot.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			shot = arg.trim_prefix("--shot=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	match shot:
		"1":
			await _arrivals_carousel()
		"2":
			await _security_spray()
		"3":
			await _food_court_totem()
		"4":
			await _gates_chase()
		"5":
			await _final_boss()
		"personality":
			await _food_court_personality()
		"sprint":
			await _arrivals_sprint()
	_hide_hints()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	image.save_png(out)
	# Unload the level before quitting, so nothing is left alive at exit.
	_level.queue_free()
	await get_tree().process_frame
	await AudioManager.silence()
	get_tree().quit()


## Store screenshots show the action, not the tutorial: clear any hint or
## PA banner (the normal HUD stays).
func _hide_hints() -> void:
	for hud in _level.find_children("*", "Hud", true, false):
		hud.show_hint("")
		hud.show_pa("")


func _open(path: String) -> void:
	_level = load(path).instantiate()
	add_child(_level)
	await get_tree().physics_frame
	_player = _level.get_node("Entities/Player")


func _chicken(at: Vector2, power := "", state := Chicken.State.PURSUE) -> Chicken:
	var chicken := CHICKEN.instantiate() as Chicken
	chicken.position = at
	_level.get_node("Entities").add_child(chicken)
	if power != "":
		chicken.power_up(power)
	chicken.state = state
	return chicken


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Level 1: a chicken rides the baggage carousel while two chase Amanda.
func _arrivals_carousel() -> void:
	await _open("res://scenes/levels/level_01_arrivals.tscn")
	var belt := get_tree().get_first_node_in_group("conveyors") as Carousel
	_player.global_position = Vector2(belt.outer.get_center().x + 24, belt.outer.end.y + 26)
	var rider := _chicken(Vector2(belt.outer.get_center().x - 14, belt.outer.end.y - 5), "", Chicken.State.EATING)
	rider._timer = 10.0
	_chicken(_player.global_position + Vector2(-96, 10))
	_chicken(_player.global_position + Vector2(104, -2))
	_player.facing = Vector2.LEFT
	await _wait(0.6)
	_player.throw_snack()
	await _wait(0.25)


## Level 2: powered chickens at a mushroom patch, frozen mid-charge.
func _security_spray() -> void:
	await _open("res://scenes/levels/level_02_security.tscn")
	var patch := get_tree().get_first_node_in_group("mushroom_patches") as Node2D
	_player.global_position = patch.global_position + Vector2(-46, 18)
	_player.give_extinguisher(3)
	_chicken(patch.global_position + Vector2(-14, 10), "rage")
	_chicken(patch.global_position + Vector2(22, -12), "flight")
	_chicken(patch.global_position + Vector2(18, 22), "egg")
	await _wait(0.8)
	_player.spray()
	await _wait(0.2)


## Level 3: a totem at the food court roost fires an egg barrage.
func _food_court_totem() -> void:
	await _open("res://scenes/levels/level_03_food_court.tscn")
	var roost := get_tree().get_first_node_in_group("roosts") as Node2D
	var totem := TOTEM.instantiate() as Totem
	totem.position = roost.position
	_level.get_node("Entities").add_child(totem)
	totem.speed = 0.0
	totem._barrage_ready_in = 0.6
	_player.global_position = roost.global_position + Vector2(104, 14)
	_chicken(roost.global_position + Vector2(-30, 26))
	await _wait(0.85)


## Level 3, for the v0.3.0 devlog: two chickens squabble over a snack, one
## lies where it tripped, a rage chicken throws a tantrum, and Amanda laughs.
func _food_court_personality() -> void:
	await _open("res://scenes/levels/level_03_food_court.tscn")
	var at := _player.global_position + Vector2(0, -40)
	_player.global_position = at
	_player.facing = Vector2.LEFT
	var snack := preload("res://scenes/objects/thrown_snack.tscn").instantiate() as ThrownSnack
	snack.direction = Vector2.ZERO
	snack.position = at + Vector2(-64, -4)
	_level.get_node("Entities").add_child(snack)
	var leader := _chicken(snack.position + Vector2(-9, 0), "", Chicken.State.WANDER)
	var rival := _chicken(snack.position + Vector2(9, 2), "", Chicken.State.WANDER)
	var tripped := _chicken(at + Vector2(-26, 10), "", Chicken.State.WANDER)
	var tantrum := _chicken(at + Vector2(58, -14), "rage", Chicken.State.WANDER)
	await get_tree().physics_frame
	for chicken in [leader, rival]:
		chicken._target_snack = snack
	leader._squabble_rivals = [rival]
	leader._enter_squabble(true, 30.0)
	rival._enter_squabble(false, 30.0)
	tripped.state = Chicken.State.RECOIL
	tripped._tripped = true
	tripped._timer = 30.0
	tripped._facing = Vector2.LEFT
	tantrum.state = Chicken.State.TANTRUM
	tantrum._timer = 30.0
	await _wait(0.5)
	_player.say("Ha!")
	await _wait(0.2)
	# A cover image, not a screenshot: no HUD.
	for hud in _level.find_children("*", "Hud", true, false):
		hud.visible = false


## Level 1, for the v0.4.0 devlog: Amanda sprints across the Arrivals floor
## with chickens on her heels, showing off her new sprites.
func _arrivals_sprint() -> void:
	await _open("res://scenes/levels/level_01_arrivals.tscn")
	var belt := get_tree().get_first_node_in_group("conveyors") as Carousel
	var at := Vector2(belt.outer.get_center().x + 40, belt.outer.end.y + 30)
	_player.global_position = at
	_player.facing = Vector2.RIGHT
	# Hold her mid-stride: the physics step would switch her back to idle.
	_player.set_physics_process(false)
	_player._sprite.animation = "run_right"
	_player._sprite.frame = 1
	_player._sprite.stop()
	_chicken(at + Vector2(-84, 8))
	_chicken(at + Vector2(-112, -14), "rage")
	_chicken(at + Vector2(-100, 26))
	await _wait(0.6)
	# A cover image, not a screenshot: no HUD.
	for hud in _level.find_children("*", "Hud", true, false):
		hud.visible = false


## Level 4: a chase along the gate area's moving walkway.
func _gates_chase() -> void:
	await _open("res://scenes/levels/level_04_gates.tscn")
	var walkway := get_tree().get_first_node_in_group("walkways") as Node2D
	_player.global_position = walkway.global_position + Vector2(40, 6)
	_chicken(_player.global_position + Vector2(-80, -6), "rage")
	_chicken(_player.global_position + Vector2(-110, 10))
	_chicken(_player.global_position + Vector2(-70, 24), "egg")
	_player.facing = Vector2.RIGHT
	await _wait(0.8)


## Level 5: the Supreme Totem stands up in the boarding area.
func _final_boss() -> void:
	await _open("res://scenes/levels/level_05_final_gate.tscn")
	var roost := _level.get_node("BossRoost") as Node2D
	_player.global_position = roost.global_position + Vector2(76, 18)
	for i in 900:
		await get_tree().physics_frame
		if _level.boss != null:
			break
	await _wait(1.5)

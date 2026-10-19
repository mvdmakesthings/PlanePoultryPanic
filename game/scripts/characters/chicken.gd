class_name Chicken
extends CharacterBody2D
## A chicken: wanders and pecks until it spots the player, then chases and
## alerts nearby chickens. Thrown snacks beat everything else: a chicken
## drops what it's doing to go eat one. Chickens also seek out mushroom
## patches, and eating one powers them up for a while:
##   flight: hops over furniture and walls of chickens while chasing
##   rage:   chases faster than the player walks, sees further, gives up later
##   egg:    stops at range and fires eggs at the player

## Emitted just before a defeated chicken is removed.
signal defeated

enum State { WANDER, PURSUE, INVESTIGATE, EATING, SEEK_MUSHROOM, FEEDING, WINDUP, FROZEN, RECOIL, BESIEGE, SEEK_ROOST, ROOSTING }

const WALK_SHEET := preload("res://assets/sprites/chicken_walk.png")
const IDLE_SHEET := preload("res://assets/sprites/chicken_idle.png")
const POWER_SHEETS := {
	"flight": preload("res://assets/sprites/chicken_flight_walk.png"),
	"rage": preload("res://assets/sprites/chicken_rage_walk.png"),
	"egg": preload("res://assets/sprites/chicken_egg_walk.png"),
}
const EGG_SCENE := preload("res://scenes/objects/egg_projectile.tscn")
const POOF_SCENE := preload("res://scenes/objects/feather_poof.tscn")
## Frozen chickens are tinted icy and boxed in an ice block.
const FROZEN_TINT := Color(0.7, 0.95, 1.0)
const FRAME_SIZE := Vector2i(16, 16)
const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)
const WORLD_LAYER := 1
const CHICKEN_LAYER := 4
## Seconds before a power wears off when the chicken starts flickering.
const POWER_WARNING_TIME := 3.0

@export_group("Normal")
@export var wander_speed := 30.0
## Slower than the player's walk, so one normal chicken can always be escaped.
@export var pursue_speed := 60.0
@export var investigate_speed := 70.0
@export var sight_range := 64.0
## Seconds without seeing the player before giving up the chase.
@export var give_up_time := 2.0
@export var alert_radius := 48.0
@export var snack_notice_range := 100.0
@export var eat_time := 2.5
## After a peck lands, the chicken bounces back about two tiles and stays
## dazed briefly, giving the player a chance to run.
@export var recoil_speed := 180.0
@export var recoil_friction := 500.0
@export var daze_time := 0.8
## Seconds a chicken pecks at a closet door before giving up on the hidden
## player and walking off, so hiding is a real way to shake chickens.
@export var siege_patience := 5.0
## Longest a chicken that gave up spends walking briskly away from the door.
@export var retreat_time := 3.0
## How far from the door it heads when it gives up (beyond sight range).
@export var retreat_distance := 140.0
## After giving up, it ignores the player this long beyond the retreat, so a
## player stepping out of hiding has time to slip away.
@export var lost_interest_time := 3.0

@export_group("Mushrooms")
@export var mushroom_notice_range := 112.0
@export var feed_time := 1.5
@export var power_duration_min := 30.0
@export var power_duration_max := 60.0

@export_group("Rage")
## Faster than the player's walk (100), slower than their run (150).
@export var rage_speed := 105.0
@export var rage_sight_bonus := 32.0
@export var rage_give_up_time := 4.0

@export_group("Flight")
@export var hop_speed := 95.0
@export var hop_duration := 0.7
@export var hop_cooldown := 1.6
@export var hop_height := 10.0

@export_group("Frozen")
## A frozen chicken is a block of ice the player can shove. Ice slides
## further than a cart, and flattens any chicken it crashes into.
@export var ice_shove_speed := 200.0
@export var ice_friction := 160.0
@export var ice_lethal_speed := 60.0
@export var ice_shove_reach := 18.0

@export_group("Egg Shooter")
@export var egg_range := 112.0
@export var egg_windup := 0.5
@export var egg_cooldown := 1.8
## Egg shooters hang back at about this distance instead of closing in.
@export var egg_keep_distance := 72.0

var state := State.WANDER
## Active power ("flight", "rage", "egg"), or "" when normal.
var power := ""

var _player: Player
var _target_snack: ThrownSnack
var _target_patch: MushroomPatch
var _wander_dir := Vector2.ZERO
var _timer := 0.0
var _lost_sight_time := 0.0
var _facing := Vector2.DOWN
var _power_timer := 0.0
var _hop_time := 0.0
var _hop_elapsed := 0.0
var _hop_dir := Vector2.ZERO
var _hop_start := Vector2.ZERO
var _hop_ready_in := 0.0
var _egg_ready_in := 0.0
var _slide_velocity := Vector2.ZERO
var _recoil_velocity := Vector2.ZERO
var _siege_spot: HidingSpot = null
var _siege_offset := 0.0
var _siege_time := 0.0
var _retreat_left := 0.0
var _retreat_target := Vector2.ZERO
var _uninterested_left := 0.0
var _roost: Roost = null
var _roost_index := 0
var _show_prompt := false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _hitbox: Area2D = $Hitbox
@onready var _alert_label: Label = $AlertLabel
@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _ice: Sprite2D = $Ice


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	add_to_group("interactables")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpriteSheets.add_directional(frames, "walk", WALK_SHEET, FRAME_SIZE, 8.0)
	SpriteSheets.add_directional(frames, "idle", IDLE_SHEET, FRAME_SIZE, 3.0)
	for mode: String in POWER_SHEETS:
		SpriteSheets.add_directional(frames, mode + "_walk", POWER_SHEETS[mode], FRAME_SIZE, 8.0)
	_sprite.sprite_frames = frames
	# Desync chickens so they don't all peck in unison.
	_sprite.play("idle_down")
	_sprite.frame = randi() % 3
	_pick_wander()


func _physics_process(delta: float) -> void:
	_timer -= delta
	_retreat_left -= delta
	_uninterested_left -= delta
	_egg_ready_in -= delta
	_hop_ready_in -= delta
	_update_power(delta)

	if _is_hopping():
		_update_hop(delta)
	else:
		match state:
			State.WANDER:
				_wander()
			State.PURSUE:
				_pursue(delta)
			State.INVESTIGATE:
				_investigate()
			State.EATING, State.FEEDING:
				_eat()
			State.SEEK_MUSHROOM:
				_seek_mushroom()
			State.WINDUP:
				_windup()
			State.FROZEN:
				_frozen()
			State.RECOIL:
				_recoil()
			State.BESIEGE:
				_besiege()
			State.SEEK_ROOST, State.ROOSTING:
				_roosting()
		velocity += Carousel.push_for(get_tree(), global_position)
		# Chickens heading into a roost pass through each other: they're
		# about to stack up anyway, and the nest is too small otherwise.
		# (A hop that just started this frame manages its own collisions.)
		if not _is_hopping():
			var roosting := state in [State.SEEK_ROOST, State.ROOSTING]
			collision_mask = WORLD_LAYER if roosting else WORLD_LAYER | CHICKEN_LAYER
	move_and_slide()
	if not _is_hopping() and Carousel.in_any_chute(get_tree(), global_position):
		defeat()
		return
	if state == State.FROZEN:
		_check_ice_hits()
	if state == State.WANDER and _retreat_left <= 0.0 and get_slide_collision_count() > 0:
		_pick_wander()
	if velocity.length() > 1.0:
		_facing = velocity.normalized()
	_check_hit()
	_update_visuals()


## Called by a nearby chicken that spotted the player.
func alert() -> void:
	if state in [State.WANDER, State.SEEK_MUSHROOM]:
		_start_pursuit(false)


## Knocked silly (for example, tumbling off a toppled totem): no moving or
## pecking for a moment, then back to the chase.
func stun(seconds: float) -> void:
	state = State.RECOIL
	_timer = seconds
	_recoil_velocity = Vector2.ZERO


## True while settled in a roost's nest, ready to stack into a totem.
func is_roosting_at(roost: Roost) -> bool:
	return state == State.ROOSTING and _roost == roost \
		and global_position.distance_to(roost.spot_for(_roost_index)) < 5.0


## The player hid in a closet. A chicken that was chasing them saw it, and
## goes to wait outside the door and peck at it.
func besiege(spot: HidingSpot) -> void:
	if state not in [State.PURSUE, State.WINDUP]:
		return
	state = State.BESIEGE
	_siege_spot = spot
	_siege_offset = randf_range(-8.0, 8.0)
	_siege_time = 0.0


## True while standing at that closet's door, pecking at it.
func is_pecking_door(spot: HidingSpot) -> bool:
	return state == State.BESIEGE and _siege_spot == spot \
		and global_position.distance_to(_siege_target()) < 6.0


## Freezes the chicken solid. Frozen chickens can't move or peck, but the
## carousel belt still carries them and carts still flatten them. Chickens
## in mid-hop are out of reach.
func freeze(seconds: float) -> void:
	if _is_hopping():
		return
	state = State.FROZEN
	_timer = seconds
	velocity = Vector2.ZERO
	_slide_velocity = Vector2.ZERO


## Frozen chickens can be shoved like a cart.
func can_interact(player: Player) -> bool:
	return state == State.FROZEN and _slide_velocity == Vector2.ZERO \
		and global_position.distance_to(player.global_position) <= ice_shove_reach


func interact(player: Player) -> void:
	_slide_velocity = Shove.direction_for(self, player) * ice_shove_speed


## Bursts into feathers and leaves the game.
func defeat() -> void:
	var poof := POOF_SCENE.instantiate() as Node2D
	poof.position = position
	get_parent().add_child(poof)
	defeated.emit()
	queue_free()


## Powers the chicken up immediately. Also used by tests and debugging.
func power_up(mode: String) -> void:
	power = mode
	_power_timer = randf_range(power_duration_min, power_duration_max)


# ---------- states ----------

func _wander() -> void:
	if _timer <= 0.0:
		_pick_wander()
	if _retreat_left > 0.0:
		# Walking off after giving up at a closet door, around anything in the way.
		if global_position.distance_to(_retreat_target) < 6.0:
			_retreat_left = 0.0
		else:
			velocity = _direction_toward(_retreat_target) * pursue_speed
			return
	velocity = _wander_dir * wander_speed * (1.5 if power == "rage" else 1.0)
	if _try_investigate():
		return
	if _can_see_player():
		_start_pursuit(true)
		return
	_try_seek_mushroom()
	if state == State.WANDER:
		_try_seek_roost()


func _pursue(delta: float) -> void:
	if _try_investigate():
		return
	if _can_see_player():
		_lost_sight_time = 0.0
	else:
		_lost_sight_time += delta
		var patience := rage_give_up_time if power == "rage" else give_up_time
		if _lost_sight_time >= patience or _player.is_dead:
			state = State.WANDER
			_pick_wander()
			return

	var distance := global_position.distance_to(_player.global_position)
	match power:
		"rage":
			velocity = _direction_toward(_player.global_position) * rage_speed
		"flight":
			velocity = _direction_toward(_player.global_position) * pursue_speed
			if _hop_ready_in <= 0.0 and distance > 24.0:
				_start_hop()
		"egg":
			if distance < egg_range and _egg_ready_in <= 0.0 and _can_see_player():
				state = State.WINDUP
				_timer = egg_windup
				velocity = Vector2.ZERO
				return
			# Hang back at range rather than walking into the player.
			var away := 1.0 if distance > egg_keep_distance else -0.6
			velocity = _direction_toward(_player.global_position) * pursue_speed * away
		_:
			velocity = _direction_toward(_player.global_position) * pursue_speed


func _investigate() -> void:
	if not is_instance_valid(_target_snack):
		state = State.WANDER
		_pick_wander()
		return
	if global_position.distance_to(_target_snack.global_position) < 4.0:
		velocity = Vector2.ZERO
		if _target_snack.consume():
			state = State.EATING
			_timer = eat_time
		else:
			state = State.WANDER
		return
	velocity = _direction_toward(_target_snack.global_position) * investigate_speed


func _eat() -> void:
	velocity = Vector2.ZERO
	if _timer > 0.0:
		return
	if state == State.FEEDING and is_instance_valid(_target_patch):
		power_up(_target_patch.variety)
	state = State.WANDER
	_pick_wander()


func _seek_mushroom() -> void:
	if not is_instance_valid(_target_patch) or not _target_patch.is_ripe:
		state = State.WANDER
		_pick_wander()
		return
	if _try_investigate():
		return
	if _can_see_player():
		_start_pursuit(true)
		return
	if global_position.distance_to(_target_patch.global_position) < 6.0:
		velocity = Vector2.ZERO
		if _target_patch.eat():
			state = State.FEEDING
			_timer = feed_time
		else:
			state = State.WANDER
		return
	velocity = _direction_toward(_target_patch.global_position) * investigate_speed


func _frozen() -> void:
	_slide_velocity = _slide_velocity.move_toward(Vector2.ZERO, ice_friction * get_physics_process_delta_time())
	velocity = _slide_velocity
	if _timer <= 0.0:
		_slide_velocity = Vector2.ZERO
		state = State.WANDER
		_pick_wander()


## While sliding as ice: flatten chickens in the way, and stop at walls.
func _check_ice_hits() -> void:
	if _slide_velocity == Vector2.ZERO:
		return
	var lethal := _slide_velocity.length() >= ice_lethal_speed
	for i in get_slide_collision_count():
		var other := get_slide_collision(i).get_collider()
		if other is Chicken:
			if lethal:
				(other as Chicken).defeat()
		else:
			_slide_velocity = Vector2.ZERO
			return


func _try_seek_roost() -> void:
	for node in get_tree().get_nodes_in_group("roosts"):
		var roost := node as Roost
		if roost.is_open() and global_position.distance_to(roost.global_position) < roost.call_radius:
			_roost = roost
			_roost_index = roost.claim_spot()
			state = State.SEEK_ROOST
			return


## Heading to a roost, then settled in it. A snack still draws a chicken
## away (breaking up a forming totem); once settled it ignores the player.
func _roosting() -> void:
	if not is_instance_valid(_roost) or not _roost.is_open():
		state = State.WANDER
		_pick_wander()
		return
	if _try_investigate():
		return
	if state == State.SEEK_ROOST and _can_see_player():
		_start_pursuit(true)
		return
	var spot := _roost.spot_for(_roost_index)
	if global_position.distance_to(spot) < 3.0:
		state = State.ROOSTING
		velocity = Vector2.ZERO
		_facing = Vector2.DOWN
		return
	velocity = _direction_toward(spot) * investigate_speed


func _besiege() -> void:
	if not is_instance_valid(_siege_spot) or not _siege_spot.is_occupied():
		# The player came out (or was thrown out): back to the chase.
		_start_pursuit(false)
		return
	var target := _siege_target()
	if global_position.distance_to(target) < 4.0:
		velocity = Vector2.ZERO
		_facing = Vector2.UP
		_siege_time += get_physics_process_delta_time()
		if _siege_time >= siege_patience:
			_give_up_siege()
		return
	velocity = _direction_toward(target) * pursue_speed


## Lose interest in the closet and walk away from it, out of sight range,
## so the player can come out safely.
func _give_up_siege() -> void:
	state = State.WANDER
	_wander_dir = Vector2.ZERO
	_timer = retreat_time
	_retreat_left = retreat_time
	_uninterested_left = retreat_time + lost_interest_time
	# Head well away from the door along a clear straight line: no walls,
	# furniture, or carousel belt anywhere on the way. Prefer heading into
	# the room, then along the wall either side.
	var door := _siege_spot.base_point()
	var offset := randf_range(-15.0, 15.0)
	_retreat_target = door
	for angle: float in [90.0, 60.0, 120.0, 30.0, 150.0, 10.0, 170.0]:
		for distance: float in [retreat_distance, retreat_distance * 0.75]:
			var spot := door + Vector2.from_angle(deg_to_rad(angle + offset)) * distance
			if distance > sight_range and _clear_walk(door, spot):
				_retreat_target = spot
				_retreat_left = distance / pursue_speed + 0.5
				_uninterested_left = _retreat_left + lost_interest_time
				return


## True if a chicken could walk straight from a to b: on walkable floor the
## whole way, with no carousel belt to get carried off by.
func _clear_walk(a: Vector2, b: Vector2) -> bool:
	var map := get_world_2d().navigation_map
	var steps := int(a.distance_to(b) / 6.0)
	for i in range(1, steps + 1):
		var p := a.lerp(b, float(i) / steps)
		if NavigationServer2D.map_get_closest_point(map, p).distance_to(p) > 1.0:
			return false
		if Carousel.push_for(get_tree(), p) != Vector2.ZERO:
			return false
	return true


func _siege_target() -> Vector2:
	return _siege_spot.base_point() + Vector2(_siege_offset, 2.0)


func _recoil() -> void:
	_recoil_velocity = _recoil_velocity.move_toward(Vector2.ZERO, recoil_friction * get_physics_process_delta_time())
	velocity = _recoil_velocity
	if _timer <= 0.0:
		_recoil_velocity = Vector2.ZERO
		_start_pursuit(false)


func _windup() -> void:
	velocity = Vector2.ZERO
	_facing = global_position.direction_to(_player.global_position)
	if _timer > 0.0:
		return
	var egg := EGG_SCENE.instantiate() as EggProjectile
	egg.direction = global_position.direction_to(_player.global_position)
	egg.position = position + egg.direction * 6.0
	get_parent().add_child(egg)
	_egg_ready_in = egg_cooldown
	state = State.PURSUE


# ---------- powers ----------

func _update_power(delta: float) -> void:
	if power == "":
		return
	_power_timer -= delta
	if _power_timer <= 0.0 and not _is_hopping():
		power = ""


func _is_hopping() -> bool:
	return _hop_time > 0.0


func _start_hop() -> void:
	_hop_time = hop_duration
	_hop_elapsed = 0.0
	_hop_dir = global_position.direction_to(_player.global_position)
	_hop_start = global_position
	# Airborne: ignore furniture and other chickens until landing. The
	# landing check in _update_hop keeps it from touching down inside anything.
	collision_mask = 0


func _update_hop(delta: float) -> void:
	_hop_time -= delta
	_hop_elapsed += delta
	velocity = _hop_dir * hop_speed
	if _hop_time > 0.0:
		return
	if _overlaps_world():
		# Can't land inside furniture: keep flying, and turn back toward the
		# take-off point if the far side is taking too long to reach.
		_hop_time = 0.05
		if _hop_elapsed > hop_duration * 2.5:
			_hop_dir = global_position.direction_to(_hop_start)
		return
	_hop_time = 0.0
	_hop_ready_in = hop_cooldown
	collision_mask = WORLD_LAYER | CHICKEN_LAYER
	_sprite.position.y = 0.0


func _overlaps_world() -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = _body_shape.shape
	params.transform = _body_shape.global_transform
	params.collision_mask = WORLD_LAYER
	return not get_world_2d().direct_space_state.intersect_shape(params, 1).is_empty()


# ---------- senses and helpers ----------

## Next step along the navigation path, so chickens route around furniture.
## Falls back to a straight line before the navigation map is ready.
func _direction_toward(target: Vector2) -> Vector2:
	_agent.target_position = target
	var next := _agent.get_next_path_position()
	if next.distance_to(global_position) < 0.5:
		return global_position.direction_to(target)
	return global_position.direction_to(next)


func _pick_wander() -> void:
	# Half the time stand and peck; otherwise stroll somewhere.
	if randf() < 0.5:
		_wander_dir = Vector2.ZERO
	else:
		_wander_dir = Vector2.from_angle(randf() * TAU)
	_timer = randf_range(1.0, 2.5)


func _try_investigate() -> bool:
	var nearest: ThrownSnack = null
	var best := snack_notice_range
	for node in get_tree().get_nodes_in_group("snack_lures"):
		var snack := node as ThrownSnack
		var distance := global_position.distance_to(snack.global_position)
		if distance < best:
			best = distance
			nearest = snack
	if nearest == null:
		return false
	_target_snack = nearest
	state = State.INVESTIGATE
	return true


func _try_seek_mushroom() -> void:
	if power != "":
		return
	var best := mushroom_notice_range
	for node in get_tree().get_nodes_in_group("mushroom_patches"):
		var patch := node as MushroomPatch
		var distance := global_position.distance_to(patch.global_position)
		if patch.is_ripe and distance < best:
			best = distance
			_target_patch = patch
			state = State.SEEK_MUSHROOM


func _can_see_player() -> bool:
	if _player == null or _player.is_dead or _player.is_hidden or _uninterested_left > 0.0:
		return false
	var reach := sight_range
	if power == "rage":
		reach += rage_sight_bonus
	elif power == "egg":
		# Egg shooters need to see as far as they can shoot.
		reach = maxf(sight_range, egg_range)
	if global_position.distance_to(_player.global_position) > reach:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position, WORLD_LAYER)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _start_pursuit(alert_others: bool) -> void:
	state = State.PURSUE
	_lost_sight_time = 0.0
	if not alert_others:
		return
	for node in get_tree().get_nodes_in_group("chickens"):
		var other := node as Chicken
		if other != self and global_position.distance_to(other.global_position) < alert_radius:
			other.alert()


func _check_hit() -> void:
	if state in [State.EATING, State.FEEDING, State.FROZEN, State.RECOIL] or _is_hopping():
		return
	for body in _hitbox.get_overlapping_bodies():
		if body is Player and (body as Player).take_damage(Player.SUITCASE, global_position):
			# Bounce back off the player and stay dazed for a moment.
			state = State.RECOIL
			_timer = daze_time
			_recoil_velocity = body.global_position.direction_to(global_position) * recoil_speed
			return


func _update_visuals() -> void:
	var direction := SpriteSheets.direction_name(_facing)
	var moving := velocity.length() > 1.0
	# Flicker back to normal just before a power wears off, as a warning.
	var show_power := power != "" and (
		_power_timer > POWER_WARNING_TIME or int(_power_timer * 4.0) % 2 == 0)
	var animation: String
	if show_power:
		animation = power + "_walk_" + direction
	else:
		animation = ("walk_" if moving else "idle_") + direction
	if _sprite.animation != animation:
		_sprite.play(animation)
	if show_power and not moving:
		# Powered sheets only have walk cycles; stand on the passing frame.
		_sprite.pause()
		_sprite.frame = 1
	elif not _sprite.is_playing():
		_sprite.play(animation)

	_sprite.speed_scale = 1.5 if state == State.PURSUE else 1.0
	if state == State.WINDUP:
		# Squash during the wind-up so the shot can be dodged.
		_sprite.scale = Vector2(1.15, 0.85) if int(_timer * 12.0) % 2 == 0 else Vector2.ONE
	else:
		_sprite.scale = Vector2.ONE
	if _is_hopping():
		var t := clampf(_hop_elapsed / hop_duration, 0.0, 1.0)
		_sprite.position.y = -roundf(sin(t * PI) * hop_height) if t < 1.0 else -hop_height
	_alert_label.visible = state in [State.PURSUE, State.WINDUP]
	if state == State.ROOSTING and is_instance_valid(_roost) and _roost.is_forming():
		# Hop in place while the stack goes up.
		_sprite.position.y = -roundf(absf(sin(Time.get_ticks_msec() / 90.0)) * 3.0)
	elif not _is_hopping():
		_sprite.position.y = 0.0
	var frozen := state == State.FROZEN
	var prompt := _player != null and _player.interact_target == self
	if prompt != _show_prompt:
		_show_prompt = prompt
		queue_redraw()
	_ice.visible = frozen
	_sprite.modulate = FROZEN_TINT if frozen else Color.WHITE
	if frozen:
		_sprite.pause()
	_alert_label.position.y = _sprite.position.y - 26.0


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.0, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)
	if _show_prompt:
		InteractPrompt.draw(self, 0.0, -20.0, "F push")

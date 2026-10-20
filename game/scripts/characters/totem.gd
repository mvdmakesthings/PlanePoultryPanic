class_name Totem
extends CharacterBody2D
## A tower of chickens stacked on each other's backs. Lumbers after the
## player, stomps the ground when close, fires egg barrages from range, and
## calls nearby chickens into the chase. Every so often it takes off and
## flies straight at the player over furniture, its shadow marking where it
## will land, and slams down with a stomp.
##
## Ways to beat it: freeze its base with the extinguisher, ram it with a
## luggage cart, or lure it onto the carousel belt, and it topples, defeating
## any chicken it lands on while its own chickens scatter, dazed. Three
## snacks dropped beside it break it apart without any defeats.
##
## The final boss is a totem with more chickens, several hits to break
## (each hit sheds chickens off its base instead of toppling it for good),
## a giant glowing mushroom crown, and no interest in snacks.

## Emitted when a boss totem takes a hit that doesn't finish it.
signal staggered(hits_left: int)
## Emitted when the totem comes apart for good. fell: toppled, not scattered.
signal broken(fell: bool)

enum State { IDLE, STALK, STOMP_WINDUP, TOPPLING, FLYING }

const IDLE_SHEET := preload("res://assets/sprites/chicken_idle.png")
const RAGE_SHEET := preload("res://assets/sprites/chicken_rage_walk.png")
const CHICKEN_SCENE := preload("res://scenes/characters/chicken.tscn")
## Loaded when first fired rather than preloaded: totem, chicken and egg
## scenes preload each other, and a preload here could come back empty
## depending on which of them loads first.
const EGG_SCENE_PATH := "res://scenes/objects/egg_projectile.tscn"
const POOF_SCENE := preload("res://scenes/objects/feather_poof.tscn")
const CROWN_SHEET := preload("res://assets/sprites/boss_crown.png")
## Seconds a boss can't be hit again after a hit.
const REEL_TIME := 2.0
const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.45)
const SHOCKWAVE_COLOR := Color("ffffff")
const LANDING_WARNING_COLOR := Color(0.894, 0.231, 0.267, 0.45)
const GLOW_COLOR := Color("2ce8f5")
const CHICKEN_LAYER := 4
const WORLD_LAYER := 1
## Pixels between stacked chickens.
const LAYER_HEIGHT := 10.0

## How many chickens are in the stack.
var members := 4
## The roost this totem formed at, which rests after it falls.
var home: Roost = null
## Hits it takes to come apart for good; each earlier hit sheds chickens.
var max_hits := 1
## Wears the giant glowing mushroom crown (the final boss).
var crowned := false
## Ignores snacks laid beside it.
var snack_proof := false
var state := State.IDLE

@export var speed := 45.0
@export var sight_range := 110.0
@export var command_radius := 96.0
@export_group("Stomp")
@export var stomp_trigger := 34.0
@export var stomp_radius := 44.0
@export var stomp_windup := 0.8
@export var stomp_cooldown := 2.0
@export_group("Egg barrage")
@export var barrage_min_range := 50.0
@export var barrage_max_range := 120.0
@export var barrage_cooldown := 3.0
## Angles of the eggs in one barrage, in degrees from straight at the player.
@export var barrage_spread: Array[float] = [-14.0, 0.0, 14.0]
@export_group("Sustained flight")
## Seconds between flights; the first comes a little sooner.
@export var flight_interval := 7.0
@export var flight_time := 2.5
@export var flight_speed := 60.0
@export var flight_height := 10.0
## Only takes off when the player is at least this far away.
@export var flight_min_range := 40.0
## The landing area is marked this long before touching down.
@export var landing_warning := 0.7
@export_group("Toppling")
@export var topple_time := 0.6
## Distance between where each falling chicken lands.
@export var fall_spacing := 12.0
## Chickens within this distance of a landing spot are flattened.
@export var crush_radius := 10.0
@export var scatter_daze := 2.0
## Snacks lying within this distance that break the totem apart.
@export var snack_scatter_radius := 40.0
@export var snacks_to_scatter := 3

var _player: Player
var _layers: Array[Sprite2D] = []
var _timer := 0.0
var _stomp_ready_in := 1.0
var _barrage_ready_in := 1.5
var _shockwave := 0.0
var _topple_dir := Vector2.RIGHT
var _time := 0.0
var _flight_ready_in := 4.0
var _flight_elapsed := 0.0
var _hits_taken := 0
## After a hit, a moment when it can't be hit again.
var _reeling := 0.0
var _crown: Sprite2D
## Squash and stretch for the whole stack (see Juice.squash).
var stack_squash := Vector2.ONE

@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	add_to_group("totems")
	_player = get_tree().get_first_node_in_group("player") as Player
	_build_layers()
	# The stack drops into place.
	Juice.squash(self, Vector2(1.3, 0.6), 0.35, "stack_squash")
	Juice.shake(2.0)


func _build_layers() -> void:
	for layer in _layers:
		layer.queue_free()
	_layers.clear()
	for i in members:
		var layer := Sprite2D.new()
		var atlas := AtlasTexture.new()
		# The top chicken wears a red spotted cap; the rest face forward.
		atlas.atlas = RAGE_SHEET if i == members - 1 else IDLE_SHEET
		atlas.region = Rect2(16 if i == members - 1 else 0, 0, 16, 16)
		layer.texture = atlas
		layer.offset = Vector2(0, -8)
		add_child(layer)
		_layers.append(layer)
	if crowned and _crown == null:
		_crown = Sprite2D.new()
		_crown.texture = CROWN_SHEET
		_crown.hframes = 2
		_crown.offset = Vector2(0, -10)
		add_child(_crown)


## Hits it can still take, counting the one that finishes it.
func hits_left() -> int:
	return max_hits - _hits_taken


func _physics_process(delta: float) -> void:
	_time += delta
	_timer -= delta
	_stomp_ready_in -= delta
	_barrage_ready_in -= delta
	_shockwave -= delta
	_flight_ready_in -= delta
	_reeling -= delta

	match state:
		State.FLYING:
			_fly(delta)
		State.IDLE, State.STALK:
			_stalk()
		State.STOMP_WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_stomp()
		State.TOPPLING:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_finish_topple()
				return
	if state not in [State.TOPPLING, State.FLYING]:
		velocity += Carousel.push_for(get_tree(), global_position)
		move_and_slide()
		# Machinery: a totem lured onto the carousel belt loses its footing.
		var belt := Carousel.push_for(get_tree(), global_position)
		if belt != Vector2.ZERO:
			topple(belt.normalized())
			return
		_check_snack_scatter()
		_check_contact()
	_update_layers()
	queue_redraw()


## Knocks the totem over in a direction. Safe to call more than once.
func topple(direction: Vector2) -> void:
	if state == State.TOPPLING or _reeling > 0.0:
		return
	if _hits_taken + 1 < max_hits:
		_stagger(direction)
		return
	_hits_taken += 1
	state = State.TOPPLING
	_timer = topple_time
	_topple_dir = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	_flash_layers()
	Juice.shake(3.0)


## A hit that doesn't finish a boss: the bottom chickens are knocked out
## from under it and land dazed along the hit, the rest drop down a level,
## and it reels for a moment, then comes on faster.
func _stagger(direction: Vector2) -> void:
	_hits_taken += 1
	_reeling = REEL_TIME
	var shed := maxi(1, (members - 2) / (max_hits - _hits_taken + 1))
	var dir := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	for i in shed:
		var chicken := CHICKEN_SCENE.instantiate() as Chicken
		chicken.position = position + dir.rotated((i - shed / 2.0) * 0.5) * (fall_spacing * 2.0)
		get_parent().add_child(chicken)
		chicken.stun(scatter_daze)
	members -= shed
	_build_layers()
	speed *= 1.15
	flight_interval *= 0.85
	state = State.STALK
	_shockwave = 0.3
	AudioManager.play("boss_hit", global_position)
	_flash_layers()
	Juice.hitstop(0.12)
	Juice.shake(6.0)
	var poof := POOF_SCENE.instantiate() as Node2D
	poof.position = position + dir * 10.0
	get_parent().add_child(poof)
	staggered.emit(hits_left())


## The extinguisher froze the base chicken: the whole stack tips over,
## away from whoever sprayed it.
func hit_by_foam(from: Vector2) -> void:
	topple(from.direction_to(global_position))


func _stalk() -> void:
	velocity = Vector2.ZERO
	if not _can_see_player():
		# A player in range but behind furniture: fly over it.
		if _flight_ready_in <= 0.0 and _player_in_range():
			_take_off()
			return
		state = State.IDLE
		return
	if state == State.IDLE:
		_command_chickens()
	state = State.STALK
	var distance := global_position.distance_to(_player.global_position)
	if distance >= flight_min_range and _flight_ready_in <= 0.0:
		_take_off()
		return
	if distance < stomp_trigger and _stomp_ready_in <= 0.0:
		state = State.STOMP_WINDUP
		_timer = stomp_windup
		return
	if distance >= barrage_min_range and distance <= barrage_max_range and _barrage_ready_in <= 0.0:
		_barrage()
	_agent.target_position = _player.global_position
	var next := _agent.get_next_path_position()
	var target := next if next.distance_to(global_position) > 0.5 else _player.global_position
	velocity = global_position.direction_to(target) * speed


func _take_off() -> void:
	state = State.FLYING
	_timer = flight_time
	_flight_elapsed = 0.0
	# Airborne: over furniture and out of reach of carts and the belt.
	collision_mask = 0
	collision_layer = 0


func _fly(delta: float) -> void:
	_flight_elapsed += delta
	# Home in on the player until the landing spot is marked, then drop
	# straight down onto it, so a quick player can step out of the way.
	if _timer > landing_warning and _player and not _player.is_dead:
		velocity = global_position.direction_to(_player.global_position) * flight_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if _timer > 0.0:
		return
	if _overlaps_world():
		# Can't land inside furniture: keep flying a moment longer.
		_timer = 0.05
		return
	collision_mask = WORLD_LAYER
	collision_layer = CHICKEN_LAYER
	state = State.STALK
	_flight_ready_in = flight_interval
	# Landing slam.
	_stomp()


func _overlaps_world() -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = ($CollisionShape2D as CollisionShape2D).shape
	params.transform = ($CollisionShape2D as CollisionShape2D).global_transform
	params.collision_mask = WORLD_LAYER
	return not get_world_2d().direct_space_state.intersect_shape(params, 1).is_empty()


## Height above the floor: rising after take-off, sinking before landing.
func _altitude() -> float:
	if state != State.FLYING:
		return 0.0
	var rise := clampf(_flight_elapsed / 0.3, 0.0, 1.0)
	var sink := clampf(maxf(_timer, 0.0) / 0.3, 0.0, 1.0)
	return roundf(flight_height * minf(rise, sink))


func _stomp() -> void:
	state = State.STALK
	_stomp_ready_in = stomp_cooldown
	_shockwave = 0.3
	Juice.squash(self, Vector2(1.3, 0.7), 0.25, "stack_squash")
	Juice.shake(4.0)
	ParticleBurst.spawn(get_parent(), "stomp", global_position)
	if _player and global_position.distance_to(_player.global_position) <= stomp_radius:
		_player.take_damage(Player.SUITCASE, global_position)


func _barrage() -> void:
	_barrage_ready_in = barrage_cooldown
	var aim := global_position.direction_to(_player.global_position)
	var egg_scene := load(EGG_SCENE_PATH) as PackedScene
	for degrees in barrage_spread:
		var egg := egg_scene.instantiate() as EggProjectile
		egg.direction = aim.rotated(deg_to_rad(degrees))
		egg.position = position + egg.direction * 10.0
		get_parent().add_child(egg)


## Chickens nearby join the chase when the totem spots the player.
func _command_chickens() -> void:
	for node in get_tree().get_nodes_in_group("chickens"):
		var chicken := node as Chicken
		if global_position.distance_to(chicken.global_position) <= command_radius:
			chicken.alert()


func _check_contact() -> void:
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(Player.SUITCASE, global_position)


func _check_snack_scatter() -> void:
	if snack_proof:
		return
	var nearby := 0
	for node in get_tree().get_nodes_in_group("snack_lures"):
		if global_position.distance_to((node as Node2D).global_position) <= snack_scatter_radius:
			nearby += 1
	if nearby >= snacks_to_scatter:
		_break_apart(false)


func _finish_topple() -> void:
	# Each chicken in the stack lands further along the fall; anything
	# under a landing spot is flattened.
	for i in members:
		var spot := global_position + _topple_dir * fall_spacing * (i + 1)
		for node in get_tree().get_nodes_in_group("chickens"):
			var chicken := node as Chicken
			if chicken.global_position.distance_to(spot) <= crush_radius:
				chicken.defeat()
	# The boss coming down is the biggest moment in the game.
	Juice.hitstop(0.25 if crowned else 0.1)
	Juice.shake(8.0 if crowned else 5.0)
	ParticleBurst.spawn(get_parent(), "stomp", global_position + _topple_dir * fall_spacing * members / 2.0)
	_break_apart(true)


## The stack comes apart into its chickens. After a topple they land along
## the fall line, dazed; when scattered by snacks they hop down beside it.
func _break_apart(fell: bool) -> void:
	for i in members:
		var chicken := CHICKEN_SCENE.instantiate() as Chicken
		if fell:
			chicken.position = position + _topple_dir * fall_spacing * (i + 1)
		else:
			chicken.position = position + Vector2.from_angle(i * TAU / members) * 12.0
		get_parent().add_child(chicken)
		if fell:
			chicken.stun(scatter_daze)
	var poof := POOF_SCENE.instantiate() as Node2D
	poof.position = position
	get_parent().add_child(poof)
	if is_instance_valid(home):
		home.start_cooldown()
	if crowned:
		AudioManager.play("crown_burst", global_position)
	broken.emit(fell)
	queue_free()


func _player_in_range() -> bool:
	return _player != null and not _player.is_dead and not _player.is_hidden \
		and global_position.distance_to(_player.global_position) <= sight_range


func _can_see_player() -> bool:
	if not _player_in_range():
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position, WORLD_LAYER)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _update_layers() -> void:
	for i in _layers.size():
		var layer := _layers[i]
		if state == State.TOPPLING:
			# Each chicken swings out along the fall, higher ones further.
			var t := 1.0 - _timer / topple_time
			var landing := _topple_dir * fall_spacing * (i + 1)
			var standing := Vector2(0, -i * LAYER_HEIGHT)
			layer.position = standing.lerp(landing, t).round()
		else:
			# A visible wobble, worse further up; the base looks strained.
			var sway := sin(_time * 3.0 + i * 0.8) * (i * 0.6)
			var shake := (randi() % 3 - 1) if state == State.STOMP_WINDUP else 0
			var height := roundf(i * LAYER_HEIGHT * stack_squash.y)
			layer.position = Vector2(roundf(sway) + shake, -height - _altitude())
			layer.scale = (Vector2(1.1, 0.9) if i == 0 and members > 1 else Vector2.ONE) * stack_squash
		layer.flip_h = _player != null and _player.global_position.x < global_position.x
		# Flicker while reeling from a hit.
		layer.visible = _reeling <= 0.0 or int(_reeling * 12.0) % 2 == 0
	if _crown:
		var top := _layers[-1].position if not _layers.is_empty() else Vector2.ZERO
		_crown.position = top + Vector2(0, -12)
		_crown.frame = int(_time * 3.0) % 2
		_crown.visible = state != State.TOPPLING


## Every chicken in the stack flashes white as a hit lands.
func _flash_layers() -> void:
	for layer in _layers:
		Juice.flash(layer, Juice.WHITE, 0.2)
	if _crown:
		Juice.flash(_crown, Juice.WHITE, 0.2)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, SHADOW_COLOR)
	if _shockwave > 0.0:
		# Stomp shockwave: a ring spreading across the floor.
		var r := stomp_radius * (1.0 - _shockwave / 0.3)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, SHOCKWAVE_COLOR, 2.0)
	if state == State.FLYING and _timer <= landing_warning:
		# Where it's about to slam down.
		draw_circle(Vector2.ZERO, stomp_radius, LANDING_WARNING_COLOR)
	draw_set_transform(Vector2.ZERO)
	if state == State.FLYING:
		# Teal sparks falling from the airborne stack.
		for k in 4:
			var spark := Vector2(sin(_time * 9.0 + k * 1.7) * 7.0, -_altitude() + 2.0 + fmod(_time * 20.0 + k * 3.0, 8.0))
			draw_rect(Rect2(spark.round(), Vector2.ONE), GLOW_COLOR)
	if state == State.STOMP_WINDUP and int(_timer * 10.0) % 2 == 0:
		var font := ThemeDB.fallback_font
		var top := -members * LAYER_HEIGHT - 12.0
		draw_string_outline(font, Vector2(-10, top), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 8, 2, Color("181425"))
		draw_string(font, Vector2(-10, top), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 8, Color("e43b44"))

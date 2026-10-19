class_name Chicken
extends CharacterBody2D
## A normal chicken: wanders and pecks until it spots the player, then
## chases and alerts nearby chickens. Thrown snacks beat everything else:
## a chicken drops what it's doing to go eat one.

enum State { WANDER, PURSUE, INVESTIGATE, EATING }

const WALK_SHEET := preload("res://assets/sprites/chicken_walk.png")
const IDLE_SHEET := preload("res://assets/sprites/chicken_idle.png")
const FRAME_SIZE := Vector2i(16, 16)
const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)
const WORLD_LAYER := 1

@export var wander_speed := 30.0
## Slower than the player's walk, so one normal chicken can always be escaped.
@export var pursue_speed := 70.0
@export var investigate_speed := 70.0
@export var sight_range := 64.0
## Seconds without seeing the player before giving up the chase.
@export var give_up_time := 2.0
@export var alert_radius := 48.0
@export var snack_notice_range := 100.0
@export var eat_time := 2.5

var state := State.WANDER

var _player: Player
var _target_snack: ThrownSnack
var _wander_dir := Vector2.ZERO
var _timer := 0.0
var _lost_sight_time := 0.0
var _facing := Vector2.DOWN

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: Area2D = $Hitbox
@onready var _alert_label: Label = $AlertLabel
@onready var _agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpriteSheets.add_directional(frames, "walk", WALK_SHEET, FRAME_SIZE, 8.0)
	SpriteSheets.add_directional(frames, "idle", IDLE_SHEET, FRAME_SIZE, 3.0)
	_sprite.sprite_frames = frames
	# Desync chickens so they don't all peck in unison.
	_sprite.play("idle_down")
	_sprite.frame = randi() % 3
	_pick_wander()


func _physics_process(delta: float) -> void:
	_timer -= delta
	match state:
		State.WANDER:
			_wander()
		State.PURSUE:
			_pursue(delta)
		State.INVESTIGATE:
			_investigate()
		State.EATING:
			_eat()
	move_and_slide()
	if state == State.WANDER and get_slide_collision_count() > 0:
		_pick_wander()
	if velocity.length() > 1.0:
		_facing = velocity.normalized()
	_check_hit()
	_update_visuals()


## Called by a nearby chicken that spotted the player.
func alert() -> void:
	if state == State.WANDER:
		_start_pursuit(false)


func _wander() -> void:
	if _timer <= 0.0:
		_pick_wander()
	velocity = _wander_dir * wander_speed
	if _try_investigate():
		return
	if _can_see_player():
		_start_pursuit(true)


func _pursue(delta: float) -> void:
	if _try_investigate():
		return
	if _can_see_player():
		_lost_sight_time = 0.0
	else:
		_lost_sight_time += delta
		if _lost_sight_time >= give_up_time or _player.is_dead:
			state = State.WANDER
			_pick_wander()
			return
	velocity = _direction_toward(_player.global_position) * pursue_speed


func _investigate() -> void:
	if not is_instance_valid(_target_snack):
		state = State.WANDER
		_pick_wander()
		return
	var to_snack := _target_snack.global_position - global_position
	if to_snack.length() < 4.0:
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
	if _timer <= 0.0:
		state = State.WANDER
		_pick_wander()


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
		_timer = randf_range(1.0, 2.5)
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


func _can_see_player() -> bool:
	if _player == null or _player.is_dead:
		return false
	if global_position.distance_to(_player.global_position) > sight_range:
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
	if state == State.EATING:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(1, global_position)


func _update_visuals() -> void:
	var direction := SpriteSheets.direction_name(_facing)
	var moving := velocity.length() > 1.0
	var animation := ("walk_" if moving else "idle_") + direction
	if _sprite.animation != animation:
		_sprite.play(animation)
	_sprite.speed_scale = 1.5 if state == State.PURSUE else 1.0
	_alert_label.visible = state == State.PURSUE


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.0, SHADOW_COLOR)

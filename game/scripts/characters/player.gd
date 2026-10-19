class_name Player
extends CharacterBody2D
## The stranded passenger: 8-directional movement, stamina-limited running,
## luggage-icon health with invincibility frames, and snacks that either heal
## or get thrown to distract chickens.

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal snacks_changed(count: int)
signal died

const THROWN_SNACK_SCENE := preload("res://scenes/objects/thrown_snack.tscn")
const WALK_SHEET := preload("res://assets/sprites/player_walk.png")
const IDLE_SHEET := preload("res://assets/sprites/player_idle.png")
const FRAME_SIZE := Vector2i(16, 32)
const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)

@export var walk_speed := 100.0
@export var run_speed := 150.0
@export var max_health := 3
@export var max_stamina := 100.0
## Stamina spent per second while running.
@export var stamina_drain := 40.0
## Stamina recovered per second while not running.
@export var stamina_regen := 25.0
## After running dry, running is locked until stamina refills to this fraction.
@export_range(0.0, 1.0) var exhausted_recover_ratio := 0.3
@export var max_snacks := 6
@export var starting_snacks := 2
@export var invincibility_time := 1.5
@export var knockback_strength := 160.0
@export var knockback_decay := 800.0

var health: int
var stamina: float
var snacks: int
var facing := Vector2.DOWN
var is_dead := false

var _invincible_timer := 0.0
var _exhausted := false
var _knockback := Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health
	stamina = max_stamina
	snacks = starting_snacks
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpriteSheets.add_directional(frames, "walk", WALK_SHEET, FRAME_SIZE, 8.0)
	SpriteSheets.add_directional(frames, "idle", IDLE_SHEET, FRAME_SIZE, 2.0)
	_sprite.sprite_frames = frames
	_sprite.play("idle_down")
	# Deferred so listeners that connect in the level's _ready get initial values.
	_emit_state.call_deferred()


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()

	var running := Input.is_action_pressed("run") and input != Vector2.ZERO and not _exhausted
	_update_stamina(running, delta)

	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_decay * delta)
	velocity = input * (run_speed if running else walk_speed) + _knockback
	move_and_slide()

	_update_animation(input, running)
	_update_invincibility(delta)


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("throw_snack"):
		throw_snack()
	elif event.is_action_pressed("eat_snack"):
		eat_snack()


func take_damage(amount: int, from_position: Vector2) -> void:
	if is_dead or _invincible_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	_knockback = (global_position - from_position).normalized() * knockback_strength
	if health == 0:
		_die()
	else:
		_invincible_timer = invincibility_time


## Returns false when the snack bag is full, so the pickup stays in the world.
func add_snack() -> bool:
	if is_dead or snacks >= max_snacks:
		return false
	snacks += 1
	snacks_changed.emit(snacks)
	return true


func throw_snack() -> void:
	if snacks <= 0:
		return
	snacks -= 1
	snacks_changed.emit(snacks)
	var snack := THROWN_SNACK_SCENE.instantiate() as ThrownSnack
	snack.direction = facing
	snack.position = position
	get_parent().add_child(snack)


func eat_snack() -> void:
	if snacks <= 0 or health >= max_health:
		return
	snacks -= 1
	health += 1
	snacks_changed.emit(snacks)
	health_changed.emit(health, max_health)


## Stops all player control, e.g. when the level is won.
func freeze() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)
	modulate.a = 1.0


func _update_stamina(running: bool, delta: float) -> void:
	var previous := stamina
	if running:
		stamina = maxf(stamina - stamina_drain * delta, 0.0)
		if stamina == 0.0:
			_exhausted = true
	else:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)
		if _exhausted and stamina >= max_stamina * exhausted_recover_ratio:
			_exhausted = false
	if stamina != previous:
		stamina_changed.emit(stamina, max_stamina)


func _update_animation(input: Vector2, running: bool) -> void:
	var direction := SpriteSheets.direction_name(facing)
	var animation := ("walk_" if input != Vector2.ZERO else "idle_") + direction
	if _sprite.animation != animation:
		_sprite.play(animation)
	_sprite.speed_scale = 1.6 if running else 1.0


func _update_invincibility(delta: float) -> void:
	if _invincible_timer <= 0.0:
		return
	_invincible_timer -= delta
	var blink_on := int(_invincible_timer * 15.0) % 2 == 0
	modulate.a = 1.0 if _invincible_timer <= 0.0 or blink_on else 0.3


func _die() -> void:
	is_dead = true
	freeze()
	_sprite.stop()
	modulate = Color(0.5, 0.5, 0.5)
	died.emit()


func _emit_state() -> void:
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	snacks_changed.emit(snacks)


func _draw() -> void:
	# Soft floor shadow under the feet; the sprite draws on top of it.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, SHADOW_COLOR)

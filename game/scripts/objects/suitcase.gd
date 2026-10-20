class_name Suitcase
extends Node2D
## An abandoned rolling suitcase. The player picks it up with Interact and
## carries it overhead, then throws it with Use. A chicken it hits while
## it's still moving fast is defeated, and the suitcase bursts open and is
## gone. A throw that misses lands and can be picked up again.

enum State { LYING, CARRIED, FLYING, BURST }

const WORLD_LAYER := 1
const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)
## How high above the player's feet the suitcase sits while carried.
const CARRY_HEIGHT := 30.0
## How long the burst-open frame stays before the suitcase is gone.
const BURST_TIME := 0.6

@export var throw_speed := 200.0
@export var friction := 900.0
## Below this speed the suitcase is too slow to hurt a chicken.
@export var lethal_speed := 60.0
## Seconds from leaving the player's hands to touching the floor.
@export var air_time := 0.3
## Extra height at the top of the throw's arc, in pixels.
@export var arc_height := 8.0
## How close the player must be to pick it up.
@export var reach := 16.0
## A secret suitcase (the FRAGILE one) bursts into this many snacks when it
## lands or hits a chicken, instead of clothes, and finds secret_id. 0 for
## a plain suitcase.
@export var burst_snacks := 0
@export var secret_id := ""

var state := State.LYING

var _carrier: Player = null
var _velocity := Vector2.ZERO
var _flight := 0.0
var _burst_left := 0.0
var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	add_to_group("interactables")
	# A secret suitcase already burst earlier in the run stays gone.
	if burst_snacks > 0 and secret_id != "" and GameManager.has_secret(secret_id):
		queue_free()


func _physics_process(delta: float) -> void:
	match state:
		State.LYING:
			var near := _carrier_candidate() != null
			if near != _show_prompt:
				_show_prompt = near
				queue_redraw()
		State.CARRIED:
			global_position = _carrier.global_position
		State.FLYING:
			_fly(delta)
		State.BURST:
			_burst_left -= delta
			modulate.a = clampf(_burst_left / 0.2, 0.0, 1.0)
			if _burst_left <= 0.0:
				queue_free()


func can_interact(player: Player) -> bool:
	return state == State.LYING and player.carrying == null \
		and global_position.distance_to(player.global_position) <= reach


func interact(player: Player) -> void:
	player.carry(self)


## Lifted overhead by the player; follows them until thrown or put down.
func lift(player: Player) -> void:
	state = State.CARRIED
	_carrier = player
	global_position = player.global_position
	z_index = 1
	_set_height(CARRY_HEIGHT)
	_show_prompt = false
	queue_redraw()


## Thrown along direction from the carrier's hands.
func throw(direction: Vector2) -> void:
	state = State.FLYING
	global_position = _carrier.global_position
	_carrier = null
	_velocity = direction.normalized() * throw_speed
	_flight = 0.0
	queue_redraw()


## Set down at the carrier's feet.
func put_down() -> void:
	state = State.LYING
	_carrier = null
	z_index = 0
	_set_height(0.0)
	queue_redraw()


func _fly(delta: float) -> void:
	_flight += delta
	var k := minf(_flight / air_time, 1.0)
	_set_height(lerpf(CARRY_HEIGHT, 0.0, k) + arc_height * 4.0 * k * (1.0 - k))

	if _velocity.length() >= lethal_speed:
		for body in _hitbox.get_overlapping_bodies():
			if body is Chicken:
				(body as Chicken).defeat()
				_burst()
				return

	# Raycast each step so it stops at walls and furniture instead of
	# passing into them, like a thrown snack.
	var step := _velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, WORLD_LAYER)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position - _velocity.normalized() * 4.0
		_velocity = Vector2.ZERO
	else:
		position += step
		# Only slows down once it's skidding along the floor.
		if k >= 1.0:
			_velocity = _velocity.move_toward(Vector2.ZERO, friction * delta)
	if _velocity == Vector2.ZERO:
		_land()
	queue_redraw()


func _land() -> void:
	if burst_snacks > 0:
		_burst()
		return
	state = State.LYING
	z_index = 0
	_set_height(0.0)


func _burst() -> void:
	state = State.BURST
	_sprite.frame = 1
	_set_height(0.0)
	_burst_left = BURST_TIME
	queue_redraw()
	if burst_snacks > 0:
		_spill_snacks()


## A secret suitcase's snacks land around where it burst.
func _spill_snacks() -> void:
	if secret_id != "":
		GameManager.find_secret(secret_id)
	var pickup_scene := load("res://scenes/objects/item_pickup.tscn") as PackedScene
	for i in burst_snacks:
		var pickup := pickup_scene.instantiate() as ItemPickup
		pickup.position = position + Vector2.from_angle(i * TAU / burst_snacks + 0.4) * 12.0
		get_parent().add_child.call_deferred(pickup)


func _set_height(height: float) -> void:
	_sprite.position.y = -8.0 - height


func _carrier_candidate() -> Player:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and player.interact_target == self:
		return player
	return null


func _draw() -> void:
	if state == State.CARRIED or state == State.BURST:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 7.0, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)
	if _show_prompt:
		InteractPrompt.draw(self, 0.0, -20.0, "{interact} lift")

class_name ThrownSnack
extends Node2D
## A thrown snack. Slides along the floor, then sits as a lure that
## distracts nearby chickens until one eats it or it goes stale. The player
## can pick it back up, once they've stepped away from it after it lands.

const WORLD_LAYER := 1
## The player must be this far from a landed snack before it can be picked
## back up, so a snack thrown into a nearby wall doesn't pop straight back.
const ARM_DISTANCE := 14.0
const PICKUP_DISTANCE := 8.0

@export var throw_speed := 220.0
@export var friction := 500.0
@export var lifetime := 8.0

var direction := Vector2.DOWN

var _velocity: Vector2
var _landed := false
var _consumed := false
var _armed := false


func _ready() -> void:
	_velocity = direction * throw_speed


func _physics_process(delta: float) -> void:
	if _landed:
		# Snacks lying on a carousel ride the belt, and vanish down the chute.
		position += Carousel.push_for(get_tree(), global_position) * delta
		if Carousel.in_any_chute(get_tree(), global_position):
			queue_free()
			return
		if _try_pickup():
			return
		lifetime -= delta
		# Blink during the last two seconds so the player knows it's going stale.
		visible = lifetime > 2.0 or int(lifetime * 8.0) % 2 == 0
		if lifetime <= 0.0:
			queue_free()
		return
	# Raycast each step so the snack stops at walls and furniture instead of
	# sliding into them.
	var step := _velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, WORLD_LAYER)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position - _velocity.normalized() * 3.0
		_land()
		return
	position += step
	_velocity = _velocity.move_toward(Vector2.ZERO, friction * delta)
	if _velocity == Vector2.ZERO:
		_land()


## Returns false if another chicken got here first.
func consume() -> bool:
	if _consumed:
		return false
	_consumed = true
	ParticleBurst.spawn(get_parent(), "crumb", global_position)
	queue_free()
	return true


func _try_pickup() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return false
	var distance := global_position.distance_to(player.global_position)
	if distance > ARM_DISTANCE:
		_armed = true
	elif _armed and distance <= PICKUP_DISTANCE and not _consumed and player.add_snack():
		_consumed = true
		queue_free()
		return true
	return false


func _land() -> void:
	_landed = true
	add_to_group("snack_lures")

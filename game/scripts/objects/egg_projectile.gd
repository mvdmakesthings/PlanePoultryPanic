class_name EggProjectile
extends Node2D
## An egg fired by an egg-shooter chicken. Flies at chest height, hurts
## the player on contact, and splats on walls and furniture.

const WORLD_LAYER := 1
const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.35)
## Eggs fly this far above the floor, roughly at the player's middle.
const FLIGHT_HEIGHT := 10.0

@export var speed := 140.0
@export var max_lifetime := 2.0
@export var splat_time := 0.5

var direction := Vector2.RIGHT

var _splatted := false
var _timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.position.y = -FLIGHT_HEIGHT


func _physics_process(delta: float) -> void:
	_timer += delta
	if _splatted:
		if _timer >= splat_time:
			queue_free()
		return
	if _timer >= max_lifetime:
		_splat()
		return

	var step := direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, WORLD_LAYER)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position - direction * 2.0
		_splat()
		return
	position += step
	for node in get_tree().get_nodes_in_group("egg_cover"):
		if node.blocks_egg(global_position):
			_splat()
			return

	var player := get_tree().get_first_node_in_group("player") as Player
	if player and not player.is_dead and global_position.distance_to(player.global_position) < 7.0:
		player.take_damage(1, global_position - direction * 8.0)
		_splat()


func _splat() -> void:
	_splatted = true
	_timer = 0.0
	_sprite.frame = 1
	_sprite.position.y = 0.0
	queue_redraw()


func _draw() -> void:
	if not _splatted:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 3.0, SHADOW_COLOR)

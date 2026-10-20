class_name SecurityShutter
extends Node2D
## A steel grille that rolls down across a passage, worked by a
## ShutterSwitch on the wall. Closed, it blocks everyone and chickens path
## around it. A chicken caught underneath as it slams down is defeated; the
## player is nudged out from under it instead. Position this node at the
## bottom-left corner of the passage it closes, on the floor line.

signal toggled(closed: bool)

const WIDTH := 32.0
const HEIGHT := 32.0
const FRAMES := 4
## How deep the closed grille is, at the floor line.
const DEPTH := 6.0
## Chickens this close to the floor line (above or below) get flattened.
const CRUSH_REACH := 8.0

@export var start_closed := false
@export var frames_per_second := 12.0

var is_closed := false

var _amount := 0.0
var _body: StaticBody2D
var _shape: CollisionShape2D

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_body = StaticBody2D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_shape = CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(WIDTH, DEPTH)
	_shape.shape = box
	_shape.position = Vector2(WIDTH / 2.0, -DEPTH / 2.0)
	_body.add_child(_shape)
	add_child(_body)
	_set_solid(false)
	if start_closed:
		is_closed = true
		_amount = FRAMES - 1
		_set_solid(true)
	_sprite.frame = int(_amount)


func toggle() -> void:
	if is_closed:
		open()
	else:
		close()


func close() -> void:
	if is_closed:
		return
	is_closed = true
	AudioManager.play("shutter", global_position + Vector2(WIDTH / 2.0, 0))


func open() -> void:
	if not is_closed:
		return
	is_closed = false
	_set_solid(false)
	AudioManager.play("shutter", global_position + Vector2(WIDTH / 2.0, 0))
	toggled.emit(false)


## The strip under the grille where it lands, in world space.
func crush_rect() -> Rect2:
	return Rect2(global_position + Vector2(0, -CRUSH_REACH), Vector2(WIDTH, CRUSH_REACH * 2.0))


func _physics_process(delta: float) -> void:
	var target := float(FRAMES - 1) if is_closed else 0.0
	if _amount == target:
		return
	_amount = move_toward(_amount, target, frames_per_second * delta)
	_sprite.frame = int(roundf(_amount))
	if is_closed and _amount == target:
		_slam()


func _slam() -> void:
	var crush := crush_rect()
	for node in get_tree().get_nodes_in_group("chickens"):
		var chicken := node as Chicken
		if crush.has_point(chicken.global_position) and not chicken.is_hopping():
			chicken.defeat()
	var player := get_tree().get_first_node_in_group("player") as Player
	var under := Rect2(global_position + Vector2(0, -DEPTH - 4.0), Vector2(WIDTH, DEPTH + 8.0))
	if player and under.has_point(player.global_position):
		# Out from under it, to whichever side they're nearer.
		var floor_y := global_position.y
		var below := player.global_position.y >= floor_y - DEPTH / 2.0
		player.global_position.y = floor_y + 6.0 if below else floor_y - DEPTH - 6.0
	_set_solid(true)
	toggled.emit(true)


func _set_solid(solid: bool) -> void:
	_shape.set_deferred("disabled", not solid)
	if solid:
		_body.add_to_group(LevelBuilder.NAV_OBSTACLES)
	else:
		_body.remove_from_group(LevelBuilder.NAV_OBSTACLES)
	var level := owner as GameLevel
	if level and is_node_ready():
		level.rebake_navigation()

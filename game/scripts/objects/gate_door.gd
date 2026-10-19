class_name GateDoor
extends Node2D
## The boarding gate in the back wall. Its glass doors slide open as the
## player gets close, and walking up into the open doorway reaches the gate.
## Position this node at the door's top-left corner on the wall face.

signal player_entered

const FRAMES := 4
## Doorway opening inside the 48x32 door sprite (see tools/sprites/gate.py).
const DOORWAY := Rect2(8, 18, 32, 14)

@export var open_distance := 56.0
@export var frames_per_second := 12.0

var _open_amount := 0.0
var _entered := false

@onready var _sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var threshold := global_position + Vector2(24, 32)
	var near := player.global_position.distance_to(threshold) < open_distance
	var target := float(FRAMES - 1) if near else 0.0
	_open_amount = move_toward(_open_amount, target, frames_per_second * delta)
	_sprite.frame = int(roundf(_open_amount))

	if not _entered and doorway_rect().has_point(player.global_position):
		_entered = true
		player_entered.emit()


## The doorway floor area in world space, where the player counts as boarding.
func doorway_rect() -> Rect2:
	return Rect2(global_position + DOORWAY.position, DOORWAY.size)

class_name LeverSocket
extends Node2D
## An empty lever socket on the wall beside a speed panel. Fit the lever
## handle (Interact; it stays in the socket), and after that Interact at the
## lever turns its walkways around. Position this node at its top-left
## corner on the wall face, its bottom 2 px above the floor line, like a
## SpeedPanel.

const SIZE := Vector2(12, 14)
## Frames in lever_socket.png.
const FRAME_EMPTY := 0
const FRAME_UP := 1
const FRAME_DOWN := 2

@export var walkway_paths: Array[NodePath] = []
@export var key_item := "lever_handle"
@export var reach := 22.0

## True until the handle is fitted (the name is what checkpoints look for).
var is_locked := true
## Flipped from how the walkways started.
var is_reversed := false

var _walkways: Array[Walkway] = []
var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("unlockables")
	for path in walkway_paths:
		var walkway := get_node_or_null(path) as Walkway
		if walkway:
			_walkways.append(walkway)


func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 10.0)


func can_interact(player: Player) -> bool:
	return not _walkways.is_empty() and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if is_locked:
		if not player.inventory.use_key_item(key_item):
			FloatText.spawn(player, "Needs a handle")
			AudioManager.play("locked", base_point())
			return
		unlock()
		FloatText.spawn(player, "Lever fitted")
		return
	is_reversed = not is_reversed
	for walkway in _walkways:
		walkway.east = not walkway.east
	_sprite.frame = FRAME_DOWN if is_reversed else FRAME_UP
	AudioManager.play("switch", base_point())
	FloatText.spawn(player, "Reversed!")


## Fits the handle. quiet skips the sound, for restoring a save.
func unlock(quiet := false) -> void:
	if not is_locked:
		return
	is_locked = false
	_sprite.frame = FRAME_UP
	queue_redraw()
	if not quiet:
		AudioManager.play("unlock", base_point())


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()


func _draw() -> void:
	if not _show_prompt:
		return
	var prompt := "{interact} reverse walkway"
	if is_locked:
		var player := get_tree().get_first_node_in_group("player") as Player
		var has_handle := player != null and player.inventory.has_key_item(key_item)
		prompt = "{interact} fit handle" if has_handle else "{interact} needs a handle"
	InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, prompt)

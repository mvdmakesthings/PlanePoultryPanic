class_name FuseBox
extends Node2D
## An empty fuse box on the wall beside a speed panel. Its walkways have no
## power until the player fits a fuse (Interact, the fuse is used up); then
## they start moving. Position this node at its top-left corner on the wall
## face, its bottom 2 px above the floor line, like a SpeedPanel.

const SIZE := Vector2(12, 14)

@export var walkway_paths: Array[NodePath] = []
@export var key_item := "fuse"
@export var reach := 22.0

## True until a fuse is fitted (the name is what checkpoints look for).
var is_locked := true

var _walkways: Array[Walkway] = []
var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("unlockables")
	for path in walkway_paths:
		var walkway := get_node_or_null(path) as Walkway
		if walkway:
			walkway.powered = false
			_walkways.append(walkway)


func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 10.0)


func can_interact(player: Player) -> bool:
	return is_locked and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if not player.inventory.use_key_item(key_item):
		FloatText.spawn(player, "Needs a fuse")
		AudioManager.play("locked", base_point())
		return
	unlock()
	FloatText.spawn(player, "Power on!")


## Fits the fuse and powers the walkways. quiet skips the sound, for
## restoring a save.
func unlock(quiet := false) -> void:
	if not is_locked:
		return
	is_locked = false
	_sprite.frame = 1
	for walkway in _walkways:
		walkway.powered = true
	_show_prompt = false
	queue_redraw()
	if not quiet:
		AudioManager.play("switch", base_point())
		ParticleBurst.spawn(get_parent(), "sparkle", base_point(), Vector2.ZERO, 0, 12.0)


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()


func _draw() -> void:
	if not _show_prompt:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var has_fuse := player != null and player.inventory.has_key_item(key_item)
	InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, "{interact} fit fuse" if has_fuse else "{interact} needs a fuse")

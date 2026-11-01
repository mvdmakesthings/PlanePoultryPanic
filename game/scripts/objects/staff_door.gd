class_name StaffDoor
extends Node2D
## A STAFF ONLY door in the wall face, one of a pair. With the staff badge
## (never used up), Interact below it steps through: the screen fades and the
## player comes out below the partner door, somewhere else in the level.
## Chickens don't follow. Its badge reader shows green once the player
## holds a badge. Position this node at its top-left corner on the wall
## face, like a SecretDoor.

const SIZE := Vector2(16, 32)

@export var partner: StaffDoor
@export var key_item := "staff_badge"
@export var reach := 22.0

var _show_prompt := false
var _busy := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")


## The floor spot right below the door, where the player stands to use it.
func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 4.0)


func can_interact(player: Player) -> bool:
	return not _busy and partner != null and player.carrying == null \
		and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if not player.inventory.has_key_item(key_item):
		FloatText.spawn(player, "Staff only")
		AudioManager.play("locked", base_point())
		return
	_busy = true
	AudioManager.play("door", base_point())
	var level := owner as GameLevel
	var through := func() -> void:
		player.global_position = partner.base_point()
		player.velocity = Vector2.ZERO
		(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	if level:
		await level.fade_through(through)
	else:
		through.call()
	AudioManager.play("door", partner.base_point())
	_busy = false


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	_sprite.frame = 1 if player != null and player.inventory.has_key_item(key_item) else 0
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()


func _draw() -> void:
	if not _show_prompt:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var has_badge := player != null and player.inventory.has_key_item(key_item)
	InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, "{interact} staff door" if has_badge else "{interact} staff only")

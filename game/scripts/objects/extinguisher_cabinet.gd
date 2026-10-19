class_name ExtinguisherCabinet
extends Node2D
## An emergency cabinet on the back wall. Interact below it to take the fire
## extinguisher inside. Position this node at the cabinet's top-left corner
## on the wall face.

const SIZE := Vector2(16, 20)

@export var charges := 3
## How close the player's feet must be to the wall below the cabinet.
@export var reach := 22.0

var is_empty := false

var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()


## The floor spot right below the cabinet, where the player stands to use it.
func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, 24.0)


func can_interact(player: Player) -> bool:
	return not is_empty and player.inventory.first_empty_slot() >= 0 \
		and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	player.give_extinguisher(charges)
	is_empty = true
	_sprite.frame = 1
	AudioManager.play("closet", base_point())
	_show_prompt = false
	queue_redraw()


func _draw() -> void:
	if _show_prompt:
		InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, "F take")

class_name HidingSpot
extends Node2D
## A supply closet in the back wall. Interact below it to hide inside, and
## again to come out. Chickens that were chasing the player when they ducked
## in wait outside and peck at the door (it shakes) until they give up and
## walk off. Once it stops shaking, it's safe to come out.
## Position this node at the door's top-left corner on the wall face.

const SIZE := Vector2(16, 30)

@export var reach := 22.0

## The player hiding inside, or null.
var occupant: Player = null

var _swing_time := 0.0
var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")


## The floor spot right below the door, where the player stands to use it.
func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 4.0)


func is_occupied() -> bool:
	return occupant != null


func can_interact(player: Player) -> bool:
	if occupant == player:
		return true
	return occupant == null and not player.is_hidden \
		and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if occupant == player:
		_release()
		return
	occupant = player
	_swing_time = 0.3
	AudioManager.play("closet", base_point())
	player.hide_in(self)
	# Chickens already chasing saw where the player went.
	for node in get_tree().get_nodes_in_group("chickens"):
		(node as Chicken).besiege(self)


func _physics_process(delta: float) -> void:
	_swing_time -= delta
	var shaking := false
	if occupant:
		for node in get_tree().get_nodes_in_group("chickens"):
			if (node as Chicken).is_pecking_door(self):
				shaking = true
				break
	_sprite.offset.x = float(randi() % 3 - 1) if shaking else 0.0
	_sprite.frame = 1 if _swing_time > 0.0 else 0

	var player := get_tree().get_first_node_in_group("player") as Player
	var prompt := player != null and player.interact_target == self
	if prompt != _show_prompt:
		_show_prompt = prompt
		queue_redraw()


func _release() -> void:
	var player := occupant
	occupant = null
	_swing_time = 0.3
	AudioManager.play("closet", base_point())
	player.leave_hiding()


func _draw() -> void:
	if _show_prompt:
		InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, "{interact} leave" if occupant else "{interact} hide")

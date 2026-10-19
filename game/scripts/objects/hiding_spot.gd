class_name HidingSpot
extends Node2D
## A supply closet in the back wall. Interact below it to hide inside, and
## again to come out. Chickens that were chasing the player when they ducked
## in wait outside and peck at the door; enough pecking bursts it open and
## throws the player out, so hiding buys time but never lasts forever.
## Position this node at the door's top-left corner on the wall face.

const SIZE := Vector2(16, 30)

@export var reach := 22.0
## Seconds of pecking (by any number of chickens) before the door bursts.
@export var break_time := 6.0
## After bursting, the closet can't be used for this long.
@export var cooldown := 10.0
@export var burst_push := 220.0

## The player hiding inside, or null.
var occupant: Player = null

var _peck_time := 0.0
var _cooldown_left := 0.0
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
	return occupant == null and _cooldown_left <= 0.0 and not player.is_hidden \
		and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if occupant == player:
		_release(Vector2.ZERO)
		return
	occupant = player
	_peck_time = 0.0
	_swing_time = 0.3
	player.hide_in(self)
	# Chickens already chasing saw where the player went.
	for node in get_tree().get_nodes_in_group("chickens"):
		(node as Chicken).besiege(self)


func _physics_process(delta: float) -> void:
	_cooldown_left -= delta
	_swing_time -= delta
	var shaking := false
	if occupant:
		var pecking := 0
		for node in get_tree().get_nodes_in_group("chickens"):
			if (node as Chicken).is_pecking_door(self):
				pecking += 1
		if pecking > 0:
			shaking = true
			_peck_time += delta
			if _peck_time >= break_time:
				_release(Vector2.DOWN * burst_push)
				_cooldown_left = cooldown
	_sprite.offset.x = float(randi() % 3 - 1) if shaking else 0.0
	_sprite.frame = 1 if _swing_time > 0.0 or _cooldown_left > 0.0 else 0

	var player := get_tree().get_first_node_in_group("player") as Player
	var prompt := player != null and player.interact_target == self
	if prompt != _show_prompt:
		_show_prompt = prompt
		queue_redraw()


func _release(push: Vector2) -> void:
	var player := occupant
	occupant = null
	_swing_time = 0.3
	player.leave_hiding(push)


func _draw() -> void:
	if _show_prompt:
		InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, "F leave" if occupant else "F hide")

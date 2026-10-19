class_name ItemPickup
extends Area2D
## An item lying in the terminal. The player picks it up by walking over it;
## whatever doesn't fit in the inventory stays on the floor. Items the
## player dropped can't be picked up until they've stepped away once.

const ARM_DISTANCE := 14.0

@export_enum("snack", "extinguisher", "maintenance_key") var item := "snack"
## How many (snacks), or charges left (extinguisher).
@export var count := 1
## Set when the player drops this; it then waits until they step away.
@export var dropped := false

var _bob_time := randf() * TAU

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var info: Dictionary = Inventory.KEY_ITEMS.get(item, Inventory.ITEMS.get(item))
	_sprite.texture = load(info["icon"])


func _physics_process(delta: float) -> void:
	_bob_time += delta * 4.0
	_sprite.position.y = -7.0 + roundf(sin(_bob_time))
	for body in get_overlapping_bodies():
		if body is Player:
			if dropped:
				return
			count = (body as Player).pick_up(item, count)
			if count == 0:
				queue_free()
			return
	if dropped:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player and player.global_position.distance_to(global_position) > ARM_DISTANCE:
			dropped = false

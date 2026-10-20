class_name ItemPickup
extends Area2D
## An item lying in the terminal. The player picks it up by walking over it;
## whatever doesn't fit in the inventory stays on the floor. Items the
## player dropped can't be picked up until they've stepped away once.

const ARM_DISTANCE := 14.0
const SPARKLE := Color("ffffff")

@export_enum("snack", "extinguisher", "maintenance_key", "boarding_pass") var item := "snack"
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
	if Inventory.KEY_ITEMS.has(item):
		queue_redraw()
	for body in get_overlapping_bodies():
		if body is Player:
			if dropped:
				return
			var before := count
			count = (body as Player).pick_up(item, count)
			if count < before:
				ParticleBurst.spawn(get_parent(), "sparkle", global_position, Vector2.ZERO, 0, 7.0)
			if count == 0:
				queue_free()
			return
	if dropped:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player and player.global_position.distance_to(global_position) > ARM_DISTANCE:
			dropped = false


func _draw() -> void:
	if not Inventory.KEY_ITEMS.has(item):
		return
	# Key items twinkle so they stand out from the floor: a small star that
	# grows and shrinks at the item's corner, now and then.
	var t := fmod(_bob_time / 4.0, 2.0)
	if t > 1.0:
		return
	var arm := roundf(sin(t * PI) * 2.0)
	var center := _sprite.position + Vector2(5, -4)
	draw_rect(Rect2(center, Vector2.ONE), SPARKLE)
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		for i in range(1, int(arm) + 1):
			draw_rect(Rect2(center + direction * i, Vector2.ONE), SPARKLE)

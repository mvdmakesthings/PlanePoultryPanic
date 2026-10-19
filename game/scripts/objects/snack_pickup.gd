extends Area2D
## A snack lying in the terminal. The player picks it up by walking over it,
## unless their bag is full.

var _bob_time := randf() * TAU

@onready var _sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	_bob_time += delta * 4.0
	_sprite.position.y = -6.0 + roundf(sin(_bob_time))
	for body in get_overlapping_bodies():
		if body is Player and (body as Player).add_snack():
			queue_free()
			return

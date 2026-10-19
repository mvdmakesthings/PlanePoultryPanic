extends Node2D
## The burst of feathers a defeated chicken leaves behind. Plays once.

const FRAMES := 6
const FPS := 12.0

var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	_time += delta
	var frame := int(_time * FPS)
	if frame >= FRAMES:
		queue_free()
		return
	_sprite.frame = frame

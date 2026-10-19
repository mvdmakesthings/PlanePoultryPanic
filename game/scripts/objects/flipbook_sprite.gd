class_name FlipbookSprite
extends Sprite2D
## A sprite that loops through its sheet's frames at a fixed rate, for
## ambient animation like the departure board's flickering statuses.

@export var fps := 3.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	frame = int(_time * fps) % (hframes * vframes)

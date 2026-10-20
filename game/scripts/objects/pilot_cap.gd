class_name PilotCap
extends Node2D
## The hidden Pilot Cap: the mushroom the chickens are growing to fly
## planes themselves. It isn't ripe, so chickens ignore it (it isn't in the
## mushroom_patches group) and it never powers anyone up. Spraying it with
## the fire extinguisher destroys it, which finds its secret.

const GROUNDED_HINT := "You grounded their\nair force!"

@export var secret_id := ""
@export var spore_fps := 3.0

var _anim_time := 0.0
var _destroyed := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if secret_id != "" and GameManager.has_secret(secret_id):
		queue_free()
		return
	add_to_group("pilot_caps")


func _process(delta: float) -> void:
	_anim_time += delta
	_sprite.frame = int(_anim_time * spore_fps) % _sprite.hframes


## Sprayed with the fire extinguisher: gone for good.
func destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	remove_from_group("pilot_caps")
	if secret_id != "":
		GameManager.find_secret(secret_id)
	var level := owner as GameLevel
	if level:
		level.show_event_hint(GROUNDED_HINT)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

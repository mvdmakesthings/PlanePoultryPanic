class_name MushroomPatch
extends Node2D
## A patch of magic mushrooms. A chicken that eats here powers up in the
## patch's mode. Eaten patches dim and regrow after a while.

const VARIETIES: Array[String] = ["flight", "rage", "egg"]
const FRAMES_PER_VARIETY := 3

@export_enum("flight", "rage", "egg") var variety := "rage"
@export var regrow_time := 15.0
@export var spore_fps := 3.0

var is_ripe := true

var _regrow_timer := 0.0
var _anim_time := 0.0
var _destroyed := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("mushroom_patches")


func _process(delta: float) -> void:
	if _destroyed:
		return
	if not is_ripe:
		_regrow_timer -= delta
		if _regrow_timer <= 0.0:
			is_ripe = true
			modulate = Color.WHITE
	_anim_time += delta
	# Only ripe patches puff spores.
	var frame := int(_anim_time * spore_fps) % FRAMES_PER_VARIETY if is_ripe else 0
	_sprite.frame = VARIETIES.find(variety) * FRAMES_PER_VARIETY + frame


## Kills the patch for good (sprayed with the fire extinguisher).
func destroy() -> void:
	remove_from_group("mushroom_patches")
	_destroyed = true
	is_ripe = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


## Returns false if the patch was already eaten.
func eat() -> bool:
	if not is_ripe:
		return false
	is_ripe = false
	_regrow_timer = regrow_time
	modulate = Color(1, 1, 1, 0.45)
	return true

class_name MetalDetector
extends StaticBody2D
## A walk-through metal detector. Its two posts are solid; walking between
## them makes it beep and flash red for a moment. Position this node at the
## middle of the arch's feet.

const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)
const BEEP_TIME := 0.6
## How far away chickens hear it beep.
const NOISE_RANGE := 96.0
## Passes this close together count toward the tune.
const TUNE_WINDOW := 12.0

## A gag: walking through this many times in quick succession plays the
## cluck tune instead of a beep. 0 turns it off.
@export var tune_after := 0

var _beep_left := 0.0
var _passes: Array[float] = []

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _gap: Area2D = $Gap


func _ready() -> void:
	_gap.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_beep_left -= delta
	_sprite.frame = 1 if _beep_left > 0.0 and int(_beep_left * 10.0) % 2 == 0 else 0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Chicken.make_noise(get_tree(), global_position, NOISE_RANGE)
		if _tune_due():
			_beep_left = BEEP_TIME * 3.0
			AudioManager.play("cluck_tune", global_position)
			return
		_beep_left = BEEP_TIME
		AudioManager.play("beep", global_position)


## Counts this pass; true (and starts counting over) on the tune_after-th
## pass in a row.
func _tune_due() -> bool:
	if tune_after <= 0:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	_passes.append(now)
	_passes.assign(_passes.filter(func(t: float) -> bool: return now - t <= TUNE_WINDOW))
	if _passes.size() < tune_after:
		return false
	_passes.clear()
	return true


func _draw() -> void:
	for x: float in [-13.0, 13.0]:
		draw_set_transform(Vector2(x, -1), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 4.0, SHADOW_COLOR)

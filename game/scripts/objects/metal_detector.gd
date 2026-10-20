class_name MetalDetector
extends StaticBody2D
## A walk-through metal detector. Its two posts are solid; walking between
## them makes it beep and flash red for a moment. Position this node at the
## middle of the arch's feet.

const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)
const BEEP_TIME := 0.6

var _beep_left := 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _gap: Area2D = $Gap


func _ready() -> void:
	_gap.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_beep_left -= delta
	_sprite.frame = 1 if _beep_left > 0.0 and int(_beep_left * 10.0) % 2 == 0 else 0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_beep_left = BEEP_TIME
		AudioManager.play("beep", global_position)


func _draw() -> void:
	for x: float in [-13.0, 13.0]:
		draw_set_transform(Vector2(x, -1), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 4.0, SHADOW_COLOR)

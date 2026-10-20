class_name Checkpoint
extends StaticBody2D
## A "YOU ARE HERE" map stand. Walking up to it makes it the checkpoint:
## its screen lights up, the game autosaves, and after a knockout the player
## starts again here. Its base is solid; the player respawns just below it.

signal reached(checkpoint: Checkpoint)

const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)

## Names this checkpoint in the save file; unique within its level.
@export var id := ""
## How close the player must come to reach it.
@export var radius := 24.0

var is_active := false

var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("checkpoints")


## Where the player stands when starting from this checkpoint.
func spawn_point() -> Vector2:
	return global_position + Vector2(0, 14)


## Lights the stand. quiet skips the reached signal, for restoring a save.
func activate(quiet := false) -> void:
	if is_active:
		return
	is_active = true
	if not quiet:
		reached.emit(self)


func _physics_process(delta: float) -> void:
	_time += delta
	# Off, or lit with the "you are here" dot blinking.
	_sprite.frame = 0 if not is_active else 1 + int(_time * 2.0) % 2
	if is_active:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and not player.is_dead and player.global_position.distance_to(global_position) <= radius:
		activate()


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, SHADOW_COLOR)

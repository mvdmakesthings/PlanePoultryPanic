class_name PottedPlant
extends StaticBody2D
## A planter on the terminal floor. The pot is solid, and the plant joins
## the nav_obstacles group so chickens path around it like a wall.

const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)

## Column in potted_plant.png: 0 is the ficus, 1 the snake plant.
@export_enum("ficus", "snake_plant") var variety := 0


func _ready() -> void:
	$Sprite2D.frame = variety


func _draw() -> void:
	# Flat shadow under the pot; the sprite draws on top of it.
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 8.0, SHADOW_COLOR)

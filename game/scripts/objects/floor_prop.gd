class_name FloorProp
extends StaticBody2D
## A solid piece of furniture standing on the floor, like the janitor's
## cart. Its base blocks movement, and it joins the nav_obstacles group so
## chickens path around it like a wall. Draws a flat shadow under itself.

const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)

## Half the shadow's width, in pixels.
@export var shadow_radius := 12.0


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, shadow_radius, SHADOW_COLOR)

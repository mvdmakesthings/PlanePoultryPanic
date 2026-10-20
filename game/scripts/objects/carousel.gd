class_name Carousel
extends Node2D
## Gameplay for a baggage carousel. The ring around the raised island is a
## clockwise belt that carries anything standing or lying on it. Chickens
## carried into the chute are defeated; the player can't fit through it.
##
## The room paints the tiles; this node only knows the carousel's shape.

## How fast the belt carries things, in pixels per second.
@export var belt_speed := 40.0

## Everything inside the outer rim, in world pixels.
var outer: Rect2
## The raised center island. Solid; the belt runs around it.
var island: Rect2
## The chute opening on the back belt.
var chute: Rect2


func _ready() -> void:
	add_to_group("conveyors")


func setup(outer_rect: Rect2, island_rect: Rect2, chute_rect: Rect2) -> void:
	outer = outer_rect
	island = island_rect
	chute = chute_rect


## Belt velocity at a world position, or zero off the belt.
func push_at(pos: Vector2) -> Vector2:
	if not outer.has_point(pos) or island.has_point(pos):
		return Vector2.ZERO
	# Check the side columns first, so each corner turns things onto the next
	# run of the loop instead of carrying them straight off the belt.
	if pos.x < island.position.x:
		return (Vector2.RIGHT if pos.y < island.position.y else Vector2.UP) * belt_speed
	if pos.x >= island.end.x:
		return (Vector2.LEFT if pos.y >= island.end.y else Vector2.DOWN) * belt_speed
	if pos.y < island.position.y:
		return Vector2.RIGHT * belt_speed
	return Vector2.LEFT * belt_speed


## Total belt velocity at a world position from everything in the
## conveyors group (carousels and moving walkways all have push_at()).
static func push_for(tree: SceneTree, pos: Vector2) -> Vector2:
	var total := Vector2.ZERO
	for node in tree.get_nodes_in_group("conveyors"):
		total += node.push_at(pos)
	return total


## True if the position is inside any carousel's chute.
static func in_any_chute(tree: SceneTree, pos: Vector2) -> bool:
	for node in tree.get_nodes_in_group("conveyors"):
		if node is Carousel and (node as Carousel).chute.has_point(pos):
			return true
	return false

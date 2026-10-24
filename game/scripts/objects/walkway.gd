class_name Walkway
extends Node2D
## A moving walkway: a belt two tiles tall between handrails, running east
## or west. It carries anything on it (the player, chickens, snacks), so
## walking with it is faster and against it slower. A SpeedPanel switches
## it between slow, normal and full. At full speed, chickens riding off its
## far end are flung: they tumble, and hitting anything solid while still
## fast knocks them out. You get on and off only at the ends.
##
## Position this node at the belt's top-left corner, outside the level's
## depth-sorted Entities layer so it draws flat on the floor. It draws its
## own tiles from walkway.png (see docs/art-style-guide.md).

enum Speed { SLOW, NORMAL, FULL }

const SHEET := preload("res://assets/sprites/walkway.png")
const TILE := 16
const HEIGHT := 32.0
## Belt speeds in pixels per second.
const SPEEDS := {Speed.SLOW: 20.0, Speed.NORMAL: 45.0, Speed.FULL: 110.0}
## The handrails along the top and bottom edges, in pixels.
const RAIL := 3.0
## The belt slats are 8 px apart and each animation frame moves them 2 px.
const PIXELS_PER_FRAME := 2.0
const FRAMES := 4
## Rows in walkway.png.
const ROW_TOP := 0
const ROW_BOTTOM := 3
## Chickens within this many pixels of the far end get flung at full speed.
const FLING_ZONE := 8.0

@export var length_tiles := 12
## True: runs east (left to right); false: west.
@export var east := true
@export var speed: Speed = Speed.NORMAL
@export var fling_speed := 200.0

var _phase := 0.0
var _rails: Array[RID] = []


func _ready() -> void:
	add_to_group("conveyors")
	add_to_group("walkways")
	var r := belt_rect()
	# Handrails along both long edges, in world space like LockedDoor's walls.
	for rail in [Rect2(r.position, Vector2(r.size.x, RAIL)),
			Rect2(Vector2(r.position.x, r.end.y - RAIL), Vector2(r.size.x, RAIL))]:
		var body := LevelBuilder.add_wall(self, rail)
		body.position = -global_position
		_rails.append(body.get_rid())
	AudioManager.play_loop("walkway_hum", self, r.get_center())


## The whole walkway, rails included, in world space.
func belt_rect() -> Rect2:
	return Rect2(global_position, Vector2(length_tiles * TILE, HEIGHT))


func direction() -> Vector2:
	return Vector2.RIGHT if east else Vector2.LEFT


func belt_speed() -> float:
	return SPEEDS[speed]


## The handrails of every walkway. They're waist high: they block walking
## but not seeing, so sight checks leave them out.
static func rails(tree: SceneTree) -> Array[RID]:
	var out: Array[RID] = []
	for node in tree.get_nodes_in_group("walkways"):
		out.append_array((node as Walkway)._rails)
	return out


## Belt velocity at a world position, or zero off the belt.
func push_at(pos: Vector2) -> Vector2:
	var r := belt_rect().grow_individual(0, -RAIL, 0, -RAIL)
	return direction() * belt_speed() if r.has_point(pos) else Vector2.ZERO


## Steps to the next speed: slow, normal, full, then slow again.
func cycle_speed() -> void:
	speed = ((speed + 1) % Speed.size()) as Speed


func _physics_process(delta: float) -> void:
	_phase += belt_speed() * delta / PIXELS_PER_FRAME
	queue_redraw()
	if speed != Speed.FULL:
		return
	var r := belt_rect()
	var zone_x := r.end.x - FLING_ZONE if east else r.position.x
	var zone := Rect2(Vector2(zone_x, r.position.y), Vector2(FLING_ZONE, r.size.y))
	for node in get_tree().get_nodes_in_group("chickens"):
		var chicken := node as Chicken
		if zone.has_point(chicken.global_position) and not chicken.is_flung() and not chicken.is_hopping():
			chicken.fling(direction() * fling_speed)


func _draw() -> void:
	var frame := int(_phase) % FRAMES
	if not east:
		frame = (FRAMES - frame) % FRAMES
	for i in length_tiles:
		var piece := 0 if i == 0 else 2 if i == length_tiles - 1 else 1
		# The comb plates at the ends don't move; only the belt does.
		for row: int in [ROW_TOP, ROW_BOTTOM]:
			var region := Rect2((frame if piece == 1 else 0) * TILE, (row + piece) * TILE, TILE, TILE)
			var y := 0.0 if row == ROW_TOP else float(TILE)
			draw_texture_rect_region(SHEET, Rect2(i * TILE, y, TILE, TILE), region)

extends Node2D
## One-room prototype (roadmap M1). Answers one question: is sneaking past
## and distracting chickens fun? The room is built in code from the
## Arrivals tileset so the layout is easy to tweak while tuning.

const TILES := preload("res://assets/sprites/tiles_arrivals.png")
const CAROUSEL := preload("res://assets/sprites/carousel.png")
const TILE := 16
const ROOM := Vector2i(30, 20)
## North wall is 4 tiles deep: top, lip, upper face, lower face.
const WALL_ROWS := 4

## Atlas coordinates in tiles_arrivals.png (see docs/art-style-guide.md).
const ATLAS := {
	"carpet_a": Vector2i(0, 0), "carpet_b": Vector2i(1, 0),
	"tile_a": Vector2i(2, 0), "tile_b": Vector2i(3, 0),
	"wood_a": Vector2i(4, 0), "wood_b": Vector2i(5, 0),
	"carpet_shadow": Vector2i(6, 0), "tile_shadow": Vector2i(7, 0), "wood_shadow": Vector2i(0, 1),
	"wall_top": Vector2i(1, 1), "wall_lip": Vector2i(2, 1),
	"wall_face_upper": Vector2i(3, 1), "wall_face_lower": Vector2i(4, 1),
	"wall_edge_right": Vector2i(5, 1), "wall_edge_left": Vector2i(6, 1),
	"wall_edge_bottom": Vector2i(7, 1),
}
## Rows in carousel.png; each row has 4 belt animation frames.
const CAROUSEL_ROWS := {
	"top_left": 0, "top": 1, "top_right": 2,
	"left": 3, "island": 4, "right": 5,
	"bottom_left": 6, "bottom": 7, "bottom_right": 8,
}
## Carousel position and size in tiles.
const CAROUSEL_RECT := Rect2i(3, 9, 8, 4)
## The departure gate the player must reach, in tiles.
const EXIT_RECT := Rect2i(25, 4, 3, 2)
const GATE_COLOR := Color("63c74d")
const GATE_OUTLINE := Color("181425")

var _round_over := false

@onready var _floor: TileMapLayer = $Floor
@onready var _props: TileMapLayer = $Props
@onready var _exit_marker: Node2D = $ExitMarker
@onready var _player: Player = $Entities/Player
@onready var _hud: Hud = $UI/HUD


func _ready() -> void:
	var tile_set := _build_tile_set()
	_floor.tile_set = tile_set
	_props.tile_set = tile_set
	_paint_floor_and_walls()
	_paint_carousel()
	_build_collision()
	_build_exit()

	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM.x * TILE
	camera.limit_bottom = ROOM.y * TILE

	_hud.bind_player(_player)
	_player.died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)

	var floor_source := TileSetAtlasSource.new()
	floor_source.texture = TILES
	floor_source.texture_region_size = Vector2i(TILE, TILE)
	for coords: Vector2i in ATLAS.values():
		floor_source.create_tile(coords)
	tile_set.add_source(floor_source, 0)

	var carousel_source := TileSetAtlasSource.new()
	carousel_source.texture = CAROUSEL
	carousel_source.texture_region_size = Vector2i(TILE, TILE)
	for row: int in CAROUSEL_ROWS.values():
		var coords := Vector2i(0, row)
		carousel_source.create_tile(coords)
		carousel_source.set_tile_animation_frames_count(coords, 4)
		carousel_source.set_tile_animation_speed(coords, 8.0)
	tile_set.add_source(carousel_source, 1)
	return tile_set


func _paint_floor_and_walls() -> void:
	for y in ROOM.y:
		for x in ROOM.x:
			_floor.set_cell(Vector2i(x, y), 0, ATLAS[_tile_name(x, y)])


func _tile_name(x: int, y: int) -> String:
	if x == 0:
		return "wall_edge_right"
	if x == ROOM.x - 1:
		return "wall_edge_left"
	if y == ROOM.y - 1:
		return "wall_edge_bottom"
	if y < WALL_ROWS:
		return ["wall_top", "wall_lip", "wall_face_upper", "wall_face_lower"][y]
	var material := "carpet" if x < 12 else "tile" if x < 20 else "wood"
	if y == WALL_ROWS:
		return material + "_shadow"
	# Mix the two variants so the repetition is harder to spot.
	return material + ("_a" if (x * 7 + y * 3) % 5 < 3 else "_b")


func _paint_carousel() -> void:
	var r := CAROUSEL_RECT
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var vertical := "top" if y == r.position.y else "bottom" if y == r.end.y - 1 else ""
			var horizontal := "left" if x == r.position.x else "right" if x == r.end.x - 1 else ""
			var piece := "island"
			if vertical != "" and horizontal != "":
				piece = vertical + "_" + horizontal
			elif vertical != "" or horizontal != "":
				piece = vertical + horizontal
			_props.set_cell(Vector2i(x, y), 1, Vector2i(0, CAROUSEL_ROWS[piece]))


func _build_collision() -> void:
	var room_px := Vector2(ROOM * TILE)
	_add_wall(Rect2(0, 0, room_px.x, WALL_ROWS * TILE))
	_add_wall(Rect2(0, room_px.y - TILE, room_px.x, TILE))
	_add_wall(Rect2(0, 0, TILE, room_px.y))
	_add_wall(Rect2(room_px.x - TILE, 0, TILE, room_px.y))
	# The carousel's transparent margin (2px at the top and sides) stays walkable.
	var c := Rect2(CAROUSEL_RECT.position * TILE, CAROUSEL_RECT.size * TILE)
	_add_wall(Rect2(c.position + Vector2(2, 4), c.size - Vector2(4, 4)))


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


func _build_exit() -> void:
	var rect := Rect2(EXIT_RECT.position * TILE, EXIT_RECT.size * TILE)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_exit_entered)
	_exit_marker.draw.connect(_draw_exit.bind(rect))
	_exit_marker.queue_redraw()


func _draw_exit(rect: Rect2) -> void:
	# Placeholder gate marker until gate art exists.
	_exit_marker.draw_rect(rect, Color(GATE_COLOR, 0.35))
	_exit_marker.draw_rect(rect, GATE_COLOR, false, 2.0)
	var font := ThemeDB.fallback_font
	var pos := rect.position + Vector2(0, rect.size.y / 2.0 + 3.0)
	_exit_marker.draw_string_outline(font, pos, "GATE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 8, 2, GATE_OUTLINE)
	_exit_marker.draw_string(font, pos, "GATE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 8)


func _on_exit_entered(body: Node2D) -> void:
	if body is Player and not _round_over:
		_round_over = true
		_player.freeze()
		_hud.show_message("YOU MADE YOUR FLIGHT!\nPress R to play again")


func _on_player_died() -> void:
	_round_over = true
	_hud.show_message("GROUNDED.\nPress R to try again")

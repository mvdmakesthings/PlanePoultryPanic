extends Node2D
## One-room prototype (roadmap M1). Answers one question: is sneaking past
## and distracting chickens fun? The room is built in code from the
## Arrivals tileset so the layout is easy to tweak while tuning.

const TILE := LevelBuilder.TILE
const ATLAS := LevelBuilder.ATLAS
const ROOM := Vector2i(30, 20)
## North wall is 4 tiles deep: top, lip, upper face, lower face.
const WALL_ROWS := 4
## Carousel position and size in tiles.
const CAROUSEL_RECT := Rect2i(3, 9, 8, 4)
## Which tile column of the carousel's back belt holds the chute.
const CHUTE_COLUMN := 4

var _round_over := false

@onready var _floor: TileMapLayer = $Floor
@onready var _props: TileMapLayer = $Props
@onready var _gate: GateDoor = $Gate
@onready var _player: Player = $Entities/Player
@onready var _hud: Hud = $UI/HUD


func _ready() -> void:
	var tile_set := LevelBuilder.build_tile_set()
	_floor.tile_set = tile_set
	_props.tile_set = tile_set
	_paint_floor_and_walls()
	LevelBuilder.paint_carousel(_props, CAROUSEL_RECT, CHUTE_COLUMN)
	_build_collision()
	LevelBuilder.build_navigation(self, Rect2(Vector2.ZERO, Vector2(ROOM * TILE)))
	_gate.player_entered.connect(_on_gate_entered)

	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM.x * TILE
	camera.limit_bottom = ROOM.y * TILE

	_hud.bind_player(_player)
	_player.died.connect(_on_player_died)
	AudioManager.play_music("arrivals")


func _unhandled_input(event: InputEvent) -> void:
	if _round_over and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _paint_floor_and_walls() -> void:
	for y in ROOM.y:
		for x in ROOM.x:
			_floor.set_cell(Vector2i(x, y), LevelBuilder.FLOOR_SOURCE, ATLAS[_tile_name(x, y)])


func _tile_name(x: int, y: int) -> String:
	if x == 0:
		return "wall_edge_right"
	if x == ROOM.x - 1:
		return "wall_edge_left"
	if y == ROOM.y - 1:
		return "wall_edge_bottom"
	if y < WALL_ROWS:
		return ["wall_top", "wall_lip", "wall_face_upper", "wall_face_lower"][y]
	var material := "carpet_pattern" if x < 12 else "tile" if x < 20 else "wood"
	if y == WALL_ROWS:
		return material + "_shadow"
	# Mix the two variants so the repetition is harder to spot.
	return material + ("_a" if (x * 7 + y * 3) % 5 < 3 else "_b")


func _build_collision() -> void:
	var room_px := Vector2(ROOM * TILE)
	# The north wall, with a gap the player can walk up into at the gate.
	var wall_bottom := WALL_ROWS * TILE
	var doorway := _gate.doorway_rect()
	_add_wall(Rect2(0, 0, doorway.position.x, wall_bottom))
	_add_wall(Rect2(doorway.end.x, 0, room_px.x - doorway.end.x, wall_bottom))
	_add_wall(Rect2(doorway.position.x, 0, doorway.size.x, doorway.position.y))
	_add_wall(Rect2(0, room_px.y - TILE, room_px.x, TILE))
	_add_wall(Rect2(0, 0, TILE, room_px.y))
	_add_wall(Rect2(room_px.x - TILE, 0, TILE, room_px.y))
	LevelBuilder.add_carousel(self, CAROUSEL_RECT, CHUTE_COLUMN)


func _add_wall(rect: Rect2) -> void:
	LevelBuilder.add_wall(self, rect)


func _on_gate_entered() -> void:
	if not _round_over:
		_round_over = true
		_player.freeze()
		_hud.show_message("YOU MADE YOUR FLIGHT!\nPress R to play again")


func _on_player_died() -> void:
	_round_over = true
	_hud.show_message("GROUNDED.\nPress R to try again")

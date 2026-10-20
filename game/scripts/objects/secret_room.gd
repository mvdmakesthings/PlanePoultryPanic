class_name SecretRoom
extends Node2D
## A hidden room behind a SecretDoor. It's built off to the side of the
## level, far enough from the playable map that the camera never shows it
## from outside, and the door fades the player in and out. Walking down
## into the gap in its bottom wall leads back out.
##
## Position this node (tile-aligned) at the room's top-left. The room is a
## floor of size tiles behind a 4-row back wall (whose face shows murals
## and posters), with 1-tile side walls and a 2-tile gap in the bottom wall.
## Anything placed under this node (pickups, the mural, a Pilot Cap) is in
## room coordinates and drawn over its floor.

const TILE := LevelBuilder.TILE
const BACK_WALL := 4
## The screen size, to center the camera on the room.
const VIEW := Vector2(320, 180)
## What shows around the room on screen.
const DARK := Color("181425")

## The floor area, in tiles.
@export var size := Vector2i(10, 5)
## The floor's map character (see LevelBuilder): "." tile, "," carpet,
## "~" patterned carpet, "=" wood.
@export var floor_char := "."

## The door that leads here (set by the door).
var door: SecretDoor
var rows: PackedStringArray

var _player_inside := false


func _ready() -> void:
	rows = _map_rows()
	var level := owner as GameLevel
	# The level picks its tileset in its own _ready, which runs after ours.
	if level and not level.is_node_ready():
		await level.ready
	var layer := TileMapLayer.new()
	layer.tile_set = LevelBuilder.build_tile_set(level.tiles_texture if level else LevelBuilder.TILES)
	LevelBuilder.paint_map(layer, rows)
	add_child(layer)
	move_child(layer, 0)
	LevelBuilder.add_map_walls(self, rows)


## The room as a text map: back wall, floor, bottom wall with its gap, and
## one more row of wall under the gap.
func _map_rows() -> PackedStringArray:
	var width := size.x + 2
	var out := PackedStringArray()
	for y in BACK_WALL:
		out.append("#".repeat(width))
	for y in size.y:
		out.append("#" + floor_char.repeat(size.x) + "#")
	var gap := _gap_column()
	out.append("#".repeat(gap) + floor_char.repeat(2) + "#".repeat(width - gap - 2))
	out.append("#".repeat(width))
	return out


func _gap_column() -> int:
	return (size.x + 2) / 2 - 1


## Where the player appears on coming in: just inside the gap.
func entry_point() -> Vector2:
	return global_position + Vector2((_gap_column() + 1) * TILE, (BACK_WALL + size.y) * TILE - 6)


## The way out, in world space: the gap in the bottom wall.
func exit_rect() -> Rect2:
	return Rect2(global_position + Vector2(_gap_column() * TILE, (BACK_WALL + size.y) * TILE + 6),
		Vector2(2 * TILE, TILE))


## Camera limits that center the room on screen.
func view_rect() -> Rect2:
	var center := global_position + Vector2(size.x + 2, BACK_WALL + size.y + 2) * TILE / 2.0
	return Rect2(center - VIEW / 2.0, VIEW)


## Called by the door as the player comes in or goes out.
func set_player_inside(inside: bool) -> void:
	_player_inside = inside


func _physics_process(_delta: float) -> void:
	if not _player_inside or door == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and exit_rect().has_point(player.global_position):
		door.leave(player)


func _draw() -> void:
	# Darkness around the room, under its tiles.
	var view := view_rect()
	draw_rect(Rect2(view.position - global_position, view.size).grow(16), DARK)

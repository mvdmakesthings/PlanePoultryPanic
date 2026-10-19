class_name LevelBuilder
extends RefCounted
## Shared pieces for building levels in code from the Arrivals tileset:
## the tile set, carousels, wall collision, and the navigation mesh that
## chickens path on. Used by the prototype room and the real levels.

const TILES := preload("res://assets/sprites/tiles_arrivals.png")
const CAROUSEL := preload("res://assets/sprites/carousel.png")
const TILE := 16
## Source ids in the tile set from build_tile_set().
const FLOOR_SOURCE := 0
const CAROUSEL_SOURCE := 1

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
	"carpet_pattern_a": Vector2i(0, 2), "carpet_pattern_b": Vector2i(1, 2),
	"carpet_pattern_shadow": Vector2i(2, 2),
}
## Rows in carousel.png; each row has 4 belt animation frames.
const CAROUSEL_ROWS := {
	"top_left": 0, "top": 1, "top_right": 2,
	"left": 3, "island": 4, "right": 5,
	"bottom_left": 6, "bottom": 7, "bottom_right": 8, "chute": 9,
}
## Blocks only the player (physics layer 4), so chickens can fall through.
const PLAYER_BLOCKER_LAYER := 8
## Walls and furniture join this group so the navigation mesh routes around them.
const NAV_OBSTACLES := "nav_obstacles"
## Clearance kept between chicken paths and obstacles.
const NAV_AGENT_RADIUS := 6.0


static func build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)

	var floor_source := TileSetAtlasSource.new()
	floor_source.texture = TILES
	floor_source.texture_region_size = Vector2i(TILE, TILE)
	for coords: Vector2i in ATLAS.values():
		floor_source.create_tile(coords)
	tile_set.add_source(floor_source, FLOOR_SOURCE)

	var carousel_source := TileSetAtlasSource.new()
	carousel_source.texture = CAROUSEL
	carousel_source.texture_region_size = Vector2i(TILE, TILE)
	for row: int in CAROUSEL_ROWS.values():
		var coords := Vector2i(0, row)
		carousel_source.create_tile(coords)
		carousel_source.set_tile_animation_frames_count(coords, 4)
		carousel_source.set_tile_animation_speed(coords, 8.0)
	tile_set.add_source(carousel_source, CAROUSEL_SOURCE)
	return tile_set


## Paints a carousel's tiles. rect is in tiles; chute_column is which tile
## column of the back belt holds the chute, counted from the left edge.
static func paint_carousel(layer: TileMapLayer, rect: Rect2i, chute_column: int) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var vertical := "top" if y == rect.position.y else "bottom" if y == rect.end.y - 1 else ""
			var horizontal := "left" if x == rect.position.x else "right" if x == rect.end.x - 1 else ""
			var piece := "island"
			if vertical != "" and horizontal != "":
				piece = vertical + "_" + horizontal
			elif vertical != "" or horizontal != "":
				piece = vertical + horizontal
			if piece == "top" and x == rect.position.x + chute_column:
				piece = "chute"
			layer.set_cell(Vector2i(x, y), CAROUSEL_SOURCE, Vector2i(0, CAROUSEL_ROWS[piece]))


## Adds a carousel's collision and belt to parent. The belt ring is
## walkable; only the raised island is solid. Pixel offsets match the
## carousel tile art (see tools/sprites/carousel.py).
static func add_carousel(parent: Node, rect: Rect2i, chute_column: int) -> Carousel:
	var c := Rect2(rect.position * TILE, rect.size * TILE)
	var outer := Rect2(c.position + Vector2(2, 2), c.size - Vector2(4, 3))
	var island := Rect2(c.position + Vector2(12, 12), c.size - Vector2(24, 23))
	var chute_x := c.position.x + chute_column * TILE
	var chute := Rect2(chute_x + 2, c.position.y + 2, TILE - 4, 10)
	add_wall(parent, island)
	# The player bumps into the chute instead of riding into it.
	add_wall(parent, chute.grow(1), PLAYER_BLOCKER_LAYER)

	var carousel := Carousel.new()
	carousel.setup(outer, island, chute)
	parent.add_child(carousel)
	return carousel


static func add_wall(parent: Node, rect: Rect2, layer := 1) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)
	body.add_to_group(NAV_OBSTACLES)
	parent.add_child(body)
	return body


## Bakes the walkable area inside bounds (world pixels), routed around
## everything in the nav_obstacles group, and adds it to parent.
static func build_navigation(parent: Node, bounds: Rect2) -> NavigationRegion2D:
	var walkable := NavigationPolygon.new()
	walkable.agent_radius = NAV_AGENT_RADIUS
	walkable.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	# Include the chute, so chickens never choose to walk into it. They only
	# fall in when the belt carries them there.
	walkable.parsed_collision_mask = 1 | PLAYER_BLOCKER_LAYER
	walkable.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	walkable.source_geometry_group_name = NAV_OBSTACLES
	walkable.add_outline(PackedVector2Array([
		bounds.position, Vector2(bounds.end.x, bounds.position.y),
		bounds.end, Vector2(bounds.position.x, bounds.end.y),
	]))
	var region := NavigationRegion2D.new()
	region.navigation_polygon = walkable
	parent.add_child(region)
	# Bake synchronously so chickens have paths from their first frame.
	region.bake_navigation_polygon(false)
	return region


# ---------- text maps ----------
# A level's layout can be written as rows of text, one character per tile:
#   #  wall           .  terminal floor tile
#   ,  gray carpet    ~  patterned carpet    =  wood
# Walls pick their own tile from what's around them, so a wall with floor
# below it shows a front face (3/4 view): the lower face, upper face and
# lip stack up from the floor, and any wall at least 4 rows deep looks like
# the north wall. Side and bottom walls show their top edge.

const MAP_FLOORS := {".": "tile", ",": "carpet", "~": "carpet_pattern", "=": "wood"}


static func is_map_wall(rows: PackedStringArray, x: int, y: int) -> bool:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return true
	return rows[y][x] == "#"


## Which tile from ATLAS goes at (x, y) in a text map.
static func map_tile_name(rows: PackedStringArray, x: int, y: int) -> String:
	var wall := func(dx: int, dy: int) -> bool: return is_map_wall(rows, x + dx, y + dy)
	if not wall.call(0, 0):
		var material: String = MAP_FLOORS[rows[y][x]]
		# The first floor row under a wall face lies in its shadow.
		if wall.call(0, -1):
			return material + "_shadow"
		# Mix the two variants so the repetition is harder to spot.
		return material + ("_a" if (x * 7 + y * 3) % 5 < 3 else "_b")
	if not wall.call(0, 1):
		return "wall_face_lower"
	if not wall.call(0, 2):
		return "wall_face_upper"
	if not wall.call(0, 3):
		return "wall_lip"
	if not wall.call(1, 0):
		return "wall_edge_right"
	if not wall.call(-1, 0):
		return "wall_edge_left"
	if not wall.call(0, -1):
		return "wall_edge_bottom"
	return "wall_top"


static func paint_map(layer: TileMapLayer, rows: PackedStringArray) -> void:
	for y in rows.size():
		for x in rows[y].length():
			layer.set_cell(Vector2i(x, y), FLOOR_SOURCE, ATLAS[map_tile_name(rows, x, y)])


## Adds solid collision for every wall tile in a text map, merged into as
## few rectangles as possible. Tiles inside any of the gaps (in tiles) are
## left open, for doors that bring their own collision.
static func add_map_walls(parent: Node, rows: PackedStringArray, gaps: Array[Rect2i] = []) -> void:
	# Runs of wall along each row, merged downward while they line up.
	var open := {}  # Vector2i(start, end) -> Rect2i, for runs in the previous row
	var done: Array[Rect2i] = []
	for y in rows.size() + 1:
		var runs := {}
		var x := 0
		var width := rows[0].length()
		while y < rows.size() and x < width:
			if not _solid(rows, x, y, gaps):
				x += 1
				continue
			var start := x
			while x < width and _solid(rows, x, y, gaps):
				x += 1
			var key := Vector2i(start, x)
			if open.has(key):
				var rect: Rect2i = open[key]
				rect.size.y += 1
				runs[key] = rect
				open.erase(key)
			else:
				runs[key] = Rect2i(start, y, x - start, 1)
		done.append_array(open.values())
		open = runs
	for rect in done:
		add_wall(parent, Rect2(rect.position * TILE, rect.size * TILE))


static func _solid(rows: PackedStringArray, x: int, y: int, gaps: Array[Rect2i]) -> bool:
	if not is_map_wall(rows, x, y):
		return false
	for gap in gaps:
		if gap.has_point(Vector2i(x, y)):
			return false
	return true

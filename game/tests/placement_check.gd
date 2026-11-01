extends Node
## Audits where a level's furniture and wall decor sit, and finds free spots
## on the walls. Prints one line per prop with a problem:
##   godot --headless --path game res://tests/placement_check.tscn -- \
##       --level=res://scenes/levels/level_01_arrivals.tscn [--names=PlantA,AtmA] \
##       [--free="16,16,600,140,GateClock;32,16,700,140"]
##
## Problems it reports:
##   off wall  - wall decor not hung on a wall face (gantries, z_index > 0, hang over floor on purpose)
##   overlaps  - a prop's sprite covers another sprite: decor, a sign, a pickup, litter
##   into wall - a prop's collision base sits inside a wall
##   pocket    - a sliver Amanda can't fit through (her feet are 10px wide, 6px
##               tall) but that looks open: 3-9px sideways, 3-5px front to back.
##               Flush (0-2px) is fine, and so are small gaps inside a row of
##               props, like benches set side by side.
## A prop placed that way on purpose (a bin sitting on a table, graffiti
## scrawled up over the wall's lip) carries metadata/placement_ok = true in
## its scene and is skipped, along with anything it overlaps.
## --names limits the audit to those props. Each --free query is
## "width,height,x,y[,name]": the nearest spots (top-left corners) where a
## sprite that size hangs fully on a wall face without touching other
## sprites. name is a prop to ignore, i.e. the one being moved.

## Sprite overlap below this many square pixels is just touching.
const OVERLAP_SLACK := 12.0
## Gaps narrower than this read as flush.
const POCKET_MIN := 3.0
## Amanda's feet; anything narrower than these she can't walk through.
const PLAYER_SIZE := Vector2(10, 6)
## Gaps up to this wide between two props read as one row.
const ROW_GAP := 4.0
const WALL_FACES := ["wall_face_upper", "wall_face_lower"]
const LAYERS := ["Entities", "WallDecor", "FloorLitter"]

var _rows: PackedStringArray
var _level: GameLevel
## Props placed as they are on purpose (see above).
var _exempt := {}
## [prop name, layer, sprite rect] for every visible sprite.
var _sprites: Array = []
## [prop name, collision rect] for every solid prop in Entities.
var _bodies: Array = []


func _ready() -> void:
	SaveSystem.save_path = "user://placement_save.json"
	SaveSystem.settings_path = "user://placement_settings.cfg"
	GameManager.dry_run = true
	GameManager.pending = {}
	var path := ""
	var names: PackedStringArray = []
	var queries: PackedStringArray = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			path = arg.trim_prefix("--level=")
		elif arg.begins_with("--names="):
			names = arg.trim_prefix("--names=").split(",", false)
		elif arg.begins_with("--free="):
			queries = arg.trim_prefix("--free=").split(";", false)
	_level = load(path).instantiate()
	add_child(_level)
	await get_tree().physics_frame
	await get_tree().process_frame
	_rows = PackedStringArray(_level.map)
	_collect()
	var problems := 0
	for layer in ["Entities", "WallDecor"]:
		for node in _level.get_node(layer).get_children():
			if (names.is_empty() or node.name in names) and not node.has_meta("placement_ok"):
				problems += _audit(node, layer)
	print("PLACEMENT OK" if problems == 0 else "PLACEMENT PROBLEMS: %d" % problems)
	for query in queries:
		_find_free(query.split(","))
	_level.queue_free()
	await get_tree().process_frame
	await AudioManager.silence()
	get_tree().quit()


func _collect() -> void:
	for sprite: Sprite2D in _level.find_children("*", "Sprite2D", true, false):
		if not sprite.is_visible_in_tree():
			continue
		var top: Node = sprite
		while top.get_parent() != _level and top.get_parent().name not in LAYERS:
			top = top.get_parent()
		# Characters wander, so where they start doesn't matter here.
		if top is CharacterBody2D:
			continue
		if top.has_meta("placement_ok"):
			_exempt[top.name] = true
		var layer: String = top.get_parent().name if top.get_parent() != _level else ""
		_sprites.append([top.name, layer, sprite.get_global_transform() * sprite.get_rect()])
	for body in _level.get_node("Entities").get_children():
		if not body is StaticBody2D:
			continue
		for shape in body.find_children("*", "CollisionShape2D", false, false):
			if shape.shape is RectangleShape2D:
				var size: Vector2 = shape.shape.size * shape.global_scale.abs()
				_bodies.append([body.name, Rect2(shape.global_position - size / 2, size)])


## Prints the prop's problems, if any, and returns how many it has.
func _audit(node: Node, layer: String) -> int:
	var found := {}
	for mine in _sprites.filter(func(entry): return entry[0] == node.name):
		var rect: Rect2 = mine[2]
		if layer == "WallDecor" and node.z_index <= 0:
			for tile in _tiles_under(rect):
				var tile_name := LevelBuilder.map_tile_name(_rows, tile.x, tile.y)
				if tile_name not in WALL_FACES:
					found["off wall (%s at tile %d,%d)" % [tile_name, tile.x, tile.y]] = true
		for other in _sprites:
			if other[0] == node.name or other[0] in _exempt or (layer != "Entities" and other[1] == "FloorLitter"):
				continue
			var area: float = rect.intersection(other[2]).get_area()
			if area >= OVERLAP_SLACK:
				found["overlaps %s (%dpx²)" % [other[0], area]] = true
	for mine in _bodies.filter(func(entry): return entry[0] == node.name):
		var rect: Rect2 = mine[1]
		for other in _bodies + _walls_near(rect):
			if other[0] == node.name:
				continue
			var other_rect: Rect2 = other[1]
			if other_rect.intersects(rect):
				if other[0] == "wall":
					found["into wall"] = true
				continue
			var gap_x: float = maxf(other_rect.position.x - rect.end.x, rect.position.x - other_rect.end.x)
			var gap_y: float = maxf(other_rect.position.y - rect.end.y, rect.position.y - other_rect.end.y)
			# Only gaps the two rects face each other across.
			if minf(gap_x, gap_y) >= 0:
				continue
			var sideways := gap_x > 0
			var gap := gap_x if sideways else gap_y
			var fits: float = PLAYER_SIZE.x if sideways else PLAYER_SIZE.y
			var smallest := POCKET_MIN if other[0] == "wall" else ROW_GAP + 1
			if gap >= smallest and gap < fits:
				found["pocket %dpx %s to %s" % [gap, "sideways" if sideways else "front to back", other[0]]] = true
	if not found.is_empty():
		var at: Vector2 = node.global_position
		print("  %-22s %-9s (%d, %d)  %s" % [node.name, layer, at.x, at.y, "; ".join(found.keys())])
	return found.size()


func _find_free(query: PackedStringArray) -> void:
	var size := Vector2(int(query[0]), int(query[1]))
	var target := Vector2(int(query[2]), int(query[3]))
	var ignore := query[4] if query.size() > 4 else ""
	var spots := []
	var bounds := Vector2(_rows[0].length(), _rows.size()) * LevelBuilder.TILE - size
	for y in int(bounds.y):
		for x in range(0, int(bounds.x), 4):
			var rect := Rect2(Vector2(x, y), size)
			if not _tiles_under(rect).all(func(tile: Vector2i) -> bool:
					return LevelBuilder.map_tile_name(_rows, tile.x, tile.y) in WALL_FACES):
				continue
			if _sprites.any(func(entry) -> bool: return entry[0] != ignore and rect.grow(2).intersects(entry[2])):
				continue
			spots.append(rect.position)
	spots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(target) < b.distance_to(target))
	print("free %dx%d near (%d, %d): %s" % [size.x, size.y, target.x, target.y, spots.slice(0, 6)])


## Tiles the rect covers by more than a sliver.
func _tiles_under(rect: Rect2) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var tile := LevelBuilder.TILE
	for y in range(floori(rect.position.y / tile), ceili(rect.end.y / tile)):
		for x in range(floori(rect.position.x / tile), ceili(rect.end.x / tile)):
			if Rect2(x * tile, y * tile, tile, tile).intersection(rect).get_area() >= 8:
				tiles.append(Vector2i(x, y))
	return tiles


func _walls_near(rect: Rect2) -> Array:
	var walls := []
	var tile := LevelBuilder.TILE
	for y in range(floori(rect.position.y / tile) - 1, floori(rect.end.y / tile) + 2):
		for x in range(floori(rect.position.x / tile) - 1, floori(rect.end.x / tile) + 2):
			if LevelBuilder.is_map_wall(_rows, x, y):
				walls.append(["wall", Rect2(x * tile, y * tile, tile, tile)])
	return walls

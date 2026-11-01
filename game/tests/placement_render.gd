extends Node
## Renders a whole level, every room at once, to a PNG for checking where
## furniture and wall decor sit. With --mark it outlines each prop's
## collision base in red and labels everything in Entities with its name:
##   godot --path game res://tests/placement_render.tscn -- \
##       --level=res://scenes/levels/level_01_arrivals.tscn --out=/tmp/l1.png [--mark]
## Needs a window (not --headless) so the level actually draws.
## tools/placement/render.sh wraps this and slices the result into panels.

const MARK_COLOR := Color(1, 0, 0, 0.8)
const LABEL_COLOR := Color(1, 1, 0)


func _ready() -> void:
	SaveSystem.save_path = "user://placement_save.json"
	SaveSystem.settings_path = "user://placement_settings.cfg"
	GameManager.dry_run = true
	GameManager.pending = {}
	var path := ""
	var out := "user://placement.png"
	var mark := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			path = arg.trim_prefix("--level=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg == "--mark":
			mark = true
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var level: GameLevel = load(path).instantiate()
	viewport.add_child(level)
	await get_tree().physics_frame
	await get_tree().process_frame
	viewport.size = Vector2i(level.map[0].length(), level.map.size()) * LevelBuilder.TILE
	if level.has_node("UI"):
		level.get_node("UI").visible = false
	for camera in level.find_children("*", "Camera2D", true, false):
		camera.enabled = false
	var camera := Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	level.add_child(camera)
	camera.make_current()
	if mark:
		var overlay := Node2D.new()
		overlay.z_index = 4000
		overlay.draw.connect(_draw_marks.bind(overlay, level))
		level.add_child(overlay)
	# Let flipbooks, belts and shadows settle before the snapshot.
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(out)
	level.queue_free()
	await get_tree().process_frame
	await AudioManager.silence()
	get_tree().quit()


func _draw_marks(overlay: Node2D, level: GameLevel) -> void:
	var entities := level.get_node("Entities")
	for body in entities.get_children():
		if not body is StaticBody2D:
			continue
		for shape in body.find_children("*", "CollisionShape2D", false, false):
			if shape.shape is RectangleShape2D:
				var size: Vector2 = shape.shape.size
				overlay.draw_rect(Rect2(shape.global_position - size / 2, size), MARK_COLOR, false, 1.0)
	for node in entities.get_children():
		if node is Node2D:
			overlay.draw_string(ThemeDB.fallback_font, node.global_position + Vector2(-8, 8),
				node.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, LABEL_COLOR)

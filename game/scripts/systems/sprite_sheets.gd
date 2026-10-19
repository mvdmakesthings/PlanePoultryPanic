class_name SpriteSheets
extends RefCounted
## Turns sprite sheets from tools/sprites into SpriteFrames animations.
##
## Sheets use one row per direction (down, up, right, left) and one column
## per frame, so each sheet becomes four animations named
## "<name>_down", "<name>_up", "<name>_right", and "<name>_left".

const DIRECTIONS: Array[String] = ["down", "up", "right", "left"]


static func add_directional(frames: SpriteFrames, anim_name: String, sheet: Texture2D,
		frame_size: Vector2i, fps: float, loop := true) -> void:
	var frame_count := sheet.get_width() / frame_size.x
	for row in DIRECTIONS.size():
		var animation := "%s_%s" % [anim_name, DIRECTIONS[row]]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, fps)
		frames.set_animation_loop(animation, loop)
		for column in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(column * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
			frames.add_frame(animation, atlas)


## Picks the sheet row for a movement or facing vector.
static func direction_name(vector: Vector2) -> String:
	if absf(vector.x) > absf(vector.y):
		return "right" if vector.x > 0.0 else "left"
	return "down" if vector.y >= 0.0 else "up"

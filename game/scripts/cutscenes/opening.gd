extends Node2D
## The opening cutscene, played after New Game: Amanda at her cancelled
## gate in the arrival lounge, day 4 of her layover. Her flight flips to
## CANCELLED on the departure board, her boarding pass gets stamped EXPIRED,
## chickens run the tarmac outside (one squawks at her through the glass),
## and the PA announces the last flight out. Then she runs for it and
## Level 1 starts. The mushroom lore runs in the background: a news ticker
## crawls under the departure board, and out on the tarmac a chicken pecks
## at a glowing patch beside a leaking fuel drum.
##
## Everything happens on a timeline of beats (BEATS, in seconds). Confirm,
## Back or Pause skips straight to Level 1.

signal finished

const BACKDROP := preload("res://assets/sprites/opening_backdrop.png")
const TARMAC := preload("res://assets/sprites/opening_tarmac.png")
const BOARDING_PASS := preload("res://assets/sprites/opening_boarding_pass.png")
const TILES := preload("res://assets/sprites/tiles_arrivals.png")
const SEATING := preload("res://assets/sprites/seating.png")
const SUITCASE := preload("res://assets/sprites/suitcase.png")
const SNACK := preload("res://assets/sprites/item_snack.png")
const LITTER := preload("res://assets/sprites/floor_litter.png")
const PLANT := preload("res://assets/sprites/potted_plant.png")
const PLAYER_IDLE := preload("res://assets/sprites/player_idle.png")
const PLAYER_RUN := preload("res://assets/sprites/player_run.png")
const PLAYER_HURT := preload("res://assets/sprites/player_hurt.png")
const PLAYER_THROW := preload("res://assets/sprites/player_throw.png")
const CHICKEN_WALK := preload("res://assets/sprites/chicken_walk.png")
const CHICKEN_IDLE := preload("res://assets/sprites/chicken_idle.png")
const CHICKEN_CHASE := preload("res://assets/sprites/chicken_chase.png")
const CHICKEN_FLIGHT := preload("res://assets/sprites/chicken_flight_walk.png")
const MUSHROOMS := preload("res://assets/sprites/mushroom_patch.png")
const FUEL_DRUM := preload("res://assets/sprites/fuel_drum.png")

## The window glass in opening_backdrop.png, where the tarmac shows through.
const GLASS := Rect2(11, 15, 162, 57)
## Where the departure board hangs on the backdrop.
const BOARD := Rect2(184, 12, 129, 61)
const FLOOR_TOP := 96
const SHADOW := Color(0.094, 0.078, 0.145, 0.4)

## Amanda stands at the window, then runs off to the right.
const AMANDA_AT := Vector2(100, 102)
const RUN_SPEED := 120.0

## Departure board columns, in characters, and each character's cell.
const DEST_CHARS := 9
const STATUS_CHARS := 9
const CELL := 6.0
const BOARD_ROW_HEIGHT := 9.0
## A flipping board row settles one letter at a time, this far apart.
const FLAP_STEP := 0.07
const FLAP_SPIN := 0.2
const FLAP_CHARS := "ABCDEFGHIJKLMNOPRSTUVWXYZ#?*%&"
const GREEN := Color("63c74d")

## The news ticker under the departure board, crawling left.
const TICKER := Rect2(184, 76, 129, 10)
const TICKER_TEXT := "...GLOWING MUSHROOMS FOUND NEAR RUNWAY 2...     EXPERTS \"NOT WORRIED\"...     EXPERTS NOW WORRIED...     "
const TICKER_SPEED := 28.0

## The PA panel along the bottom of the screen.
const PANEL := Rect2(12, 130, 228, 44)
const TYPE_SPEED := 32.0

## The beats: [seconds, method]. Each runs once when its time comes.
const BEATS := [
	[0.3, "_show_caption"],
	[3.4, "_hide_panel"],
	[3.8, "_cancel_home"],
	[5.6, "_cancel_the_rest"],
	[8.0, "_turn_around"],
	[8.6, "_hold_up_pass"],
	[10.2, "_stamp_pass"],
	[12.4, "_put_pass_away"],
	[12.8, "_fly_by"],
	[15.6, "_chicken_at_glass"],
	[16.3, "_recover"],
	[17.2, "_chicken_drops"],
	[17.8, "_pa_chime"],
	[18.8, "_announce_last_flight"],
	[21.0, "_board_last_flight"],
	[24.6, "_announce_sealing"],
	[27.4, "_announce_bawk"],
	[29.4, "_hide_panel"],
	[29.6, "_run_for_it"],
	[31.6, "_finish"],
]

## Board rows: destination, status, and status color. Flips change them.
var board_rows: Array[Dictionary] = []
## What the PA panel shows: a title and the full text being typed out.
var panel_title := ""
var panel_text := ""
var panel_visible := false
var pass_expired := false
var skipped := false

var _time := 0.0
var _next_beat := 0
var _done := false
var _typed := 0.0
var _outside: Control
var _ticker: Control
var _glow: Sprite2D
var _board_layer: Node2D
var _front: Node2D
var _amanda: AnimatedSprite2D
var _pass: Sprite2D
var _glass_chicken: AnimatedSprite2D
var _flyer: AnimatedSprite2D
var _wanderer: AnimatedSprite2D
var _running := false
var _flash_last_flight := false
var _shake := 0.0


func _ready() -> void:
	AudioManager.stop_music()
	var frames := _sprite_frames()
	_build_outside(frames)
	var backdrop := Sprite2D.new()
	backdrop.texture = BACKDROP
	backdrop.centered = false
	add_child(backdrop)
	_board_layer = Node2D.new()
	_board_layer.draw.connect(_draw_board)
	add_child(_board_layer)
	_ticker = Control.new()
	_ticker.position = TICKER.position
	_ticker.size = TICKER.size
	_ticker.clip_contents = true
	_ticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker.draw.connect(_draw_ticker)
	add_child(_ticker)
	_build_props()
	_amanda = _animated(frames, Vector2(0, -16), "idle_up")
	_amanda.position = AMANDA_AT
	_amanda.speed_scale = 0.5
	_pass = Sprite2D.new()
	_pass.texture = BOARDING_PASS
	_pass.hframes = 2
	_pass.visible = false
	add_child(_pass)
	_front = Node2D.new()
	_front.draw.connect(_draw_front)
	add_child(_front)

	board_rows = [
		{"dest": "HOME", "status": "ON TIME", "color": GREEN},
		{"dest": "HENVER", "status": "DELAYED", "color": BoardMenu.STATUS},
		{"dest": "CLUCKLAND", "status": "CANCELLED", "color": BoardMenu.CANCELLED},
		{"dest": "EGGSETER", "status": "BOARDING", "color": GREEN},
		{"dest": "", "status": "", "color": BoardMenu.STATUS},
	]
	for row in board_rows:
		row["from"] = row["status"]
		row["start"] = -1.0


func _sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpriteSheets.add_directional(frames, "idle", PLAYER_IDLE, Vector2i(16, 32), 2.0)
	SpriteSheets.add_directional(frames, "run", PLAYER_RUN, Vector2i(16, 32), 14.0)
	SpriteSheets.add_directional(frames, "hurt", PLAYER_HURT, Vector2i(16, 32), 1.0)
	SpriteSheets.add_directional(frames, "throw", PLAYER_THROW, Vector2i(16, 32), 10.0, false)
	SpriteSheets.add_directional(frames, "walk", CHICKEN_WALK, Vector2i(16, 16), 8.0)
	SpriteSheets.add_directional(frames, "peck", CHICKEN_IDLE, Vector2i(16, 16), 4.0)
	SpriteSheets.add_directional(frames, "chase", CHICKEN_CHASE, Vector2i(16, 16), 12.0)
	SpriteSheets.add_directional(frames, "flight", CHICKEN_FLIGHT, Vector2i(16, 16), 8.0)
	return frames


func _animated(frames: SpriteFrames, offset: Vector2, anim: String, parent: Node = self) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.offset = offset
	sprite.play(anim)
	parent.add_child(sprite)
	return sprite


## The view through the window, clipped to the glass: the tarmac and the
## chickens out on it.
func _build_outside(frames: SpriteFrames) -> void:
	_outside = Control.new()
	_outside.position = GLASS.position
	_outside.size = GLASS.size
	_outside.clip_contents = true
	_outside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_outside)
	var tarmac := Sprite2D.new()
	tarmac.texture = TARMAC
	tarmac.centered = false
	_outside.add_child(tarmac)
	# A leaking fuel drum, and the glowing patch that's sprouted beside it.
	var drum := Sprite2D.new()
	drum.texture = FUEL_DRUM
	drum.hframes = 2
	drum.position = Vector2(38, 34)
	_outside.add_child(drum)
	_glow = Sprite2D.new()
	_glow.texture = MUSHROOMS
	_glow.hframes = 3
	_glow.vframes = 3
	_glow.position = Vector2(60, 40)
	_outside.add_child(_glow)
	# One pecks at the plane's landing gear, one strolls the taxiway, and
	# one pecks at the glowing patch.
	var pecker := _animated(frames, Vector2(0, -8), "peck_left", _outside)
	pecker.position = Vector2(124, 34)
	_wanderer = _animated(frames, Vector2(0, -8), "walk_right", _outside)
	_wanderer.position = Vector2(14, 50)
	var sitter := _animated(frames, Vector2(0, -8), "peck_down", _outside)
	sitter.position = Vector2(56, 40)
	sitter.frame = 1
	_flyer = _animated(frames, Vector2(0, -8), "flight_left", _outside)
	_flyer.position = Vector2(GLASS.size.x + 12, 14)
	_flyer.visible = false
	_glass_chicken = _animated(frames, Vector2(0, -8), "chase_down", _outside)
	_glass_chicken.position = Vector2(136, GLASS.size.y + 18)


## Amanda's camp from four days of waiting, and the lounge's seats.
func _build_props() -> void:
	var props := [
		[SEATING, Rect2(0, 0, 48, 24), Vector2(196, 104)],
		[SEATING, Rect2(0, 0, 48, 24), Vector2(252, 104)],
		[PLANT, Rect2(0, 0, 16, 24), Vector2(178, 98)],
		[SUITCASE, Rect2(0, 0, 14, 16), Vector2(42, 92)],
		[SNACK, Rect2(0, 0, 10, 12), Vector2(60, 98)],
		[LITTER, Rect2(0, 0, 16, 16), Vector2(150, 132)],
		[LITTER, Rect2(16, 0, 16, 16), Vector2(64, 140)],
	]
	for prop in props:
		var sprite := Sprite2D.new()
		sprite.texture = prop[0]
		sprite.region_enabled = true
		sprite.region_rect = prop[1]
		sprite.centered = false
		sprite.position = prop[2]
		add_child(sprite)


func _unhandled_input(event: InputEvent) -> void:
	if _done or event.is_echo():
		return
	for action: String in ["ui_accept", "ui_cancel", "pause"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			skip()
			return


## Skips the rest of the scene and goes on to Level 1.
func skip() -> void:
	if _done:
		return
	skipped = true
	AudioManager.play("ui_confirm")
	_finish()


func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	while _next_beat < BEATS.size() and _time >= BEATS[_next_beat][0]:
		var method: String = BEATS[_next_beat][1]
		_next_beat += 1
		call(method)
		if _done:
			return
	_update_flaps()
	_glow.frame = int(_time * 3.0) % 3
	_ticker.queue_redraw()
	_typed += delta * TYPE_SPEED
	# The chicken on the taxiway strolls back and forth.
	var dir := 1.0 if _wanderer.animation == "walk_right" else -1.0
	_wanderer.position.x += dir * 14.0 * delta
	if _wanderer.position.x > 92.0:
		_wanderer.play("walk_left")
	elif _wanderer.position.x < 10.0:
		_wanderer.play("walk_right")
	if _flyer.visible:
		_flyer.position.x -= 60.0 * delta
		_flyer.position.y = 14.0 + roundf(sin(_time * 6.0) * 2.0)
	if _running:
		_amanda.position.x += RUN_SPEED * delta
	if _shake > 0.0:
		_shake -= delta
		position = Vector2(randi_range(-1, 1), randi_range(-1, 1)) if _shake > 0.0 else Vector2.ZERO
	queue_redraw()
	_board_layer.queue_redraw()
	_front.queue_redraw()


# --- Beats ---------------------------------------------------------------

func _show_caption() -> void:
	_show_panel("GATE A3", "LAYOVER: DAY 4")


func _hide_panel() -> void:
	panel_visible = false


func _cancel_home() -> void:
	flip_row(0, "CANCELLED", BoardMenu.CANCELLED)


func _cancel_the_rest() -> void:
	flip_row(1, "CANCELLED", BoardMenu.CANCELLED)
	flip_row(3, "FOWL", BoardMenu.TITLE, 0.5)


func _turn_around() -> void:
	_amanda.play("idle_down")


func _hold_up_pass() -> void:
	# Arm up, pass in hand; the close-up pops up from the bottom.
	_amanda.animation = "throw_down"
	_amanda.frame = 0
	_amanda.stop()
	_pass.frame = 0
	_pass.visible = true
	_pass.position = Vector2(128, 220)
	var tween := create_tween()
	tween.tween_property(_pass, "position", Vector2(128, 44), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play("pickup")


func _stamp_pass() -> void:
	pass_expired = true
	_pass.frame = 1
	_shake = 0.2
	AudioManager.play("stamp")


func _put_pass_away() -> void:
	var tween := create_tween()
	tween.tween_property(_pass, "position", Vector2(128, 220), 0.3).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _pass.visible = false)
	_amanda.play("idle_down")


func _fly_by() -> void:
	_flyer.visible = true


func _chicken_at_glass() -> void:
	var tween := create_tween()
	tween.tween_property(_glass_chicken, "position:y", GLASS.size.y + 2.0, 0.15)
	AudioManager.play("cluck")
	_amanda.play("hurt_right")
	_amanda.position.x -= 2.0


func _recover() -> void:
	_amanda.position.x = AMANDA_AT.x
	_amanda.play("idle_right")


func _chicken_drops() -> void:
	var tween := create_tween()
	tween.tween_property(_glass_chicken, "position:y", GLASS.size.y + 18.0, 0.4)


func _pa_chime() -> void:
	AudioManager.play("pa_chime")
	_amanda.play("idle_down")


func _announce_last_flight() -> void:
	_show_panel("ANNOUNCEMENT", "ATTENTION PASSENGERS. THE LAST FLIGHT\nOUT OF BAWKSTON IS NOW BOARDING\nAT GATE C13.")


func _board_last_flight() -> void:
	board_rows[4]["dest"] = "LAST FLT"
	flip_row(4, "GATE C13", GREEN)
	_flash_last_flight = true


func _announce_sealing() -> void:
	_show_panel("ANNOUNCEMENT", "AFTER DEPARTURE THE AIRPORT\nWILL BE SEALED. DO NOT MISS IT.")


func _announce_bawk() -> void:
	panel_text += "\n...BAWK."


func _run_for_it() -> void:
	_amanda.speed_scale = 1.0
	_amanda.play("run_right")
	_running = true


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	GameManager.start_first_level()


# --- The departure board -------------------------------------------------

## Flips a board row's status to new text, letter by letter.
func flip_row(index: int, status: String, color: Color, delay := 0.0) -> void:
	var row := board_rows[index]
	row["from"] = row["status"]
	row["status"] = status
	row["color"] = color
	row["start"] = _time + delay


## The text a row shows right now, mid-flip or settled.
func row_status(index: int) -> String:
	var row := board_rows[index]
	var start: float = row["start"]
	var target: String = row["status"]
	if start < 0.0 or _time >= _settle_time(start, STATUS_CHARS - 1):
		if _flash_last_flight and index == 4 and int(_time * 1.5) % 2 == 1:
			return "BOARDING"
		return target
	var shown := ""
	for i in STATUS_CHARS:
		if _time < start:
			shown += _char(row["from"], i)
		elif _time >= _settle_time(start, i):
			shown += _char(target, i)
		else:
			shown += FLAP_CHARS[(i * 7 + int(_time * 30.0)) % FLAP_CHARS.length()]
	return shown.strip_edges(false, true)


func _settle_time(start: float, index: int) -> float:
	return start + FLAP_SPIN + index * FLAP_STEP


func _char(text: String, index: int) -> String:
	return text[index] if index < text.length() else " "


## Clacks once for each letter that settles this frame.
func _update_flaps() -> void:
	for row in board_rows:
		var start: float = row["start"]
		if start < 0.0:
			continue
		var settled := 0
		for i in STATUS_CHARS:
			if _time >= _settle_time(start, i):
				settled += 1
		if settled > row.get("clacked", 0):
			row["clacked"] = settled
			AudioManager.play("flap")


func _draw_board() -> void:
	var font := ThemeDB.fallback_font
	var canvas := _board_layer
	canvas.draw_rect(BOARD.grow(1), BoardMenu.BACK)
	canvas.draw_rect(BOARD, BoardMenu.BEZEL)
	canvas.draw_rect(Rect2(BOARD.position, Vector2(BOARD.size.x, 1)), BoardMenu.BEZEL_LIGHT)
	var inner := BOARD.grow(-2)
	canvas.draw_rect(inner, BoardMenu.BACK)
	canvas.draw_string(font, Vector2(inner.position.x, inner.position.y + 9), "DEPARTURES",
		HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, BoardMenu.FONT_SIZE, BoardMenu.TITLE)
	canvas.draw_rect(Rect2(inner.position + Vector2(3, 11), Vector2(inner.size.x - 6, 1)), BoardMenu.DIVIDER)
	for i in board_rows.size():
		var y := inner.position.y + 20.0 + i * BOARD_ROW_HEIGHT
		var x := inner.position.x + 3.0
		_draw_cells(canvas, font, Vector2(x, y), board_rows[i]["dest"], BoardMenu.LABEL)
		var status := row_status(i)
		var color: Color = board_rows[i]["color"]
		if status != board_rows[i]["status"] and status != "BOARDING":
			color = BoardMenu.STATUS
		_draw_cells(canvas, font, Vector2(x + (DEST_CHARS + 1) * CELL, y), status, color)


## Draws text one letter per fixed-width cell, like split-flap modules.
func _draw_cells(canvas: CanvasItem, font: Font, pos: Vector2, text: String, color: Color) -> void:
	for i in text.length():
		# Centered by hand: a width limit would drop letters wider than a cell.
		var width := font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, BoardMenu.FONT_SIZE).x
		canvas.draw_string(font, Vector2(pos.x + i * CELL + roundf((CELL - width) / 2.0), pos.y), text[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, BoardMenu.FONT_SIZE, color)


## The news ticker: the mushroom story, crawling past on a loop.
func _draw_ticker() -> void:
	var font := ThemeDB.fallback_font
	_ticker.draw_rect(Rect2(Vector2.ZERO, TICKER.size), BoardMenu.BACK)
	var width := font.get_string_size(TICKER_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, BoardMenu.FONT_SIZE).x
	var x := -fmod(_time * TICKER_SPEED, width) + TICKER.size.x
	for i in 2:
		_ticker.draw_string(font, Vector2(roundf(x - width + i * width), 8), TICKER_TEXT,
			HORIZONTAL_ALIGNMENT_LEFT, -1, BoardMenu.FONT_SIZE, BoardMenu.STATUS)


# --- The PA panel and the skip hint ---------------------------------------

func _show_panel(title: String, text: String) -> void:
	panel_title = title
	panel_text = text
	panel_visible = true
	_typed = 0.0


## The panel's text as far as it's been typed out.
func typed_text() -> String:
	return panel_text.substr(0, int(_typed))


func _draw_front() -> void:
	var font := ThemeDB.fallback_font
	var canvas := _front
	if panel_visible:
		canvas.draw_rect(PANEL.grow(3), BoardMenu.BACK)
		canvas.draw_rect(PANEL.grow(2), BoardMenu.BEZEL)
		canvas.draw_rect(Rect2(PANEL.position - Vector2(2, 2), Vector2(PANEL.size.x + 4, 1)), BoardMenu.BEZEL_LIGHT)
		canvas.draw_rect(PANEL, BoardMenu.BACK)
		canvas.draw_string(font, PANEL.position + Vector2(6, 9), panel_title, HORIZONTAL_ALIGNMENT_LEFT, -1,
			BoardMenu.FONT_SIZE, BoardMenu.TITLE)
		canvas.draw_rect(Rect2(PANEL.position + Vector2(4, 11), Vector2(PANEL.size.x - 8, 1)), BoardMenu.DIVIDER)
		var lines := typed_text().split("\n")
		for i in lines.size():
			canvas.draw_string(font, PANEL.position + Vector2(6, 20 + i * 9), lines[i], HORIZONTAL_ALIGNMENT_LEFT,
				-1, BoardMenu.FONT_SIZE, BoardMenu.LABEL)
	var hint := "{ui_accept} SKIP"
	var width := ButtonGlyphs.width(font, hint)
	canvas.draw_rect(Rect2(312 - width, 162, width + 6, 14), BoardMenu.BACK)
	ButtonGlyphs.draw(canvas, font, Vector2(315 - width, 172), hint, BoardMenu.LABEL)


# --- The floor and shadows -----------------------------------------------

func _draw() -> void:
	for y in range(FLOOR_TOP, 180, 16):
		for x in range(0, 320, 16):
			var tile := Vector2(2, 2) if y == FLOOR_TOP else Vector2((x / 16 + y / 16) % 2, 2)
			draw_texture_rect_region(TILES, Rect2(x, y, 16, 16), Rect2(tile * 16, Vector2(16, 16)))
	draw_set_transform(_amanda.position, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, SHADOW)
	draw_set_transform(Vector2.ZERO)

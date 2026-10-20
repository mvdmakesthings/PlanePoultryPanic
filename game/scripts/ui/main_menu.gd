extends Control
## The main menu: the title on a departure-board sign, the menu as a board
## of "flights" (New Game, Continue, Settings, Quit), and a looping scene
## along the floor of the passenger running from a few chickens. Once a
## run has been finished, the best score shows under the board.

const TILES := preload("res://assets/sprites/tiles_arrivals.png")
const PLAYER_RUN := preload("res://assets/sprites/player_run.png")
const CHICKEN_WALK := preload("res://assets/sprites/chicken_walk.png")
const TITLE := "PLANE POULTRY PANIC"
const TAGLINE := "THE LAST FLIGHT OUT IS BOARDING"
const SIGN := Rect2(36, 6, 248, 40)
## The chase runs right to left along the floor at this speed, then loops.
const CHASE_SPEED := 70.0
const CHASE_FLOOR_Y := 178.0
## Who's in the chase and how far behind the passenger each one runs.
const CHASERS := [34.0, 52.0, 76.0]
## Where the best score line sits.
const BEST_Y := 149.0

var _board: BoardMenu
var _settings: SettingsMenu
var _chase: Array[AnimatedSprite2D] = []
var _chase_x := 340.0
var _confirm_new_game := false
## The best score and fastest finish, or {} before any finished run.
var best: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AudioManager.stop_music()
	best = SaveSystem.load_best()
	_build_chase()
	_board = BoardMenu.new()
	_board.panel_top = 56.0
	_board.title = "DEPARTURES"
	_board.footer = "{ui_accept} SELECT"
	add_child(_board)
	_board.chosen.connect(_on_chosen)
	_board.cancelled.connect(func() -> void: _set_new_game_confirm(false))
	_settings = SettingsMenu.new()
	add_child(_settings)
	_settings.closed.connect(_open_board)
	_open_board()


func _open_board() -> void:
	_confirm_new_game = false
	_refresh()
	_board.open()


func _refresh() -> void:
	var has_save := SaveSystem.has_save()
	var rows: Array[Dictionary] = [
		{"id": "new_game", "label": "NEW GAME", "kind": "button",
			"status": "OVERWRITE SAVE?" if _confirm_new_game else "BOARDING"},
		{"id": "continue", "label": "CONTINUE", "kind": "button",
			"status": "ON TIME" if has_save else "CANCELLED", "disabled": not has_save},
		{"id": "settings", "label": "SETTINGS", "kind": "button", "status": ">"},
		{"id": "quit", "label": "QUIT", "kind": "button", "status": "LAST CALL"},
	]
	_board.set_items(rows)


func _set_new_game_confirm(on: bool) -> void:
	_confirm_new_game = on
	_refresh()


func _on_chosen(id: String) -> void:
	match id:
		"new_game":
			# Starting over replaces the save, so ask once first.
			if SaveSystem.has_save() and not _confirm_new_game:
				_set_new_game_confirm(true)
				return
			_board.active = false
			GameManager.new_game()
		"continue":
			_board.active = false
			GameManager.continue_game()
		"settings":
			_board.close()
			_settings.open()
		"quit":
			GameManager.quit_game()


func _build_chase() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpriteSheets.add_directional(frames, "run", PLAYER_RUN, Vector2i(16, 32), 12.0)
	SpriteSheets.add_directional(frames, "walk", CHICKEN_WALK, Vector2i(16, 16), 12.0)
	var runner := AnimatedSprite2D.new()
	runner.sprite_frames = frames
	runner.offset = Vector2(0, -16)
	runner.play("run_left")
	_chase.append(runner)
	for i in CHASERS.size():
		var chicken := AnimatedSprite2D.new()
		chicken.sprite_frames = frames
		chicken.offset = Vector2(0, -8)
		chicken.play("walk_left")
		chicken.frame = i
		_chase.append(chicken)
	for sprite in _chase:
		add_child(sprite)
		move_child(sprite, 0)


func _process(delta: float) -> void:
	_chase_x -= CHASE_SPEED * delta
	if _chase_x < -CHASERS[-1] - 40.0:
		_chase_x = size.x + 20.0
	_chase[0].position = Vector2(roundf(_chase_x), CHASE_FLOOR_Y)
	for i in CHASERS.size():
		# Chickens bob along a little out of step with each other.
		var bob := roundf(absf(sin(Time.get_ticks_msec() / 120.0 + i)) * -2.0)
		_chase[i + 1].position = Vector2(roundf(_chase_x + CHASERS[i]), CHASE_FLOOR_Y + bob)
	queue_redraw()


func _draw() -> void:
	# The terminal floor, with the wall's shadow along the top.
	for y in range(0, int(size.y) + 16, 16):
		for x in range(0, int(size.x) + 16, 16):
			var tile := Vector2(2 + (x / 16 + y / 16) % 2, 0) if y > 0 else Vector2(7, 0)
			draw_texture_rect_region(TILES, Rect2(x, y, 16, 16), Rect2(tile * 16, Vector2(16, 16)))
	# Shadows under the chase, drawn before the sprites.
	for sprite in _chase:
		draw_set_transform(sprite.position, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 6.0, Color(0.094, 0.078, 0.145, 0.4))
	draw_set_transform(Vector2.ZERO)
	# The title on a big departure-board sign, out of the way of Settings.
	if _settings.visible:
		return
	var font := get_theme_default_font()
	draw_rect(SIGN.grow(3), BoardMenu.BACK)
	draw_rect(SIGN.grow(2), BoardMenu.BEZEL)
	draw_rect(SIGN, BoardMenu.BACK)
	draw_string_outline(font, Vector2(SIGN.position.x, SIGN.position.y + 22), TITLE,
		HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 16, 2, Color("733e39"))
	draw_string(font, Vector2(SIGN.position.x, SIGN.position.y + 22), TITLE,
		HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 16, BoardMenu.TITLE)
	draw_string(font, Vector2(SIGN.position.x, SIGN.position.y + 35), TAGLINE,
		HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 8, BoardMenu.STATUS)
	if not best.is_empty():
		# On a dark plate, like the board's footer.
		var line := best_line()
		var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_rect(Rect2(roundf((size.x - width) / 2.0) - 3, BEST_Y - 8, width + 6, 11), BoardMenu.BACK)
		draw_string(font, Vector2(0, BEST_Y), line, HORIZONTAL_ALIGNMENT_CENTER, size.x, 8, BoardMenu.LABEL)


## Like "BEST 8,450  FIRST CLASS   FASTEST 24:51".
func best_line() -> String:
	var line := "BEST %s  %s" % [ScoreScreen.format_points(int(best.get("total", 0))), best.get("rank", "")]
	if best.has("time"):
		line += "   FASTEST " + ScoreScreen.format_time(best["time"])
	return line

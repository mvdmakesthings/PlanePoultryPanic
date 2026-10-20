class_name Ending
extends Node2D
## The ending: Amanda crosses the tarmac and boards the last plane, it takes
## off into the night, and then a close-up of a cabin window: a chicken pops
## up and winks, one eye glowing mushroom teal, while in the next window
## along Amanda faces forward, blinking contentedly, none the wiser. THE END.
## A run that found every secret sees the stowaway in the captain's hat
## from the crew room, and the PA has one last word. Any confirm or
## pause press skips ahead; on the end card it goes back to the main menu,
## and the finished run's save is cleared.

signal finished

const SKY := preload("res://assets/sprites/ending_sky.png")
const PLANE := preload("res://assets/sprites/plane_side.png")
const STOWAWAY := preload("res://assets/sprites/stowaway.png")
const STOWAWAY_CAPTAIN := preload("res://assets/sprites/stowaway_captain.png")
const CAPTAIN_LINE := "\"This is your captain speaking. BAWK.\""
const PASSENGER := preload("res://assets/sprites/passenger_window.png")
const WALK := preload("res://assets/sprites/player_walk.png")
const BLACK := Color("181425")
## Where the plane waits, and where its door is along the fuselage.
const PLANE_PARKED := Vector2(100, 116)
const DOOR_X := 196.0

## The caption on the board at the bottom, and the end card's lines.
var caption := ""
var shot := ""
## Every secret was found this run: the captain's ending.
var captain := false
## The captain's PA line is showing on the end card.
var captain_spoke := false

var _plane: Sprite2D
var _amanda: Sprite2D
var _window: Sprite2D
var _passenger: Sprite2D
var _fuselage: Node2D
var _overlay: ColorRect
var _ui: Control
var _skipped := false
var _done := false


func _ready() -> void:
	var sky := Sprite2D.new()
	sky.texture = SKY
	sky.centered = false
	add_child(sky)
	_plane = Sprite2D.new()
	_plane.texture = PLANE
	_plane.hframes = 2
	_plane.centered = false
	_plane.position = PLANE_PARKED
	add_child(_plane)
	_amanda = Sprite2D.new()
	_amanda.texture = WALK
	_amanda.hframes = 4
	_amanda.vframes = 4
	_amanda.frame = 2 * 4  # the right-facing row
	_amanda.centered = false
	_amanda.position = Vector2(-20, 126)
	add_child(_amanda)
	# The close-up: the side of the plane filling the screen, in the night sky.
	_fuselage = Node2D.new()
	_fuselage.visible = false
	_fuselage.draw.connect(func() -> void:
		_fuselage.draw_rect(Rect2(0, 0, 320, 180), BLACK)
		_fuselage.draw_rect(Rect2(0, 24, 320, 128), Color("ffffff"))
		_fuselage.draw_rect(Rect2(0, 24, 320, 6), Color("c0cbdc"))
		_fuselage.draw_rect(Rect2(0, 128, 320, 10), Color("124e89"))
		_fuselage.draw_rect(Rect2(0, 138, 320, 4), Color("0099db"))
		_fuselage.draw_rect(Rect2(0, 146, 320, 6), Color("8b9bb4")))
	add_child(_fuselage)
	_window = Sprite2D.new()
	captain = GameManager.found_every_secret()
	_window.texture = STOWAWAY_CAPTAIN if captain else STOWAWAY
	_window.hframes = 3
	_window.scale = Vector2(6, 6)
	_window.position = Vector2(104, 84)
	_window.visible = false
	add_child(_window)
	# Amanda one window forward (to the right, the way the plane faces).
	_passenger = Sprite2D.new()
	_passenger.texture = PASSENGER
	_passenger.hframes = 2
	_passenger.scale = Vector2(6, 6)
	_passenger.position = Vector2(216, 84)
	_passenger.visible = false
	add_child(_passenger)

	var layer := CanvasLayer.new()
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.color = BLACK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.draw.connect(_draw_ui)
	layer.add_child(_ui)
	AudioManager.play_music("victory")
	_play()


func _process(_delta: float) -> void:
	# A slow, contented blink: eyes shut for a moment every 1.6 seconds.
	if _passenger.visible:
		_passenger.frame = 1 if Time.get_ticks_msec() % 1600 < 160 else 0


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("ui_accept") or event.is_action_pressed("pause")):
		return
	get_viewport().set_input_as_handled()
	if shot == "end":
		_finish()
	else:
		_skipped = true


func _play() -> void:
	# The tarmac: she walks up to the plane's door and steps aboard.
	shot = "boarding"
	await _fade(0.0, 0.6)
	_set_caption("FLIGHT 13  ANYWHERE BUT HERE  BOARDING")
	AudioManager.play("pa_chime")
	var walk := create_tween()
	walk.tween_property(_amanda, "position:x", DOOR_X, 3.0)
	while walk.is_running() and not _skipped:
		_amanda.frame = 2 * 4 + int(Time.get_ticks_msec() / 125) % 4
		await get_tree().process_frame
	walk.kill()
	if not _skipped:
		_amanda.visible = false
		AudioManager.play("door")
		await _wait(0.8)

	# Takeoff: rolling, then climbing off to the upper right.
	shot = "takeoff"
	_amanda.visible = false
	_set_caption("FLIGHT 13  ANYWHERE BUT HERE  DEPARTED")
	if not _skipped:
		AudioManager.play("whoosh")
		var roll := create_tween()
		roll.tween_property(_plane, "position", PLANE_PARKED + Vector2(90, 0), 1.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		roll.tween_callback(func() -> void: _plane.frame = 1)
		roll.tween_property(_plane, "position", PLANE_PARKED + Vector2(330, -110), 2.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		while roll.is_running() and not _skipped:
			await get_tree().process_frame
		roll.kill()
	await _fade(1.0, 0.6)

	# The stowaway.
	shot = "stowaway"
	_set_caption("")
	_plane.visible = false
	_fuselage.visible = true
	_window.visible = true
	_window.frame = 0
	_passenger.visible = true
	await _fade(0.0, 0.5)
	await _wait(1.0)
	_window.frame = 1
	AudioManager.play("cluck")
	await _wait(1.0)
	_window.frame = 2
	AudioManager.play("crown_burst")
	await _wait(1.6)
	await _fade(1.0, 0.6)

	shot = "end"
	_ui.queue_redraw()
	if captain:
		await get_tree().create_timer(1.2).timeout
		if not _done:
			AudioManager.play("pa_chime")
			captain_spoke = true
			_ui.queue_redraw()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	GameManager.finish_game()


func _set_caption(text: String) -> void:
	caption = text
	_ui.queue_redraw()


func _fade(alpha: float, seconds: float) -> void:
	if _skipped:
		_overlay.modulate.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", alpha, seconds)
	await tween.finished


func _wait(seconds: float) -> void:
	if not _skipped:
		await get_tree().create_timer(seconds).timeout


func _draw_ui() -> void:
	var font := ThemeDB.fallback_font
	var w := _ui.size.x
	if shot == "end":
		_ui.draw_string(font, Vector2(0, 70), "THE END", HORIZONTAL_ALIGNMENT_CENTER, w, 16, BoardMenu.TITLE)
		_ui.draw_string(font, Vector2(0, 92), "Amanda made her flight.", HORIZONTAL_ALIGNMENT_CENTER, w, 8, BoardMenu.LABEL)
		_ui.draw_string(font, Vector2(0, 104), "Thanks for playing Plane Poultry Panic!", HORIZONTAL_ALIGNMENT_CENTER, w, 8, BoardMenu.LABEL)
		if captain_spoke:
			_ui.draw_string(font, Vector2(0, 124), CAPTAIN_LINE, HORIZONTAL_ALIGNMENT_CENTER, w, 8, BoardMenu.STATUS)
		ButtonGlyphs.draw_centered(_ui, font, w / 2.0, 150, "{ui_accept} MAIN MENU", BoardMenu.STATUS)
		return
	if caption == "":
		return
	var box := Rect2(8, 160, w - 16, 14)
	_ui.draw_rect(box.grow(1), BoardMenu.BEZEL)
	_ui.draw_rect(box, BoardMenu.BACK)
	_ui.draw_string(font, box.position + Vector2(0, 10), caption, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 8, BoardMenu.STATUS)

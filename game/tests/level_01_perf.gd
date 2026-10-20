extends Node
## Performance check for Level 1. Run it in a window (not headless), so
## rendering is measured too:
##   godot --path game res://tests/level_01_perf.tscn
## Vsync is turned off so frames aren't capped and the headroom shows. It
## plays three scenarios for a few seconds each and prints, per scenario,
## frame times (average and worst 1%), draw calls, memory and node count:
##   normal  - Amanda walks a lap of Baggage Claim with the level's chickens
##   chase   - every chicken in the level chasing her at once
##   stress  - 40 extra chickens chasing, far beyond what a level will have
## The target is 60 FPS (16.7 ms a frame) on a Steam Deck or a dual-core
## laptop, so on a faster machine the numbers should leave lots of room.

const LEVEL := preload("res://scenes/levels/level_01_arrivals.tscn")
const CHICKEN := preload("res://scenes/characters/chicken.tscn")
const SECONDS := 6.0
const LAP: Array[Vector2] = [Vector2(620, 300), Vector2(820, 300), Vector2(820, 480), Vector2(400, 480), Vector2(300, 300)]

var _frame_ms: Array[float] = []
var _draw_calls: Array[float] = []
var _last_usec := 0
var _sampling := false


func _ready() -> void:
	SaveSystem.save_path = "user://perf_save.json"
	GameManager.dry_run = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	print("renderer: %s, %s" % [RenderingServer.get_video_adapter_name(), OS.get_processor_name()])

	var level := LEVEL.instantiate()
	add_child(level)
	var player: Player = level.get_node("Entities/Player")
	# Untouchable and tireless, without changing the HUD (a huge health
	# would draw thousands of suitcases and swamp the measurement).
	player._invincible_timer = 1.0e9
	player.max_stamina = 100000.0
	player.stamina = 100000.0
	await _wait(1.0)
	player.global_position = LAP[0]
	await _measure("normal", player)

	for chicken: Chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.global_position = player.global_position + Vector2(randf_range(-120, 120), randf_range(-80, 80))
		chicken.alert()
	await _measure("chase", player)

	var entities := level.get_node("Entities")
	for i in 40:
		var chicken := CHICKEN.instantiate() as Chicken
		chicken.position = Vector2(randf_range(240, 880), randf_range(280, 520))
		entities.add_child(chicken)
	await get_tree().physics_frame
	for chicken: Chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.alert()
	await _measure("stress", player)

	SaveSystem.delete_game()
	await AudioManager.silence()
	get_tree().quit()


## Walks the lap while sampling every frame for SECONDS.
func _measure(label: String, player: Player) -> void:
	_frame_ms.clear()
	_draw_calls.clear()
	_last_usec = Time.get_ticks_usec()
	_sampling = true
	var start := Time.get_ticks_msec()
	var target := 1
	while Time.get_ticks_msec() - start < SECONDS * 1000.0:
		var to := LAP[target] - player.global_position
		if to.length() < 12.0:
			target = (target + 1) % LAP.size()
		_press_toward(to)
		await get_tree().process_frame
	_press_toward(Vector2.ZERO)
	_sampling = false
	_frame_ms.sort()
	var worst := _frame_ms.slice(int(_frame_ms.size() * 0.99))
	print("%-6s  %5d frames  avg %5.2f ms (%4.0f fps)  worst 1%% %5.2f ms  draw calls %3.0f  memory %3.0f MB  nodes %4d  chickens %d" % [
		label, _frame_ms.size(), _avg(_frame_ms), 1000.0 / _avg(_frame_ms), _avg(worst), _avg(_draw_calls),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		get_tree().get_nodes_in_group("chickens").size()])


func _process(_delta: float) -> void:
	if not _sampling:
		return
	var now := Time.get_ticks_usec()
	_frame_ms.append((now - _last_usec) / 1000.0)
	_last_usec = now
	_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


## Holds the movement keys that head toward direction. Only presses or
## releases a key when that changes: doing it every frame costs far more
## than the game itself and would skew the numbers.
func _press_toward(direction: Vector2) -> void:
	var wanted := {
		"move_left": direction.x < -4.0, "move_right": direction.x > 4.0,
		"move_up": direction.y < -4.0, "move_down": direction.y > 4.0,
	}
	for action: String in wanted:
		if wanted[action] and not Input.is_action_pressed(action):
			Input.action_press(action)
		elif not wanted[action] and Input.is_action_pressed(action):
			Input.action_release(action)


func _avg(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

extends Node
## Smoke test for scoring: the points math and ranks, tracking a run's
## stats in a real level (time, items, chickens, hits, secrets), stats
## surviving a retry, Continue and the next level, the best score, the
## score screen, and the best score on the main menu. Quits with a non-zero
## exit code on failure. Run from the repo root:
##   godot --headless --path game res://tests/scoring_smoke.tscn

const LEVEL_1 := preload("res://scenes/levels/level_01_arrivals.tscn")
const LEVEL_1_PATH := "res://scenes/levels/level_01_arrivals.tscn"
const LEVEL_2 := preload("res://scenes/levels/level_02_security.tscn")
const LEVEL_2_PATH := "res://scenes/levels/level_02_security.tscn"

var _failures: Array[String] = []
var _requested := [""]


func _ready() -> void:
	# Files of its own, so other tests running at the same time can't clash.
	SaveSystem.save_path = "user://test_scoring_save.json"
	SaveSystem.settings_path = "user://test_scoring_settings.cfg"
	SaveSystem.delete_game()
	SaveSystem.delete_best()
	SaveSystem.reset_controls()
	GameManager.dry_run = true
	_points_tests()
	await _tracking_test()
	await _retry_and_continue_test()
	await _next_level_test()
	await _starting_snacks_test()
	await _best_score_test()
	await _score_screen_test()
	await _main_menu_test()
	SaveSystem.delete_game()
	SaveSystem.delete_best()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.settings_path))

	get_tree().paused = false
	await AudioManager.silence()
	if _failures.is_empty():
		print("SCORING SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("FAILED: " + failure)
		get_tree().quit(1)


func _points_tests() -> void:
	var stats := {
		"time": 15.0 * 60.0, "level_times": {}, "collected": 10, "used": 5,
		"met": 40, "spotted": 10, "defeated": 0, "hits": 0, "knockouts": 0,
		"secrets": 0, "secret_total": 0,
	}
	var score := RunStats.score(stats)
	var points: Dictionary = score["points"]
	_check(points["time"] == RunStats.TIME_MAX, "15 minutes or under earns every time point")
	_check(points["efficiency"] == 1000, "using half the items earns half the efficiency points")
	_check(points["stealth"] == 1500, "a quarter of the chickens spotting her costs a quarter of stealth")
	_check(points["discovery"] == 0, "no secrets yet earns no discovery points")
	_check(score["perfect"] and points["perfect"] == RunStats.BONUS, "no hits earns the Perfect Run bonus")
	_check(score["pacifist"] and points["pacifist"] == RunStats.BONUS, "no defeats earns the Pacifist bonus")
	_check(score["speed_runner"], "under 25 minutes is a Speed Runner")
	_check(score["total"] == 3000 + 1000 + 1500 + 2000, "the total adds the categories up")

	stats.merge({"time": 45.0 * 60.0, "used": 12, "spotted": 40, "hits": 1, "defeated": 2,
		"secrets": 1, "secret_total": 4}, true)
	score = RunStats.score(stats)
	points = score["points"]
	_check(points["time"] == 0 and points["efficiency"] == 0 and points["stealth"] == 0,
		"45 minutes, every item used and every chicken alerted earn nothing (and never go negative)")
	_check(points["discovery"] == 500, "one secret of four earns a quarter of discovery")
	_check(not score["perfect"] and not score["pacifist"] and not score["speed_runner"],
		"a hit, a defeat and a slow time lose the bonuses")
	stats.merge({"time": 30.0 * 60.0}, true)
	_check(RunStats.score(stats)["points"]["time"] == 1500, "30 minutes earns half the time points")
	_check(RunStats.rank_for(0) == "LOST LUGGAGE" and RunStats.rank_for(6500) == "BUSINESS CLASS"
		and RunStats.rank_for(99999) == "CAPTAIN", "totals map to airline ranks")
	_check(ScoreScreen.format_time(1591.0) == "26:31" and ScoreScreen.format_time(3725.0) == "1:02:05",
		"times show as m:ss or h:mm:ss")
	_check(ScoreScreen.format_points(10250) == "10,250" and ScoreScreen.format_points(0) == "0",
		"points show with thousands separators")


## A new run in Level 1: the clock, items, chickens, hits and secrets.
func _tracking_test() -> void:
	RunStats.reset()
	var level := await _fresh_level(LEVEL_1)
	var player: Player = level.get_node("Entities/Player")
	_check(RunStats.collected == 0, "Amanda starts Level 1 with nothing to count")
	_check(RunStats.chickens.size() == _chickens_in(level).size() and RunStats.chickens.size() > 0,
		"every chicken in the level counts as met")

	await _wait(0.5)
	_check(RunStats.time > 0.3, "the clock runs while playing")
	_check(float(RunStats.level_times.get(LEVEL_1_PATH, 0.0)) == RunStats.time, "the level's own time runs too")
	get_tree().paused = true
	var paused_at := RunStats.time
	await _wait(0.3)
	_check(RunStats.time == paused_at, "the clock stops while paused")
	get_tree().paused = false

	player.pick_up("snack", 3)
	player.pick_up("extinguisher", 2)
	player.pick_up("maintenance_key", 1)
	_check(RunStats.collected == 4, "snacks count one each, an extinguisher once, key items not at all")
	player.throw_snack()
	_check(RunStats.used == 1, "throwing a snack uses it")
	player.inventory.select_item("extinguisher")
	player.spray()
	_check(RunStats.used == 1, "an extinguisher with charges left isn't used up yet")
	player.spray()
	_check(RunStats.used == 2, "an emptied extinguisher is used")
	player.inventory.select_item("snack")
	player.drop_item()
	_check(RunStats.collected == 2, "dropping snacks takes them off the collected count")
	player.pick_up("snack", 2)
	_check(RunStats.collected == 4, "picking them up again counts them once more")

	# One that isn't busy with the snack or the foam.
	var chickens := _chickens_in(level)
	var chicken: Chicken = chickens.filter(func(c: Chicken) -> bool: return c.state == Chicken.State.WANDER)[0]
	chicken.alert()
	# physics_frame comes before the frame's processing, so wait two.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(RunStats.summary()["spotted"] == 1, "a chicken chasing Amanda has spotted her")
	chicken.defeat()
	_check(RunStats.defeated == 1, "defeated chickens are counted")
	var spawned: Chicken = preload("res://scenes/characters/chicken.tscn").instantiate()
	level.get_node("Entities").add_child(spawned)
	_check(RunStats.chickens.size() == chickens.size() + 1, "chickens that arrive later (vents) count as met")

	player._invincible_timer = 0.0
	player.take_damage(Player.PECK, player.global_position + Vector2.RIGHT)
	_check(RunStats.hits == 1, "a hit is counted")
	player.eat_snack()
	_check(RunStats.used == 3 and RunStats.hits == 1, "eating a snack uses it and doesn't count as a hit")

	# Secrets are GameManager's (from the secrets work); 0 of 0 until then.
	var found: Variant = GameManager.get("secrets_found")
	var total: int = GameManager.get_script().get_script_constant_map().get("SECRETS_TOTAL", 0)
	_check(RunStats.summary()["secrets"] == (found.size() if found is Array else 0)
		and RunStats.summary()["secret_total"] == total, "discovery counts GameManager's secrets found and total")
	level.queue_free()
	await get_tree().process_frame


## After a knockout the checkpoint's items and chickens come back, but the
## time and hits don't. Continue picks every stat up from the save.
func _retry_and_continue_test() -> void:
	RunStats.reset()
	SaveSystem.delete_game()
	var level := await _fresh_level(LEVEL_1)
	var player: Player = level.get_node("Entities/Player")
	_check(GameManager.last_checkpoint.has("stats"), "a checkpoint snapshot holds the stats")
	player.pick_up("snack", 2)
	_chickens_in(level)[0].alert()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player._invincible_timer = 0.0
	player.take_damage(Player.PECK, player.global_position + Vector2.RIGHT)
	var save := SaveSystem.load_game()
	_check(int(save["stats"]["run"]["hits"]) == 1, "a hit is written to the save straight away")
	player.knock_out("peck")
	_check(RunStats.knockouts == 1, "a knockout is counted")
	await _wait(0.3)
	var time_at_knockout := RunStats.time
	await _wait(0.3)
	_check(RunStats.time == time_at_knockout, "the clock stops once Amanda is knocked out")

	GameManager.retry(LEVEL_1_PATH)
	level.queue_free()
	level = await _fresh_level(LEVEL_1, false)
	_check(RunStats.collected == 0 and RunStats.summary()["spotted"] == 0,
		"retrying puts the items and spotted chickens back to the checkpoint")
	_check(RunStats.hits == 2 and RunStats.knockouts == 1 and RunStats.time >= time_at_knockout,
		"retrying keeps the hits, the knockout and the time")
	_check(RunStats.chickens.size() == _chickens_in(level).size(), "the same chickens aren't met twice")

	# Quitting to the menu and choosing Continue.
	await _wait(0.2)
	var time_at_quit := RunStats.time
	GameManager.quit_to_menu()
	level.queue_free()
	await get_tree().process_frame
	RunStats.reset()
	GameManager.continue_game()
	_check(is_equal_approx(RunStats.time, time_at_quit) and RunStats.hits == 2 and RunStats.knockouts == 1,
		"Continue brings back the time, hits and knockouts")
	level = await _fresh_level(LEVEL_1, false)
	_check(RunStats.chickens.size() == _chickens_in(level).size(), "and the level's chickens")
	level.queue_free()
	await get_tree().process_frame


## Clearing a level carries the stats on, and starts counting the next
## level's chickens on top of the last one's.
func _next_level_test() -> void:
	RunStats.reset()
	var level := await _fresh_level(LEVEL_1)
	var player: Player = level.get_node("Entities/Player")
	var met_in_1 := RunStats.chickens.size()
	_chickens_in(level)[0].alert()
	await get_tree().physics_frame
	await get_tree().physics_frame
	player.pick_up("snack", 2)
	GameManager.level_cleared(LEVEL_2_PATH, LevelState.capture_inventory(player.inventory))
	GameManager.continue_run()
	level.queue_free()
	level = await _fresh_level(LEVEL_2, false)
	await get_tree().physics_frame
	var summary := RunStats.summary()
	_check(RunStats.past_met == met_in_1 and summary["met"] == met_in_1 + _chickens_in(level).size(),
		"chickens met add up across levels")
	_check(summary["spotted"] == 1 and RunStats.collected == 2, "spotted chickens and items carry over")
	_check(RunStats.level_times.has(LEVEL_1_PATH) and RunStats.level_times.has(LEVEL_2_PATH),
		"each level keeps its own time")
	level.queue_free()
	await get_tree().process_frame


## A run starting anywhere counts the snacks Amanda starts with.
func _starting_snacks_test() -> void:
	RunStats.reset()
	var level := await _fresh_level(LEVEL_2)
	var player: Player = level.get_node("Entities/Player")
	_check(player.snacks > 0 and RunStats.collected == player.snacks,
		"the snacks a new run starts with count as collected")
	level.queue_free()
	await get_tree().process_frame


## Finishing scores the run, clears the save, keeps the best and goes to
## the score screen.
func _best_score_test() -> void:
	SaveSystem.delete_best()
	RunStats.reset()
	RunStats.time = 20.0 * 60.0
	SaveSystem.save_game({"level": LEVEL_1_PATH, "checkpoint": "start"})
	var requested := _watch_scene_changes()
	GameManager.finish_game()
	_check(requested[0] == GameManager.SCORE_SCREEN, "finishing the game shows the score screen")
	_check(not SaveSystem.has_save(), "and clears the finished run's save")
	var best := SaveSystem.load_best()
	var first: Dictionary = RunStats.last_result
	_check(first["new_best"] and first["new_fastest"] and int(best["total"]) == first["total"]
		and best["rank"] == first["rank"], "the first finished run is the best")
	_check(SaveSystem.best_path() != SaveSystem.save_path, "the best score has a file of its own")

	RunStats.reset()
	RunStats.time = 40.0 * 60.0
	RunStats.hits = 3
	GameManager.finish_game()
	_check(not RunStats.last_result["new_best"] and int(SaveSystem.load_best()["total"]) == first["total"],
		"a lower score leaves the best alone")
	RunStats.reset()
	RunStats.time = 10.0 * 60.0
	RunStats.hits = 30
	RunStats.defeated = 9
	RunStats.used = 1
	GameManager.finish_game()
	var faster := SaveSystem.load_best()
	_check(RunStats.last_result["new_fastest"] and float(faster["time"]) == 600.0
		and int(faster["total"]) == first["total"], "a faster but lower run sets only the fastest time")
	_unwatch()


## The board flips in, a press shows it all, and the next goes to the menu.
func _score_screen_test() -> void:
	RunStats.last_result = {}
	var screen: ScoreScreen = preload("res://scenes/ui/score_screen.tscn").instantiate()
	add_child(screen)
	await get_tree().process_frame
	_check(screen.sample, "on its own, the score screen shows a sample run")
	screen.queue_free()

	RunStats.reset()
	RunStats.time = 26.0 * 60.0
	RunStats.collected = 10
	RunStats.used = 4
	RunStats.hits = 2
	SaveSystem.delete_best()
	var requested := _watch_scene_changes()
	GameManager.finish_game()
	requested[0] = ""
	screen = preload("res://scenes/ui/score_screen.tscn").instantiate()
	add_child(screen)
	await get_tree().process_frame
	_check(not screen.sample and screen.result == RunStats.last_result, "after a run it shows that run")
	_check(AudioManager.music_playing() == "victory", "the victory music plays on")
	var rows := ScoreScreen.rows_for(screen.result)
	_check(rows.size() == 6, "it has a row for each category and bonus")
	_check(rows[1]["detail"] == "USED 4 OF 10 ITEMS" and rows[3]["detail"].ends_with("SECRETS")
		and rows[4]["detail"] == "2 HITS", "the rows say what was counted")
	_check(screen.shown_rows < rows.size() and not screen.rank_shown, "the rows flip in one at a time")
	await _wait(ScoreScreen.ROW_DELAY * 2.5)
	_check(screen.shown_rows >= 2 and screen.shown_rows < rows.size(), "row by row")
	_tap("ui_accept")
	await get_tree().process_frame
	_check(screen.rank_shown and screen.shown_total == screen.result["total"] and requested[0] == "",
		"a press shows everything at once, without leaving")
	_tap("ui_accept")
	await get_tree().process_frame
	_check(requested[0] == GameManager.MAIN_MENU, "the next press goes back to the main menu")
	_unwatch()
	screen.queue_free()

	# Left alone, it gets to the rank by itself.
	screen = preload("res://scenes/ui/score_screen.tscn").instantiate()
	add_child(screen)
	await _wait(ScoreScreen.ROW_DELAY * 6 + ScoreScreen.COUNT_TIME + 0.6)
	_check(screen.rank_shown and screen.shown_total == screen.result["total"], "left alone, the total and rank come up")
	screen.queue_free()
	await get_tree().process_frame


func _main_menu_test() -> void:
	SaveSystem.delete_best()
	var menu: Control = preload("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check(menu.best.is_empty(), "the main menu shows no best before any finished run")
	menu.queue_free()
	SaveSystem.save_best({"total": 8450, "rank": "FIRST CLASS", "time": 1491.0})
	menu = preload("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check(menu.best_line() == "BEST 8,450  FIRST CLASS   FASTEST 24:51", "then it shows the best score and fastest time")
	menu.queue_free()
	await get_tree().process_frame


func _chickens_in(level: Node) -> Array[Chicken]:
	var found: Array[Chicken] = []
	for node in get_tree().get_nodes_in_group("chickens"):
		if level.is_ancestor_of(node) and not node.is_queued_for_deletion():
			found.append(node as Chicken)
	return found


## Starts recording the scene changes GameManager announces: returns the
## list, whose [0] is the latest ("" for none yet).
func _watch_scene_changes() -> Array:
	_requested = [""]
	GameManager.scene_change_requested.connect(_on_scene_change_requested)
	return _requested


func _unwatch() -> void:
	GameManager.scene_change_requested.disconnect(_on_scene_change_requested)


func _on_scene_change_requested(path: String) -> void:
	_requested[0] = path


## A new copy of a level. fresh=false keeps any pending snapshot.
func _fresh_level(scene: PackedScene, fresh := true) -> Node:
	get_tree().paused = false
	if fresh:
		GameManager.pending = {}
	await get_tree().process_frame
	var level := scene.instantiate()
	add_child(level)
	await get_tree().physics_frame
	return level


func _check(condition: bool, description: String) -> void:
	print(("ok    " if condition else "FAIL  ") + description)
	if not condition:
		_failures.append(description)


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout

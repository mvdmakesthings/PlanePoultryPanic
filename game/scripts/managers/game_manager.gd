extends Node
## Moves the game between the main menu and the levels, and remembers the
## latest checkpoint (autoload: GameManager).
##
## A checkpoint is a snapshot of the run (see LevelState): which level and
## checkpoint, the player's inventory, and what they've changed in the
## level. Reaching one autosaves it. Retrying after a knockout, or choosing
## Continue in the main menu, loads the level and hands it that snapshot to
## restore; with no snapshot a level starts from the beginning.

signal scene_change_requested(path: String)

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const FIRST_LEVEL := "res://scenes/levels/level_01_arrivals.tscn"
const FADE_TIME := 0.25

## The snapshot the next level should restore, taken with take_pending().
var pending: Dictionary = {}
## The latest checkpoint reached in this run, or {}.
var last_checkpoint: Dictionary = {}
## Tests set this so scene changes are only announced, not made, since a
## real change would replace the test itself.
var dry_run := false

var _fade: ColorRect
var _changing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color("181425")
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


## Starts over from the first level, replacing any save.
func new_game() -> void:
	SaveSystem.delete_game()
	last_checkpoint = {}
	pending = {}
	change_scene(FIRST_LEVEL)


## Loads the saved checkpoint. Does nothing if there's no save.
func continue_game() -> void:
	var save := SaveSystem.load_game()
	if save.is_empty():
		return
	last_checkpoint = save
	pending = save
	change_scene(save["level"])


## Called by a level when the player leaves through its exit: autosaves at
## the start of the next level (by scene path), carrying the inventory over.
func level_cleared(next_level: String, inventory: Dictionary) -> void:
	checkpoint_reached({
		"level": next_level,
		"checkpoint": "start",
		"reached": [],
		"inventory": inventory,
		"collected": [],
		"unlocked": [],
	})


## Carries on from the latest checkpoint, for example into the next level
## after one is cleared.
func continue_run() -> void:
	if last_checkpoint.is_empty():
		return
	pending = last_checkpoint
	change_scene(last_checkpoint["level"])


## Reloads a level (by scene path) from its latest checkpoint.
func retry(level: String) -> void:
	if last_checkpoint.get("level", "") == level:
		pending = last_checkpoint
	else:
		pending = {}
	change_scene(level)


## Called by a level when the player reaches a checkpoint: remembers it and
## autosaves.
func checkpoint_reached(snapshot: Dictionary) -> void:
	last_checkpoint = snapshot
	SaveSystem.save_game(snapshot)


## The snapshot to restore, if any, for a level that has just loaded.
## Only the level it belongs to gets it.
func take_pending(level_path: String) -> Dictionary:
	var snapshot := pending
	pending = {}
	return snapshot if snapshot.get("level", "") == level_path else {}


func quit_to_menu() -> void:
	change_scene(MAIN_MENU)


func quit_game() -> void:
	await AudioManager.silence()
	get_tree().quit()


## Fades to black, swaps scenes, and fades back in.
func change_scene(path: String) -> void:
	scene_change_requested.emit(path)
	if dry_run or _changing:
		return
	_changing = true
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	_changing = false

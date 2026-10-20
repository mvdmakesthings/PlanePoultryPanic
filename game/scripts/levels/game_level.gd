class_name GameLevel
extends Node2D
## What every campaign level shares: building the layout from a text map,
## the camera, the HUD, tutorial hints, checkpoints and autosave, the retry
## screen after a knockout, locked doors, and the level-clear screen that
## leads on to the next level.
##
## A level extends this and fills in its own details in _setup(): the text
## map (see LevelBuilder for the legend), its tileset, music, hints, and
## which door is the way out. Props, chickens, pickups and checkpoints are
## placed in the level's scene, which needs these nodes: Floor and Props
## (TileMapLayers), Entities/Player, UI/HUD and UI/GameMenus.
##
## Reaching a checkpoint autosaves; after a knockout the player retries from
## the latest one with their inventory as it was then. Leaving through the
## exit autosaves at the start of the next level, with the inventory carried
## over.

const TILE := LevelBuilder.TILE
## How long each zone's hint shows, in seconds in all.
const HINT_TIME := 8.0
## One-off hints for things that happen, shown for this long.
const EVENT_HINT_TIME := 5.0
## The first PA announcement comes this long after the level starts, then
## one every PA_INTERVAL seconds, each shown for PA_TIME.
const PA_FIRST_DELAY := 4.0
const PA_INTERVAL := 40.0
const PA_TIME := 6.0
## Retry hints every level can fall back on, by what landed the last hit.
const COMMON_RETRY_HINTS := {
	"peck": [
		"Chickens stop for a thrown snack.\nToss one ({use_item}) and slip past.",
		"Chickens are slower than you walk.\nKeep moving and don't get cornered.",
		"Hold {run} to sprint out of trouble,\nbut keep an eye on your stamina.",
		"Low on suitcases? {eat_snack} eats a snack\nto heal one.",
	],
	"egg": ["Egg shooters wind up before they fire.\nStep aside, or duck behind a cart."],
	"stomp": ["A red zone marks where the totem\nwill land. Get out of it!"],
}

# ---------- filled in by each level's _setup() ----------
## Rows of the text map.
var map: Array = []
## The tileset the map is painted with (same layout as tiles_arrivals.png).
var tiles_texture: Texture2D = LevelBuilder.TILES
## Music track name for AudioManager.
var music := ""
## Tutorial hints: {"zone": Rect2i in tiles, "text": String}. While the
## player stands in a zone its hint shows at the top of the screen.
var hint_zones: Array = []
## Shown once, the first time the player gets each key item.
var key_hints := {}
## Shown when the player tries a locked door without its key, by door name.
var locked_hints := {}
## Shown the first time the player is hurt ("" for none).
var hurt_hint := ""
## PA announcements, played in turn through the level: the terminal on
## autopilot, getting stranger as the chickens take over (storyline.md).
var pa_lines: Array = []
## Extra retry hints, merged over COMMON_RETRY_HINTS.
var retry_hints := {}
## The door that ends the level when walked through.
var exit_door: LockedDoor
## The level-clear screen's title, e.g. "ARRIVALS CLEARED!".
var clear_title := ""
## The next level's scene path, or "" if it isn't built yet.
var next_level := ""
## The level-clear button that leads on, e.g. "ON TO SECURITY".
var next_label := ""

## The baked navigation, rebaked when something like a shutter moves.
var navigation: NavigationRegion2D

var _level_over := false
var _hint_time_left: Array[float] = []
var _event_hint := ""
var _event_hint_left := 0.0
var _shown_hurt_hint := false
var _shown_key_hints := {}
var _last_health := -1
var _rebake_queued := false
var _pa_next := PA_FIRST_DELAY
var _pa_index := 0
var _pa_left := 0.0
## The scene's item pickups, to tell which have been picked up.
var _pickups: Array[String] = []

@onready var _floor: TileMapLayer = $Floor
@onready var _props: TileMapLayer = $Props
@onready var _player: Player = $Entities/Player
@onready var _hud: Hud = $UI/HUD
@onready var _menus: GameMenus = $UI/GameMenus


func _ready() -> void:
	_setup()
	var rows := PackedStringArray(map)
	var tile_set := LevelBuilder.build_tile_set(tiles_texture)
	_floor.tile_set = tile_set
	_props.tile_set = tile_set
	LevelBuilder.paint_map(_floor, rows)
	var gaps: Array[Rect2i] = []
	for door in _doors():
		gaps.append(door.wall_gap())
	LevelBuilder.add_map_walls(self, rows, gaps)
	_build()
	var size_px := Vector2(rows[0].length(), rows.size()) * TILE
	navigation = LevelBuilder.build_navigation(self, Rect2(Vector2.ZERO, size_px))

	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size_px.x)
	camera.limit_bottom = int(size_px.y)

	_hud.controls_hint = ""
	_hud.bind_player(_player)
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_player_health_changed)
	_player.inventory_changed.connect(_on_inventory_changed)
	for door in _doors():
		door.interacted_locked.connect(_on_door_locked.bind(door))
	exit_door.player_entered.connect(_on_exit_entered)
	_menus.chosen.connect(_on_menu_chosen)
	# Keeps playing across retries, since it's already the track playing.
	AudioManager.play_music(music)
	for i in hint_zones.size():
		_hint_time_left.append(HINT_TIME)

	_pickups = LevelState.pickup_paths(self)
	for checkpoint in _checkpoints():
		checkpoint.reached.connect(_on_checkpoint_reached)
	var restore := GameManager.take_pending(scene_file_path)
	if restore.is_empty():
		_save_checkpoint("start")
	else:
		_restore(restore)


## Fills in the level's details (see the variables above).
func _setup() -> void:
	pass


## Builds anything beyond the text map (carousels and the like) before the
## navigation is baked.
func _build() -> void:
	pass


func _physics_process(delta: float) -> void:
	_update_hints(delta)
	_update_pa(delta)


## Plays the PA chime and shows an announcement at the bottom of the screen.
func announce(text: String) -> void:
	AudioManager.play("pa_chime")
	_hud.show_pa(text)
	_pa_left = PA_TIME


func _update_pa(delta: float) -> void:
	if _level_over:
		_hud.show_pa("")
		return
	_pa_left -= delta
	if _pa_left <= 0.0:
		_hud.show_pa("")
	if pa_lines.is_empty():
		return
	_pa_next -= delta
	if _pa_next <= 0.0:
		_pa_next = PA_INTERVAL
		announce(pa_lines[_pa_index % pa_lines.size()])
		_pa_index += 1


## Bakes the navigation again (next frame, once), after something solid
## like a shutter has moved, so chickens path around it.
func rebake_navigation() -> void:
	if _rebake_queued:
		return
	_rebake_queued = true
	await get_tree().physics_frame
	_rebake_queued = false
	if navigation and not navigation.is_baking():
		navigation.bake_navigation_polygon(true)


# ---------- hints ----------

## Shows the event hint if there is one, otherwise the hint for the zone
## the player is standing in (until its time runs out).
func _update_hints(delta: float) -> void:
	if _level_over:
		_hud.show_hint("")
		return
	_event_hint_left -= delta
	if _event_hint_left > 0.0:
		_hud.show_hint(_event_hint)
		return
	var tile := Vector2i(_player.global_position / TILE)
	for i in hint_zones.size():
		if _hint_time_left[i] > 0.0 and (hint_zones[i]["zone"] as Rect2i).has_point(tile):
			_hint_time_left[i] -= delta
			_hud.show_hint(hint_zones[i]["text"])
			return
	_hud.show_hint("")


func show_event_hint(text: String) -> void:
	_event_hint = text
	_event_hint_left = EVENT_HINT_TIME


func _on_player_health_changed(current: int, _maximum: int) -> void:
	if _last_health >= 0 and current < _last_health and hurt_hint != "" \
			and not _shown_hurt_hint and not _player.is_dead:
		_shown_hurt_hint = true
		show_event_hint(hurt_hint)
	_last_health = current


func _on_inventory_changed() -> void:
	for item: String in key_hints:
		if not _shown_key_hints.has(item) and _player.inventory.has_key_item(item):
			_shown_key_hints[item] = true
			show_event_hint(key_hints[item])


func _on_door_locked(door: LockedDoor) -> void:
	if locked_hints.has(door.name):
		show_event_hint(locked_hints[door.name])


## Fades to black, calls middle (for example to move the player somewhere
## else in the level), and fades back in.
func fade_through(middle: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var black := ColorRect.new()
	black.color = Color("181425")
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.modulate.a = 0.0
	layer.add_child(black)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(black, "modulate:a", 1.0, 0.25)
	await tween.finished
	middle.call()
	tween = create_tween()
	tween.tween_property(black, "modulate:a", 0.0, 0.25)
	await tween.finished
	layer.queue_free()


# ---------- the end of the level ----------

func _on_exit_entered() -> void:
	if _level_over:
		return
	_level_over = true
	_menus.can_pause = false
	_player.freeze()
	AudioManager.play("level_clear")
	if next_level != "":
		# Autosave at the start of the next level, so Continue goes there.
		GameManager.level_cleared(next_level, LevelState.capture_inventory(_player.inventory))
	var rows: Array[Dictionary] = []
	if next_level != "":
		rows.append({"id": "next", "label": next_label, "kind": "button", "status": "BOARDING"})
	else:
		rows.append({"id": "next", "label": next_label, "kind": "button", "status": "COMING SOON", "disabled": true})
	_menus.open_level_clear(clear_title, rows)


func _on_menu_chosen(id: String) -> void:
	if id == "next":
		GameManager.continue_run()


func _on_player_died() -> void:
	if _level_over:
		return
	_level_over = true
	_menus.can_pause = false
	# Let the knockout land before the retry screen comes up.
	await get_tree().create_timer(1.5).timeout
	var hints: Array = retry_hints.get(_player.last_hit,
		COMMON_RETRY_HINTS.get(_player.last_hit, COMMON_RETRY_HINTS["peck"]))
	_menus.open_retry(hints.pick_random())


# ---------- checkpoints ----------

func _on_checkpoint_reached(checkpoint: Checkpoint) -> void:
	_save_checkpoint(checkpoint.id)
	AudioManager.play("checkpoint")
	FloatText.spawn(_player, "Checkpoint!")


## Snapshots the run at this checkpoint and autosaves it.
func _save_checkpoint(id: String) -> void:
	var reached: Array[String] = []
	for checkpoint in _checkpoints():
		if checkpoint.is_active:
			reached.append(checkpoint.id)
	var unlocked: Array[String] = []
	for node in get_tree().get_nodes_in_group("unlockables"):
		if is_ancestor_of(node) and not node.is_locked:
			unlocked.append(str(get_path_to(node)))
	GameManager.checkpoint_reached({
		"level": scene_file_path,
		"checkpoint": id,
		"reached": reached,
		"inventory": LevelState.capture_inventory(_player.inventory),
		"collected": LevelState.collected(self, _pickups),
		"unlocked": unlocked,
		"extra": _extra_state(),
	})


## Puts the level back the way it was at a checkpoint. The "start"
## checkpoint keeps the player where the scene puts them.
func _restore(data: Dictionary) -> void:
	for checkpoint in _checkpoints():
		if checkpoint.id in data.get("reached", []):
			checkpoint.activate(true)
		if checkpoint.id == data.get("checkpoint", ""):
			_player.global_position = checkpoint.spawn_point()
	for path: String in data.get("collected", []):
		if has_node(path):
			get_node(path).free()
	for path: String in data.get("unlocked", []):
		if has_node(path):
			get_node(path).unlock(true)
	# Don't announce key items the player already had.
	for item: String in key_hints:
		_shown_key_hints[item] = true
	LevelState.restore_inventory(_player.inventory, data.get("inventory", {}))
	_shown_key_hints.clear()
	for item: String in key_hints:
		if _player.inventory.has_key_item(item):
			_shown_key_hints[item] = true
	_restored(data)
	# The run carries on from here, so this is the latest checkpoint again.
	GameManager.last_checkpoint = data


## Anything level-specific to keep in a checkpoint (plain JSON values).
func _extra_state() -> Dictionary:
	return {}


## Called after a checkpoint is restored, for anything level-specific
## (data["extra"] holds what _extra_state() returned).
func _restored(_data: Dictionary) -> void:
	pass


## Names of anything standing on the floor (under Entities) whose feet are
## inside a wall tile, for tests: placement mistakes the eye can miss.
func things_in_walls() -> Array[String]:
	var rows := PackedStringArray(map)
	var stuck: Array[String] = []
	for node in $Entities.get_children():
		if node is Node2D:
			var tile := Vector2i(((node as Node2D).global_position - Vector2(0, 1)) / TILE)
			if LevelBuilder.is_map_wall(rows, tile.x, tile.y):
				stuck.append(str(node.name))
	return stuck


func _checkpoints() -> Array[Checkpoint]:
	var found: Array[Checkpoint] = []
	for node in find_children("*", "", true, false):
		if node is Checkpoint:
			found.append(node as Checkpoint)
	return found


func _doors() -> Array[LockedDoor]:
	var found: Array[LockedDoor] = []
	for node in find_children("*", "", true, false):
		if node is LockedDoor:
			found.append(node as LockedDoor)
	return found

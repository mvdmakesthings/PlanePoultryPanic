extends Node2D
## Level 1: Arrivals / Baggage Claim, the tutorial level. The player steps
## off their flight into the arrival lounge, learns to walk, run and throw
## snacks in the hallway, then comes down into Baggage Claim, where the
## door to Security is locked. The maintenance key that opens it is in the
## staff room on the far side of the carousel.
##
## The layout is the text map below (see LevelBuilder for the legend). Props,
## chickens, pickups and checkpoints are placed in the scene. Reaching a
## checkpoint autosaves; after a knockout the player retries from the latest
## one with their inventory as it was then.

const TILE := LevelBuilder.TILE
const MAP := [
	"##########################################################",
	"##########################################################",
	"##########################################################",
	"##########################################################",
	"#~~~~~~~~~~~~~~##,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"#~~~~~~~~~~~~~~##,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"#~~~~~~~~~~~~~~##,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"#~~~~~~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"#~~~~~~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"#~~~~~~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"#~~~~~~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"#~~~~~~~~~~~~~~##,,,,,,,,,,,,,,,,,,,,,,,,##,,,,,,,,,,,,,,#",
	"####################################,,,,#########,,#######",
	"####################################,,,,#########,,#######",
	"####################################,,,,#########,,#######",
	"####################################,,,,#########,,#######",
	"#~~~~~~~~~~~~~~..........................................#",
	"#~~~~~~~~~~~~~~..........................................#",
	"#~~~~~~~~~~~~~~..........................................#",
	"#~~~~~~~~~~~~~~..........................................#",
	"#~~~~~~~~~~~~~~..........................................#",
	"#~~~~~~~~~~~~~~..........................................#",
	"#~~~~~~~~~~~~~~..........................................#",
	"#~~~~~~~~~~~~~~..........................................#",
	"#############............................................#",
	"#############............................................#",
	"#############............................................#",
	"#############............................................#",
	"#==========##............................................#",
	"#============............................................#",
	"#============............................................#",
	"#============............................................#",
	"#==========##............................................#",
	"#==========##............................................#",
	"##########################################################",
]
## The baggage carousel, in tiles, and which column of its back belt has the chute.
const CAROUSEL_RECT := Rect2i(22, 21, 14, 6)
const CHUTE_COLUMN := 6

## Tutorial hints. While the player stands in a zone (in tiles), its hint
## shows at the top of the screen, for HINT_TIME seconds in all. Buttons in
## braces match the player's bindings.
const HINT_ZONES := [
	{"zone": Rect2i(1, 4, 8, 8), "text": "{move} to walk"},
	{"zone": Rect2i(9, 4, 6, 8), "text": "Snacks! Walk over them\nto pick them up"},
	{"zone": Rect2i(15, 6, 5, 6), "text": "Hold {run} to run.\nRunning uses stamina"},
	{"zone": Rect2i(20, 4, 11, 8), "text": "Chickens chase you on sight.\n{use_item} throws a snack to\ndistract them"},
	{"zone": Rect2i(31, 4, 10, 8), "text": "{interact} shoves a luggage cart.\nA rolling cart flattens chickens"},
	{"zone": Rect2i(36, 12, 4, 7), "text": "Baggage Claim. Security\nis through the door ahead"},
	{"zone": Rect2i(19, 18, 20, 12), "text": "The belt carries chickens\ninto the chute. Lure one\nonto it with a snack!"},
	{"zone": Rect2i(39, 27, 7, 6), "text": "{interact} lifts a suitcase.\n{use_item} throws it at a chicken"},
	{"zone": Rect2i(13, 27, 6, 7), "text": "A staff room. Maybe\nthere's a key in here"},
]
const HINT_TIME := 8.0
## One-off hints for things that happen, shown for this long.
const EVENT_HINT_TIME := 5.0
const HURT_HINT := "Ouch! {eat_snack} eats a snack\nto heal a suitcase"
const LOCKED_HINT := "Locked. Find a maintenance\nkey: try the staff room"
const KEY_HINT := "Got the maintenance key!\nBack to the SECURITY door"
## Shown on the retry screen, by what landed the last hit.
const RETRY_HINTS := {
	"peck": [
		"Chickens stop for a thrown snack.\nToss one ({use_item}) and slip past.",
		"Chickens are slower than you walk.\nKeep moving and don't get cornered.",
		"Hold {run} to sprint out of trouble,\nbut keep an eye on your stamina.",
		"Low on suitcases? {eat_snack} eats a snack\nto heal one.",
	],
	"egg": ["Egg shooters wind up before they fire.\nStep aside, or duck behind a cart."],
	"stomp": ["A red zone marks where the totem\nwill land. Get out of it!"],
}

var _level_over := false
var _hint_time_left: Array[float] = []
var _event_hint := ""
var _event_hint_left := 0.0
var _shown_hurt_hint := false
var _shown_key_hint := false
var _last_health := -1
var _start_position: Vector2
## The scene's item pickups, to tell which have been picked up.
var _pickups: Array[String] = []

@onready var _floor: TileMapLayer = $Floor
@onready var _props: TileMapLayer = $Props
@onready var _door: LockedDoor = $SecurityDoor
@onready var _player: Player = $Entities/Player
@onready var _hud: Hud = $UI/HUD
@onready var _menus: GameMenus = $UI/GameMenus


func _ready() -> void:
	var rows := PackedStringArray(MAP)
	var tile_set := LevelBuilder.build_tile_set()
	_floor.tile_set = tile_set
	_props.tile_set = tile_set
	LevelBuilder.paint_map(_floor, rows)
	LevelBuilder.paint_carousel(_props, CAROUSEL_RECT, CHUTE_COLUMN)
	var gaps: Array[Rect2i] = [_door.wall_gap()]
	LevelBuilder.add_map_walls(self, rows, gaps)
	LevelBuilder.add_carousel(self, CAROUSEL_RECT, CHUTE_COLUMN)
	var size_px := Vector2(rows[0].length(), rows.size()) * TILE
	LevelBuilder.build_navigation(self, Rect2(Vector2.ZERO, size_px))

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
	_door.player_entered.connect(_on_door_entered)
	_door.interacted_locked.connect(func() -> void: _show_event_hint(LOCKED_HINT))
	_menus.chosen.connect(_on_menu_chosen)
	# Keeps playing across retries, since it's already the track playing.
	AudioManager.play_music("arrivals")
	for i in HINT_ZONES.size():
		_hint_time_left.append(HINT_TIME)

	_start_position = _player.global_position
	_pickups = LevelState.pickup_paths(self)
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if is_ancestor_of(node):
			(node as Checkpoint).reached.connect(_on_checkpoint_reached)
	var restore := GameManager.take_pending(scene_file_path)
	if restore.is_empty():
		_save_checkpoint("start")
	else:
		_restore(restore)


func _physics_process(delta: float) -> void:
	_update_hints(delta)


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
	for i in HINT_ZONES.size():
		if _hint_time_left[i] > 0.0 and (HINT_ZONES[i]["zone"] as Rect2i).has_point(tile):
			_hint_time_left[i] -= delta
			_hud.show_hint(HINT_ZONES[i]["text"])
			return
	_hud.show_hint("")


func _show_event_hint(text: String) -> void:
	_event_hint = text
	_event_hint_left = EVENT_HINT_TIME


func _on_player_health_changed(current: int, _maximum: int) -> void:
	if _last_health >= 0 and current < _last_health and not _shown_hurt_hint and not _player.is_dead:
		_shown_hurt_hint = true
		_show_event_hint(HURT_HINT)
	_last_health = current


func _on_inventory_changed() -> void:
	if not _shown_key_hint and _player.inventory.has_key_item(_door.key_item):
		_shown_key_hint = true
		_show_event_hint(KEY_HINT)


func _on_door_entered() -> void:
	if _level_over:
		return
	_level_over = true
	_menus.can_pause = false
	_player.freeze()
	AudioManager.play("level_clear")
	var rows: Array[Dictionary] = [
		{"id": "security", "label": "ON TO SECURITY", "kind": "button", "status": "COMING SOON", "disabled": true},
		{"id": "again", "label": "PLAY AGAIN", "kind": "button", "status": "BOARDING"},
	]
	_menus.open_level_clear("ARRIVALS CLEARED!", rows)


func _on_menu_chosen(id: String) -> void:
	if id == "again":
		GameManager.new_game()


func _on_player_died() -> void:
	if _level_over:
		return
	_level_over = true
	_menus.can_pause = false
	# Let the knockout land before the retry screen comes up.
	await get_tree().create_timer(1.5).timeout
	var hints: Array = RETRY_HINTS.get(_player.last_hit, RETRY_HINTS["peck"])
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
	if not _door.is_locked:
		unlocked.append(str(get_path_to(_door)))
	GameManager.checkpoint_reached({
		"level": scene_file_path,
		"checkpoint": id,
		"reached": reached,
		"inventory": LevelState.capture_inventory(_player.inventory),
		"collected": LevelState.collected(self, _pickups),
		"unlocked": unlocked,
	})


## Puts the level back the way it was at a checkpoint.
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
			(get_node(path) as LockedDoor).unlock(true)
	# Don't announce a key the player already had.
	_shown_key_hint = true
	LevelState.restore_inventory(_player.inventory, data.get("inventory", {}))
	_shown_key_hint = _player.inventory.has_key_item(_door.key_item) or not _door.is_locked
	# The run carries on from here, so this is the latest checkpoint again.
	GameManager.last_checkpoint = data


func _checkpoints() -> Array[Checkpoint]:
	var found: Array[Checkpoint] = []
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if is_ancestor_of(node):
			found.append(node as Checkpoint)
	return found

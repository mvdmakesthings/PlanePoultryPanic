extends Node2D
## Level 1: Arrivals / Baggage Claim, the tutorial level. The player steps
## off their flight into the arrival lounge, learns to walk, run and throw
## snacks in the hallway, then comes down into Baggage Claim, where the
## door to Security is locked. The maintenance key that opens it is in the
## staff room on the far side of the carousel.
##
## The layout is the text map below (see LevelBuilder for the legend). Props,
## chickens and pickups are placed in the scene.

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

var _level_over := false
var _hint_time_left: Array[float] = []
var _event_hint := ""
var _event_hint_left := 0.0
var _shown_hurt_hint := false
var _shown_key_hint := false
var _last_health := -1

@onready var _floor: TileMapLayer = $Floor
@onready var _props: TileMapLayer = $Props
@onready var _door: LockedDoor = $SecurityDoor
@onready var _player: Player = $Entities/Player
@onready var _hud: Hud = $UI/HUD


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
	for i in HINT_ZONES.size():
		_hint_time_left.append(HINT_TIME)
	AudioManager.play_music("arrivals")


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
	_player.freeze()
	AudioManager.play("level_clear")
	_hud.show_message("ARRIVALS CLEARED!\nNext stop: Security\n(coming soon)")


func _on_player_died() -> void:
	if _level_over:
		return
	_level_over = true
	_hud.show_message("GROUNDED.\nBack to the gate...")
	# Until checkpoints arrive, start the level over.
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

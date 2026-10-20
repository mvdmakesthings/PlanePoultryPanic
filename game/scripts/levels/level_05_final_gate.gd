extends GameLevel
## Level 5: the Final Departure Gate. Amanda arrives in Gate C13's night
## lounge (a last chance to stock up), then steps into the boarding area,
## where eight chickens rush the roost and stack into the Supreme Totem:
## taller, crowned with a giant glowing mushroom, deaf to snacks, and it
## takes three hits (carts, a frozen base, or a walkway under it) to break.
## When it falls the doors start closing: a countdown runs, chickens drop
## out of the vents, the boarding door reads her pass, and she runs the jet
## bridge (a full-speed walkway) to the plane door. Missing the countdown
## counts as a knockout. Checkpoints: entering the boarding area, and the
## moment the boss falls.
##
## The layout is the text map below (see LevelBuilder for the legend; in
## this tileset "," is night carpet, "." dark tile, "~" the glowing
## boarding-area carpet and "=" the jet bridge); the rest comes from
## GameLevel.

const MAP: Array[String] = [
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"#,.......,,,,,,,,,,,##........................................##################",
	"#,.......,,,,,,,,,,,##........................................##################",
	"#,.......,,,,,,,,,,,##........................................##################",
	"#,.......,,,,,,,,,,,##........................................##################",
	"#,.......,,,,,,,,,,,##......~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,........~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,........~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,........~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,........~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,........~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,........~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,........~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,##......~~~~~~~~~~~~~~~~~~~~~~~~~~~~......##################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"#,,,,,,,,,,,,,,,,,,,##........................................##################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"##============================================================================##",
	"##============================================================================##",
	"##============================================================================##",
	"##============================================================================##",
	"################################################################################",
	"################################################################################",
	"################################################################################",
]
const HINT_ZONES := [
	{"zone": Rect2i(1, 11, 6, 7), "text": "Gate C13: the last flight\nout. Stock up: the boarding\narea is just ahead"},
]
const ARENA_X := 22 * TILE
const BOSS_HITS := 3
const ESCAPE_TIME := 30.0
## Seconds between chickens dropping out of the vents, and the most at once.
const VENT_INTERVAL := 2.5
const MAX_CHICKENS := 12
## Where the jet bridge starts, for walking through the boarding door.
const JET_BRIDGE_START := Vector2(48, 496)
const BOSS_HINT := "The SUPREME TOTEM! Snacks won't\nwork. Ram it, freeze it, or lure\nit onto a walkway: three hits!"
const STAGGER_HINT := "It's shrinking! Hit it again!"
const ESCAPE_HINT := "FINAL CALL! The doors close in\n30 seconds. Scan your pass at\nthe BOARDING door and run!"
const RETRY_HINTS := {
	"peck": [
		"Shove a cart into the totem, or\nfreeze its base, then hit it again.",
		"Lure the totem onto a walkway:\nit loses its footing.",
		"Watch for the red landing zone\nwhen the totem takes off.",
		"Chickens stop for a thrown snack.\nToss one ({use_item}) and slip past.",
	],
	"time": [
		"The doors closed! Ride the jet bridge\nwalkway and don't stop for chickens.",
		"Out of time. Head straight for the\nBOARDING door and scan your pass.",
	],
}

var boss: Totem
var boss_beaten := false
var escape_left := -1.0

var _fight_started := false
var _vent_timer := 0.0
var _last_tick := -1

@onready var _roost: Roost = $BossRoost
@onready var _boarding_door: LockedDoor = $BoardingDoor


func _setup() -> void:
	map = MAP
	tiles_texture = preload("res://assets/sprites/tiles_final.png")
	music = "gates"
	hint_zones = HINT_ZONES
	retry_hints = RETRY_HINTS
	key_hints = {"maintenance_key": "A maintenance key! The vending\nmachine is in the lounge"}
	locked_hints = {"BoardingDoor": "Sealed while the chickens\nhold the gate!"}
	exit_door = $PlaneDoor
	clear_title = "YOU MADE YOUR FLIGHT!"
	next_label = "THE END"
	next_level = ""


func _build() -> void:
	_roost.totem_formed.connect(_on_boss_formed)
	_boarding_door.player_entered.connect(_on_boarding_door_entered)
	# The boss's chickens wait, still, until she steps into the boarding area.
	for chicken in _boss_chickens():
		chicken.set_physics_process(false)


func _ready() -> void:
	super()
	# Only reachable through Security in a real run; when this level is
	# started on its own for testing, hand her the pass she'd have.
	if not _player.inventory.has_key_item("boarding_pass") and GameManager.last_checkpoint.get("checkpoint") == "start":
		_player.inventory.add_key_item("boarding_pass")


func _physics_process(delta: float) -> void:
	super(delta)
	if _level_over:
		return
	if not _fight_started and not boss_beaten and _player.global_position.x > ARENA_X + 8:
		_start_fight()
	if escape_left >= 0.0:
		_update_escape(delta)


func _boss_chickens() -> Array[Chicken]:
	var found: Array[Chicken] = []
	for node in $Entities.get_children():
		if node is Chicken and str(node.name).begins_with("BossChicken"):
			found.append(node as Chicken)
	return found


# ---------- the boss ----------

func _start_fight() -> void:
	_fight_started = true
	_roost.wake()
	for chicken in _boss_chickens():
		chicken.set_physics_process(true)
	AudioManager.play_music("boss")
	show_event_hint("The chickens are gathering\nat the nest...")


func _on_boss_formed(totem: Totem) -> void:
	boss = totem
	totem.staggered.connect(_on_boss_staggered)
	totem.broken.connect(_on_boss_broken)
	_hud.show_boss(BOSS_HITS, BOSS_HITS)
	show_event_hint(BOSS_HINT)


func _on_boss_staggered(hits_left: int) -> void:
	_hud.show_boss(hits_left, BOSS_HITS)
	show_event_hint(STAGGER_HINT)


func _on_boss_broken(_fell: bool) -> void:
	boss_beaten = true
	_hud.show_boss(0, 0)
	_boarding_door.sealed = false
	_start_escape()
	# The boss is down for good: this is the new checkpoint.
	($Entities/CheckpointEscape as Checkpoint).activate()


# ---------- the escape ----------

func _start_escape() -> void:
	escape_left = ESCAPE_TIME
	_vent_timer = 1.0
	AudioManager.play("pa_chime")
	AudioManager.play_music("boss")
	show_event_hint(ESCAPE_HINT)


func _update_escape(delta: float) -> void:
	escape_left -= delta
	_hud.show_countdown(maxf(escape_left, 0.0))
	var secs := int(ceilf(escape_left))
	if secs != _last_tick and secs <= 10 and secs > 0:
		AudioManager.play("tick")
	_last_tick = secs
	if escape_left <= 0.0:
		escape_left = -1.0
		_hud.show_countdown(-1.0)
		_player.knock_out("time")
		return
	_vent_timer -= delta
	if _vent_timer <= 0.0:
		_vent_timer = VENT_INTERVAL
		if get_tree().get_nodes_in_group("chickens").size() < MAX_CHICKENS:
			var vent := _nearest_vent()
			if vent:
				vent.spawn()


## A vent in the same area as the player (boarding area or jet bridge),
## not right on top of her.
func _nearest_vent() -> ChickenVent:
	var on_bridge := _player.global_position.y > 26 * TILE
	var best: ChickenVent = null
	var best_score := INF
	for node in get_children():
		var vent := node as ChickenVent
		if vent == null or (vent.drop_point().y > 26 * TILE) != on_bridge:
			continue
		var distance := vent.drop_point().distance_to(_player.global_position)
		var score := absf(distance - 140.0)
		if score < best_score:
			best_score = score
			best = vent
	return best


func _on_boarding_door_entered() -> void:
	fade_through(func() -> void:
		_player.global_position = JET_BRIDGE_START
		_player.velocity = Vector2.ZERO
		($Entities/Player/Camera2D as Camera2D).reset_smoothing())


func _on_exit_entered() -> void:
	escape_left = -1.0
	_hud.show_countdown(-1.0)
	super()


func _on_player_died() -> void:
	escape_left = -1.0
	_hud.show_countdown(-1.0)
	super()


# ---------- checkpoints ----------

func _extra_state() -> Dictionary:
	return {"boss_beaten": boss_beaten}


func _restored(data: Dictionary) -> void:
	if not data.get("extra", {}).get("boss_beaten", false):
		return
	# Back to the moment the boss fell: it stays beaten, the door unsealed,
	# and the countdown starts again from the top.
	boss_beaten = true
	_fight_started = true
	_roost.dormant = true
	for chicken in _boss_chickens():
		chicken.free()
	_boarding_door.sealed = false
	_start_escape()

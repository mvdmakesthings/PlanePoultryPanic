extends GameLevel
## Level 3: the Food Court. Amanda comes in from Security at the bottom of a
## big court ringed by restaurant fronts, packed with chickens and snacks.
## Three vending machines open with maintenance keys, but there are only
## two keys: one in the staff kitchen (top left), one by a lost bag (east).
## The way out to the gates is at the top, behind a sunken seating plaza
## with a roost where chickens stack into the first totem. Restroom stalls
## (top right) are hiding spots.
##
## The layout is the text map below (see LevelBuilder for the legend; in
## this tileset "." is the checker floor, "," rust carpet, "=" the plaza's
## wood and "~" red diner carpet); the rest comes from GameLevel.

const MAP: Array[String] = [
	"################################################################",
	"################################################################",
	"################################################################",
	"################################################################",
	"#...........##,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,##...........#",
	"#...........##,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,##...........#",
	"#...........##....................................##...........#",
	"#...........##....................................##...........#",
	"#...........##....................................##...........#",
	"#...........##............============............##...........#",
	"#...........##............============............##...........#",
	"#...........##............============............##...........#",
	"#...........##............============............##...........#",
	"######..######............============............######..######",
	"######..######............============............######..######",
	"######..######............============............######..######",
	"######..######............============............######..######",
	"#,,,,,....................................................,,,,,#",
	"#,,,,,....................................................,,,,,#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#...............~~~~~~~~~..............~~~~~~~~~...............#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"################################################################",
]
const HINT_ZONES := [
	{"zone": Rect2i(26, 34, 12, 5), "text": "The Food Court! Stock up\non snacks, but the gates\nare to the north"},
	{"zone": Rect2i(20, 31, 9, 5), "text": "Vending machines open with a\nmaintenance key. Two keys,\nthree machines: choose!"},
	{"zone": Rect2i(1, 4, 11, 9), "text": "The staff kitchen. Somebody\nleft a key around here"},
	{"zone": Rect2i(24, 17, 16, 5), "text": "Four chickens on a nest stack\ninto a TOTEM! A thrown snack\nbreaks it up while it forms"},
	{"zone": Rect2i(52, 4, 11, 9), "text": "Restroom stalls: hide in\none to shake off a chase"},
]
const KEY_HINT := "A maintenance key! {interact} at a\nvending machine to open it"
const TOTEM_HINT := "A TOTEM! Ram it with a cart,\nfreeze its base, or leave\n3 snacks beside it"
const RETRY_HINTS := {
	"peck": [
		"Ram the totem with a luggage cart\nto topple it.",
		"Freeze the totem's base with the\nextinguisher, then shove it over.",
		"Three snacks beside a totem\nbreak it apart, no fight needed.",
		"Too many chickens? Hide in a\nrestroom stall ({interact}).",
		"Chickens stop for a thrown snack.\nToss one ({use_item}) and slip past.",
	],
}
const NEXT_LEVEL := "res://scenes/levels/level_04_gates.tscn"
## PA announcements, played in turn (see GameLevel.pa_lines).
const PA_LINES := [
	"The Food Court is open. The chickens\nhave been very clear about that.",
	"Vending machines now accept maintenance\nkeys only. Exact change is extinct.",
	"Please do not stack the chickens.\nThe chickens will stack themselves.",
	"Today's special: everything.\nTomorrow's special: unknown.",
]

var _shown_totem_hint := false


func _setup() -> void:
	map = MAP
	pa_lines = PA_LINES
	tiles_texture = preload("res://assets/sprites/tiles_food_court.png")
	# The GDD gives Security and the Food Court one track.
	music = "security"
	hint_zones = HINT_ZONES
	retry_hints = RETRY_HINTS
	key_hints = {"maintenance_key": KEY_HINT}
	exit_door = $GatesDoor
	clear_title = "FOOD COURT CLEARED!"
	next_label = "ON TO THE GATES"
	next_level = NEXT_LEVEL if ResourceLoader.exists(NEXT_LEVEL) else ""


func _build() -> void:
	$Roost.totem_formed.connect(_on_totem_formed)


func _on_totem_formed(_totem: Totem) -> void:
	if not _shown_totem_hint:
		_shown_totem_hint = true
		show_event_hint(TOTEM_HINT)

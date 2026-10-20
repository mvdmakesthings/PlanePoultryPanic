extends GameLevel
## Level 4: the Gate Areas. Three gate lounges, A, B and C, left to right,
## each harder than the last, joined by corridors with two moving walkways
## (one each way) and a speed panel. At full speed a walkway flings
## chickens off its far end into the wall stub there. Gate A has a rage
## patch; Gate B a roost, a vending machine, and a south room (with the key
## for it) behind a shutter; Gate C two roosts, all three mushrooms, and the
## door on to the last flight's gate, C13. Each lounge starts with a
## checkpoint (Gate A's is the level start).
##
## The layout is the text map below (see LevelBuilder for the legend; in
## this tileset "," is teal carpet, "~" the lounges' grid carpet and "."
## terminal tile); the rest comes from GameLevel.

const MAP: Array[String] = [
	"##################################################################################################################################",
	"##################################################################################################################################",
	"##################################################################################################################################",
	"##################################################################################################################################",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,#",
	"#,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,#",
	"#,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,#",
	"#,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,#",
	"#,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,######################,,,~~~~~~~~~~,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,.......................##,,,,,,,,,,,,,,,,,,,,,,,,,.......................##,,,,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,.......................##,,,,,,,,,,,,,,,,,,,,,,,,,.......................##,,,,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,.......................##,,,,,,,,,,,,,,,,,,,,,,,,,.......................##,,,,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,............................,,,,,,,,,,,,~~~~~~~~~~............................,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,............................,,,,,,,,,,,,~~~~~~~~~~............................,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,##.......................,,,,,,,,,,,,~~~~~~~~~~,,,##.......................,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,##.......................,,,,,,,,,,,,~~~~~~~~~~,,,##.......................,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,##.......................,,,,,,,,,,,,~~~~~~~~~~,,,##.......................,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,##.......................,,,,,,,,,,,,,,,,,,,,,,,,,##.......................,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,###################################..###################################,,,,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,###################################..###################################,,,,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,###################################..###################################,,,,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,~~~~~~~~~~,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,~~~~~~~~~~,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"#,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,######################,,,,,,,,,,,,,,,,,,,,,,,,,,,,#",
	"##################################################################################################################################",
]
const HINT_ZONES := [
	{"zone": Rect2i(1, 12, 6, 8), "text": "The gate areas. The last\nflight leaves from Gate C,\ntwo lounges east"},
	{"zone": Rect2i(26, 10, 6, 5), "text": "Moving walkways carry you\nfaster one way, slower the\nother. Chickens too!"},
	{"zone": Rect2i(35, 10, 6, 3), "text": "{interact} at the panel sets the\nwalkway speed. At FULL,\nchickens fly off the end!"},
	{"zone": Rect2i(51, 13, 6, 6), "text": "Gate B. A roost, and a\nvending machine: the key's\nin the south room"},
	{"zone": Rect2i(60, 22, 8, 4), "text": "{interact} at the switch drops\nthe shutter behind you"},
	{"zone": Rect2i(101, 13, 6, 6), "text": "Gate C: two roosts. Gate\nC13 to the last flight is\nat the far end"},
]
const TOTEM_HINT := "A TOTEM! Ram it with a cart,\nfreeze its base, or leave\n3 snacks beside it"
const RETRY_HINTS := {
	"peck": [
		"Lure chickens onto a walkway,\nthen turn it up to FULL.",
		"Ride a full-speed walkway to\noutrun a chase.",
		"Ram a totem with a luggage cart\nto topple it.",
		"The supply closet in Gate C\nis a place to hide ({interact}).",
		"Chickens stop for a thrown snack.\nToss one ({use_item}) and slip past.",
	],
}
const NEXT_LEVEL := "res://scenes/levels/level_05_final_gate.tscn"
## PA announcements, played in turn (see GameLevel.pa_lines).
const PA_LINES := [
	"Please keep right on the moving walkways.\nChickens, please keep... anywhere else.",
	"Flight 13, the last flight out, is now\nboarding at Gate C13.",
	"Mushrooms growing in the carpet are\nnot complimentary. Do not eat them.",
	"Gate agents are on a permanent break.\nPassengers will kindly board themselves.",
	"Our Platinum lounge is for members only.\nNobody is Platinum anymore. Go on in.",
]

var _shown_totem_hint := false


func _setup() -> void:
	map = MAP
	pa_lines = PA_LINES
	tiles_texture = preload("res://assets/sprites/tiles_gates.png")
	music = "gates" if ResourceLoader.exists(AudioManager.MUSIC_DIR + "gates.wav") else "security"
	hint_zones = HINT_ZONES
	retry_hints = RETRY_HINTS
	key_hints = {"maintenance_key": "A maintenance key! The vending\nmachine is up in Gate B"}
	exit_door = $FinalGateDoor
	clear_title = "GATE AREAS CLEARED!"
	next_label = "ON TO GATE C13"
	next_level = NEXT_LEVEL if ResourceLoader.exists(NEXT_LEVEL) else ""


func _build() -> void:
	for roost: Roost in [$RoostB, $RoostC1, $RoostC2]:
		roost.totem_formed.connect(_on_totem_formed)


func _on_totem_formed(_totem: Totem) -> void:
	if not _shown_totem_hint:
		_shown_totem_hint = true
		show_event_hint(TOTEM_HINT)

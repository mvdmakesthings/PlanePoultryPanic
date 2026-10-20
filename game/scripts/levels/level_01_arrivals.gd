extends GameLevel
## Level 1: Arrivals / Baggage Claim, the tutorial level. The player steps
## off their flight into the arrival lounge, learns to walk, run and throw
## snacks in the hallway, then comes down into Baggage Claim, where the
## door to Security is locked. The maintenance key that opens it is in the
## staff room on the far side of the carousel.
##
## The layout is the text map below (see LevelBuilder for the legend); the
## rest (hints, checkpoints, retrying, the exit) comes from GameLevel.

const MAP: Array[String] = [
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
## shows at the top of the screen. Buttons in braces match the player's bindings.
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
const HURT_HINT := "Ouch! {eat_snack} eats a snack\nto heal a suitcase"
const LOCKED_HINT := "Locked. Find a maintenance\nkey: try the staff room"
const KEY_HINT := "Got the maintenance key!\nBack to the SECURITY door"
const NEXT_LEVEL := "res://scenes/levels/level_02_security.tscn"
## PA announcements, played in turn (see GameLevel.pa_lines).
const PA_LINES := [
	"Welcome to Bawkston! Baggage from all\nflights is arriving on the carousel.",
	"Passengers are reminded not to feed\nthe wildlife. The wildlife has noticed.",
	"The last flight out departs from Gate C13.\nPlease proceed through Security.",
	"Lost and Found reports a surplus of\nsnacks, and a shortage of staff.",
	"Passengers are reminded that walls are\nnot usually doors. Except that one.",
]


func _setup() -> void:
	map = MAP
	pa_lines = PA_LINES
	music = "arrivals"
	hint_zones = HINT_ZONES
	hurt_hint = HURT_HINT
	locked_hints = {"SecurityDoor": LOCKED_HINT}
	key_hints = {"maintenance_key": KEY_HINT}
	exit_door = $SecurityDoor
	clear_title = "ARRIVALS CLEARED!"
	next_label = "ON TO SECURITY"
	next_level = NEXT_LEVEL if ResourceLoader.exists(NEXT_LEVEL) else ""


func _build() -> void:
	LevelBuilder.paint_carousel(_props, CAROUSEL_RECT, CHUTE_COLUMN)
	LevelBuilder.add_carousel(self, CAROUSEL_RECT, CHUTE_COLUMN)

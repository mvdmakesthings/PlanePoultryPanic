extends GameLevel
## Level 2: the Security Checkpoint. Amanda comes in from Arrivals at the
## bottom left of the queue hall, past an extinguisher cabinet and the first
## mushroom patch, up into the scanner hall, through one of three scanner
## lanes (the third has a roll-down shutter on a switch), and into the
## screening area. Her boarding pass is in the bins at its far end, guarded
## by an egg-shooter patch, and the gate to the Food Court at the end of the
## corridor reads it. The restrooms (top left) and a supply closet are
## places to hide.
##
## The layout is the text map below (see LevelBuilder for the legend; in
## this tileset "," is rubber matting, "~" dark tread and "=" hazard
## stripes); the rest comes from GameLevel.

const MAP: Array[String] = [
	"################################################################",
	"################################################################",
	"################################################################",
	"################################################################",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##.............#",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##.............#",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##.............#",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##.............#",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............#",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............#",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............#",
	"#...........##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##.............#",
	"#####..#############==########==########==######################",
	"#####..#############==########==########==######################",
	"#####..#############==########==########==######################",
	"#####..#############==########==########==######################",
	"#...................==........==........==.....................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"#..............................................................#",
	"########################################################...#####",
	"########################################################...#####",
	"########################################################...#####",
	"########################################################...#####",
	"#..............................................................#",
	"#.........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................#",
	"#.........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................#",
	"#.........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................#",
	"#.........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................#",
	"#.........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................#",
	"#.........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................#",
	"#.........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................#",
	"#..............................................................#",
	"################################################################",
]
const HINT_ZONES := [
	{"zone": Rect2i(1, 31, 6, 6), "text": "Security. Your boarding pass\nis in the screening bins\nup ahead"},
	{"zone": Rect2i(5, 28, 7, 3), "text": "{interact} takes the fire\nextinguisher from the cabinet"},
	{"zone": Rect2i(44, 28, 18, 9), "text": "Chickens that eat mushrooms\npower up! {use_item} sprays foam:\nit freezes them, and kills patches"},
	{"zone": Rect2i(38, 16, 9, 4), "text": "{interact} at the switch drops the\nshutter. It flattens any\nchicken under it"},
	{"zone": Rect2i(47, 16, 6, 4), "text": "Chased? {interact} at a door\nhides you until they give up"},
	{"zone": Rect2i(1, 16, 10, 8), "text": "Teal caps can hop over\nthings. Restrooms ahead:\nstalls are good hiding spots"},
	{"zone": Rect2i(14, 4, 20, 8), "text": "Screening. Search the\nbins for a boarding pass"},
	{"zone": Rect2i(36, 4, 12, 8), "text": "Purple caps shoot eggs.\nDuck behind a table or cart"},
]
const PASS_HINT := "Got a boarding pass! The FOOD\nCOURT gate is through the east door"
const GATE_HINT := "No boarding pass, no entry.\nSearch the screening bins"
const RETRY_HINTS := {
	"peck": [
		"Raging chickens outrun you.\nFreeze them with the extinguisher ({use_item}).",
		"Spray a mushroom patch and no\nchicken can power up there again.",
		"Hide in a stall or the closet ({interact})\nto shake off a chase.",
		"Lure a chicken under the shutter\nwith a snack, then drop it.",
		"Chickens stop for a thrown snack.\nToss one ({use_item}) and slip past.",
	],
}
const NEXT_LEVEL := "res://scenes/levels/level_03_food_court.tscn"
## PA announcements, played in turn (see GameLevel.pa_lines).
const PA_LINES := [
	"Please remove all snacks, keys and\ndignity from your pockets.",
	"Unattended chickens will be left\nunattended. We're not going near them.",
	"A valid boarding pass is required\nfor your final departure.",
	"Liquids over 100 ml have been confiscated.\nSo has the security staff.",
	"This is a reminder that this is a video\ngame. Please continue to panic.",
]
## A gag: hide in restroom stall 3 this long and the PA notices.
const STALL_GAG_TIME := 10.0
const STALL_GAG_PA := "Stall 3 is occupied.\nForever."

var _stall_time := 0.0
var _stall_announced := false


func _setup() -> void:
	map = MAP
	pa_lines = PA_LINES
	tiles_texture = preload("res://assets/sprites/tiles_security.png")
	music = "security" if ResourceLoader.exists(AudioManager.MUSIC_DIR + "security.wav") else "arrivals"
	hint_zones = HINT_ZONES
	retry_hints = RETRY_HINTS
	key_hints = {"boarding_pass": PASS_HINT}
	locked_hints = {"PassGate": GATE_HINT}
	exit_door = $PassGate
	clear_title = "SECURITY CLEARED!"
	next_label = "ON TO THE FOOD COURT"
	next_level = NEXT_LEVEL if ResourceLoader.exists(NEXT_LEVEL) else ""


func _physics_process(delta: float) -> void:
	super(delta)
	if ($Stall3 as HidingSpot).is_occupied():
		_stall_time += delta
		if _stall_time >= STALL_GAG_TIME and not _stall_announced:
			_stall_announced = true
			announce(STALL_GAG_PA)
	else:
		_stall_time = 0.0
		_stall_announced = false

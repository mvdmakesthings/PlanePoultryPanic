class_name ParticleBurst
extends Node2D
## A handful of little bits flying out from one spot: dust, feathers,
## crumbs, foam, egg bits, sparks, sparkles or confetti, drawn from
## effects_particles.png. Each bit moves across the floor and up and down
## in height (the 3/4 view), lands, and blinks out at the end of its life.
## Positions are whole pixels. Frees itself when every bit is gone.
##
##   ParticleBurst.spawn(get_parent(), "feather", global_position)

const SHEET := preload("res://assets/sprites/effects_particles.png")
const SIZE := 8
## Row of each kind in the sheet (see docs/art-style-guide.md).
const KINDS: Array[String] = ["dust", "feather", "crumb", "foam", "egg", "spark", "sparkle", "confetti"]
## How each kind behaves:
##   count     how many bits
##   speed     floor speed range, px/s
##   rise      upward speed range, px/s
##   gravity   pulls height back down, px/s^2 (negative floats up)
##   drag      floor speed lost per second, px/s
##   life      lifetime range, s
##   animate   true: play the row's frames over the life; false: pick one
##   height    starting height above the floor, px
##   flutter   side-to-side sway while airborne, px
##   above     drawn over characters (true) or sorted with them (false)
##   row       (optional) the sheet row to draw, for a kind that borrows
##             another's art
const STYLES := {
	# A ring of dust thrown out by a totem's stomp or a heavy landing.
	"stomp": {"row": "dust", "count": 10, "speed": [55.0, 75.0], "rise": [2.0, 8.0], "gravity": 0.0,
		"drag": 140.0, "life": [0.35, 0.5], "animate": true, "height": 1.0, "flutter": 0.0, "above": false},
	"dust": {"count": 3, "speed": [8.0, 20.0], "rise": [4.0, 12.0], "gravity": 0.0, "drag": 60.0,
		"life": [0.4, 0.55], "animate": true, "height": 1.0, "flutter": 0.0, "above": false},
	"feather": {"count": 4, "speed": [20.0, 45.0], "rise": [30.0, 60.0], "gravity": 70.0, "drag": 40.0,
		"life": [0.8, 1.2], "animate": false, "height": 8.0, "flutter": 2.0, "above": true},
	"crumb": {"count": 5, "speed": [15.0, 40.0], "rise": [30.0, 60.0], "gravity": 300.0, "drag": 30.0,
		"life": [0.5, 0.8], "animate": false, "height": 6.0, "flutter": 0.0, "above": true},
	"foam": {"count": 3, "speed": [0.0, 10.0], "rise": [0.0, 0.0], "gravity": 0.0, "drag": 30.0,
		"life": [1.8, 2.6], "animate": true, "height": 0.0, "flutter": 0.0, "above": false},
	"egg": {"count": 6, "speed": [20.0, 50.0], "rise": [30.0, 70.0], "gravity": 300.0, "drag": 30.0,
		"life": [0.5, 0.8], "animate": false, "height": 6.0, "flutter": 0.0, "above": true},
	"spark": {"count": 5, "speed": [50.0, 100.0], "rise": [20.0, 60.0], "gravity": 400.0, "drag": 120.0,
		"life": [0.2, 0.35], "animate": true, "height": 4.0, "flutter": 0.0, "above": true},
	"sparkle": {"count": 4, "speed": [10.0, 25.0], "rise": [10.0, 25.0], "gravity": -20.0, "drag": 20.0,
		"life": [0.45, 0.7], "animate": true, "height": 6.0, "flutter": 0.0, "above": true},
	# Amanda's gas: a slow puff of dust that hangs and drifts up. Spawn it
	# with modulate set to a sickly green.
	"gas": {"row": "dust", "count": 9, "speed": [10.0, 28.0], "rise": [2.0, 8.0], "gravity": -6.0,
		"drag": 18.0, "life": [0.9, 1.3], "animate": true, "height": 6.0, "flutter": 1.0, "above": true},
	"confetti": {"count": 16, "speed": [20.0, 50.0], "rise": [70.0, 110.0], "gravity": 160.0, "drag": 25.0,
		"life": [1.1, 1.5], "animate": false, "height": 20.0, "flutter": 3.0, "above": true},
}

## Each bit: floor position (offset from the burst), floor velocity,
## height, rising speed, age, life, frame (for variants), sway phase.
var _bits: Array[Dictionary] = []
var _style: Dictionary
var _row := 0


## Spawns a burst of kind at a floor position, as a child of parent (use
## the level's y-sorted Entities, or the emitter's parent). direction, if
## given, aims the burst; otherwise it sprays every way. count 0 uses the
## kind's usual number; height, if not negative, is how far above the floor
## the bits start (a snack at her mouth, an egg at chest height).
static func spawn(parent: Node, kind: String, at: Vector2, direction := Vector2.ZERO,
		count := 0, height := -1.0) -> ParticleBurst:
	if parent == null or not is_instance_valid(parent):
		return null
	var burst := ParticleBurst.new()
	burst.setup(kind, direction, count, height)
	parent.add_child(burst)
	burst.global_position = at.round()
	return burst


func setup(kind: String, direction := Vector2.ZERO, count := 0, height := -1.0) -> void:
	_style = STYLES[kind]
	_row = KINDS.find(_style.get("row", kind))
	if _style["above"]:
		z_index = 1
	var variants := SHEET.get_width() / SIZE
	for i in (count if count > 0 else int(_style["count"])):
		var angle := randf() * TAU
		if direction != Vector2.ZERO:
			angle = direction.angle() + randf_range(-0.7, 0.7)
		var speed: Array = _style["speed"]
		var rise: Array = _style["rise"]
		var life: Array = _style["life"]
		var floor_velocity := Vector2.from_angle(angle) * randf_range(speed[0], speed[1])
		# The floor is seen at an angle, so movement toward or away from
		# the camera looks shorter.
		floor_velocity.y *= 0.5
		_bits.append({
			"pos": Vector2.ZERO, "vel": floor_velocity,
			"h": height if height >= 0.0 else float(_style["height"]), "vh": randf_range(rise[0], rise[1]),
			"age": 0.0, "life": randf_range(life[0], life[1]),
			"frame": randi() % variants, "phase": randf() * TAU,
		})


func _process(delta: float) -> void:
	var drag: float = _style["drag"]
	var gravity: float = _style["gravity"]
	for i in range(_bits.size() - 1, -1, -1):
		var bit := _bits[i]
		bit["age"] += delta
		if bit["age"] >= bit["life"]:
			_bits.remove_at(i)
			continue
		bit["pos"] += bit["vel"] * delta
		bit["vel"] = (bit["vel"] as Vector2).move_toward(Vector2.ZERO, drag * delta)
		bit["vh"] -= gravity * delta
		bit["h"] = maxf(bit["h"] + bit["vh"] * delta, 0.0)
		if bit["h"] == 0.0 and bit["vh"] < 0.0:
			# Landed: it stops where it fell.
			bit["vh"] = 0.0
			bit["vel"] = Vector2.ZERO
	if _bits.is_empty():
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var flutter: float = _style["flutter"]
	for bit in _bits:
		var t: float = bit["age"] / bit["life"]
		# Blink out over the last fifth of its life, never fading: pixels
		# are either there or not.
		if t > 0.8 and int(bit["age"] * 20.0) % 2 == 0:
			continue
		var frame: int = int(t * 4.0) if _style["animate"] else bit["frame"]
		var sway := 0.0
		if flutter > 0.0 and bit["h"] > 0.0:
			sway = sin(bit["age"] * 8.0 + bit["phase"]) * flutter
		var at := (bit["pos"] as Vector2) + Vector2(sway, -bit["h"]) - Vector2(SIZE, SIZE) / 2.0
		draw_texture_rect_region(SHEET, Rect2(at.round(), Vector2(SIZE, SIZE)),
			Rect2(frame * SIZE, _row * SIZE, SIZE, SIZE))


## Bits still showing, for tests.
func bit_count() -> int:
	return _bits.size()

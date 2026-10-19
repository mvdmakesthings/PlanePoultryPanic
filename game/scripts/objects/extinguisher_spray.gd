class_name ExtinguisherSpray
extends Node2D
## One blast of the fire extinguisher: a short cone of foam, plus a burst
## right around the player. For as long as the foam hangs in the air it
## freezes every chicken in the cone or the burst, including ones that run
## into it, and destroys any mushroom patch in the cone. Place it at the
## player's feet.

const FOAM := [Color("ffffff"), Color("c0cbdc"), Color("8b9bb4")]

@export var length := 60.0
## Half the cone's opening angle, in degrees.
@export var half_angle := 38.0
@export var freeze_time := 4.0
## Chickens this close to the player's feet freeze whichever way the player
## faces, so a chicken pecking from the side or behind can still be stopped.
@export var point_blank_radius := 20.0
## Foam is drawn from the nozzle at waist height, slightly ahead of the feet.
const NOZZLE_HEIGHT := 4.0
## How long the foam hangs in the air, still freezing chickens that enter it.
@export var lifetime := 0.5

var direction := Vector2.DOWN

var _time := 0.0
var _puffs: Array[Vector3] = []  # x, y offset along the cone, and size
var _burst: Array[Vector2] = []  # puff positions in a ring around the feet


func _ready() -> void:
	_apply()
	for i in 22:
		var t := randf_range(0.15, 1.0)
		var angle := deg_to_rad(randf_range(-half_angle, half_angle)) * t
		var offset := direction.rotated(angle) * length * t
		_puffs.append(Vector3(offset.x, offset.y, randf_range(1.0, 2.5)))
	for i in 10:
		# Flattened ring, since the floor is seen at an angle.
		var around := Vector2.from_angle(i * TAU / 10.0) * point_blank_radius * 0.7
		_burst.append(Vector2(around.x, around.y * 0.5))


func _physics_process(_delta: float) -> void:
	_apply()


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	queue_redraw()


## True if a floor position is inside the spray cone, measured from the
## player's feet.
func in_cone(pos: Vector2) -> bool:
	var to := pos - global_position
	if to.length() > length:
		return false
	return to.length() < 0.5 or absf(rad_to_deg(direction.angle_to(to))) <= half_angle


## True if a floor position is close enough to be caught in the point-blank burst.
func in_burst(pos: Vector2) -> bool:
	return global_position.distance_to(pos) <= point_blank_radius


func _apply() -> void:
	for node in get_tree().get_nodes_in_group("chickens"):
		var chicken := node as Chicken
		if chicken.state == Chicken.State.FROZEN:
			continue
		if in_cone(chicken.global_position) or in_burst(chicken.global_position):
			chicken.freeze(freeze_time)
	for node in get_tree().get_nodes_in_group("mushroom_patches"):
		var patch := node as MushroomPatch
		if in_cone(patch.global_position):
			patch.destroy()


func _draw() -> void:
	var grow := 1.0 + _time / lifetime
	for i in _burst.size():
		draw_circle((_burst[i] * grow).round(), 1.0 + grow * 0.5, FOAM[i % FOAM.size()])
	draw_set_transform(direction * NOZZLE_HEIGHT + Vector2(0, -NOZZLE_HEIGHT))
	for i in _puffs.size():
		var p := _puffs[i]
		var pos := Vector2(p.x, p.y) * (0.6 + 0.4 * grow)
		draw_circle(pos.round(), roundf(p.z * grow), FOAM[i % FOAM.size()])

class_name ExtinguisherSpray
extends Node2D
## One blast of the fire extinguisher: a short cone of foam. On the first
## frame it freezes every chicken in the cone and destroys any mushroom patch
## in it, then the foam drifts out and fades.

const FOAM := [Color("ffffff"), Color("c0cbdc"), Color("8b9bb4")]

@export var length := 44.0
## Half the cone's opening angle, in degrees.
@export var half_angle := 32.0
@export var freeze_time := 4.0
@export var lifetime := 0.4

var direction := Vector2.DOWN

var _time := 0.0
var _puffs: Array[Vector3] = []  # x, y offset along the cone, and size


func _ready() -> void:
	_apply()
	for i in 22:
		var t := randf_range(0.15, 1.0)
		var angle := deg_to_rad(randf_range(-half_angle, half_angle)) * t
		var offset := direction.rotated(angle) * length * t
		_puffs.append(Vector3(offset.x, offset.y, randf_range(1.0, 2.5)))


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	queue_redraw()


## True if a world position is inside the spray cone.
func in_cone(pos: Vector2) -> bool:
	var to := pos - global_position
	if to.length() > length or to.length() < 0.5:
		return to.length() < 0.5
	return absf(rad_to_deg(direction.angle_to(to))) <= half_angle


func _apply() -> void:
	for node in get_tree().get_nodes_in_group("chickens"):
		var chicken := node as Chicken
		# Aim at the chicken's body, a few pixels above its feet.
		if in_cone(chicken.global_position + Vector2(0, -4)):
			chicken.freeze(freeze_time)
	for node in get_tree().get_nodes_in_group("mushroom_patches"):
		var patch := node as MushroomPatch
		if in_cone(patch.global_position + Vector2(0, -4)):
			patch.destroy()


func _draw() -> void:
	var grow := 1.0 + _time / lifetime
	for i in _puffs.size():
		var p := _puffs[i]
		var pos := Vector2(p.x, p.y) * (0.6 + 0.4 * grow)
		draw_circle(pos.round(), roundf(p.z * grow), FOAM[i % FOAM.size()])

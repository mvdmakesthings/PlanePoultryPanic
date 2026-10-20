class_name SpeedPanel
extends Node2D
## A control panel on the wall that sets the speed of one or more moving
## walkways: Interact below it to step slow, normal, full, then slow again.
## Its dial and light show the speed. Position this node at its top-left
## corner on the wall face, its bottom 2 px above the floor line.

const SIZE := Vector2(12, 14)
const NAMES := ["slow", "normal", "FULL"]

@export var walkway_paths: Array[NodePath] = []
@export var reach := 22.0

var walkways: Array[Walkway] = []

var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	for path in walkway_paths:
		var walkway := get_node_or_null(path) as Walkway
		if walkway:
			walkways.append(walkway)


func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 10.0)


func can_interact(player: Player) -> bool:
	return not walkways.is_empty() and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	for walkway in walkways:
		walkway.cycle_speed()
	AudioManager.play("switch", base_point())
	FloatText.spawn(player, "Speed: " + NAMES[walkways[0].speed])


func _physics_process(_delta: float) -> void:
	_sprite.frame = walkways[0].speed if not walkways.is_empty() else 0
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()


func _draw() -> void:
	if _show_prompt:
		InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, "{interact} walkway speed")

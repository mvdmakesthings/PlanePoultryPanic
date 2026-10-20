class_name ShutterSwitch
extends Node2D
## A lever box on the wall that drops or raises a SecurityShutter. Interact
## below it to flip it. Position this node at the box's top-left corner on
## the wall face, its bottom 2 px above the floor line.

const SIZE := Vector2(10, 14)

## The shutter this switch works.
@export var shutter_path: NodePath
## How close the player's feet must be to the spot below the switch.
@export var reach := 22.0

var shutter: SecurityShutter
var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	shutter = get_node_or_null(shutter_path) as SecurityShutter


## The floor spot right below the switch, where the player stands to use it.
func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 10.0)


func can_interact(player: Player) -> bool:
	return shutter != null and player.global_position.distance_to(base_point()) <= reach


func interact(_player: Player) -> void:
	AudioManager.play("switch", base_point())
	shutter.toggle()


func _physics_process(_delta: float) -> void:
	_sprite.frame = 1 if shutter and shutter.is_closed else 0
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()


func _draw() -> void:
	if _show_prompt:
		var text := "{interact} raise shutter" if shutter.is_closed else "{interact} drop shutter"
		InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, text)

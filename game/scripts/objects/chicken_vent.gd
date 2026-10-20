class_name ChickenVent
extends Node2D
## A vent high on the back wall that chickens drop out of during the escape.
## spawn() knocks the grille open and drops a chicken on the floor below,
## already chasing the player. Position this node at the vent's top-left
## corner on the wall face.

const CHICKEN_SCENE := preload("res://scenes/characters/chicken.tscn")
const SIZE := Vector2(16, 12)

## Where new chickens are added: the level's depth-sorted entity layer.
@export var entities_path: NodePath = ^"../Entities"

var _open_left := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


## The floor spot below the vent where chickens land.
func drop_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, 28.0)


func spawn() -> Chicken:
	var chicken := CHICKEN_SCENE.instantiate() as Chicken
	chicken.position = drop_point()
	get_node(entities_path).add_child(chicken)
	chicken.alert()
	_open_left = 0.6
	AudioManager.play("vent", drop_point())
	return chicken


func _process(delta: float) -> void:
	_open_left -= delta
	_sprite.frame = 1 if _open_left > 0.0 else 0

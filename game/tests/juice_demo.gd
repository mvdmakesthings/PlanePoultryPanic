extends Node
## Stages the game-feel effects one after another in the prototype room,
## for recording a clip of them (not a test: it checks nothing). Run from
## the repo root, writing PNG frames to a folder:
##   godot --path game --write-movie /tmp/juice/frame.png --fixed-fps 30 res://tests/juice_demo.tscn

const ROOM := preload("res://scenes/levels/prototype_room.tscn")
const CHICKEN := preload("res://scenes/characters/chicken.tscn")
const TOTEM := preload("res://scenes/characters/totem.tscn")

var _room: Node
var _player: Player
var _entities: Node2D


func _ready() -> void:
	SaveSystem.save_path = "user://demo_save.json"
	SaveSystem.settings_path = "user://demo_settings.cfg"
	_room = ROOM.instantiate()
	add_child(_room)
	_player = _room.get_node("Entities/Player")
	_entities = _room.get_node("Entities")
	for chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.queue_free()
	_player.global_position = Vector2(200, 250)
	_player.facing = Vector2.RIGHT
	await _wait(0.8)

	# A chicken pecks her.
	var pecker := _chicken(Vector2(222, 250))
	pecker.alert()
	await _wait(1.6)
	if is_instance_valid(pecker):
		pecker.defeat()
	await _wait(1.0)

	# Foam freezes a chicken; then a shove sends it into the wall.
	var frozen := _chicken(Vector2(236, 250))
	_player._invincible_timer = 0.0
	_player.give_extinguisher(5)
	_player.facing = Vector2.RIGHT
	_player.spray()
	await _wait(1.2)
	frozen.global_position = Vector2(236, 250)
	frozen.freeze(3.0)
	await _wait(1.0)

	# A cart rolls through a chicken and slams into the furniture.
	for chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.queue_free()
	var cart: LuggageCart = _room.get_node("Entities/Cart1")
	cart.global_position = Vector2(180, 290)
	_chicken(Vector2(240, 290))
	_player.global_position = Vector2(160, 290)
	await _wait(0.6)
	cart.interact(_player)
	await _wait(1.6)

	# A totem stacks up, stomps, then topples.
	_player.global_position = Vector2(200, 250)
	var totem := TOTEM.instantiate() as Totem
	totem.members = 4
	totem.position = Vector2(250, 240)
	_entities.add_child(totem)
	await _wait(1.0)
	totem.state = Totem.State.STOMP_WINDUP
	totem._timer = 0.4
	await _wait(1.2)
	totem.topple(Vector2.RIGHT)
	await _wait(2.0)

	# The boss takes a hit, then goes down.
	for chicken in get_tree().get_nodes_in_group("chickens"):
		chicken.queue_free()
	var boss := TOTEM.instantiate() as Totem
	boss.members = 6
	boss.max_hits = 2
	boss.crowned = true
	boss.position = Vector2(250, 240)
	_entities.add_child(boss)
	await _wait(1.2)
	boss.topple(Vector2.RIGHT)
	await _wait(2.4)
	boss._reeling = 0.0
	boss.topple(Vector2.RIGHT)
	await _wait(2.4)

	await AudioManager.silence()
	get_tree().quit()


func _chicken(at: Vector2) -> Chicken:
	var chicken := CHICKEN.instantiate() as Chicken
	chicken.position = at
	_entities.add_child(chicken)
	return chicken


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

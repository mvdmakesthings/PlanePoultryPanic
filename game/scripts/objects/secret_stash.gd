class_name SecretStash
extends Node2D
## A secret stash to search: the CONFISCATED bin in Security, the chickens'
## snack hoard in the Food Court, or Amanda's own bag riding the carousel.
## Interact beside it to search it, which finds its secret and spills its
## snacks (and an extinguisher, if it has one) at the player's feet.
## Position this node at the middle of the stash's base.

const PICKUP_SCENE := preload("res://scenes/objects/item_pickup.tscn")
const KINDS: Array[String] = ["confiscated", "hoard", "amanda_bag"]
## A bag that rides into the chute comes back around after this long.
const BELT_RETURN_TIME := 3.0

@export var secret_id := ""
## Which stash this is: a row of secret_stashes.png.
@export_enum("confiscated", "hoard", "amanda_bag") var kind := "confiscated"
@export_range(0, 6) var snacks := 2
## Charges of a fire extinguisher inside, or 0 for none.
@export var extinguisher_charges := 0
@export var prompt := "{interact} search"
@export var found_text := "Snacks!"
## Rides the baggage carousel's belt (Amanda's bag).
@export var rides_belt := false
@export var reach := 20.0
## Raises the sprite off the floor, for a stash sitting on a table.
@export var lift := 0.0

var searched := false

var _show_prompt := false
var _start := Vector2.ZERO
var _return_left := 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	_start = global_position
	_sprite.offset.y -= lift
	_sprite.frame = KINDS.find(kind) * 2
	if secret_id != "" and GameManager.has_secret(secret_id):
		searched = true
		_sprite.frame += 1


func can_interact(player: Player) -> bool:
	return not searched and visible and player.carrying == null \
		and player.global_position.distance_to(global_position) <= reach


func interact(player: Player) -> void:
	searched = true
	_sprite.frame = KINDS.find(kind) * 2 + 1
	_show_prompt = false
	queue_redraw()
	if secret_id != "":
		GameManager.find_secret(secret_id)
	AudioManager.play("vend", global_position)
	FloatText.spawn(player, found_text)
	var items: Array[Dictionary] = []
	for i in snacks:
		items.append({"item": "snack", "count": 1})
	if extinguisher_charges > 0:
		items.append({"item": "extinguisher", "count": extinguisher_charges})
	for i in items.size():
		var pickup := PICKUP_SCENE.instantiate() as ItemPickup
		pickup.item = items[i]["item"]
		pickup.count = items[i]["count"]
		# A little arc at her feet, so whatever fits goes straight in the bag.
		var spread := (i - (items.size() - 1) / 2.0) * 10.0
		pickup.position = player.position + Vector2(spread, 6 + absf(spread) * 0.3)
		player.get_parent().add_child.call_deferred(pickup)


func _physics_process(delta: float) -> void:
	if rides_belt and not searched:
		_ride(delta)
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()


## Goes round on the carousel; into the chute and back out where it started.
func _ride(delta: float) -> void:
	if not visible:
		_return_left -= delta
		if _return_left <= 0.0:
			global_position = _start
			visible = true
		return
	global_position += Carousel.push_for(get_tree(), global_position) * delta
	if Carousel.in_any_chute(get_tree(), global_position):
		visible = false
		_return_left = BELT_RETURN_TIME


func _draw() -> void:
	if _show_prompt:
		InteractPrompt.draw(self, 0.0, -20.0 - lift, prompt)

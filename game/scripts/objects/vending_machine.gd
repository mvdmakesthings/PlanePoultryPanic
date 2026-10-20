class_name VendingMachine
extends StaticBody2D
## A snack machine on the floor. Interact in front of it with a maintenance
## key to break it open (the key is used up): it drops its snacks on the
## floor in front. Its base is solid. Position this node at the middle of
## its base.

const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)
const PICKUP_SCENE := preload("res://scenes/objects/item_pickup.tscn")

@export var key_item := "maintenance_key"
## How many snacks it drops.
@export_range(1, 6) var snacks := 3
@export var reach := 22.0

var is_locked := true

var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("unlockables")


## The floor spot in front of the machine, where the player stands to use it.
func base_point() -> Vector2:
	return global_position + Vector2(0, 10)


func can_interact(player: Player) -> bool:
	return is_locked and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if not player.inventory.use_key_item(key_item):
		FloatText.spawn(player, "Needs a key")
		AudioManager.play("locked", global_position)
		return
	unlock()
	FloatText.spawn(player, "Snacks!")


## Opens the machine and drops its snacks. quiet (restoring a save) opens
## it without sound or snacks.
func unlock(quiet := false) -> void:
	if not is_locked:
		return
	is_locked = false
	_sprite.frame = 1
	_show_prompt = false
	queue_redraw()
	if quiet:
		return
	AudioManager.play("vend", global_position)
	for i in snacks:
		var pickup := PICKUP_SCENE.instantiate() as ItemPickup
		# Spread out in a little arc in front of the flap.
		var spread := (i - (snacks - 1) / 2.0) * 10.0
		pickup.position = position + Vector2(spread, 14 + absf(spread) * 0.3)
		get_parent().add_child.call_deferred(pickup)


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var prompt := player != null and player.interact_target == self
	if prompt != _show_prompt:
		_show_prompt = prompt
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 11.0, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)
	if _show_prompt:
		var player := get_tree().get_first_node_in_group("player") as Player
		var has_key := player != null and player.inventory.has_key_item(key_item)
		InteractPrompt.draw(self, 0.0, -33.0, "{interact} open" if has_key else "{interact} needs a key")

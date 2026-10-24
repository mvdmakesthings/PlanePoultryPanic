class_name Roost
extends Node2D
## A nest where chickens gather to form a totem. Wandering chickens nearby
## head here and settle. Once enough have settled, they spend a couple of
## seconds stacking up (with a clear warning), then become a Totem. A thrown
## snack draws them off and breaks the formation up.

signal totem_formed(totem: Totem)

const TOTEM_SCENE := preload("res://scenes/characters/totem.tscn")
const POOF_SCENE := preload("res://scenes/objects/feather_poof.tscn")
const WARNING_COLOR := Color("e43b44")
## A totem forming this close makes Amanda say "Nope." (about 10 tiles).
const NOPE_RANGE := 160.0

## Chickens this close wander over to the roost.
@export var call_radius := 120.0
@export var chickens_needed := 4
## Seconds of stacking before the totem stands up.
@export var formation_time := 2.0
## After a totem is toppled or scattered, the roost stays quiet this long.
@export var cooldown := 20.0
## Where totems are added: the room's depth-sorted entity layer. The roost
## itself sits outside it, so the nest always draws flat on the floor.
@export var entities_path: NodePath = ^"../Entities"
@export_group("Totem")
## The totem's settings: the final boss is taller, takes several hits,
## wears the mushroom crown and ignores snacks.
@export var totem_hits := 1
@export var totem_crowned := false
@export var totem_snack_proof := false
## A dormant roost draws no chickens until wake() is called.
@export var dormant := false
## Forms only once: after its totem is broken it stays empty.
@export var once := false

var _forming_time := 0.0
var _cooldown_left := 0.0
var _next_spot := 0


func _ready() -> void:
	add_to_group("roosts")


func is_open() -> bool:
	return _cooldown_left <= 0.0 and not dormant


func wake() -> void:
	dormant = false


## Hands out settling spots in turn, so no two chickens aim for the same one.
func claim_spot() -> int:
	_next_spot += 1
	return _next_spot % 5


## Where a settling chicken stands: spread around the middle of the nest.
func spot_for(index: int) -> Vector2:
	return global_position + Vector2.from_angle(index * TAU / 5.0) * Vector2(5, 2.5)


## True while the stack is going up, so settled chickens can bob.
func is_forming() -> bool:
	return _forming_time > 0.0


func start_cooldown() -> void:
	_cooldown_left = cooldown
	if once:
		dormant = true


func _physics_process(delta: float) -> void:
	_cooldown_left -= delta
	var settled := settled_chickens()
	if settled.size() >= chickens_needed and is_open():
		_forming_time += delta
		if _forming_time >= formation_time:
			_form(settled)
	else:
		_forming_time = 0.0
	queue_redraw()


func settled_chickens() -> Array[Chicken]:
	var out: Array[Chicken] = []
	for node in get_tree().get_nodes_in_group("chickens"):
		var chicken := node as Chicken
		if chicken.is_roosting_at(self):
			out.append(chicken)
	return out


func _form(members: Array[Chicken]) -> void:
	_forming_time = 0.0
	var totem := TOTEM_SCENE.instantiate() as Totem
	totem.members = members.size()
	totem.home = self
	totem.max_hits = totem_hits
	totem.crowned = totem_crowned
	totem.snack_proof = totem_snack_proof
	totem.position = position
	for chicken in members:
		chicken.queue_free()
	var entities := get_node(entities_path)
	var poof := POOF_SCENE.instantiate() as Node2D
	poof.position = position
	entities.add_child(poof)
	entities.add_child(totem)
	totem_formed.emit(totem)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.global_position.distance_to(global_position) <= NOPE_RANGE:
		player.say("Nope.")


func _draw() -> void:
	# A flashing "!!" while the totem is stacking up: the player's cue to act.
	if is_forming() and int(_forming_time * 8.0) % 2 == 0:
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(-20, -34), "!!", HORIZONTAL_ALIGNMENT_CENTER, 40, 8, 2, Color("181425"))
		draw_string(font, Vector2(-20, -34), "!!", HORIZONTAL_ALIGNMENT_CENTER, 40, 8, WARNING_COLOR)

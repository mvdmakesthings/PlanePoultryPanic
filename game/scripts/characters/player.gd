class_name Player
extends CharacterBody2D
## The stranded passenger: 8-directional movement, stamina-limited running,
## luggage-icon health with invincibility frames, and a six-slot inventory.
## Space uses the selected item (throw a snack, spray the extinguisher), Q
## and R switch slots, E eats a snack, and G drops the selected item. While
## carrying a suitcase overhead, Space throws it and F puts it down.

## Health is counted in quarter suitcases (see SUITCASE).
signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal inventory_changed
signal died

const THROWN_SNACK_SCENE := preload("res://scenes/objects/thrown_snack.tscn")
const SPRAY_SCENE := preload("res://scenes/objects/extinguisher_spray.tscn")
const ITEM_PICKUP_SCENE := preload("res://scenes/objects/item_pickup.tscn")
const WALK_SHEET := preload("res://assets/sprites/player_walk.png")
const IDLE_SHEET := preload("res://assets/sprites/player_idle.png")
const WALK_EXTINGUISHER_SHEET := preload("res://assets/sprites/player_walk_extinguisher.png")
const IDLE_EXTINGUISHER_SHEET := preload("res://assets/sprites/player_idle_extinguisher.png")
const KO_SHEET := preload("res://assets/sprites/player_ko.png")
const FRAME_SIZE := Vector2i(16, 32)
## The knocked-out pose lies flat, so its frames are wide and short.
const KO_FRAME_SIZE := Vector2i(32, 20)
## Health units in one suitcase on the HUD. A chicken peck costs half a
## suitcase (PECK); an egg costs a single unit, a quarter of one.
const SUITCASE := 4
const PECK := SUITCASE / 2
const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)
## The extinguisher swings toward the nearest unfrozen chicken this close,
## whichever way the player is facing, so it works mid-chase.
const SPRAY_AIM_RANGE := 64.0

@export var walk_speed := 100.0
@export var run_speed := 150.0
## Walking speed while carrying a suitcase; running isn't possible then.
@export var carry_speed := 75.0
## Health in suitcases, as shown on the HUD.
@export var suitcases := 5
@export var max_stamina := 100.0
## Stamina spent per second while running.
@export var stamina_drain := 40.0
## Stamina recovered per second while not running.
@export var stamina_regen := 25.0
## After running dry, running is locked until stamina refills to this fraction.
@export_range(0.0, 1.0) var exhausted_recover_ratio := 0.3
@export var starting_snacks := 2
@export var invincibility_time := 1.5
@export var knockback_strength := 160.0
@export var knockback_decay := 800.0

## Current and maximum health, in quarter suitcases.
var health: int
var max_health: int
var stamina: float
var inventory := Inventory.new()
## Snacks held across all slots.
var snacks: int:
	get:
		return inventory.count_of("snack")
## Fire extinguisher charges held; 0 means no extinguisher.
var extinguisher_charges: int:
	get:
		return inventory.count_of("extinguisher")
var facing := Vector2.DOWN
var is_dead := false
## The closest thing Interact would use right now, or null. Only this one
## shows its prompt, so overlapping prompts never stack up.
var interact_target: Node2D = null
## The suitcase held overhead, or null.
var carrying: Suitcase = null
## The closet the player is hiding in, or null.
var hidden_in: HidingSpot = null
var is_hidden: bool:
	get:
		return hidden_in != null

var _invincible_timer := 0.0
var _exhausted := false
var _knockback := Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	max_health = suitcases * SUITCASE
	health = max_health
	stamina = max_stamina
	inventory.add_stackable("snack", starting_snacks)
	inventory.changed.connect(inventory_changed.emit)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	SpriteSheets.add_directional(frames, "walk", WALK_SHEET, FRAME_SIZE, 8.0)
	SpriteSheets.add_directional(frames, "idle", IDLE_SHEET, FRAME_SIZE, 2.0)
	SpriteSheets.add_directional(frames, "walk_ext", WALK_EXTINGUISHER_SHEET, FRAME_SIZE, 8.0)
	SpriteSheets.add_directional(frames, "idle_ext", IDLE_EXTINGUISHER_SHEET, FRAME_SIZE, 2.0)
	frames.add_animation("ko")
	frames.set_animation_speed("ko", 3.0)
	for column in KO_SHEET.get_width() / KO_FRAME_SIZE.x:
		var atlas := AtlasTexture.new()
		atlas.atlas = KO_SHEET
		atlas.region = Rect2(Vector2(column * KO_FRAME_SIZE.x, 0), KO_FRAME_SIZE)
		frames.add_frame("ko", atlas)
	_sprite.sprite_frames = frames
	_sprite.play("idle_down")
	# Deferred so listeners that connect in the level's _ready get initial values.
	_emit_state.call_deferred()


func _physics_process(delta: float) -> void:
	if is_hidden:
		# Inside a closet: no moving, but Interact still lets the player out.
		interact_target = _nearest_interactable()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()

	var running := Input.is_action_pressed("run") and input != Vector2.ZERO and not _exhausted \
		and carrying == null
	_update_stamina(running, delta)

	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_decay * delta)
	var speed := carry_speed if carrying else run_speed if running else walk_speed
	velocity = input * speed + _knockback
	velocity += Carousel.push_for(get_tree(), global_position)
	move_and_slide()

	# Both hands are full while carrying, so nothing else can be used.
	interact_target = null if carrying else _nearest_interactable()
	_update_animation(input, running)
	_update_invincibility(delta)


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if is_hidden:
		if event.is_action_pressed("interact"):
			interact()
		return
	if carrying:
		if event.is_action_pressed("use_item"):
			throw_suitcase()
		elif event.is_action_pressed("interact"):
			put_down_suitcase()
		return
	if event.is_action_pressed("use_item"):
		use_item()
	elif event.is_action_pressed("eat_snack"):
		eat_snack()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("prev_item"):
		inventory.cycle(-1)
	elif event.is_action_pressed("next_item"):
		inventory.cycle(1)
	elif event.is_action_pressed("drop_item"):
		drop_item()


## Returns true if the hit landed (false while dead or invincible).
func take_damage(amount: int, from_position: Vector2) -> bool:
	if is_dead or is_hidden or _invincible_timer > 0.0:
		return false
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	_knockback = (global_position - from_position).normalized() * knockback_strength
	put_down_suitcase()
	if health == 0:
		_die()
	else:
		_invincible_timer = invincibility_time
	return true


## Picks up count of an item. Returns how many didn't fit, so pickups can
## leave the rest lying where they were.
func pick_up(item: String, count: int) -> int:
	if is_dead or is_hidden:
		return count
	if Inventory.ITEMS[item]["stack"] > 1:
		return count - inventory.add_stackable(item, count)
	if not inventory.add_single(item, count):
		return count
	# A newly picked up tool goes straight into the player's hand.
	if item == "extinguisher":
		inventory.select_item(item)
	return 0


## Returns false when there's no room, so the snack stays in the world.
func add_snack() -> bool:
	return pick_up("snack", 1) == 0


## Uses the selected item: throw a snack or spray the extinguisher.
func use_item() -> void:
	match inventory.selected_item():
		"snack":
			throw_snack()
		"extinguisher":
			spray()


func throw_snack() -> void:
	var index := inventory.slot_with("snack")
	if index < 0:
		return
	inventory.take_from(index)
	var snack := THROWN_SNACK_SCENE.instantiate() as ThrownSnack
	snack.direction = facing
	snack.position = position
	get_parent().add_child(snack)


## Eats a snack from any slot (the selected one first) to heal a suitcase.
func eat_snack() -> void:
	var index := inventory.slot_with("snack")
	if index < 0 or health >= max_health:
		return
	inventory.take_from(index)
	health = mini(health + SUITCASE, max_health)
	health_changed.emit(health, max_health)


## Returns false if every slot is full.
func give_extinguisher(charges: int) -> bool:
	return pick_up("extinguisher", charges) == 0


## Sprays a cone of foam ahead, freezing chickens and killing mushroom
## patches. An extinguisher that runs dry is thrown away.
func spray() -> void:
	var index := inventory.slot_with("extinguisher")
	if index < 0:
		return
	inventory.take_from(index)
	facing = _spray_aim()
	var foam := SPRAY_SCENE.instantiate() as ExtinguisherSpray
	foam.direction = facing
	foam.position = position
	get_parent().add_child(foam)


## Aim at the nearest threatening chicken in range, or straight ahead.
func _spray_aim() -> Vector2:
	var best := SPRAY_AIM_RANGE
	var aim := facing
	for node in get_tree().get_nodes_in_group("chickens"):
		var chicken := node as Chicken
		var distance := global_position.distance_to(chicken.global_position)
		if chicken.state != Chicken.State.FROZEN and distance < best and distance > 0.5:
			best = distance
			aim = global_position.direction_to(chicken.global_position)
	for node in get_tree().get_nodes_in_group("totems"):
		var totem := node as Node2D
		var distance := global_position.distance_to(totem.global_position)
		if distance < best and distance > 0.5:
			best = distance
			aim = global_position.direction_to(totem.global_position)
	return aim


## Lifts a suitcase overhead with both hands.
func carry(suitcase: Suitcase) -> void:
	carrying = suitcase
	suitcase.lift(self)


## Throws the carried suitcase the way the player is facing.
func throw_suitcase() -> void:
	if carrying == null:
		return
	carrying.throw(facing)
	carrying = null


## Sets the carried suitcase down at the player's feet, if holding one.
func put_down_suitcase() -> void:
	if carrying == null:
		return
	carrying.put_down()
	carrying = null


## Drops the whole selected slot on the floor just ahead, to make room.
func drop_item() -> void:
	var slot := inventory.remove_selected()
	if slot.is_empty():
		return
	var pickup := ITEM_PICKUP_SCENE.instantiate() as ItemPickup
	pickup.item = slot["item"]
	pickup.count = slot["count"]
	pickup.dropped = true
	pickup.position = position + facing * 10.0
	get_parent().add_child(pickup)


## Uses the nearest thing in reach that can be interacted with, if any.
func interact() -> void:
	var target := _nearest_interactable()
	if target:
		target.interact(self)


func _nearest_interactable() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as Node2D
		var distance := global_position.distance_to(target.global_position)
		if target.can_interact(self) and distance < best:
			best = distance
			nearest = target
	return nearest


## Steps into a closet: hidden, untouchable, and out of the way.
func hide_in(spot: HidingSpot) -> void:
	hidden_in = spot
	global_position = spot.base_point()
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	collision_layer = 0
	visible = false


## Steps back out of the closet.
func leave_hiding() -> void:
	hidden_in = null
	collision_layer = 2
	visible = true


## Stops all player control, e.g. when the level is won.
func freeze() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)
	modulate.a = 1.0


func _update_stamina(running: bool, delta: float) -> void:
	var previous := stamina
	if running:
		stamina = maxf(stamina - stamina_drain * delta, 0.0)
		if stamina == 0.0:
			_exhausted = true
	else:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)
		if _exhausted and stamina >= max_stamina * exhausted_recover_ratio:
			_exhausted = false
	if stamina != previous:
		stamina_changed.emit(stamina, max_stamina)


func _update_animation(input: Vector2, running: bool) -> void:
	var direction := SpriteSheets.direction_name(facing)
	var animation := "walk" if input != Vector2.ZERO else "idle"
	# Carry the extinguisher in hand while it's the selected item.
	if inventory.selected_item() == "extinguisher" and carrying == null:
		animation += "_ext"
	animation += "_" + direction
	if _sprite.animation != animation:
		_sprite.play(animation)
	_sprite.speed_scale = 1.6 if running else 1.0


func _update_invincibility(delta: float) -> void:
	if _invincible_timer <= 0.0:
		return
	_invincible_timer -= delta
	var blink_on := int(_invincible_timer * 15.0) % 2 == 0
	modulate.a = 1.0 if _invincible_timer <= 0.0 or blink_on else 0.3


func _die() -> void:
	is_dead = true
	freeze()
	# Flat on their back, centered over where they stood.
	_sprite.offset = Vector2(0, -KO_FRAME_SIZE.y / 2.0)
	_sprite.play("ko")
	queue_redraw()
	died.emit()


func _emit_state() -> void:
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	inventory_changed.emit()


func _draw() -> void:
	# Soft floor shadow under the feet; the sprite draws on top of it.
	# Lying down, the shadow stretches the length of the body.
	var width := 2.5 if is_dead else 1.0
	draw_set_transform(Vector2(0, -3) if is_dead else Vector2.ZERO, 0.0, Vector2(width, 0.4))
	draw_circle(Vector2.ZERO, 6.0, SHADOW_COLOR)

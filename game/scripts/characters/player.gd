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
const RUN_SHEET := preload("res://assets/sprites/player_run.png")
const RUN_EXTINGUISHER_SHEET := preload("res://assets/sprites/player_run_extinguisher.png")
const THROW_SHEET := preload("res://assets/sprites/player_throw.png")
const HURT_SHEET := preload("res://assets/sprites/player_hurt.png")
const EAT_SHEET := preload("res://assets/sprites/player_eat.png")
const DEFEAT_SHEET := preload("res://assets/sprites/player_defeat.png")
## The defeat frames are wide enough for her to fall flat, like the KO pose.
const DEFEAT_FRAME_SIZE := Vector2i(32, 32)
## How long each action plays over the walk or idle, in seconds.
const ACTION_TIMES := {"throw": 0.3, "eat": 0.45, "hurt": 0.35}
const KO_SHEET := preload("res://assets/sprites/player_ko.png")
## Flyaway hair drawn over every animation, messier as health drops. Rows
## are directions, columns are mess levels 1-3; each frame reaches
## HAIR_MARGIN pixels above and beside the player frame.
const HAIR_SHEET := preload("res://assets/sprites/player_hair_mess.png")
const HAIR_LEVELS := 3
const HAIR_MARGIN := 4
## Below each of these fractions of full health, the hair gets one level messier.
const HAIR_MESS_BELOW: Array[float] = [0.75, 0.5, 0.25]
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
## How far away chickens hear her running footsteps.
const RUN_NOISE_RANGE := 48.0

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
## What landed the last hit: "peck", "egg" or "stomp" (anything heavier),
## so the retry screen can say what went wrong.
var last_hit := ""
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
## An action animation playing over walking and idling ("throw", "eat",
## "hurt"), and how much longer it plays.
var _action := ""
var _action_left := 0.0
var _hair: Sprite2D
## Top opaque row of each animation frame, so the hair follows the head.
var _head_tops := {}
var _sheet_images := {}

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
	SpriteSheets.add_directional(frames, "run", RUN_SHEET, FRAME_SIZE, 14.0)
	SpriteSheets.add_directional(frames, "run_ext", RUN_EXTINGUISHER_SHEET, FRAME_SIZE, 14.0)
	SpriteSheets.add_directional(frames, "throw", THROW_SHEET, FRAME_SIZE, 10.0, false)
	SpriteSheets.add_directional(frames, "hurt", HURT_SHEET, FRAME_SIZE, 1.0, false)
	# Eating is only drawn facing the camera.
	_add_strip(frames, "eat_down", EAT_SHEET, FRAME_SIZE, 7.0, false)
	_add_strip(frames, "defeat", DEFEAT_SHEET, DEFEAT_FRAME_SIZE, 8.0, false)
	_add_strip(frames, "ko", KO_SHEET, KO_FRAME_SIZE, 3.0, true)
	_sprite.sprite_frames = frames
	_hair = Sprite2D.new()
	_hair.texture = HAIR_SHEET
	_hair.centered = false
	_hair.hframes = HAIR_LEVELS
	_hair.vframes = SpriteSheets.DIRECTIONS.size()
	_sprite.add_child(_hair)
	_sprite.frame_changed.connect(_update_hair)
	_sprite.frame_changed.connect(_play_footstep)
	_sprite.animation_changed.connect(_update_hair)
	health_changed.connect(func(_current: int, _maximum: int) -> void: _update_hair())
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
	last_hit = "peck" if amount == PECK else "egg" if amount < PECK else "stomp"
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	AudioManager.play("hurt")
	# A heavier hit shakes harder and holds the moment longer.
	Juice.shake(1.5 + amount * 0.75)
	Juice.hitstop(0.04 + 0.01 * amount)
	Juice.flash(_sprite, Juice.DANGER, 0.2)
	Juice.squash(_sprite, Vector2(1.25, 0.8))
	_knockback = (global_position - from_position).normalized() * knockback_strength
	put_down_suitcase()
	if health == 0:
		_die()
	else:
		_invincible_timer = invincibility_time
		_start_action("hurt")
	return true


## Knocked out by something other than a hit, like missing the flight.
## reason becomes last_hit, for the retry screen's hint.
func knock_out(reason: String) -> void:
	if is_dead:
		return
	if is_hidden and hidden_in:
		hidden_in.interact(self)
	last_hit = reason
	health = 0
	health_changed.emit(health, max_health)
	_die()


## Picks up count of an item. Returns how many didn't fit, so pickups can
## leave the rest lying where they were.
func pick_up(item: String, count: int) -> int:
	if is_dead or is_hidden:
		return count
	if Inventory.KEY_ITEMS.has(item):
		inventory.add_key_item(item, count)
		FloatText.spawn(self, "Got it!")
		AudioManager.play("key")
		return 0
	if Inventory.ITEMS[item]["stack"] > 1:
		var added := inventory.add_stackable(item, count)
		RunStats.item_collected(added)
		if added > 0:
			AudioManager.play("pickup")
		return count - added
	if not inventory.add_single(item, count):
		return count
	RunStats.item_collected()
	AudioManager.play("pickup")
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
	RunStats.item_used()
	var snack := THROWN_SNACK_SCENE.instantiate() as ThrownSnack
	snack.direction = facing
	snack.position = position
	get_parent().add_child(snack)
	AudioManager.play("throw")
	_start_action("throw")


## Eats a snack from any slot (the selected one first) to heal a suitcase.
func eat_snack() -> void:
	var index := inventory.slot_with("snack")
	# Say why nothing happened, so a press never seems ignored.
	if index < 0:
		FloatText.spawn(self, "No snacks")
		return
	if health >= max_health:
		FloatText.spawn(self, "Full!")
		return
	inventory.take_from(index)
	RunStats.item_used()
	AudioManager.play("eat")
	ParticleBurst.spawn(get_parent(), "crumb", global_position, Vector2.ZERO, 0, 18.0)
	_start_action("eat")
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
	if inventory.slots[index].is_empty():
		RunStats.item_used()
	facing = _spray_aim()
	var foam := SPRAY_SCENE.instantiate() as ExtinguisherSpray
	foam.direction = facing
	foam.position = position
	get_parent().add_child(foam)
	AudioManager.play("spray")


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
	AudioManager.play("throw")
	_start_action("throw")


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
	RunStats.item_dropped(slot)
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


## Plays an action (throw, eat, hurt) over walking and idling for a moment.
func _start_action(action: String) -> void:
	_action = action
	_action_left = ACTION_TIMES[action]
	_sprite.play(action + "_" + ("down" if action == "eat" else SpriteSheets.direction_name(facing)))


func _update_animation(input: Vector2, running: bool) -> void:
	var direction := SpriteSheets.direction_name(facing)
	if _action_left > 0.0:
		_action_left -= get_physics_process_delta_time()
		return
	var animation := "idle"
	if input != Vector2.ZERO:
		animation = "run" if running else "walk"
	# Carry the extinguisher in hand while it's the selected item.
	if inventory.selected_item() == "extinguisher" and carrying == null:
		animation += "_ext"
	animation += "_" + direction
	if _sprite.animation != animation:
		# Switching between walking and running keeps the stride going.
		var frame := _sprite.frame
		_sprite.play(animation)
		if input != Vector2.ZERO:
			_sprite.frame = frame


## 0 while health is high, up to 3 (wild) when it's nearly gone.
func hair_mess_level() -> int:
	var ratio := float(health) / float(max_health)
	var level := 0
	for threshold in HAIR_MESS_BELOW:
		if ratio < threshold:
			level += 1
	return level


func _update_hair() -> void:
	var level := hair_mess_level()
	var animation := String(_sprite.animation)
	var row := SpriteSheets.DIRECTIONS.find(animation.get_slice("_", animation.get_slice_count("_") - 1))
	_hair.visible = level > 0 and not is_dead and row >= 0
	if not _hair.visible:
		return
	_hair.frame = row * HAIR_LEVELS + level - 1
	var top_left := _sprite.offset - Vector2(FRAME_SIZE) / 2.0
	var head_top := _head_top(_sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame))
	_hair.position = top_left + Vector2(-HAIR_MARGIN, head_top - HAIR_MARGIN)


## The first row of a frame with anything drawn in it: where the head starts.
func _head_top(texture: Texture2D) -> int:
	if _head_tops.has(texture):
		return _head_tops[texture]
	var top := 0
	var atlas := texture as AtlasTexture
	if atlas:
		if not _sheet_images.has(atlas.atlas):
			_sheet_images[atlas.atlas] = atlas.atlas.get_image()
		var image: Image = _sheet_images[atlas.atlas]
		var region := Rect2i(atlas.region)
		top = region.size.y
		for y in region.size.y:
			for x in region.size.x:
				if image.get_pixel(region.position.x + x, region.position.y + y).a > 0.0:
					top = y
					break
			if top == y:
				break
	_head_tops[texture] = top
	return top


## A footstep on each contact frame of the walk and run cycles.
func _play_footstep() -> void:
	var animation := String(_sprite.animation)
	if (animation.begins_with("walk") or animation.begins_with("run")) and _sprite.frame % 2 == 0:
		AudioManager.play("step")
		# Running kicks up a little dust behind her, and chickens nearby hear
		# it. Walking is silent.
		if animation.begins_with("run"):
			ParticleBurst.spawn(get_parent(), "dust", global_position - facing * 3.0, -facing)
			Chicken.make_noise(get_tree(), global_position, RUN_NOISE_RANGE)


func _update_invincibility(delta: float) -> void:
	if _invincible_timer <= 0.0:
		return
	_invincible_timer -= delta
	var blink_on := int(_invincible_timer * 15.0) % 2 == 0
	modulate.a = 1.0 if _invincible_timer <= 0.0 or blink_on else 0.3


func _die() -> void:
	is_dead = true
	freeze()
	# Flinch, buckle and fall flat on her back, then lie there seeing stars.
	_sprite.offset = Vector2(0, -DEFEAT_FRAME_SIZE.y / 2.0 + 1.0)
	_sprite.play("defeat")
	_sprite.animation_finished.connect(_on_defeat_finished, CONNECT_ONE_SHOT)
	_update_hair()
	AudioManager.play("death")
	queue_redraw()
	died.emit()


func _on_defeat_finished() -> void:
	# Centered over where she stood, like the defeat frames.
	_sprite.offset = Vector2(0, -KO_FRAME_SIZE.y / 2.0)
	_sprite.play("ko")


## One animation from a single-row sheet of frame_size frames.
static func _add_strip(frames: SpriteFrames, anim_name: String, sheet: Texture2D,
		frame_size: Vector2i, fps: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for column in sheet.get_width() / frame_size.x:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(column * frame_size.x, 0), frame_size)
		frames.add_frame(anim_name, atlas)


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

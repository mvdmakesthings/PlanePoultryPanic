class_name MushroomPatch
extends Node2D
## A patch of magic mushrooms. A chicken that eats here powers up in the
## patch's mode. Eaten patches dim and regrow after a while.
##
## In a campaign level, a ripe patch spreads: every spread_time seconds it
## grows a sprout a few tiles away. A sprout can't be eaten; it ripens into
## a full patch (which spreads in turn) after sprout_time, unless Amanda
## stomps it by walking over it or sprays it. The level caps how many
## patches there can be (GameLevel.mushroom_cap). Sprouts aren't saved, so
## a retry puts the level back to its placed patches.

const VARIETIES: Array[String] = ["flight", "rage", "egg"]
const FRAMES_PER_VARIETY := 3
const PATCH_SHEET := preload("res://assets/sprites/mushroom_patch.png")
const SPROUT_SHEET := preload("res://assets/sprites/mushroom_sprout.png")
const SPROUT_FRAMES := 2
const TILE := LevelBuilder.TILE
## Sprouts land this far from their parent, in tiles.
const SPREAD_MIN := 2.0
const SPREAD_MAX := 4.0
## How many random spots to try before giving up on a sprout this time.
const SPREAD_TRIES := 12
## Keep-away distances for a new sprout, in px.
const CLEAR_OF_CHECKPOINTS := 3.0 * TILE
const CLEAR_OF_PLAYER := 2.0 * TILE
const CLEAR_OF_HIDING := 1.5 * TILE
const CLEAR_OF_PATCHES := 12.0
## The last stretch of a sprout's growth, when it wobbles as a tell.
const WOBBLE_TIME := 2.0
## Amanda stomps a sprout when her feet come this close.
const STOMP_REACH := 7.0

@export_enum("flight", "rage", "egg") var variety := "rage"
@export var regrow_time := 15.0
@export var spore_fps := 3.0
## Seconds a ripe patch takes to grow each sprout (0 never spreads).
@export var spread_time := 25.0
## Seconds a sprout takes to ripen into a full patch.
@export var sprout_time := 8.0

var is_ripe := true
## Still a sprout: can't be eaten, can be stomped.
var is_sprout := false

var _regrow_timer := 0.0
var _spread_timer := 0.0
var _sprout_timer := 0.0
var _anim_time := 0.0
var _destroyed := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("mushroom_patches")
	_spread_timer = spread_time
	if is_sprout:
		is_ripe = false
		_sprout_timer = sprout_time
		_sprite.texture = SPROUT_SHEET
		_sprite.hframes = SPROUT_FRAMES


func _process(delta: float) -> void:
	if _destroyed:
		return
	if is_sprout:
		_grow(delta)
		return
	if not is_ripe:
		_regrow_timer -= delta
		if _regrow_timer <= 0.0:
			is_ripe = true
			_spread_timer = spread_time
			modulate = Color.WHITE
	else:
		_spread_timer -= delta
		if _spread_timer <= 0.0:
			_spread_timer = spread_time
			_spread()
	_anim_time += delta
	# Only ripe patches puff spores.
	var frame := int(_anim_time * spore_fps) % FRAMES_PER_VARIETY if is_ripe else 0
	_sprite.frame = VARIETIES.find(variety) * FRAMES_PER_VARIETY + frame


## Kills the patch for good (sprayed with the fire extinguisher).
func destroy() -> void:
	remove_from_group("mushroom_patches")
	_destroyed = true
	is_ripe = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


## Returns false if the patch was already eaten.
func eat() -> bool:
	if not is_ripe:
		return false
	is_ripe = false
	_regrow_timer = regrow_time
	_spread_timer = spread_time
	modulate = Color(1, 1, 1, 0.45)
	return true


## Squashed flat under Amanda's feet. Only sprouts can be stomped.
func stomp() -> void:
	if not is_sprout or _destroyed:
		return
	remove_from_group("mushroom_patches")
	_destroyed = true
	rotation = 0.0
	AudioManager.play("splat")
	ParticleBurst.spawn(get_parent(), "dust", global_position, Vector2.ZERO, 4)
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.6, 0.25), 0.08)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _grow(delta: float) -> void:
	_sprout_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and not player.is_dead and not player.is_hidden \
			and global_position.distance_to(player.global_position) < STOMP_REACH:
		stomp()
		return
	if _sprout_timer <= 0.0:
		_ripen()
		return
	var late := _sprout_timer < sprout_time / 2.0
	_sprite.frame = VARIETIES.find(variety) * SPROUT_FRAMES + (1 if late else 0)
	rotation = sin(_sprout_timer * 30.0) * 0.2 if _sprout_timer < WOBBLE_TIME else 0.0


## The sprout pops into a full patch, ready to eat and to spread.
func _ripen() -> void:
	is_sprout = false
	is_ripe = true
	rotation = 0.0
	_spread_timer = spread_time
	_sprite.texture = PATCH_SHEET
	_sprite.hframes = FRAMES_PER_VARIETY
	AudioManager.play("poof")
	ParticleBurst.spawn(get_parent(), "sparkle", global_position, Vector2.ZERO, 0, 6.0)
	_sprite.scale = Vector2(0.6, 1.4)
	create_tween().tween_property(_sprite, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Grows a sprout nearby, if the level allows it and there's room.
func _spread() -> void:
	var level := owner as GameLevel
	if level == null or spread_time <= 0.0 or level.patch_count() >= level.mushroom_cap:
		return
	for i in SPREAD_TRIES:
		var spot := global_position \
			+ Vector2.from_angle(randf() * TAU) * randf_range(SPREAD_MIN, SPREAD_MAX) * TILE
		if can_sprout_at(spot.round()):
			_sprout(level, spot.round())
			return


func _sprout(level: GameLevel, at: Vector2) -> void:
	var sprout := load(scene_file_path).instantiate() as MushroomPatch
	sprout.variety = variety
	sprout.regrow_time = regrow_time
	sprout.spread_time = spread_time
	sprout.sprout_time = sprout_time
	sprout.is_sprout = true
	sprout.position = at
	get_parent().add_child(sprout)
	sprout.owner = level
	ParticleBurst.spawn(get_parent(), "dust", at, Vector2.ZERO, 3)
	level.mushroom_sprouted()


## True if a sprout may grow at this floor spot: open floor chickens can
## reach, off every belt, and clear of checkpoints, doors, the level's
## start, hiding spots, Amanda and other patches.
func can_sprout_at(spot: Vector2) -> bool:
	var level := owner as GameLevel
	var nav_map := get_world_2d().navigation_map
	# Off the baked floor, or too early to tell (not baked and synced yet).
	if NavigationServer2D.map_get_iteration_id(nav_map) == 0 \
			or not NavigationServer2D.map_get_closest_point_owner(nav_map, spot).is_valid() \
			or NavigationServer2D.map_get_closest_point(nav_map, spot).distance_to(spot) > 1.0:
		return false
	if Carousel.push_for(get_tree(), spot) != Vector2.ZERO:
		return false
	if level and spot.distance_to(level.start_point) < CLEAR_OF_CHECKPOINTS:
		return false
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if spot.distance_to((node as Node2D).global_position) < CLEAR_OF_CHECKPOINTS:
			return false
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is LockedDoor and spot.distance_to((node as LockedDoor).base_point()) < CLEAR_OF_CHECKPOINTS:
			return false
		if node is HidingSpot and spot.distance_to((node as HidingSpot).base_point()) < CLEAR_OF_HIDING:
			return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and spot.distance_to(player.global_position) < CLEAR_OF_PLAYER:
		return false
	for group in ["mushroom_patches", "pilot_caps"]:
		for node in get_tree().get_nodes_in_group(group):
			if spot.distance_to((node as Node2D).global_position) < CLEAR_OF_PATCHES:
				return false
	return true

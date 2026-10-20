class_name LockedDoor
extends Node2D
## A locked door in the back wall, like the door to Security. Interact
## below it while holding the right key item to unlock it (the key is used
## up, unless consume_key is off, as for the boarding-pass gates). Once unlocked, its doors slide open as the player gets close, and
## walking up into the doorway goes through.
## Position this node at the door's top-left corner on the wall face, and
## leave the wall tiles behind its lower face row open: the door brings its
## own collision there (see wall_gap()).

signal unlocked
## The player tried the door without the key.
signal interacted_locked
signal player_entered

const SIZE := Vector2(48, 32)
## Frames in security_door.png: locked, unlocked (closed), opening, open.
const FRAME_LOCKED := 0
const FRAME_CLOSED := 1
const FRAME_OPEN := 3
## Doorway opening inside the sprite, the same as the boarding gate's.
const DOORWAY := Rect2(8, 18, 32, 14)

## The key item that opens it.
@export var key_item := "maintenance_key"
## False for a pass that's only shown, like the boarding pass at a gate.
@export var consume_key := true
## Prompts, with and without the key, and what pops up on unlocking.
@export var unlock_prompt := "{interact} unlock"
@export var locked_prompt := "{interact} locked"
@export var unlocked_text := "Unlocked!"
## Starts unlocked, for an exit that needs no key.
@export var start_unlocked := false
## Won't open at all, key or not, until the level unseals it.
@export var sealed := false
@export var sealed_text := "Sealed"
@export var reach := 26.0
@export var open_distance := 56.0
@export var frames_per_second := 12.0

var is_locked := true

var _open_amount := 0.0
var _entered := false
var _show_prompt := false
var _barrier: StaticBody2D
var _target_frame := float(FRAME_CLOSED)

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	# Door posts either side of the doorway, and a barrier across it while locked.
	var face := Rect2(global_position + Vector2(0, 16), Vector2(SIZE.x, 16))
	LevelBuilder.add_wall(self, Rect2(face.position, Vector2(DOORWAY.position.x, face.size.y)))
	var right := global_position.x + DOORWAY.end.x
	LevelBuilder.add_wall(self, Rect2(Vector2(right, face.position.y), Vector2(face.end.x - right, face.size.y)))
	_barrier = LevelBuilder.add_wall(self, Rect2(
		Vector2(global_position.x + DOORWAY.position.x, face.position.y), Vector2(DOORWAY.size.x, face.size.y)))
	# Built in world space, so undo this node's own offset.
	for child in get_children():
		if child is StaticBody2D:
			child.position = -global_position
	_sprite.frame = FRAME_LOCKED
	add_to_group("unlockables")
	if start_unlocked:
		unlock(true)


## The wall tiles (in tile coordinates) this door replaces: its lower face row.
func wall_gap() -> Rect2i:
	var tile := Vector2i(global_position / LevelBuilder.TILE)
	return Rect2i(tile + Vector2i(0, 1), Vector2i(int(SIZE.x) / LevelBuilder.TILE, 1))


## The floor spot right below the door, where the player stands to use it.
func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 4.0)


func can_interact(player: Player) -> bool:
	return is_locked and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if sealed:
		FloatText.spawn(player, sealed_text)
		AudioManager.play("locked")
		interacted_locked.emit()
		return
	var has_key := player.inventory.has_key_item(key_item)
	if has_key and consume_key:
		player.inventory.use_key_item(key_item)
	if not has_key:
		FloatText.spawn(player, "It's locked")
		AudioManager.play("locked")
		interacted_locked.emit()
		return
	unlock()
	FloatText.spawn(player, unlocked_text)


## Unlocks the door. quiet skips the sound, for restoring a save.
func unlock(quiet := false) -> void:
	if not is_locked:
		return
	is_locked = false
	_barrier.queue_free()
	if not quiet:
		AudioManager.play("unlock")
		ParticleBurst.spawn(get_parent(), "sparkle", base_point(), Vector2.ZERO, 0, 12.0)
	_sprite.frame = FRAME_CLOSED
	_show_prompt = false
	queue_redraw()
	unlocked.emit()


## The doorway floor area in world space, where the player goes through.
func doorway_rect() -> Rect2:
	return Rect2(global_position + DOORWAY.position, DOORWAY.size)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var prompt := player.interact_target == self
	if prompt != _show_prompt:
		_show_prompt = prompt
		queue_redraw()
	if is_locked:
		return
	var near := player.global_position.distance_to(base_point()) < open_distance
	var target := float(FRAME_OPEN) if near else float(FRAME_CLOSED)
	if target != _target_frame:
		_target_frame = target
		AudioManager.play("door", base_point())
	_open_amount = move_toward(maxf(_open_amount, FRAME_CLOSED), target, frames_per_second * delta)
	_sprite.frame = int(roundf(_open_amount))
	if not _entered and doorway_rect().has_point(player.global_position):
		_entered = true
		player_entered.emit()


func _draw() -> void:
	if not _show_prompt:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var has_key := player != null and player.inventory.has_key_item(key_item)
	InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, unlock_prompt if has_key else locked_prompt)

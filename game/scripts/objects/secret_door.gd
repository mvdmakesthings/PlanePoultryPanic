class_name SecretDoor
extends Node2D
## A hidden way into a SecretRoom, set into the wall face: a cracked panel,
## a staff door, a freezer panel, an emergency exit or a pecked-open vent.
## Each has a tell (feathers, a crooked sign, frost) that gives it away to
## a player who looks. Interact below it to open it, which finds its secret,
## and again to step through; the screen fades and the player is in the
## room. Walking out of the room's bottom gap brings them back here.
## Position this node at its top-left corner on the wall face.

const SIZE := Vector2(16, 32)
const KINDS: Array[String] = ["cracked", "staff", "frost", "exit", "vent"]

@export var secret_id := ""
## Which door this is: a row of secret_doors.png.
@export_enum("cracked", "staff", "frost", "exit", "vent") var kind := "cracked"
@export var room: SecretRoom
@export var open_prompt := "{interact} open"
@export var enter_prompt := "{interact} go in"
@export var reach := 22.0

var is_open := false

var _show_prompt := false
var _busy := false
## The camera's limits before going in, put back on the way out.
var _limits: Array[int] = []

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	_sprite.frame = KINDS.find(kind) * 2
	if room:
		room.door = self
	# Found earlier in the run (before a retry, say): already open.
	if secret_id != "" and GameManager.has_secret(secret_id):
		_set_open()


## The floor spot right below the door, where the player stands to use it.
func base_point() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 4.0)


func can_interact(player: Player) -> bool:
	return not _busy and room != null and player.carrying == null \
		and player.global_position.distance_to(base_point()) <= reach


func interact(player: Player) -> void:
	if not is_open:
		_set_open()
		AudioManager.play("unlock", base_point())
		if secret_id != "":
			GameManager.find_secret(secret_id)
		return
	enter(player)


## Steps through into the room.
func enter(player: Player) -> void:
	if _busy:
		return
	_busy = true
	AudioManager.play("door", base_point())
	await _fade(func() -> void:
		var camera := _camera(player)
		_limits = [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]
		var view := room.view_rect()
		camera.limit_left = int(view.position.x)
		camera.limit_top = int(view.position.y)
		camera.limit_right = int(view.end.x)
		camera.limit_bottom = int(view.end.y)
		_move(player, room.entry_point(), camera)
		room.set_player_inside(true))
	_busy = false


## Comes back out of the room, in front of the door.
func leave(player: Player) -> void:
	if _busy:
		return
	_busy = true
	room.set_player_inside(false)
	await _fade(func() -> void:
		var camera := _camera(player)
		if _limits.size() == 4:
			camera.limit_left = _limits[0]
			camera.limit_top = _limits[1]
			camera.limit_right = _limits[2]
			camera.limit_bottom = _limits[3]
		_move(player, base_point(), camera))
	AudioManager.play("door", base_point())
	_busy = false


func _set_open() -> void:
	is_open = true
	_sprite.frame = KINDS.find(kind) * 2 + 1
	queue_redraw()


func _move(player: Player, to: Vector2, camera: Camera2D) -> void:
	player.global_position = to
	player.velocity = Vector2.ZERO
	camera.reset_smoothing()


func _camera(player: Player) -> Camera2D:
	return player.get_node("Camera2D") as Camera2D


func _fade(middle: Callable) -> void:
	var level := owner as GameLevel
	if level:
		await level.fade_through(middle)
	else:
		middle.call()


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var prompt := player != null and player.interact_target == self
	if prompt != _show_prompt:
		_show_prompt = prompt
		queue_redraw()


func _draw() -> void:
	if _show_prompt:
		InteractPrompt.draw(self, SIZE.x / 2.0, -3.0, enter_prompt if is_open else open_prompt)

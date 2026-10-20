class_name LuggageCart
extends CharacterBody2D
## An abandoned baggage cart. The player shoves it with Interact; it rolls
## a short way, and any chicken it hits while moving fast bursts into
## feathers. Carts also block eggs and line of sight, so they work as cover.

const SHADOW_COLOR := Color(0.094, 0.078, 0.145, 0.4)

## Speed right after a shove, in pixels per second.
@export var shove_speed := 190.0
@export var friction := 240.0
## Below this speed the cart is too slow to hurt a chicken.
@export var lethal_speed := 60.0
## How close the player must be to shove it.
@export var reach := 20.0
## The floor area the cart's body and luggage cover, relative to its
## position. Eggs fly at chest height, so anything passing over this area
## would visibly hit the luggage. Wider and deeper than the wheel collider.
@export var cover := Rect2(-12, -12, 24, 14)

var _show_prompt := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("egg_cover")


## True if an egg at this floor position would hit the cart.
func blocks_egg(pos: Vector2) -> bool:
	return cover.has_point(pos - global_position)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player != null and player.interact_target == self
	if near != _show_prompt:
		_show_prompt = near
		queue_redraw()

	if velocity == Vector2.ZERO:
		return
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	var speed := velocity.length()
	var hit_wall := move_and_slide() and get_slide_collision_count() > 0
	if hit_wall:
		# A hard slam into something solid jolts the screen.
		if speed >= lethal_speed:
			Juice.shake(2.0)
			Juice.squash(_sprite, Vector2(0.85, 1.15), 0.15)
		velocity = Vector2.ZERO
	# Spin the wheels while rolling.
	_sprite.frame = int(Time.get_ticks_msec() / 80) % 2 if velocity != Vector2.ZERO else 0
	if velocity.length() >= lethal_speed:
		for body in _hitbox.get_overlapping_bodies():
			if body is Chicken:
				(body as Chicken).defeat()
			elif body is Totem:
				(body as Totem).topple(velocity)


func can_interact(player: Player) -> bool:
	return velocity == Vector2.ZERO and global_position.distance_to(player.global_position) <= reach


func interact(player: Player) -> void:
	var direction := Shove.direction_for(self, player)
	if direction == Vector2.ZERO:
		return
	velocity = direction * shove_speed
	AudioManager.play("shove", global_position)
	if absf(direction.x) > 0.1:
		_sprite.flip_h = direction.x < 0.0
	_show_prompt = false
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 11.0, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)
	if _show_prompt:
		InteractPrompt.draw(self, 0.0, -24.0, "{interact} push")

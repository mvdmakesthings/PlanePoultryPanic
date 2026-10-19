class_name Shove
extends RefCounted
## Shared aiming for things the player shoves (luggage carts, frozen chickens).


## Which way a shove sends body: along the player's facing when they're lined
## up with it, otherwise straight away from the player. If a wall is in the
## way it slides sideways along the wall instead, then straight back, so a
## shoved thing can never get stuck in a corner. Zero if boxed in.
static func direction_for(body: CharacterBody2D, player: Player) -> Vector2:
	var wanted := player.global_position.direction_to(body.global_position)
	if player.facing.dot(wanted) > 0.3:
		wanted = player.facing
	wanted = wanted.normalized()
	for option: Vector2 in [wanted, wanted.orthogonal(), -wanted.orthogonal(), -wanted]:
		if not body.test_move(body.global_transform, option * 12.0):
			return option
	return Vector2.ZERO

class_name LevelState
extends RefCounted
## Snapshots of a level for checkpoints and the save file, as plain
## dictionaries that survive a trip through JSON:
##   level        - the level's scene path
##   checkpoint   - id of the checkpoint to start from ("start" = level start)
##   reached      - ids of every checkpoint already reached
##   inventory    - the player's slots, selection and key items
##   collected    - paths (from the level) of item pickups already taken
##   unlocked     - paths of doors and vending machines already unlocked
## Chickens, carts and thrown items start fresh on a retry.


static func capture_inventory(inventory: Inventory) -> Dictionary:
	return {
		"slots": inventory.slots.duplicate(true),
		"selected": inventory.selected,
		"key_items": inventory.key_items.duplicate(),
	}


static func restore_inventory(inventory: Inventory, data: Dictionary) -> void:
	var slots: Array = data.get("slots", [])
	for i in Inventory.SLOT_COUNT:
		var slot: Dictionary = slots[i] if i < slots.size() else {}
		# JSON turns every number into a float; counts are whole numbers.
		inventory.slots[i] = {} if slot.is_empty() else {"item": slot["item"], "count": int(slot["count"])}
	inventory.selected = int(data.get("selected", 0))
	inventory.key_items.clear()
	var keys: Dictionary = data.get("key_items", {})
	for item: String in keys:
		inventory.key_items[item] = int(keys[item])
	inventory.changed.emit()


## Paths (relative to level) of the scene's item pickups, to compare later.
static func pickup_paths(level: Node) -> Array[String]:
	var paths: Array[String] = []
	for node in level.find_children("*", "", true, false):
		if node is ItemPickup:
			paths.append(str(level.get_path_to(node)))
	return paths


## Which of the scene's original pickups are gone (picked up) now.
static func collected(level: Node, original: Array[String]) -> Array[String]:
	var gone: Array[String] = []
	for path in original:
		if not level.has_node(path) or level.get_node(path).is_queued_for_deletion():
			gone.append(path)
	return gone

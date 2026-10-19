class_name Inventory
extends RefCounted
## The player's six item slots plus a separate row of key items.
##
## Each slot holds one kind of item and a count. For stackable items the
## count is how many (snacks stack 3 per slot); for the fire extinguisher it
## is the charges left, and each extinguisher takes a slot of its own. Key
## items (boarding pass, maintenance keys, map) never use slots.

signal changed

const SLOT_COUNT := 6

## Per-item rules. "stack": how many fit in one slot; 1 means each item
## takes its own slot and its count is something else, like charges.
const ITEMS := {
	"snack": {"stack": 3, "icon": "res://assets/sprites/item_snack.png"},
	"extinguisher": {"stack": 1, "icon": "res://assets/sprites/item_extinguisher.png"},
}

## Each slot is {} when empty, or {"item": String, "count": int}.
var slots: Array[Dictionary] = []
var selected := 0
## Key item name -> how many (for example two maintenance keys).
var key_items := {}


func _init() -> void:
	for i in SLOT_COUNT:
		slots.append({})


## Adds up to count of a stackable item, filling existing stacks first.
## Returns how many were added; the rest didn't fit.
func add_stackable(item: String, count: int) -> int:
	var stack: int = ITEMS[item]["stack"]
	var added := 0
	for slot in slots:
		if added == count:
			break
		if slot.get("item") == item and slot["count"] < stack:
			var room: int = mini(stack - slot["count"], count - added)
			slot["count"] += room
			added += room
	for i in SLOT_COUNT:
		if added == count:
			break
		if slots[i].is_empty():
			var amount := mini(stack, count - added)
			slots[i] = {"item": item, "count": amount}
			added += amount
	if added > 0:
		changed.emit()
	return added


## Puts one non-stacking item (like an extinguisher with its charges) in a
## free slot. Returns false if every slot is taken.
func add_single(item: String, count: int) -> bool:
	var index := first_empty_slot()
	if index < 0:
		return false
	slots[index] = {"item": item, "count": count}
	changed.emit()
	return true


## True if at least one of this item would fit right now.
func has_room_for(item: String) -> bool:
	if first_empty_slot() >= 0:
		return true
	var stack: int = ITEMS[item]["stack"]
	for slot in slots:
		if slot.get("item") == item and slot["count"] < stack:
			return true
	return false


func first_empty_slot() -> int:
	for i in SLOT_COUNT:
		if slots[i].is_empty():
			return i
	return -1


## Total of an item across all slots (snacks held, or extinguisher charges).
func count_of(item: String) -> int:
	var total := 0
	for slot in slots:
		if slot.get("item") == item:
			total += slot["count"]
	return total


## The slot to take an item from: the selected slot if it holds that item,
## otherwise the first slot that does. -1 if none.
func slot_with(item: String) -> int:
	if slots[selected].get("item") == item:
		return selected
	for i in SLOT_COUNT:
		if slots[i].get("item") == item:
			return i
	return -1


## Uses up amount from a slot, emptying it when nothing is left.
func take_from(index: int, amount := 1) -> void:
	slots[index]["count"] -= amount
	if slots[index]["count"] <= 0:
		slots[index] = {}
	changed.emit()


## Removes and returns the selected slot's contents ({} if empty).
func remove_selected() -> Dictionary:
	var slot := slots[selected]
	slots[selected] = {}
	if not slot.is_empty():
		changed.emit()
	return slot


func selected_item() -> String:
	return slots[selected].get("item", "")


## Moves the selection by step slots, wrapping around.
func cycle(step: int) -> void:
	selected = posmod(selected + step, SLOT_COUNT)
	changed.emit()


## Selects the first slot holding item, if any.
func select_item(item: String) -> void:
	var index := slot_with(item)
	if index >= 0:
		selected = index
		changed.emit()


func add_key_item(item: String, count := 1) -> void:
	key_items[item] = key_items.get(item, 0) + count
	changed.emit()


func has_key_item(item: String) -> bool:
	return key_items.get(item, 0) > 0


func use_key_item(item: String) -> bool:
	if not has_key_item(item):
		return false
	key_items[item] -= 1
	if key_items[item] == 0:
		key_items.erase(item)
	changed.emit()
	return true

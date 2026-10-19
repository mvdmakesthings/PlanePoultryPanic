extends Node
## Registers the default control bindings at startup.
##
## Bindings live in code rather than project.godot so they stay readable in
## review. A future remapping menu can overwrite them through InputMap.

const KEY_BINDINGS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"run": [KEY_SHIFT],
	"use_item": [KEY_SPACE],
	"eat_snack": [KEY_E],
	"interact": [KEY_F],
	"prev_item": [KEY_Q],
	"next_item": [KEY_R],
	"drop_item": [KEY_G],
	# Shares R with next_item; the level only restarts once a round is over.
	"restart": [KEY_R],
}

const JOY_BUTTON_BINDINGS := {
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"run": [JOY_BUTTON_RIGHT_SHOULDER],
	"use_item": [JOY_BUTTON_A],
	"eat_snack": [JOY_BUTTON_X],
	"interact": [JOY_BUTTON_B],
	"prev_item": [JOY_BUTTON_LEFT_SHOULDER],
	"next_item": [JOY_BUTTON_Y],
	"drop_item": [JOY_BUTTON_BACK],
	"restart": [JOY_BUTTON_START],
}

## action -> [axis, direction]
const JOY_AXIS_BINDINGS := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}

const MOUSE_BUTTON_BINDINGS := {
	"prev_item": [MOUSE_BUTTON_WHEEL_UP],
	"next_item": [MOUSE_BUTTON_WHEEL_DOWN],
}

const STICK_DEADZONE := 0.2


func _ready() -> void:
	for action: String in KEY_BINDINGS:
		_ensure_action(action)
		for key: Key in KEY_BINDINGS[action]:
			var event := InputEventKey.new()
			# Physical keys keep WASD in the same spot on non-QWERTY layouts.
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

	for action: String in JOY_BUTTON_BINDINGS:
		_ensure_action(action)
		for button: JoyButton in JOY_BUTTON_BINDINGS[action]:
			var event := InputEventJoypadButton.new()
			event.button_index = button
			InputMap.action_add_event(action, event)

	for action: String in MOUSE_BUTTON_BINDINGS:
		_ensure_action(action)
		for button: MouseButton in MOUSE_BUTTON_BINDINGS[action]:
			var event := InputEventMouseButton.new()
			event.button_index = button
			InputMap.action_add_event(action, event)

	for action: String in JOY_AXIS_BINDINGS:
		_ensure_action(action)
		var event := InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_BINDINGS[action][0]
		event.axis_value = JOY_AXIS_BINDINGS[action][1]
		InputMap.action_add_event(action, event)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, STICK_DEADZONE)

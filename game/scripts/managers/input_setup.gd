extends Node
## Registers the default control bindings at startup.
##
## Bindings live in code rather than project.godot so they stay readable in
## review. The Settings menu remaps them through SaveSystem.

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
	"pause": [KEY_ESCAPE],
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
	"pause": [JOY_BUTTON_START],
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

## Extra bindings for the menus' built-in ui_* actions, so WASD and the
## gamepad work in every menu too.
const UI_KEYS := {
	"ui_up": [KEY_W], "ui_down": [KEY_S], "ui_left": [KEY_A], "ui_right": [KEY_D],
	"ui_cancel": [KEY_ESCAPE],
}
const UI_BUTTONS := {
	"ui_accept": [JOY_BUTTON_A], "ui_cancel": [JOY_BUTTON_B],
	"ui_up": [JOY_BUTTON_DPAD_UP], "ui_down": [JOY_BUTTON_DPAD_DOWN],
	"ui_left": [JOY_BUTTON_DPAD_LEFT], "ui_right": [JOY_BUTTON_DPAD_RIGHT],
}


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

	_add_ui_bindings()


## The key an action starts with (its first default key), or KEY_NONE.
func default_key(action: String) -> int:
	return KEY_BINDINGS[action][0] if KEY_BINDINGS.has(action) else KEY_NONE


## The gamepad button an action starts with, or JOY_BUTTON_INVALID.
func default_button(action: String) -> int:
	return JOY_BUTTON_BINDINGS[action][0] if JOY_BUTTON_BINDINGS.has(action) else JOY_BUTTON_INVALID


func _add_ui_bindings() -> void:
	for action: String in UI_KEYS:
		for key: Key in UI_KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	for action: String in UI_BUTTONS:
		for button: JoyButton in UI_BUTTONS[action]:
			var event := InputEventJoypadButton.new()
			event.button_index = button
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	var stick := {"ui_up": [JOY_AXIS_LEFT_Y, -1.0], "ui_down": [JOY_AXIS_LEFT_Y, 1.0],
		"ui_left": [JOY_AXIS_LEFT_X, -1.0], "ui_right": [JOY_AXIS_LEFT_X, 1.0]}
	for action: String in stick:
		var event := InputEventJoypadMotion.new()
		event.axis = stick[action][0]
		event.axis_value = stick[action][1]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, STICK_DEADZONE)

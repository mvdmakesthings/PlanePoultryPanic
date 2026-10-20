class_name InputLabels
extends RefCounted
## Names the button bound to an action ("F", "SPACE", or "B" on a gamepad),
## so prompts and hints always match the player's bindings and the device
## they're using. Text can name actions in braces, like "{interact} push";
## format() fills in the names and ButtonGlyphs draws them as buttons.

## Actions that are really a group of bindings, named as one.
const GROUPS := {"move": "WASD"}
const PAD_GROUPS := {"move": "L-STICK"}
## Shorter names for keys whose full names crowd a prompt.
const SHORT := {"ESCAPE": "ESC", "ENTER": "ENTER", "BACKSPACE": "BKSP"}

## Gamepad buttons named the Xbox way, which Steam Deck also uses.
const BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_BACK: "BACK", JOY_BUTTON_START: "START", JOY_BUTTON_GUIDE: "HOME",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "D-UP", JOY_BUTTON_DPAD_DOWN: "D-DOWN",
	JOY_BUTTON_DPAD_LEFT: "D-LEFT", JOY_BUTTON_DPAD_RIGHT: "D-RIGHT",
}

## True while the player is using a gamepad (InputSetup watches for it).
static var gamepad := false

static var _token := RegEx.create_from_string("\\{(\\w+)\\}")


static func label(action: String) -> String:
	if gamepad:
		if PAD_GROUPS.has(action):
			return PAD_GROUPS[action]
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventJoypadButton:
					return button_name((event as InputEventJoypadButton).button_index)
	if GROUPS.has(action):
		return GROUPS[action]
	if not InputMap.has_action(action):
		return action.to_upper()
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key:
			return key_name(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return action.to_upper()


## Replaces each {action} in text with that action's button.
static func format(text: String) -> String:
	var out := text
	for found in _token.search_all(text):
		out = out.replace(found.get_string(), label(found.get_string(1)))
	return out


static func key_name(keycode: int) -> String:
	if keycode == KEY_NONE:
		return "-"
	var name := OS.get_keycode_string(keycode).to_upper()
	return SHORT.get(name, name)


static func button_name(button: int) -> String:
	if button == JOY_BUTTON_INVALID:
		return "-"
	return BUTTON_NAMES.get(button, "BTN %d" % button)

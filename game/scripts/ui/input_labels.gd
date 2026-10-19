class_name InputLabels
extends RefCounted
## Names the button bound to an action ("F", "SPACE"), so prompts and hints
## always match the player's bindings. Text can name actions in braces,
## like "{interact} push", and format() fills in the buttons.

## Actions that are really a group of bindings, named as one.
const GROUPS := {"move": "WASD"}

static var _token := RegEx.create_from_string("\\{(\\w+)\\}")


static func label(action: String) -> String:
	if GROUPS.has(action):
		return GROUPS[action]
	if not InputMap.has_action(action):
		return action.to_upper()
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key:
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			return OS.get_keycode_string(code).to_upper()
	return action.to_upper()


## Replaces each {action} in text with that action's button.
static func format(text: String) -> String:
	var out := text
	for found in _token.search_all(text):
		out = out.replace(found.get_string(), label(found.get_string(1)))
	return out

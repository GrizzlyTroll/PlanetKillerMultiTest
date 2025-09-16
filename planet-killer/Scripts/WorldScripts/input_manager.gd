extends Node

signal input_rebound(action_name, new_event)

# Default keybindings
var default_keybindings = {
	"Left": [KEY_A, KEY_LEFT],
	"Right": [KEY_D, KEY_RIGHT],
	"Jump": [KEY_SPACE, KEY_W, KEY_UP],
	"Crouch": [KEY_S, KEY_DOWN],
	"Dig": [MOUSE_BUTTON_RIGHT],
	"SwingAxe": [MOUSE_BUTTON_LEFT],
	"Save": [KEY_F5]
}

# Current keybindings
var current_keybindings = {}

func _ready():
	# Load saved keybindings
	load_keybindings()
	
	# Apply keybindings to input map
	apply_keybindings()

func load_keybindings():
	"""Load keybindings from config"""
	var saved_keybindings = ConfigFileHandler.load_key_bindings()
	
	# Use saved keybindings or defaults
	for action in default_keybindings.keys():
		if saved_keybindings.has(action):
			current_keybindings[action] = saved_keybindings[action]
		else:
			# Create default input event
			var default_keys = default_keybindings[action]
			if default_keys.size() > 0:
				var event = create_input_event(default_keys[0])
				current_keybindings[action] = event

func apply_keybindings():
	"""Apply current keybindings to the input map"""
	for action in current_keybindings.keys():
		# Check if action exists in InputMap before trying to erase events
		if InputMap.has_action(action):
			# Clear existing events for this action
			InputMap.action_erase_events(action)
			
			# Add the current event
			InputMap.action_add_event(action, current_keybindings[action])
		else:
			print("Warning: Action '" + action + "' not found in InputMap")

func rebind_action(action_name: String, new_event: InputEvent):
	"""Rebind an action to a new input event"""
	if current_keybindings.has(action_name):
		# Check for conflicts
		if not has_conflict(action_name, new_event):
			current_keybindings[action_name] = new_event
			apply_keybindings()
			ConfigFileHandler.save_key_binding(action_name, new_event)
			input_rebound.emit(action_name, new_event)
			return true
		else:
			print("Input conflict detected!")
			return false
	return false

func has_conflict(action_name: String, new_event: InputEvent) -> bool:
	"""Check if the new input event conflicts with existing bindings"""
	for action in current_keybindings.keys():
		if action != action_name:
			var existing_event = current_keybindings[action]
			if events_match(existing_event, new_event):
				return true
	return false

func events_match(event1: InputEvent, event2: InputEvent) -> bool:
	"""Check if two input events are the same"""
	if event1 is InputEventKey and event2 is InputEventKey:
		return event1.keycode == event2.keycode
	elif event1 is InputEventMouseButton and event2 is InputEventMouseButton:
		return event1.button_index == event2.button_index
	return false

func create_input_event(key_or_button) -> InputEvent:
	"""Create an input event from a key code or mouse button"""
	if key_or_button is int:
		if key_or_button >= 0 and key_or_button < 1000:  # Key codes
			var event = InputEventKey.new()
			event.keycode = key_or_button
			return event
		else:  # Mouse buttons
			var event = InputEventMouseButton.new()
			event.button_index = key_or_button
			return event
	return null

func reset_to_defaults():
	"""Reset all keybindings to defaults"""
	for action in default_keybindings.keys():
		var default_keys = default_keybindings[action]
		if default_keys.size() > 0:
			var event = create_input_event(default_keys[0])
			current_keybindings[action] = event
			ConfigFileHandler.save_key_binding(action, event)
	
	apply_keybindings()
	print("Keybindings reset to defaults")

func get_action_event(action_name: String) -> InputEvent:
	"""Get the current input event for an action"""
	return current_keybindings.get(action_name, null)

func get_action_display_name(action_name: String) -> String:
	"""Get a display name for an action's current binding"""
	var event = get_action_event(action_name)
	if event:
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
		elif event is InputEventMouseButton:
			return "Mouse " + str(event.button_index)
	return "Unbound"

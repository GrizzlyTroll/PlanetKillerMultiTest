extends Node

var config: ConfigFile
const FILE_PATH = "res://Ini Files/settings.ini"

func _ready():
	config = ConfigFile.new()
	create_default_settings()

func create_default_settings():
	if not FileAccess.file_exists(FILE_PATH):
		# Create default settings file
		# Key bindings
		config.set_value("key_binding", "Left", "A")
		config.set_value("key_binding", "Right", "D")
		config.set_value("key_binding", "Jump", "Space")
		config.set_value("key_binding", "Crouch","S")
		config.set_value("key_binding", "Dig", "mouse2")
		config.set_value("key_binding", "SwingAxe", "mouse1")
		
		# Video settings
		config.set_value("video", "full_screen", false)
		config.set_value("video", "screen_shake", true)
		config.set_value("video", "resolution", Vector2i(1280, 720))
		
		# Audio settings
		config.set_value("audio", "master_volume", 1.0)
		config.set_value("audio", "sfx_volume", 1.0)
		config.set_value("audio", "music_volume", 1.0)
		
		# Gameplay settings
		config.set_value("gameplay", "difficulty", 1) # 0=Easy, 1=Normal, 2=Hard
		config.set_value("gameplay", "auto_save", true)
		
		config.save(FILE_PATH)
	else:
		# Load existing settings
		config.load(FILE_PATH)

# Key binding functions
func save_key_binding(action: String, event: InputEvent):
	var event_string = ""
	if event is InputEventKey:
		event_string = OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		event_string = "mouse_" + str(event.button_index)
	
	config.set_value("key_binding", action, event_string)
	config.save(FILE_PATH)

func load_key_bindings():
	var key_bindings = {}
	var keys = config.get_section_keys("key_binding")
	
	for key in keys:
		var input_event
		var event_string = config.get_value("key_binding", key)
		
		if event_string.contains("mouse_"):
			input_event = InputEventMouseButton.new()
			input_event.button_index = int(event_string.split("_")[1])
		else:
			input_event = InputEventKey.new()
			input_event.keycode = OS.find_keycode_from_string(event_string)
		
		key_bindings[key] = input_event
	
	return key_bindings

# Video settings functions
func save_video_setting(key: String, value):
	config.set_value("video", key, value)
	config.save(FILE_PATH)

func load_video_settings():
	var video_settings = {}
	var keys = config.get_section_keys("video")
	for key in keys:
		video_settings[key] = config.get_value("video", key)
	return video_settings

# Audio settings functions
func save_audio_setting(key: String, value):
	config.set_value("audio", key, value)
	config.save(FILE_PATH)

func load_audio_settings():
	var audio_settings = {}
	var keys = config.get_section_keys("audio")
	for key in keys:
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings

# Gameplay settings functions
func save_gameplay_setting(key: String, value):
	config.set_value("gameplay", key, value)
	config.save(FILE_PATH)

func load_gameplay_settings():
	var gameplay_settings = {}
	var keys = config.get_section_keys("gameplay")
	for key in keys:
		gameplay_settings[key] = config.get_value("gameplay", key)
	return gameplay_settings

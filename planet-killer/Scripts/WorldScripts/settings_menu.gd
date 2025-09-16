extends Control

# Tab Container
var tab_container: TabContainer

# Controls Tab
var left_button: Button
var right_button: Button
var jump_button: Button
var crouch_button: Button
var dig_button: Button
var hit_button: Button
var reset_keybindings_button: Button

# Video Tab
var full_screen_checkbox: CheckBox
var screen_shake_checkbox: CheckBox
var resolution_option_button: OptionButton

# Audio Tab
var master_volume_slider: HSlider
var master_volume_label: Label
var sfx_volume_slider: HSlider
var sfx_volume_label: Label
var music_volume_slider: HSlider
var music_volume_label: Label

# Gameplay Tab
var difficulty_option_button: OptionButton
var auto_save_checkbox: CheckBox

# Buttons
var close_button: Button
var back_button: Button
var apply_button: Button

# State
var currently_remapping = false
var remapping_button = null
var available_resolutions = [
	Vector2i(2560,1440),
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 768)
]

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get all the nodes
	get_all_nodes()
	
	# Setup UI
	setup_ui()
	
	# Connect signals
	connect_signals()
	
	# Load current settings
	load_settings()
	
	# Setup resolution options
	setup_resolution_options()
	
	# Setup difficulty options
	setup_difficulty_options()

func get_all_nodes():
	"""Get all UI nodes"""
	# Tab Container
	tab_container = get_node_or_null("MainContainer/VBoxContainer/TabContainer")
	
	# Controls Tab
	left_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Controls/ControlsVBox/KeybindingsContainer/LeftBinding/LeftButton")
	right_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Controls/ControlsVBox/KeybindingsContainer/RightBinding/RightButton")
	jump_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Controls/ControlsVBox/KeybindingsContainer/JumpBinding/JumpButton")
	crouch_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Controls/ControlsVBox/KeybindingsContainer/CrouchBinding/CrouchButton")
	dig_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Controls/ControlsVBox/KeybindingsContainer/DigBinding/DigButton")
	hit_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Controls/ControlsVBox/KeybindingsContainer/HitBinding/HitButton")
	reset_keybindings_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Controls/ControlsVBox/ResetKeybindingsButton")
	
	# Video Tab
	full_screen_checkbox = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Video/VideoVBox/VideoSettingsContainer/FullScreenContainer/FullScreenCheckBox")
	screen_shake_checkbox = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Video/VideoVBox/VideoSettingsContainer/ScreenShakeContainer/ScreenShakeCheckBox")
	resolution_option_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Video/VideoVBox/VideoSettingsContainer/ResolutionContainer/ResolutionOptionButton")
	
	# Audio Tab
	master_volume_slider = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Audio/AudioVBox/AudioSettingsContainer/MasterVolumeContainer/MasterVolumeSlider")
	master_volume_label = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Audio/AudioVBox/AudioSettingsContainer/MasterVolumeContainer/MasterVolumeLabel")
	sfx_volume_slider = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Audio/AudioVBox/AudioSettingsContainer/SFXVolumeContainer/SFXVolumeSlider")
	sfx_volume_label = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Audio/AudioVBox/AudioSettingsContainer/SFXVolumeContainer/SFXVolumeLabel")
	music_volume_slider = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Audio/AudioVBox/AudioSettingsContainer/MusicVolumeContainer/MusicVolumeSlider")
	music_volume_label = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Audio/AudioVBox/AudioSettingsContainer/MusicVolumeContainer/MusicVolumeLabel")
	
	# Gameplay Tab
	difficulty_option_button = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Gameplay/GameplayVBox/GameplaySettingsContainer/DifficultyContainer/DifficultyOptionButton")
	auto_save_checkbox = get_node_or_null("MainContainer/VBoxContainer/TabContainer/Gameplay/GameplayVBox/GameplaySettingsContainer/AutoSaveContainer/AutoSaveCheckBox")
	
	# Buttons
	close_button = get_node_or_null("MainContainer/VBoxContainer/TitleContainer/CloseButton")
	back_button = get_node_or_null("MainContainer/VBoxContainer/ButtonContainer/BackButton")
	apply_button = get_node_or_null("MainContainer/VBoxContainer/ButtonContainer/ApplyButton")

func setup_ui():
	"""Setup initial UI state"""
	# Set initial tab
	if tab_container:
		tab_container.current_tab = 0

func setup_resolution_options():
	"""Setup resolution dropdown options"""
	if resolution_option_button:
		resolution_option_button.clear()
		for i in range(available_resolutions.size()):
			var resolution = available_resolutions[i]
			resolution_option_button.add_item(str(resolution.x) + "x" + str(resolution.y), i)

func setup_difficulty_options():
	"""Setup difficulty dropdown options"""
	if difficulty_option_button:
		difficulty_option_button.clear()
		difficulty_option_button.add_item("Easy", 0)
		difficulty_option_button.add_item("Normal", 1)
		difficulty_option_button.add_item("Hard", 2)

func connect_signals():
	"""Connect all UI signals"""
	# Keybinding buttons
	if left_button:
		left_button.pressed.connect(_on_keybinding_button_pressed.bind(left_button, "Left"))
	if right_button:
		right_button.pressed.connect(_on_keybinding_button_pressed.bind(right_button, "Right"))
	if jump_button:
		jump_button.pressed.connect(_on_keybinding_button_pressed.bind(jump_button, "Jump"))
	if crouch_button:
		crouch_button.pressed.connect(_on_keybinding_button_pressed.bind(crouch_button, "Crouch"))
	if dig_button:
		dig_button.pressed.connect(_on_keybinding_button_pressed.bind(dig_button, "Dig"))
	if hit_button:
		hit_button.pressed.connect(_on_keybinding_button_pressed.bind(hit_button, "Hit"))
	
	# Reset keybindings
	if reset_keybindings_button:
		reset_keybindings_button.pressed.connect(_on_reset_keybindings_pressed)
	
	# Video settings
	if full_screen_checkbox:
		full_screen_checkbox.toggled.connect(_on_full_screen_toggled)
	if screen_shake_checkbox:
		screen_shake_checkbox.toggled.connect(_on_screen_shake_toggled)
	if resolution_option_button:
		resolution_option_button.item_selected.connect(_on_resolution_selected)
	
	# Audio settings
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	
	# Gameplay settings
	if difficulty_option_button:
		difficulty_option_button.item_selected.connect(_on_difficulty_selected)
	if auto_save_checkbox:
		auto_save_checkbox.toggled.connect(_on_auto_save_toggled)
	
	# Navigation buttons
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	if apply_button:
		apply_button.pressed.connect(_on_apply_button_pressed)

func load_settings():
	"""Load all settings from config"""
	# Load keybindings using InputManager
	update_keybinding_buttons()
	
	# Load video settings
	var video_settings = ConfigFileHandler.load_video_settings()
	if full_screen_checkbox:
		full_screen_checkbox.button_pressed = video_settings.get("full_screen", false)
	if screen_shake_checkbox:
		screen_shake_checkbox.button_pressed = video_settings.get("screen_shake", true)
	
	# Set current resolution
	var current_resolution = DisplayServer.window_get_size()
	var resolution_index = available_resolutions.find(current_resolution)
	if resolution_option_button and resolution_index >= 0:
		resolution_option_button.selected = resolution_index
	
	# Load audio settings
	var audio_settings = ConfigFileHandler.load_audio_settings()
	var master_volume = audio_settings.get("master_volume", 1.0)
	var sfx_volume = audio_settings.get("sfx_volume", 1.0)
	var music_volume = audio_settings.get("music_volume", 1.0)
	
	if master_volume_slider:
		master_volume_slider.value = master_volume * 100
	if master_volume_label:
		master_volume_label.text = "Master Volume: " + str(int(master_volume * 100)) + "%"
	
	if sfx_volume_slider:
		sfx_volume_slider.value = sfx_volume * 100
	if sfx_volume_label:
		sfx_volume_label.text = "SFX Volume: " + str(int(sfx_volume * 100)) + "%"
	
	if music_volume_slider:
		music_volume_slider.value = music_volume * 100
	if music_volume_label:
		music_volume_label.text = "Music Volume: " + str(int(music_volume * 100)) + "%"
	
	# Load gameplay settings
	var gameplay_settings = ConfigFileHandler.load_gameplay_settings()
	if difficulty_option_button:
		difficulty_option_button.selected = gameplay_settings.get("difficulty", 1)
	if auto_save_checkbox:
		auto_save_checkbox.button_pressed = gameplay_settings.get("auto_save", true)

func update_keybinding_buttons():
	"""Update keybinding button texts"""
	var actions = ["Left", "Right", "Jump", "Crouch", "Dig", "SwingAxe"]
	for action in actions:
		var button = get_keybinding_button(action)
		if button != null:
			button.text = InputManager.get_action_display_name(action)
			button.set_meta("action", action)

func get_keybinding_button(action):
	"""Get button for specific action"""
	match action:
		"Left": return left_button
		"Right": return right_button
		"Jump": return jump_button
		"Crouch": return crouch_button
		"Dig": return dig_button
		"SwingAxe": return hit_button
		_: return null

func update_input_map():
	"""Update the input map with saved keybindings"""
	InputManager.apply_keybindings()

func _input(event):
	"""Handle input for keybinding remapping"""
	if currently_remapping and remapping_button != null:
		if event is InputEventKey or event is InputEventMouseButton:
			var action_name = remapping_button.get_meta("action")
			
			# Try to rebind the action
			if InputManager.rebind_action(action_name, event):
				# Update the button text
				remapping_button.text = InputManager.get_action_display_name(action_name)
			else:
				# Conflict detected, revert to original
				remapping_button.text = InputManager.get_action_display_name(action_name)
			
			# Reset remapping state
			currently_remapping = false
			remapping_button = null
			get_viewport().set_input_as_handled()

# Signal handlers
func _on_keybinding_button_pressed(button, action):
	"""Handle keybinding button press"""
	if not currently_remapping:
		currently_remapping = true
		remapping_button = button
		button.text = "Press any key..."
		button.set_meta("action", action)

func _on_reset_keybindings_pressed():
	"""Reset keybindings to defaults"""
	InputManager.reset_to_defaults()
	
	# Reload the settings to update the UI
	load_settings()

func _on_full_screen_toggled(button_pressed):
	"""Handle fullscreen toggle"""
	ConfigFileHandler.save_video_setting("full_screen", button_pressed)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_screen_shake_toggled(button_pressed):
	"""Handle screen shake toggle"""
	ConfigFileHandler.save_video_setting("screen_shake", button_pressed)

func _on_resolution_selected(index):
	"""Handle resolution selection"""
	if index >= 0 and index < available_resolutions.size():
		var resolution = available_resolutions[index]
		DisplayServer.window_set_size(resolution)
		ConfigFileHandler.save_video_setting("resolution", resolution)

func _on_master_volume_changed(value):
	"""Handle master volume change"""
	var volume = value / 100.0
	ConfigFileHandler.save_audio_setting("master_volume", volume)
	if master_volume_label:
		master_volume_label.text = "Master Volume: " + str(int(value)) + "%"
	# Apply volume change to audio bus
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

func _on_sfx_volume_changed(value):
	"""Handle SFX volume change"""
	var volume = value / 100.0
	ConfigFileHandler.save_audio_setting("sfx_volume", volume)
	if sfx_volume_label:
		sfx_volume_label.text = "SFX Volume: " + str(int(value)) + "%"
	# Apply volume change to SFX bus (if it exists)
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(volume))

func _on_music_volume_changed(value):
	"""Handle music volume change"""
	var volume = value / 100.0
	ConfigFileHandler.save_audio_setting("music_volume", volume)
	if music_volume_label:
		music_volume_label.text = "Music Volume: " + str(int(value)) + "%"
	# Apply volume change to Music bus (if it exists)
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(volume))

func _on_difficulty_selected(index):
	"""Handle difficulty selection"""
	ConfigFileHandler.save_gameplay_setting("difficulty", index)

func _on_auto_save_toggled(button_pressed):
	"""Handle auto save toggle"""
	ConfigFileHandler.save_gameplay_setting("auto_save", button_pressed)
	AutoSave.set_auto_save_enabled(button_pressed)

func _on_close_button_pressed():
	"""Handle close button press"""
	_on_back_button_pressed()

func _on_back_button_pressed():
	"""Handle back button press"""
	# Check if we're in a game or in the title screen
	var current_scene = get_tree().current_scene.get_name()
	if current_scene == "StyledSettingsMenu" or current_scene == "SettingsMenu":
		# We're in the settings menu as a standalone scene, return to title screen
		get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")
	else:
		# We're in a game, close settings and return to pause menu
		GameManager.close_settings()

func _on_apply_button_pressed():
	"""Handle apply button press"""
	# Apply all settings
	update_input_map()
	
	# Apply video settings
	if full_screen_checkbox:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full_screen_checkbox.button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Apply audio settings
	if master_volume_slider:
		var master_volume = master_volume_slider.value / 100.0
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	
	if sfx_volume_slider:
		var sfx_volume = sfx_volume_slider.value / 100.0
		var sfx_bus_index = AudioServer.get_bus_index("SFX")
		if sfx_bus_index != -1:
			AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))
	
	if music_volume_slider:
		var music_volume = music_volume_slider.value / 100.0
		var music_bus_index = AudioServer.get_bus_index("Music")
		if music_bus_index != -1:
			AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume))
	
	print("Settings applied!")

func _unhandled_key_input(event):
	"""Handle unhandled key input"""
	# Allow ESC to go back
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

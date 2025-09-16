extends Control

signal resume_game
signal open_settings
signal open_achievements
signal return_to_main_menu
signal quit_game

var resume_button: Button
var settings_button: Button
var achievements_button: Button
var main_menu_button: Button
var quit_button: Button

func _ready():
	# Get button references
	resume_button = $MainContainer/VBoxContainer/ButtonContainer/ResumeButton
	settings_button = $MainContainer/VBoxContainer/ButtonContainer/SettingsButton
	achievements_button = $MainContainer/VBoxContainer/ButtonContainer/AchievementsButton
	main_menu_button = $MainContainer/VBoxContainer/ButtonContainer/MainMenuButton
	quit_button = $MainContainer/VBoxContainer/ButtonContainer/QuitButton
	
	# Connect signals
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	achievements_button.pressed.connect(_on_achievements_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Initially hide the pause menu
	hide()
	
	# Ensure this control can receive input
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

# ESC key handling is now done by GameManager
# This prevents conflicts between pause menu and game manager

func show_pause_menu():
	"""Show the pause menu and pause the game"""
	show()
	get_tree().paused = true

func hide_pause_menu():
	"""Hide the pause menu and resume the game"""
	hide()
	get_tree().paused = false

func _on_resume_button_pressed():
	"""Handle resume button press"""
	hide_pause_menu()
	resume_game.emit()

func _on_settings_button_pressed():
	"""Handle settings button press"""
	# Hide pause menu temporarily
	hide()
	# Emit signal to open settings
	open_settings.emit()

func _on_achievements_button_pressed():
	"""Handle achievements button press"""
	# Hide pause menu temporarily
	hide()
	# Emit signal to open achievements
	open_achievements.emit()

func _on_main_menu_button_pressed():
	"""Handle main menu button press"""
	# Unpause the game before changing scenes
	get_tree().paused = false
	return_to_main_menu.emit()

func _on_quit_button_pressed():
	"""Handle quit button press"""
	quit_game.emit()

func on_settings_closed():
	"""Called when settings menu is closed - show pause menu again"""
	show_pause_menu()

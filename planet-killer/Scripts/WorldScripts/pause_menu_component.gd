extends CanvasLayer
class_name PauseMenuComponent

signal resume_game
signal open_settings
signal open_achievements
signal return_to_main_menu
signal quit_game

@onready var resume_button: Button = $Control/MainContainer/VBoxContainer/ButtonContainer/ResumeButton
@onready var settings_button: Button = $Control/MainContainer/VBoxContainer/ButtonContainer/SettingsButton
@onready var achievements_button: Button = $Control/MainContainer/VBoxContainer/ButtonContainer/AchievementsButton
@onready var multiplayer_button: Button = $Control/MainContainer/VBoxContainer/ButtonContainer/Multiplayer
@onready var main_menu_button: Button = $Control/MainContainer/VBoxContainer/ButtonContainer/MainMenuButton
@onready var quit_button: Button = $Control/MainContainer/VBoxContainer/ButtonContainer/QuitButton

func _ready() -> void:
	# Connect button signals
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	achievements_button.pressed.connect(_on_achievements_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Initially hide the pause menu
	$Control.hide()
	
	# Ensure this control can receive input and process even when paused
	$Control.mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set up input handling
	set_process_input(true)

func _input(event: InputEvent) -> void:
	# Handle ESC key to toggle pause menu
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

func show_pause_menu() -> void:
	"""Show the pause menu and pause the game"""
	$Control.show()
	get_tree().paused = true

func hide_pause_menu() -> void:
	"""Hide the pause menu and resume the game"""
	$Control.hide()
	get_tree().paused = false

func toggle_pause_menu() -> void:
	"""Toggle pause menu visibility"""
	if $Control.visible:
		hide_pause_menu()
	else:
		show_pause_menu()

func _on_resume_button_pressed() -> void:
	"""Handle resume button press"""
	hide_pause_menu()
	resume_game.emit()

func _on_settings_button_pressed() -> void:
	"""Handle settings button press"""
	# Hide pause menu temporarily
	$Control.hide()
	# Emit signal to open settings
	open_settings.emit()

func _on_achievements_button_pressed() -> void:
	"""Handle achievements button press"""
	# Hide pause menu temporarily
	$Control.hide()
	# Emit signal to open achievements
	open_achievements.emit()

func _on_main_menu_button_pressed() -> void:
	"""Handle main menu button press"""
	# Unpause the game before changing scenes
	get_tree().paused = false
	return_to_main_menu.emit()

func _on_quit_button_pressed() -> void:
	"""Handle quit button press"""
	quit_game.emit()

func on_settings_closed() -> void:
	"""Called when settings menu is closed - show pause menu again"""
	show_pause_menu()

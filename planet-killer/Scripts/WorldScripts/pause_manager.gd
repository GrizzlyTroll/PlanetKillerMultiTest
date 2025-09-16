extends Node
class_name PauseManager

# Reference to the pause menu component
var pause_menu: PauseMenuComponent

func _ready() -> void:
	# Find the pause menu component in the scene
	pause_menu = find_child("PauseMenuComponent", true, false)
	
	if pause_menu:
		# Connect pause menu signals
		pause_menu.resume_game.connect(_on_resume_game)
		pause_menu.return_to_main_menu.connect(_on_return_to_main_menu)
		pause_menu.quit_game.connect(_on_quit_game)
		pause_menu.open_settings.connect(_on_open_settings)
		print("Pause manager: Pause menu found and connected")
	else:
		print("Pause manager: No pause menu component found in scene")

func _input(event: InputEvent) -> void:
	# Handle ESC key to toggle pause menu
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	"""Toggle pause menu visibility"""
	if pause_menu:
		pause_menu.toggle_pause_menu()

func _on_resume_game() -> void:
	"""Handle resume game from pause menu"""
	print("Pause manager: Resuming game...")

func _on_return_to_main_menu() -> void:
	"""Handle return to main menu from pause menu"""
	print("Pause manager: Returning to main menu...")
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")

func _on_quit_game() -> void:
	"""Handle quit game from pause menu"""
	print("Pause manager: Quitting game...")
	get_tree().quit()

func _on_open_settings() -> void:
	"""Handle opening settings from pause menu"""
	print("Pause manager: Opening settings...")
	# You can implement settings menu logic here
	# For now, just show the pause menu again
	if pause_menu:
		pause_menu.on_settings_closed()

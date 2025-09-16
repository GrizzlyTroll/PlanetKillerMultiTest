extends Node

signal game_paused
signal game_resumed
signal game_state_changed(new_state)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	SETTINGS
}

var current_state: GameState = GameState.MENU
var pause_menu_scene: PackedScene
var settings_menu_scene: PackedScene
var achievements_menu_scene: PackedScene
var pause_menu_instance: Control
var settings_menu_instance: Control
var achievements_menu_instance: Control
var ui_layer: CanvasLayer

func _ready():
	# Load scenes
	pause_menu_scene = preload("res://Scenes/PauseMenu.tscn")
	settings_menu_scene = preload("res://Scenes/StyledSettingsMenu.tscn")
	achievements_menu_scene = preload("res://Scenes/UI/AchievementsMenu.tscn")
	
	# Ensure GameManager continues to process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Wait for the scene tree to be ready
	await get_tree().process_frame
	
	# Create pause menu instance
	create_pause_menu_instance()

func create_pause_menu_instance():
	"""Create and setup the pause menu instance with proper UI layering"""
	# Clean up existing pause menu if it exists
	if pause_menu_instance:
		pause_menu_instance.queue_free()
	
	# Create fresh CanvasLayer to avoid transform inheritance
	if ui_layer:
		ui_layer.queue_free()
		ui_layer = null
	
	ui_layer = CanvasLayer.new()
	ui_layer.follow_viewport_enabled = false  # Keep UI isolated from parallax
	ui_layer.layer = 1000  # High layer to ensure it's on top
	
	# Create dedicated UI parent
	var ui_parent = get_tree().root.get_node_or_null("UI_Parent")
	if not ui_parent:
		ui_parent = Node.new()
		ui_parent.name = "UI_Parent"
		ui_parent.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child(ui_parent)
	
	ui_parent.add_child(ui_layer)
	
	# Create and setup pause menu
	pause_menu_instance = pause_menu_scene.instantiate()
	pause_menu_instance.resume_game.connect(_on_resume_game)
	pause_menu_instance.open_settings.connect(_on_open_settings)
	pause_menu_instance.open_achievements.connect(_on_open_achievements)
	pause_menu_instance.return_to_main_menu.connect(_on_return_to_main_menu)
	pause_menu_instance.quit_game.connect(_on_quit_game)
	
	ui_layer.add_child(pause_menu_instance)
	pause_menu_instance.hide()

func _input(event):
	# Handle pause input when playing, or resume when paused
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING:
			pause_game()
			get_viewport().set_input_as_handled()
		elif current_state == GameState.PAUSED:
			resume_game()
			get_viewport().set_input_as_handled()

func change_game_state(new_state: GameState):
	"""Change the current game state"""
	var _old_state = current_state
	current_state = new_state
	game_state_changed.emit(new_state)
	
	match new_state:
		GameState.MENU:
			get_tree().paused = false
		GameState.PLAYING:
			get_tree().paused = false
		GameState.PAUSED:
			get_tree().paused = true
		GameState.SETTINGS:
			get_tree().paused = true

func pause_game():
	"""Pause the game and show pause menu"""
	if current_state == GameState.PLAYING:
		change_game_state(GameState.PAUSED)
		if pause_menu_instance:
			pause_menu_instance.show_pause_menu()
		else:
			print("ERROR: No pause menu instance!")
		game_paused.emit()
	else:
		print("Cannot pause: Current state is ", current_state)

func resume_game():
	"""Resume the game"""
	if current_state == GameState.PAUSED:
		change_game_state(GameState.PLAYING)
		if pause_menu_instance:
			pause_menu_instance.hide_pause_menu()
		else:
			print("ERROR: No pause menu instance!")
		game_resumed.emit()
	else:
		print("Cannot resume: Current state is ", current_state)

func open_settings():
	"""Open settings menu with proper UI layering"""
	print("=== Opening Settings ===")
	change_game_state(GameState.SETTINGS)
	
	# Create settings menu instance if it doesn't exist
	if not settings_menu_instance:
		print("Creating settings menu instance")
		settings_menu_instance = settings_menu_scene.instantiate()
		# Add to UI layer, not game scene
		if ui_layer:
			ui_layer.add_child(settings_menu_instance)
			print("Settings menu added to UI layer")
		else:
			print("ERROR: No UI layer for settings menu!")
	else:
		print("Using existing settings menu instance")
	
	settings_menu_instance.show()
	print("Settings menu shown")

func close_settings():
	"""Close settings menu"""
	change_game_state(GameState.PAUSED)
	
	if settings_menu_instance:
		settings_menu_instance.hide()
		if pause_menu_instance:
			pause_menu_instance.on_settings_closed()

func open_achievements():
	"""Open achievements menu with proper UI layering"""
	print("=== Opening Achievements ===")
	change_game_state(GameState.SETTINGS)
	
	# Create achievements menu instance if it doesn't exist
	if not achievements_menu_instance:
		print("Creating achievements menu instance")
		achievements_menu_instance = achievements_menu_scene.instantiate()
		# Connect the close signal
		achievements_menu_instance.achievements_menu_closed.connect(_on_achievements_closed)
		# Add to UI layer, not game scene
		if ui_layer:
			ui_layer.add_child(achievements_menu_instance)
			print("Achievements menu added to UI layer")
		else:
			print("ERROR: No UI layer for achievements menu!")
	else:
		print("Using existing achievements menu instance")
	
	achievements_menu_instance.show_achievements_menu()
	print("Achievements menu shown")

func close_achievements():
	"""Close achievements menu"""
	change_game_state(GameState.PAUSED)
	
	if achievements_menu_instance:
		achievements_menu_instance.hide_achievements_menu()
		if pause_menu_instance:
			pause_menu_instance.on_settings_closed()

func _on_achievements_closed():
	"""Handle achievements menu closed signal"""
	print("=== Achievements Menu Closed ===")
	# Just change game state and show pause menu - don't call close_achievements() again
	change_game_state(GameState.PAUSED)
	if pause_menu_instance:
		pause_menu_instance.on_settings_closed()

func return_to_main_menu():
	"""Return to main menu with proper cleanup"""
	# Save the game before returning to main menu
	_save_game_before_exit()
	
	change_game_state(GameState.MENU)
	clear_ui_layer()
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")

func quit_game():
	"""Quit the game"""
	# Save the game before quitting
	_save_game_before_exit()
	get_tree().quit()

# Signal handlers
func _on_resume_game():
	resume_game()

func _on_open_settings():
	open_settings()

func _on_open_achievements():
	open_achievements()

func _on_return_to_main_menu():
	return_to_main_menu()

func _on_quit_game():
	quit_game()

# Public methods for other scripts
func is_game_paused() -> bool:
	return current_state == GameState.PAUSED or current_state == GameState.SETTINGS

func _save_game_before_exit() -> void:
	"""Save the game before exiting to main menu or quitting"""
	if current_state == GameState.PLAYING or current_state == GameState.PAUSED:
		print("Saving game before exit...")
		if SaveSystemIntegration:
			var success = SaveSystemIntegration.save_current_game()
			if success:
				print("Game saved successfully before exit")
			else:
				print("ERROR: Failed to save game before exit")
		else:
			print("ERROR: SaveSystemIntegration not available for exit save")

func get_current_state() -> GameState:
	return current_state

func recreate_pause_menu_for_scene():
	"""Recreate pause menu instance for the current scene"""
	# Wait a frame to ensure the scene is ready
	await get_tree().process_frame
	create_pause_menu_instance()

func clear_pause_menu():
	"""Clear the pause menu instance"""
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null

func clear_ui_layer():
	"""Clean up UI layer when returning to title screen"""
	if ui_layer:
		ui_layer.queue_free()
		ui_layer = null
	
	if pause_menu_instance:
		pause_menu_instance = null
	
	if settings_menu_instance:
		settings_menu_instance = null

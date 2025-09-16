extends Control

const VERSION = "v0.0.0.5"

var play_button: Button
var multiplayer_button: Button
var settings_button: Button
var quit_button: Button
var dev_play_button: Button
var world_selection_menu: WorldSelectionMenu

func _ready():
	# Set game state to menu
	GameManager.change_game_state(GameManager.GameState.MENU)
	
	# Load saved keybindings
	load_saved_keybindings()
	
	# Get button references
	play_button = $MainContainer/VBoxContainer/ButtonContainer/PlayButton
	multiplayer_button = $MainContainer/VBoxContainer/ButtonContainer/MultiplayerButton
	settings_button = $MainContainer/VBoxContainer/ButtonContainer/SettingsButton
	quit_button = $MainContainer/VBoxContainer/ButtonContainer/QuitButton
	dev_play_button = $MainContainer/VBoxContainer/ButtonContainer/DevPlayButton
	
	# Connect button signals
	play_button.pressed.connect(_on_play_button_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	dev_play_button.pressed.connect(_on_dev_play_button_pressed)
	
	# Create world selection menu
	_create_world_selection_menu()
	
	# Clear any existing UI layer (since we're in title screen)
	GameManager.clear_ui_layer()

func load_saved_keybindings():
	# Load saved keybindings and apply them to the input map
	InputManager.apply_keybindings()

func _create_world_selection_menu():
	"""Create and set up the world selection menu"""
	var world_selection_scene = preload("res://Scenes/UI/WorldSelectionMenu.tscn")
	world_selection_menu = world_selection_scene.instantiate()
	
	# Connect signals
	world_selection_menu.world_selection_menu_closed.connect(_on_world_selection_menu_closed)
	world_selection_menu.new_world_requested.connect(_on_new_world_requested)
	world_selection_menu.world_selected.connect(_on_world_selected)
	world_selection_menu.world_deleted.connect(_on_world_deleted)
	
	# Add to scene
	add_child(world_selection_menu)

func _on_play_button_pressed():
	"""Handle play button press - show world selection menu"""
	world_selection_menu.show_world_selection_menu()

func _on_multiplayer_button_pressed():
	"""Handle multiplayer button press - go to lobby"""
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

func _on_world_selection_menu_closed():
	"""Handle world selection menu closed"""
	# Menu is hidden, no action needed
	pass

func _on_new_world_requested():
	"""Handle new world creation request"""
	# The world selection menu already created the world, just transition to the game
	# Load the loading scene which will then transition to the procedural world
	get_tree().change_scene_to_file("res://Scenes/LoadingScene.tscn")

func _on_world_selected(world_name: String):
	"""Handle world selection"""
	print("Selected world: " + world_name)
	
	# Load the selected world using the SQLite save system
	if SaveSystemIntegration:
		if SaveSystemIntegration.load_world_for_selector(world_name):
			print("World loaded successfully: ", world_name)
			# Load the procedural world scene instead of the premade game scene
			get_tree().change_scene_to_file("res://Scenes/procedural_test.tscn")
		else:
			print("Failed to load world: ", world_name)
	else:
		print("ERROR: SaveSystemIntegration not available!")

func _on_world_deleted(world_name: String):
	"""Handle world deletion"""
	print("World deleted: " + world_name)
	# No additional action needed, the world selection menu will refresh automatically

func _on_settings_button_pressed():
	# Load the styled settings menu
	get_tree().change_scene_to_file("res://Scenes/StyledSettingsMenu.tscn")

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	# Allow ESC to quit from title screen
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _on_dev_play_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
	

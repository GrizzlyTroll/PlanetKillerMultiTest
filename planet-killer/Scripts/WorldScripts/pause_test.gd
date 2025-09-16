extends Node2D

var player: ColorRect

func _ready():
	# Set game state to playing
	GameManager.change_game_state(GameManager.GameState.PLAYING)
	
	# Get player reference
	player = $Player
	
	# Connect to game manager signals
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	
	# Recreate pause menu for this scene
	GameManager.recreate_pause_menu_for_scene()

func _physics_process(delta):
	# Only process input if game is not paused
	if GameManager.is_game_paused():
		return
	
	# Simple player movement for testing
	var movement = Vector2.ZERO
	
	if Input.is_action_pressed("Left"):
		movement.x -= 1
	if Input.is_action_pressed("Right"):
		movement.x += 1
	if Input.is_action_pressed("Jump"):
		movement.y -= 1
	if Input.is_action_pressed("Crouch"):
		movement.y += 1
	
	# Apply movement
	player.position += movement * 200 * delta
	
	# Keep player on screen
	player.position.x = clamp(player.position.x, 0, 1180)
	player.position.y = clamp(player.position.y, 0, 680)

func _on_game_paused():
	"""Called when the game is paused"""
	print("Game paused - player movement stopped")

func _on_game_resumed():
	"""Called when the game is resumed"""
	print("Game resumed - player movement enabled")

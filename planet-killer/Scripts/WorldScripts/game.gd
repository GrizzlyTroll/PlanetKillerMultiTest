extends Node2D

@export var mob_scene_east: PackedScene
@export var mob_scene_west: PackedScene
var gold: int
var wave_number: int
var wave_break: bool
var crosshair = load("res://Assets/Icons/CrossHair.png")

# Multiplayer variables
var network_handler: Node
var multiplayer_spawner: MultiplayerSpawner
var timer_sync_timer: Timer

func _ready():
	# Load saved keybindings when the game starts
	load_saved_keybindings()
	wave_break = true
	%MobTimerWaveBreak.start()
	Input.set_custom_mouse_cursor(crosshair)
	
	# Set game state to playing
	GameManager.change_game_state(GameManager.GameState.PLAYING)
	
	# Connect to game manager signals
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	
	# Start auto-save
	AutoSave.start_auto_save()
	
	# Recreate pause menu for this scene
	GameManager.recreate_pause_menu_for_scene()
	
	# Initialize multiplayer system
	_setup_multiplayer()
	
	# Set up timer sync
	_setup_timer_sync()
	
	## Set up infinite scrolling for parallax layers
	#var parallax_layers = $World/MyParallax.get_children()
	#for layer in parallax_layers:
		#if layer is ParallaxLayer:
			#layer.motion_mirroring = Vector2(1024, 0)  # Adjust based on your texture width
	#

func _physics_process(delta: float) -> void:
	# Update mob timer labels for all players (labels are now in main game scene)
	if has_node("%MobTimerWaveBreakLabel") and has_node("%MobTimerWaveBreak"):
		%MobTimerWaveBreakLabel.text = "Wave Break: %d:%02d" % [floor(%MobTimerWaveBreak.time_left / 60), int(%MobTimerWaveBreak.time_left) % 60]
	if has_node("%MobSpawnDurationLabel") and has_node("%MobSpawnDuration"):
		%MobSpawnDurationLabel.text = "Spawn Duration: %d:%02d" % [floor(%MobSpawnDuration.time_left / 60), int(%MobSpawnDuration.time_left) % 60]

func load_saved_keybindings():
	# Load saved keybindings and apply them to the input map
	InputManager.apply_keybindings()

func _on_game_paused():
	"""Called when the game is paused"""
	print("Game paused")

func _on_game_resumed():
	"""Called when the game is resumed"""
	print("Game resumed")

func _input(event: InputEvent) -> void:
	"""Handle input events"""
	if event.is_action_pressed("Save"):
		_manual_save()

func _manual_save() -> void:
	"""Trigger a manual save"""
	print("Manual save triggered!")
	if SaveSystemIntegration:
		var success = SaveSystemIntegration.save_current_game()
		if success:
			print("Manual save completed successfully!")
			# Show a toast notification
			if ToastManager:
				ToastManager.show_success("Game Saved!", "Your progress has been saved.")
		else:
			print("Manual save failed!")
			if ToastManager:
				ToastManager.show_error("Save Failed!", "Failed to save your progress.")
	else:
		print("SaveSystemIntegration not available!")


func _on_mob_timer_timeout() -> void:
	# Create a new instance of the Mob scene.
	var mobE = mob_scene_east.instantiate()
	var mobW = mob_scene_west.instantiate()
	# Choose a random location on Path2D.
	var mob_spawn_location_east = %MobSpawnLocationEast
	var mob_spawn_location_west = %MobSpawnLocationWest
	mob_spawn_location_east.progress_ratio = randf()
	mob_spawn_location_west.progress_ratio = randf()
	
	# Set the mob's position to the random location.
	mobE.position = mob_spawn_location_east.position
	mobW.position = mob_spawn_location_west.position
	# Spawn the mob by adding it to the Main scene.
	add_child(mobE)
	add_child(mobW)


func _on_mob_timer_wave_break_timeout() -> void:
	%MobTimer.start()
	%MobSpawnDuration.start()
	%MobTimerWaveBreak.stop()
	


func _on_mob_spwan_duration_timeout() -> void:
	%MobTimerWaveBreak.start()
	%MobSpawnDuration.stop()
	%MobTimer.stop()
	%MobSpawnDuration.wait_time += 10

# Multiplayer functions
func _setup_multiplayer() -> void:
	# Get network handler and spawner references
	network_handler = $MultiplayerNodes/NetworkHandler
	multiplayer_spawner = $MultiplayerNodes/MultiplayerSpawner
	
	# Connect network handler signals
	if network_handler:
		network_handler.server_created.connect(_on_server_created)
		network_handler.server_joined.connect(_on_server_joined)
		network_handler.server_left.connect(_on_server_left)
		network_handler.connection_failed.connect(_on_connection_failed)
	
	# Set up multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_server_created() -> void:
	print("Game: Server created successfully")
	# Set up the existing player for multiplayer
	_setup_existing_player()

func _on_server_joined() -> void:
	print("Game: Successfully joined server")
	# Remove the existing player and spawn our own player
	var existing_player = $Player
	if existing_player:
		existing_player.queue_free()
		print("Game: Removed existing player, spawning our own player")
		# Wait for the player to be fully removed before spawning new one
		await get_tree().process_frame
	
	# Spawn our own player as a client
	_spawn_local_player()

func _on_server_left() -> void:
	print("Game: Disconnected from server")
	# Handle disconnection - maybe return to main menu

func _on_connection_failed() -> void:
	print("Game: Failed to connect to server")
	# Show error message to player

func _on_peer_connected(id: int) -> void:
	print("Game: Peer connected: ", id)
	# Don't spawn players for clients - they spawn their own
	# The server just needs to know about the connection

func _on_peer_disconnected(id: int) -> void:
	print("Game: Peer disconnected: ", id)
	# Remove the disconnected player
	var player_node = get_node_or_null(str(id))
	if player_node:
		print("Game: Removing player node: ", str(id))
		player_node.queue_free()
	else:
		print("Game: Player node not found for ID: ", id)

func _setup_existing_player() -> void:
	# Set up the existing player for multiplayer (server only)
	var existing_player = $Player
	if existing_player:
		existing_player.name = str(multiplayer.get_unique_id())
		print("Game: Set up existing player with ID: ", existing_player.name)
		print("Game: Player multiplayer authority: ", existing_player.get_multiplayer_authority())
		print("Game: Local multiplayer ID: ", multiplayer.get_unique_id())
	else:
		print("Game: No existing player found!")

func _spawn_local_player() -> void:
	# This is called when we need to spawn our own player (server or client)
	var player_scene = preload("res://Scenes/PlayerStuff/Player.tscn")
	var player = player_scene.instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.position = Vector2(100 + (multiplayer.get_unique_id() * 50), 100)  # Offset spawn positions
	add_child(player)
	print("Game: Spawned local player with ID: ", player.name, " at position: ", player.position)
	print("Game: Player multiplayer authority: ", player.get_multiplayer_authority())
	print("Game: Local multiplayer ID: ", multiplayer.get_unique_id())
	print("Game: Is server: ", multiplayer.is_server())
	print("Game: Is client: ", multiplayer.is_client())

func _spawn_remote_player(peer_id: int) -> void:
	# This is called by the server when a client connects
	var player_scene = preload("res://Scenes/PlayerStuff/Player.tscn")
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.position = Vector2(100 + (peer_id * 50), 100)  # Offset spawn positions
	add_child(player)

func is_multiplayer_active() -> bool:
	return multiplayer.multiplayer_peer != null

func get_player_count() -> int:
	if is_multiplayer_active():
		return multiplayer.get_peers().size() + 1  # +1 for server
	return 1

# Mob timer synchronization
func _sync_mob_timers() -> void:
	# Only the server should sync timer values
	if not is_multiplayer_active() or not multiplayer.is_server():
		return
	
	# Sync timer values to all clients
	rpc("_update_mob_timers", %MobTimerWaveBreak.time_left, %MobSpawnDuration.time_left)

@rpc("any_peer", "reliable")
func _update_mob_timers(wave_break_time: float, spawn_duration_time: float) -> void:
	# Update timer values on all clients by stopping and starting timers
	if has_node("%MobTimerWaveBreak"):
		%MobTimerWaveBreak.stop()
		%MobTimerWaveBreak.wait_time = wave_break_time
		%MobTimerWaveBreak.start()
	if has_node("%MobSpawnDuration"):
		%MobSpawnDuration.stop()
		%MobSpawnDuration.wait_time = spawn_duration_time
		%MobSpawnDuration.start()

func _setup_timer_sync() -> void:
	# Create a timer to sync mob timers every 2 seconds
	timer_sync_timer = Timer.new()
	timer_sync_timer.wait_time = 2.0
	timer_sync_timer.timeout.connect(_on_timer_sync_timeout)
	add_child(timer_sync_timer)
	timer_sync_timer.start()

func _on_timer_sync_timeout() -> void:
	# Only sync if we're the server
	if is_multiplayer_active() and multiplayer.is_server():
		_sync_mob_timers()

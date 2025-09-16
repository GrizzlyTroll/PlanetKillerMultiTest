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
	# Remove the existing player - the server will spawn all players
	var existing_player = $Player
	if existing_player:
		existing_player.queue_free()
		print("Game: Removed existing player, waiting for server to spawn all players")
		# Wait for the player to be fully removed
		await get_tree().process_frame
	
	# Request the server to spawn all players (including us)
	if not multiplayer.is_server():
		rpc_id(1, "_request_player_spawns")

func _on_server_left() -> void:
	print("Game: Disconnected from server")
	# Handle disconnection - maybe return to main menu

func _on_connection_failed() -> void:
	print("Game: Failed to connect to server")
	# Show error message to player

func _on_peer_connected(id: int) -> void:
	print("Game: Peer connected: ", id)
	# Server spawns a player for the new client
	if multiplayer.is_server():
		_spawn_remote_player(id)
		# Also spawn the new player for all existing clients
		_spawn_player_for_all_clients(id)

func _on_peer_disconnected(id: int) -> void:
	print("Game: Peer disconnected: ", id)
	# Remove the disconnected player from all clients
	if multiplayer.is_server():
		# Remove from server
		var player_node = get_node_or_null(str(id))
		if player_node:
			print("Game: Removing player node from server: ", str(id))
			player_node.queue_free()
		
		# Tell all clients to remove this player
		for client_id in multiplayer.get_peers():
			rpc_id(client_id, "_remove_player_instance", id)
	else:
		# Client removes the player locally
		var player_node = get_node_or_null(str(id))
		if player_node:
			print("Game: Removing player node from client: ", str(id))
			player_node.queue_free()

@rpc("any_peer", "reliable")
func _remove_player_instance(peer_id: int):
	# Remove a player instance
	if not multiplayer.is_server():  # Only clients should receive this
		var player_node = get_node_or_null(str(peer_id))
		if player_node:
			print("Game: Client removing player instance: ", peer_id)
			player_node.queue_free()

func _setup_existing_player() -> void:
	# Set up the existing player for multiplayer (server only)
	var existing_player = $Player
	if existing_player:
		existing_player.name = str(multiplayer.get_unique_id())
		# Add color modulation to distinguish players
		_set_player_color(existing_player, multiplayer.get_unique_id())
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
	player.position = Vector2(100 + (multiplayer.get_unique_id() * 100), 100)  # Increased spacing
	add_child(player)
	
	# Add color modulation to distinguish players
	_set_player_color(player, multiplayer.get_unique_id())
	
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
	player.position = Vector2(100 + (peer_id * 100), 100)  # Increased spacing
	add_child(player)
	
	# Add color modulation to distinguish players
	_set_player_color(player, peer_id)
	
	print("Game: Server spawned player for peer: ", peer_id)
	print("Game: Server player authority: ", player.get_multiplayer_authority())
	print("Game: Server local ID: ", multiplayer.get_unique_id())

func _spawn_player_for_all_clients(peer_id: int) -> void:
	# Spawn the new player on all existing clients
	for client_id in multiplayer.get_peers():
		if client_id != peer_id:  # Don't send to the new client (they'll get it via _request_player_spawns)
			rpc_id(client_id, "_spawn_player_instance", peer_id, Vector2(100 + (peer_id * 100), 100))

@rpc("any_peer", "reliable")
func _request_player_spawns():
	# Client requests all current players to be spawned
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("Game: Client ", sender_id, " requested player spawns")
		
		# Spawn all existing players for the requesting client
		for peer_id in multiplayer.get_peers():
			if peer_id != sender_id:  # Don't spawn the requesting client's player
				rpc_id(sender_id, "_spawn_player_instance", peer_id, Vector2(100 + (peer_id * 100), 100))
		
		# Spawn the requesting client's player for all other clients
		_spawn_player_for_all_clients(sender_id)
		
		# Debug: Check authorities after spawning
		await get_tree().process_frame
		debug_player_authorities()

@rpc("any_peer", "reliable")
func _spawn_player_instance(peer_id: int, position: Vector2):
	# Spawn a player instance for a specific peer
	if not multiplayer.is_server():  # Only clients should receive this
		var player_scene = preload("res://Scenes/PlayerStuff/Player.tscn")
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		player.position = position
		add_child(player)
		
		# Add color modulation to distinguish players
		_set_player_color(player, peer_id)
		
		print("Game: Client spawned player instance for peer: ", peer_id, " at position: ", position)
		print("Game: Player authority after spawn: ", player.get_multiplayer_authority())
		print("Game: Local multiplayer ID: ", multiplayer.get_unique_id())
		print("Game: Should this player have authority? ", (peer_id == multiplayer.get_unique_id()))
		
		# Debug: Check authorities after spawning
		await get_tree().process_frame
		debug_player_authorities()

func is_multiplayer_active() -> bool:
	return multiplayer.multiplayer_peer != null

func get_player_count() -> int:
	if is_multiplayer_active():
		return multiplayer.get_peers().size() + 1  # +1 for server
	return 1

func _set_player_color(player: Node, peer_id: int):
	# Set a unique color for each player to distinguish them
	var colors = [
		Color.WHITE,      # Player 1 (server) - default white
		Color.RED,        # Player 2 - red
		Color.BLUE,       # Player 3 - blue
		Color.GREEN,      # Player 4 - green
		Color.YELLOW,     # Player 5 - yellow
		Color.MAGENTA,    # Player 6 - magenta
		Color.CYAN,       # Player 7 - cyan
		Color.ORANGE      # Player 8 - orange
	]
	
	var color_index = (peer_id - 1) % colors.size()
	var sprite = player.get_node("AnimatedSprite2D")
	if sprite:
		sprite.modulate = colors[color_index]
		print("Game: Set player ", peer_id, " color to: ", colors[color_index])

func debug_player_authorities():
	# Debug function to check all player authorities
	print("=== PLAYER AUTHORITY DEBUG ===")
	print("Local multiplayer ID: ", multiplayer.get_unique_id())
	print("Is server: ", multiplayer.is_server())
	print("Is client: ", multiplayer.is_client())
	
	for child in get_children():
		if child.name.is_valid_int():
			print("Player ", child.name, " - Authority: ", child.get_multiplayer_authority(), " - Should have authority: ", (child.name.to_int() == multiplayer.get_unique_id()))
	print("=== END DEBUG ===")

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

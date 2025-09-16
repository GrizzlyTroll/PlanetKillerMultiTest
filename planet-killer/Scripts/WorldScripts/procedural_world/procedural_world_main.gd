extends Node2D
class_name ProceduralWorldMain

# World parameters
var world_seed: int
var chunk_size: int = WorldConstants.CHUNK_SIZE
var world_width: int = WorldConstants.WORLD_WIDTH
var world_height: int = WorldConstants.WORLD_HEIGHT
var block_size: int = WorldConstants.BLOCK_SIZE

# Component systems
var noise_generator: NoiseGenerator
var chunk_manager: ChunkManager
var day_night_system: DayNightSystemManager
var world_config: WorldGenerationConfig

# Block breaking system
var block_health: Dictionary = {}  # Stores health for each block position
var modified_blocks: Dictionary = {}  # Stores only blocks modified by the player
var player: CharacterBody2D
var is_loading_existing_world: bool = false

func _ready():
	# Add this world to the "World" group for save system integration
	add_to_group("World")
	
	# Check if we're loading an existing world or creating a new one
	is_loading_existing_world = _check_for_existing_world_data()
	
	if is_loading_existing_world:
		# Load existing world data
		_load_existing_world()
	else:
		# Create new world
		_create_new_world()
	
	# Set up GameManager integration
	GameManager.change_game_state(GameManager.GameState.PLAYING)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	
	# Create pause menu for this scene
	GameManager.recreate_pause_menu_for_scene()

func _check_for_existing_world_data() -> bool:
	"""Check if there's existing world data to load"""
	if SaveSystemIntegration:
		var sqlite_manager = SaveSystemIntegration.get_sqlite_save_manager()
		if sqlite_manager and sqlite_manager.current_world_name != "":
			# Check if world data exists in the database
			var world_manager = sqlite_manager.world_data_save_manager
			var load_result = world_manager.load_world_data()
			
			if load_result:
				var saved_seed = world_manager.get_world_seed()
				var last_save_time = world_manager.get_all_world_data().get("last_save_time", 0)
				
				
				# Only consider it existing if we have a valid seed or save time
				# Don't check world_data.size() as it's always > 0 due to default structure
				if saved_seed != 0 or last_save_time > 0:
					print("Found existing world data with seed: ", saved_seed, " and last save time: ", last_save_time)
					return true
				else:
					print("No existing world data found (seed: ", saved_seed, ", last save: ", last_save_time, ")")
			else:
				print("Failed to load world data from database")
		else:
			print("No SQLite manager or world name not set")
	else:
		print("SaveSystemIntegration not available")
	return false

func _load_existing_world() -> void:
	"""Load an existing world from save data"""
	print("Loading existing world...")
	
	if SaveSystemIntegration:
		var sqlite_manager = SaveSystemIntegration.get_sqlite_save_manager()
		var world_manager = sqlite_manager.world_data_save_manager
		
		# Load the world seed from save data
		world_seed = world_manager.get_world_seed()
		print("Using saved world seed: ", world_seed)
		
		# Initialize world generation configuration
		world_config = WorldGenerationConfig.get_default_config()
		
		# Try to load custom configuration if it exists
		var config_paths = [
			"user://world_generation_config.json",
			"res://Ini Files/world_generation_config.json"
		]
		
		var config_loaded = false
		for config_path in config_paths:
			if FileAccess.file_exists(config_path):
				if world_config.load_from_file(config_path):
					print("Loaded custom world generation configuration from: ", config_path)
					config_loaded = true
					break
				else:
					print("Failed to load configuration from: ", config_path)
		
		if not config_loaded:
			print("Using default world generation configuration")
		
		# Initialize component systems with the saved seed
		noise_generator = NoiseGenerator.new()
		noise_generator.setup_noise(world_seed)
		
		# Apply configuration to noise generator
		world_config.apply_to_noise_generator(noise_generator)
		
		# Initialize biome system with world seed
		BiomeSystem.initialize_biome_system(world_seed)
		
		# Apply configuration to biome system
		world_config.apply_to_biome_system()
		
		chunk_manager = ChunkManager.new()
		chunk_manager.world_seed = world_seed
		chunk_manager.world_height = world_height
		chunk_manager.cave_noise = noise_generator.cave_noise
		
		# Set up chunk manager with our implementations
		chunk_manager.noise_generator = noise_generator
		chunk_manager.parent_node = self
		chunk_manager.block_size = block_size
		chunk_manager.block_health = block_health
		chunk_manager.world_config = world_config
		
		# Generate world with saved seed
		generate_world()
		
		# Load player and other data
		_load_player_data()
		setup_day_night_system()
		
		print("Existing world loaded successfully!")
	else:
		print("ERROR: SaveSystemIntegration not available for loading existing world!")
		# Fallback to creating new world
		_create_new_world()

func _create_new_world() -> void:
	"""Create a new world with random seed"""
	print("Creating new world...")
	
	randomize()
	world_seed = randi()
	print("Generated new world seed: ", world_seed)
	
	# Initialize world generation configuration
	world_config = WorldGenerationConfig.get_default_config()
	
	# Try to load custom configuration if it exists
	var config_paths = [
		"user://world_generation_config.json",
		"res://Ini Files/world_generation_config.json"
	]
	
	var config_loaded = false
	for config_path in config_paths:
		if FileAccess.file_exists(config_path):
			if world_config.load_from_file(config_path):
				print("Loaded custom world generation configuration from: ", config_path)
				config_loaded = true
				break
			else:
				print("Failed to load configuration from: ", config_path)
	
	if not config_loaded:
		print("Using default world generation configuration")
	
	# Initialize component systems
	noise_generator = NoiseGenerator.new()
	noise_generator.setup_noise(world_seed)
	
	# Apply configuration to noise generator
	world_config.apply_to_noise_generator(noise_generator)
	
	# Initialize biome system with world seed
	BiomeSystem.initialize_biome_system(world_seed)
	
	# Apply configuration to biome system
	world_config.apply_to_biome_system()
	
	chunk_manager = ChunkManager.new()
	chunk_manager.world_seed = world_seed
	chunk_manager.world_height = world_height
	chunk_manager.cave_noise = noise_generator.cave_noise
	
	# Set up chunk manager with our implementations
	chunk_manager.noise_generator = noise_generator
	chunk_manager.parent_node = self
	chunk_manager.block_size = block_size
	chunk_manager.block_health = block_health
	chunk_manager.world_config = world_config
	
	generate_world()
	spawn_player()
	setup_day_night_system()

func _load_player_data() -> void:
	"""Load player data from save system"""
	if SaveSystemIntegration:
		# Load world data first (chunks and blocks) - this must happen before player spawning
		# so that the world is ready when the player spawns
		var sqlite_manager = SaveSystemIntegration.get_sqlite_save_manager()
		if sqlite_manager.load_world_data():
			# Apply world data (chunks and blocks) first
			SaveSystemIntegration._apply_world_data_to_game()
			
			# Wait a frame to ensure chunks are fully placed
			await get_tree().process_frame
			
			# Now get saved player position and spawn player
			var player_manager = sqlite_manager.player_save_manager
			var saved_position = player_manager.get_player_position()
			
			
			# Spawn player at saved position
			spawn_player_at_position(saved_position)
			
			# Apply player data to the spawned player
			SaveSystemIntegration._apply_player_data_to_game()
			
			# Apply other data (inventory, achievements, entities)
			SaveSystemIntegration._apply_inventory_data_to_game()
			SaveSystemIntegration._apply_achievement_data_to_game()
			SaveSystemIntegration._apply_entity_data_to_game()
			
			# Set player chunk position after player is spawned and data is applied
			if player and chunk_manager:
				var player_world_x = int(player.position.x / block_size)
				var player_world_y = int(player.position.y / block_size)
				chunk_manager.set_player_chunk_position(player_world_x, player_world_y)
		else:
			print("Failed to load world data, falling back to new player")
			spawn_player()
	else:
		# Fallback to spawning new player
		spawn_player()

func generate_world() -> void:
	print("Starting infinite world generation...")
	print("World dimensions: Infinite width x ", world_height, " blocks deep")
	
	# Generate initial chunks around spawn point
	chunk_manager.generate_initial_chunks()
	
	print("=== INITIAL WORLD GENERATION COMPLETE ===")
	
	# Only auto-save if this is a new world (not loading existing)
	if not is_loading_existing_world:
		_auto_save_after_generation()
	else:
		print("Skipping auto-save for existing world")

func _auto_save_after_generation() -> void:
	"""Auto-save the world after initial generation is complete"""
	print("🔄 Auto-save: World generation complete, saving initial state...")
	print("Current world seed: ", world_seed)
	
	# Wait a frame to ensure everything is properly initialized
	await get_tree().process_frame
	
	if SaveSystemIntegration:
		# Update world data with current generation info
		var world_manager = SaveSystemIntegration.get_sqlite_save_manager().world_data_save_manager
		print("Setting world seed to: ", world_seed)
		world_manager.set_world_seed(world_seed)
		world_manager.set_world_setting("generation_complete", true)
		world_manager.set_world_setting("initial_chunks_generated", chunk_manager.loaded_chunks.size())
		world_manager.set_world_setting("world_height", world_height)
		
		# Verify the seed was set correctly
		var saved_seed = world_manager.get_world_seed()
		print("Verified saved seed: ", saved_seed)
		
		# Save the world
		var success = SaveSystemIntegration.save_current_game()
		if success:
			print("✅ Auto-save: Initial world state saved successfully!")
			# Show a toast notification
			if ToastManager:
				ToastManager.show_success("World Generated!", "Initial world state has been saved.")
		else:
			print("❌ Auto-save: Failed to save initial world state!")
			if ToastManager:
				ToastManager.show_error("Save Failed!", "Failed to save initial world state.")
	else:
		print("⚠️ Auto-save: SaveSystemIntegration not available!")

func setup_day_night_system() -> void:
	"""Set up the day/night cycle system"""
	day_night_system = DayNightIntegration.setup_day_night_system(self)

func spawn_player() -> void:
	"""Spawn the player at a safe location"""
	# Position player at a safe spawn point (above the surface)
	var spawn_x = 0  # Center of chunk 0
	var spawn_y = 10  # Above the surface
	var spawn_position = Vector2(spawn_x * block_size, spawn_y * block_size)
	spawn_player_at_position(spawn_position)

func spawn_player_at_position(position: Vector2) -> void:
	"""Spawn the player at a specific position"""
	# Load the original player scene as a PackedScene (like Unity's Prefab)
	var player_scene = load("res://Scenes/PlayerStuff/Player.tscn")
	if player_scene:
		# Instance the player scene
		var player_instance = player_scene.instantiate()
		player_instance.name = "Player"
		
		# Find a safe spawn position (no blocks above player)
		var safe_position = _find_safe_spawn_position(position)
		player_instance.position = safe_position
		
		add_child(player_instance)
		player = player_instance
		print("Player spawned at safe position: ", player_instance.position)
		
		# Add drill tool to player
		setup_drill_tool(player_instance)
	else:
		print("ERROR: Could not load player scene!")

func _find_safe_spawn_position(original_position: Vector2) -> Vector2:
	"""Find a safe spawn position where the player won't be blocked by objects"""
	var world_x = int(original_position.x / block_size)
	var world_y = int(original_position.y / block_size)
	
	# Check if there are blocks at the original position
	var has_block_at_position = BlockBreaking.has_block_at_world_coords(world_x, world_y, self, block_size)
	
	if not has_block_at_position:
		# Original position is safe
		return original_position
	
	# Search for a safe position nearby
	var search_radius = 10  # Search within 10 blocks
	for radius in range(1, search_radius + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				# Only check positions on the edge of the current radius
				if abs(dx) == radius or abs(dy) == radius:
					var test_x = world_x + dx
					var test_y = world_y + dy
					
					# Check if this position is safe (no blocks)
					if not BlockBreaking.has_block_at_world_coords(test_x, test_y, self, block_size):
						var safe_position = Vector2(test_x * block_size, test_y * block_size)
						print("Found safe spawn position at: ", safe_position, " (moved from: ", original_position, ")")
						return safe_position
	
	# If no safe position found, spawn above the original position
	var safe_y = world_y - 5  # 5 blocks above
	var safe_position = Vector2(world_x * block_size, safe_y * block_size)
	print("No safe position found nearby, spawning above at: ", safe_position)
	return safe_position

func setup_drill_tool(player_instance: CharacterBody2D) -> void:
	"""Setup drill tool for the player"""
	# Create a simple drill visual that stays with the player
	var drill = Area2D.new()
	drill.name = "Drill"
	
	# Add a simple sprite for the drill
	var sprite = Sprite2D.new()
	var drill_texture = load("res://Assets/ItemsEQ/Drill.png")
	if drill_texture:
		sprite.texture = drill_texture
		sprite.scale = Vector2(0.5, 0.5)  # Make it smaller
	drill.add_child(sprite)
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(8, 8)
	collision.shape = shape
	drill.add_child(collision)
	
	# Position the drill relative to the player
	drill.position = Vector2(8, 0)  # Offset to the right of player
	
	player_instance.add_child(drill)
	print("Simple drill tool added to player")

func _process(delta: float) -> void:
	"""Process function to handle infinite world generation"""
	if player:
		# Only update chunks periodically to improve performance
		chunk_manager.last_chunk_update += 1
		if chunk_manager.last_chunk_update >= chunk_manager.chunk_update_threshold:
			chunk_manager.last_chunk_update = 0
			
			# Convert player position to world coordinates
			var player_world_x = int(player.position.x / block_size)
			var player_world_y = int(player.position.y / block_size)
			
			chunk_manager.update_chunks(player_world_x, player_world_y)



func _input(event: InputEvent) -> void:
	"""Handle input for block breaking and day/night testing"""
	if event.is_action_pressed("Dig") and player:
		handle_dig_input()
	
	# Handle manual save (F5 key)
	if event.is_action_pressed("Save"):
		_manual_save()
	
	# Handle day/night system input
	DayNightIntegration.handle_day_night_input(event, day_night_system)

func handle_dig_input() -> void:
	"""Handle dig input - break blocks near player"""
	if not player:
		return
	
	var mouse_pos = get_global_mouse_position()
	var player_pos = player.global_position
	var distance = mouse_pos.distance_to(player_pos)
	
	# Only allow digging within a certain range
	if distance > 100:  # 100 pixel range
		return
	
	# Find the block at mouse position
	var block = BlockBreaking.get_block_at_position(mouse_pos, self, block_size)
	if block:
		BlockBreaking.break_block(block, block_health, modified_blocks)

func _on_game_paused():
	"""Handle game pause event from GameManager"""
	print("Procedural world: Game paused")

func _on_game_resumed():
	"""Handle game resume event from GameManager"""
	print("Procedural world: Game resumed")

## Save/Load System Integration Methods

func get_world_seed() -> int:
	"""Get the current world seed"""
	return world_seed

func set_world_seed(seed: int) -> void:
	"""Set the world seed"""
	world_seed = seed

func get_world_settings() -> Dictionary:
	"""Get world settings"""
	return {
		"chunk_size": chunk_size,
		"world_width": world_width,
		"world_height": world_height,
		"block_size": block_size
	}

func set_world_settings(settings: Dictionary) -> void:
	"""Set world settings"""
	if settings.has("chunk_size"):
		chunk_size = settings.chunk_size
	if settings.has("world_width"):
		world_width = settings.world_width
	if settings.has("world_height"):
		world_height = settings.world_height
	if settings.has("block_size"):
		block_size = settings.block_size

func get_chunk_manager() -> ChunkManager:
	"""Get the chunk manager instance"""
	return chunk_manager

func get_block_health() -> Dictionary:
	"""Get the block health dictionary"""
	return block_health

func set_block_health(health_data: Dictionary) -> void:
	"""Set the block health dictionary"""
	block_health = health_data
	if chunk_manager:
		chunk_manager.block_health = block_health

func get_modified_blocks() -> Dictionary:
	"""Get only blocks that were modified by the player"""
	return modified_blocks.duplicate()

func set_modified_blocks(blocks_data: Dictionary) -> void:
	"""Set the modified blocks dictionary"""
	modified_blocks = blocks_data

func _manual_save() -> void:
	"""Handle manual save request"""
	print("Manual save requested...")
	
	if SaveSystemIntegration:
		var success = SaveSystemIntegration.save_current_game()
		if success:
			print("✅ Manual save completed successfully!")
			if ToastManager:
				ToastManager.show_success("Game Saved!", "Your progress has been saved.")
		else:
			print("❌ Manual save failed!")
			if ToastManager:
				ToastManager.show_error("Save Failed!", "Failed to save your progress.")
	else:
		print("ERROR: SaveSystemIntegration not available for manual save!")
		if ToastManager:
			ToastManager.show_error("Save Error!", "Save system not available.")

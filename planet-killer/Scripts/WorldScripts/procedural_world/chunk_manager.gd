extends RefCounted
class_name ChunkManager

# Chunk management for infinite world
var loaded_chunks: Dictionary = {}  # Stores loaded chunks by chunk coordinates
var current_chunk_x: int = 0  # Current chunk the player is in
var current_chunk_y: int = 0  # Current chunk the player is in (vertical)
var last_chunk_update: int = 0  # Track last chunk update to avoid excessive updates
var chunk_update_threshold: int = WorldConstants.CHUNK_UPDATE_THRESHOLD
var _has_loaded_existing_chunks: bool = false  # Track if we've loaded existing chunks from save

func get_chunk_coordinate(world_x: int) -> int:
	"""Convert world coordinate to chunk coordinate"""
	return int(floor(float(world_x) / float(WorldConstants.CHUNK_SIZE)))

func get_chunk_coordinate_y(world_y: int) -> int:
	"""Convert world Y coordinate to chunk coordinate"""
	return int(floor(float(world_y) / float(WorldConstants.CHUNK_SIZE)))

func get_chunk_key(chunk_x: int, chunk_y: int) -> String:
	"""Get a unique key for a chunk coordinate pair"""
	return str(chunk_x) + "," + str(chunk_y)

func update_chunks(player_world_x: int, player_world_y: int) -> void:
	"""Update chunks based on player position - now handles both X and Y coordinates"""
	var player_chunk_x = get_chunk_coordinate(player_world_x)
	var player_chunk_y = get_chunk_coordinate_y(player_world_y)
	
	# Check if player moved to a new chunk
	if player_chunk_x != current_chunk_x or player_chunk_y != current_chunk_y:
		current_chunk_x = player_chunk_x
		current_chunk_y = player_chunk_y
		
		# Generate all adjacent chunks (including diagonals)
		generate_adjacent_chunks(player_chunk_x, player_chunk_y)
		
		# Unload distant chunks to save memory
		unload_distant_chunks()

func generate_adjacent_chunks(center_chunk_x: int, center_chunk_y: int) -> void:
	"""Generate all chunks adjacent to the player's current chunk (including diagonals)"""
	# Generate a 3x3 grid around the player's chunk
	for chunk_x in range(center_chunk_x - 1, center_chunk_x + 2):
		for chunk_y in range(center_chunk_y - 1, center_chunk_y + 2):
			var chunk_key = get_chunk_key(chunk_x, chunk_y)
			if chunk_key not in loaded_chunks:
				generate_chunk(chunk_x, chunk_y)

func generate_extended_chunks(center_chunk_x: int, center_chunk_y: int) -> void:
	"""Generate an extended area of chunks around the player - used when loading from save"""
	# Generate a 5x5 grid around the player's chunk to ensure we cover movement
	for chunk_x in range(center_chunk_x - 2, center_chunk_x + 3):
		for chunk_y in range(center_chunk_y - 2, center_chunk_y + 3):
			var chunk_key = get_chunk_key(chunk_x, chunk_y)
			if chunk_key not in loaded_chunks:
				generate_chunk(chunk_x, chunk_y)

func unload_distant_chunks() -> void:
	"""Unload chunks that are too far from the player"""
	var chunks_to_unload = []
	
	for chunk_key in loaded_chunks:
		var chunk_coords = chunk_key.split(",")
		var chunk_x = int(chunk_coords[0])
		var chunk_y = int(chunk_coords[1])
		
		# Calculate Manhattan distance to current chunk
		var distance = abs(chunk_x - current_chunk_x) + abs(chunk_y - current_chunk_y)
		
		# Keep chunks loaded longer - only unload if they're beyond the buffer distance
		# Be more conservative when we've loaded existing chunks to prevent immediate unloading
		var unload_distance = 2 + WorldConstants.CHUNK_UNLOAD_BUFFER
		if _has_loaded_existing_chunks:
			unload_distance += 1  # Keep chunks loaded longer after loading from save
		
		if distance > unload_distance:
			chunks_to_unload.append(chunk_key)
	
	for chunk_key in chunks_to_unload:
		loaded_chunks.erase(chunk_key)
		print("Unloaded chunk: ", chunk_key)
	
	# Debug: Show current chunk status
	if loaded_chunks.size() > 0:
		print("Loaded chunks: ", loaded_chunks.keys(), " (Player in chunk: ", current_chunk_x, ",", current_chunk_y, ")")

func generate_initial_chunks() -> void:
	"""Generate the initial chunks around the spawn point"""
	print("Generating initial chunks...")
	
	# Only generate initial chunks if we haven't loaded existing chunks
	if not _has_loaded_existing_chunks:
		# Generate a 3x3 grid of chunks around spawn point
		for chunk_x in range(-WorldConstants.INITIAL_CHUNKS_RANGE, WorldConstants.INITIAL_CHUNKS_RANGE + 1):
			for chunk_y in range(-WorldConstants.INITIAL_CHUNKS_RANGE, WorldConstants.INITIAL_CHUNKS_RANGE + 1):
				generate_chunk(chunk_x, chunk_y)
	else:
		print("Skipping initial chunk generation - existing chunks loaded from save")

func generate_chunk(chunk_x: int, chunk_y: int) -> void:
	"""Generate a single chunk at the specified chunk coordinates"""
	var chunk_key = get_chunk_key(chunk_x, chunk_y)
	if chunk_key in loaded_chunks:
		# Check if this chunk was loaded from save data but doesn't have blocks placed
		# If it's just metadata from save, we need to place the blocks
		if not _has_loaded_existing_chunks:
			return  # Chunk already loaded and generated
	
	
	# Add a small delay to prevent freezing
	await Engine.get_main_loop().process_frame
	
	var chunk_data = {}
	var biome_counts = {}
	
	# Calculate world coordinates for this chunk
	var chunk_start_x = chunk_x * WorldConstants.CHUNK_SIZE
	var chunk_end_x = chunk_start_x + WorldConstants.CHUNK_SIZE
	var chunk_start_y = chunk_y * WorldConstants.CHUNK_SIZE
	var chunk_end_y = chunk_start_y + WorldConstants.CHUNK_SIZE
	
	# Check if this is a starting area based on configuration
	var is_starting_area = false
	if world_config:
		is_starting_area = world_config.is_starting_area(chunk_x, chunk_y)
	else:
		# Fallback to default behavior
		is_starting_area = abs(chunk_x) <= 2 and abs(chunk_y) <= 2
	
	# Generate each column in the chunk
	for x in range(chunk_start_x, chunk_end_x):
		var temperature = get_temperature(x)
		var humidity = get_humidity(x)
		
		# Get biome first, then elevation based on biome
		var biome = BiomeSystem.get_biome(x, temperature, humidity, 0, is_starting_area)
		var elevation = get_elevation(x, biome, is_starting_area)
		
		# Count biomes for debug output
		var biome_name = BiomeSystem.get_biome_name(biome)
		if biome_name in biome_counts:
			biome_counts[biome_name] += 1
		else:
			biome_counts[biome_name] = 1
		
		# Generate the column from top to bottom of the chunk
		for y in range(chunk_start_y, chunk_end_y):
			var block_type = BlockSystem.get_block_type(x, y, elevation, biome, world_seed, world_height, cave_noise)
			if block_type != "air":
				place_block(x, y, block_type)
		
		# Add biome-specific features
		add_biome_features(x, elevation, biome)
		
		# Store chunk data
		chunk_data[x] = {
			"elevation": elevation,
			"temperature": temperature,
			"humidity": humidity,
			"biome": biome
		}
		
		# Add small delay every few columns to prevent freezing
		if x % 16 == 0:
			await Engine.get_main_loop().process_frame
	
	# Store the chunk data
	loaded_chunks[chunk_key] = chunk_data
	
	
	# Debug output for first chunk
	if chunk_x == 0 and chunk_y == 0:
		print("=== CHUNK 0,0 BIOME DISTRIBUTION ===")
		for biome_name in biome_counts:
			print(biome_name, ": ", biome_counts[biome_name], " columns")
		print("Chunk 0,0 generated with ", WorldConstants.CHUNK_SIZE, "x", WorldConstants.CHUNK_SIZE, " blocks")

# References to external systems - set by main procedural world class
var noise_generator: NoiseGenerator
var parent_node: Node2D
var block_size: int = WorldConstants.BLOCK_SIZE
var block_health: Dictionary
var world_config: WorldGenerationConfig

# These variables need to be set by the main procedural world class
var world_seed: int = 0
var world_height: int = WorldConstants.WORLD_HEIGHT
var cave_noise: FastNoiseLite

# Function implementations that use the external references
func get_elevation(x: int, biome: BiomeSystem.BIOME_TYPE = BiomeSystem.BIOME_TYPE.PLAINS, is_starting_area: bool = false) -> int:
	if noise_generator:
		return noise_generator.get_elevation(x, biome, is_starting_area, world_config)
	return 0

func get_temperature(x: int) -> float:
	if noise_generator:
		return noise_generator.get_temperature(x)
	return 0.0

func get_humidity(x: int) -> float:
	if noise_generator:
		return noise_generator.get_humidity(x)
	return 0.0

func place_block(x: int, y: int, block_type: String) -> void:
	if parent_node and block_size > 0:
		BlockBreaking.place_block(x, y, block_type, parent_node, block_size, block_health)

func add_biome_features(x: int, surface_height: int, biome: BiomeSystem.BIOME_TYPE) -> void:
	if parent_node:
		BiomeFeatures.add_biome_features(x, surface_height, biome, place_block)

## Save/Load System Integration Methods

func get_loaded_chunks() -> Dictionary:
	"""Get all currently loaded chunks"""
	return loaded_chunks.duplicate()

func load_chunks_from_data(chunks_data: Dictionary) -> void:
	"""Load chunks from saved data"""
	print("DEBUG: Loading chunks from saved data: ", chunks_data.size(), " chunks")
	
	# Clear existing chunks
	loaded_chunks.clear()
	
	# Load each chunk and actually place the blocks
	for chunk_key in chunks_data:
		var chunk_data = chunks_data[chunk_key]
		loaded_chunks[chunk_key] = chunk_data
		
		# Actually place the blocks for this chunk
		_place_chunk_blocks_from_data(chunk_key, chunk_data)
	
	print("DEBUG: Loaded and placed ", loaded_chunks.size(), " chunks from save data")
	
	# CRITICAL: Mark that we've loaded existing chunks so new generation works properly
	# This ensures chunk generation continues for new areas
	_has_loaded_existing_chunks = true

func _place_chunk_blocks_from_data(chunk_key: String, chunk_data: Dictionary) -> void:
	"""Actually place the blocks for a chunk from saved data"""
	var coords = chunk_key.split(",")
	if coords.size() < 2:
		return
	
	var chunk_x = int(coords[0])
	var chunk_y = int(coords[1])
	
	print("DEBUG: Placing blocks for chunk ", chunk_key, " with ", chunk_data.size(), " columns")
	
	# Calculate world coordinates for this chunk
	var chunk_start_x = chunk_x * WorldConstants.CHUNK_SIZE
	var chunk_end_x = chunk_start_x + WorldConstants.CHUNK_SIZE
	var chunk_start_y = chunk_y * WorldConstants.CHUNK_SIZE
	var chunk_end_y = chunk_start_y + WorldConstants.CHUNK_SIZE
	
	# Place blocks for each column in the chunk
	for x in range(chunk_start_x, chunk_end_x):
		# Convert integer to string key since chunk data uses string keys
		var x_key = str(x)
		if not chunk_data.has(x_key):
			continue
			
		var column_data = chunk_data[x_key]
		var elevation = column_data.get("elevation", 0)
		var biome = column_data.get("biome", BiomeSystem.BIOME_TYPE.PLAINS)
		
		# Generate the column from top to bottom of the chunk
		var blocks_placed_in_column = 0
		for y in range(chunk_start_y, chunk_end_y):
			# Check if this block has been modified (broken/placed)
			var block_key = Vector2i(x, y)
			var has_modification = false
			
			if block_health and block_health.has(block_key):
				# This block has been modified - check if it should be air or a different type
				var health = block_health[block_key]
				if health <= 0:
					# Block was broken - don't place anything (air)
					has_modification = true
				else:
					# Block was damaged but not broken - place the original block type
					var block_type = BlockSystem.get_block_type(x, y, elevation, biome, world_seed, world_height, cave_noise)
					if block_type != "air":
						place_block(x, y, block_type)
						blocks_placed_in_column += 1
					has_modification = true
			
			# If no modification, place the original block
			if not has_modification:
				var block_type = BlockSystem.get_block_type(x, y, elevation, biome, world_seed, world_height, cave_noise)
				if block_type != "air":
					place_block(x, y, block_type)
					blocks_placed_in_column += 1
		
		
		# Add biome-specific features (only if no blocks were modified in this column)
		var column_has_modifications = false
		for y in range(chunk_start_y, chunk_end_y):
			var block_key = Vector2i(x, y)
			if block_health and block_health.has(block_key):
				column_has_modifications = true
				break
		
		if not column_has_modifications:
			add_biome_features(x, elevation, biome)

func set_player_chunk_position(player_world_x: int, player_world_y: int) -> void:
	"""Set the player's current chunk position - used when loading from save"""
	var player_chunk_x = get_chunk_coordinate(player_world_x)
	var player_chunk_y = get_chunk_coordinate_y(player_world_y)
	
	current_chunk_x = player_chunk_x
	current_chunk_y = player_chunk_y
	
	# When loading from save, generate a larger area to ensure we cover the player's movement
	# Generate a 5x5 grid instead of 3x3 to account for potential player movement
	if _has_loaded_existing_chunks:
		generate_extended_chunks(current_chunk_x, current_chunk_y)
	else:
		generate_adjacent_chunks(current_chunk_x, current_chunk_y)
extends RefCounted
class_name WorldDataSaveManager

## World Data Save Manager - Handles saving and loading world-specific data
## Manages chunks, blocks, world generation settings, and world state

# Database reference
var database: SQLite

# Table configuration
const TABLE_NAME = "world_data"

# World data structure
var world_data: Dictionary = {
	"world_seed": 0,
	"world_settings": {},
	"chunks": {},  # chunk_key -> chunk_data
	"blocks": {},  # block_key -> block_data
	"world_events": [],  # Array of world events
	"last_save_time": 0
}

func set_database(db: SQLite) -> void:
	"""Set the database reference"""
	database = db

func create_table() -> bool:
	"""Create the world_data table"""
	if not database:
		print("ERROR: Database not initialized in world data save manager")
		return false
	
	print("DEBUG: Creating world_data table: ", TABLE_NAME)
	
	var query = """
		CREATE TABLE IF NOT EXISTS %s (
			id INTEGER PRIMARY KEY,
			world_seed INTEGER NOT NULL DEFAULT 0,
			world_settings TEXT NOT NULL DEFAULT '{}',
			chunks_data TEXT NOT NULL DEFAULT '{}',
			blocks_data TEXT NOT NULL DEFAULT '{}',
			world_events TEXT NOT NULL DEFAULT '[]',
			last_save_time INTEGER NOT NULL DEFAULT 0
		)
	""" % [TABLE_NAME]
	
	print("DEBUG: World_data table query: ", query)
	var result = database.query(query)
	print("DEBUG: World_data table creation result: ", result)
	
	# Try to verify the table was created
	if result:
		var verify_query = "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'" % TABLE_NAME
		var verify_result = database.query(verify_query)
		if verify_result:
			print("DEBUG: World_data table verification successful")
	
	return result

func save_world_data() -> bool:
	"""Save current world data to database"""
	if not database:
		return false
	
	# Update save time
	world_data.last_save_time = Time.get_unix_time_from_system()
	
	# Convert data to JSON strings
	var world_settings_json = JSON.stringify(world_data.world_settings)
	var chunks_json = JSON.stringify(world_data.chunks)
	var blocks_json = JSON.stringify(world_data.blocks)
	var world_events_json = JSON.stringify(world_data.world_events)
	
	# Use insert_row instead of raw SQL
	var row_data = {
		"id": 1,
		"world_seed": world_data.world_seed,
		"world_settings": world_settings_json,
		"chunks_data": chunks_json,
		"blocks_data": blocks_json,
		"world_events": world_events_json,
		"last_save_time": world_data.last_save_time
	}
	
	print("DEBUG: Saving world data with seed: ", world_data.world_seed)
	
	# Use INSERT OR REPLACE to handle existing data
	var query = """
		INSERT OR REPLACE INTO %s (id, world_seed, world_settings, chunks_data, blocks_data, world_events, last_save_time) 
		VALUES (%d, %d, '%s', '%s', '%s', '%s', %d)
	""" % [TABLE_NAME, 1, world_data.world_seed, world_settings_json, chunks_json, 
		blocks_json, world_events_json, world_data.last_save_time]
	
	var result = database.query(query)
	
	# Verify the data was actually inserted
	if result:
		var verify_query = "SELECT COUNT(*) FROM %s WHERE id = 1" % TABLE_NAME
		var verify_result = database.query(verify_query)
		print("DEBUG: World data verification - rows with id=1: ", verify_result)
		
		# Also try to immediately load the data to see if it's there
		var immediate_load = database.select_rows(TABLE_NAME, "SELECT * FROM %s WHERE id = 1" % TABLE_NAME, ["id", "world_seed", "world_settings", "chunks_data", "blocks_data", "world_events", "last_save_time"])
		print("DEBUG: Immediate load after save - result size: ", immediate_load.size() if immediate_load else 0)
		
		# WORKAROUND: Since select_rows is broken, create a backup file
		_create_backup_file()
	
	return result

func _create_backup_file() -> void:
	"""Create a backup file with world data since select_rows is broken"""
	var current_world_name = ""
	if SaveSystemIntegration:
		var sqlite_manager = SaveSystemIntegration.get_sqlite_save_manager()
		if sqlite_manager:
			current_world_name = sqlite_manager.current_world_name
	
	if current_world_name == "":
		print("DEBUG: No current world name available for backup")
		return
	
	# Create backup data
	var backup_data = {
		"world_seed": world_data.world_seed,
		"world_settings": world_data.world_settings,
		"chunks": world_data.chunks,
		"blocks": world_data.blocks,
		"world_events": world_data.world_events,
		"last_save_time": world_data.last_save_time,
		"backup_timestamp": Time.get_unix_time_from_system()
	}
	
	# Save to backup file
	var backup_file_path = "user://world_backup_%s.json" % current_world_name.replace(" ", "_")
	var json_string = JSON.stringify(backup_data)
	
	var file = FileAccess.open(backup_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("DEBUG: Created backup file: ", backup_file_path)
	else:
		print("DEBUG: Failed to create backup file: ", backup_file_path)

func load_world_data() -> bool:
	"""Load world data from database"""
	if not database:
		return false
	
	# WORKAROUND: Since select_rows is completely broken across all tables,
	# let's use a file-based backup system for critical data
	print("DEBUG: Using file-based backup system since select_rows is completely broken")
	
	# Try to load world data from a backup file
	var current_world_name = ""
	if SaveSystemIntegration:
		var sqlite_manager = SaveSystemIntegration.get_sqlite_save_manager()
		if sqlite_manager:
			current_world_name = sqlite_manager.current_world_name
	
	if current_world_name == "":
		print("DEBUG: No current world name available")
		return false
	
	# Try to load from backup file
	var backup_file_path = "user://world_backup_%s.json" % current_world_name.replace(" ", "_")
	print("DEBUG: Attempting to load world data from backup file: ", backup_file_path)
	
	if FileAccess.file_exists(backup_file_path):
		var file = FileAccess.open(backup_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var backup_data = json.data
				if backup_data.has("world_seed") and backup_data.world_seed != 0:
					var loaded_seed = backup_data.world_seed
					var last_save_time = backup_data.get("last_save_time", 0)
					
					print("DEBUG: Successfully loaded world seed from backup file: ", loaded_seed)
					print("DEBUG: Last save time: ", last_save_time)
					
					world_data = {
						"world_seed": loaded_seed,
						"world_settings": backup_data.get("world_settings", {}),
						"chunks": backup_data.get("chunks", {}),
						"blocks": backup_data.get("blocks", {}),
						"world_events": backup_data.get("world_events", []),
						"last_save_time": last_save_time
					}
					print("DEBUG: World data loaded successfully from backup with seed: ", loaded_seed)
					return true
				else:
					print("DEBUG: Backup file exists but has invalid seed")
			else:
				print("DEBUG: Failed to parse backup file JSON")
		else:
			print("DEBUG: Could not open backup file for reading")
	else:
		print("DEBUG: No backup file found")
	
	# If we can't get data from backup file, use defaults
	print("DEBUG: Could not load world data from backup file, using defaults")
	
	# If no data found, use defaults
	print("DEBUG: No world data found, using defaults")
	world_data = {
		"world_seed": 0,
		"world_settings": {},
		"chunks": {},
		"blocks": {},
		"world_events": [],
		"last_save_time": 0
	}
	return true

## World settings methods

func set_world_seed(world_seed: int) -> void:
	"""Set the world seed"""
	world_data.world_seed = world_seed

func get_world_seed() -> int:
	"""Get the world seed"""
	return world_data.world_seed

func set_world_setting(key: String, value) -> void:
	"""Set a world setting"""
	world_data.world_settings[key] = value

func get_world_setting(key: String, default_value = null):
	"""Get a world setting"""
	return world_data.world_settings.get(key, default_value)

func get_all_world_settings() -> Dictionary:
	"""Get all world settings"""
	return world_data.world_settings.duplicate()

## Chunk management methods

func save_chunk(chunk_x: int, chunk_y: int, chunk_data: Dictionary) -> bool:
	"""Save chunk data"""
	var chunk_key = "%d,%d" % [chunk_x, chunk_y]
	world_data.chunks[chunk_key] = chunk_data
	return true

func load_chunk(chunk_x: int, chunk_y: int) -> Dictionary:
	"""Load chunk data"""
	var chunk_key = "%d,%d" % [chunk_x, chunk_y]
	return world_data.chunks.get(chunk_key, {})

func has_chunk(chunk_x: int, chunk_y: int) -> bool:
	"""Check if chunk exists"""
	var chunk_key = "%d,%d" % [chunk_x, chunk_y]
	return world_data.chunks.has(chunk_key)

func remove_chunk(chunk_x: int, chunk_y: int) -> bool:
	"""Remove chunk data"""
	var chunk_key = "%d,%d" % [chunk_x, chunk_y]
	if world_data.chunks.has(chunk_key):
		world_data.chunks.erase(chunk_key)
		return true
	return false

func get_all_chunks() -> Dictionary:
	"""Get all chunk data"""
	return world_data.chunks.duplicate()

## Block management methods

func save_block(block_x: int, block_y: int, block_data: Dictionary) -> bool:
	"""Save individual block data"""
	var block_key = "%d,%d" % [block_x, block_y]
	world_data.blocks[block_key] = block_data
	return true

func load_block(block_x: int, block_y: int) -> Dictionary:
	"""Load individual block data"""
	var block_key = "%d,%d" % [block_x, block_y]
	return world_data.blocks.get(block_key, {})

func has_block(block_x: int, block_y: int) -> bool:
	"""Check if block data exists"""
	var block_key = "%d,%d" % [block_x, block_y]
	return world_data.blocks.has(block_key)

func remove_block(block_x: int, block_y: int) -> bool:
	"""Remove block data"""
	var block_key = "%d,%d" % [block_x, block_y]
	if world_data.blocks.has(block_key):
		world_data.blocks.erase(block_key)
		return true
	return false

func get_blocks_in_area(start_x: int, start_y: int, end_x: int, end_y: int) -> Dictionary:
	"""Get all blocks in a rectangular area"""
	var blocks = {}
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var block_key = "%d,%d" % [x, y]
			if world_data.blocks.has(block_key):
				blocks[block_key] = world_data.blocks[block_key]
	return blocks

func get_all_blocks() -> Dictionary:
	"""Get all block data"""
	return world_data.blocks.duplicate()

## World events methods

func add_world_event(event_type: String, event_data: Dictionary = {}) -> void:
	"""Add a world event"""
	var event = {
		"type": event_type,
		"data": event_data,
		"timestamp": Time.get_unix_time_from_system()
	}
	world_data.world_events.append(event)

func get_world_events(event_type: String = "") -> Array:
	"""Get world events, optionally filtered by type"""
	if event_type.is_empty():
		return world_data.world_events.duplicate()
	
	var filtered_events = []
	for event in world_data.world_events:
		if event.type == event_type:
			filtered_events.append(event)
	return filtered_events

func clear_world_events() -> void:
	"""Clear all world events"""
	world_data.world_events.clear()

func clear_world_events_by_type(event_type: String) -> int:
	"""Clear world events of a specific type, returns count of removed events"""
	var removed_count = 0
	var events_to_remove = []
	
	for i in range(world_data.world_events.size()):
		if world_data.world_events[i].type == event_type:
			events_to_remove.append(i)
	
	# Remove in reverse order to maintain indices
	events_to_remove.reverse()
	for index in events_to_remove:
		world_data.world_events.remove_at(index)
		removed_count += 1
	
	return removed_count

## Statistics methods

func get_chunk_count() -> int:
	"""Get total number of saved chunks"""
	return world_data.chunks.size()

func get_block_count() -> int:
	"""Get total number of saved blocks"""
	return world_data.blocks.size()

func get_world_event_count() -> int:
	"""Get total number of world events"""
	return world_data.world_events.size()

## Utility methods

func clear_all_chunks() -> void:
	"""Clear all chunk data"""
	world_data.chunks.clear()

func clear_all_blocks() -> void:
	"""Clear all block data"""
	world_data.blocks.clear()

func clear_all_world_data() -> void:
	"""Clear all world data except seed and settings"""
	world_data.chunks.clear()
	world_data.blocks.clear()
	world_data.world_events.clear()

func get_all_world_data() -> Dictionary:
	"""Get all world data"""
	return world_data.duplicate()

func set_all_world_data(data: Dictionary) -> void:
	"""Set all world data at once"""
	world_data = data.duplicate()

## Performance optimization methods

func optimize_storage() -> void:
	"""Optimize storage by removing unnecessary data"""
	# Remove empty chunks
	var chunks_to_remove = []
	for chunk_key in world_data.chunks:
		if world_data.chunks[chunk_key].is_empty():
			chunks_to_remove.append(chunk_key)
	
	for chunk_key in chunks_to_remove:
		world_data.chunks.erase(chunk_key)
	
	# Remove empty blocks
	var blocks_to_remove = []
	for block_key in world_data.blocks:
		if world_data.blocks[block_key].is_empty():
			blocks_to_remove.append(block_key)
	
	for block_key in blocks_to_remove:
		world_data.blocks.erase(block_key)
	
	# Limit world events to last 1000
	if world_data.world_events.size() > 1000:
		world_data.world_events = world_data.world_events.slice(-1000)

extends Node

## SQLite Save Manager - Central coordinator for all save operations
## Manages database connections and coordinates data saving/loading

signal save_completed(world_name: String, success: bool)
signal load_completed(world_name: String, success: bool)
signal world_created(world_name: String)
signal world_deleted(world_name: String)

# Database configuration
const DATABASE_VERSION = 1
const WORLDS_TABLE = "worlds"
const PLAYERS_TABLE = "players"
const INVENTORIES_TABLE = "inventories"
const ACHIEVEMENTS_TABLE = "achievements"
const ENTITIES_TABLE = "entities"
const WORLD_DATA_TABLE = "world_data"

# Database connection
var database: SQLite
var current_world_name: String = ""
var database_path: String = ""

# Data managers
var player_save_manager: PlayerSaveManager
var inventory_save_manager: InventorySaveManager
var achievement_save_manager: AchievementSaveManager
var entity_save_manager: EntitySaveManager
var world_data_save_manager: WorldDataSaveManager

func _ready() -> void:
	# Initialize SQLite
	database = SQLite.new()
	
	# Initialize data managers
	player_save_manager = PlayerSaveManager.new()
	inventory_save_manager = InventorySaveManager.new()
	achievement_save_manager = AchievementSaveManager.new()
	entity_save_manager = EntitySaveManager.new()
	world_data_save_manager = WorldDataSaveManager.new()
	
	# Set up managers with database reference
	_setup_managers()

func _setup_managers() -> void:
	"""Set up all save managers with database reference"""
	player_save_manager.set_database(database)
	inventory_save_manager.set_database(database)
	achievement_save_manager.set_database(database)
	entity_save_manager.set_database(database)
	world_data_save_manager.set_database(database)

## Create a new world save
func create_world(world_name: String, world_seed: int = 0) -> bool:
	"""Create a new world save with all necessary tables"""
	if world_name.is_empty():
		print("ERROR: World name cannot be empty")
		return false
	
	# Set up database path for this world
	database_path = "user://worlds/" + world_name + ".db"
	
	# Ensure worlds directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	
	# Open/create database
	if not _open_database():
		return false
	
	# Create tables
	if not _create_tables():
		return false
	
	# Initialize world record
	if not _initialize_world_record(world_name, world_seed):
		return false
	
	current_world_name = world_name
	world_created.emit(world_name)
	print("World created: ", world_name)
	return true

## Load an existing world
func load_world(world_name: String) -> bool:
	"""Load an existing world save"""
	if world_name.is_empty():
		print("ERROR: World name cannot be empty")
		return false
	
	# Set up database path
	database_path = "user://worlds/" + world_name + ".db"
	
	# Check if world exists
	if not FileAccess.file_exists(database_path):
		print("ERROR: World save not found: ", world_name)
		return false
	
	# Open database
	if not _open_database():
		return false
	
	# Verify database structure
	if not _verify_database_structure():
		return false
	
	current_world_name = world_name
	load_completed.emit(world_name, true)
	print("World loaded: ", world_name)
	return true

## Save current world
func save_world() -> bool:
	"""Save all data for the current world"""
	if current_world_name.is_empty():
		print("ERROR: No world loaded")
		return false
	
	if not database:
		print("ERROR: Database not initialized")
		return false
	
	var success = true
	
	# Save all data types with detailed logging
	print("DEBUG: Starting save process for world: ", current_world_name)
	
	print("DEBUG: Saving player data...")
	var player_success = player_save_manager.save_player_data()
	print("DEBUG: Player save result: ", player_success)
	success = success and player_success
	
	print("DEBUG: Saving inventory data...")
	var inventory_success = inventory_save_manager.save_inventory_data()
	print("DEBUG: Inventory save result: ", inventory_success)
	success = success and inventory_success
	
	print("DEBUG: Saving achievement data...")
	var achievement_success = achievement_save_manager.save_achievement_data()
	print("DEBUG: Achievement save result: ", achievement_success)
	success = success and achievement_success
	
	print("DEBUG: Saving entity data...")
	var entity_success = entity_save_manager.save_entity_data()
	print("DEBUG: Entity save result: ", entity_success)
	success = success and entity_success
	
	print("DEBUG: Saving world data...")
	var world_success = world_data_save_manager.save_world_data()
	print("DEBUG: World data save result: ", world_success)
	success = success and world_success
	
	# Update world metadata
	if success:
		print("DEBUG: Updating world metadata...")
		var metadata_success = _update_world_metadata()
		print("DEBUG: Metadata update result: ", metadata_success)
		success = success and metadata_success
	
	save_completed.emit(current_world_name, success)
	
	if success:
		print("World saved successfully: ", current_world_name)
	else:
		print("ERROR: Failed to save world: ", current_world_name)
	
	return success

## Load all data for current world
func load_world_data() -> bool:
	"""Load all data for the current world"""
	if current_world_name.is_empty():
		print("ERROR: No world loaded")
		return false
	
	var success = true
	
	# Load all data types
	success = success and player_save_manager.load_player_data()
	success = success and inventory_save_manager.load_inventory_data()
	success = success and achievement_save_manager.load_achievement_data()
	success = success and entity_save_manager.load_entity_data()
	success = success and world_data_save_manager.load_world_data()
	
	return success

## Get list of available worlds
func get_available_worlds() -> Array:
	"""Get list of all available world saves"""
	var worlds = []
	var dir = DirAccess.open("user://worlds")
	
	if not dir:
		print("No worlds directory found")
		return worlds
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".db") and not file_name.begins_with("."):
			var world_name = file_name.get_basename()
			# Get actual world info from the database
			var world_info = _get_world_metadata(world_name)
			if world_info:
				worlds.append(world_info)
				print("Found world: ", world_name, " (seed: ", world_info.world_seed, ", last save: ", world_info.last_save_time, ")")
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Total worlds found: ", worlds.size())
	return worlds

## Get world metadata without loading the full world
func _get_world_metadata(world_name: String) -> Dictionary:
	"""Get basic world metadata from the database using select_rows"""
	var temp_db = SQLite.new()
	var world_path = "user://worlds/" + world_name + ".db"
	
	temp_db.path = world_path
	var open_result = temp_db.open_db()
	if not open_result:
		print("ERROR: Failed to open database for metadata: ", world_path)
		return {}
	
	# Use select_rows with proper parameters (like inventory and entity managers do)
	var result = temp_db.select_rows("worlds", "name = '%s'" % world_name, ["name", "seed", "created_time", "last_save_time", "game_time"])
	temp_db.close_db()
	
	if result and result.size() > 0:
		var row = result[0]
		var seed_value = row.get("seed", 0)
		var last_save = row.get("last_save_time", 0)
		print("DEBUG: Found world metadata - seed: ", seed_value, ", last_save: ", last_save)
		return {
			"name": row.get("name", world_name),
			"last_save_time": last_save,
			"game_time": row.get("game_time", 0),
			"world_seed": seed_value
		}
	
	# Fallback if no data found
	print("DEBUG: No world metadata found, using fallback")
	return {
		"name": world_name,
		"last_save_time": 0,
		"game_time": 0,
		"world_seed": 0
	}

## Delete a world
func delete_world(world_name: String) -> bool:
	"""Delete a world save"""
	if world_name.is_empty():
		return false
	
	var world_path = "user://worlds/" + world_name + ".db"
	
	if FileAccess.file_exists(world_path):
		var dir = DirAccess.open("user://worlds")
		if dir.remove(world_name + ".db") == OK:
			world_deleted.emit(world_name)
			print("World deleted: ", world_name)
			return true
	
	return false

## Close current database
func close_database() -> void:
	"""Close the current database connection"""
	if database:
		database.close_db()
		current_world_name = ""

# Private helper methods

func _open_database() -> bool:
	"""Open the database connection"""
	# Create a new database instance
	var new_db = SQLite.new()
	new_db.path = database_path
	
	# Open the database - this will create it if it doesn't exist
	var result = new_db.open_db()
	if not result:
		print("ERROR: Failed to open database: ", database_path)
		return false
	
	# Replace the database instance
	database = new_db
	
	# Update all managers with the new database reference
	_setup_managers()
	
	return true

func _create_tables() -> bool:
	"""Create all necessary tables"""
	print("DEBUG: Creating all database tables...")
	var success = true
	
	# Create worlds table
	print("DEBUG: Creating worlds table...")
	var worlds_table_success = _create_worlds_table()
	print("DEBUG: Worlds table creation result: ", worlds_table_success)
	success = success and worlds_table_success
	
	# Create data tables
	print("DEBUG: Creating player table...")
	var player_table_success = player_save_manager.create_table()
	print("DEBUG: Player table creation result: ", player_table_success)
	success = success and player_table_success
	
	print("DEBUG: Creating inventory table...")
	var inventory_table_success = inventory_save_manager.create_table()
	print("DEBUG: Inventory table creation result: ", inventory_table_success)
	success = success and inventory_table_success
	
	print("DEBUG: Creating achievement table...")
	var achievement_table_success = achievement_save_manager.create_table()
	print("DEBUG: Achievement table creation result: ", achievement_table_success)
	success = success and achievement_table_success
	
	print("DEBUG: Creating entity table...")
	var entity_table_success = entity_save_manager.create_table()
	print("DEBUG: Entity table creation result: ", entity_table_success)
	success = success and entity_table_success
	
	print("DEBUG: Creating world_data table...")
	var world_data_table_success = world_data_save_manager.create_table()
	print("DEBUG: World_data table creation result: ", world_data_table_success)
	success = success and world_data_table_success
	
	print("DEBUG: All tables creation result: ", success)
	return success

func _create_worlds_table() -> bool:
	"""Create the worlds metadata table"""
	print("DEBUG: Creating worlds table: ", WORLDS_TABLE)
	
	var query = """
		CREATE TABLE IF NOT EXISTS %s (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT UNIQUE NOT NULL,
			seed INTEGER NOT NULL,
			created_time INTEGER NOT NULL,
			last_save_time INTEGER NOT NULL,
			game_time INTEGER DEFAULT 0,
			version INTEGER DEFAULT %d
		)
	""" % [WORLDS_TABLE, DATABASE_VERSION]
	
	print("DEBUG: Worlds table query: ", query)
	var result = database.query(query)
	print("DEBUG: Worlds table creation result: ", result)
	return result

func _initialize_world_record(world_name: String, world_seed: int) -> bool:
	"""Initialize the world record in the worlds table"""
	var current_time = Time.get_unix_time_from_system()
	
	var query = """
		INSERT OR REPLACE INTO %s (name, seed, created_time, last_save_time, game_time, version) 
		VALUES ('%s', %d, %d, %d, %d, %d)
	""" % [WORLDS_TABLE, world_name, world_seed, current_time, current_time, 0, DATABASE_VERSION]
	
	var result = database.query(query)
	return result

func _update_world_metadata() -> bool:
	"""Update the world metadata with current save time"""
	var current_time = Time.get_unix_time_from_system()
	
	# First get current game_time using raw SQL
	var current_query = "SELECT game_time FROM %s WHERE name = '%s'" % [WORLDS_TABLE, current_world_name]
	var current_result = database.query(current_query)
	var current_game_time = 0
	
	if current_result:
		# For now, assume no data and use default
		current_game_time = 0
	
	# Get the current world seed from the world_data table
	var world_seed = 0
	if world_data_save_manager:
		world_seed = world_data_save_manager.get_world_seed()
		print("DEBUG: Updating world metadata with seed: ", world_seed)
	else:
		print("DEBUG: No world_data_save_manager available for metadata update")
	
	# Update with new values including the world seed
	var query = """
		UPDATE %s 
		SET last_save_time = %d, game_time = %d, seed = %d
		WHERE name = '%s'
	""" % [WORLDS_TABLE, current_time, current_game_time + 1, world_seed, current_world_name]
	
	print("DEBUG: Executing metadata update query: ", query)
	var result = database.query(query)
	print("DEBUG: Metadata update result: ", result)
	
	# Metadata is now stored directly in the database, no need for separate files
	
	return result


func _get_world_info(world_name: String) -> Dictionary:
	"""Get information about a specific world"""
	var temp_db = SQLite.new()
	var world_path = "user://worlds/" + world_name + ".db"
	
	temp_db.path = world_path
	var open_result = temp_db.open_db()
	if not open_result:
		print("ERROR: Failed to open database: ", world_path)
		return {}
	
	# Use raw SQL query instead of select_rows
	var query = "SELECT * FROM %s WHERE name = '%s'" % [WORLDS_TABLE, world_name]
	var query_result = temp_db.query(query)
	
	if query_result:
		# For now, return empty data since we can't access the result
		temp_db.close_db()
		return {}
	
	temp_db.close_db()
	return {}

func _verify_database_structure() -> bool:
	"""Verify that the database has the correct structure"""
	print("DEBUG: Verifying database structure...")
	
	# Check if worlds table exists using raw SQL
	var query = "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'" % WORLDS_TABLE
	var result = database.query(query)
	print("DEBUG: Worlds table exists check: ", result)
	
	# If worlds table doesn't exist, create all tables
	if not result:
		print("DEBUG: Worlds table doesn't exist, creating all tables...")
		return _create_tables()
	
	# Even if worlds table exists, make sure all data tables exist
	print("DEBUG: Worlds table exists, ensuring all data tables exist...")
	return _create_tables()

## Get current world name
func get_current_world_name() -> String:
	return current_world_name

## Check if a world is currently loaded
func is_world_loaded() -> bool:
	return not current_world_name.is_empty() and database != null

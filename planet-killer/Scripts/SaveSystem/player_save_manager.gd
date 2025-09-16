extends RefCounted
class_name PlayerSaveManager

## Player Save Manager - Handles saving and loading player data
## Manages player position, health, stats, and other player-specific information

# Database reference
var database: SQLite

# Table configuration
const TABLE_NAME = "players"
const PLAYER_ID = 1  # Single player game, so we use ID 1

# Player data structure
var player_data: Dictionary = {
	"position_x": 0.0,
	"position_y": 0.0,
	"health": 100,
	"max_health": 100,
	"stamina": 100,
	"max_stamina": 100,
	"experience": 0,
	"level": 1,
	"skill_points": 0,
	"last_save_time": 0
}

func set_database(db: SQLite) -> void:
	"""Set the database reference"""
	database = db

func create_table() -> bool:
	"""Create the players table"""
	if not database:
		return false
	
	var query = """
		CREATE TABLE IF NOT EXISTS %s (
			id INTEGER PRIMARY KEY,
			position_x REAL NOT NULL DEFAULT 0.0,
			position_y REAL NOT NULL DEFAULT 0.0,
			health INTEGER NOT NULL DEFAULT 100,
			max_health INTEGER NOT NULL DEFAULT 100,
			stamina INTEGER NOT NULL DEFAULT 100,
			max_stamina INTEGER NOT NULL DEFAULT 100,
			experience INTEGER NOT NULL DEFAULT 0,
			level INTEGER NOT NULL DEFAULT 1,
			skill_points INTEGER NOT NULL DEFAULT 0,
			last_save_time INTEGER NOT NULL DEFAULT 0
		)
	""" % [TABLE_NAME]
	
	return database.query(query)

func save_player_data() -> bool:
	"""Save current player data to database"""
	if not database:
		print("ERROR: Database not initialized in player save manager")
		return false
	
	# Update save time
	player_data.last_save_time = Time.get_unix_time_from_system()
	
	# Use insert_row instead of raw SQL
	var row_data = {
		"id": PLAYER_ID,
		"position_x": player_data.position_x,
		"position_y": player_data.position_y,
		"health": player_data.health,
		"max_health": player_data.max_health,
		"stamina": player_data.stamina,
		"max_stamina": player_data.max_stamina,
		"experience": player_data.experience,
		"level": player_data.level,
		"skill_points": player_data.skill_points,
		"last_save_time": player_data.last_save_time
	}
	
	print("DEBUG: Player data to save: ", row_data)
	
	# Use INSERT OR REPLACE to handle existing data
	var query = """
		INSERT OR REPLACE INTO %s (id, position_x, position_y, health, max_health, stamina, max_stamina, experience, level, skill_points, last_save_time) 
		VALUES (%d, %f, %f, %d, %d, %d, %d, %d, %d, %d, %d)
	""" % [TABLE_NAME, PLAYER_ID, player_data.position_x, player_data.position_y, 
		player_data.health, player_data.max_health, player_data.stamina, 
		player_data.max_stamina, player_data.experience, player_data.level, 
		player_data.skill_points, player_data.last_save_time]
	
	print("DEBUG: Player save query: ", query)
	var result = database.query(query)
	print("DEBUG: Player save result: ", result)
	
	# No longer using backup files, data is stored directly in database
	
	return result


func load_player_data() -> bool:
	"""Load player data from database using select_rows"""
	if not database:
		print("ERROR: Database not initialized")
		return false
	
	# Use select_rows like inventory and entity managers do
	var result = database.select_rows(TABLE_NAME, "id = %d" % PLAYER_ID, ["id", "position_x", "position_y", "health", "max_health", "stamina", "max_stamina", "experience", "level", "skill_points", "last_save_time"])
	print("DEBUG: Player load query result: ", result)
	
	if result and result.size() > 0:
		print("DEBUG: Player load query successful")
		var row = result[0]  # Get the first (and should be only) row
		
		# Parse the loaded data
		player_data = {
			"position_x": row.get("position_x", 0.0),
			"position_y": row.get("position_y", 0.0),
			"health": row.get("health", 100),
			"max_health": row.get("max_health", 100),
			"stamina": row.get("stamina", 100),
			"max_stamina": row.get("max_stamina", 100),
			"experience": row.get("experience", 0),
			"level": row.get("level", 1),
			"skill_points": row.get("skill_points", 0),
			"last_save_time": row.get("last_save_time", 0)
		}
		print("DEBUG: Loaded player data: ", player_data)
		return true
	
	# If no data found, use defaults
	print("DEBUG: No player data found, using defaults")
	player_data = {
		"position_x": 0.0,
		"position_y": 0.0,
		"health": 100,
		"max_health": 100,
		"stamina": 100,
		"max_stamina": 100,
		"experience": 0,
		"level": 1,
		"skill_points": 0,
		"last_save_time": 0
	}
	return true

## Data access methods

func set_player_position(position: Vector2) -> void:
	"""Set player position"""
	player_data.position_x = position.x
	player_data.position_y = position.y

func get_player_position() -> Vector2:
	"""Get player position"""
	return Vector2(player_data.position_x, player_data.position_y)

func set_player_health(health: int, max_health: int = -1) -> void:
	"""Set player health"""
	player_data.health = health
	if max_health >= 0:
		player_data.max_health = max_health

func get_player_health() -> Dictionary:
	"""Get player health data"""
	return {
		"health": player_data.health,
		"max_health": player_data.max_health
	}

func set_player_stamina(stamina: int, max_stamina: int = -1) -> void:
	"""Set player stamina"""
	player_data.stamina = stamina
	if max_stamina >= 0:
		player_data.max_stamina = max_stamina

func get_player_stamina() -> Dictionary:
	"""Get player stamina data"""
	return {
		"stamina": player_data.stamina,
		"max_stamina": player_data.max_stamina
	}

func set_player_experience(experience: int) -> void:
	"""Set player experience"""
	player_data.experience = experience

func get_player_experience() -> int:
	"""Get player experience"""
	return player_data.experience

func set_player_level(level: int) -> void:
	"""Set player level"""
	player_data.level = level

func get_player_level() -> int:
	"""Get player level"""
	return player_data.level

func set_player_skill_points(skill_points: int) -> void:
	"""Set player skill points"""
	player_data.skill_points = skill_points

func get_player_skill_points() -> int:
	"""Get player skill points"""
	return player_data.skill_points

func get_all_player_data() -> Dictionary:
	"""Get all player data"""
	return player_data.duplicate()

func set_all_player_data(data: Dictionary) -> void:
	"""Set all player data at once"""
	player_data = data.duplicate()

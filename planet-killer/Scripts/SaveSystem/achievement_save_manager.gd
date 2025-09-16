extends RefCounted
class_name AchievementSaveManager

## Achievement Save Manager - Handles saving and loading achievement data
## Manages achievement unlock status, progress, and completion timestamps

# Database reference
var database: SQLite

# Table configuration
const TABLE_NAME = "achievements"

# Achievement data structure
var achievement_data: Dictionary = {
	"achievements": {},  # achievement_id -> achievement_data
	"total_unlocked": 0,
	"total_achievements": 0,
	"last_save_time": 0
}

func set_database(db: SQLite) -> void:
	"""Set the database reference"""
	database = db

func create_table() -> bool:
	"""Create the achievements table"""
	if not database:
		print("ERROR: Database not initialized in achievement save manager")
		return false
	
	print("DEBUG: Creating achievement table: ", TABLE_NAME)
	
	var query = """
		CREATE TABLE IF NOT EXISTS %s (
			id INTEGER PRIMARY KEY,
			world_name TEXT NOT NULL,
			achievements_data TEXT NOT NULL DEFAULT '{}',
			total_unlocked INTEGER NOT NULL DEFAULT 0,
			total_achievements INTEGER NOT NULL DEFAULT 0,
			last_save_time INTEGER NOT NULL DEFAULT 0
		)
	""" % [TABLE_NAME]
	
	print("DEBUG: Achievement table query: ", query)
	var result = database.query(query)
	print("DEBUG: Achievement table creation result: ", result)
	
	# Try to verify the table was created
	if result:
		var verify_query = "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'" % TABLE_NAME
		var verify_result = database.query(verify_query)
		if verify_result:
			print("DEBUG: Achievement table verification successful")
	
	return result

func save_achievement_data() -> bool:
	"""Save current achievement data to database using raw SQL"""
	if not database:
		print("ERROR: Database not initialized in achievement save manager")
		return false
	
	# Update save time
	achievement_data.last_save_time = Time.get_unix_time_from_system()
	
	# Convert data to JSON string
	var achievements_json = JSON.stringify(achievement_data.achievements)
	
	# Get current world name for per-world achievements
	var world_name = ""
	if SaveSystemIntegration:
		var sqlite_manager = SaveSystemIntegration.get_sqlite_save_manager()
		if sqlite_manager:
			world_name = sqlite_manager.current_world_name
	
	if world_name.is_empty():
		print("ERROR: No world name available for achievement save")
		return false
	
	# Use raw SQL with world-specific ID (hash of world name)
	var world_id = world_name.hash()
	
	# First, try to delete any existing record for this world
	var delete_query = "DELETE FROM %s WHERE world_name = '%s'" % [TABLE_NAME, world_name]
	print("DEBUG: Deleting existing achievement data for world: ", world_name)
	database.query(delete_query)
	
	# Then insert new data
	var query = """
		INSERT INTO %s (id, world_name, achievements_data, total_unlocked, total_achievements, last_save_time) 
		VALUES (%d, '%s', '%s', %d, %d, %d)
	""" % [TABLE_NAME, world_id, world_name, achievements_json, achievement_data.total_unlocked, 
		achievement_data.total_achievements, achievement_data.last_save_time]
	
	print("DEBUG: Achievement save query for world: ", world_name)
	var result = database.query(query)
	print("DEBUG: Achievement save result: ", result)
	return result

func load_achievement_data() -> bool:
	"""Load achievement data from database using select_rows for current world"""
	if not database:
		return false
	
	# Get current world name for per-world achievements
	var world_name = ""
	if SaveSystemIntegration:
		var sqlite_manager = SaveSystemIntegration.get_sqlite_save_manager()
		if sqlite_manager:
			world_name = sqlite_manager.current_world_name
	
	if world_name.is_empty():
		print("ERROR: No world name available for achievement load")
		# Use defaults for new world
		achievement_data = {
			"achievements": {},
			"total_unlocked": 0,
			"total_achievements": 0,
			"last_save_time": 0
		}
		return true
	
	# Use select_rows for current world - just use world_name for simplicity
	var result = database.select_rows(TABLE_NAME, "world_name = '%s'" % world_name, ["id", "world_name", "achievements_data", "total_unlocked", "total_achievements", "last_save_time"])
	print("DEBUG: Achievement load query for world: ", world_name)
	print("DEBUG: Query condition: world_name = '%s'" % world_name)
	
	if result and result.size() > 0:
		print("DEBUG: Achievement load query successful for world: ", world_name)
		var row = result[0]
		
		# Parse the loaded data
		var achievements_json = row.get("achievements_data", "{}")
		print("DEBUG: Raw achievements JSON: ", achievements_json)
		var achievements_parse = JSON.parse_string(achievements_json)
		
		achievement_data = {
			"achievements": achievements_parse if achievements_parse else {},
			"total_unlocked": row.get("total_unlocked", 0),
			"total_achievements": row.get("total_achievements", 0),
			"last_save_time": row.get("last_save_time", 0)
		}
		print("DEBUG: Loaded achievement data for world: ", world_name)
		print("DEBUG: Parsed achievements: ", achievement_data.achievements)
		print("DEBUG: Total unlocked: ", achievement_data.total_unlocked)
		return true
	
	# If no data found, use defaults (achievements reset per world)
	print("DEBUG: No achievement data found for world, using defaults: ", world_name)
	achievement_data = {
		"achievements": {},
		"total_unlocked": 0,
		"total_achievements": 0,
		"last_save_time": 0
	}
	return true

## Achievement management methods

func unlock_achievement(achievement_id: String, unlock_time: int = -1) -> bool:
	"""Unlock an achievement"""
	if unlock_time == -1:
		unlock_time = int(Time.get_unix_time_from_system())
	
	if not achievement_data.achievements.has(achievement_id):
		achievement_data.achievements[achievement_id] = {
			"unlocked": true,
			"unlock_time": unlock_time,
			"progress": 1.0,
			"max_progress": 1.0
		}
		achievement_data.total_unlocked += 1
		return true
	elif not achievement_data.achievements[achievement_id].unlocked:
		achievement_data.achievements[achievement_id].unlocked = true
		achievement_data.achievements[achievement_id].unlock_time = unlock_time
		achievement_data.achievements[achievement_id].progress = 1.0
		achievement_data.total_unlocked += 1
		return true
	
	return false

func is_achievement_unlocked(achievement_id: String) -> bool:
	"""Check if an achievement is unlocked"""
	if not achievement_data.achievements.has(achievement_id):
		return false
	return achievement_data.achievements[achievement_id].unlocked

func get_achievement_unlock_time(achievement_id: String) -> int:
	"""Get the unlock time of an achievement"""
	if not achievement_data.achievements.has(achievement_id):
		return 0
	return achievement_data.achievements[achievement_id].get("unlock_time", 0)

func set_achievement_progress(achievement_id: String, progress: float, max_progress: float = 1.0) -> void:
	"""Set progress for an achievement (for incremental achievements)"""
	if not achievement_data.achievements.has(achievement_id):
		achievement_data.achievements[achievement_id] = {
			"unlocked": false,
			"unlock_time": 0,
			"progress": progress,
			"max_progress": max_progress
		}
	else:
		achievement_data.achievements[achievement_id].progress = progress
		achievement_data.achievements[achievement_id].max_progress = max_progress
	
	# Check if achievement should be unlocked
	if progress >= max_progress and not achievement_data.achievements[achievement_id].unlocked:
		unlock_achievement(achievement_id)

func get_achievement_progress(achievement_id: String) -> Dictionary:
	"""Get progress for an achievement"""
	if not achievement_data.achievements.has(achievement_id):
		return {"progress": 0.0, "max_progress": 1.0, "percentage": 0.0}
	
	var achievement = achievement_data.achievements[achievement_id]
	var percentage = (achievement.progress / achievement.max_progress) * 100.0
	
	return {
		"progress": achievement.progress,
		"max_progress": achievement.max_progress,
		"percentage": percentage
	}

func add_achievement_progress(achievement_id: String, progress_increment: float) -> bool:
	"""Add progress to an achievement"""
	if not achievement_data.achievements.has(achievement_id):
		set_achievement_progress(achievement_id, progress_increment)
		return true
	
	var achievement = achievement_data.achievements[achievement_id]
	var new_progress = achievement.progress + progress_increment
	
	set_achievement_progress(achievement_id, new_progress, achievement.max_progress)
	return true

## Statistics methods

func get_total_achievements() -> int:
	"""Get total number of achievements"""
	return achievement_data.total_achievements

func set_total_achievements(total: int) -> void:
	"""Set total number of achievements"""
	achievement_data.total_achievements = total

func get_unlocked_achievements() -> int:
	"""Get number of unlocked achievements"""
	return achievement_data.total_unlocked

func get_achievement_percentage() -> float:
	"""Get percentage of achievements unlocked"""
	if achievement_data.total_achievements == 0:
		return 0.0
	return (float(achievement_data.total_unlocked) / float(achievement_data.total_achievements)) * 100.0

## Data access methods

func get_achievement_data(achievement_id: String) -> Dictionary:
	"""Get complete data for a specific achievement"""
	if not achievement_data.achievements.has(achievement_id):
		return {}
	return achievement_data.achievements[achievement_id].duplicate()

func get_all_achievements() -> Dictionary:
	"""Get all achievement data"""
	return achievement_data.achievements.duplicate()

func get_unlocked_achievement_ids() -> Array:
	"""Get list of unlocked achievement IDs"""
	var unlocked = []
	for achievement_id in achievement_data.achievements:
		if achievement_data.achievements[achievement_id].unlocked:
			unlocked.append(achievement_id)
	return unlocked

func get_locked_achievement_ids() -> Array:
	"""Get list of locked achievement IDs"""
	var locked = []
	for achievement_id in achievement_data.achievements:
		if not achievement_data.achievements[achievement_id].unlocked:
			locked.append(achievement_id)
	return locked

## Utility methods

func clear_achievements() -> void:
	"""Clear all achievement data"""
	achievement_data.achievements.clear()
	achievement_data.total_unlocked = 0

func reset_achievement(achievement_id: String) -> bool:
	"""Reset a specific achievement to locked state"""
	if not achievement_data.achievements.has(achievement_id):
		return false
	
	if achievement_data.achievements[achievement_id].unlocked:
		achievement_data.total_unlocked -= 1
	
	achievement_data.achievements[achievement_id] = {
		"unlocked": false,
		"unlock_time": 0,
		"progress": 0.0,
		"max_progress": 1.0
	}
	
	return true

func get_all_achievement_data() -> Dictionary:
	"""Get all achievement data"""
	return achievement_data.duplicate()

func set_all_achievement_data(data: Dictionary) -> void:
	"""Set all achievement data at once"""
	achievement_data = data.duplicate()

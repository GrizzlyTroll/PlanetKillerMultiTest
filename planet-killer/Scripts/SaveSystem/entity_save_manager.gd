extends RefCounted
class_name EntitySaveManager

## Entity Save Manager - Handles saving and loading entity data
## Manages NPCs, enemies, and other world entities

# Database reference
var database: SQLite

# Table configuration
const TABLE_NAME = "entities"

# Entity data structure
var entity_data: Dictionary = {
	"entities": {},  # entity_id -> entity_data
	"total_entities": 0,
	"last_save_time": 0
}

func set_database(db: SQLite) -> void:
	"""Set the database reference"""
	database = db

func create_table() -> bool:
	"""Create the entities table"""
	if not database:
		print("ERROR: Database not initialized in entity save manager")
		return false
	
	print("DEBUG: Creating entity table: ", TABLE_NAME)
	
	var query = """
		CREATE TABLE IF NOT EXISTS %s (
			id INTEGER PRIMARY KEY,
			entities_data TEXT NOT NULL DEFAULT '{}',
			total_entities INTEGER NOT NULL DEFAULT 0,
			last_save_time INTEGER NOT NULL DEFAULT 0
		)
	""" % [TABLE_NAME]
	
	print("DEBUG: Entity table query: ", query)
	var result = database.query(query)
	print("DEBUG: Entity table creation result: ", result)
	
	# Try to verify the table was created
	if result:
		var verify_query = "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'" % TABLE_NAME
		var verify_result = database.query(verify_query)
		if verify_result:
			print("DEBUG: Entity table verification successful")
	
	return result

func save_entity_data() -> bool:
	"""Save current entity data to database"""
	if not database:
		print("ERROR: Database not initialized in entity save manager")
		return false
	
	# Update save time
	entity_data.last_save_time = Time.get_unix_time_from_system()
	
	# Convert data to JSON string
	var entities_json = JSON.stringify(entity_data.entities)
	
	# Use insert_row instead of raw SQL
	var row_data = {
		"id": 1,
		"entities_data": entities_json,
		"total_entities": entity_data.total_entities,
		"last_save_time": entity_data.last_save_time
	}
	
	print("DEBUG: Entity data to save: ", row_data)
	
	# Use INSERT OR REPLACE to handle existing data
	var query = """
		INSERT OR REPLACE INTO %s (id, entities_data, total_entities, last_save_time) 
		VALUES (%d, '%s', %d, %d)
	""" % [TABLE_NAME, 1, entities_json, entity_data.total_entities, entity_data.last_save_time]
	
	print("DEBUG: Entity save query: ", query)
	var result = database.query(query)
	print("DEBUG: Entity save result: ", result)
	return result

func load_entity_data() -> bool:
	"""Load entity data from database"""
	if not database:
		return false
	
	# Use select_rows instead of raw SQL query
	var query = "SELECT * FROM %s WHERE id = %d" % [TABLE_NAME, 1]  # Single player game, so we use ID 1
	var result = database.select_rows(TABLE_NAME, query, ["id", "entities_data", "total_entities", "last_save_time"])
	
	if result and result.size() > 0:
		var row = result[0]  # Get the first (and should be only) row
		
		# Parse the loaded data
		var entities_json = row.get("entities_data", "{}")
		var entities_parse = JSON.parse_string(entities_json)
		
		entity_data = {
			"entities": entities_parse if entities_parse else {},
			"total_entities": row.get("total_entities", 0),
			"last_save_time": row.get("last_save_time", 0)
		}
		return true
	
	# If no data found, use defaults
	entity_data = {
		"entities": {},
		"total_entities": 0,
		"last_save_time": 0
	}
	return true

## Entity management methods

func add_entity(entity_id: String, entity_type: String, position: Vector2, data: Dictionary = {}) -> bool:
	"""Add an entity to the world"""
	if entity_data.entities.has(entity_id):
		return false  # Entity already exists
	
	var entity_info = {
		"type": entity_type,
		"position_x": position.x,
		"position_y": position.y,
		"health": data.get("health", 100),
		"max_health": data.get("max_health", 100),
		"alive": data.get("alive", true),
		"spawn_time": Time.get_unix_time_from_system(),
		"last_update_time": Time.get_unix_time_from_system(),
		"custom_data": data.get("custom_data", {})
	}
	
	entity_data.entities[entity_id] = entity_info
	entity_data.total_entities += 1
	
	return true

func remove_entity(entity_id: String) -> bool:
	"""Remove an entity from the world"""
	if not entity_data.entities.has(entity_id):
		return false
	
	entity_data.entities.erase(entity_id)
	entity_data.total_entities -= 1
	
	return true

func update_entity_position(entity_id: String, position: Vector2) -> bool:
	"""Update entity position"""
	if not entity_data.entities.has(entity_id):
		return false
	
	entity_data.entities[entity_id].position_x = position.x
	entity_data.entities[entity_id].position_y = position.y
	entity_data.entities[entity_id].last_update_time = Time.get_unix_time_from_system()
	
	return true

func update_entity_health(entity_id: String, health: int, max_health: int = -1) -> bool:
	"""Update entity health"""
	if not entity_data.entities.has(entity_id):
		return false
	
	entity_data.entities[entity_id].health = health
	if max_health >= 0:
		entity_data.entities[entity_id].max_health = max_health
	
	entity_data.entities[entity_id].last_update_time = Time.get_unix_time_from_system()
	
	# Check if entity died
	if health <= 0:
		entity_data.entities[entity_id].alive = false
	
	return true

func set_entity_alive(entity_id: String, alive: bool) -> bool:
	"""Set entity alive status"""
	if not entity_data.entities.has(entity_id):
		return false
	
	entity_data.entities[entity_id].alive = alive
	entity_data.entities[entity_id].last_update_time = Time.get_unix_time_from_system()
	
	return true

func update_entity_custom_data(entity_id: String, custom_data: Dictionary) -> bool:
	"""Update entity custom data"""
	if not entity_data.entities.has(entity_id):
		return false
	
	entity_data.entities[entity_id].custom_data = custom_data
	entity_data.entities[entity_id].last_update_time = Time.get_unix_time_from_system()
	
	return true

## Data access methods

func get_entity_data(entity_id: String) -> Dictionary:
	"""Get complete data for a specific entity"""
	if not entity_data.entities.has(entity_id):
		return {}
	return entity_data.entities[entity_id].duplicate()

func get_entity_position(entity_id: String) -> Vector2:
	"""Get entity position"""
	if not entity_data.entities.has(entity_id):
		return Vector2.ZERO
	
	var entity = entity_data.entities[entity_id]
	return Vector2(entity.position_x, entity.position_y)

func get_entity_health(entity_id: String) -> Dictionary:
	"""Get entity health data"""
	if not entity_data.entities.has(entity_id):
		return {"health": 0, "max_health": 0}
	
	var entity = entity_data.entities[entity_id]
	return {
		"health": entity.health,
		"max_health": entity.max_health
	}
	
func get_entity_type(entity_id: String) -> String:
	"""Get entity type"""
	if not entity_data.entities.has(entity_id):
		return ""
	return entity_data.entities[entity_id].type

func is_entity_alive(entity_id: String) -> bool:
	"""Check if entity is alive"""
	if not entity_data.entities.has(entity_id):
		return false
	return entity_data.entities[entity_id].alive

func get_entity_custom_data(entity_id: String) -> Dictionary:
	"""Get entity custom data"""
	if not entity_data.entities.has(entity_id):
		return {}
	return entity_data.entities[entity_id].get("custom_data", {})

## Query methods

func get_entities_by_type(entity_type: String) -> Array:
	"""Get all entities of a specific type"""
	var entities = []
	for entity_id in entity_data.entities:
		if entity_data.entities[entity_id].type == entity_type:
			entities.append(entity_id)
	return entities

func get_alive_entities() -> Array:
	"""Get all alive entities"""
	var entities = []
	for entity_id in entity_data.entities:
		if entity_data.entities[entity_id].alive:
			entities.append(entity_id)
	return entities

func get_dead_entities() -> Array:
	"""Get all dead entities"""
	var entities = []
	for entity_id in entity_data.entities:
		if not entity_data.entities[entity_id].alive:
			entities.append(entity_id)
	return entities

func get_entities_in_area(center: Vector2, radius: float) -> Array:
	"""Get all entities within a certain radius of a point"""
	var entities = []
	for entity_id in entity_data.entities:
		var entity_pos = Vector2(
			entity_data.entities[entity_id].position_x,
			entity_data.entities[entity_id].position_y
		)
		if entity_pos.distance_to(center) <= radius:
			entities.append(entity_id)
	return entities

## Statistics methods

func get_total_entities() -> int:
	"""Get total number of entities"""
	return entity_data.total_entities

func get_entity_count_by_type(entity_type: String) -> int:
	"""Get count of entities of a specific type"""
	var count = 0
	for entity_id in entity_data.entities:
		if entity_data.entities[entity_id].type == entity_type:
			count += 1
	return count

func get_alive_entity_count() -> int:
	"""Get count of alive entities"""
	var count = 0
	for entity_id in entity_data.entities:
		if entity_data.entities[entity_id].alive:
			count += 1
	return count

## Utility methods

func clear_all_entities() -> void:
	"""Clear all entity data"""
	entity_data.entities.clear()
	entity_data.total_entities = 0

func clear_entities_by_type(entity_type: String) -> int:
	"""Clear all entities of a specific type, returns count of removed entities"""
	var removed_count = 0
	var entities_to_remove = []
	
	for entity_id in entity_data.entities:
		if entity_data.entities[entity_id].type == entity_type:
			entities_to_remove.append(entity_id)
	
	for entity_id in entities_to_remove:
		entity_data.entities.erase(entity_id)
		removed_count += 1
	
	entity_data.total_entities -= removed_count
	return removed_count

func get_all_entity_data() -> Dictionary:
	"""Get all entity data"""
	return entity_data.duplicate()

func set_all_entity_data(data: Dictionary) -> void:
	"""Set all entity data at once"""
	entity_data = data.duplicate()

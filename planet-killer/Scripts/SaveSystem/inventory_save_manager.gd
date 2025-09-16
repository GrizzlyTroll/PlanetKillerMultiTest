extends RefCounted
class_name InventorySaveManager

## Inventory Save Manager - Handles saving and loading inventory data
## Manages items, quantities, equipment, and hotbar configuration

# Database reference
var database: SQLite

# Table configuration
const TABLE_NAME = "inventories"
const INVENTORY_ID = 1  # Single player game, so we use ID 1

# Inventory data structure
var inventory_data: Dictionary = {
	"items": {},  # item_id -> quantity
	"equipment": {},  # slot -> item_id
	"hotbar": [],  # Array of item_ids
	"max_slots": 40,
	"hotbar_size": 10,
	"last_save_time": 0
}

func set_database(db: SQLite) -> void:
	"""Set the database reference"""
	database = db

func create_table() -> bool:
	"""Create the inventories table"""
	if not database:
		print("ERROR: Database not initialized in inventory save manager")
		return false
	
	print("DEBUG: Creating inventory table: ", TABLE_NAME)
	
	var query = """
		CREATE TABLE IF NOT EXISTS %s (
			id INTEGER PRIMARY KEY,
			items_data TEXT NOT NULL DEFAULT '{}',
			equipment_data TEXT NOT NULL DEFAULT '{}',
			hotbar_data TEXT NOT NULL DEFAULT '[]',
			max_slots INTEGER NOT NULL DEFAULT 40,
			hotbar_size INTEGER NOT NULL DEFAULT 10,
			last_save_time INTEGER NOT NULL DEFAULT 0
		)
	""" % [TABLE_NAME]
	
	print("DEBUG: Inventory table query: ", query)
	var result = database.query(query)
	print("DEBUG: Inventory table creation result: ", result)
	
	# Try to verify the table was created
	if result:
		var verify_query = "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'" % TABLE_NAME
		var verify_result = database.query(verify_query)
		if verify_result:
			print("DEBUG: Inventory table verification successful")
	
	return result

func save_inventory_data() -> bool:
	"""Save current inventory data to database"""
	if not database:
		print("ERROR: Database not initialized in inventory save manager")
		return false
	
	# Update save time
	inventory_data.last_save_time = Time.get_unix_time_from_system()
	
	# Convert data to JSON strings
	var items_json = JSON.stringify(inventory_data.items)
	var equipment_json = JSON.stringify(inventory_data.equipment)
	var hotbar_json = JSON.stringify(inventory_data.hotbar)
	
	# Use insert_row instead of raw SQL
	var row_data = {
		"id": INVENTORY_ID,
		"items_data": items_json,
		"equipment_data": equipment_json,
		"hotbar_data": hotbar_json,
		"max_slots": inventory_data.max_slots,
		"hotbar_size": inventory_data.hotbar_size,
		"last_save_time": inventory_data.last_save_time
	}
	
	print("DEBUG: Inventory data to save: ", row_data)
	
	# Use INSERT OR REPLACE to handle existing data
	var query = """
		INSERT OR REPLACE INTO %s (id, items_data, equipment_data, hotbar_data, max_slots, hotbar_size, last_save_time) 
		VALUES (%d, '%s', '%s', '%s', %d, %d, %d)
	""" % [TABLE_NAME, INVENTORY_ID, items_json, equipment_json, hotbar_json, 
		inventory_data.max_slots, inventory_data.hotbar_size, inventory_data.last_save_time]
	
	print("DEBUG: Inventory save query: ", query)
	var result = database.query(query)
	print("DEBUG: Inventory save result: ", result)
	return result

func load_inventory_data() -> bool:
	"""Load inventory data from database"""
	if not database:
		return false
	
	# Use select_rows instead of raw SQL query
	var query = "SELECT * FROM %s WHERE id = %d" % [TABLE_NAME, INVENTORY_ID]
	var result = database.select_rows(TABLE_NAME, query, ["id", "items_data", "equipment_data", "hotbar_data", "max_slots", "hotbar_size", "last_save_time"])
	print("DEBUG: Inventory load query result: ", result)
	
	if result and result.size() > 0:
		print("DEBUG: Inventory load query successful")
		var row = result[0]  # Get the first (and should be only) row
		
		# Parse the loaded data
		var items_json = row.get("items_data", "{}")
		var equipment_json = row.get("equipment_data", "{}")
		var hotbar_json = row.get("hotbar_data", "[]")
		
		# Parse JSON data
		var items_parse = JSON.parse_string(items_json)
		var equipment_parse = JSON.parse_string(equipment_json)
		var hotbar_parse = JSON.parse_string(hotbar_json)
		
		inventory_data = {
			"items": items_parse if items_parse else {},
			"equipment": equipment_parse if equipment_parse else {},
			"hotbar": hotbar_parse if hotbar_parse else [],
			"max_slots": row.get("max_slots", 40),
			"hotbar_size": row.get("hotbar_size", 10),
			"last_save_time": row.get("last_save_time", 0)
		}
		print("DEBUG: Loaded inventory data: ", inventory_data)
		return true
	
	# If no data found, use defaults
	print("DEBUG: No inventory data found, using defaults")
	inventory_data = {
		"items": {},
		"equipment": {},
		"hotbar": [],
		"max_slots": 40,
		"hotbar_size": 10,
		"last_save_time": 0
	}
	return true

## Item management methods

func add_item(item_id: String, quantity: int = 1) -> bool:
	"""Add items to inventory"""
	if quantity <= 0:
		return false
	
	if inventory_data.items.has(item_id):
		inventory_data.items[item_id] += quantity
	else:
		inventory_data.items[item_id] = quantity
	
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	"""Remove items from inventory"""
	if not inventory_data.items.has(item_id):
		return false
	
	var current_quantity = inventory_data.items[item_id]
	if current_quantity < quantity:
		return false
	
	current_quantity -= quantity
	if current_quantity <= 0:
		inventory_data.items.erase(item_id)
	else:
		inventory_data.items[item_id] = current_quantity
	
	return true

func get_item_quantity(item_id: String) -> int:
	"""Get quantity of a specific item"""
	return inventory_data.items.get(item_id, 0)

func set_item_quantity(item_id: String, quantity: int) -> void:
	"""Set quantity of a specific item"""
	if quantity <= 0:
		inventory_data.items.erase(item_id)
	else:
		inventory_data.items[item_id] = quantity

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Check if inventory has enough of an item"""
	return get_item_quantity(item_id) >= quantity

func get_all_items() -> Dictionary:
	"""Get all items in inventory"""
	return inventory_data.items.duplicate()

func clear_inventory() -> void:
	"""Clear all items from inventory"""
	inventory_data.items.clear()

## Equipment management methods

func equip_item(slot: String, item_id: String) -> bool:
	"""Equip an item to a specific slot"""
	if not has_item(item_id, 1):
		return false
	
	inventory_data.equipment[slot] = item_id
	return true

func unequip_item(slot: String) -> String:
	"""Unequip item from a slot, returns the item_id"""
	var item_id = inventory_data.equipment.get(slot, "")
	if item_id != "":
		inventory_data.equipment.erase(slot)
	return item_id

func get_equipped_item(slot: String) -> String:
	"""Get the item equipped in a specific slot"""
	return inventory_data.equipment.get(slot, "")

func get_all_equipment() -> Dictionary:
	"""Get all equipped items"""
	return inventory_data.equipment.duplicate()

## Hotbar management methods

func set_hotbar_item(slot: int, item_id: String) -> bool:
	"""Set an item in the hotbar"""
	if slot < 0 or slot >= inventory_data.hotbar_size:
		return false
	
	# Ensure hotbar array is large enough
	while inventory_data.hotbar.size() <= slot:
		inventory_data.hotbar.append("")
	
	inventory_data.hotbar[slot] = item_id
	return true

func get_hotbar_item(slot: int) -> String:
	"""Get the item in a hotbar slot"""
	if slot < 0 or slot >= inventory_data.hotbar.size():
		return ""
	return inventory_data.hotbar[slot]

func get_hotbar() -> Array:
	"""Get the entire hotbar"""
	return inventory_data.hotbar.duplicate()

func clear_hotbar() -> void:
	"""Clear the hotbar"""
	inventory_data.hotbar.clear()

## Inventory configuration methods

func set_max_slots(max_slots: int) -> void:
	"""Set maximum inventory slots"""
	inventory_data.max_slots = max_slots

func get_max_slots() -> int:
	"""Get maximum inventory slots"""
	return inventory_data.max_slots

func set_hotbar_size(hotbar_size: int) -> void:
	"""Set hotbar size"""
	inventory_data.hotbar_size = hotbar_size

func get_hotbar_size() -> int:
	"""Get hotbar size"""
	return inventory_data.hotbar_size

## Utility methods

func get_inventory_size() -> int:
	"""Get current number of items in inventory"""
	return inventory_data.items.size()

func is_inventory_full() -> bool:
	"""Check if inventory is full"""
	return get_inventory_size() >= inventory_data.max_slots

func get_all_inventory_data() -> Dictionary:
	"""Get all inventory data"""
	return inventory_data.duplicate()

func set_all_inventory_data(data: Dictionary) -> void:
	"""Set all inventory data at once"""
	inventory_data = data.duplicate()

extends Node
class_name SaveSystemIntegrationBridge

## Save System Integration - SQLite-based save system integration
## Provides integration with existing UI and game systems

# Main SQLite save manager
var sqlite_save_manager: Node


func _ready() -> void:
	# Initialize SQLite save manager
	var sqlite_save_manager_scene = preload("res://Scripts/SaveSystem/sqlite_save_manager.gd")
	sqlite_save_manager = sqlite_save_manager_scene.new()
	add_child(sqlite_save_manager)
	
	# Connect signals
	sqlite_save_manager.save_completed.connect(_on_save_completed)
	sqlite_save_manager.load_completed.connect(_on_load_completed)
	sqlite_save_manager.world_created.connect(_on_world_created)
	sqlite_save_manager.world_deleted.connect(_on_world_deleted)


## Integration with world selector

func get_available_worlds_for_selector() -> Array:
	"""Get available worlds in format expected by world selector"""
	var worlds = sqlite_save_manager.get_available_worlds()
	var formatted_worlds = []
	
	for world in worlds:
		formatted_worlds.append({
			"name": world.name,
			"last_save_time": world.last_save_time,
			"game_time": world.game_time,
			"world_seed": world.world_seed
		})
	
	return formatted_worlds

func create_new_world_for_selector(world_name: String, world_seed: int = 0) -> bool:
	"""Create a new world from world selector"""
	return sqlite_save_manager.create_world(world_name, world_seed)

func load_world_for_selector(world_name: String) -> bool:
	"""Load a world from world selector"""
	return sqlite_save_manager.load_world(world_name)

func delete_world_for_selector(world_name: String) -> bool:
	"""Delete a world from world selector"""
	return sqlite_save_manager.delete_world(world_name)

## Integration with existing systems

func save_current_game() -> bool:
	"""Save the current game state"""
	if not sqlite_save_manager.is_world_loaded():
		print("No world loaded, cannot save")
		return false
	
	# Update player data from current game state
	_update_player_data_from_game()
	
	# Update inventory data from current game state
	_update_inventory_data_from_game()
	
	# Update achievement data from current game state
	_update_achievement_data_from_game()
	
	# Update entity data from current game state
	_update_entity_data_from_game()
	
	# Update world data from current game state
	_update_world_data_from_game()
	
	# Save everything
	return sqlite_save_manager.save_world()

func load_current_game() -> bool:
	"""Load the current game state"""
	if not sqlite_save_manager.is_world_loaded():
		print("No world loaded, cannot load")
		return false
	
	# Load all data
	if not sqlite_save_manager.load_world_data():
		return false
	
	# Apply loaded data to game state
	_apply_player_data_to_game()
	_apply_inventory_data_to_game()
	_apply_achievement_data_to_game()
	_apply_entity_data_to_game()
	_apply_world_data_to_game()
	
	return true

## Data synchronization methods

func _update_player_data_from_game() -> void:
	"""Update player data from current game state"""
	var player_manager = sqlite_save_manager.player_save_manager
	
	# Find player in scene
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player_manager.set_player_position(player.global_position)
		
		# Update health - check for Health component first, then fallback to player method
		var health_component = player.get_node_or_null("Health")
		if health_component and health_component.has_method("get_health") and health_component.has_method("get_max_health"):
			# Use the Health component
			var current_health = health_component.get_health()
			var max_health = health_component.get_max_health()
			player_manager.set_player_health(int(current_health), max_health)
		elif player.has_method("get_health"):
			# Fallback to player's get_health method
			var current_health = player.get_health()
			# Handle different return types from get_health()
			if current_health is Dictionary:
				# If it returns a dictionary with health and max_health
				player_manager.set_player_health(current_health.health, current_health.max_health)
			else:
				# If it returns just the health value (float/int)
				player_manager.set_player_health(int(current_health), 100)  # Default max_health to 100
		
		# Update stamina if player has stamina component
		if player.has_method("get_stamina"):
			var stamina_data = player.get_stamina()
			player_manager.set_player_stamina(stamina_data.stamina, stamina_data.max_stamina)

func _update_inventory_data_from_game() -> void:
	"""Update inventory data from current game state"""
	var inventory_manager = sqlite_save_manager.inventory_save_manager
	
	# Find inventory in scene
	var inventory = get_tree().get_first_node_in_group("Inventory")
	if inventory and inventory.has_method("get_all_items"):
		var items = inventory.get_all_items()
		inventory_manager.clear_inventory()
		
		for item_id in items:
			inventory_manager.add_item(item_id, items[item_id])

func _update_achievement_data_from_game() -> void:
	"""Update achievement data from current game state"""
	var achievement_manager = sqlite_save_manager.achievement_save_manager
	
	# Update from AchievementManager if available
	if AchievementManager:
		var achievements = AchievementManager.get_all_achievements()
		for achievement_id in achievements:
			var achievement = achievements[achievement_id]
			if achievement.unlocked:
				achievement_manager.unlock_achievement(achievement_id)
			else:
				achievement_manager.set_achievement_progress(
					achievement_id, 
					achievement.progress, 
					achievement.max_progress
				)

func _update_entity_data_from_game() -> void:
	"""Update entity data from current game state"""
	var entity_manager = sqlite_save_manager.entity_save_manager
	
	# Clear existing entities
	entity_manager.clear_all_entities()
	
	# Find all entities in scene
	var entities = get_tree().get_nodes_in_group("Enemies")
	for entity in entities:
		if entity.has_method("get_entity_id"):
			var entity_id = entity.get_entity_id()
			var entity_type = entity.get_entity_type() if entity.has_method("get_entity_type") else "enemy"
			var position = entity.global_position
			
			var entity_data = {}
			if entity.has_method("get_health"):
				var health_data = entity.get_health()
				entity_data["health"] = health_data.health
				entity_data["max_health"] = health_data.max_health
			
			entity_manager.add_entity(entity_id, entity_type, position, entity_data)

func _update_world_data_from_game() -> void:
	"""Update world data from current game state"""
	var world_manager = sqlite_save_manager.world_data_save_manager
	
	# Find world in scene
	var world = get_tree().get_first_node_in_group("World")
	if world:
		# Update world seed if available
		if world.has_method("get_world_seed"):
			world_manager.set_world_seed(world.get_world_seed())
		
		# Update world settings if available
		if world.has_method("get_world_settings"):
			var settings = world.get_world_settings()
			for key in settings:
				world_manager.set_world_setting(key, settings[key])
		
		# Save chunk data from chunk manager
		if world.has_method("get_chunk_manager"):
			var chunk_manager = world.get_chunk_manager()
			if chunk_manager and chunk_manager.has_method("get_loaded_chunks"):
				var loaded_chunks = chunk_manager.get_loaded_chunks()
				print("DEBUG: Saving ", loaded_chunks.size(), " chunks to database")
				
				# Clear existing chunks and save new ones
				world_manager.clear_all_chunks()
				for chunk_key in loaded_chunks:
					var chunk_data = loaded_chunks[chunk_key]
					# Parse chunk coordinates from key
					var coords = chunk_key.split(",")
					if coords.size() >= 2:
						var chunk_x = int(coords[0])
						var chunk_y = int(coords[1])
						world_manager.save_chunk(chunk_x, chunk_y, chunk_data)
		
		# Save block modifications (broken/placed blocks)
		if world.has_method("get_modified_blocks"):
			var modified_blocks = world.get_modified_blocks()
			print("DEBUG: Saving ", modified_blocks.size(), " player-modified blocks to database")
			
			# Clear existing blocks and save new ones
			world_manager.clear_all_blocks()
			for block_key in modified_blocks:
				var block_data = modified_blocks[block_key]
				
				# Handle block coordinates - could be Vector2i or String
				var block_x: int
				var block_y: int
				
				if block_key is Vector2i:
					# If it's a Vector2i, use x and y directly
					block_x = block_key.x
					block_y = block_key.y
				elif block_key is String:
					# If it's a string, split it
					var coords = block_key.split(",")
					if coords.size() >= 2:
						block_x = int(coords[0])
						block_y = int(coords[1])
					else:
						continue  # Skip invalid string format
				else:
					continue  # Skip unknown format
				
				world_manager.save_block(block_x, block_y, block_data)
		else:
			# Fallback: save all block health (old behavior)
			if world.has_method("get_block_health"):
				var block_health = world.get_block_health()
				print("DEBUG: Fallback - saving all ", block_health.size(), " blocks to database")
				
				# Clear existing blocks and save new ones
				world_manager.clear_all_blocks()
				for block_key in block_health:
					var health_data = block_health[block_key]
					
					# Handle block coordinates - could be Vector2i or String
					var block_x: int
					var block_y: int
					
					if block_key is Vector2i:
						# If it's a Vector2i, use x and y directly
						block_x = block_key.x
						block_y = block_key.y
					elif block_key is String:
						# If it's a string, split it
						var coords = block_key.split(",")
						if coords.size() >= 2:
							block_x = int(coords[0])
							block_y = int(coords[1])
						else:
							continue  # Skip invalid string format
					else:
						continue  # Skip unknown format
					
					var block_data = {
						"health": health_data,
						"modified": true,
						"modification_time": Time.get_unix_time_from_system()
					}
					world_manager.save_block(block_x, block_y, block_data)

## Apply loaded data to game

func _apply_player_data_to_game() -> void:
	"""Apply loaded player data to game state"""
	var player_manager = sqlite_save_manager.player_save_manager
	var _player_data = player_manager.get_all_player_data()
	
	# Find player in scene
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# Get saved position
		var saved_position = player_manager.get_player_position()
		print("DEBUG: Loading player position: ", saved_position)
		print("DEBUG: Current player position: ", player.global_position)
		
		# Set position
		player.global_position = saved_position
		print("DEBUG: Player position set to: ", player.global_position)
	else:
		print("DEBUG: No player found in scene when trying to load position")
		return
	
	# Set health - check for Health component first, then fallback to player method
	var health_data = player_manager.get_player_health()
	var health_component = player.get_node_or_null("Health")
	if health_component and health_component.has_method("set_health") and health_component.has_method("set_max_health"):
		# Use the Health component
		health_component.set_max_health(health_data.max_health)
		health_component.set_health(health_data.health)
	elif player.has_method("set_health"):
		# Fallback to player's set_health method
		# Handle different set_health method signatures
		if player.get("set_health").get_parameter_count() >= 2:
			# If set_health takes two parameters (health, max_health)
			player.set_health(health_data.health, health_data.max_health)
		else:
			# If set_health takes only one parameter (health)
			player.set_health(health_data.health)
	
	# Set stamina if player has stamina component
	if player.has_method("set_stamina"):
		var stamina_data = player_manager.get_player_stamina()
		player.set_stamina(stamina_data.stamina, stamina_data.max_stamina)
	
	# Set experience and level if player has these methods
	if player.has_method("set_experience"):
		player.set_experience(player_manager.get_player_experience())
	if player.has_method("set_level"):
		player.set_level(player_manager.get_player_level())
	if player.has_method("set_skill_points"):
		player.set_skill_points(player_manager.get_player_skill_points())

func _apply_inventory_data_to_game() -> void:
	"""Apply loaded inventory data to game state"""
	var inventory_manager = sqlite_save_manager.inventory_save_manager
	var inventory_data = inventory_manager.get_all_inventory_data()
	
	# Find inventory in scene
	var inventory = get_tree().get_first_node_in_group("Inventory")
	if inventory and inventory.has_method("set_items"):
		inventory.set_items(inventory_data.items)

func _apply_achievement_data_to_game() -> void:
	"""Apply loaded achievement data to game state"""
	var achievement_manager = sqlite_save_manager.achievement_save_manager
	var achievement_data = achievement_manager.get_all_achievements()
	
	print("DEBUG: _apply_achievement_data_to_game called")
	print("DEBUG: Loaded achievement data: ", achievement_data)
	print("DEBUG: Number of achievements loaded: ", achievement_data.size())
	
	# Update AchievementManager if available
	if AchievementManager:
		# First reset all achievements to default state for this world
		print("DEBUG: Resetting all achievements to default state")
		AchievementManager.reset_achievements()
		
		# Then apply the loaded achievement data (if any)
		if achievement_data.size() > 0:
			print("DEBUG: Applying loaded achievement data...")
			for achievement_id in achievement_data:
				var achievement = achievement_data[achievement_id]
				print("DEBUG: Processing achievement: ", achievement_id, " unlocked: ", achievement.unlocked)
				if achievement.unlocked:
					print("DEBUG: Unlocking achievement: ", achievement_id)
					AchievementManager.unlock_achievement(achievement_id)
				else:
					print("DEBUG: Setting progress for achievement: ", achievement_id, " progress: ", achievement.progress)
					AchievementManager.set_achievement_progress(
						achievement_id, 
						achievement.progress, 
						achievement.max_progress
					)
		else:
			print("DEBUG: No achievement data to apply - all achievements remain reset")
		
		print("DEBUG: Applied achievement data to AchievementManager for current world")

func _apply_entity_data_to_game() -> void:
	"""Apply loaded entity data to game state"""
	var entity_manager = sqlite_save_manager.entity_save_manager
	var entity_data = entity_manager.get_all_entity_data()
	
	# This would typically involve spawning entities based on saved data
	# Implementation depends on your entity spawning system
	print("Entity data loaded: ", entity_data.total_entities, " entities")

func _apply_world_data_to_game() -> void:
	"""Apply loaded world data to game state"""
	var world_manager = sqlite_save_manager.world_data_save_manager
	var _world_data = world_manager.get_all_world_data()
	
	# Find world in scene
	var world = get_tree().get_first_node_in_group("World")
	if world:
		# Set world seed if available
		if world.has_method("set_world_seed"):
			world.set_world_seed(world_manager.get_world_seed())
		
		# Apply world settings if available
		if world.has_method("set_world_settings"):
			var settings = world_manager.get_all_world_settings()
			world.set_world_settings(settings)
		
		# Load block modifications FIRST (broken/placed blocks)
		# This must happen before chunk loading so that block modifications are available
		# when chunks are placed
		if world.has_method("set_modified_blocks"):
			var all_blocks = world_manager.get_all_blocks()
			print("DEBUG: Loading ", all_blocks.size(), " block modifications from database")
			
			var modified_blocks = {}
			var block_health = {}
			
			for block_key in all_blocks:
				var block_data = all_blocks[block_key]
				
				# Convert string coordinates back to Vector2i
				var coords = block_key.split(",")
				if coords.size() >= 2:
					var block_x = int(coords[0])
					var block_y = int(coords[1])
					var vector_key = Vector2i(block_x, block_y)
					
					# Store in modified blocks dictionary
					modified_blocks[vector_key] = block_data
					
					# Also update block health for the breaking system
					if block_data.has("health"):
						block_health[vector_key] = block_data.health
			
			world.set_modified_blocks(modified_blocks)
			if world.has_method("set_block_health"):
				world.set_block_health(block_health)
		else:
			# Fallback: load into block health only
			if world.has_method("set_block_health"):
				var all_blocks = world_manager.get_all_blocks()
				print("DEBUG: Fallback - loading ", all_blocks.size(), " blocks into block health")
				
				var block_health = {}
				for block_key in all_blocks:
					var block_data = all_blocks[block_key]
					if block_data.has("health"):
						# Convert string coordinates back to Vector2i for the block health system
						var coords = block_key.split(",")
						if coords.size() >= 2:
							var block_x = int(coords[0])
							var block_y = int(coords[1])
							var vector_key = Vector2i(block_x, block_y)
							block_health[vector_key] = block_data.health
				
				world.set_block_health(block_health)
		
		# Load chunk data into chunk manager AFTER block modifications are loaded
		if world.has_method("get_chunk_manager"):
			var chunk_manager = world.get_chunk_manager()
			if chunk_manager and chunk_manager.has_method("load_chunks_from_data"):
				var all_chunks = world_manager.get_all_chunks()
				print("DEBUG: Loading ", all_chunks.size(), " chunks from database")
				chunk_manager.load_chunks_from_data(all_chunks)
				
				# Note: Player chunk position will be set after player is spawned
				# This is handled in the procedural world main after player spawning

## Signal handlers

func _on_save_completed(world_name: String, success: bool) -> void:
	if success:
		print("Save completed for world: ", world_name)
	else:
		print("Save failed for world: ", world_name)

func _on_load_completed(world_name: String, success: bool) -> void:
	if success:
		print("Load completed for world: ", world_name)
	else:
		print("Load failed for world: ", world_name)

func _on_world_created(world_name: String) -> void:
	print("World created: ", world_name)

func _on_world_deleted(world_name: String) -> void:
	print("World deleted: ", world_name)

## Public API for other systems

func get_sqlite_save_manager() -> Node:
	"""Get the SQLite save manager instance"""
	return sqlite_save_manager

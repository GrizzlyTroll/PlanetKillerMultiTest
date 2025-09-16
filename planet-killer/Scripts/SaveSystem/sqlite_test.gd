extends Node

## SQLite Test Script - Test the save system functionality

func _ready() -> void:
	test_save_system()

func test_save_system() -> void:
	print("Testing SQLite save system...")
	
	# Create a test save manager
	var save_manager = SQLiteSaveManager.new()
	add_child(save_manager)
	
	# Test world creation
	print("Testing world creation...")
	var world_created = save_manager.create_world("test_world", 12345)
	print("World creation result: ", world_created)
	
	if world_created:
		# Test setting some player data
		print("Testing player data...")
		save_manager.player_save_manager.set_player_position(Vector2(100, 200))
		save_manager.player_save_manager.set_player_health(75, 100)
		save_manager.player_save_manager.set_player_experience(1500)
		save_manager.player_save_manager.set_player_level(5)
		
		# Test setting some inventory data
		print("Testing inventory data...")
		save_manager.inventory_save_manager.set_item_quantity("wood", 50)
		save_manager.inventory_save_manager.set_item_quantity("stone", 25)
		save_manager.inventory_save_manager.set_hotbar_item(0, "axe")
		save_manager.inventory_save_manager.set_hotbar_item(1, "pickaxe")
		
		# Test setting some achievement data
		print("Testing achievement data...")
		save_manager.achievement_save_manager.unlock_achievement("first_kill")
		save_manager.achievement_save_manager.set_achievement_progress("kill_100_enemies", 25, 100)
		
		# Test setting some entity data
		print("Testing entity data...")
		save_manager.entity_save_manager.add_entity("enemy_001", "goblin", Vector2(200, 300), {
			"health": 50,
			"max_health": 50
		})
		
		# Test setting some world data
		print("Testing world data...")
		save_manager.world_data_save_manager.set_world_seed(12345)
		save_manager.world_data_save_manager.set_world_setting("difficulty", "normal")
		save_manager.world_data_save_manager.save_chunk(0, 0, {"blocks": {"0,0": "stone"}})
		
		# Test saving
		print("Testing save...")
		var save_result = save_manager.save_world()
		print("Save result: ", save_result)
		
		# Test loading
		print("Testing load...")
		var load_result = save_manager.load_world_data()
		print("Load result: ", load_result)
		
		# Verify loaded data
		if load_result:
			var player_pos = save_manager.player_save_manager.get_player_position()
			var player_health = save_manager.player_save_manager.get_player_health()
			var player_exp = save_manager.player_save_manager.get_player_experience()
			var player_level = save_manager.player_save_manager.get_player_level()
			
			print("Loaded player position: ", player_pos)
			print("Loaded player health: ", player_health)
			print("Loaded player experience: ", player_exp)
			print("Loaded player level: ", player_level)
			
			var wood_count = save_manager.inventory_save_manager.get_item_quantity("wood")
			var stone_count = save_manager.inventory_save_manager.get_item_quantity("stone")
			var hotbar_item_0 = save_manager.inventory_save_manager.get_hotbar_item(0)
			var hotbar_item_1 = save_manager.inventory_save_manager.get_hotbar_item(1)
			
			print("Loaded wood count: ", wood_count)
			print("Loaded stone count: ", stone_count)
			print("Loaded hotbar item 0: ", hotbar_item_0)
			print("Loaded hotbar item 1: ", hotbar_item_1)
			
			var first_kill_unlocked = save_manager.achievement_save_manager.is_achievement_unlocked("first_kill")
			var kill_progress = save_manager.achievement_save_manager.get_achievement_progress("kill_100_enemies")
			
			print("First kill unlocked: ", first_kill_unlocked)
			print("Kill progress: ", kill_progress)
			
			var enemy_exists = save_manager.entity_save_manager.has_entity("enemy_001")
			var enemy_data = save_manager.entity_save_manager.get_entity("enemy_001")
			
			print("Enemy exists: ", enemy_exists)
			print("Enemy data: ", enemy_data)
			
			var world_seed = save_manager.world_data_save_manager.get_world_seed()
			var difficulty = save_manager.world_data_save_manager.get_world_setting("difficulty")
			var chunk_data = save_manager.world_data_save_manager.load_chunk(0, 0)
			
			print("World seed: ", world_seed)
			print("Difficulty: ", difficulty)
			print("Chunk data: ", chunk_data)
		
		# Test getting available worlds
		print("Testing get available worlds...")
		var worlds = save_manager.get_available_worlds()
		print("Available worlds: ", worlds)
		
		# Close database
		save_manager.close_database()
		
		print("SQLite save system test completed!")
	else:
		print("Failed to create test world!")

extends RefCounted
class_name BlockBreaking

# Block breaking system
var block_health: Dictionary = {}  # Stores health for each block position

static func get_block_at_position(pos: Vector2, parent_node: Node2D, block_size: int) -> StaticBody2D:
	"""Get the block at the given world position"""
	for child in parent_node.get_children():
		if child is StaticBody2D and child.has_meta("block_type"):
			var block_rect = Rect2(child.position - Vector2(block_size/2, block_size/2), Vector2(block_size, block_size))
			if block_rect.has_point(pos):
				return child
	return null

static func has_block_at_world_coords(world_x: int, world_y: int, parent_node: Node2D, block_size: int) -> bool:
	"""Check if there's a block at the given world coordinates"""
	var world_pos = Vector2(world_x * block_size + block_size/2, world_y * block_size + block_size/2)
	return get_block_at_position(world_pos, parent_node, block_size) != null

static func break_block(block: StaticBody2D, block_health_dict: Dictionary, modified_blocks_dict: Dictionary = {}) -> void:
	"""Break a block and drop items"""
	if not block.has_meta("block_type") or not block.has_meta("block_pos"):
		return
	
	var block_type = block.get_meta("block_type")
	var block_pos = block.get_meta("block_pos")
	
	# Check if block can be broken
	if block_type not in BlockSystem.BLOCK_DATA or BlockSystem.BLOCK_DATA[block_type]["health"] <= 0:
		return
	
	# Get original health if not already stored
	var original_health = BlockSystem.BLOCK_DATA[block_type]["health"]
	
	# Reduce block health
	if block_pos in block_health_dict:
		block_health_dict[block_pos] -= 1
		print("Block health: ", block_health_dict[block_pos], "/", original_health)
		
		# Track this as a player modification
		if modified_blocks_dict != {}:
			modified_blocks_dict[block_pos] = {
				"health": block_health_dict[block_pos],
				"original_health": original_health,
				"block_type": block_type,
				"modified": true,
				"modification_time": Time.get_unix_time_from_system()
			}
		
		# Check if block is destroyed
		if block_health_dict[block_pos] <= 0:
			# Drop item if block drops something
			var item_name = BlockSystem.BLOCK_DATA[block_type]["item"]
			if item_name:
				drop_item(item_name, block.global_position)
			
			# Remove the block
			block.queue_free()
			block_health_dict.erase(block_pos)
			
			# Mark as destroyed in modified blocks
			if modified_blocks_dict != {}:
				modified_blocks_dict[block_pos] = {
					"health": 0,
					"original_health": original_health,
					"block_type": block_type,
					"destroyed": true,
					"modified": true,
					"modification_time": Time.get_unix_time_from_system()
				}
			
			print("Block destroyed! Item dropped: ", item_name)
			
			# Trigger achievement progress
			_trigger_digging_achievements(block_type, item_name, block_pos)

static func drop_item(item_name: String, position: Vector2) -> void:
	"""Drop an item at the given position"""
	# For now, just print what would be dropped
	# In a full implementation, you'd create an actual item entity
	print("Dropped item: ", item_name, " at position: ", position)
	
	# TODO: Create actual item entity and add to inventory
	# This would involve creating a visual item that can be picked up

static func _trigger_digging_achievements(block_type: String, item_name: String, block_pos: Vector2i) -> void:
	"""Trigger achievement progress for digging activities"""
	print("🎯 _trigger_digging_achievements called with block_type: ", block_type, " item_name: ", item_name)
	
	if not AchievementManager:
		print("❌ AchievementManager not found")
		return
	
	print("✅ AchievementManager found, triggering achievements...")
	
	# Track total blocks dug
	print("📊 Incrementing dig achievements...")
	AchievementManager.increment("dig_10_blocks")
	AchievementManager.increment("dig_100_blocks")
	AchievementManager.increment("dig_1000_blocks")
	
	# Track first dig achievement
	if not AchievementManager.is_unlocked("first_dig"):
		print("🏆 Unlocking first_dig achievement...")
		AchievementManager.unlock("first_dig")
	else:
		print("ℹ️ first_dig achievement already unlocked")
	
	# Track specific item achievements
	match item_name:
		"wood":
			if not AchievementManager.is_unlocked("first_wood"):
				print("🏆 Unlocking first_wood achievement...")
				AchievementManager.unlock("first_wood")
			else:
				print("ℹ️ first_wood achievement already unlocked")
		"stone":
			if not AchievementManager.is_unlocked("first_stone"):
				print("🏆 Unlocking first_stone achievement...")
				AchievementManager.unlock("first_stone")
			else:
				print("ℹ️ first_stone achievement already unlocked")
	
	# Track deep digging achievement
	# Note: This would need player position, which should be passed as parameter
	# For now, we'll use block position as a proxy
	if block_pos.y > 50:
		print("📊 Incrementing deep_digger achievement...")
		AchievementManager.increment("deep_digger", block_pos.y - 50)
	
	# Track cave exploration
	# Note: This would need cave detection logic, which should be passed as parameter
	# For now, we'll skip this check
	
	print("✅ Achievement triggers completed")

static func place_block(x: int, y: int, block_type: String, parent_node: Node2D, block_size: int, block_health_dict: Dictionary) -> void:
	"""Place a block at the given coordinates"""
	# Safety check to prevent invalid block types
	if not block_type in BlockSystem.BLOCK_COLORS:
		print("Warning: Unknown block type: ", block_type)
		return
	
	# Safety check to prevent placing blocks outside reasonable bounds
	if y < -1000 or y > 2000:  # Reasonable bounds for world generation
		return
	
	# Create a static body for collision
	var static_body = StaticBody2D.new()
	static_body.position = Vector2(x * block_size + block_size/2, y * block_size + block_size/2)
	
	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(block_size, block_size)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	
	# Create a colored rectangle for visual representation
	var rect = ColorRect.new()
	rect.color = BlockSystem.BLOCK_COLORS[block_type]
	rect.size = Vector2(block_size, block_size)
	rect.position = Vector2(-block_size/2, -block_size/2)  # Center relative to static body
	static_body.add_child(rect)
	
	# Store block data for breaking system
	var block_pos = Vector2i(x, y)
	if block_type in BlockSystem.BLOCK_DATA:
		block_health_dict[block_pos] = BlockSystem.BLOCK_DATA[block_type]["health"]
		static_body.set_meta("block_type", block_type)
		static_body.set_meta("block_pos", block_pos)
	
	parent_node.add_child(static_body)
	

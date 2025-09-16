extends RefCounted
class_name BiomeFeatures

static func add_biome_features(x: int, surface_height: int, biome: BiomeSystem.BIOME_TYPE, place_block_func: Callable) -> void:
	"""Add trees, plants, and other features based on biome"""
	var feature_chance = 0.05 # 5% chance for features
	
	# Use deterministic random based on position and world seed for consistent placement
	var deterministic_random = _get_deterministic_random(x, surface_height)
	
	if deterministic_random < feature_chance:
		match biome:
			BiomeSystem.BIOME_TYPE.FOREST, BiomeSystem.BIOME_TYPE.FLOWER_FOREST:
				place_tree(x, surface_height - 1, "tree_trunk", "leaves", place_block_func)
			BiomeSystem.BIOME_TYPE.BIRCH_FOREST, BiomeSystem.BIOME_TYPE.OLD_GROWTH_BIRCH_FOREST:
				place_tree(x, surface_height - 1, "tree_trunk", "birch_leaves", place_block_func)
			BiomeSystem.BIOME_TYPE.DARK_FOREST:
				place_tree(x, surface_height - 1, "tree_trunk", "dark_leaves", place_block_func)
			BiomeSystem.BIOME_TYPE.JUNGLE, BiomeSystem.BIOME_TYPE.SPARSE_JUNGLE:
				place_tree(x, surface_height - 1, "tree_trunk", "jungle_leaves", place_block_func)
			BiomeSystem.BIOME_TYPE.BAMBOO_JUNGLE:
				place_bamboo(x, surface_height - 1, place_block_func)
			BiomeSystem.BIOME_TYPE.TAIGA, BiomeSystem.BIOME_TYPE.SNOWY_TAIGA:
				place_tree(x, surface_height - 1, "tree_trunk", "pine_leaves", place_block_func)
			BiomeSystem.BIOME_TYPE.OLD_GROWTH_PINE_TAIGA, BiomeSystem.BIOME_TYPE.OLD_GROWTH_SPRUCE_TAIGA:
				place_tree(x, surface_height - 1, "tree_trunk", "spruce_leaves", place_block_func)
			BiomeSystem.BIOME_TYPE.DESERT:
				place_cactus(x, surface_height - 1, place_block_func)
			BiomeSystem.BIOME_TYPE.SAVANNA, BiomeSystem.BIOME_TYPE.SAVANNA_PLATEAU, BiomeSystem.BIOME_TYPE.WINDSWEPT_SAVANNA:
				place_dead_bush(x, surface_height, place_block_func)
			BiomeSystem.BIOME_TYPE.SWAMP:
				place_lily_pad(x, surface_height, place_block_func)
			BiomeSystem.BIOME_TYPE.MANGROVE_SWAMP:
				place_mangrove_tree(x, surface_height - 1, place_block_func)
			BiomeSystem.BIOME_TYPE.SUNFLOWER_PLAINS:
				place_sunflower(x, surface_height, place_block_func)
			BiomeSystem.BIOME_TYPE.FLOWER_FOREST:
				place_flowers(x, surface_height, place_block_func)
			BiomeSystem.BIOME_TYPE.JAGGED_PEAKS, BiomeSystem.BIOME_TYPE.FROZEN_PEAKS, BiomeSystem.BIOME_TYPE.STONY_PEAKS:
				place_rock_formation(x, surface_height, place_block_func)
			_:
				pass

static func place_tree(x: int, y: int, trunk_type: String, leaves_type: String, place_block_func: Callable) -> void:
	"""Place a tree with trunk and leaves"""
	# Place tree trunk
	place_block_func.call(x, y, trunk_type)
	place_block_func.call(x, y - 1, trunk_type)
	place_block_func.call(x, y - 2, trunk_type)
	
	# Place leaves
	for dx in range(-1, 2):
		for dy in range(-3, -1):
			if abs(dx) + abs(dy + 3) <= 2: # Create a leaf ball
				place_block_func.call(x + dx, y + dy, leaves_type)

static func place_bamboo(x: int, y: int, place_block_func: Callable) -> void:
	"""Place bamboo stalks"""
	var height = _get_deterministic_int(x, y, 3, 6)
	for i in range(height):
		place_block_func.call(x, y - i, "bamboo")

static func place_cactus(x: int, y: int, place_block_func: Callable) -> void:
	"""Place a cactus"""
	var height = _get_deterministic_int(x, y, 2, 4)
	for i in range(height):
		place_block_func.call(x, y - i, "cactus")

static func place_dead_bush(x: int, y: int, place_block_func: Callable) -> void:
	"""Place a dead bush"""
	place_block_func.call(x, y, "dead_bush")

static func place_lily_pad(x: int, y: int, place_block_func: Callable) -> void:
	"""Place a lily pad"""
	place_block_func.call(x, y, "lily_pads")

static func place_mangrove_tree(x: int, y: int, place_block_func: Callable) -> void:
	"""Place a mangrove tree with roots and leaves"""
	# Place mangrove roots and trunk
	place_block_func.call(x, y, "mangrove_wood")
	place_block_func.call(x, y - 1, "mangrove_wood")
	place_block_func.call(x, y - 2, "mangrove_wood")
	
	# Place mangrove leaves
	for dx in range(-1, 2):
		for dy in range(-3, -1):
			if abs(dx) + abs(dy + 3) <= 2:
				place_block_func.call(x + dx, y + dy, "leaves")

static func place_sunflower(x: int, y: int, place_block_func: Callable) -> void:
	"""Place a sunflower"""
	place_block_func.call(x, y, "sunflowers")

static func place_flowers(x: int, y: int, place_block_func: Callable) -> void:
	"""Place flowers"""
	place_block_func.call(x, y, "flowers")

static func place_rock_formation(x: int, y: int, place_block_func: Callable) -> void:
	"""Place rock formations in mountain biomes"""
	var height = _get_deterministic_int(x, y, 2, 5)
	for i in range(height):
		place_block_func.call(x, y - i, "basalt")
	# Add some variety
	if _get_deterministic_random(x + 1, y) < 0.3:
		place_block_func.call(x + 1, y - 2, "granite")
	if _get_deterministic_random(x - 1, y) < 0.3:
		place_block_func.call(x - 1, y - 3, "andesite")

## Deterministic random functions for consistent world generation

static func _get_deterministic_random(x: int, y: int) -> float:
	"""Get a deterministic random value between 0 and 1 based on position"""
	# Use a simple hash function to create deterministic randomness
	var hash_value = _simple_hash(x, y)
	return float(hash_value % 1000) / 1000.0

static func _get_deterministic_int(x: int, y: int, min_val: int, max_val: int) -> int:
	"""Get a deterministic random integer between min_val and max_val based on position"""
	var hash_value = _simple_hash(x, y)
	return min_val + (hash_value % (max_val - min_val + 1))

static func _simple_hash(x: int, y: int) -> int:
	"""Simple hash function for deterministic randomness"""
	# Use a combination of position and a prime number for good distribution
	return (x * 73856093) ^ (y * 19349663) ^ 0x9e3779b9

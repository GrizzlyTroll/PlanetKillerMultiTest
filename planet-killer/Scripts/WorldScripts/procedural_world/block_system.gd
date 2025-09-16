extends RefCounted
class_name BlockSystem

# Block data for breaking system
static var BLOCK_DATA = {
	# Basic terrain blocks
	"grass": {"health": 2, "item": "dirt"},
	"dirt": {"health": 1, "item": "dirt"},
	"stone": {"health": 4, "item": "stone"},
	"sand": {"health": 1, "item": "sand"},
	"snow": {"health": 1, "item": "snow"},
	"water": {"health": 0, "item": null},  # Can't break water
	"ice": {"health": 2, "item": "ice"},
	"clay": {"health": 2, "item": "clay"},
	"gravel": {"health": 2, "item": "gravel"},
	"mud": {"health": 1, "item": "mud"},
	"peat": {"health": 1, "item": "peat"},
	"ash": {"health": 1, "item": "ash"},
	"obsidian": {"health": 8, "item": "obsidian"},
	"basalt": {"health": 6, "item": "basalt"},
	"granite": {"health": 5, "item": "granite"},
	"marble": {"health": 4, "item": "marble"},
	"limestone": {"health": 3, "item": "limestone"},
	"shale": {"health": 3, "item": "shale"},
	"slate": {"health": 4, "item": "slate"},
	"chalk": {"health": 2, "item": "chalk"},
	"pumice": {"health": 1, "item": "pumice"},
	"tuff": {"health": 2, "item": "tuff"},
	"andesite": {"health": 4, "item": "andesite"},
	"diorite": {"health": 4, "item": "diorite"},
	"gabbro": {"health": 5, "item": "gabbro"},
	"peridotite": {"health": 6, "item": "peridotite"},
	"serpentinite": {"health": 5, "item": "serpentinite"},
	"gneiss": {"health": 4, "item": "gneiss"},
	"schist": {"health": 3, "item": "schist"},
	"quartzite": {"health": 6, "item": "quartzite"},
	"sandstone": {"health": 3, "item": "sandstone"},
	"conglomerate": {"health": 4, "item": "conglomerate"},
	"breccia": {"health": 4, "item": "breccia"},
	
	# Biome-specific surface blocks
	"sunflower_grass": {"health": 2, "item": "dirt"},
	"forest_grass": {"health": 2, "item": "dirt"},
	"dark_forest_grass": {"health": 2, "item": "dirt"},
	"jungle_grass": {"health": 2, "item": "dirt"},
	"taiga_grass": {"health": 2, "item": "dirt"},
	"savanna_grass": {"health": 2, "item": "dirt"},
	"swamp_grass": {"health": 2, "item": "dirt"},
	"beach_sand": {"health": 1, "item": "sand"},
	"stony_ground": {"health": 3, "item": "stone"},
	"mangrove_wood": {"health": 4, "item": "wood"},
	"bamboo": {"health": 2, "item": "bamboo"},
	"cactus": {"health": 3, "item": "cactus"},
	"tree_trunk": {"health": 6, "item": "wood"},
	"leaves": {"health": 1, "item": "leaves"},
	"pine_leaves": {"health": 1, "item": "leaves"},
	"spruce_leaves": {"health": 1, "item": "leaves"},
	"birch_leaves": {"health": 1, "item": "leaves"},
	"jungle_leaves": {"health": 1, "item": "leaves"},
	"dark_leaves": {"health": 1, "item": "leaves"},
	"flowers": {"health": 1, "item": "flowers"},
	"sunflowers": {"health": 1, "item": "sunflowers"},
	"lily_pads": {"health": 1, "item": "lily_pads"},
	"mushrooms": {"health": 1, "item": "mushrooms"},
	"vines": {"health": 1, "item": "vines"},
	"dead_bush": {"health": 1, "item": "dead_bush"},
	"tall_grass": {"health": 1, "item": "grass"},
	"seagrass": {"health": 1, "item": "seagrass"},
	"kelp": {"health": 1, "item": "kelp"},
	
	# Aquatic blocks
	"coral": {"health": 2, "item": "coral"},
	"sea_anemone": {"health": 1, "item": "sea_anemone"},
	"tube_coral": {"health": 2, "item": "tube_coral"},
	"brain_coral": {"health": 2, "item": "brain_coral"},
	"bubble_coral": {"health": 2, "item": "bubble_coral"},
	"fire_coral": {"health": 2, "item": "fire_coral"},
	"horn_coral": {"health": 2, "item": "horn_coral"},
	"dead_coral": {"health": 1, "item": "dead_coral"},
	"coral_fan": {"health": 1, "item": "coral_fan"},
	"sea_lantern": {"health": 3, "item": "sea_lantern"},
	"prismarine": {"health": 4, "item": "prismarine"},
	"dark_prismarine": {"health": 5, "item": "dark_prismarine"},
	"prismarine_bricks": {"health": 4, "item": "prismarine_bricks"},
	"sea_urchin": {"health": 1, "item": "sea_urchin"},
	"sea_sponge": {"health": 2, "item": "sea_sponge"},
	"seaweed": {"health": 1, "item": "seaweed"},
	"barnacle": {"health": 2, "item": "barnacle"},
	"sea_star": {"health": 1, "item": "sea_star"},
	"jellyfish": {"health": 1, "item": "jellyfish"},
	"sea_slug": {"health": 1, "item": "sea_slug"},
	"anemone": {"health": 1, "item": "anemone"},
}

# Block colors for visualization
static var BLOCK_COLORS = {
	# Basic terrain blocks
	"grass": Color(0.2, 0.8, 0.2),
	"dirt": Color(0.6, 0.4, 0.2),
	"stone": Color(0.5, 0.5, 0.5),
	"sand": Color(0.9, 0.8, 0.6),
	"snow": Color(0.9, 0.9, 0.9),
	"water": Color(0.2, 0.4, 0.8),
	"ice": Color(0.7, 0.9, 1.0),
	"clay": Color(0.8, 0.6, 0.4),
	"gravel": Color(0.7, 0.7, 0.7),
	"mud": Color(0.4, 0.3, 0.2),
	"peat": Color(0.2, 0.15, 0.1),
	"ash": Color(0.3, 0.3, 0.3),
	"obsidian": Color(0.1, 0.1, 0.2),
	"basalt": Color(0.2, 0.2, 0.2),
	"granite": Color(0.6, 0.5, 0.4),
	"marble": Color(0.9, 0.9, 0.8),
	"limestone": Color(0.8, 0.8, 0.7),
	"shale": Color(0.4, 0.4, 0.5),
	"slate": Color(0.3, 0.3, 0.4),
	"chalk": Color(0.95, 0.95, 0.9),
	"pumice": Color(0.8, 0.8, 0.8),
	"tuff": Color(0.6, 0.6, 0.6),
	"andesite": Color(0.5, 0.5, 0.4),
	"diorite": Color(0.7, 0.7, 0.6),
	"gabbro": Color(0.3, 0.3, 0.3),
	"peridotite": Color(0.2, 0.3, 0.2),
	"serpentinite": Color(0.2, 0.4, 0.3),
	"gneiss": Color(0.6, 0.5, 0.6),
	"schist": Color(0.5, 0.4, 0.5),
	"quartzite": Color(0.9, 0.9, 0.9),
	"sandstone": Color(0.9, 0.8, 0.6),
	"conglomerate": Color(0.7, 0.6, 0.5),
	"breccia": Color(0.6, 0.5, 0.4),
	
	# Biome-specific surface blocks
	"sunflower_grass": Color(0.3, 0.9, 0.3),
	"forest_grass": Color(0.1, 0.6, 0.1),
	"dark_forest_grass": Color(0.05, 0.4, 0.05),
	"jungle_grass": Color(0.1, 0.7, 0.1),
	"taiga_grass": Color(0.3, 0.5, 0.3),
	"savanna_grass": Color(0.8, 0.7, 0.3),
	"swamp_grass": Color(0.2, 0.5, 0.2),
	"beach_sand": Color(0.95, 0.9, 0.7),
	"stony_ground": Color(0.6, 0.6, 0.6),
	"mangrove_wood": Color(0.4, 0.2, 0.1),
	"bamboo": Color(0.8, 0.9, 0.3),
	"cactus": Color(0.2, 0.6, 0.2),
	"tree_trunk": Color(0.4, 0.3, 0.2),
	"leaves": Color(0.1, 0.5, 0.1),
	"pine_leaves": Color(0.1, 0.4, 0.1),
	"spruce_leaves": Color(0.05, 0.3, 0.05),
	"birch_leaves": Color(0.3, 0.6, 0.3),
	"jungle_leaves": Color(0.05, 0.6, 0.05),
	"dark_leaves": Color(0.02, 0.3, 0.02),
	"flowers": Color(1.0, 0.8, 0.9),
	"sunflowers": Color(1.0, 0.9, 0.0),
	"lily_pads": Color(0.1, 0.8, 0.1),
	"mushrooms": Color(0.8, 0.2, 0.2),
	"vines": Color(0.1, 0.4, 0.1),
	"dead_bush": Color(0.6, 0.5, 0.3),
	"tall_grass": Color(0.3, 0.7, 0.3),
	"seagrass": Color(0.1, 0.6, 0.1),
	"kelp": Color(0.1, 0.5, 0.1),
	
	# Aquatic blocks
	"coral": Color(1.0, 0.4, 0.4),
	"sea_anemone": Color(0.2, 0.8, 0.2),
	"tube_coral": Color(0.8, 0.2, 0.8),
	"brain_coral": Color(0.8, 0.4, 0.8),
	"bubble_coral": Color(0.8, 0.2, 0.4),
	"fire_coral": Color(0.8, 0.2, 0.2),
	"horn_coral": Color(0.8, 0.6, 0.2),
	"dead_coral": Color(0.6, 0.6, 0.6),
	"coral_fan": Color(1.0, 0.4, 0.4),
	"sea_lantern": Color(0.8, 0.9, 1.0),
	"prismarine": Color(0.2, 0.8, 0.6),
	"dark_prismarine": Color(0.1, 0.6, 0.4),
	"prismarine_bricks": Color(0.2, 0.7, 0.5),
	"sea_urchin": Color(0.9, 0.9, 0.8),
	"sea_sponge": Color(0.8, 0.7, 0.5),
	"seaweed": Color(0.1, 0.5, 0.1),
	"barnacle": Color(0.6, 0.5, 0.4),
	"sea_star": Color(0.8, 0.4, 0.2),
	"jellyfish": Color(0.9, 0.8, 0.9),
	"sea_slug": Color(0.7, 0.3, 0.8),
	"anemone": Color(0.8, 0.2, 0.6),
}

static func get_block_type(x: int, y: int, surface_height: int, biome: BiomeSystem.BIOME_TYPE, world_seed: int, world_height: int, cave_noise: FastNoiseLite) -> String:
	"""Determine block type at given coordinates"""
	if is_cave(x, y, cave_noise, world_height):
		return "air"
	
	if y == surface_height:
		return BiomeSystem.get_surface_block(biome)
	elif y > surface_height:
		if y < surface_height + 5:
			return BiomeSystem.get_sub_surface_block(biome)
		else:
			return get_deep_underground_block(x, y, world_seed, world_height)
	
	return "air"

static func get_deep_underground_block(x: int, y: int, world_seed: int, world_height: int) -> String:
	"""Get underground block type based on depth and noise"""
	# Use noise to determine underground rock types
	var underground_noise = FastNoiseLite.new()
	underground_noise.seed = world_seed + 100
	underground_noise.frequency = 0.1
	
	var noise_value = underground_noise.get_noise_2d(x, y)
	
	# Calculate depth factor for different rock layers
	var depth_factor = float(y) / float(world_height)
	
	# Different rock types at different depths
	if depth_factor > 0.8:  # Deepest layers (bottom 20%)
		if noise_value < -0.6:
			return "obsidian"
		elif noise_value < -0.3:
			return "basalt"
		elif noise_value < 0.0:
			return "granite"
		elif noise_value < 0.3:
			return "gabbro"
		else:
			return "peridotite"
	elif depth_factor > 0.6:  # Deep layers (60-80%)
		if noise_value < -0.5:
			return "basalt"
		elif noise_value < -0.2:
			return "granite"
		elif noise_value < 0.1:
			return "andesite"
		elif noise_value < 0.4:
			return "diorite"
		else:
			return "gabbro"
	elif depth_factor > 0.4:  # Mid layers (40-60%)
		if noise_value < -0.4:
			return "granite"
		elif noise_value < -0.1:
			return "andesite"
		elif noise_value < 0.2:
			return "stone"
		elif noise_value < 0.5:
			return "diorite"
		else:
			return "gneiss"
	else:  # Upper layers (0-40%)
		if noise_value < -0.3:
			return "andesite"
		elif noise_value < 0.0:
			return "stone"
		elif noise_value < 0.3:
			return "diorite"
		elif noise_value < 0.6:
			return "gneiss"
		else:
			return "schist"

static func is_cave(x: int, y: int, cave_noise: FastNoiseLite, world_height: int) -> bool:
	"""Check if a position should be a cave"""
	# Only generate caves below a certain depth
	if y < 100:  # Don't generate caves near surface for deep world
		return false
	
	var cave_value = cave_noise.get_noise_2d(x, y)
	
	# Adjust cave frequency based on depth
	var depth_factor = float(y) / float(world_height)
	var cave_threshold = 0.3 + (depth_factor * 0.2)  # More caves at greater depths
	
	return cave_value > cave_threshold

extends RefCounted
class_name BiomeSystem

# Enhanced biome system with rarity weighting and natural shapes
enum BIOME_TYPE {
	# Common biomes (high frequency, good for starting areas)
	PLAINS,
	FOREST,
	MEADOW,
	
	# Uncommon biomes (medium frequency)
	BIRCH_FOREST,
	TAIGA,
	SAVANNA,
	DESERT,
	SWAMP,
	BEACH,
	GROVE,
	
	# Rare biomes (low frequency)
	SUNFLOWER_PLAINS,
	FLOWER_FOREST,
	OLD_GROWTH_BIRCH_FOREST,
	DARK_FOREST,
	JUNGLE,
	SPARSE_JUNGLE,
	BAMBOO_JUNGLE,
	SNOWY_TAIGA,
	OLD_GROWTH_PINE_TAIGA,
	OLD_GROWTH_SPRUCE_TAIGA,
	SAVANNA_PLATEAU,
	WINDSWEPT_SAVANNA,
	MANGROVE_SWAMP,
	SNOWY_BEACH,
	STONY_SHORE,
	RIVER,
	FROZEN_RIVER,
	SNOWY_PLAINS,
	ICE_SPIKES,
	SNOWY_SLOPES,
	JAGGED_PEAKS,
	FROZEN_PEAKS,
	STONY_PEAKS,
	WINDSWEPT_HILLS,
	WINDSWEPT_FOREST,
	WINDSWEPT_GRAVELLY_HILLS
}

# Biome data with rarity, size, and terrain characteristics
static var BIOME_DATA = {
	# Common biomes - high frequency, good for starting areas
	BIOME_TYPE.PLAINS: {
		"rarity": 0.25,
		"size_multiplier": 1.2,
		"terrain_type": "flat",
		"elevation_variance": 0.1,
		"temperature_range": [-0.2, 0.3],
		"humidity_range": [0.1, 0.4],
		"elevation_range": [0, 20],
		"is_starting_biome": true
	},
	BIOME_TYPE.FOREST: {
		"rarity": 0.20,
		"size_multiplier": 1.0,
		"terrain_type": "hilly",
		"elevation_variance": 0.3,
		"temperature_range": [-0.1, 0.3],
		"humidity_range": [0.4, 0.8],
		"elevation_range": [0, 25],
		"is_starting_biome": true
	},
	BIOME_TYPE.MEADOW: {
		"rarity": 0.15,
		"size_multiplier": 0.8,
		"terrain_type": "flat",
		"elevation_variance": 0.05,
		"temperature_range": [-0.1, 0.2],
		"humidity_range": [0.2, 0.5],
		"elevation_range": [0, 15],
		"is_starting_biome": true
	},
	
	# Uncommon biomes - medium frequency
	BIOME_TYPE.BIRCH_FOREST: {
		"rarity": 0.08,
		"size_multiplier": 0.9,
		"terrain_type": "hilly",
		"elevation_variance": 0.25,
		"temperature_range": [-0.2, 0.2],
		"humidity_range": [0.3, 0.6],
		"elevation_range": [0, 20],
		"is_starting_biome": false
	},
	BIOME_TYPE.TAIGA: {
		"rarity": 0.07,
		"size_multiplier": 1.1,
		"terrain_type": "hilly",
		"elevation_variance": 0.4,
		"temperature_range": [-0.4, -0.1],
		"humidity_range": [0.2, 0.5],
		"elevation_range": [5, 30],
		"is_starting_biome": false
	},
	BIOME_TYPE.SAVANNA: {
		"rarity": 0.06,
		"size_multiplier": 1.3,
		"terrain_type": "flat",
		"elevation_variance": 0.15,
		"temperature_range": [0.3, 0.6],
		"humidity_range": [0.1, 0.3],
		"elevation_range": [0, 25],
		"is_starting_biome": false
	},
	BIOME_TYPE.DESERT: {
		"rarity": 0.05,
		"size_multiplier": 1.5,
		"terrain_type": "flat",
		"elevation_variance": 0.2,
		"temperature_range": [0.5, 0.8],
		"humidity_range": [-0.2, 0.1],
		"elevation_range": [0, 20],
		"is_starting_biome": false
	},
	BIOME_TYPE.SWAMP: {
		"rarity": 0.04,
		"size_multiplier": 0.7,
		"terrain_type": "flat",
		"elevation_variance": 0.1,
		"temperature_range": [0.1, 0.4],
		"humidity_range": [0.6, 0.9],
		"elevation_range": [-5, 10],
		"is_starting_biome": false
	},
	BIOME_TYPE.BEACH: {
		"rarity": 0.03,
		"size_multiplier": 0.5,
		"terrain_type": "flat",
		"elevation_variance": 0.05,
		"temperature_range": [-0.1, 0.4],
		"humidity_range": [0.3, 0.7],
		"elevation_range": [-2, 5],
		"is_starting_biome": false
	},
	BIOME_TYPE.GROVE: {
		"rarity": 0.03,
		"size_multiplier": 0.6,
		"terrain_type": "hilly",
		"elevation_variance": 0.3,
		"temperature_range": [-0.2, 0.1],
		"humidity_range": [0.2, 0.4],
		"elevation_range": [10, 35],
		"is_starting_biome": false
	},
	
	# Rare biomes - low frequency
	BIOME_TYPE.SUNFLOWER_PLAINS: {
		"rarity": 0.02,
		"size_multiplier": 0.8,
		"terrain_type": "flat",
		"elevation_variance": 0.08,
		"temperature_range": [0.0, 0.3],
		"humidity_range": [0.1, 0.3],
		"elevation_range": [0, 15],
		"is_starting_biome": false
	},
	BIOME_TYPE.FLOWER_FOREST: {
		"rarity": 0.015,
		"size_multiplier": 0.6,
		"terrain_type": "hilly",
		"elevation_variance": 0.2,
		"temperature_range": [0.1, 0.4],
		"humidity_range": [0.5, 0.8],
		"elevation_range": [0, 20],
		"is_starting_biome": false
	},
	BIOME_TYPE.DARK_FOREST: {
		"rarity": 0.01,
		"size_multiplier": 0.9,
		"terrain_type": "hilly",
		"elevation_variance": 0.4,
		"temperature_range": [0.0, 0.3],
		"humidity_range": [0.6, 0.9],
		"elevation_range": [0, 25],
		"is_starting_biome": false
	},
	BIOME_TYPE.JUNGLE: {
		"rarity": 0.008,
		"size_multiplier": 1.2,
		"terrain_type": "hilly",
		"elevation_variance": 0.5,
		"temperature_range": [0.4, 0.7],
		"humidity_range": [0.7, 0.9],
		"elevation_range": [0, 30],
		"is_starting_biome": false
	},
	BIOME_TYPE.JAGGED_PEAKS: {
		"rarity": 0.005,
		"size_multiplier": 1.4,
		"terrain_type": "mountain",
		"elevation_variance": 0.8,
		"temperature_range": [-0.8, -0.4],
		"humidity_range": [-0.1, 0.3],
		"elevation_range": [30, 60],
		"is_starting_biome": false
	},
	BIOME_TYPE.FROZEN_PEAKS: {
		"rarity": 0.005,
		"size_multiplier": 1.2,
		"terrain_type": "mountain",
		"elevation_variance": 0.7,
		"temperature_range": [-0.9, -0.5],
		"humidity_range": [0.0, 0.4],
		"elevation_range": [35, 65],
		"is_starting_biome": false
	},
	BIOME_TYPE.ICE_SPIKES: {
		"rarity": 0.003,
		"size_multiplier": 0.8,
		"terrain_type": "flat",
		"elevation_variance": 0.3,
		"temperature_range": [-0.8, -0.5],
		"humidity_range": [0.1, 0.4],
		"elevation_range": [0, 20],
		"is_starting_biome": false
	}
}

# Biome clustering and generation system
static var biome_clusters: Dictionary = {}
static var biome_noise: FastNoiseLite
static var cluster_noise: FastNoiseLite

static func initialize_biome_system(world_seed: int) -> void:
	"""Initialize the biome system with noise generators for clustering"""
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = world_seed + 1000
	biome_noise.frequency = 0.005  # Large biome areas
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	cluster_noise = FastNoiseLite.new()
	cluster_noise.seed = world_seed + 2000
	cluster_noise.frequency = 0.01  # Medium cluster areas
	cluster_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	biome_clusters.clear()

static func get_biome(x: int, temperature: float, humidity: float, elevation: int, is_starting_area: bool = false) -> BIOME_TYPE:
	"""Enhanced biome selection with rarity weighting, clustering, and starting area guarantees"""
	
	# Safety check - ensure biome system is initialized
	if not biome_noise or not cluster_noise:
		print("WARNING: Biome system not initialized, using fallback biome selection")
		return _select_biome_by_conditions(temperature, humidity, elevation)
	
	# For starting areas, force common biomes
	if is_starting_area:
		return _get_starting_biome(x, temperature, humidity, elevation)
	
	# Get biome cluster for this area
	var cluster_id = _get_biome_cluster(x)
	
	# If we have a cluster, use it with some variation
	if cluster_id in biome_clusters:
		var cluster_biome = biome_clusters[cluster_id]
		
		# Safety check for biome_noise
		var variation_chance = 0.5  # Default variation chance
		if biome_noise:
			variation_chance = biome_noise.get_noise_1d(x * 0.1)
		
		# 20% chance to break out of cluster for natural variation
		if variation_chance > 0.8:
			return _select_biome_by_conditions(temperature, humidity, elevation)
		else:
			return cluster_biome
	
	# No cluster exists, create one
	var selected_biome = _select_biome_by_conditions(temperature, humidity, elevation)
	biome_clusters[cluster_id] = selected_biome
	return selected_biome

static func _get_starting_biome(x: int, temperature: float, humidity: float, elevation: int) -> BIOME_TYPE:
	"""Get a biome suitable for starting areas (common, flat biomes)"""
	var starting_biomes = []
	
	# Find all starting biomes that match current conditions
	for biome_type in BIOME_DATA:
		var data = BIOME_DATA[biome_type]
		if not data.is_starting_biome:
			continue
			
		# Check if conditions match
		if _conditions_match_biome(temperature, humidity, elevation, data):
			starting_biomes.append(biome_type)
	
	# If no starting biomes match, default to plains
	if starting_biomes.is_empty():
		return BIOME_TYPE.PLAINS
	
	# Use deterministic selection based on position
	var index = abs(x) % starting_biomes.size()
	return starting_biomes[index]

static func _get_biome_cluster(x: int) -> int:
	"""Get cluster ID for biome clustering"""
	# Safety check - ensure cluster noise is initialized
	if not cluster_noise:
		print("WARNING: cluster_noise not initialized, using fallback clustering")
		return int(x / 100)  # Simple fallback based on position
	
	# Use cluster noise to determine cluster boundaries
	var cluster_value = cluster_noise.get_noise_1d(x * 0.01)
	return int(cluster_value * 1000)  # Convert to integer cluster ID

static func _select_biome_by_conditions(temperature: float, humidity: float, elevation: int) -> BIOME_TYPE:
	"""Select biome based on environmental conditions with rarity weighting"""
	var candidate_biomes = []
	var total_weight = 0.0
	
	# Find all biomes that match current conditions
	for biome_type in BIOME_DATA:
		var data = BIOME_DATA[biome_type]
		if _conditions_match_biome(temperature, humidity, elevation, data):
			var weight = data.rarity
			candidate_biomes.append({"biome": biome_type, "weight": weight})
			total_weight += weight
	
	# If no biomes match, fallback to plains
	if candidate_biomes.is_empty():
		return BIOME_TYPE.PLAINS
	
	# Weighted random selection
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for candidate in candidate_biomes:
		current_weight += candidate.weight
		if random_value <= current_weight:
			return candidate.biome
	
	# Fallback
	return candidate_biomes[0].biome

static func _conditions_match_biome(temperature: float, humidity: float, elevation: int, biome_data: Dictionary) -> bool:
	"""Check if environmental conditions match a biome's requirements"""
	var temp_range = biome_data.temperature_range
	var humidity_range = biome_data.humidity_range
	var elevation_range = biome_data.elevation_range
	
	return (temperature >= temp_range[0] and temperature <= temp_range[1] and
			humidity >= humidity_range[0] and humidity <= humidity_range[1] and
			elevation >= elevation_range[0] and elevation <= elevation_range[1])

# Legacy function for backward compatibility (overloaded)
static func get_biome_legacy(temperature: float, humidity: float, elevation: int) -> BIOME_TYPE:
	"""Legacy biome selection - redirects to new system"""
	return _select_biome_by_conditions(temperature, humidity, elevation)

static func get_biome_data(biome: BIOME_TYPE) -> Dictionary:
	"""Get biome data including rarity, size, and terrain characteristics"""
	if biome in BIOME_DATA:
		return BIOME_DATA[biome]
	else:
		# Fallback data for unknown biomes
		return {
			"rarity": 0.01,
			"size_multiplier": 1.0,
			"terrain_type": "flat",
			"elevation_variance": 0.2,
			"temperature_range": [-0.5, 0.5],
			"humidity_range": [0.0, 1.0],
			"elevation_range": [0, 50],
			"is_starting_biome": false
		}

static func get_terrain_type(biome: BIOME_TYPE) -> String:
	"""Get the terrain type for a biome (flat, hilly, mountain)"""
	var data = get_biome_data(biome)
	return data.terrain_type

static func get_elevation_variance(biome: BIOME_TYPE) -> float:
	"""Get the elevation variance for a biome (0.0 = flat, 1.0 = very rugged)"""
	var data = get_biome_data(biome)
	return data.elevation_variance

static func get_size_multiplier(biome: BIOME_TYPE) -> float:
	"""Get the size multiplier for a biome (affects biome area size)"""
	var data = get_biome_data(biome)
	return data.size_multiplier

static func is_starting_biome(biome: BIOME_TYPE) -> bool:
	"""Check if a biome is suitable for starting areas"""
	var data = get_biome_data(biome)
	return data.is_starting_biome

static func get_biome_name(biome: BIOME_TYPE) -> String:
	"""Get the display name for a biome type"""
	match biome:
		BIOME_TYPE.PLAINS: return "Plains"
		BIOME_TYPE.SUNFLOWER_PLAINS: return "Sunflower Plains"
		BIOME_TYPE.FOREST: return "Forest"
		BIOME_TYPE.FLOWER_FOREST: return "Flower Forest"
		BIOME_TYPE.BIRCH_FOREST: return "Birch Forest"
		BIOME_TYPE.OLD_GROWTH_BIRCH_FOREST: return "Old Growth Birch Forest"
		BIOME_TYPE.DARK_FOREST: return "Dark Forest"
		BIOME_TYPE.JUNGLE: return "Jungle"
		BIOME_TYPE.SPARSE_JUNGLE: return "Sparse Jungle"
		BIOME_TYPE.BAMBOO_JUNGLE: return "Bamboo Jungle"
		BIOME_TYPE.TAIGA: return "Taiga"
		BIOME_TYPE.SNOWY_TAIGA: return "Snowy Taiga"
		BIOME_TYPE.OLD_GROWTH_PINE_TAIGA: return "Old Growth Pine Taiga"
		BIOME_TYPE.OLD_GROWTH_SPRUCE_TAIGA: return "Old Growth Spruce Taiga"
		BIOME_TYPE.SAVANNA: return "Savanna"
		BIOME_TYPE.SAVANNA_PLATEAU: return "Savanna Plateau"
		BIOME_TYPE.WINDSWEPT_SAVANNA: return "Windswept Savanna"
		BIOME_TYPE.DESERT: return "Desert"
		BIOME_TYPE.SWAMP: return "Swamp"
		BIOME_TYPE.MANGROVE_SWAMP: return "Mangrove Swamp"
		BIOME_TYPE.BEACH: return "Beach"
		BIOME_TYPE.SNOWY_BEACH: return "Snowy Beach"
		BIOME_TYPE.STONY_SHORE: return "Stony Shore"
		BIOME_TYPE.RIVER: return "River"
		BIOME_TYPE.FROZEN_RIVER: return "Frozen River"
		BIOME_TYPE.SNOWY_PLAINS: return "Snowy Plains"
		BIOME_TYPE.ICE_SPIKES: return "Ice Spikes"
		BIOME_TYPE.SNOWY_SLOPES: return "Snowy Slopes"
		BIOME_TYPE.GROVE: return "Grove"
		BIOME_TYPE.JAGGED_PEAKS: return "Jagged Peaks"
		BIOME_TYPE.FROZEN_PEAKS: return "Frozen Peaks"
		BIOME_TYPE.STONY_PEAKS: return "Stony Peaks"
		BIOME_TYPE.WINDSWEPT_HILLS: return "Windswept Hills"
		BIOME_TYPE.WINDSWEPT_FOREST: return "Windswept Forest"
		BIOME_TYPE.WINDSWEPT_GRAVELLY_HILLS: return "Windswept Gravelly Hills"
		BIOME_TYPE.MEADOW: return "Meadow"
		_: return "Unknown"

static func get_surface_block(biome: BIOME_TYPE) -> String:
	"""Get the surface block type for a biome"""
	match biome:
		BIOME_TYPE.PLAINS, BIOME_TYPE.MEADOW:
			return "grass"
		BIOME_TYPE.SUNFLOWER_PLAINS:
			return "sunflower_grass"
		BIOME_TYPE.FOREST, BIOME_TYPE.FLOWER_FOREST:
			return "forest_grass"
		BIOME_TYPE.BIRCH_FOREST, BIOME_TYPE.OLD_GROWTH_BIRCH_FOREST:
			return "birch_leaves"
		BIOME_TYPE.DARK_FOREST:
			return "dark_forest_grass"
		BIOME_TYPE.JUNGLE, BIOME_TYPE.SPARSE_JUNGLE, BIOME_TYPE.BAMBOO_JUNGLE:
			return "jungle_grass"
		BIOME_TYPE.TAIGA, BIOME_TYPE.SNOWY_TAIGA, BIOME_TYPE.OLD_GROWTH_PINE_TAIGA, BIOME_TYPE.OLD_GROWTH_SPRUCE_TAIGA:
			return "taiga_grass"
		BIOME_TYPE.SAVANNA, BIOME_TYPE.SAVANNA_PLATEAU, BIOME_TYPE.WINDSWEPT_SAVANNA:
			return "savanna_grass"
		BIOME_TYPE.DESERT:
			return "sand"
		BIOME_TYPE.SWAMP, BIOME_TYPE.MANGROVE_SWAMP:
			return "swamp_grass"
		BIOME_TYPE.BEACH:
			return "beach_sand"
		BIOME_TYPE.SNOWY_BEACH:
			return "snow"
		BIOME_TYPE.STONY_SHORE, BIOME_TYPE.WINDSWEPT_GRAVELLY_HILLS:
			return "gravel"
		BIOME_TYPE.SNOWY_PLAINS, BIOME_TYPE.ICE_SPIKES, BIOME_TYPE.SNOWY_SLOPES:
			return "snow"
		BIOME_TYPE.JAGGED_PEAKS, BIOME_TYPE.FROZEN_PEAKS, BIOME_TYPE.STONY_PEAKS:
			return "stone"
		BIOME_TYPE.WINDSWEPT_HILLS, BIOME_TYPE.WINDSWEPT_FOREST:
			return "grass"
		BIOME_TYPE.RIVER, BIOME_TYPE.FROZEN_RIVER:
			return "water"
		_:
			return "grass"

static func get_sub_surface_block(biome: BIOME_TYPE) -> String:
	"""Get the subsurface block type for a biome"""
	match biome:
		BIOME_TYPE.DESERT, BIOME_TYPE.BEACH, BIOME_TYPE.SNOWY_BEACH:
			return "sand"
		BIOME_TYPE.STONY_SHORE, BIOME_TYPE.WINDSWEPT_GRAVELLY_HILLS, BIOME_TYPE.JAGGED_PEAKS, BIOME_TYPE.FROZEN_PEAKS, BIOME_TYPE.STONY_PEAKS:
			return "gravel"
		BIOME_TYPE.SNOWY_PLAINS, BIOME_TYPE.ICE_SPIKES, BIOME_TYPE.SNOWY_SLOPES:
			return "dirt"
		BIOME_TYPE.SWAMP, BIOME_TYPE.MANGROVE_SWAMP:
			return "mud"
		BIOME_TYPE.JAGGED_PEAKS, BIOME_TYPE.FROZEN_PEAKS, BIOME_TYPE.STONY_PEAKS:
			return "basalt"
		_:
			return "dirt"

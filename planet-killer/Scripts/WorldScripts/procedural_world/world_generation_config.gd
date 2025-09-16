extends RefCounted
class_name WorldGenerationConfig

# Configurable world generation parameters
# This class allows adjusting world generation settings without modifying code

# Biome generation settings
var biome_rarity_multiplier: float = 1.0  # Multiplier for all biome rarities
var biome_size_multiplier: float = 1.0    # Multiplier for all biome sizes
var biome_clustering_strength: float = 0.8  # How strongly biomes cluster (0.0 = no clustering, 1.0 = maximum clustering)
var cluster_variation_chance: float = 0.2   # Chance to break out of clusters (0.0 = no variation, 1.0 = always vary)

# Terrain generation settings
var terrain_detail_strength: float = 1.0   # Strength of terrain detail noise
var mountain_strength: float = 1.0         # Strength of mountain generation
var valley_strength: float = 1.0           # Strength of valley generation
var elevation_range_multiplier: float = 1.0 # Multiplier for elevation ranges

# Starting area settings
var starting_area_size: int = 2            # Radius of starting area in chunks (2 = 5x5 chunks)
var starting_area_flatness: float = 1.0    # How flat starting areas are (1.0 = completely flat)
var starting_area_elevation: int = 100     # Fixed elevation for starting areas

# World size and performance settings
var chunk_size: int = 64                   # Size of each chunk in blocks
var world_height: int = 1200               # Total world height in blocks
var initial_chunks_range: int = 1          # Initial chunks to generate around spawn

# Noise settings
var elevation_noise_frequency: float = 0.01
var temperature_noise_frequency: float = 0.02
var humidity_noise_frequency: float = 0.015
var cave_noise_frequency: float = 0.05
var terrain_detail_frequency: float = 0.1
var mountain_noise_frequency: float = 0.003
var valley_noise_frequency: float = 0.008

# Biome-specific overrides
var biome_overrides: Dictionary = {}       # Override specific biome settings

# Default configuration
static var default_config: WorldGenerationConfig

static func get_default_config() -> WorldGenerationConfig:
	"""Get the default world generation configuration"""
	if not default_config:
		default_config = WorldGenerationConfig.new()
	return default_config

func apply_to_biome_system() -> void:
	"""Apply configuration settings to the biome system"""
	# Apply biome rarity multipliers
	for biome_type in BiomeSystem.BIOME_DATA:
		var data = BiomeSystem.BIOME_DATA[biome_type]
		data.rarity *= biome_rarity_multiplier
		data.size_multiplier *= biome_size_multiplier
		
		# Apply biome-specific overrides
		if biome_type in biome_overrides:
			var override = biome_overrides[biome_type]
			for key in override:
				if key in data:
					data[key] = override[key]

func apply_to_noise_generator(noise_gen: NoiseGenerator) -> void:
	"""Apply configuration settings to the noise generator"""
	if noise_gen.elevation_noise:
		noise_gen.elevation_noise.frequency = elevation_noise_frequency
	if noise_gen.temperature_noise:
		noise_gen.temperature_noise.frequency = temperature_noise_frequency
	if noise_gen.humidity_noise:
		noise_gen.humidity_noise.frequency = humidity_noise_frequency
	if noise_gen.cave_noise:
		noise_gen.cave_noise.frequency = cave_noise_frequency
	if noise_gen.terrain_detail_noise:
		noise_gen.terrain_detail_noise.frequency = terrain_detail_frequency
	if noise_gen.mountain_noise:
		noise_gen.mountain_noise.frequency = mountain_noise_frequency
	if noise_gen.valley_noise:
		noise_gen.valley_noise.frequency = valley_noise_frequency

func is_starting_area(chunk_x: int, chunk_y: int) -> bool:
	"""Check if a chunk is in the starting area based on configuration"""
	return abs(chunk_x) <= starting_area_size and abs(chunk_y) <= starting_area_size

func get_starting_area_elevation() -> int:
	"""Get the elevation for starting areas"""
	return starting_area_elevation

func get_terrain_multiplier(terrain_type: String) -> float:
	"""Get the terrain strength multiplier for a specific terrain type"""
	match terrain_type:
		"flat":
			return terrain_detail_strength
		"hilly":
			return terrain_detail_strength * 0.8 + valley_strength * 0.2
		"mountain":
			return mountain_strength
		_:
			return 1.0

# Configuration presets
static func create_preset(preset_name: String) -> WorldGenerationConfig:
	"""Create a configuration preset"""
	var config = WorldGenerationConfig.new()
	
	match preset_name:
		"default":
			# Use default values
			pass
		"flat_world":
			config.terrain_detail_strength = 0.1
			config.mountain_strength = 0.1
			config.valley_strength = 0.1
			config.elevation_range_multiplier = 0.3
		"mountainous":
			config.terrain_detail_strength = 1.5
			config.mountain_strength = 2.0
			config.valley_strength = 1.2
			config.elevation_range_multiplier = 1.5
		"varied":
			config.biome_clustering_strength = 0.5
			config.cluster_variation_chance = 0.4
			config.terrain_detail_strength = 1.2
		"performance":
			config.chunk_size = 32
			config.initial_chunks_range = 0
			config.terrain_detail_strength = 0.5
		"creative":
			config.starting_area_size = 5
			config.starting_area_flatness = 1.0
			config.biome_clustering_strength = 0.3
	
	return config

# Save/load configuration
func save_to_file(file_path: String) -> bool:
	"""Save configuration to a file"""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false
	
	var config_data = {
		"biome_rarity_multiplier": biome_rarity_multiplier,
		"biome_size_multiplier": biome_size_multiplier,
		"biome_clustering_strength": biome_clustering_strength,
		"cluster_variation_chance": cluster_variation_chance,
		"terrain_detail_strength": terrain_detail_strength,
		"mountain_strength": mountain_strength,
		"valley_strength": valley_strength,
		"elevation_range_multiplier": elevation_range_multiplier,
		"starting_area_size": starting_area_size,
		"starting_area_flatness": starting_area_flatness,
		"starting_area_elevation": starting_area_elevation,
		"chunk_size": chunk_size,
		"world_height": world_height,
		"initial_chunks_range": initial_chunks_range,
		"elevation_noise_frequency": elevation_noise_frequency,
		"temperature_noise_frequency": temperature_noise_frequency,
		"humidity_noise_frequency": humidity_noise_frequency,
		"cave_noise_frequency": cave_noise_frequency,
		"terrain_detail_frequency": terrain_detail_frequency,
		"mountain_noise_frequency": mountain_noise_frequency,
		"valley_noise_frequency": valley_noise_frequency,
		"biome_overrides": biome_overrides
	}
	
	file.store_string(JSON.stringify(config_data, "\t"))
	file.close()
	return true

func load_from_file(file_path: String) -> bool:
	"""Load configuration from a file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return false
	
	var config_data = json.data
	if not config_data is Dictionary:
		return false
	
	# Load configuration values
	biome_rarity_multiplier = config_data.get("biome_rarity_multiplier", 1.0)
	biome_size_multiplier = config_data.get("biome_size_multiplier", 1.0)
	biome_clustering_strength = config_data.get("biome_clustering_strength", 0.8)
	cluster_variation_chance = config_data.get("cluster_variation_chance", 0.2)
	terrain_detail_strength = config_data.get("terrain_detail_strength", 1.0)
	mountain_strength = config_data.get("mountain_strength", 1.0)
	valley_strength = config_data.get("valley_strength", 1.0)
	elevation_range_multiplier = config_data.get("elevation_range_multiplier", 1.0)
	starting_area_size = config_data.get("starting_area_size", 2)
	starting_area_flatness = config_data.get("starting_area_flatness", 1.0)
	starting_area_elevation = config_data.get("starting_area_elevation", 100)
	chunk_size = config_data.get("chunk_size", 64)
	world_height = config_data.get("world_height", 1200)
	initial_chunks_range = config_data.get("initial_chunks_range", 1)
	elevation_noise_frequency = config_data.get("elevation_noise_frequency", 0.01)
	temperature_noise_frequency = config_data.get("temperature_noise_frequency", 0.02)
	humidity_noise_frequency = config_data.get("humidity_noise_frequency", 0.015)
	cave_noise_frequency = config_data.get("cave_noise_frequency", 0.05)
	terrain_detail_frequency = config_data.get("terrain_detail_frequency", 0.1)
	mountain_noise_frequency = config_data.get("mountain_noise_frequency", 0.003)
	valley_noise_frequency = config_data.get("valley_noise_frequency", 0.008)
	biome_overrides = config_data.get("biome_overrides", {})
	
	return true

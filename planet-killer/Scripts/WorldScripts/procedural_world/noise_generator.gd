extends RefCounted
class_name NoiseGenerator

# Noise objects for different world features
var elevation_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var humidity_noise: FastNoiseLite
var cave_noise: FastNoiseLite

# Additional noise for terrain shaping
var terrain_detail_noise: FastNoiseLite
var mountain_noise: FastNoiseLite
var valley_noise: FastNoiseLite

func setup_noise(world_seed: int) -> void:
	"""Set up noise generators for world generation"""
	print("Setting up noise generators...")
	
	# Elevation noise (controls surface height)
	elevation_noise = FastNoiseLite.new()
	elevation_noise.seed = world_seed
	elevation_noise.frequency = 0.01
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Temperature noise (controls biomes)
	temperature_noise = FastNoiseLite.new()
	temperature_noise.seed = world_seed + 1
	temperature_noise.frequency = 0.02  # Higher frequency for more variation
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Humidity noise (controls humidity)
	humidity_noise = FastNoiseLite.new()
	humidity_noise.seed = world_seed + 2
	humidity_noise.frequency = 0.015
	humidity_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Cave noise (for underground caves)
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = world_seed + 3
	cave_noise.frequency = 0.05
	cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Terrain detail noise (for fine terrain features)
	terrain_detail_noise = FastNoiseLite.new()
	terrain_detail_noise.seed = world_seed + 4
	terrain_detail_noise.frequency = 0.1
	terrain_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Mountain noise (for mountain ranges)
	mountain_noise = FastNoiseLite.new()
	mountain_noise.seed = world_seed + 5
	mountain_noise.frequency = 0.003
	mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Valley noise (for valleys and depressions)
	valley_noise = FastNoiseLite.new()
	valley_noise.seed = world_seed + 6
	valley_noise.frequency = 0.008
	valley_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	print("Noise generators configured:")
	print("  Elevation noise seed: ", elevation_noise.seed)
	print("  Temperature noise seed: ", temperature_noise.seed)
	print("  Humidity noise seed: ", humidity_noise.seed)
	print("  Cave noise seed: ", cave_noise.seed)
	print("  Terrain detail noise seed: ", terrain_detail_noise.seed)
	print("  Mountain noise seed: ", mountain_noise.seed)
	print("  Valley noise seed: ", valley_noise.seed)

func get_elevation(x: int, biome: BiomeSystem.BIOME_TYPE = BiomeSystem.BIOME_TYPE.PLAINS, is_starting_area: bool = false, world_config: WorldGenerationConfig = null) -> int:
	"""Get elevation at given X coordinate with biome-specific terrain shaping"""
	
	# For starting areas, ensure superflat terrain
	if is_starting_area:
		if world_config:
			return world_config.get_starting_area_elevation()
		else:
			return 100  # Default fixed elevation for starting areas
	
	# Get base elevation from main noise
	var base_noise = elevation_noise.get_noise_1d(x)
	var base_elevation = remap(base_noise, -1.0, 1.0, 50, 150)
	
	# Get biome data for terrain shaping
	var biome_data = BiomeSystem.get_biome_data(biome)
	var terrain_type = biome_data.terrain_type
	var elevation_variance = biome_data.elevation_variance
	
	# Apply biome-specific terrain shaping
	var final_elevation = base_elevation
	
	match terrain_type:
		"flat":
			# Flat biomes: reduce elevation variance significantly
			var detail_noise = terrain_detail_noise.get_noise_1d(x) * 0.1
			final_elevation += detail_noise * elevation_variance * 10
			
		"hilly":
			# Hilly biomes: moderate elevation variance
			var detail_noise = terrain_detail_noise.get_noise_1d(x)
			var valley_effect = valley_noise.get_noise_1d(x * 0.5) * 0.3
			final_elevation += (detail_noise + valley_effect) * elevation_variance * 20
			
		"mountain":
			# Mountain biomes: high elevation variance with mountain ranges
			var mountain_effect = mountain_noise.get_noise_1d(x) * 0.8
			var detail_noise = terrain_detail_noise.get_noise_1d(x * 2) * 0.4
			final_elevation += (mountain_effect + detail_noise) * elevation_variance * 40
			
			# Ensure mountains are actually elevated
			if mountain_effect > 0.3:
				final_elevation += 30
			elif mountain_effect > 0.1:
				final_elevation += 15
	
	# Clamp elevation to reasonable bounds
	final_elevation = clamp(final_elevation, 20, 200)
	
	return int(final_elevation)

func get_temperature(x: int) -> float:
	"""Get temperature at given X coordinate"""
	return temperature_noise.get_noise_1d(x)

func get_humidity(x: int) -> float:
	"""Get humidity at given X coordinate"""
	return humidity_noise.get_noise_1d(x)

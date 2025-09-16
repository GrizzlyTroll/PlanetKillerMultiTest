extends Node2D
class_name PlayerSpawner

# Player scene reference (like Unity's Prefab)
var player_scene: PackedScene

# Spawn parameters
var spawn_position: Vector2 = Vector2.ZERO
var spawn_offset: Vector2 = Vector2(0, -50)  # Spawn slightly above ground

func _ready() -> void:
	# Load the player scene
	player_scene = load("res://Scenes/PlayerStuff/Player.tscn")
	if not player_scene:
		print("ERROR: Could not load player scene!")

func spawn_player_at_position(position: Vector2) -> Node2D:
	"""Spawn the original player at a specific position"""
	if not player_scene:
		print("ERROR: Player scene not loaded!")
		return null
	
	# Instance the player
	var player = player_scene.instantiate()
	player.name = "Player"
	player.position = position + spawn_offset
	
	# Add to scene
	add_child(player)
	print("Player spawned at: ", player.position)
	
	return player

func spawn_player_at_world_coords(world_x: int, world_y: int, block_size: int = 8) -> Node2D:
	"""Spawn player at world coordinates (like tile coordinates)"""
	var world_position = Vector2(world_x * block_size, world_y * block_size)
	return spawn_player_at_position(world_position)

func spawn_player_above_surface(surface_x: int, surface_y: int, block_size: int = 8) -> Node2D:
	"""Spawn player above the surface at given coordinates"""
	var spawn_x = surface_x
	var spawn_y = surface_y - 3  # 3 blocks above surface
	return spawn_player_at_world_coords(spawn_x, spawn_y, block_size)

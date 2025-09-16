extends Node2D

@export var block: Dictionary[String, BlockData]
@export var player: CharacterBody2D

@onready var ground = $Ground

var broken_tiles_health: Dictionary
var distance: float = INF

func _physics_process(delta: float) -> void:
	if player:
		distance = (get_global_mouse_position() - player.position).length()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var tile_pos = get_snapped_position(get_global_mouse_position())
		
		if event.button_index == MOUSE_BUTTON_LEFT and distance < 25:
			var data = ground.get_cell_tile_data(tile_pos)
			var tile_name
			if data:
				tile_name = data.get_custom_data("tile_name")
				take_damage(tile_name,tile_pos)

func get_snapped_position(global_pos: Vector2) -> Vector2:
	var local_pos = ground.to_local(global_pos)
	var tile_pos = ground.local_to_map(local_pos)
	return tile_pos

func take_damage(tile_name:StringName,tile_pos:Vector2i,amount:float=1):
	if tile_pos not in broken_tiles_health:
		broken_tiles_health[tile_pos] = block[tile_name].health - amount
	else:
		broken_tiles_health[tile_pos] -= amount
	
	var difference = block[tile_name].health - broken_tiles_health[tile_pos]
	var next_tile: Vector2i
	
	if difference >= block[tile_name].health:
		ground.erase_cell(tile_pos)
		broken_tiles_health.erase(tile_pos)
	elif difference < block[tile_name].atlas_coords.size():
		next_tile = block[tile_name].atlas_coords[difference]
		ground.set_cell(tile_pos, block[tile_name].source_id, next_tile)

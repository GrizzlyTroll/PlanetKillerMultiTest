extends Area2D

@export var grass_layer_path: NodePath
@export var clay_layer_path: NodePath
@export var dirt_layer_path: NodePath
@export var tip_path: NodePath			   # drag your Tip (Marker2D) here
@export var step_pixels: int = 6
@export var drill_action: String = "Dig"
@onready var origin_local: Vector2 = position
@onready var grass_layer: TileMapLayer = get_node_or_null(grass_layer_path)
@onready var clay_layer: TileMapLayer  = get_node_or_null(clay_layer_path)
@onready var dirt_layer: TileMapLayer  = get_node_or_null(dirt_layer_path)
@onready var tip: Marker2D = get_node_or_null(tip_path)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var origin_global: Vector2 = global_position
var input_armed := false

# Direction variables
var current_direction := 0  # 0=down, 1=right, 2=up, 3=left
var direction_vectors := [Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)]


func _ready() -> void:
	# Fallback auto-binding if paths are unset on the instance
	if grass_layer == null or clay_layer == null or dirt_layer == null:
		var parent_node := get_parent()
		if parent_node and parent_node.get_parent():
			var world := parent_node.get_parent()
			grass_layer = grass_layer if grass_layer != null else world.get_node_or_null("Grass")
			clay_layer = clay_layer if clay_layer != null else world.get_node_or_null("Clay")
			dirt_layer = dirt_layer if dirt_layer != null else world.get_node_or_null("Dirt")

func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("BringDrillToOrigin"):
		bring_to_origin()
	
	if not input_armed:
		input_armed = true
		sprite.play("Empty")
		return
	
	
	if Input.is_action_just_pressed("ChangeDrillDirection"):
		print("ChangeDrillDirection pressed!")  # Debug print
		update_direction()
	
	if Input.is_action_just_pressed(drill_action):
		var start_pos := position
		position += direction_vectors[current_direction] * step_pixels
		if _break_one_tile_at_tip():
			#position = origin_local  # or start_pos if you prefer
			sprite.play("Empty")
	
func bring_to_origin() -> void:
	position = origin_local

func update_direction() -> void:
	current_direction = (current_direction + 1) % 4
	rotation_degrees = current_direction * 90  # Rotate 90 degrees for each direction
	print("Drill direction: ", current_direction, " rotation: ", rotation_degrees)

func _break_one_tile_at_tip() -> bool:
	var world_pos: Vector2 = tip.global_position if tip != null else global_position
	for _layer in [grass_layer, clay_layer, dirt_layer]:
		var layer := _layer as TileMapLayer
		if layer == null:
			continue
		var local_pos: Vector2 = layer.to_local(world_pos)
		var cell: Vector2i = layer.local_to_map(local_pos)
		
		# Check if there's any tile data at this position
		var tile_data = layer.get_cell_tile_data(cell)
		if tile_data != null or layer.get_cell_source_id(cell) != -1 or layer.get_cell_atlas_coords(cell) != Vector2i(-1, -1):
			layer.erase_cell(cell)
			return true
	return false

extends TileMapLayer

# Dictionary to store health for each tree tile
var tree_health: Dictionary = {}
var max_tree_health: int = 8

# Reference to your wood plank item
#var wood_plank_scene = preload("res://inventory/items/WoodPlank.tres")

func _ready():
	# Connect to your axe's hit signal (you'll need to create this)
	# axe.connect("tree_hit", _on_axe_hit_tree)
	pass

func _on_axe_hit_tree(position: Vector2):
	var cell = local_to_map(position)
	var tree_tile = get_cell_source_id(cell)  # Fixed: layer first, then cell
	
	# Check if there's a tree at this position
	if tree_tile != -1:
		# Initialize health if this tree hasn't been hit before
		if not tree_health.has(cell):
			tree_health[cell] = max_tree_health
		
		# Reduce tree health
		tree_health[cell] -= 1
		
		# Check if tree is destroyed
		if tree_health[cell] <= 0:
			# Remove the tree tile
			erase_cell(cell)  # Fixed: layer first, then cell
			
			# Drop wood planks
			#drop_wood_planks(position)
			
			# Clean up health data
			tree_health.erase(cell)

#func drop_wood_planks(position: Vector2):
	## Create wood plank item at the tree position
	#var wood_plank = wood_plank_scene.duplicate()
	#wood_plank.position = position
	#
	## Add to your inventory or drop on ground
	## You'll need to connect this to your inventory system
	#if get_parent().has_method("add_item_to_inventory"):
		#get_parent().add_item_to_inventory(wood_plank)
	## If no inventory method, the item is dropped on ground

# Optional: Visual feedback when tree is hit
func _on_tree_hit_visual(cell: Vector2i):
	# You could add a hit animation or sound here
	pass

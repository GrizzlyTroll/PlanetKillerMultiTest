extends Node

# Parallax system using CanvasLayer (recommended in Godot 4.4)
# This approach doesn't affect the viewport or UI

var parallax_layers: Array[CanvasLayer] = []
var cloud_sprites: Array[Sprite2D] = []
var cloud_speeds: Array[float] = []
var screen_width: float = 1280.0

func _ready():
	# Wait for the scene tree to be ready before creating parallax layers
	await get_tree().process_frame
	# Parallax layers will be created when we detect the game scene
	
func create_parallax_layers():
	"""Create parallax layers using CanvasLayer instead of ParallaxBackground"""
	print("Creating parallax layers...")
	
	# Create cloud layer for moving clouds
	var cloud_layer = CanvasLayer.new()
	cloud_layer.layer = -5  # Behind game world
	cloud_layer.follow_viewport_enabled = true
	get_tree().root.add_child(cloud_layer)
	parallax_layers.append(cloud_layer)
	print("Created cloud layer")
	
	# Move existing cloud sprites to our CanvasLayer system
	migrate_existing_clouds()
	
func migrate_existing_clouds():
	"""Move existing cloud sprites from ParallaxBackground to CanvasLayer"""
	print("Migrating existing clouds...")
	var scene_name: String
	if get_tree().current_scene:
		scene_name = get_tree().current_scene.name
	else:
		scene_name = "No scene"
	print("Current scene: ", scene_name)
	var world = get_tree().current_scene.get_node_or_null("World")
	if not world:
		print("World node not found!")
		return
		
	var day_parallax = world.get_node_or_null("DAY")
	if not day_parallax:
		print("DAY ParallaxBackground not found!")
		return
	
	# Find and move ONLY cloud sprites (not sky or sun)
	for child in day_parallax.get_children():
		if child is ParallaxLayer:
			var layer_name = child.name
			
			# Only move cloud layers, not sky or sun
			if "BlueClouds" in layer_name or "WhiteClouds" in layer_name:
				var target_layer = parallax_layers[0]  # cloud_layer (index 0 since we only have one layer)
				
				for sprite in child.get_children():
					if sprite is Sprite2D:
						# Remove from ParallaxLayer and add to CanvasLayer
						child.remove_child(sprite)
						target_layer.add_child(sprite)
						
						# Set up parallax movement
						cloud_sprites.append(sprite)
						
						# Set different speeds based on layer
						var speed = 0.5
						if "BlueClouds" in layer_name:
							speed = 0.3  # Blue clouds medium
						elif "WhiteClouds" in layer_name:
							speed = 0.5  # White clouds faster
						
						cloud_speeds.append(speed)
						print("Migrated cloud: ", sprite.name, " to CanvasLayer with speed: ", speed)
	
	# Hide only the cloud layers we moved, keep sky and sun visible
	for child in day_parallax.get_children():
		if child is ParallaxLayer:
			var layer_name = child.name
			if "BlueClouds" in layer_name or "WhiteClouds" in layer_name:
				child.visible = false  # Hide only the cloud layers

func _process(delta):
	"""Update cloud positions for parallax effect"""
	# Check if we're in the game scene and haven't created layers yet
	if get_tree().current_scene and get_tree().current_scene.name == "Game" and parallax_layers.size() == 0:
		print("Detected Game scene - creating parallax layers")
		create_parallax_layers()
	
	# Update cloud positions for parallax effect
	for i in range(cloud_sprites.size()):
		var cloud = cloud_sprites[i]
		var speed = cloud_speeds[i]
		
		# Move cloud to the left
		cloud.position.x -= speed * delta * 50
		
		# Wrap cloud around when it goes off screen
		if cloud.position.x < -cloud.texture.get_width() * cloud.scale.x:
			cloud.position.x = screen_width + cloud.texture.get_width() * cloud.scale.x

func set_cloud_visibility(visible: bool):
	"""Show or hide all clouds"""
	for cloud in cloud_sprites:
		cloud.visible = visible

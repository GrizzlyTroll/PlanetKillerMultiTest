extends Area2D

@export var item_data: Resource
var can_pickup = true

func _ready():
	add_to_group("pickup_items")
	body_entered.connect(_on_body_entered)
	
	if item_data and item_data.texture:
		$Sprite2D.texture = item_data.texture
		$Sprite2D.scale = Vector2(0.5, 0.5)
		
		var shape = CircleShape2D.new()
		shape.radius = 8
		$CollisionShape2D.shape = shape

func _on_body_entered(body):
	if body.is_in_group("Player") and can_pickup:
		if body.player_inventory != null:
			if body.player_inventory.items != null:
				if body.player_inventory.add_item(item_data):
					print("Item added successfully!")
					
					# Update the inventory UI
					var inv_ui = get_tree().current_scene.get_node("Inv_UI")
					if inv_ui:
						inv_ui.update_slots()
						print("Inventory UI updated")
					
					can_pickup = false
					queue_free()
				else:
					print("Failed to add item - inventory full?")
			else:
				print("ERROR: Items array is null!")
		else:
			print("ERROR: Player inventory is null!")

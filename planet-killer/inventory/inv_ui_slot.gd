extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display
var slot_index: int
var player: Node
var is_dragging = false
var drag_sprite: Sprite2D

func _ready():
	gui_input.connect(_on_slot_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_mouse_exited():
	modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_slot_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				if player and player.player_inventory:
					var item = player.player_inventory.get_item(slot_index)
					if item:
						start_drag(item)
			else:
				# End drag
				if is_dragging:
					end_drag()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			drop_item()

func start_drag(item: Resource):
	is_dragging = true
	
	# Create drag sprite
	drag_sprite = Sprite2D.new()
	drag_sprite.texture = item.texture
	drag_sprite.scale = Vector2(0.5, 0.5)
	drag_sprite.z_index = 1000
	get_tree().current_scene.add_child(drag_sprite)
	
	# Hide original item
	item_visual.visible = false
	
	# ← ADDED THESE LINES TO NOTIFY MAIN UI:
	var inv_ui = get_tree().current_scene.get_node_or_null("Inv_UI")
	if not inv_ui:
		inv_ui = get_tree().current_scene.get_node_or_null("Inv_Ui")
	
	if inv_ui:
		inv_ui.start_drag(slot_index, item)  # ← NOTIFIES MAIN UI
	
	print("Started dragging from slot: ", slot_index)

func end_drag():
	if is_dragging and drag_sprite:
		# Use a different approach - check all slots manually
		var target_slot = check_all_slots()
		
		print("Target slot found: ", target_slot)
		
		if target_slot != -1 and target_slot != slot_index:
	# ← REPLACED WITH MAIN UI DRAG SYSTEM:
			var inv_ui = get_tree().current_scene.get_node_or_null("Inv_UI")
			if not inv_ui:
				inv_ui = get_tree().current_scene.get_node_or_null("Inv_Ui")
			
			if inv_ui:
				inv_ui.end_drag(target_slot)  # ← USES MAIN UI'S DRAG SYSTEM
				print("Successfully moved item from slot ", slot_index, " to slot ", target_slot)
			else:
				print("Could not find inventory UI")
				
		# Clean up drag sprite
		drag_sprite.queue_free()
		drag_sprite = null
		
		# Show original item again
		item_visual.visible = true
		
		is_dragging = false

func check_all_slots():
	
	var mouse_pos = get_global_mouse_position()
	
	# ← ADDED FALLBACK DETECTION:
	var inv_ui = get_tree().current_scene.get_node_or_null("Inv_UI")  # ← SAFE
	if not inv_ui:
		inv_ui = get_tree().current_scene.get_node_or_null("Inv_Ui")  # ← TRY OTHER NAME
	
	if inv_ui:
		var grid_container = inv_ui.get_node("NinePatchRect/GridContainer")
		var slots = grid_container.get_children()
		
		# Check which slot the mouse is actually over
		for i in range(slots.size()):
			var slot = slots[i]
			var slot_rect = Rect2(slot.global_position, slot.size)
			if slot_rect.has_point(mouse_pos):
				print("Mouse over slot: ", i)
				return i  # ← RETURNS THE ACTUAL SLOT THE MOUSE IS OVER!
	
	return -1
	

func _process(delta):
	# Update drag sprite position
	if is_dragging and drag_sprite:
		drag_sprite.global_position = get_global_mouse_position()

func update(item: Resource):
	if !item:
		item_visual.visible = false
	else: 
		item_visual.visible = true
		item_visual.texture = item.texture

func drop_item():
	if player and player.player_inventory:
		var item = player.player_inventory.get_item(slot_index)
		if item:
			var dropped_item = preload("res://Scenes/PlayerStuff/droppable_item.tscn").instantiate()
			dropped_item.item_data = item
			dropped_item.global_position = player.global_position + Vector2(randf_range(-20, 20), -10)
			get_tree().current_scene.add_child(dropped_item)
			
			player.player_inventory.remove_item(slot_index)
			update(null)

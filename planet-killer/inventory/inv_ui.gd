extends Control

@onready var inv: Resource
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()
var is_open = false
var player: Node
var dragged_slot = -1
var dragged_item: Resource

func _ready():
	await get_tree().process_frame
	
	player = get_tree().current_scene.get_node("Player")
	if player and player.player_inventory:
		inv = player.player_inventory
		update_slots()
	
	close()
	
	# Set up slot references
	for i in range(slots.size()):
		slots[i].slot_index = i
		slots[i].player = player

func start_drag(slot_index: int, item: Resource):
	dragged_slot = slot_index
	dragged_item = item
	print("Drag started from slot: ", slot_index)

func end_drag(target_slot: int):
	if dragged_slot != -1 and dragged_slot != target_slot:
		# Move the item
		if inv.move_item(dragged_slot, target_slot):
			print("Moved item from slot ", dragged_slot, " to slot ", target_slot)
			update_slots()
	
	# Reset drag state
	dragged_slot = -1
	dragged_item = null

func update_slots():
	if inv and inv.items != null:
		for i in range(min(inv.items.size(), slots.size())):
			slots[i].update(inv.items[i])

func _process(delta):
	if Input.is_action_just_pressed("i"):
		if is_open:
			close()
		else:
			open()

func open():
	visible = true
	is_open = true
	update_slots()

func close():
	visible = false
	is_open = false

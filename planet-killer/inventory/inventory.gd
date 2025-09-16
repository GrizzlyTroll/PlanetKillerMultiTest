extends Resource

# Remove class_name line completely
@export var items: Array[Resource]

func add_item(item: Resource) -> bool:
	# Find first empty slot
	for i in range(items.size()):
		if items[i] == null:
			items[i] = item
			return true
	return false  # Inventory full

func remove_item(slot_index: int) -> Resource:
	if slot_index >= 0 and slot_index < items.size():
		var item = items[slot_index]
		items[slot_index] = null
		return item
	return null

func get_item(slot_index: int) -> Resource:
	if slot_index >= 0 and slot_index < items.size():
		return items[slot_index]
	return null
	
func move_item(from_slot: int, to_slot: int) -> bool:
	if items == null:
		return false
	
	# Check if slots are valid
	if from_slot < 0 or from_slot >= items.size():
		return false
	if to_slot < 0 or to_slot >= items.size():
		return false
	
	# Get the item from source slot
	var item = items[from_slot]
	
	# If destination slot is empty, move the item
	if items[to_slot] == null:
		items[to_slot] = item
		items[from_slot] = null
		return true
		
	# If destination slot has an item, swap them
	else:
		var temp_item = items[to_slot]
		items[to_slot] = item
		items[from_slot] = temp_item
		return true

	
	

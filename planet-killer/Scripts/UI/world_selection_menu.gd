extends Control
class_name WorldSelectionMenu

## World Selection Menu - Displays available world saves and allows creating new worlds
## Reuses the panel-based layout from the achievements menu

signal world_selection_menu_closed
signal new_world_requested
signal world_selected(world_name: String)
signal world_deleted(world_name: String)

@onready var scroll_container: ScrollContainer = $MainContainer/ContentPanel/VBoxContainer/ScrollContainer
@onready var worlds_container: VBoxContainer = $MainContainer/ContentPanel/VBoxContainer/ScrollContainer/WorldsContainer
@onready var close_button: Button = $MainContainer/ContentPanel/VBoxContainer/Header/CloseButton
@onready var title_label: Label = $MainContainer/ContentPanel/VBoxContainer/Header/TitleLabel
@onready var new_world_button: Button = $MainContainer/ContentPanel/VBoxContainer/ScrollContainer/WorldsContainer/NewWorldButton

# World item scene
var world_item_scene: PackedScene
var deletion_dialog: WorldDeletionDialog

func _ready() -> void:
	# Connect signals
	close_button.pressed.connect(_on_close_button_pressed)
	new_world_button.pressed.connect(_on_new_world_button_pressed)
	
	# Initially hide the menu
	hide()
	
	# Load world item scene
	world_item_scene = preload("res://Scenes/UI/WorldItem.tscn")
	
	# Create deletion dialog
	_create_deletion_dialog()

## Create the deletion confirmation dialog
func _create_deletion_dialog() -> void:
	"""Create and set up the deletion confirmation dialog"""
	deletion_dialog = WorldDeletionDialog.new()
	deletion_dialog.world_deletion_confirmed.connect(_on_deletion_confirmed)
	add_child(deletion_dialog)

## Show the world selection menu
func show_world_selection_menu() -> void:
	show()
	_populate_worlds()

## Hide the world selection menu
func hide_world_selection_menu() -> void:
	hide()
	world_selection_menu_closed.emit()

## Populate the worlds list
func _populate_worlds() -> void:
	# Clear existing world items (except the new world button)
	for child in worlds_container.get_children():
		if child != new_world_button:
			child.queue_free()
	
	# Get all world saves from SaveSystem
	var world_saves = _get_available_worlds()
	
	# Create world items for each save
	for world_data in world_saves:
		_create_world_item(world_data)

## Get available world saves
func _get_available_worlds() -> Array:
	# Return actual save files from the SQLite save system
	var worlds = []
	
	# Check if SaveSystemIntegration is available
	if SaveSystemIntegration:
		worlds = SaveSystemIntegration.get_available_worlds_for_selector()
	else:
		print("ERROR: SaveSystemIntegration not available!")
	
	return worlds

## Create a world item
func _create_world_item(world_data: Dictionary) -> void:
	# Create a proper WorldItem scene
	var world_item = world_item_scene.instantiate()
	if world_item:
		worlds_container.add_child(world_item)
		world_item.configure(world_data)
		world_item.world_selected.connect(_on_world_selected)
		world_item.world_deleted.connect(_on_world_deleted)
		
		# Insert before the new world button
		worlds_container.move_child(world_item, worlds_container.get_child_count() - 2)

## Handle close button press
func _on_close_button_pressed() -> void:
	hide_world_selection_menu()

## Handle new world button press
func _on_new_world_button_pressed() -> void:
	# Create a new world using the SQLite save system
	if SaveSystemIntegration:
		var world_name = "New World " + str(Time.get_unix_time_from_system())
		if SaveSystemIntegration.create_new_world_for_selector(world_name):
			print("New world created: ", world_name)
		else:
			print("Failed to create new world")
	
	new_world_requested.emit()
	hide_world_selection_menu()

## Handle world selection
func _on_world_selected(world_name: String) -> void:
	# Load the selected world using the SQLite save system
	if SaveSystemIntegration:
		if SaveSystemIntegration.load_world_for_selector(world_name):
			print("World loaded: ", world_name)
		else:
			print("Failed to load world: ", world_name)
	
	world_selected.emit(world_name)
	hide_world_selection_menu()

## Handle world deletion request
func _on_world_deleted(world_name: String) -> void:
	# Show confirmation dialog
	deletion_dialog.show_deletion_dialog(world_name)

## Handle deletion confirmation
func _on_deletion_confirmed(world_name: String) -> void:
	# Delete the world using the SQLite save system
	if SaveSystemIntegration:
		if SaveSystemIntegration.delete_world_for_selector(world_name):
			print("World deleted: ", world_name)
			# Refresh the world list
			_populate_worlds()
		else:
			print("Failed to delete world: ", world_name)
	
	world_deleted.emit(world_name)

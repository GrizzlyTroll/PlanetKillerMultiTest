extends Control
class_name WorldItem

## World Item - Displays a single world save with its details
## Shows icon, name, save time, play time, and seed

signal world_selected(world_name: String)
signal world_deleted(world_name: String)

@onready var world_icon: TextureRect = $HBoxContainer/IconContainer/WorldIcon
@onready var title_label: Label = $HBoxContainer/ContentContainer/VBoxContainer/TitleLabel
@onready var details_label: Label = $HBoxContainer/ContentContainer/VBoxContainer/DetailsLabel
@onready var play_time_label: Label = $HBoxContainer/ContentContainer/VBoxContainer/PlayTimeLabel
@onready var seed_label: Label = $HBoxContainer/ContentContainer/VBoxContainer/SeedLabel
@onready var play_button: Button = $HBoxContainer/StatusContainer/VBoxContainer/PlayButton
@onready var delete_button: Button = $HBoxContainer/StatusContainer/VBoxContainer/DeleteButton
@onready var background_panel: Panel = $BackgroundPanel

var world_data: Dictionary = {}

func _ready() -> void:
	# Set up the item appearance
	_setup_appearance()
	
	# Connect button signals
	play_button.pressed.connect(_on_play_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)

## Configure the world item with data
func configure(data: Dictionary) -> void:
	world_data = data
	
	# Set title
	title_label.text = data.get("name", "Unknown World")
	
	# Set save time
	var last_save_time = data.get("last_save_time", 0)
	if last_save_time > 0:
		var save_time = Time.get_datetime_string_from_unix_time(last_save_time)
		details_label.text = "Last saved: " + save_time
	else:
		details_label.text = "Last saved: Never"
	
	# Set play time
	var game_time = data.get("game_time", 0)
	play_time_label.text = "Play time: " + _format_game_time(game_time)
	
	# Set seed
	var world_seed = data.get("world_seed", 0)
	seed_label.text = "Seed: " + str(world_seed)
	
	# Set icon (using a placeholder for now)
	_setup_world_icon()

## Set up the world icon
func _setup_world_icon() -> void:
	# For now, use a placeholder icon
	# Later this could be a world preview or biome icon
	var icon = preload("res://inventory/InvSlot-1.png")
	if icon:
		world_icon.texture = icon

## Format game time in a readable format
func _format_game_time(seconds: int) -> String:
	var hours = seconds / 3600  # Integer division is intentional for time formatting
	var minutes = (seconds % 3600) / 60  # Integer division is intentional for time formatting
	
	if hours > 0:
		return str(hours) + "h " + str(minutes) + "m"
	else:
		return str(minutes) + "m"

## Set up the basic appearance
func _setup_appearance() -> void:
	# Set up background panel with theme colors
	if background_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.3, 0.02, 0.5, 0.8)  # Theme normal color
		panel_style.border_color = Color(0.559017, 0.00328598, 0.888036, 0.8)  # Theme accent color
		panel_style.border_width_left = 2
		panel_style.border_width_right = 2
		panel_style.border_width_top = 2
		panel_style.border_width_bottom = 2
		panel_style.corner_radius_top_left = 6.0
		panel_style.corner_radius_top_right = 6.0
		panel_style.corner_radius_bottom_left = 6.0
		panel_style.corner_radius_bottom_right = 6.0
		
		background_panel.add_theme_stylebox_override("panel", panel_style)

## Handle play button press
func _on_play_button_pressed() -> void:
	world_selected.emit(world_data.get("name", "Unknown World"))

## Handle delete button press
func _on_delete_button_pressed() -> void:
	world_deleted.emit(world_data.get("name", "Unknown World"))

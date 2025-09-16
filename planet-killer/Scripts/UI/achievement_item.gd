extends Control
class_name AchievementItem

## Achievement Item - Displays a single achievement with its details
## Shows icon, title, description, progress, and unlock status

@onready var icon_texture: TextureRect = $HBoxContainer/IconContainer/IconTexture
@onready var title_label: Label = $HBoxContainer/ContentContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $HBoxContainer/ContentContainer/VBoxContainer/DescriptionLabel
@onready var progress_label: Label = $HBoxContainer/ContentContainer/VBoxContainer/ProgressLabel
@onready var status_icon: TextureRect = $HBoxContainer/StatusContainer/StatusIcon
@onready var background_panel: Panel = $BackgroundPanel

var achievement_data: Dictionary = {}

func _ready() -> void:
	# Set up the item appearance
	_setup_appearance()

## Configure the achievement item with data
func configure(data: Dictionary) -> void:
	achievement_data = data
	
	# Set title and description
	title_label.text = data.get("title", "Unknown Achievement")
	description_label.text = data.get("description", "No description available")
	
	# Set icon based on unlock status
	var icon_path = data.get("icon_unlocked", "") if data.get("unlocked", false) else data.get("icon_locked", "")
	if not icon_path.is_empty():
		var icon = load(icon_path)
		if icon:
			icon_texture.texture = icon
		else:
			# Use placeholder icon if loading fails
			icon_texture.texture = preload("res://inventory/InvSlot-1.png")
	
	# Set up progress display
	_setup_progress_display(data)
	
	# Set up status icon
	_setup_status_display(data.get("unlocked", false))
	
	# Apply visual styling based on unlock status
	_apply_unlock_styling(data.get("unlocked", false))

## Set up the progress display
func _setup_progress_display(data: Dictionary) -> void:
	var max_progress = data.get("max_progress", 1.0)
	var progress = data.get("progress", 0.0)
	var unlocked = data.get("unlocked", false)
	
	if max_progress > 1.0 and not unlocked:
		# Show progress text for incremental achievements that aren't unlocked
		progress_label.visible = true
		
		var progress_text = "%d/%d" % [int(progress), int(max_progress)]
		progress_label.text = progress_text
	else:
		# Hide progress for non-incremental or unlocked achievements
		progress_label.visible = false

## Set up the status display
func _setup_status_display(unlocked: bool) -> void:
	if unlocked:
		# Show unlocked icon (checkmark or star)
		status_icon.texture = preload("res://inventory/InvSlot-1.png")  # Placeholder
		status_icon.modulate = Color(0.4, 0.4, 0.4)  # Gray color

## Apply visual styling based on unlock status
func _apply_unlock_styling(unlocked: bool) -> void:
	if unlocked:
		# Unlocked achievements are fully visible
		modulate = Color.WHITE
		title_label.modulate = Color.WHITE
		description_label.modulate = Color.WHITE
		
		# Add a subtle glow effect
		_add_unlock_glow()
	else:
		# Locked achievements are grayed out
		modulate = Color(0.8, 0.8, 0.8, 0.9)
		title_label.modulate = Color(0.7, 0.7, 0.7)
		description_label.modulate = Color(0.5, 0.5, 0.5)

## Add a subtle glow effect for unlocked achievements
func _add_unlock_glow() -> void:
	if background_panel:
		# Create a simple glow effect using theme colors
		var glow_style = StyleBoxFlat.new()
		glow_style.bg_color = Color(0.559017, 0.00328598, 0.888036, 0.2)  # Theme accent color with transparency
		glow_style.border_color = Color(0.559017, 0.00328598, 0.888036, 0.6)  # Theme accent color border
		glow_style.border_width_left = 2
		glow_style.border_width_right = 2
		glow_style.border_width_top = 2
		glow_style.border_width_bottom = 2
		glow_style.corner_radius_top_left = 6.0
		glow_style.corner_radius_top_right = 6.0
		glow_style.corner_radius_bottom_left = 6.0
		glow_style.corner_radius_bottom_right = 6.0
		
		background_panel.add_theme_stylebox_override("panel", glow_style)

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
	

	

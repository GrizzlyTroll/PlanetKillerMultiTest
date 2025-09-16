extends Control
class_name AchievementToast

## Custom toast for achievement unlock notifications
## Standalone achievement toast with achievement-specific styling

signal toast_dismissed
signal toast_finished

@onready var background: Panel = $Background
@onready var title_label: Label = $Layout/CenterSlot/TitleLabel
@onready var description_label: Label = $Layout/CenterSlot/DescriptionLabel
@onready var achievement_icon: TextureRect = $Layout/LeftSlot/AchievementIcon
@onready var progress_bar: ProgressBar = $Layout/CenterSlot/ProgressBar
@onready var close_button: Button = $Layout/RightSlot/CloseButton

func _ready() -> void:
	_setup_achievement_theme()
	_setup_close_button()
	_setup_default_layout()

## Set up achievement-specific theme
func _setup_achievement_theme() -> void:
	var achievement_theme = {
		"background_color": Color(0.2, 0.1, 0.4, 0.95),  # Purple background
		"border_color": Color(1.0, 0.8, 0.2, 0.8),       # Gold border
		"title_color": Color(1.0, 0.9, 0.3),             # Gold title
		"description_color": Color(0.9, 0.8, 0.9),       # Light purple description
		"corner_radius": 12.0
	}
	_apply_theme(achievement_theme)

## Set up the close button
func _setup_close_button() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

## Set up the default layout
func _setup_default_layout() -> void:
	# Configure title label
	if title_label:
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Configure description label
	if description_label:
		description_label.add_theme_font_size_override("font_size", 14)
		description_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.9))
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

## Configure the achievement toast with data
func configure(data: Dictionary) -> void:
	# Set title
	if data.has("title") and title_label:
		title_label.text = data.get("title", "")
		title_label.visible = not title_label.text.is_empty()
	
	# Set description
	if data.has("description") and description_label:
		description_label.text = data.get("description", "")
		description_label.visible = not description_label.text.is_empty()
	
	# Set up achievement icon
	if data.has("icon_path") and achievement_icon:
		var icon = load(data.get("icon_path", ""))
		if icon:
			achievement_icon.texture = icon
			achievement_icon.visible = true
		else:
			achievement_icon.visible = false
	
	# Set up progress bar for incremental achievements
	if data.has("progress") and data.has("max_progress") and progress_bar:
		var progress = data.get("progress", 0.0)
		var max_progress = data.get("max_progress", 1.0)
		
		if max_progress > 1.0:  # Only show for incremental achievements
			progress_bar.max_value = max_progress
			progress_bar.value = progress
			progress_bar.visible = true
		else:
			progress_bar.visible = false
	
	# Add achievement-specific styling
	_add_achievement_effects()

## Add special effects for achievement toasts
func _add_achievement_effects() -> void:
	# Add a subtle glow effect
	if background:
		# Create a simple glow effect by adding a ColorRect behind the background
		var glow = ColorRect.new()
		glow.color = Color(1.0, 0.8, 0.2, 0.3)  # Gold glow
		glow.size = background.size + Vector2(4, 4)
		glow.position = background.position - Vector2(2, 2)
		glow.z_index = background.z_index - 1
		
		# Add to the background's parent
		if background.get_parent():
			background.get_parent().add_child(glow)
			background.get_parent().move_child(glow, 0)  # Move to back
	
	# Add a subtle animation
	if get_tree():
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

## Apply theme to the achievement toast
func _apply_theme(theme_data: Dictionary) -> void:
	if background:
		# Add a subtle border effect
		var border_style = StyleBoxFlat.new()
		border_style.bg_color = theme_data.get("background_color", Color.BLACK)
		border_style.border_color = theme_data.get("border_color", Color.WHITE)
		border_style.border_width_left = 2
		border_style.border_width_right = 2
		border_style.border_width_top = 2
		border_style.border_width_bottom = 2
		border_style.corner_radius_top_left = theme_data.get("corner_radius", 8.0)
		border_style.corner_radius_top_right = theme_data.get("corner_radius", 8.0)
		border_style.corner_radius_bottom_left = theme_data.get("corner_radius", 8.0)
		border_style.corner_radius_bottom_right = theme_data.get("corner_radius", 8.0)
		
		background.add_theme_stylebox_override("panel", border_style)

## Handle close button press
func _on_close_pressed() -> void:
	toast_dismissed.emit()
	queue_free()

## Manually dismiss the toast
func dismiss() -> void:
	toast_dismissed.emit()
	queue_free()

## Manually finish the toast
func finish() -> void:
	toast_finished.emit()
	queue_free()

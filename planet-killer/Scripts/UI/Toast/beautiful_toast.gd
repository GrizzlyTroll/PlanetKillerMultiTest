extends Control
class_name BeautifulToast

## Beautiful reusable toast component with dynamic sizing
## Based on the design from basic_toast_test.gd

signal toast_dismissed
signal toast_finished

var title_label: Label
var description_label: Label

func _ready() -> void:
	_setup_toast()

func _setup_toast() -> void:
	# Set up the toast with proper sizing
	custom_minimum_size = Vector2(300, 60)  # Smaller minimum size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Background with gradient
	var background = Panel.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create gradient style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.95)  # Darker background
	style.border_color = Color(0, 200, 120, 0.9)  # Slightly darker green border
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Add subtle shadow
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	
	background.add_theme_stylebox_override("panel", style)
	add_child(background)
	
	# Main layout
	var layout = HBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 12)  # Reduced separation
	add_child(layout)
	
	# Left slot - Success icon
	var left_slot = Control.new()
	left_slot.name = "LeftSlot"
	left_slot.custom_minimum_size = Vector2(50, 0)  # Smaller left slot
	left_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(left_slot)
	
	# Success circle with checkmark
	var success_circle = Control.new()
	success_circle.name = "SuccessCircle"
	success_circle.custom_minimum_size = Vector2(28, 28)  # Smaller circle
	success_circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	success_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Position will be updated dynamically in _adjust_toast_size()
	success_circle.position = Vector2(11, 16)  # Initial position
	left_slot.add_child(success_circle)
	
	# Circle background - make it actually circular
	var circle_bg = Panel.new()
	circle_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var circle_style = StyleBoxFlat.new()
	circle_style.bg_color = Color(0, 200, 120, 1.0)  # Slightly darker green
	circle_style.corner_radius_top_left = 14
	circle_style.corner_radius_top_right = 14
	circle_style.corner_radius_bottom_left = 14
	circle_style.corner_radius_bottom_right = 14
	circle_bg.add_theme_stylebox_override("panel", circle_style)
	
	success_circle.add_child(circle_bg)
	
	# Checkmark - properly centered
	var checkmark = Label.new()
	checkmark.text = "✓"
	checkmark.add_theme_font_size_override("font_size", 16)  # Smaller checkmark
	checkmark.add_theme_color_override("font_color", Color.WHITE)
	checkmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkmark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	checkmark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	success_circle.add_child(checkmark)
	
	# Center slot - Title and description with proper padding
	var center_slot = MarginContainer.new()
	center_slot.name = "CenterSlot"
	center_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_slot.add_theme_constant_override("margin_left", 8)
	center_slot.add_theme_constant_override("margin_right", 8)
	center_slot.add_theme_constant_override("margin_top", 20)  # Top padding
	center_slot.add_theme_constant_override("margin_bottom", 20)  # Bottom padding to match top
	
	# Add VBoxContainer inside the MarginContainer
	var text_container = VBoxContainer.new()
	text_container.name = "TextContainer"
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_container.add_theme_constant_override("separation", 2)  # Reduced separation
	center_slot.add_child(text_container)
	
	layout.add_child(center_slot)
	
	# Right slot - Close button
	var right_slot = Control.new()
	right_slot.name = "RightSlot"
	right_slot.custom_minimum_size = Vector2(50, 0)  # Larger right slot
	right_slot.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(right_slot)
	
	# Close button - larger
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(32, 32)  # Larger button
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_font_size_override("font_size", 24)  # Larger X
	close_button.add_theme_color_override("font_color", Color(180, 180, 180, 0.8))  # Better color
	close_button.add_theme_color_override("font_hover_color", Color(220, 220, 220, 1.0))
	close_button.add_theme_color_override("font_pressed_color", Color(140, 140, 140, 0.6))
	close_button.flat = true
	right_slot.add_child(close_button)
	
	# Create labels
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 16)  # Smaller text
	title_label.add_theme_color_override("font_color", Color(255, 255, 255, 1.0))  # Pure white
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.visible = false
	
	description_label = Label.new()
	description_label.name = "DescriptionLabel"
	description_label.add_theme_font_size_override("font_size", 14)  # Smaller text
	description_label.add_theme_color_override("font_color", Color(220, 220, 220, 1.0))  # Slightly dimmer white
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.visible = false
	
	# Add to text container
	text_container.add_child(title_label)
	text_container.add_child(description_label)
	
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

func configure(data: Dictionary):
	print("🔧 Configuring beautiful toast with data: ", data)
	
	if data.has("title") and title_label:
		title_label.text = data.get("title", "")
		title_label.visible = not title_label.text.is_empty()
		print("✅ Title set to: ", title_label.text, " visible: ", title_label.visible)
	
	if data.has("description") and description_label:
		description_label.text = data.get("description", "")
		description_label.visible = not description_label.text.is_empty()
		print("✅ Description set to: ", description_label.text, " visible: ", description_label.visible)
	
	# Dynamic sizing based on content
	call_deferred("_adjust_toast_size")
	
	# Auto-dismiss after duration
	if data.has("duration") and data.get("duration", 0) > 0:
		if get_tree():
			var timer = get_tree().create_timer(data.get("duration"))
			timer.timeout.connect(func(): toast_finished.emit())
		else:
			print("Warning: Cannot create timer - scene tree not available")

func _adjust_toast_size():
	# Wait for labels to update their size
	await get_tree().process_frame
	
	var title_height = 0
	var description_height = 0
	
	if title_label and title_label.visible:
		title_height = title_label.get_minimum_size().y
	
	if description_label and description_label.visible:
		description_height = description_label.get_minimum_size().y
	
	# Calculate total content height
	var content_height = title_height + description_height
	if title_height > 0 and description_height > 0:
		content_height += 2  # Add separation
	
	# Add padding (top + bottom) - account for the 20px top and 20px bottom padding of container
	var total_height = content_height + 40  # 20px top + 20px bottom padding
	
	# Ensure minimum height
	total_height = max(total_height, 60)
	
	# Update toast size
	custom_minimum_size.y = total_height
	size.y = total_height
	
	# Center the checkmark vertically and align with text
	var success_circle = $Layout/LeftSlot/SuccessCircle
	if success_circle:
		var circle_y = (total_height - 28) / 2  # Center the 28px circle in the new height
		success_circle.position.y = circle_y
		# Align checkmark with text by positioning it to account for the 8px left margin
		success_circle.position.x = 11 + 8  # Original 11px + 8px to align with text margin
		print("🎯 Centered checkmark at y: ", circle_y, " x: ", success_circle.position.x)
	
	print("📏 Adjusted toast height to: ", total_height, " (title: ", title_height, ", desc: ", description_height, ")")

func _on_close_pressed():
	toast_dismissed.emit()
	queue_free()

func dismiss():
	toast_dismissed.emit()
	queue_free()

func finish():
	toast_finished.emit()
	queue_free()

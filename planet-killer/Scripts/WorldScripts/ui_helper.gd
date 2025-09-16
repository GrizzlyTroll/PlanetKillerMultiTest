extends Node

# UI Helper class for common UI functionality and styling

static func create_button(text: String, custom_minimum_size: Vector2 = Vector2(120, 40)) -> Button:
	"""Create a styled button with consistent appearance"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = custom_minimum_size
	button.flat = false
	
	# Apply consistent styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	
	button.add_theme_stylebox_override("normal", style)
	
	# Hover style
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	return button

static func create_slider(min_value: float, max_value: float, step: float = 1.0) -> HSlider:
	"""Create a styled slider with consistent appearance"""
	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.custom_minimum_size = Vector2(200, 20)
	
	# Apply consistent styling
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.6, 0.6, 0.6, 1.0)
	grabber_style.corner_radius_top_left = 3
	grabber_style.corner_radius_top_right = 3
	grabber_style.corner_radius_bottom_right = 3
	grabber_style.corner_radius_bottom_left = 3
	
	slider.add_theme_stylebox_override("grabber", grabber_style)
	slider.add_theme_stylebox_override("grabber_highlight", grabber_style)
	
	return slider

static func create_checkbox(text: String = "") -> CheckBox:
	"""Create a styled checkbox with consistent appearance"""
	var checkbox = CheckBox.new()
	checkbox.text = text
	
	# Apply consistent styling
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	normal_style.corner_radius_top_left = 2
	normal_style.corner_radius_top_right = 2
	normal_style.corner_radius_bottom_right = 2
	normal_style.corner_radius_bottom_left = 2
	
	checkbox.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	checkbox.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	checkbox.add_theme_stylebox_override("pressed", pressed_style)
	
	return checkbox

static func create_option_button() -> OptionButton:
	"""Create a styled option button with consistent appearance"""
	var option_button = OptionButton.new()
	option_button.custom_minimum_size = Vector2(150, 30)
	
	# Apply consistent styling
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.corner_radius_bottom_left = 4
	
	option_button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	option_button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	option_button.add_theme_stylebox_override("pressed", pressed_style)
	
	return option_button

static func create_label(text: String, horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	"""Create a styled label with consistent appearance"""
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = horizontal_alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Apply consistent styling
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	
	return label

static func create_title_label(text: String) -> Label:
	"""Create a styled title label with larger font"""
	var label = create_label(text, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	return label

static func create_container(container_type: String = "VBoxContainer", separation: int = 10) -> Container:
	"""Create a styled container with consistent spacing"""
	var container
	match container_type:
		"VBoxContainer":
			container = VBoxContainer.new()
		"HBoxContainer":
			container = HBoxContainer.new()
		"GridContainer":
			container = GridContainer.new()
		_:
			container = VBoxContainer.new()
	
	container.add_theme_constant_override("separation", separation)
	return container

static func create_panel() -> Panel:
	"""Create a styled panel with consistent appearance"""
	var panel = Panel.new()
	
	# Apply consistent styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	
	panel.add_theme_stylebox_override("panel", style)
	
	return panel

static func format_percentage(value: float) -> String:
	"""Format a value as a percentage string"""
	return str(int(value)) + "%"

static func format_resolution(resolution: Vector2i) -> String:
	"""Format a resolution vector as a string"""
	return str(resolution.x) + "x" + str(resolution.y)

static func get_difficulty_name(difficulty_index: int) -> String:
	"""Get difficulty name from index"""
	match difficulty_index:
		0: return "Easy"
		1: return "Normal"
		2: return "Hard"
		_: return "Normal"

static func animate_fade_in(node: Control, duration: float = 0.3):
	"""Animate a fade in effect for a control node"""
	node.modulate.a = 0.0
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)

static func animate_fade_out(node: Control, duration: float = 0.3):
	"""Animate a fade out effect for a control node"""
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)

static func create_tooltip(text: String) -> Control:
	"""Create a tooltip control"""
	var tooltip = Control.new()
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var label = create_label(text, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	
	var panel = create_panel()
	var panel_style = panel.get_theme_stylebox("panel").duplicate()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.8)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	panel.add_child(label)
	tooltip.add_child(panel)
	
	# Position label in center of panel
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	return tooltip

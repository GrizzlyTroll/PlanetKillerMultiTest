extends Node

var current_theme: Theme
var dark_theme: Theme
var light_theme: Theme

func _ready():
	# Create themes
	create_themes()
	
	# Apply default theme
	apply_theme("dark")

func create_themes():
	"""Create the available themes"""
	create_dark_theme()
	create_light_theme()

func create_dark_theme():
	"""Create a dark theme"""
	dark_theme = Theme.new()
	
	# Colors
	dark_theme.set_color("font_color", "Button", Color.WHITE)
	dark_theme.set_color("font_hover_color", "Button", Color(1, 0.8, 0.8))
	dark_theme.set_color("font_pressed_color", "Button", Color(0.8, 0.8, 0.8))
	dark_theme.set_color("font_focus_color", "Button", Color(1, 0.8, 0.8))
	
	dark_theme.set_color("font_color", "Label", Color.WHITE)
	dark_theme.set_color("font_color", "TabContainer", Color.WHITE)
	
	# Font sizes
	dark_theme.set_font_size("font_size", "Button", 16)
	dark_theme.set_font_size("font_size", "Label", 14)
	dark_theme.set_font_size("font_size", "TabContainer", 14)
	
	# Styleboxes
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	button_normal.border_color = Color(0.4, 0.4, 0.5)
	button_normal.border_width_left = 2
	button_normal.border_width_right = 2
	button_normal.border_width_top = 2
	button_normal.border_width_bottom = 2
	button_normal.corner_radius_top_left = 5
	button_normal.corner_radius_top_right = 5
	button_normal.corner_radius_bottom_left = 5
	button_normal.corner_radius_bottom_right = 5
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.3, 0.3, 0.4, 0.8)
	button_hover.border_color = Color(0.5, 0.5, 0.6)
	button_hover.border_width_left = 2
	button_hover.border_width_right = 2
	button_hover.border_width_top = 2
	button_hover.border_width_bottom = 2
	button_hover.corner_radius_top_left = 5
	button_hover.corner_radius_top_right = 5
	button_hover.corner_radius_bottom_left = 5
	button_hover.corner_radius_bottom_right = 5
	
	var button_pressed = StyleBoxFlat.new()
	button_pressed.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	button_pressed.border_color = Color(0.6, 0.6, 0.7)
	button_pressed.border_width_left = 2
	button_pressed.border_width_right = 2
	button_pressed.border_width_top = 2
	button_pressed.border_width_bottom = 2
	button_pressed.corner_radius_top_left = 5
	button_pressed.corner_radius_top_right = 5
	button_pressed.corner_radius_bottom_left = 5
	button_pressed.corner_radius_bottom_right = 5
	
	dark_theme.set_stylebox("normal", "Button", button_normal)
	dark_theme.set_stylebox("hover", "Button", button_hover)
	dark_theme.set_stylebox("pressed", "Button", button_pressed)
	dark_theme.set_stylebox("focus", "Button", button_hover)

func create_light_theme():
	"""Create a light theme"""
	light_theme = Theme.new()
	
	# Colors
	light_theme.set_color("font_color", "Button", Color.BLACK)
	light_theme.set_color("font_hover_color", "Button", Color(0.2, 0.2, 0.8))
	light_theme.set_color("font_pressed_color", "Button", Color(0.1, 0.1, 0.1))
	light_theme.set_color("font_focus_color", "Button", Color(0.2, 0.2, 0.8))
	
	light_theme.set_color("font_color", "Label", Color.BLACK)
	light_theme.set_color("font_color", "TabContainer", Color.BLACK)
	
	# Font sizes
	light_theme.set_font_size("font_size", "Button", 16)
	light_theme.set_font_size("font_size", "Label", 14)
	light_theme.set_font_size("font_size", "TabContainer", 14)
	
	# Styleboxes
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color(0.9, 0.9, 0.9, 0.8)
	button_normal.border_color = Color(0.6, 0.6, 0.6)
	button_normal.border_width_left = 2
	button_normal.border_width_right = 2
	button_normal.border_width_top = 2
	button_normal.border_width_bottom = 2
	button_normal.corner_radius_top_left = 5
	button_normal.corner_radius_top_right = 5
	button_normal.corner_radius_bottom_left = 5
	button_normal.corner_radius_bottom_right = 5
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.8, 0.8, 0.9, 0.8)
	button_hover.border_color = Color(0.5, 0.5, 0.7)
	button_hover.border_width_left = 2
	button_hover.border_width_right = 2
	button_hover.border_width_top = 2
	button_hover.border_width_bottom = 2
	button_hover.corner_radius_top_left = 5
	button_hover.corner_radius_top_right = 5
	button_hover.corner_radius_bottom_left = 5
	button_hover.corner_radius_bottom_right = 5
	
	var button_pressed = StyleBoxFlat.new()
	button_pressed.bg_color = Color(0.7, 0.7, 0.8, 0.8)
	button_pressed.border_color = Color(0.4, 0.4, 0.6)
	button_pressed.border_width_left = 2
	button_pressed.border_width_right = 2
	button_pressed.border_width_top = 2
	button_pressed.border_width_bottom = 2
	button_pressed.corner_radius_top_left = 5
	button_pressed.corner_radius_top_right = 5
	button_pressed.corner_radius_bottom_left = 5
	button_pressed.corner_radius_bottom_right = 5
	
	light_theme.set_stylebox("normal", "Button", button_normal)
	light_theme.set_stylebox("hover", "Button", button_hover)
	light_theme.set_stylebox("pressed", "Button", button_pressed)
	light_theme.set_stylebox("focus", "Button", button_hover)

func apply_theme(theme_name: String):
	"""Apply a theme to the current scene"""
	match theme_name.to_lower():
		"dark":
			current_theme = dark_theme
		"light":
			current_theme = light_theme
		_:
			current_theme = dark_theme
	
	# Apply theme to current scene
	var _current_scene = get_tree().current_scene
	#if _current_scene:
		#_current_scene.theme = current_theme
	#
	
	print("Applied theme: " + theme_name)

func get_current_theme() -> Theme:
	"""Get the current theme"""
	return current_theme

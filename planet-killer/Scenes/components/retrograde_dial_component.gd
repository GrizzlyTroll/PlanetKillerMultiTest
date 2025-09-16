extends Control
class_name RetrogradeDialComponent

## Retrograde Dial Component
## Displays time as a clock with backwards-rotating hand and day/night arcs

signal time_clicked(time_of_day: float)

# Visual settings
@export var dial_size: float = 120.0
@export var hand_length: float = 45.0
@export var hand_width: float = 3.0
@export var dial_thickness: float = 8.0
@export var show_time_text: bool = true
@export var show_icons: bool = true

# Colors
@export var dial_background_color: Color = Color(0.1, 0.1, 0.1, 0.8)
@export var day_arc_color: Color = Color(0.2, 0.6, 1.0, 0.8)
@export var night_arc_color: Color = Color(0.1, 0.1, 0.3, 0.8)
@export var hand_color: Color = Color.WHITE
@export var text_color: Color = Color.WHITE

# Day/Night configuration
@export var day_percentage: float = 0.7  # 70% of cycle is day
@export var night_percentage: float = 0.3  # 30% of cycle is night

# Node references
@onready var dial_background: ColorRect
@onready var day_arc: ColorRect
@onready var night_arc: ColorRect
@onready var hand: ColorRect
@onready var center_point: ColorRect
@onready var time_label: Label
@onready var sun_icon: TextureRect
@onready var moon_icon: TextureRect

# Current state
var current_time: float = 0.0
var is_hovered: bool = false
var is_clicked: bool = false

func _ready() -> void:
	_setup_dial_nodes()
	_update_dial_appearance()

func _setup_dial_nodes() -> void:
	# Set control size
	custom_minimum_size = Vector2(dial_size, dial_size)
	size = Vector2(dial_size, dial_size)
	
	# Create dial background
	dial_background = ColorRect.new()
	dial_background.name = "DialBackground"
	dial_background.color = dial_background_color
	dial_background.anchor_right = 1.0
	dial_background.anchor_bottom = 1.0
	dial_background.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(dial_background)
	
	# Create day arc
	day_arc = ColorRect.new()
	day_arc.name = "DayArc"
	day_arc.color = day_arc_color
	day_arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(day_arc)
	
	# Create night arc
	night_arc = ColorRect.new()
	night_arc.name = "NightArc"
	night_arc.color = night_arc_color
	night_arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night_arc)
	
	# Create hand
	hand = ColorRect.new()
	hand.name = "Hand"
	hand.color = hand_color
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand)
	
	# Create center point
	center_point = ColorRect.new()
	center_point.name = "CenterPoint"
	center_point.color = hand_color
	center_point.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_point)
	
	# Create time label
	if show_time_text:
		time_label = Label.new()
		time_label.name = "TimeLabel"
		time_label.text = "00:00"
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		time_label.add_theme_color_override("font_color", text_color)
		time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(time_label)
	
	# Create sun icon
	if show_icons:
		sun_icon = TextureRect.new()
		sun_icon.name = "SunIcon"
		sun_icon.texture = _create_sun_icon()
		sun_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sun_icon)
		
		moon_icon = TextureRect.new()
		moon_icon.name = "MoonIcon"
		moon_icon.texture = _create_moon_icon()
		moon_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(moon_icon)

func _create_sun_icon() -> Texture2D:
	# Create a simple sun icon
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw center circle
	for x in range(4, 12):
		for y in range(4, 12):
			if Vector2(x - 8, y - 8).length() <= 4:
				image.set_pixel(x, y, Color.YELLOW)
	
	# Draw simple sun rays (just dots at the ends)
	for i in range(8):
		var angle = i * PI / 4
		var ray_pos = Vector2(8, 8) + Vector2(cos(angle), sin(angle)) * 8
		var x = int(ray_pos.x)
		var y = int(ray_pos.y)
		if x >= 0 and x < 16 and y >= 0 and y < 16:
			image.set_pixel(x, y, Color.YELLOW)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func _create_moon_icon() -> Texture2D:
	# Create a simple moon icon
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw moon shape
	for x in range(16):
		for y in range(16):
			var pos = Vector2(x - 8, y - 8)
			var distance = pos.length()
			if distance <= 6 and distance >= 3:
				# Create crescent shape
				var angle = atan2(pos.y, pos.x)
				if angle < 0:
					angle += 2 * PI
				if angle > PI / 2 and angle < 3 * PI / 2:
					image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_clicked = true
				_handle_click(event.position)
			else:
				is_clicked = false
	elif event is InputEventMouseMotion:
		is_hovered = _is_point_in_dial(event.position)
		if is_clicked:
			_handle_click(event.position)

func _handle_click(position: Vector2) -> void:
	var center = Vector2(dial_size / 2, dial_size / 2)
	var direction = (position - center).normalized()
	var angle = atan2(direction.y, direction.x)
	
	# Convert angle to time (0.0 to 1.0)
	# Start from top (12 o'clock) and go clockwise
	var time_angle = -angle + PI / 2
	if time_angle < 0:
		time_angle += 2 * PI
	
	var clicked_time = time_angle / (2 * PI)
	time_clicked.emit(clicked_time)

func _is_point_in_dial(position: Vector2) -> bool:
	var center = Vector2(dial_size / 2, dial_size / 2)
	var distance = position.distance_to(center)
	return distance <= dial_size / 2

func _update_dial_appearance() -> void:
	var center = Vector2(dial_size / 2, dial_size / 2)
	var radius = dial_size / 2 - dial_thickness / 2
	
	# Update dial background
	dial_background.size = Vector2(dial_size, dial_size)
	dial_background.position = Vector2.ZERO
	
	# Update day arc (simplified - just show as a colored ring)
	var day_angle = day_percentage * 2 * PI
	day_arc.size = Vector2(radius * 2, radius * 2)
	day_arc.position = center - Vector2(radius, radius)
	day_arc.color = day_arc_color
	day_arc.modulate.a = 0.5  # Semi-transparent
	
	# Update night arc (simplified - just show as a colored ring)
	var night_angle = night_percentage * 2 * PI
	night_arc.size = Vector2(radius * 2, radius * 2)
	night_arc.position = center - Vector2(radius, radius)
	night_arc.color = night_arc_color
	night_arc.modulate.a = 0.5  # Semi-transparent
	
	# Update hand
	var hand_angle = current_time * 2 * PI
	hand.size = Vector2(hand_width, hand_length)
	hand.position = center - Vector2(hand_width / 2, hand_length)
	hand.rotation = hand_angle
	
	# Update center point
	center_point.size = Vector2(6, 6)
	center_point.position = center - Vector2(3, 3)
	
	# Update time label
	if show_time_text and time_label:
		time_label.text = _format_time(current_time)
		time_label.size = Vector2(dial_size, 20)
		time_label.position = Vector2(0, dial_size + 5)
	
	# Update icons
	if show_icons:
		var icon_radius = radius - 20
		var sun_angle = day_angle / 2  # Middle of day arc
		var moon_angle = day_angle + night_angle / 2  # Middle of night arc
		
		sun_icon.size = Vector2(16, 16)
		sun_icon.position = center + Vector2(
			cos(sun_angle - PI / 2) * icon_radius - 8,
			sin(sun_angle - PI / 2) * icon_radius - 8
		)
		
		moon_icon.size = Vector2(16, 16)
		moon_icon.position = center + Vector2(
			cos(moon_angle - PI / 2) * icon_radius - 8,
			sin(moon_angle - PI / 2) * icon_radius - 8
		)



func _format_time(time_of_day: float) -> String:
	var total_minutes = time_of_day * 24.0 * 60.0
	var hours = int(total_minutes / 60.0)
	var minutes = int(total_minutes) % 60
	return "%02d:%02d" % [hours, minutes]

## Public API

func update_time(time_of_day: float) -> void:
	"""Update the dial to show the current time"""
	current_time = clamp(time_of_day, 0.0, 1.0)
	_update_dial_appearance()

func set_day_night_ratio(day_ratio: float) -> void:
	"""Set the ratio of day to night (0.0 to 1.0)"""
	day_percentage = clamp(day_ratio, 0.0, 1.0)
	night_percentage = 1.0 - day_percentage
	_update_dial_appearance()

func get_current_time() -> float:
	"""Get the currently displayed time"""
	return current_time

func set_dial_size(new_size: float) -> void:
	"""Set the dial size"""
	dial_size = new_size
	custom_minimum_size = Vector2(dial_size, dial_size)
	_update_dial_appearance()

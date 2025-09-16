extends RefCounted
class_name DayNightIntegration

static func setup_day_night_system(parent_node: Node2D) -> DayNightSystemManager:
	"""Set up the day/night cycle system"""
	# Create day/night system manager
	var day_night_system = DayNightSystemManager.new()
	day_night_system.name = "DayNightSystem"
	
	# Configure the system
	day_night_system.enable_sky_transitions = true
	day_night_system.enable_dial_ui = true
	day_night_system.auto_start = true
	day_night_system.time_speed_multiplier = 2.0  # Faster for testing
	day_night_system.start_time = 0.25  # Start at day time
	
	# Connect signals
	day_night_system.time_changed.connect(_on_time_changed)
	day_night_system.day_started.connect(_on_day_started)
	day_night_system.night_started.connect(_on_night_started)
	day_night_system.sunrise_started.connect(_on_sunrise_started)
	day_night_system.sunset_started.connect(_on_sunset_started)
	day_night_system.sky_state_changed.connect(_on_sky_state_changed)
	
	# Add to scene
	parent_node.add_child(day_night_system)
	
	# Create CanvasLayer for UI elements
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DayNightUI"
	parent_node.add_child(canvas_layer)
	
	# Move the dial to the CanvasLayer and position it
	if day_night_system.retrograde_dial:
		day_night_system.remove_child(day_night_system.retrograde_dial)
		canvas_layer.add_child(day_night_system.retrograde_dial)
		day_night_system.retrograde_dial.position = Vector2(1150, 50)
		# Ensure dial is always visible
		day_night_system.retrograde_dial.visible = true
	
	print("Day/Night system initialized")
	return day_night_system

static func _on_time_changed(time_of_day: float) -> void:
	"""Handle time changes"""
	# You can add time-based world effects here
	# For example, changing lighting, spawning creatures, etc.
	pass

static func _on_day_started() -> void:
	"""Handle day start"""
	print("Day has begun!")
	# Add day-specific effects here

static func _on_night_started() -> void:
	"""Handle night start"""
	print("Night has fallen!")
	# Add night-specific effects here

static func _on_sunrise_started() -> void:
	"""Handle sunrise start"""
	print("Sunrise begins!")
	# Add sunrise effects here

static func _on_sunset_started() -> void:
	"""Handle sunset start"""
	print("Sunset begins!")
	# Add sunset effects here

static func _on_sky_state_changed(state_name: String) -> void:
	"""Handle sky state changes"""
	print("Sky changed to: ", state_name)
	# Add sky state specific effects here

static func handle_day_night_input(event: InputEvent, day_night_system: DayNightSystemManager) -> void:
	"""Handle day/night system input controls"""
	if event.is_action_pressed("ui_left"):  # Left arrow
		# Advance to previous time period
		if day_night_system:
			var current_time = day_night_system.get_current_time()
			if current_time < 0.25:
				day_night_system.advance_to_sunrise()
			elif current_time < 0.5:
				day_night_system.advance_to_day()
			elif current_time < 0.75:
				day_night_system.advance_to_sunset()
			else:
				day_night_system.advance_to_night()
	
	if event.is_action_pressed("ui_right"):  # Right arrow
		# Advance to next time period
		if day_night_system:
			var current_time = day_night_system.get_current_time()
			if current_time < 0.25:
				day_night_system.advance_to_day()
			elif current_time < 0.5:
				day_night_system.advance_to_sunset()
			elif current_time < 0.75:
				day_night_system.advance_to_night()
			else:
				day_night_system.advance_to_sunrise()
	
	if event.is_action_pressed("ui_up"):  # Up arrow
		# Increase time speed
		if day_night_system:
			var current_speed = day_night_system.time_speed_multiplier
			day_night_system.set_time_speed(current_speed + 0.5)
			print("Time speed: ", day_night_system.time_speed_multiplier)
	
	if event.is_action_pressed("ui_down"):  # Down arrow
		# Decrease time speed
		if day_night_system:
			var current_speed = day_night_system.time_speed_multiplier
			day_night_system.set_time_speed(max(0.0, current_speed - 0.5))
			print("Time speed: ", day_night_system.time_speed_multiplier)

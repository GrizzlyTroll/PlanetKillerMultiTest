extends Node2D

## Day/Night Cycle Test Scene
## Standalone test for the day/night system

# Day/Night system
var day_night_system: DayNightSystemManager

func _ready() -> void:
	setup_day_night_system()

func setup_day_night_system() -> void:
	"""Set up the day/night cycle system for testing"""
	# Create day/night system manager
	day_night_system = DayNightSystemManager.new()
	day_night_system.name = "DayNightSystem"
	
	# Configure the system for testing
	day_night_system.enable_sky_transitions = true
	day_night_system.enable_dial_ui = true
	day_night_system.auto_start = true
	day_night_system.time_speed_multiplier = 3.0  # Faster for testing
	day_night_system.start_time = 0.25  # Start at day time
	
	# Connect signals
	day_night_system.time_changed.connect(_on_time_changed)
	day_night_system.day_started.connect(_on_day_started)
	day_night_system.night_started.connect(_on_night_started)
	day_night_system.sunrise_started.connect(_on_sunrise_started)
	day_night_system.sunset_started.connect(_on_sunset_started)
	day_night_system.sky_state_changed.connect(_on_sky_state_changed)
	
	# Add to scene
	add_child(day_night_system)
	
	# Create CanvasLayer for UI elements
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DayNightUI"
	add_child(canvas_layer)
	
	# Move the dial to the CanvasLayer and position it
	if day_night_system.retrograde_dial:
		day_night_system.remove_child(day_night_system.retrograde_dial)
		canvas_layer.add_child(day_night_system.retrograde_dial)
		day_night_system.retrograde_dial.position = Vector2(1150, 50)

func _input(event: InputEvent) -> void:
	"""Handle input for testing the day/night system"""
	if not day_night_system:
		return
	
	# Day/Night system test controls
	if event.is_action_pressed("ui_accept"):  # Spacebar
		# Toggle dial visibility
		day_night_system.toggle_dial()
	
	if event.is_action_pressed("ui_left"):  # Left arrow
		# Advance to previous time period
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
		var current_speed = day_night_system.time_speed_multiplier
		day_night_system.set_time_speed(current_speed + 0.5)
	
	if event.is_action_pressed("ui_down"):  # Down arrow
		# Decrease time speed
		var current_speed = day_night_system.time_speed_multiplier
		day_night_system.set_time_speed(max(0.0, current_speed - 0.5))

func _on_time_changed(time_of_day: float) -> void:
	"""Handle time changes"""
	pass

func _on_day_started() -> void:
	"""Handle day start"""
	pass

func _on_night_started() -> void:
	"""Handle night start"""
	pass

func _on_sunrise_started() -> void:
	"""Handle sunrise start"""
	pass

func _on_sunset_started() -> void:
	"""Handle sunset start"""
	pass

func _on_sky_state_changed(state_name: String) -> void:
	"""Handle sky state changes"""
	pass

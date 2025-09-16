extends Node
class_name DayNightSystemManager

## Day/Night System Manager
## Coordinates all day/night cycle components and provides unified interface

signal time_changed(time_of_day: float)
signal day_started
signal night_started
signal sunrise_started
signal sunset_started
signal sky_state_changed(state_name: String)

# Component references
@export var day_night_cycle: DayNightCycleComponent
@export var skybox_transition: SkyboxTransitionComponent
@export var retrograde_dial: RetrogradeDialComponent

# System settings
@export var enable_sky_transitions: bool = true
@export var enable_dial_ui: bool = true
@export var auto_start: bool = true

# Time control
@export var time_speed_multiplier: float = 1.0
@export var start_time: float = 0.0  # 0.0 = sunrise

func _ready() -> void:
	_setup_components()
	_connect_signals()
	
	if auto_start:
		start_system()

func _setup_components() -> void:
	# Create components if not provided
	if not day_night_cycle:
		day_night_cycle = DayNightCycleComponent.new()
		add_child(day_night_cycle)
	
	if not skybox_transition and enable_sky_transitions:
		skybox_transition = SkyboxTransitionComponent.new()
		skybox_transition.name = "SkyboxTransition"
		add_child(skybox_transition)
	
	if not retrograde_dial and enable_dial_ui:
		retrograde_dial = RetrogradeDialComponent.new()
		# Create CanvasLayer for UI elements
		var canvas_layer = CanvasLayer.new()
		canvas_layer.name = "DayNightUI"
		add_child(canvas_layer)
		canvas_layer.add_child(retrograde_dial)
		retrograde_dial.position = Vector2(1150, 50)

func _connect_signals() -> void:
	if day_night_cycle:
		day_night_cycle.time_changed.connect(_on_time_changed)
		day_night_cycle.day_started.connect(_on_day_started)
		day_night_cycle.night_started.connect(_on_night_started)
		day_night_cycle.sunrise_started.connect(_on_sunrise_started)
		day_night_cycle.sunset_started.connect(_on_sunset_started)
	
	if skybox_transition:
		skybox_transition.sky_state_changed.connect(_on_sky_state_changed)
	
	if retrograde_dial:
		retrograde_dial.time_clicked.connect(_on_dial_time_clicked)

func _on_time_changed(time_of_day: float) -> void:
	# Update skybox
	if skybox_transition:
		skybox_transition.update_sky_for_time(time_of_day)
	
	# Update dial
	if retrograde_dial:
		retrograde_dial.update_time(time_of_day)
	
	# Forward signal
	time_changed.emit(time_of_day)

func _on_day_started() -> void:
	day_started.emit()

func _on_night_started() -> void:
	night_started.emit()

func _on_sunrise_started() -> void:
	sunrise_started.emit()

func _on_sunset_started() -> void:
	sunset_started.emit()

func _on_sky_state_changed(state_name: String) -> void:
	sky_state_changed.emit(state_name)

func _on_dial_time_clicked(time_of_day: float) -> void:
	# Allow clicking dial to set time
	set_time(time_of_day)

## Public API

func start_system() -> void:
	"""Start the day/night cycle system"""
	if day_night_cycle:
		day_night_cycle.set_time(start_time)
		day_night_cycle.set_time_speed(time_speed_multiplier)
		day_night_cycle.resume_time()

func stop_system() -> void:
	"""Stop the day/night cycle system"""
	if day_night_cycle:
		day_night_cycle.pause_time()

func set_time(time_of_day: float) -> void:
	"""Set the current time of day (0.0 to 1.0)"""
	if day_night_cycle:
		day_night_cycle.set_time(time_of_day)

func advance_time(seconds: float) -> void:
	"""Advance time by the specified number of seconds"""
	if day_night_cycle:
		day_night_cycle.advance_time(seconds)

func set_time_speed(speed: float) -> void:
	"""Set the time progression speed multiplier"""
	time_speed_multiplier = speed
	if day_night_cycle:
		day_night_cycle.set_time_speed(speed)

func get_current_time() -> float:
	"""Get the current time of day (0.0 to 1.0)"""
	if day_night_cycle:
		return day_night_cycle.get_time_of_day()
	return 0.0

func get_time_string() -> String:
	"""Get the current time as a formatted string"""
	if day_night_cycle:
		return day_night_cycle.get_time_string()
	return "00:00"

func is_currently_day() -> bool:
	"""Check if it's currently day time"""
	if day_night_cycle:
		return day_night_cycle.is_currently_day()
	return true

func is_currently_night() -> bool:
	"""Check if it's currently night time"""
	if day_night_cycle:
		return day_night_cycle.is_currently_night()
	return false

func is_currently_sunrise() -> bool:
	"""Check if it's currently sunrise"""
	if day_night_cycle:
		return day_night_cycle.is_currently_sunrise()
	return false

func is_currently_sunset() -> bool:
	"""Check if it's currently sunset"""
	if day_night_cycle:
		return day_night_cycle.is_currently_sunset()
	return false

func get_current_sky_state() -> String:
	"""Get the current sky state name"""
	if skybox_transition:
		return skybox_transition.get_current_sky_state()
	return "day"

func set_day_night_ratio(day_ratio: float) -> void:
	"""Set the ratio of day to night (0.0 to 1.0)"""
	if day_night_cycle:
		day_night_cycle.day_percentage = day_ratio
		day_night_cycle.night_percentage = 1.0 - day_ratio
	
	if retrograde_dial:
		retrograde_dial.set_day_night_ratio(day_ratio)

func set_sky_transition_smoothness(smoothness: float) -> void:
	"""Set the sky transition smoothness"""
	if skybox_transition:
		skybox_transition.set_transition_smoothness(smoothness)

func set_dial_size(size: float) -> void:
	"""Set the retrograde dial size"""
	if retrograde_dial:
		retrograde_dial.set_dial_size(size)

func show_dial() -> void:
	"""Show the retrograde dial UI"""
	if retrograde_dial:
		retrograde_dial.visible = true

func hide_dial() -> void:
	"""Hide the retrograde dial UI"""
	if retrograde_dial:
		retrograde_dial.visible = false

func toggle_dial() -> void:
	"""Toggle the retrograde dial UI visibility"""
	if retrograde_dial:
		retrograde_dial.visible = not retrograde_dial.visible

## Convenience methods for common time operations

func advance_to_day() -> void:
	"""Advance time to the start of day"""
	set_time(0.15)  # Day starts at 15% of cycle

func advance_to_night() -> void:
	"""Advance time to the start of night"""
	set_time(0.85)  # Night starts at 85% of cycle

func advance_to_sunrise() -> void:
	"""Advance time to sunrise"""
	set_time(0.0)

func advance_to_sunset() -> void:
	"""Advance time to sunset"""
	set_time(0.65)  # Sunset starts at 65% of cycle

func sleep_until_morning() -> void:
	"""Simulate sleeping until morning (advance to sunrise)"""
	advance_to_sunrise()

func sleep_until_evening() -> void:
	"""Simulate sleeping until evening (advance to sunset)"""
	advance_to_sunset()

extends Node
class_name DayNightCycleComponent

## Day/Night Cycle Component
## Manages time progression and provides signals for time-based events

signal time_changed(time_of_day: float)
signal day_started
signal night_started
signal sunrise_started
signal sunset_started

# Time configuration
@export var day_duration_seconds: float = 1200.0  # 20 minutes for full cycle
@export var day_percentage: float = 0.7  # 70% of cycle is day
@export var night_percentage: float = 0.3  # 30% of cycle is night

# Current time state
var time_of_day: float = 0.0  # 0.0 to 1.0
var is_day: bool = true
var is_night: bool = false
var is_sunrise: bool = false
var is_sunset: bool = false

# Time progression
var time_speed: float = 1.0  # Multiplier for time progression
var is_paused: bool = false

# Time thresholds
var sunrise_start: float = 0.0
var day_start: float = 0.15
var sunset_start: float = 0.65
var night_start: float = 0.85

func _ready() -> void:
	# Calculate time thresholds based on day/night percentages
	_update_time_thresholds()
	# Start at sunrise
	time_of_day = sunrise_start
	_update_time_state()

func _process(delta: float) -> void:
	if is_paused:
		return
	
	# Advance time
	time_of_day += (delta / day_duration_seconds) * time_speed
	
	# Wrap around
	if time_of_day >= 1.0:
		time_of_day = 0.0
	
	_update_time_state()
	time_changed.emit(time_of_day)

func _update_time_thresholds() -> void:
	# Calculate thresholds based on day/night percentages
	day_start = (1.0 - day_percentage) / 2.0
	sunset_start = day_start + day_percentage
	night_start = sunset_start + (1.0 - day_percentage) / 2.0
	sunrise_start = 0.0

func _update_time_state() -> void:
	var was_day = is_day
	var was_night = is_night
	var was_sunrise = is_sunrise
	var was_sunset = is_sunset
	
	# Update current state
	is_sunrise = time_of_day >= sunrise_start and time_of_day < day_start
	is_day = time_of_day >= day_start and time_of_day < sunset_start
	is_sunset = time_of_day >= sunset_start and time_of_day < night_start
	is_night = time_of_day >= night_start or time_of_day < sunrise_start
	
	# Emit signals for state changes
	if not was_sunrise and is_sunrise:
		sunrise_started.emit()
	if not was_day and is_day:
		day_started.emit()
	if not was_sunset and is_sunset:
		sunset_started.emit()
	if not was_night and is_night:
		night_started.emit()

## Public API

func set_time(new_time: float) -> void:
	"""Set the time of day (0.0 to 1.0)"""
	time_of_day = clamp(new_time, 0.0, 1.0)
	_update_time_state()
	time_changed.emit(time_of_day)

func advance_time(seconds: float) -> void:
	"""Advance time by the specified number of seconds"""
	var time_delta = seconds / day_duration_seconds
	time_of_day += time_delta
	
	# Wrap around
	while time_of_day >= 1.0:
		time_of_day -= 1.0
	
	_update_time_state()
	time_changed.emit(time_of_day)

func set_time_speed(speed: float) -> void:
	"""Set the time progression speed multiplier"""
	time_speed = max(0.0, speed)

func pause_time() -> void:
	"""Pause time progression"""
	is_paused = true

func resume_time() -> void:
	"""Resume time progression"""
	is_paused = false

func get_time_of_day() -> float:
	"""Get current time of day (0.0 to 1.0)"""
	return time_of_day

func get_time_percentage() -> float:
	"""Get time as percentage (0 to 100)"""
	return time_of_day * 100.0

func get_time_string() -> String:
	"""Get time as formatted string (HH:MM)"""
	var total_minutes = time_of_day * 24.0 * 60.0
	var hours = int(total_minutes / 60.0)
	var minutes = int(total_minutes) % 60
	return "%02d:%02d" % [hours, minutes]

func is_currently_day() -> bool:
	"""Check if it's currently day time"""
	return is_day

func is_currently_night() -> bool:
	"""Check if it's currently night time"""
	return is_night

func is_currently_sunrise() -> bool:
	"""Check if it's currently sunrise"""
	return is_sunrise

func is_currently_sunset() -> bool:
	"""Check if it's currently sunset"""
	return is_sunset

func get_day_night_ratio() -> float:
	"""Get the ratio of day to night (0.0 = all night, 1.0 = all day)"""
	return day_percentage

extends CanvasLayer
class_name SkyboxTransitionComponent

## Skybox Transition Component
## Handles smooth transitions between different sky states based on time

signal sky_state_changed(state_name: String)

# Sky states configuration
@export var sky_states: Dictionary = {
	"sunrise": {
		"color_top": Color(1.0, 0.8, 0.6, 1.0),      # Pale yellow
		"color_bottom": Color(0.8, 0.9, 1.0, 1.0),   # Light blue
		"cloud_opacity": 0.3,
		"star_visibility": 0.0
	},
	"day": {
		"color_top": Color(0.5, 0.8, 1.0, 1.0),      # Bright blue
		"color_bottom": Color(0.8, 0.9, 1.0, 1.0),   # Light blue
		"cloud_opacity": 0.6,
		"star_visibility": 0.0
	},
	"sunset": {
		"color_top": Color(1.0, 0.4, 0.2, 1.0),      # Orange
		"color_bottom": Color(0.6, 0.2, 0.8, 1.0),   # Purple
		"cloud_opacity": 0.8,
		"star_visibility": 0.2
	},
	"night": {
		"color_top": Color(0.05, 0.05, 0.2, 1.0),    # Dark blue
		"color_bottom": Color(0.1, 0.1, 0.3, 1.0),   # Darker blue
		"cloud_opacity": 0.1,
		"star_visibility": 1.0
	}
}

# Transition settings
@export var transition_smoothness: float = 2.0  # Higher = smoother transitions
@export var enable_clouds: bool = true
@export var enable_stars: bool = true

# Node references
@onready var sky_gradient: ColorRect
@onready var clouds_layer: Control
@onready var stars_layer: Control

# Current state
var current_sky_state: String = "day"
var target_sky_state: String = "day"
var transition_progress: float = 0.0
var is_transitioning: bool = false

# Time thresholds for sky states
var sunrise_threshold: float = 0.15
var day_threshold: float = 0.35
var sunset_threshold: float = 0.65
var night_threshold: float = 0.85

func _ready() -> void:
	_setup_sky_nodes()
	_update_sky_state("day")

func _setup_sky_nodes() -> void:
	# Set CanvasLayer to be behind everything
	layer = -1000
	
	# Create sky gradient background
	sky_gradient = ColorRect.new()
	sky_gradient.name = "SkyGradient"
	sky_gradient.anchor_right = 1.0
	sky_gradient.anchor_bottom = 1.0
	sky_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_gradient.color = Color.BLUE  # Set initial color
	add_child(sky_gradient)
	
	# Create clouds layer
	if enable_clouds:
		clouds_layer = Control.new()
		clouds_layer.name = "CloudsLayer"
		clouds_layer.anchor_right = 1.0
		clouds_layer.anchor_bottom = 1.0
		clouds_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clouds_layer)
		_setup_clouds()
	
	# Create stars layer
	if enable_stars:
		stars_layer = Control.new()
		stars_layer.name = "StarsLayer"
		stars_layer.anchor_right = 1.0
		stars_layer.anchor_bottom = 1.0
		stars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(stars_layer)
		_setup_stars()

func _setup_clouds() -> void:
	# Load cloud texture
	var cloud_texture = preload("res://Assets/Parallax/DAYSKY/WhiteClouds.png")
	if cloud_texture:
		# Create multiple cloud sprites for parallax effect
		for i in range(5):
			var cloud = TextureRect.new()
			cloud.texture = cloud_texture
			cloud.modulate.a = 0.0  # Start invisible
			# Use viewport-relative positioning
			cloud.position = Vector2(
				randf_range(0, 1280),
				randf_range(50, 200)
			)
			cloud.size = Vector2(64, 32) * randf_range(0.5, 1.5)
			cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
			clouds_layer.add_child(cloud)

func _setup_stars() -> void:
	# Create star sprites
	for i in range(100):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = Color.WHITE
		star.modulate.a = 0.0  # Start invisible
		# Use viewport-relative positioning
		star.position = Vector2(
			randf_range(0, 1280),
			randf_range(50, 400)
		)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars_layer.add_child(star)

func _process(delta: float) -> void:
	if is_transitioning:
		transition_progress += delta * transition_smoothness
		if transition_progress >= 1.0:
			transition_progress = 1.0
			is_transitioning = false
			current_sky_state = target_sky_state
		
		_update_sky_appearance()

func update_sky_for_time(time_of_day: float) -> void:
	var new_state = _get_sky_state_for_time(time_of_day)
	if new_state != target_sky_state:
		_start_transition_to(new_state)

func _get_sky_state_for_time(time_of_day: float) -> String:
	if time_of_day < sunrise_threshold:
		return "night"
	elif time_of_day < day_threshold:
		return "sunrise"
	elif time_of_day < sunset_threshold:
		return "day"
	elif time_of_day < night_threshold:
		return "sunset"
	else:
		return "night"

func _start_transition_to(new_state: String) -> void:
	if new_state == current_sky_state:
		return
	
	target_sky_state = new_state
	transition_progress = 0.0
	is_transitioning = true
	sky_state_changed.emit(new_state)

func _update_sky_appearance() -> void:
	if not sky_gradient:
		return
	
	# Interpolate between current and target states
	var current_state = sky_states[current_sky_state]
	var target_state = sky_states[target_sky_state]
	
	# Interpolate colors
	var top_color = current_state.color_top.lerp(target_state.color_top, transition_progress)
	var bottom_color = current_state.color_bottom.lerp(target_state.color_bottom, transition_progress)
	
	# For now, use a simple blend of the two colors
	var blended_color = top_color.lerp(bottom_color, 0.5)
	sky_gradient.color = blended_color
	
	# Update clouds opacity
	if enable_clouds and clouds_layer:
		var cloud_opacity = lerp(
			current_state.cloud_opacity,
			target_state.cloud_opacity,
			transition_progress
		)
		for cloud in clouds_layer.get_children():
			if cloud is TextureRect:
				cloud.modulate.a = cloud_opacity
	
	# Update stars visibility
	if enable_stars and stars_layer:
		var star_visibility = lerp(
			current_state.star_visibility,
			target_state.star_visibility,
			transition_progress
		)
		for star in stars_layer.get_children():
			if star is ColorRect:
				star.modulate.a = star_visibility

func _update_sky_state(state_name: String) -> void:
	if not sky_states.has(state_name):
		return
	
	current_sky_state = state_name
	target_sky_state = state_name
	transition_progress = 1.0
	is_transitioning = false
	
	var state = sky_states[state_name]
	
	# Update gradient
	if sky_gradient:
		var blended_color = state.color_top.lerp(state.color_bottom, 0.5)
		sky_gradient.color = blended_color
	
	# Update clouds
	if enable_clouds and clouds_layer:
		for cloud in clouds_layer.get_children():
			if cloud is TextureRect:
				cloud.modulate.a = state.cloud_opacity
	
	# Update stars
	if enable_stars and stars_layer:
		for star in stars_layer.get_children():
			if star is ColorRect:
				star.modulate.a = state.star_visibility

## Public API

func set_sky_state(state_name: String) -> void:
	"""Immediately set sky to a specific state"""
	_update_sky_state(state_name)

func get_current_sky_state() -> String:
	"""Get the current sky state name"""
	return current_sky_state

func is_transition_active() -> bool:
	"""Check if a sky transition is currently happening"""
	return is_transitioning

func set_transition_smoothness(smoothness: float) -> void:
	"""Set the transition smoothness (higher = smoother)"""
	transition_smoothness = max(0.1, smoothness)

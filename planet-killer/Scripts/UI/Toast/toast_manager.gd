extends Node

## Simple Toast Manager - Autoload singleton for showing toast notifications
## Uses the BeautifulToast component for all notifications

signal toast_shown(toast: Control)
signal toast_dismissed(toast: Control)
signal toast_finished(toast: Control)

@export var max_toasts: int = 5
@export var toast_spacing: float = 10.0
@export var default_duration: float = 4.0
@export var animation_duration: float = 0.3

var active_toasts: Array[Control] = []
var toast_container: Control

func _ready() -> void:
	print("ToastManager initialized")
	call_deferred("_setup_toast_container")

func _setup_toast_container() -> void:
	await get_tree().process_frame
	_setup_toast_container_internal()

func _setup_toast_container_internal() -> void:
	print("Setting up toast container...")
	
	# Create toast container
	toast_container = Control.new()
	toast_container.name = "ToastContainer"
	toast_container.process_mode = Node.PROCESS_MODE_ALWAYS
	toast_container.custom_minimum_size = Vector2(400, 200)  # Give it a proper height
	toast_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	toast_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Use valid size flag
	toast_container.position = Vector2(50, 50)
	
	# Try to find or create a CanvasLayer for UI elements
	var canvas_layer = _find_or_create_canvas_layer()
	if canvas_layer:
		canvas_layer.add_child(toast_container)
		print("✅ Toast container added to CanvasLayer for UI persistence")
	else:
		# Fallback to root
		if get_tree() and get_tree().root:
			get_tree().root.add_child(toast_container)
			print("✅ Toast container added to root for persistence")
		
	toast_container.move_to_front()
	toast_container.z_index = 1000
	toast_container.visible = true
	print("✅ Toast container setup complete - position: ", toast_container.position, " size: ", toast_container.size, " visible: ", toast_container.visible)

## Helper function to find or create CanvasLayer for UI elements
func _find_or_create_canvas_layer() -> CanvasLayer:
	# First try to find existing CanvasLayer
	if get_tree() and get_tree().root:
		var existing_layer = _find_canvas_layer(get_tree().root)
		if existing_layer:
			print("✅ Found existing CanvasLayer: ", existing_layer.name)
			return existing_layer
	
	# Create new CanvasLayer if none exists
	if get_tree() and get_tree().root:
		var new_layer = CanvasLayer.new()
		new_layer.name = "ToastCanvasLayer"
		get_tree().root.add_child(new_layer)
		print("✅ Created new CanvasLayer: ", new_layer.name)
		return new_layer
	
	return null

## Helper function to find CanvasLayer in the scene tree
func _find_canvas_layer(node: Node) -> CanvasLayer:
	if node is CanvasLayer:
		return node
	
	for child in node.get_children():
		var result = _find_canvas_layer(child)
		if result:
			return result
	
	return null

## Main API: Show a toast notification
func show_toast(title: String, description: String = "", duration: float = -1.0) -> void:
	"""Show a toast notification with the given title and description"""
	print("🎬 ToastManager.show_toast called with title: ", title)
	
	if not _ensure_container_accessible():
		print("❌ Container not accessible, deferring...")
		call_deferred("show_toast", title, description, duration)
		return
	
	# Ensure container is ready before adding toast
	if not toast_container or not is_instance_valid(toast_container):
		print("❌ Container not valid, deferring...")
		call_deferred("show_toast", title, description, duration)
		return
	
	print("✅ Container ready, creating toast...")
	
	# Create beautiful toast
	var toast = BeautifulToast.new()
	toast_container.add_child(toast)
	active_toasts.append(toast)
	print("✅ Toast created and added to container: ", toast.name)
	
	# Configure the toast
	var data = {
		"title": title,
		"description": description,
		"duration": duration if duration > 0 else default_duration
	}
	toast.configure(data)
	
	# Position the toast
	_position_toast(toast)
	
	# Connect signals
	toast.toast_dismissed.connect(_on_toast_dismissed.bind(toast))
	toast.toast_finished.connect(_on_toast_finished.bind(toast))
	
	# Show animation
	_show_toast_animation(toast)
	
	toast_shown.emit(toast)
	print("✅ Toast setup complete: ", toast.name)

## Convenience methods for different toast types
func show_success(title: String, description: String = "", duration: float = -1.0) -> void:
	"""Show a success toast (same as show_toast, but semantically clear)"""
	show_toast(title, description, duration)

func show_error(title: String, description: String = "", duration: float = -1.0) -> void:
	"""Show an error toast (same as show_toast, but semantically clear)"""
	show_toast(title, description, duration)

func show_info(title: String, description: String = "", duration: float = -1.0) -> void:
	"""Show an info toast (same as show_toast, but semantically clear)"""
	show_toast(title, description, duration)

## Ensure container is accessible
func _ensure_container_accessible() -> bool:
	print("🔍 Checking container accessibility...")
	print("  Container exists: ", toast_container != null)
	print("  Container valid: ", is_instance_valid(toast_container) if toast_container else false)
	
	if not toast_container or not is_instance_valid(toast_container):
		print("❌ Container not accessible, recreating...")
		_force_recreate_container()
		return false
	
	print("  Container in tree: ", toast_container.is_inside_tree())
	
	# Check if container is in scene tree
	if not toast_container.is_inside_tree():
		print("❌ Container not in scene tree, attempting to re-add...")
		# Try to re-add to CanvasLayer instead of root
		var canvas_layer = _find_or_create_canvas_layer()
		if canvas_layer:
			canvas_layer.add_child(toast_container)
			toast_container.move_to_front()
			toast_container.z_index = 1000
			print("✅ Container re-added to CanvasLayer")
			return true
		else:
			print("❌ Cannot re-add container, recreating...")
			_force_recreate_container()
			return false
	
	print("✅ Container is accessible")
	return true

## Force container recreation
func _force_recreate_container() -> void:
	print("🔄 Force recreating toast container...")
	if toast_container and is_instance_valid(toast_container):
		toast_container.queue_free()
	toast_container = null
	call_deferred("_setup_toast_container_internal")

## Position a toast in the container
func _position_toast(toast: Control) -> void:
	print("🎯 Positioning toast: ", toast.name)
	toast.position = Vector2.ZERO
	toast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Stack toasts with spacing
	_update_toast_positions()

## Update positions of all active toasts
func _update_toast_positions() -> void:
	print("📐 Updating toast positions for ", active_toasts.size(), " toasts")
	var current_y = toast_spacing
	
	# Clean up any invalid toasts first
	active_toasts = active_toasts.filter(func(toast): return is_instance_valid(toast))
	
	for i in range(active_toasts.size()):
		var toast = active_toasts[i]
		if is_instance_valid(toast):
			toast.position.y = current_y
			print("  Toast ", i, " positioned at y: ", current_y, " size: ", toast.size)
			current_y += toast.size.y + toast_spacing
		else:
			print("  Toast ", i, " is invalid, skipping")

## Show toast with slide-in animation
func _show_toast_animation(toast: Control) -> void:
	print("🎬 Starting toast animation for: ", toast.name)
	print("  Container position: ", toast_container.position, " size: ", toast_container.size)
	print("  Toast initial position: ", toast.position, " size: ", toast.size)
	
	# For debugging: make toast visible immediately without animation
	toast.modulate.a = 1.0
	toast.position.x = 0.0
	print("  DEBUG: Toast made visible immediately at position: ", toast.position)
	
	# TODO: Re-enable animation once positioning is confirmed working
	# if get_tree():
	# 	# Start with toast off-screen and transparent
	# 	toast.modulate.a = 0.0
	# 	toast.position.x = -toast.size.x  # Start off-screen to the LEFT instead of right
	# 	print("  Toast positioned off-screen at: ", toast.position)
	# 	
	# 	# Create slide-and-fade animation
	# 	var tween = create_tween()
	# 	tween.set_parallel(true)
	# 	tween.tween_property(toast, "modulate:a", 1.0, animation_duration)
	# 	tween.tween_property(toast, "position:x", 0.0, animation_duration)
	# 	print("  Animation started - duration: ", animation_duration)
	# else:
	# 	# Fallback: make toast visible immediately
	# 	toast.modulate.a = 1.0
	# 	toast.position.x = 0.0
	# 	print("  Fallback: toast made visible immediately")

## Hide toast with slide-out animation
func _hide_toast_animation(toast: Control) -> void:
	if get_tree():
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(toast, "modulate:a", 0.0, animation_duration)
		tween.tween_property(toast, "position:x", toast.size.x, animation_duration)
		tween.tween_callback(_remove_toast.bind(toast))
	else:
		_remove_toast(toast)

## Remove toast from active list (deprecated - use _remove_toast_safely)
func _remove_toast(toast: Control) -> void:
	_remove_toast_safely(toast)

## Signal handlers
func _on_toast_dismissed(toast: Control) -> void:
	var toast_name = toast.name if is_instance_valid(toast) else "invalid"
	print("🚪 Toast dismissed: ", toast_name)
	toast_dismissed.emit(toast)
	_remove_toast_safely(toast)

func _on_toast_finished(toast: Control) -> void:
	var toast_name = toast.name if is_instance_valid(toast) else "invalid"
	print("✅ Toast finished: ", toast_name)
	toast_finished.emit(toast)
	_remove_toast_safely(toast)

## Safely remove toast from active list
func _remove_toast_safely(toast: Control) -> void:
	if not is_instance_valid(toast):
		print("⚠️ Toast is invalid, removing from list")
		active_toasts = active_toasts.filter(func(t): return t != toast and is_instance_valid(t))
		_update_toast_positions()
		return
	
	if toast in active_toasts:
		active_toasts.erase(toast)
		print("🗑️ Toast removed from active list: ", toast.name)
		toast.queue_free()
		_update_toast_positions()
	else:
		print("⚠️ Toast not found in active list: ", toast.name)
